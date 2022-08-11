## User Story

    This is an Auction Smart contract as you must have noticed.

    When a user wants to atart an auction, they need;
    1. the auction nft token address and the token id they wnat to auction
    2. the price thet want their nft bid to start from

    Here is what happens when the bid starts 
    the auction contract factory would deploy a new auction contract for that bid using create two, also specificing the detail need for the auction contract constructor

    Now the user can interact with the contract from using the address specified during the bid contract deployment 
    the opreations they can carryout is starting the bid and the withdraw functionality

    then the normal users (not admin) would be able to hit the function make bid


    TODO:

