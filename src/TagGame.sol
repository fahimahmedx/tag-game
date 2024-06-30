// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TagGame {
    address public it; // Address of the player who is "it"
    mapping(address => bool) public players; // Mapping to track players
    address[] public playerList; // List of all players
    uint public playerCount; // Total number of players
    uint public lastTagTime; // Timestamp of the last tag
    uint public tagTimeout = 1 hours; // Timeout duration

    event JoinedGame(address player);
    event LeftGame(address player);
    event Tagged(address taggedPlayer);
    event NewGameStarted(address firstIt);
    event ItTimeout(address newIt);

    modifier onlyPlayer() {
        require(players[msg.sender], "You must be a player to perform this action");
        _;
    }

    modifier onlyIt() {
        require(msg.sender == it, "Only 'it' can perform this action");
        _;
    }

    function joinGame() public {
        require(!players[msg.sender], "You are already in the game");

        players[msg.sender] = true;
        playerList.push(msg.sender);
        playerCount++;

        emit JoinedGame(msg.sender);

        // Start the game if there are enough players (minimum 2 players to start)
        if (playerCount == 2 && it == address(0)) {
            startNewGame();
        }
    }

    function leaveGame() public onlyPlayer {
        require(players[msg.sender], "You are not in the game");

        players[msg.sender] = false;
        playerCount--;

        // Remove player from playerList
        for (uint i = 0; i < playerList.length; i++) {
            if (playerList[i] == msg.sender) {
                playerList[i] = playerList[playerList.length - 1];
                playerList.pop();
                break;
            }
        }

        emit LeftGame(msg.sender);

        // If the player leaving is "it", choose a new "it" if there are still players
        if (msg.sender == it && playerCount > 0) {
            chooseNewIt();
        }
    }

    function tagPlayer(address _taggedPlayer) public onlyIt {
        require(players[_taggedPlayer], "The tagged player must be in the game");
        require(_taggedPlayer != it, "You cannot tag yourself");

        it = _taggedPlayer;
        lastTagTime = block.timestamp;

        emit Tagged(_taggedPlayer);
    }

    function startNewGame() internal {
        require(playerCount >= 2, "Need at least 2 players to start the game");

        // Randomly choose the first player to be "it"
        uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % playerCount;
        it = playerList[randomIndex];
        lastTagTime = block.timestamp;

        emit NewGameStarted(it);
    }

    function chooseNewIt() internal {
        require(playerCount > 0, "No players available to choose 'it'");

        // Randomly choose a new player to be "it"
        uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % playerCount;
        it = playerList[randomIndex];
        lastTagTime = block.timestamp;

        emit ItTimeout(it);
    }

    function checkItTimeout() public {
        require(block.timestamp >= lastTagTime + tagTimeout, "Timeout has not occurred yet");

        // Choose a new player to be "it" if the timeout has occurred
        chooseNewIt();
    }

    function getPlayers() public view returns (address[] memory) {
        return playerList;
    }

    function getIt() public view returns (address) {
        return it;
    }
}
