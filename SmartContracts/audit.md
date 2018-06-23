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

Fourth Review at Commit `8c83351`

- [x] import paths have been changed to `browser/` for unknown. No such path exists in the repo and contracts cannot compile. Revert to `./` import path.  Fixed in 588f42c.

Fifth Review at Commit: `588f42c`

Sixth Review at Commit: `0d0e88c`

Fixes from prior reviews have now allowed for a deeper architectural review. An inordinate number of potential failure vectors and manual deploy requirments have been noted. A significant refactor is required to greatly simplify the contracts and contract set. HITAirDrop and TokenDistribution can be dropped completely and Hodler can be deployed by HIT. This requires integrating a bulk transfer function and token/state distribution function into the HIT contract. The Timelock contract can be dropped and replaced by a simple lock mapping, function and test in the HIT contract. Hodler itself has broken maths, unused state declaration, unnecessary state declaration, an overly complex reward calculation and requires more consideration around finalizing the contract.

It must be noted that even with the required refactoring, the contract set still cannot pass audit as it does not present a trustless architecture as the holders are entirely dependant upon the owners deploying the contracts correctly and manually distribute the correct value of tokens for each holder

Seventh Review at Commit: `2411a70`

Contracts have been refactored and compile without error or warning. However, the code has been resubmitted for audit but includes old code commented out. It is concerning that the engineer has a continual disregard for basic coding practises and lacks proper consideration of the implications of the changes required to the codebase as raised by this auditing process. At every step so far, it appears that the engineer has not performed sufficient testing of the code before submission.  While the code base has now been greatly simplified, further bugs have been introduced and areas of code redundancy remains. The Reward claiming process is inconsistent, containing race conditions and errors in logical conditions for time checks.

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

Review 6 `0d0e88c`
 -[x] All tests passed

**Passed audit**

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

Review 6 `0d0e88c`
 -[x] All tests passed

**Passed audit**

Review 7
- [ ] The refactoring and simplification of the other contracts now allows for the removal of the `SafeMath40` library 



## ERC20.sol
- [x] Compiler is set to ^0.4.18.  Fix in 2137139 set to 0.4.18

### Contracts
#### contract ERC20

- [x] Contract does not contain all state variable defined in ERC20 but contains only `totalSupply`. redeclared `interface` in `0d0e88c`
- [x] `totalSupply` typed as `uint` alias. Redeclare `totalSupply` as abstract getter instead of a state variable. Almost fixed in `0d0e88c`
The contract is written in abstract should should declare the `totalSupply()`
getter abstract instead of declare a state variable. The contract can then be declared as an `interface ERC20Interface`
- [x] Use of `constant` for functions is depreciated replace `constant` with `view`. 
for functions referencing state variables. Fixed in 2137139

review 6
- [x] `totalSupply` has been redeclared as abstract function and contract declared as interface, however an uneccessarily and what I thought to be an improperly named return parameter `totalSupply` has been introduced and shaddows the function of the same name. This practice causes compiler warnings and breaks standard calling conventions by preventing the oppertunity for recursive calling. However, in reviewing the [standard ERC20 document](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md), it's noted that they also use shadow declarations for named return parameters.  As it's improper (in the least) to have a 'standard' which causes compiler warnings, an issue has been raised against the standard itself. For the purpose of these contracts, there is no real issue raised however it is suggested that the naming of the return parameter be removed or changed to supress the compiler warning. Fixed in  `2411a70`.

review 7
**interface ERC20** passes audit 


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

Sixth Review
- [x] Refactor the contract to be deployed and owned by HIT.  Refactored in  `2411a70`.
    - [x] Redundant state variable. `address HITTokenContract` and `ERC20 public tokenContract` are set once to the same address. `HITTokenContract` is used only in a modifier. Remove `HITTokenContract` and use `address(tokenContract)` casting in modifier `onlyTokenContract` instead.
    - [x] `tokenDistributionContract` no longer required once token distribution is written into the HIT contract.
    - [x] `onlyAccessContract` modifier no longer needed
    - [x] constructor to take single argument for pool tokens
    - [x] timed pools (` TOKEN_HODL_3M`, ...) to be calculated accordingly
    - [x] remove `hodlerTime3M`, etc state variable and calculate dynamically from `hodlerTimeStart`
    - [x] remove unused state declarations `hodlerTotalValue3M`...
    - [x] remove `_setter` parameter from events as it doesn't provide useful information

