// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PuzzleGame} from "../src/PuzzleGame.sol";
import {Script} from "forge-std/Script.sol";

contract DeployPuzzleGame is Script {
    uint256 private entryFee = 0.001 ether;
    address private backendSigner = 0x76CCD3b19D8c4C4A0b0806bF537Bc3F2717d710E;

    function run() external returns (address) {
        vm.startBroadcast();
        address puzzleGameAddress = deployPuzzleGame(entryFee, backendSigner);
        vm.stopBroadcast();
        return puzzleGameAddress;
    }

    function deployPuzzleGame(uint256 _entryFee, address _backendSigner) public returns (address) {
        PuzzleGame puzzleGame = new PuzzleGame(_entryFee, _backendSigner);
        return address(puzzleGame);
    }
}
