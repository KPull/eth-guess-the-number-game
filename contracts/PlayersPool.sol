pragma solidity ^0.4.11;

import './GuessTheNumberGame.sol';

contract PlayersPool {
    enum State { Open, Closed, Victory }

    State public state;

    modifier onlyInState(State _state) {
        require(_state == state);
        _;
    }

    function moveToState(State _state) private {
        state = _state;
    }

    event RewardWithdraw(address player, uint reward);

    GuessTheNumberGame game;
    mapping(address => uint) bets;

    uint public weiRaised;
    uint public weiWon;

    uint guessedNumber;

    function PlayersPool(uint _guessedNumber, address _game) {
        guessedNumber = _guessedNumber;
        game = GuessTheNumberGame(_game);
        state = State.Open;
    }

    function bet() payable onlyInState(State.Open) {
        bets[msg.sender] += msg.value;
        weiRaised += msg.value;

        if(weiRaised >= game.bet()) {
            game.submitGuess.value(weiRaised)(guessedNumber);
            moveToState(State.Closed);
        }
    }

    function claimVictory() public onlyInState(State.Closed) {
        game.collectPlayerWinnings();

        weiWon = this.balance;

        moveToState(State.Victory);
    }

    function withdrawReward() public onlyInState(State.Victory) {
        uint reward = weiWon * bets[msg.sender] / weiRaised;

        require(reward > 0);
        require(this.balance >= reward);

        assert(msg.sender.send(reward));

        bets[msg.sender] = 0;

        RewardWithdraw(msg.sender, reward);
    }
}