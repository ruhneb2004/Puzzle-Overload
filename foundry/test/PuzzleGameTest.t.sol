// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployPuzzleGame} from "../script/DeployPuzzleGame.s.sol";
import {PuzzleGame, MessageHashUtils} from "../src/PuzzleGame.sol";

contract PuzzleGameTest is Test {
    using MessageHashUtils for bytes32;

    PuzzleGame puzzleGame;
    uint256 entryFee = 0.001 ether;
    address backendSigner = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address user = makeAddr("user");
    uint256 constant BACKEND_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    bytes32 solution = 0x031082f9e91723feb65277f353c2c641ae8cf778536f946e290dc071348ba0ba;
    //for a 3*3 puzzle, we need 9 hashes
    bytes32[] tileHashes;

    function setUp() public {
        DeployPuzzleGame deployer = new DeployPuzzleGame();
        address puzzleGameAddress = deployer.deployPuzzleGame(entryFee, backendSigner);
        puzzleGame = PuzzleGame(puzzleGameAddress);
        vm.deal(user, 10 ether); // Give user some ether for testing
        tileHashes.push(0xb85fa7230c2772186467f6cc073d0a24045aeffee835dfd6c70852c92c797e22);
        tileHashes.push(0x137356154ec89bca35dda1431a5d8ed4d18e21ff364204721e8ddebfd93ca3ca);
        tileHashes.push(0xe9c61fb2da73a579f936107fb43efa597d3108acd50ebb05a8178e3d38a0fc8e);
        tileHashes.push(0x943d1412d0544bca9f69e6282553d0fec2ef7a790745a0733ff50c409eb244bf);
        tileHashes.push(0x57fd3fdf41037e8ebba22661941c149df76bc110e0ee523c9adcd2d5b2a733b4);
        tileHashes.push(0xedf43bb4b03418231cb2c7adfded76778c9af4198bda0569cf29073c9272eae4);
        tileHashes.push(0xa82505856049e4ee5c439f0cd6122a38aa37990c16df6104af1d664bda44e5cf);
        tileHashes.push(0x7a28e56c5ca7f9fc9c3adcbea2f59bea405473f399e93dd5a8bc0d2d6984441b);
        tileHashes.push(0x42d087fa6c6be535f958ce9f9976dcfd9494545d0c81f406646f9aeaf7fd3edb);
    }

    function testInitialState() public view {
        assertEq(puzzleGame.GAME_DURATION(), 1 days);
        assertEq(puzzleGame.i_entryFee(), 0.001 ether);
        assertEq(puzzleGame.getCurrentGameId(), 1);
        assertEq(puzzleGame.prizePool(), 0);
        assertEq(puzzleGame.getGameStartingTime(), block.timestamp);
        assertEq(puzzleGame.i_backendSigner(), backendSigner);
        assertEq(puzzleGame.getCurrentGameId(), 1);
    }

    function testEnterGame() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, false, false);
        emit PuzzleGame.PuzzleGame_PlayerEntered(1, block.timestamp, user);
        puzzleGame.enterGame{value: entryFee}();
        vm.stopPrank();

        assertEq(puzzleGame.getPlayer(0), user);
        assertEq(puzzleGame.playerScores(1, user), 1);
        assertEq(puzzleGame.prizePool(), entryFee);
    }

    function testEnterGameFailsIfAmountNotEqualToEntryFee() public {
        vm.startPrank(user);
        vm.expectRevert(PuzzleGame.PuzzleGame_IncorrectEntryFee.selector);
        puzzleGame.enterGame{value: 0.002 ether}();
        vm.stopPrank();
    }

    function testEnterGameFailsIfGameEnded() public {
        vm.warp(block.timestamp + 1 days + 1);
        vm.roll(100);
        vm.startPrank(user);
        vm.expectRevert(PuzzleGame.PuzzleGame_GameEnded.selector);
        puzzleGame.enterGame{value: entryFee}();
        vm.stopPrank();
    }

    function testEnterGameFailsIfPlayerAlreadyEntered() public {
        vm.startPrank(user);
        puzzleGame.enterGame{value: entryFee}();
        vm.expectRevert(PuzzleGame.PuzzleGame_PlayerAlreadyEntered.selector);
        puzzleGame.enterGame{value: entryFee}();
        vm.stopPrank();
    }

    function testRegisterGameSolution() public {
        vm.prank(user);
        puzzleGame.enterGame{value: entryFee}();

        vm.prank(user);
        puzzleGame.registerGameSolution(solution);
        assertEq(puzzleGame.playerSolutions(1, user, 1), solution);
    }

    function testPlayeGameFailsWithIncorrectNumberOfHashes() public {
        vm.startPrank(user);
        puzzleGame.enterGame{value: entryFee}();

        bytes32[] memory falseTileHashes = new bytes32[](5); // Incorrect number of hashes
        bytes memory sig = hex"1234567890abcdef"; // Dummy signature
        vm.expectRevert(PuzzleGame.PuzzleGame_IncorrectHashes.selector);
        puzzleGame.playGame(falseTileHashes, sig);
        vm.stopPrank();
    }

    function testPlayGameHashWorks() public {
        vm.startPrank(user);
        puzzleGame.enterGame{value: entryFee}();

        puzzleGame.registerGameSolution(solution);

        bytes32 actualSolution = puzzleGame.playerSolutions(1, user, 1);

        // Create a valid signature for the solution
        bytes32 computedHash = keccak256(abi.encodePacked(tileHashes));
        console.logBytes32(computedHash);
        console.logBytes32(actualSolution);
        assertEq(actualSolution, computedHash, "The actual solution should match the computed hash");
        bytes32 ethSignedMessage = computedHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BACKEND_PRIVATE_KEY, ethSignedMessage);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, false, false);
        emit PuzzleGame.PuzzleGame_RoundCleared(1, user, 1);
        puzzleGame.playGame(tileHashes, sig);
        assertEq(puzzleGame.playerScores(1, user), 2); // Assuming score increments by 1
        vm.stopPrank();
    }
}