Seventh Review
- [ ] Refactoring the HODL struct to use a time instead of flags has reduced the struct to two state slots. There is no longer a benefit for using `uint40` for time variable `lastClaimed` as there is no state packing advantage. Redeclaring as `uint` allows the removal of type casting throught the contract and removal of the `SafeMath40` library
- [ ] Redeclare `hodlerTimeStart` from `uint40` to `uint256`
- [ ] remove obsolete commented code


`function setContractAddresses`

- [x] Allows the owner to change the referenced contracts at any time which introduces a point of *trust*. Fixed in 2137139
Require that one of the contract addresses 0x0 before setting.
- [x] Require that passed parameters are valid contracts. Refactored and removed in  `2411a70`.
- [x] Function does not declare a return value

Review 6
- [x] Refactoring for the removal of redundant `TokenDIstribution` and `HITAirDrop` contracts, this function can be removed. Refactored and removed in  `2411a70`.

Review 7
- [ ] remove obsolete commented code

`function addHodlerStake`

- [x] Declare and implement boolean return values for the calling contract to test. Fixed in 2137139
- [x] Use `emit` keyword for event invocation. Fixed in 2137139

Review 6
- [x] Change modifier to `onlyTokenContract()`.  Refactored and removed in  `2411a70`.


`function setHodlerTime`

- [x] Declare and implement boolean return values for the calling contract to test.
- [x] Use `emit` keyword for event invocation. Fixed in 2137139

Review 7
- [ ] Redeclare parameter `_time` as `uint256`. (Refactoring has allowed for removal of `SafeMath40`)

`function invalidate(address _account)`

- [x] Declare and implement boolean return values for the calling contract to test. Fixed in 2137139
- [x] Incorrect return structure, may return a false positive. Move `return true` into true conditional block else return false. Fixed in 8c83351
- [x] Garbage collect `hodlerStakes- [_account].stake`.  Refactored and fixed in  `2411a70`.
- [x] **BUG** `delete hodlerStakes[_account]` New garbage collection code introduced in 8c83351 for above issue breaks invalidation testing of the staker. The invalid flag design is using logic that is unnecessarily inverted. Project has removed buggy garbage collection instead of repatterned code to use positive logic to address the garbage collection issue

Review 6
- [x] Invalidate to simply delete account from mapping.  Fixed in  `2411a70`.
- [ ] *BUG* Remove `hodlerTotalValue = hodlerTotalValue.sub(hodlerStakes[_account].stake);` as it breaks reward maths.

`function checkStakeValidation(address _account) view public returns (bool)`
- [x] better name would be `isValid(address _account)`. Fixed in `2411a70`.
- [x] should simply return true if account stake is > 0. Fixed in `2411a70`.

`function claimHodlReward`

- [ ] Declare and implement boolean return values for the calling contract to test. Buggy fix in 8c83351
- [ ] 8c83351 introduced incorrect return value. Function needs to return the return value of `claimHodlRewardFor()`, not `true`

`function claimHodlRewardFor`

- [x] Declare and implement boolean return values for the calling contract to test.
- [x] Use `emit` keyword for event invocation.  Fixed in 2137139

Review 6
- [x] can be greatly simplified by refactoring `struct HODL` to use `lastClaimed` time instead of bool flags. Refactored in  `2411a70`.
- [x] calculate `hodlerTime3M`,... dynamically against `hodlerTimeStart` rather than using state variables. Refactored in  `2411a70`.
- [x] remove core calculation to its own internal function. Refactored in  `2411a70`.
- [ ] *BUG* maths is broken by change to `hodlerTotalValue` in function `invalidate()`. Two holders of equal stake will recieve different rewards if a third staker invalidates.

Review 7
- [ ] remove `uint40` casting of `block.timestamp`

`function calculateStake`

Review 7
This function has been introduced under refactoring advice from review 6.
- [ ] remove obsolete commented code
- [ ] *BUG* Incorrect time threshold calculations. Should be:
    `if( now >= hodlerTimeStart + 90 days && 
        hodlerStakes[_beneficiary].lastClaimed < hodlerTimeStart + 90 days)` etc
