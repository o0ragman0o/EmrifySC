# Emrify ICO Audit
Web: [https://www.emrify.com/](https://www.emrify.com/)

Repo: [https://github.com/emrifylabs/EmrifySC](https://github.com/emrifylabs/EmrifySC)

Auditor: Darryl Morris


Initial commit for audit:  `f72af68`
14-May-18
Note: contract set does not compile

Commit: `240e10d` 

Second review

Contracts compile with warnings.

HITAirDop.sol does not compile.

Commit: `2137139`

Third review

Preliminary notes:

- [x] contract set cannot compile due to missing `library.sol` and incorrect import chains. Fixed in 240e10d
- [x] Choose same compiler version for all contracts. Mix of 0.4.18 and 0.4.23 introduces inconsitent coding behaviours. Fixed in 2137139
- [x] Clean up code style in all contracts according to Solidity Style Guide.  Fixed in 588f42c.
- [x] Write contract level description blocks outlining the purpose and interaction of each contract.  Fixed in 588f42c.

Fourth Review- Commit `8c83351`

- [x] import paths have been changed to `browser/` for unknown. No such path exists in the repo and contracts cannot compile. Revert to `./` import path.  Fixed in 588f42c.

Fifth Review - Commit: `588f42c`

## Library.sol
compiler is set to solidity 0.4.23

- [x] imported by other contracts but missing from repo. fixed in 240e10d

### Contracts
#### contract Ownable 
Compiles with warning

- [x] Constructor name is same as contract. This pattern is depreciated from Solidity 0.4.22.  Fixed in 2137139
- [x] `owner` may be inadvertantly burned if an incorrect address is provided to `transferOwnership()` resulting in
potential los of contract control. Consider two phase ownership transferal of `transferOwnership()` 
and `acceptOwnership()` to prove that the recipient can control the contract. Attemped fix in 2137139 has introduced new bug
- [x] *BUG introduced in 2137139 `owner = newOwner;` should be `tempOwner = newOwner;`. Fixed in  8c83351
- [x] Declare tempOwner as `public` in order to be verified for claiming ownership. Fixed in  8c83351


#### library SafeMath

This is a library taken from the OpenZeppelin set. No issues (though coding style
can be cleaned up but use of return parameter for `c`) 

- [x] Parallel `uint40` SafeMath library has been introducted under recommendation for `uint40` time variables.
A preferrable option would be the addition of a `to40()` safe casting function. 
All math can then be conducted in `uint256` and cast to uint40 when necessary.
e.g.

```
   // Safe cast from uint to uint40
    function to40(uint a) internal pure returns (uint40 b) {
        b = uint40(a);
        assert(uint(b) == a);
    }
    
    ...
    
    uint40 someTime = (block.timestamp + 1 day).to40();
```
Project has elected to keep using `SafeMath40` library


## ERC20.sol
- [x] Compiler is set to ^0.4.18.  Fix in 2137139 set to 0.4.18

### Contracts
#### contract ERC20

- [ ] Contract does not contain all state variable defined in ERC20 but contains only `totalSupply`.
- [ ] `totalSupply` typed as `uint` alias. Redeclare `totalSupply` as abstract getter instead of a state variable.
The contract is written in abstract should should declare the `totalSupply()`
getter abstract instead of declare a state variable. The contract can then be declared as an `interface ERC20Interface`
- [x] Use of `constant` for functions is depreciated replace `constant` with `view`. Fixed in 2137139
for functions referencing state variables



## Holder.sol
- [x] Compiler is set to ^0.4.18. Fix in 2137139 set to 0.4.18 

Imports library.sol ERC20.sol

- [x] Change filename to reflect name of primary contract name (Holder vs Hodler).  Fixed in 2137139 set to 0.4.18

- [x] Commit 8c83351 has introduced incorrect import paths as `browser/`. FIxed in 588f42c

### Contracts
#### contract Hodler is Ownable
- [x] All functions should return a value. Functions that are called by an external
contract in particular should return at least a `bool` success value so the calling contract can test for expecteded behaviour.
Severity: high. Contracts may not behave as expected if testing return values of inter-contract calls is not performed. Addressed in 2137139

- [x] Storage costs for HODL struct may be halved by redefining member types to fit in 1 storage slot rather than two and type casting when needed. Project has elected to keep seperate slots.
- [x] Storage costs for time variables (hodlerTimeStart, hodlerTime3M, ...) can be declared `uint40` to pack all six variable in one storage slot.   Fixed in 2137139
- [x] Declare `ERC20 tokenContract;` as public. Fixed in  8c83351

`function setContractAddresses`

- [x] Allows the owner to change the referenced contracts at any time which introduces a point of *trust*. Fixed in 2137139
Require that one of the contract addresses 0x0 before setting.
- [ ] Require that passed parameters are valid contracts.
- [x] Function does not declare a return value

`function addHodlerStake`

- [x] Declare and implement boolean return values for the calling contract to test. Fixed in 2137139
- [x] Use `emit` keyword for event invocation. Fixed in 2137139

`function setHodlerTime`

- [x] Declare and implement boolean return values for the calling contract to test.
- [x] Use `emit` keyword for event invocation. Fixed in 2137139

`function invalidate(address _account)`

- [x] Declare and implement boolean return values for the calling contract to test. Fixed in 2137139
- [x] Incorrect return structure, may return a false positive. Move `return true` into true conditional block else return false. Fixed in 8c83351
- [ ] Garbage collect `hodlerStakes- [_account].stake`
- [x] **BUG** `delete hodlerStakes[_account]` New garbage collection code introduced in 8c83351 for above issue breaks invalidation testing of the staker. The invalid flag design is using logic that is unnecessarily inverted. Project has removed buggy garbage collection instead of repatterned code to use positive logic to address the garbage collection issue

`function claimHodlReward`

- [ ] Declare and implement boolean return values for the calling contract to test. Buggy fix in 8c83351
- [ ] 8c83351 introduced incorrect return value. Function needs to return the return value of `claimHodlRewardFor()`, not `true`

`function claimHodlRewardFor`

- [x] Declare and implement boolean return values for the calling contract to test.
- [x] Use `emit` keyword for event invocation.  Fixed in 2137139

`function finalizeHodler`

- [x] Declare and implement boolean return values for the calling contract to test.  Fixed in 2137139
- [x] Use `require` instead of `assert` for testing success of code execution. (`assert` boolean expressions should only be referencing data not changing it)  Fixed in 2137139

`function claimHodlRewardsForMultipleAddresses`

- [x] Declare and implement boolean return values for the calling contract to test.  Fixed in 2137139
- [x] parameter requirments in `claimHodlRewardFor()` can cause this function to fail 
if a hodler has already claimed. Change `claimHodlRewardFor()` to non-blocking or test beneficiary before calling `claimHodlRewardFor`.  Modified in 588f42c (see next issue).
- [ ] Fix for above issue can be significantly gas optomised by caching the beneficiary struct to memory before reading it's state. e.g.
```
HODL memory hodler = hodlerStakes(_beneficiaries[i]);
```


## ERC20HIT.sol
Compiler set to Solidity 0.4.23

- [x] fix invalid import paths introduced in 2137139. Fixed in 588f42c

### Contracts
#### contract TokenInterface

- [x] No state declarations so contract can be declared as `interface`.  Fixed in 2137139
- [x] Use of `constant` for functions is depreciated replace `constant` with `view`.  Fixed in 2137139
- [x] Note: `internal` functions cannot be declared in an interface as they cannot be interfaced by an external caller.  Fixed in 2137139
- [ ] This contract is redundant once the ERC20 interface contract is properly declared and inherited instead. Remove and use the standard ERC20 interface contract from ERC20.sol

#### contract HIT is TokenInterface, Ownable

- [x] contract ownerable is not delcared in file or imports. Fixed in 240e10d
- [x] library.sol is locally imported but does not exist in repo.  Fixed in 240e10d
- [x] Constructor name is same as contract. This pattern is depreciated from Solidity 0.4.22. Declare using the `constructor` keyword.  Fixed in 2137139
- [x] Constructor assigns tokens and so should emit the `Transfer` event using `0x0` as the from address according to the ERC20 standard. This will allow full ledger replay.  Fixed in 2137139
- [x] State variables `name`, `symbol`, `decimals`, `totalSupply` can be declared as `constant` to reduce storage costs upon deployment. Fixed in 2137139
- [x] State variable `balances` should not be declared public as it's getter `balanceOf()` has been explicity defined. Fixed in 2137139
- [x] State variable `allowances` should not be declared public as it's getter `allowance()` has been explicity defined. Fixed in 2137139
- [ ] `hodlerContract` should be declared as constant and assigned the pre deployed Hodler contract address.
- [ ] `function setHolderContractAddress` No restriction upon owner resetting the contract address which is a point of*trust* Function can be removed when `holderContract` is declared at construction
- [x] `function _transfer` A zero value transfer is a valid transfer under ERC20. Remove the `_value > 0` condition from the paramter requirments.  Fixed in 2137139
    - [x] `_to != 0x0` ERC20 transfer events to and from address 0x0 are understood to be *burn* and *mint* events. The contract can be simplified to take advantage of this pattern.  Fixed in 2137139
    - [x] `hodlerContract.invalidate(_from)` test return value of external call.  Fixed in 2137139
- [x] `function _burn()` can be simplified to use the `_transfer` to 0x0. Fixed in 2137139
    - [x] Burning tokens does not invalidate tokens in hodler contract. Use `transfer` to 0x0.  Fixed in 2137139
    - [x] Burn event not required if rewitten to use `transfer` to 0x0.  Fixed in 2137139
- [x] `function approve` is vulnerable to front running double spend attack. This is where
an observant spender detects a change in allowance in the pending transaction pool
and creates a higher gas priced `transferFrom` to spend and outstanding allowance before update.
This can be mitigated by setting the allowance to `0` followed by a second transaction to set the actual allowance.
Project has elected to mitigate risk by raising awareness in their community of untrusted spenders. 588f42c 
- [x] `function balanceOf` implement using the `view` modifier instead of `constant`. Fixed in 2137139
- [x] `function allowance` implement using the `view` modifier instead of `constant`. Fixed in 2137139

- [ ] Import ERC20.sol and inherit from ERC20 interface contract instead

## HITAirdop.sol
Compiler set to Solidity 0.4.23

imports library.sol and ERC20.sol

- [x] Fix filename spelling. Fixed in 2137139

### Contracts
#### contract Ownable

- [x] remove to own file as it is required by other contracts which have not imported this file. Fixed in 240e10d
- [x] Remove from file as it is declared in `library.sol`. Fixed in 2137139

#### contract Airdrop is Ownable

- [x] Constructor name is same as contract. This pattern is depreciated from Solidity 0.4.22. Declare using the `constructor` keyword. Fixed in 2137139

- [x] `function distributeTokens` Use `require` instead of `assert` for testing success of code execution. (`assert` boolean expressions should only be referencing data not changing it). Fixed in 2137139
    - [x] Declare and implement a boolean return value.  Fixed in 2137139
    - [ ] *BUG* Function does not return a value and defaults to `return false` which will force functions `AirDropTokens` and `AirdropMultiValues` to throw.
- [ ] Inconsistent camelCase for `AirDropTokens` and `AirdropMultiValues`
    


## TimeLock.sol
Compiler set to Solidity 0.4.23

imports ERC20.sol

### Contracts
#### contract TimeLock 

NOTE: This contract is not referenced by any other contracts in the set. It's purpose is unclear from reading its code alone.
- [x] Establish purpose of contract in comments and how it will be utilized by the contract set. Fixed in 588f42c.
- [x] Constructor name is same as contract. This pattern is depreciated from Solidity 0.4.22. Declare using the `constructor` keyword.  Fixed in 2137139
- [x] Storage gas can be saved by declaring variable `releaseTime` as `uint64` which will pack in a storage slot with the `beneficiary` address variable. Fixed in 588f42c.
- [x] modifier `onlyOwner` only used once. Remove and inline the requirment into the implementing function. Fixed in 2137139
- [x] modifier `onlyBeneficiary` only used once. Remove and inline the requirment into the implementing function. Fixed in 2137139
- [x] `function LockTokens` contains external #call before update# anti-pattern. Move `require(tokenContract.transferFrom(msg.sender, address(this), _amount));` to end of function. Fixed in 2137139
    - [ ]  Declare and implement a boolean return value.
- [x] `function release()` Use `require` instead of `assert` for testing success of code execution. (`assert` boolean expressions should only be referencing data not changing it). Fixed in 2137139
    - [x]  Declare and implement a boolean return value. Fixed in 2137139
- [x] Fix invalid import paths introduced in 2137139.  Fixed in 588f42c.



## TokenDistribution.sol
Compiler set to Solidity 0.4.23
Imports library.sol ERC20.sol Holder.sol

### Contracts
#### contract TokenDistribution is Ownable
- [x] `tokenContract` should be declared as public. Fixed in 2137139
- [x] `tokenContract` should be declared public constant and assigned address of relevent predeplyed contract. Fixed in 2137139
- [x] `hodlerContract` should be declared as public. Fixed in 2137139
- [x] `hodlerContract` should be declared public constant and assigned address of relevent predeplyed contract. Fixed in 2137139
- [x] `function setContractAddresses` Owner can arbitrarily change contract addresses creating a non-deterministic point of true. Set contract address variables as public constants. Removed in 2137139
- [x] `function distributeTokens` Use `require` instead of `assert` for testing success of code execution. (`assert` boolean expressions should only be referencing data not changing it). Fixed in 2137139
- [x] `function distributeTokens` implement boolean return value. Fixed in 2137139
- [x] `function SaleDistribution` Use `camelCase` for function identifiers to prevent confusion with events. Fixed in 2137139
- [x] `function SaleDistribution` Implement success testing for external calls to contracts. Fixed in 2137139
    - [x]  Declare and implement a boolean return value.
- [x] `function SaleDistributionMultiAddress` Use `camelCase` for function identifiers to prevent confusion with events. Fixed in 2137139
- [x] `function BatchTransfer` Impliment success testing for external calls to contracts. Fixed in 2137139
- [x] `function BatchTransfer` Use `camelCase` for function identifiers to prevent confusion with events. Fixed in 2137139
- [x] Fix invalid import paths introduced in 2137139.  Fixed in 588f42c.

