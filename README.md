- `registerPlayer(displayName: string)`: Registers a new player with a unique display name and mints an NFT for their game stats. Use this function for new player onboarding.

- `initiateMatch()`: Starts a new game match and returns its unique ID. Call this when a player wants to start a new match.

- `joinMatch(matchId: uint256)`: Allows a second player to join an existing match. Use this for allowing players to join ongoing matches.

- `commitMove(matchId: uint256, hashedMove: bytes32)`: Players commit their move in a hashed form. Implement when players make their move, ensuring the move remains secret.

- `revealMove(matchId: uint256, playerMove: enum Move, secret: bytes32)`: Players reveal their move, verifying against the commit hash. Use a timer to prompt players to reveal their move within N blocks.

#### Utility Functions for Frontend

- `getPlayerData(playerAddress: address)`: Returns Player struct (displayName: string, totalWins: uint256, nftId: uint256). Display player information and statistics.

- `getMatchData(matchId: uint256)`: Returns GameMatch struct. Show details of a match including player participation and status.

- `getNFTMetadata(nftId: uint256)`: Returns NFTMetadata struct. Display NFT-related statistics like wins per move type.

- `isPlayerRegistered(playerAddress: address)`: Returns Boolean. Verify if a user is already registered.

- `getTotalMatches()`: Returns Total number of matches (uint256). Display statistics like total matches played on the platform.

- `isPlayerInMatch(matchId: uint256, playerAddress: address)`: Returns Boolean. Determine if a specific player is in a particular match.

- `isMatchResolved(matchId: uint256)`: Returns Boolean. Check if a match has been resolved.
