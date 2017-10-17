# Guess The Number Game in Solidity

In this smart contract, written in Solidity, we implement a simple game where the Player attempts to guess the secret number (from 1 to 10) chosen by the Operator. When deploying the contract, the Operator chooses the Player's bet amount. They then submit the chosen number, or rather, its hash along with 8 times the agreed bet amount. The ether sent will be held by the contract in escrow until the end of the game.

The Player will then submit their guess along with the bet amount. Likewise, the player's bet will be held in escrow until the end of the game. In the final phase, the Operator will submit the real result: the smart contract will verify that the submitted number matches the hash previously submitted and determine the winner. If the Player guessed correctly, they can then withdraw all the contract funds; otherwise, the Operator can withdraw all the funds.

## Exercises

The smart contract has a couple of problems? Can you fix them?

* The hashed number is not enough to keep the number secret as the Player can brute force search the numbers 1 to 10 to find the correct hash. Can you modify the contract so that it also takes a [long salt message](https://en.wikipedia.org/wiki/Salt_(cryptography)) when hashing the secret number from the Operator?
* The Operator can choose not to reveal the real result, ensuring that the contract remains pending forever. Add a deadline by which the Operator must reveal the result. If the Operator does not submit the result at the end by the deadline, then the Player is considered the winner and they can withdraw all the funds at any time.

## Challenge

Finally, here's a challenge if you would like to take your Solidity skills further. Two Players would like to take on the Operator's game by splitting the bet and then splitting any potential winnings. WITHOUT changing the original contract, arrange for this to be done in a fair and transparent manner.

_Hint_: Write another contract for the players to deposit their share of the bet. The contract will play the game and submit a guess, and then collects any winnings and distributes it equally among the players.
