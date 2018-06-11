pragma solidity 0.4.23;

import "./Hodler.sol";
import "./library.sol";
import "./ERC20.sol";


/*
The Main HIT token contract, it is a standard ERC20 contract with a small addition.
The addition is that this contract will notify another contract whenever token transfer
happens.
*/


contract HIT is ERC20,Ownable {    
    using SafeMath for uint256;
    string public constant name = "Health Information Token";
    string public constant symbol = "HIT";
    uint8 public constant decimals = 18;
    uint256 private constant totalSupply1 = 1000000000 * 10 ** uint256(decimals);
    mapping (address => uint256)  balances;
    mapping (address => mapping (address => uint256))  allowed;
    Hodler public hodlerContract;

    // The constructor method which will initialize the token supply.	    
    constructor() public {
        emit Transfer(0x0,msg.sender,totalSupply1);
        balances[msg.sender] = totalSupply1;	
    }

    // Constant function to return the total supply of the HIT contract
    function totalSupply() public view returns(uint) {
        return totalSupply1;
    }

    // To set the HODL contract address, This contract will notify HODL on token transfer. Check `transfer()` method
    function setHolderContractAddress(address _holderContractAddress) public onlyOwner {
        require(hodlerContract==address(0));
        hodlerContract = Hodler(_holderContractAddress);
    }

    /* 
    Transfer amount from one account to another (may require approval). This function trigger the action to 
    invalidate the participant's right to get the HODL rewards if they make any transation within the hodl period.
    Getting into the HODL club is optional by not moving their tokens after reveiving tokens in their wallet for 
    pre-defined period like 3,6,9 or 12 months.
    More details are here about the HODL T&C : https://medium.com/@Vikas1188/lets-hodl-with-emrify-bc5620a14237
    */
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(hodlerContract.checkStakeValidation(_from)) {
            require(hodlerContract.invalidate(_from));
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
	
    // Standard token transfer method.
    function transfer(address _to, uint256 _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    /*
    This method will allow a 3rd person to spend tokens (requires `approval()` 
    to be called before with that 3rd person's address)
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    // Approve `_spender` to move `_value` tokens from owner's account
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Returns balance
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // Returns whether the `_spender` address is allowed to move the coins of the `_owner` 
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}

