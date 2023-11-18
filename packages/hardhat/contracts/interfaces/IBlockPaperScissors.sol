// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlockPaperScissors {
    struct Player {
        string displayName;
        uint256 totalWins;
        uint256 nftId;
    }

    struct Match {
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

    function registerPlayer(string calldata displayName) external;

    function initiateMatch() external returns (uint256);

    function joinMatch(uint256 matchId) external;

    function commitThrow(uint256 matchId, uint256 playerThrow) external;

    function resolveMatch(uint256 matchId) external;

    // Add any other external/public functions that you want to expose via the interface
}
