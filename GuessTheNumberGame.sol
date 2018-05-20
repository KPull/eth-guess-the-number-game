pragma solidity ^0.4.23;

/** 
 *  A game where a player tries to guess a number between 1 and 10.
 *  Operator sets the bet amount which the player must send when making a guess.
 *  Operator must deposit 8 times the bet amount.
 *  If player guess, they get all the funds.
 *  Otherwise, the operator gets the funds.
 */
contract GuessTheNumberGame {
    
    event GameStarted(uint bet);
    event SecretNumberSubmitted(bytes32 secretNumber);
    event GuessSubmitted(address indexed player, uint guess);
    event ResultSubmitted(uint result);
    event PlayerWins(address indexed player);
    event OperatorWins(address indexed operator);
    
    enum State {
        WAITING_SECRET, WAITING_GUESS, WAITING_RESULT, OPERATOR_WIN, PLAYER_WIN
    }
    
    address public operator;
    address public player;
    State public state;
    uint256 public bet;
    
    bytes32 public secretNumber;
    uint public guess;
    uint public result; // This is not strictly needed: can use state instead
    
    modifier byOperator() {
        require(msg.sender == operator);
        _;
    }
    
    modifier byPlayer() {
        require(msg.sender == player);
        _;
    }
    
    modifier inState(State expected) {
        require(state == expected);
        _;
    }
    
    constructor(uint256 _bet) public {
        require(_bet > 0);
        
        operator = msg.sender;
        state = State.WAITING_SECRET;
        bet = _bet;
        
        emit GameStarted(bet);
        
        assert(getOperatorBet() > _bet);   // Protect against overflow
    }
    
    function submitSecretNumber(bytes32 _secretNumber) public payable byOperator inState(State.WAITING_SECRET) {
        require(msg.value == getOperatorBet());
        
        secretNumber = _secretNumber;
        moveToState(State.WAITING_GUESS);
        
        emit SecretNumberSubmitted(_secretNumber);
    }
    
    function submitGuess(uint _guess) public payable inState(State.WAITING_GUESS) {
        require(isValidNumber(_guess));
        require(msg.value == bet);
        
        guess = _guess;
        player = msg.sender;
        moveToState(State.WAITING_RESULT);
        
        emit GuessSubmitted(player, guess);
    }
    
    function submitResult(uint _result) public byOperator inState(State.WAITING_RESULT) {
        require(isValidNumber(_result));
        require(makeSecret(_result) == secretNumber);
        
        result = _result;
        emit ResultSubmitted(_result);
        
        if (result == guess) {
            moveToState(State.PLAYER_WIN);
            emit PlayerWins(player);
        } else {
            moveToState(State.OPERATOR_WIN);
            emit OperatorWins(player);
        }
    }
    
    function collectOperatorWinnings() public byOperator inState(State.OPERATOR_WIN) {
        selfdestruct(operator);
    }
    
    function collectPlayerWinnings() public byPlayer inState(State.PLAYER_WIN) {
        selfdestruct(player);
    }
    
    function makeSecret(uint _result) public pure returns (bytes32 _secretNumber) {
        return keccak256(_result);
    }
    
    function moveToState(State _state) private {
        state = _state;
    }
    
    function getOperatorBet() private view returns (uint256) {
        return bet * 8;
    }
    
    function isValidNumber(uint _guess) private pure returns (bool) {
        return _guess >= 1 && _guess <= 10;
    } 
    
}
