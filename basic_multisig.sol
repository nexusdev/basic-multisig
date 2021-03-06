/// basic_multisig.sol -- basic standalone multisig implementation

contract BasicMultisigEvents {
    event LogProposed  (uint indexed id);
    event LogConfirmed (uint indexed id, address member);
    event LogTriggered (uint indexed id);
}

contract BasicMultisig is BasicMultisigEvents {
    function assert(bool condition) {
        if (!condition) throw;
    }

    function members() constant returns (uint count) {
        return member.length;
    }

    address[]  public  member;
    uint8      public  quorum;
    uint40     public  window;

    mapping (address => bool)  public  isMember;

    function BasicMultisig(
        address[] _members,
        uint8     _quorum,
        uint40    _window
    ) {
        member = _members;
        quorum = _quorum;
        window = _window;

        assert(members() <= 255);
        assert(members() >= quorum);

        for (uint i = 0; i < members(); i++) {
            isMember[member[i]] = true;
        }
    }

    //------------------------------------------------------
    // Proposing new actions
    //------------------------------------------------------

    function actions() constant returns (uint count) {
        return target.length;
    }

    function callsize(uint id) constant returns (uint) {
        return calldata[id].length;
    }

    function callhash(uint id) constant returns (bytes32) {
        return sha3(calldata[id]);
    }

    function expired(uint id) constant returns (bool) {
        return now >= expiration[id];
    }

    function confirmed(uint id) constant returns (bool) {
        return confirmations[id] >= quorum;
    }

    address[]  public  target;
    bytes[]    public  calldata;
    uint[]     public  value;
    uint40[]   public  expiration;
    uint8[]    public  confirmations;
    bool[]     public  triggered;
    bool[]     public  succeeded;

    mapping (uint => mapping (address => bool))  public  confirmedBy;

    function propose(address _target, bytes _calldata, uint _value)
        returns (uint id)
    {
        id = actions();

        target        .push(_target);
        calldata      .push(_calldata);
        value         .push(_value);
        expiration    .push(uint40(now) + window);
        confirmations .push(0);
        triggered     .push(false);
        succeeded     .push(false);

        LogProposed(id);
    }

    function propose(address target, bytes calldata) returns (uint id) {
        return propose(target, calldata, 0);
    }

    function propose(address target, uint value) returns (uint id) {
        return propose(target, "", value);
    }

    function propose(address target) returns (uint id) {
        return propose(target, "", 0);
    }

    //------------------------------------------------------
    // Confirming and triggering pending actions
    //------------------------------------------------------

    modifier pending(uint id) {
        assert(id < actions());
        assert(!expired(id));
        assert(!triggered[id]);
        _
    }

    function confirm(uint id) pending(id) {
        assert(isMember[msg.sender]);
        assert(!confirmedBy[id][msg.sender]);

        confirmations[id]++;
        confirmedBy[id][msg.sender] = true;

        LogConfirmed(id, msg.sender);
    }

    function trigger(uint id) pending(id) {
        assert(confirmed(id));
        assert(this.balance >= value[id]);

        triggered[id] = true;
        succeeded[id] = target[id].call.value(value[id])(calldata[id]);

        LogTriggered(id);
    }
}
