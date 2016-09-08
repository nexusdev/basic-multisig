import "basic_multisig.sol";

contract BasicMultisigFactory {
    function createMultisig(
        address[] members, uint8 quorum, uint40 window
    ) returns (BasicMultisig) {
        return new BasicMultisig(members, quorum, window);
    }
}
