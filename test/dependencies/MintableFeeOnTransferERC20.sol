pragma solidity 0.8.26;

import {ERC20} from "oz/token/ERC20/ERC20.sol";
import {UNIT, MAX_FEE} from "../../src/IMetrom.sol";

contract MintableFeeOnTransferERC20 is ERC20 {
    uint32 public fee;
    address public recipient;

    error InvalidRecipient();

    constructor(string memory _name, string memory _symbol, uint32 _fee, address _recipient) ERC20(_name, _symbol) {
        if (_recipient == address(0)) revert InvalidRecipient();
        fee = _fee;
        recipient = _recipient;
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        _spendAllowance(_from, msg.sender, _value);

        uint256 _feeAmount = _value * fee / UNIT;
        _transfer(_from, recipient, _feeAmount);
        _transfer(_from, _to, _value - _feeAmount);

        return true;
    }
}