- [ ] *BUG* stake share only calculates against `TOKEN_HODL_3M` for all time thresholds
- [ ] `hodlerStakes[_beneficiary].lastClaimed` should be cached to a `uint` local variable to increase readability and save significant gas costs of multiple mapping dereferences

`function finalizeHodler`

- [x] Declare and implement boolean return values for the calling contract to test.  Fixed in 2137139
- [x] Use `require` instead of `assert` for testing success of code execution. (`assert` boolean expressions should only be referencing data not changing it)  Fixed in 2137139

Review 6
- [x] *BUG* function does not test for unclaimed rewards and can completely wipe unclaimed rewards after 12 months. Refactored and removed in  `2411a70`.

Review 7
- [ ] The function has been removed but no alternative method of returning unclaimed reward tokens has been provided

`function claimHodlRewardsForMultipleAddresses`

- [x] Declare and implement boolean return values for the calling contract to test.  Fixed in 2137139
- [x] parameter requirments in `claimHodlRewardFor()` can cause this function to fail 
if a hodler has already claimed. Change `claimHodlRewardFor()` to non-blocking or test beneficiary before calling `claimHodlRewardFor`.  Modified in 588f42c (see next issue).
- [x] Fix for above issue can be significantly gas optomised by caching the beneficiary struct to memory before reading it's state. e.g. 
```
HODL memory hodler = hodlerStakes(_beneficiaries[i]);
```

Review 6
- [x] function can be greatly simplified if `struct HODL` is refactored to use a last claim time rather than bool flags.  Refactored in  `2411a70`.

Review 7
- [ ] `claimHodlRewardFor()` is no longer blocking. `if` conditions and `require` in this loop can be removed.
- [ ] caching of `hodler` no longer required after refactor.

## ERC20HIT.sol
Compiler set to Solidity 0.4.23

- [x] fix invalid import paths introduced in 2137139. Fixed in 588f42c

### Contracts
#### contract TokenInterface

- [x] No state declarations so contract can be declared as `interface`.  Fixed in 2137139
- [x] Use of `constant` for functions is depreciated replace `constant` with `view`.  Fixed in 2137139
- [x] Note: `internal` functions cannot be declared in an interface as they cannot be interfaced by an external caller.  Fixed in 2137139
- [x] This contract is redundant once the ERC20 interface contract is properly declared and inherited instead. Remove and use the standard ERC20 interface contract from ERC20.sol. Removed in `0d0e88c`

#### contract HIT is TokenInterface, Ownable

- [x] contract ownerable is not delcared in file or imports. Fixed in 240e10d
- [x] library.sol is locally imported but does not exist in repo.  Fixed in 240e10d
- [x] Constructor name is same as contract. This pattern is depreciated from Solidity 0.4.22. Declare using the `constructor` keyword.  Fixed in 2137139
- [x] Constructor assigns tokens and so should emit the `Transfer` event using `0x0` as the from address according to the ERC20 standard. This will allow full ledger replay.  Fixed in 2137139
- [x] State variables `name`, `symbol`, `decimals`, `totalSupply` can be declared as `constant` to reduce storage costs upon deployment. Fixed in 2137139
- [x] State variable `balances` should not be declared public as it's getter `balanceOf()` has been explicity defined. Fixed in 2137139
- [x] State variable `allowances` should not be declared public as it's getter `allowance()` has been explicity defined. Fixed in 2137139
- [x] Import ERC20.sol and inherit from ERC20 interface contract instead.
- [x] `hodlerContract` should be declared as constant and assigned the pre deployed Hodler contract address. Refactored in  `2411a70` to create `Hodler` contract upon deployment

Sixth Review
- [x] Include a bulk transfer function and stake initialization function to allow removal of redundant contracts `tokenDistribution` and `HITAirDrop`.  Refactored in `2411a70`.

Seventh Review
- [ ] Remove obsolete commented code
- [ ] `tokenLockTime` is declared with magic number. Comment how number is derived
- [ ] The `_timeStamp` parameter in events does not provide useful information as the timestamp is already contained in the block that logs the event

