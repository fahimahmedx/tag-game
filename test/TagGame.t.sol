// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TagGame} from "../src/TagGame.sol";

contract TagGameTest is Test {
    TagGame public tagGame;
    address player1 = address(0x1);
    address player2 = address(0x2);
    address player3 = address(0x3);

    function setUp() public {
        tagGame = new TagGame();
    }

    function testJoinGame() public {
        vm.prank(player1);
        tagGame.joinGame();
        assertTrue(tagGame.players(player1));
        assertEq(tagGame.playerCount(), 1);

        vm.prank(player2);
        tagGame.joinGame();
        assertTrue(tagGame.players(player2));
        assertEq(tagGame.playerCount(), 2);
    }

    function testLeaveGame() public {
        vm.prank(player1);
        tagGame.joinGame();

        vm.prank(player2);
        tagGame.joinGame();

        vm.prank(player1);
        tagGame.leaveGame();
        assertFalse(tagGame.players(player1));
        assertEq(tagGame.playerCount(), 1);

        // Ensure player1 is removed from the player list
        address[] memory players = tagGame.getPlayers();
        assertEq(players.length, 1);
        assertEq(players[0], player2);
    }

    function testLeaveGameWhenIt() public {
        vm.prank(player1);
        tagGame.joinGame();

        vm.prank(player2);
        tagGame.joinGame();

        vm.prank(player3);
        tagGame.joinGame();

        // Ensure the game starts and there is an "it" player
        address initialIt = tagGame.getIt();
        assertTrue(initialIt == player1 || initialIt == player2 || initialIt == player3);

        // The "it" player leaves the game
        vm.prank(initialIt);
        tagGame.leaveGame();
        assertFalse(tagGame.players(initialIt));
        assertEq(tagGame.playerCount(), 2);

        // Ensure a new "it" player is chosen
        address newIt = tagGame.getIt();
        assertTrue(newIt != initialIt);
        assertTrue(newIt == player1 || newIt == player2 || newIt == player3);
    }

    function testTagPlayer() public {
        vm.prank(player1);
        tagGame.joinGame();

        vm.prank(player2);
        tagGame.joinGame();

        address itPlayer = tagGame.getIt();
        address notItPlayer = itPlayer == player1 ? player2 : player1;

        vm.prank(itPlayer);
        tagGame.tagPlayer(notItPlayer);
        assertEq(tagGame.getIt(), notItPlayer);
    }

    function testTagSelfFails() public {
        vm.prank(player1);
        tagGame.joinGame();

        vm.prank(player2);
        tagGame.joinGame();

        address itPlayer = tagGame.getIt();

        vm.prank(itPlayer);
        vm.expectRevert("You cannot tag yourself");
        tagGame.tagPlayer(itPlayer);
    }

    function testOnlyItCanTag() public {
        vm.prank(player1);
        tagGame.joinGame();

        vm.prank(player2);
        tagGame.joinGame();

        address itPlayer = tagGame.getIt();
        address notItPlayer = itPlayer == player1 ? player2 : player1;

        vm.prank(notItPlayer);
        vm.expectRevert("Only 'it' can perform this action");
        tagGame.tagPlayer(itPlayer);
    }

    function testCheckItTimeout() public {
        vm.prank(player1);
        tagGame.joinGame();

        vm.prank(player2);
        tagGame.joinGame();

        address initialIt = tagGame.getIt();

        // Fast forward time by more than the timeout duration
        vm.warp(block.timestamp + 1 hours + 1);

        // Ensure timeout can be checked and a new "it" player is chosen
        tagGame.checkItTimeout();
        address newIt = tagGame.getIt();
        assertTrue(newIt != initialIt);
    }

    function testGetPlayers() public {
        vm.prank(player1);
        tagGame.joinGame();

        vm.prank(player2);
        tagGame.joinGame();

        address[] memory players = tagGame.getPlayers();
        assertEq(players.length, 2);
        assertEq(players[0], player1);
        assertEq(players[1], player2);
    }
}
