# Bracket.bet

This project was created to decentralize betting platforms all throughout
the board.

Each user can create a tournament as well as bet on whichever tournament has been uploaded to the dApp

Oracle dependencies:

- Ownable.sol - OpenZeppelin
    - Context.sol - OpenZeppelin

- [BokkyPooBahsDateTimeLibrary.sol](https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/TestDateTime.sol)

Oracle functionality overview:

- Create a new event that is stored by ID in the blockchain

- Creat new matches that are stored on the blockchain and can be accessed to run other contracts
which will be used in the future to create a betting contract

- Be able to assign a winner of a match, as well as cancel the match if need be

- Be able to group matches by event ID