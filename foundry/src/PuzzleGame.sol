// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title PuzzleGame
 * @author Benhur P Benny
 * @notice This contract is a simple game where players can score points. Each game lasts for one day, the player who has the highest score at the end of the game wins.
 */
contract PuzzleGame is Ownable {
    using MessageHashUtils for bytes32;
    /*//////////////////////////////////////////////////////////////
                               STATE VARS
    //////////////////////////////////////////////////////////////*/

    uint256 private gameStartingTime = block.timestamp;
    uint256 public constant GAME_DURATION = 1 days;
    address[] private players;
    uint256 private currentGameId = 1;
    // the player level and score will be the same
    mapping(uint256 currentGameId => mapping(address player => uint256 score)) public playerScores;
    uint256 public i_entryFee;
    mapping(address winner => uint256 totalWinnings) public playerWinnings;
    mapping(uint256 currentGameId => mapping(address player => mapping(uint256 level => bytes32 solution))) public
        playerSolutions;
    uint256 public prizePool;
    address public i_backendSigner;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PuzzleGame_WinnerSelected(address indexed winner, uint256 indexed gameId, uint256 indexed prizeAmount);
    event PuzzleGame_PlayerEntered(uint256 indexed gameId, uint256 indexed startingTime, address indexed player);
    event PuzzleGame_RoundCleared(uint256 indexed gameId, address indexed player, uint256 indexed level);
    event PuzzleGame_GameRegistered(
        uint256 indexed gameId, uint256 indexed startingTime, uint256 entryFee, address indexed player
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error PuzzleGame_IncorrectEntryFee();
    error PuzzleGame_GameEnded();
    error PuzzleGame_GameNotEnded();
    error PuzzleGame_PlayerAlreadyEntered();
    error PuzzleGame_PlayerNotEntered();
    error PuzzleGame_IncorrectSolution();
    error PuzzleGame_IncorrectHashes();
    error PuzzleGame_TransactionFailed();
    error PuzzleGame_MsgSenderNotWinner();

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier validEntry() {
        if (block.timestamp > gameStartingTime + GAME_DURATION) {
            revert PuzzleGame_GameEnded();
        }
        if (playerScores[currentGameId][msg.sender] == 0) {
            revert PuzzleGame_PlayerNotEntered();
        }
        _;
    }

    constructor(uint256 _entryFee, address _backendSigner) Ownable(msg.sender) {
        i_entryFee = _entryFee;
        i_backendSigner = _backendSigner;
    }

    function enterGame() external payable {
        if (msg.value != i_entryFee) {
            revert PuzzleGame_IncorrectEntryFee();
        }
        if (block.timestamp > gameStartingTime + GAME_DURATION) revert PuzzleGame_GameEnded();
        // Player can enter the game only once
        if (playerScores[currentGameId][msg.sender] != 0) {
            revert PuzzleGame_PlayerAlreadyEntered();
        }
        players.push(msg.sender); // Add player to the list
        playerScores[currentGameId][msg.sender] = 1; // Initialize player's score
        prizePool += i_entryFee;
        emit PuzzleGame_PlayerEntered(currentGameId, gameStartingTime, msg.sender);
    }

    function registerGameSolution(bytes32 solution) external validEntry {
        // Store the player's solution for the given level
        uint256 level = playerScores[currentGameId][msg.sender]; // Assuming level is the same as score
        playerSolutions[currentGameId][msg.sender][level] = solution;
        //here I am thinking about adding a penalty like if the user changes the challenge they have to pay a fee or I will deduct a point from their score but now let it be.
        emit PuzzleGame_GameRegistered(currentGameId, gameStartingTime, i_entryFee, msg.sender);
    }

    //I have to a sig check also!
    function playGame(bytes32[] memory tileHashes, bytes memory sig) external validEntry {
        uint256 level = playerScores[currentGameId][msg.sender];
        uint256 tileCount = (level + 2) * (level + 2); // Assuming level is the same as score, calculate tile count
        //ex: for level one 9 tile, 3x3 grid, for level two 16 tile, 4x4 grid, etc.
        if (tileHashes.length != tileCount) {
            revert PuzzleGame_IncorrectHashes();
        }
        bytes32 solution = playerSolutions[currentGameId][msg.sender][level];
        bytes32 computedHash = keccak256(abi.encodePacked(tileHashes));
        //checking whether the user is solving the puzzle through the correct means, i.e through the website!
        bytes32 ethSignedMessage = computedHash.toEthSignedMessageHash();
        address signer = ECDSA.recover(ethSignedMessage, sig);
        if (signer != i_backendSigner) {
            revert PuzzleGame_IncorrectSolution();
        }
        if (computedHash != solution) {
            revert PuzzleGame_IncorrectSolution();
        }
        playerScores[currentGameId][msg.sender] += 1; // Increment player's score
        emit PuzzleGame_RoundCleared(currentGameId, msg.sender, level);
    }

    // if there is a draw in here like
    // Alice 5 and Bob 5
    // then the winner will be the one who has entered the game first
    function selectWinner() external returns (address winner) {
        if (block.timestamp < gameStartingTime + GAME_DURATION) {
            revert PuzzleGame_GameNotEnded();
        }
        if (players.length == 0) {
            gameStartingTime = block.timestamp; // Reset game starting time if no players
            currentGameId++;
            return address(0);
        }

        uint256 highestScore = 0;
        uint256 playerLen = players.length;
        for (uint256 i = 0; i < playerLen; i++) {
            address player = players[i];
            if (playerScores[currentGameId][player] > highestScore) {
                highestScore = playerScores[currentGameId][player];
                winner = player;
            }
        }
        uint256 winningAmount = prizePool * 9e17 / 1e18;
        prizePool = 0; // Reset prize pool for the next game
        playerWinnings[winner] += winningAmount;
        gameStartingTime += GAME_DURATION; // Reset game starting time for the next game
        currentGameId++; // Increment game ID for the next game
        // aderyn-ignore-next-line
        players = new address[](0);
        emit PuzzleGame_WinnerSelected(winner, currentGameId - 1, winningAmount);
    }

    function claimWinnings() external {
        uint256 winnings = playerWinnings[msg.sender];
        if (winnings == 0) {
            revert PuzzleGame_MsgSenderNotWinner();
        }
        playerWinnings[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: winnings}("");
        if (!success) revert PuzzleGame_TransactionFailed();
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance - prizePool}("");
        if (!success) revert PuzzleGame_TransactionFailed();
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getGameStartingTime() external view returns (uint256) {
        return gameStartingTime;
    }

    function getCurrentGameId() external view returns (uint256) {
        return currentGameId;
    }

    function getPlayer(uint256 _index) external view returns (address) {
        if (_index >= players.length) {
            revert PuzzleGame_PlayerNotEntered();
        }
        return players[_index];
    }

    function getPlayerWinnings(address _player) external view returns (uint256) {
        return playerWinnings[_player];
    }
}
