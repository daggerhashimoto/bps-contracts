// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BlockPaperScissors is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _matchIds;
    Counters.Counter private _nftIds;

    uint256 private constant ROCK = 1;
    uint256 private constant PAPER = 2;
    uint256 private constant SCISSORS = 3;

    struct Player {
        string displayName;
        uint256 totalWins;
        uint256 nftId;
    }

    struct GameMatch {
        uint256 id;
        address player1;
        address player2;
        uint256 throw1;
        uint256 throw2;
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

    constructor() ERC1155("https://game-api.example.com/metadata/{id}.json") {}

    function registerPlayer(string memory displayName) public {
        require(bytes(players[msg.sender].displayName).length == 0, "Player already registered");
        
        _nftIds.increment();
        uint256 newNftId = _nftIds.current();

        players[msg.sender] = Player(displayName, 0, newNftId);
        _mint(msg.sender, newNftId, 1, "");  // Minting one NFT per player

        nftMetadatas[newNftId] = NFTMetadata(0, 0, 0, 0);  // Initializing NFT metadata
    }

    function initiateMatch() public returns (uint256) {
        _matchIds.increment();
        uint256 newMatchId = _matchIds.current();
        matches[newMatchId] = GameMatch(newMatchId, msg.sender, address(0), 0, 0, false);
        return newMatchId;
    }

    function joinMatch(uint256 matchId) public {
        GameMatch storage gameMatch = matches[matchId];
        require(gameMatch.player2 == address(0), "GameMatch already has two players");
        gameMatch.player2 = msg.sender;
    }

    function commitThrow(uint256 matchId, uint256 playerThrow) public {
        GameMatch storage gameMatch = matches[matchId];
        require(gameMatch.player1 == msg.sender || gameMatch.player2 == msg.sender, "Player not part of the GameMatch");
        if (gameMatch.player1 == msg.sender) {
            gameMatch.throw1 = playerThrow;
        } else {
            gameMatch.throw2 = playerThrow;
        }
    }

    function resolveMatch(uint256 matchId) public {
        GameMatch storage gameMatch = matches[matchId];
        require(!gameMatch.isResolved, "GameMatch already resolved");
        require(gameMatch.throw1 != 0 && gameMatch.throw2 != 0, "Both players must commit their throws");

        uint256 winnerThrow = determineWinner(gameMatch.throw1, gameMatch.throw2);
        address winner;
        if (winnerThrow == gameMatch.throw1) {
            winner = gameMatch.player1;
            players[winner].totalWins += 1;
            updatePlayerStatsAndNFTMetadata(winner, gameMatch.throw1);
        } else if (winnerThrow == gameMatch.throw2) {
            winner = gameMatch.player2;
            players[winner].totalWins += 1;
            updatePlayerStatsAndNFTMetadata(winner, gameMatch.throw2);
        }

        gameMatch.isResolved = true;
        nftMetadatas[players[winner].nftId].totalMatches += 1;
    }

    function determineWinner(uint256 throw1, uint256 throw2) private pure returns (uint256) {
        if (throw1 == throw2) {
            return 0; // A tie
        }
        if ((throw1 == ROCK && throw2 == SCISSORS) ||
            (throw1 == PAPER && throw2 == ROCK) ||
            (throw1 == SCISSORS && throw2 == PAPER)) {
            return throw1; // Player 1 wins
        } else {
            return throw2; // Player 2 wins
        }
    }

    function updatePlayerStatsAndNFTMetadata(address player, uint256 winningThrow) private {
        uint256 nftId = players[player].nftId;
        if (winningThrow == ROCK) {
            nftMetadatas[nftId].blockWins += 1;
        } else if (winningThrow == PAPER) {
            nftMetadatas[nftId].paperWins += 1;
        } else if (winningThrow == SCISSORS) {
            nftMetadatas[nftId].scissorsWins += 1;
        }
    }
}