`contructor()`
Seventh Review
- [ ] The value passed to the `new Hodler` constructor is a magic number and should be a declared as a named constant in the state declarations.

 `function setHolderContractAddress`
- [x] No restriction upon owner resetting the contract address which is a point of*trust* Function can be removed when `holderContract` is declared at construction.  Refactored and removed in `2411a70`

Seventh Review
- [ ] Remove commented obsolete code

 `function _transfer`
- [x] A zero value transfer is a valid transfer under ERC20. Remove the `_value > 0` condition from the paramter requirments.  Fixed in 2137139
- [x] `_to != 0x0` ERC20 transfer events to and from address 0x0 are understood to be *burn* and *mint* events. The contract can be simplified to take advantage of this pattern.  Fixed in 2137139
- [x] `hodlerContract.invalidate(_from)` test return value of external call.  Fixed in 2137139

Seventh Review
- [ ] include `require(block.timestamp >= lockTimes[msg.sender]);`


`function _burn()`
- [x] can be simplified to use the `_transfer` to 0x0. Fixed in 2137139
- [x] Burning tokens does not invalidate tokens in hodler contract. Use `transfer` to 0x0.  Fixed in 2137139
- [x] Burn event not required if rewitten to use `transfer` to 0x0.  Removed in 2137139

`function transfer`
Seventh Review
- [ ] move `require` condition into `_transfer`

`function approve`
- [x] is vulnerable to front running double spend attack. This is where
an observant spender detects a change in allowance in the pending transaction pool
and creates a higher gas priced `transferFrom` to spend and outstanding allowance before update.
This can be mitigated by setting the allowance to `0` followed by a second transaction to set the actual allowance.
Project has elected to mitigate risk by raising awareness in their community of untrusted spenders. 588f42c 

Seventh Review

- [ ] move `require` condition into `_transfer`
 
`function balanceOf`
- [x] implement using the `view` modifier instead of `constant`. Fixed in 2137139

`function allowance`
- [x] implement using the `view` modifier instead of `constant`. Fixed in 2137139

`function AirDropTokens`
Seventh Review

- [ ] This function is new after refactor advise from review 6. It is notrequired as same can be accomplished in `batchTransfer`

`saleDistribution`
Seventh Review

- [ ] This function is new after refactor advise from review 6. It is not required as the same can be accomplished with modifications to `saleDistributionMultiAddress`

`batchTransfer`
Seventh Review

This function is new after refactor advise from review 6.
- [ ] `onlyOwner` modifier should be dropped to allow holder to batch transfer their own tokens also
- [ ] `_addresses[i]!=owner` not required
- [ ] `require(transfer...` requirment is redundant
- [ ] use internal transfer function `_transfer`
- [ ] `TokenDistributionAddressNotCorrect` `0x0` will be the only fail address

`setLockTime`
Seventh Review

This function is new after refactor advise from review 6.
- [ ] Function not required. The project has stated only 2 addresses will be time locked. these can be done during construction or at some other appropriate phase.

`startHodler`
Seventh Review

This function is new after refactor advise from review 6.
-[ ] Function not required. `hodlerContract.setHodlerTime` should be called deterministically at the correct phase of the ICO rather than by the owner.

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
    - [x] *BUG* Function does not return a value and defaults to `return false` which will force functions `AirDropTokens` and `AirdropMultiValues` to throw.Contract removed
- [x] Inconsistent camelCase for `AirDropTokens` and `AirdropMultiValues`. Contract removed
    
Sixth Review
- [x] This contract is found to be entirely redundant.  Remove and incorporate the bulk transfer function into the HIT contract.  Refactored removed in  `2411a70`.


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

Sixth Review
- [x] This contract can be replaced by a lock mapping in the `HIT` contract along with a locking function and lock test in the transfer function.  Refactored removed in  `2411a70`.


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

Sixth review
- [x] The only unique functionality of this contract is the external call to `hodlerContract.addHodlerStake(_beneficiaryAddress,_amount)`. The entire contract can be considered redundant if the bulk transfer function is incorportate into t `HIT` contract along with the addtion of the `saleDistributionMultiAddress()` function which initiates hodler staking. Refactored removed in  `2411a70`.

