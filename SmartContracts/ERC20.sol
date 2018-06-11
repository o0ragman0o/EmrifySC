pragma solidity 0.4.23;

/*
This is the interface of the HIT token contract(just below). It gives the basic idea
of the functions we are using in the HIT contract.
*/

interface ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);  
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool ok);
    function transferFrom(address from, address to, uint256 value) external returns (bool ok);
    function approve(address spender, uint256 value) external returns (bool ok);  
    function totalSupply() external view returns(uint256 totalSupply);
}

