// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
Test Cases:
1. Simple Swap and Execution test: Test creating a swap and checks if thetokens are correctly transferred upon execution
2. CounterParty: Ensure that Eve can't interfere the swap
3. Token Approvals: Check the allowance doesn't bear any security risks
4. Expiration test: Test that swap can't be executed after expired
 */

/// @title A contract that allow users to initiate and execute token swaps
/// @author Eric Taylor
/// @notice An "Over-the-counter" swap contract that any two parties come together for ERC20 token swaps
/// @dev Swap Id is deterministic by addresses, amount and token contracts
contract OTCSwap is Ownable {
    using SafeERC20 for IERC20;

    // Duration for the swap to be expired
    uint256 public expiration;
    
    // Swap object type definition
    struct Swap {
        address alice;
        address bob;
        address tokenX;
        address tokenY;
        uint256 amountX;
        uint256 amountY;
        bool executed;
    }

    // All swaps is put to here    
    mapping(bytes32 => Swap) public swaps;
    
    event SwapInitiated(bytes32 indexed swapId, address indexed alice, address indexed bob, address tokenX, address tokenY, uint256 amountX, uint256 amountY);
    event SwapExecuted(bytes32 indexed swapId);
    
    constructor(uint256 _expiration) {
        expiration = _expiration;
    }
    
    /**
     * @notice Initiates a new swap object
     * @param bob address of the user who is the owner of `tokenY`
     * @param tokenX address of the `tokenX` to be swapped in to `tokenY`
     * @param tokenY address of the `tokenY` to be swapped from `tokenX`
     * @param amountX amount of the `tokenX`
     * @param amountY amount of the `tokenY`
     */
    function initiateSwap(address bob, address tokenX, address tokenY, uint256 amountX, uint256 amountY) external {
        require(tokenX != tokenY, "Tokens must be different");
        require(amountX > 0 && amountY > 0, "Amounts must be greater than zero");
        require(IERC20(tokenX).allowance(msg.sender, address(this)) >= amountX, "Contract is not allowed to transfer tokenX");
        require(IERC20(tokenY).allowance(bob, address(this)) >= amountY, "Bob is not allowed to transfer tokenY");
        
        bytes32 swapId = keccak256(abi.encodePacked(msg.sender, bob, tokenX, tokenY, amountX, amountY));
        require(swaps[swapId].alice == address(0), "Swap already exists");
        
        swaps[swapId] = Swap({
            alice: msg.sender,
            bob: bob,
            tokenX: tokenX,
            tokenY: tokenY,
            amountX: amountX,
            amountY: amountY,
            executed: false
        });
        
        emit SwapInitiated(swapId, msg.sender, bob, tokenX, tokenY, amountX, amountY);
    }
    
    /**
     * @notice Function that executes the swap operation
     * @dev Only alice or bob can call this function
     * @param swapId Swap Object Id to be executed
     */
    function executeSwap(bytes32 swapId) external {
        Swap storage swap = swaps[swapId];
        require(swap.alice == msg.sender || swap.bob == msg.sender, "Caller is not part of the swap");
        require(block.timestamp <= expiration, "Swap has expired");
        require(!swap.executed, "Swap already executed");
        
        IERC20(swap.tokenX).transferFrom(swap.alice, swap.bob, swap.amountX);
        IERC20(swap.tokenY).transferFrom(swap.bob, swap.alice, swap.amountY);
        
        swap.executed = true;
        
        emit SwapExecuted(swapId);
    }
}

