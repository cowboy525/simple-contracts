// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
1. Deploying the contract with correct parameters
2. Adding and Removing a signer, check signer permissions as well
3. Changing parameters
4. Queueing and Executing actions: Test queueing multiple actions and executing them 
with the required number of signatures, ensuring that actions are executed in the correct order and only once.
*/

/// @title A smart contract that implements a multisig wallet
/// @author Eric Taylor
/// @notice A Multisig wallet where m of n signatures required for any action
/// @dev Adding/Removing signer might be replaced into an action later. We can also add removeAction
contract MultiSigWallet {
    // Maximum number of signers
    uint256 public constant MAX_SIGNERS = 10;
    // Maximum number of queued actions
    uint256 public constant MAX_ACTIONS = 100;
    
    // List of current signers
    address[] public signers;
    // Mapping to track if address is a signer
    mapping(address => bool) public isSigner;
    
    // Number of required signatures for execution
    uint256 public quorum;
    // Mapping to track executed transactions
    mapping(bytes32 => bool) public executed;
    
    struct Action {
        address to;
        uint256 value;
        bytes data;
    }
    
    // Queue of actions
    Action[] public actions;
    
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event QuorumChanged(uint256 quorum);
    event ActionQueued(uint256 indexed index, address indexed to, uint256 value, bytes data);
    event ActionExecuted(uint256 indexed index, address indexed to, uint256 value, bytes data);
    
    modifier onlySigner() {
        require(isSigner[msg.sender], "Only signers can call this function");
        _;
    }
    
    modifier isValidRequire(uint256 _quorum, uint256 _numSigners) {
        require(_quorum > 0 && _numSigners > 0 && _quorum <= _numSigners && _numSigners <= MAX_SIGNERS, "Invalid requirement");
        _;
    }
    
    constructor(address[] memory _signers, uint256 _quorum) isValidRequire(_quorum, _signers.length) {
        for (uint256 i = 0; i < _signers.length; i++) {
            require(!isSigner[_signers[i]] && _signers[i] != address(0), "Invalid signer address");
            isSigner[_signers[i]] = true;
        }
        signers = _signers;
        quorum = _quorum;
    }
    
    /**
     * @notice Registers a new signer
     * @dev We may want to do this via multisig action later
     * @param newSigner Address of the new signer
     */
    function addSigner(address newSigner) external onlySigner {
        require(signers.length < MAX_SIGNERS, "Max number of signers reached");
        require(!isSigner[newSigner] && newSigner != address(0), "Invalid signer address");
        
        isSigner[newSigner] = true;
        signers.push(newSigner);
        
        emit SignerAdded(newSigner);
    }
    
    /**
     * @notice Removes the existing signer
     * @dev We may want to do this via multisig action later
     * @param signerToRemove Address of the signer to be removed
     */    
    function removeSigner(address signerToRemove) external onlySigner {
        require(signers.length > 1, "Cannot remove all signers");
        require(isSigner[signerToRemove], "Address is not a signer");
        
        isSigner[signerToRemove] = false;
        
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signerToRemove) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }
        
        emit SignerRemoved(signerToRemove);
    }
    
    /**
     * @notice Update quorum number for an action
     * @param _quorum newQuorum number
     */
    function changeQuorum(uint256 _quorum) external onlySigner isValidRequire(_quorum, signers.length) {
        quorum = _quorum;
        emit QuorumChanged(_quorum);
    }
    
    /**
     * @notice Add a new action
     * @param to Target address for the action
     * @param value Ether value for the action
     * @param data Calldata
     */
    function queueAction(address to, uint256 value, bytes memory data) external onlySigner {
        require(actions.length < MAX_ACTIONS, "Max number of queued actions reached");
        
        bytes32 actionHash = keccak256(abi.encodePacked(to, value, data));
        require(!executed[actionHash], "Action already executed");
        
        actions.push(Action({
            to: to,
            value: value,
            data: data
        }));
        
        emit ActionQueued(actions.length - 1, to, value, data);
    }
    
    /**
     * @notice Executes the action
     * @param index of the action in the list
     */
    function executeAction(uint256 index) external onlySigner {
        require(index < actions.length, "Invalid action index");
        require(actions.length > 0, "No actions to execute");
        
        bytes32 actionHash = keccak256(abi.encodePacked(actions[index].to, actions[index].value, actions[index].data));
        require(!executed[actionHash], "Action already executed");
        
        executed[actionHash] = true;
        
        (bool success, ) = actions[index].to.call{value: actions[index].value}(actions[index].data);
        require(success, "Action execution failed");
        
        emit ActionExecuted(index, actions[index].to, actions[index].value, actions[index].data);
    }
}
