// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Pausable is Ownable {

    // === Vars ===

    bool public paused = false;

    // === Events ===

    event PauseStateChanged(bool _paused);

    // === Errors ===

    error ContractPaused();
    error AlreadyInRequestedPausedState(bool _paused);

    // === Modifiers ===

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier notPaused() {
        if (paused)
            revert ContractPaused();
        _;
    }

    // === Functions ===

    /**
     * @dev Sets the contract paused state. Revert if the same state is passed. Emits a {PauseStateChanged} event.
     * @param _paused true to pause the contract, false to unpause
     */
    function setPaused(bool _paused) public onlyOwner {
        if (paused == _paused)
            revert AlreadyInRequestedPausedState(paused);
        paused = _paused;
        emit PauseStateChanged(_paused);
    }

    function pause() public onlyOwner {
        setPaused(true);
    }

    function unpause() public onlyOwner {
        setPaused(false);
    }
}