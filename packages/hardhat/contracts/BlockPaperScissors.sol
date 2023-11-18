// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BlockPaperScissors is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _matchIds;
    Counters.Counter private _nftIds;

    enum Move { None, Rock, Paper, Scissors }
    uint256 private constant MAX_BLOCKS_FOR_REVEAL = 10;

    struct Player {
        string displayName;
        uint256 totalWins;
        uint256 nftId;
    }

    struct GameMatch {
        uint256 id;
        address player1;
        address player2;
        bytes32 commit1;
        bytes32 commit2;
        Move reveal1;
        Move reveal2;
        uint256 commitBlockNumber;
        bool isResolved;
    }

    struct NFTMetadata {
        uint256 blockWins;
        uint256 paperWins;
        uint256 scissorsWins;
        uint256 totalMatches;
    }

    mapping(address => Player) public players;
    mapping(uint256 => GameMatch) public matches;
    mapping(uint256 => NFTMetadata) public nftMetadatas;
   
    mapping(address => uint256) private activeMatches;

    constructor() ERC1155("https://blockpaperscissorc.xyz/metadata/{id}.json") {}

   // Utility view functions
    function getPlayerData(address playerAddress) public view returns (Player memory) {
        return players[playerAddress];
    }

    function getMatchData(uint256 matchId) public view returns (GameMatch memory) {
        return matches[matchId];
    }

    function getNFTMetadata(uint256 nftId) public view returns (NFTMetadata memory) {
        return nftMetadatas[nftId];
    }

    function isPlayerRegistered(address playerAddress) public view returns (bool) {
        return bytes(players[playerAddress].displayName).length != 0;
    }

    function getTotalMatches() public view returns (uint256) {
        return _matchIds.current();
    }

    function isPlayerInMatch(uint256 matchId, address playerAddress) public view returns (bool) {
        GameMatch memory gameMatch = matches[matchId];
        return gameMatch.player1 == playerAddress || gameMatch.player2 == playerAddress;
    }

    function isMatchResolved(uint256 matchId) public view returns (bool) {
        return matches[matchId].isResolved;
    }

    function registerPlayer(string memory displayName) public {
        require(bytes(players[msg.sender].displayName).length == 0, "Player already registered");
        
        _nftIds.increment();
        uint256 newNftId = _nftIds.current();

        players[msg.sender] = Player(displayName, 0, newNftId);
        _mint(msg.sender, newNftId, 1, "");
        nftMetadatas[newNftId] = NFTMetadata(0, 0, 0, 0);
    }

    function initiateMatch() public returns (uint256) {
        // Check if the player is already in an active match
        require(activeMatches[msg.sender] == 0 || matches[activeMatches[msg.sender]].isResolved, "Player is already in an active match");

        _matchIds.increment();
        uint256 newMatchId = _matchIds.current();

        // Set the current match as the player's active match
        activeMatches[msg.sender] = newMatchId;

        matches[newMatchId] = GameMatch(newMatchId, msg.sender, address(0), 0, 0, Move.None, Move.None, block.number, false);
        return newMatchId;
    }

    function joinMatch(uint256 matchId) public {
        GameMatch storage gameMatch = matches[matchId];
        require(gameMatch.player2 == address(0), "Match already has two players");
        gameMatch.player2 = msg.sender;
        activeMatches[msg.sender] = matchId;
    }

    function commitMove(uint256 matchId, bytes32 hashedMove) public {
        GameMatch storage gameMatch = matches[matchId];
        require(gameMatch.player1 == msg.sender || gameMatch.player2 == msg.sender, "Player not part of the Match");
        if (gameMatch.player1 == msg.sender) {
            gameMatch.commit1 = hashedMove;
        } else {
            gameMatch.commit2 = hashedMove;
        }
    }

    function revealMove(uint256 matchId, Move playerMove, bytes32 secret) public {
        GameMatch storage gameMatch = matches[matchId];
        require(block.number <= gameMatch.commitBlockNumber + MAX_BLOCKS_FOR_REVEAL, "Reveal period has ended");
        bytes32 hashedMove = keccak256(abi.encodePacked(playerMove, secret));
        if (gameMatch.player1 == msg.sender) {
            require(hashedMove == gameMatch.commit1, "Move does not match the committed move");
            gameMatch.reveal1 = playerMove;
        } else if (gameMatch.player2 == msg.sender) {
            require(hashedMove == gameMatch.commit2, "Move does not match the committed move");
            gameMatch.reveal2 = playerMove;
        }

        if (gameMatch.reveal1 != Move.None && gameMatch.reveal2 != Move.None) {
            resolveMatch(matchId);
        }
    }

    function resolveMatch(uint256 matchId) internal {
        GameMatch storage gameMatch = matches[matchId];
        require(!gameMatch.isResolved, "GameMatch already resolved");

        address winner;
        if (gameMatch.reveal1 == Move.None || gameMatch.reveal2 == Move.None) {
            winner = gameMatch.reveal1 == Move.None ? gameMatch.player2 : gameMatch.player1;
        } else {
            Move winnerThrow = determineWinner(gameMatch.reveal1, gameMatch.reveal2);
            winner = winnerThrow == gameMatch.reveal1 ? gameMatch.player1 : gameMatch.player2;
        }

        players[winner].totalWins += 1;
        updateStatsAndMetadata(winner, gameMatch.reveal1);
        gameMatch.isResolved = true;

        activeMatches[matches[matchId].player1] = 0;
        activeMatches[matches[matchId].player2] = 0;
        
        nftMetadatas[players[winner].nftId].totalMatches += 1;
    }

    function determineWinner(Move throw1, Move throw2) private pure returns (Move) {
        if (throw1 == throw2) {
            return Move.None;
        }
        if ((throw1 == Move.Rock && throw2 == Move.Scissors) ||
            (throw1 == Move.Paper && throw2 == Move.Rock) ||
            (throw1 == Move.Scissors && throw2 == Move.Paper)) {
            return throw1;
        } else {
            return throw2;
        }
    }

    function updateStatsAndMetadata(address player, Move winningThrow) private {
        uint256 nftId = players[player].nftId;
        if (winningThrow == Move.Rock) {
            nftMetadatas[nftId].blockWins += 1;
        } else if (winningThrow == Move.Paper) {
            nftMetadatas[nftId].paperWins += 1;
        } else if (winningThrow == Move.Scissors) {
            nftMetadatas[nftId].scissorsWins += 1;
        }
    }
}
