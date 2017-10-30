const Game = artifacts.require('./GuessTheNumberGame.sol');
const PlayersPool = artifacts.require('./PlayersPool.sol');

const ether = amount => new web3.BigNumber(web3.toWei(amount, 'ether'));

contract('GuessTheNumberGame', async function([operator, player, anotherPlayer]) {
	const playerBet = ether(1);
	const operatorBet = ether(8);
	const theNumber = 5;
	const wrongNumber = 4;

	it("player win", async function() {
		const playerBalanceBefore = await web3.eth.getBalance(player);
		const operatorBalanceBefore = await web3.eth.getBalance(operator);

		const game = await Game.new(playerBet);

		const secretNumber = await game.makeSecret(theNumber);

		const tx1 = await game.submitSecretNumber(secretNumber, { from: operator, value: operatorBet });
		assert(tx1.logs[0].args['secretNumber'], secretNumber);

		const tx2 = await game.submitGuess(theNumber, { from: player, value: playerBet });
		assert(tx2.logs[0].args['player'], player);
		assert(tx2.logs[0].args['guess'], theNumber);

		const tx3 = await game.submitResult(theNumber, { from: operator });
		assert(tx3.logs[0].args['result'], theNumber);
		assert.ok(tx3.logs.find(e => e.event === 'PlayerWins'));

		await game.collectPlayerWinnings({ from: player });

		const playerBalanceAfter = await web3.eth.getBalance(player);
		const operatorBalanceAfter = await web3.eth.getBalance(operator);

		assert.ok(operatorBalanceAfter.eq(web3.BigNumber.min(operatorBalanceBefore, operatorBalanceAfter)));
		assert.ok(playerBalanceBefore.eq(web3.BigNumber.min(playerBalanceBefore, playerBalanceAfter)));
	});

	it("operators wins", async function() {
		const playerBalanceBefore = await web3.eth.getBalance(player);
		const operatorBalanceBefore = await web3.eth.getBalance(operator);

		const game = await Game.new(playerBet);

		const secretNumber = await game.makeSecret(theNumber);

		await game.submitSecretNumber(secretNumber, { from: operator, value: operatorBet });

		await game.submitGuess(wrongNumber, { from: player, value: playerBet });

		await game.submitResult(theNumber, { from: operator });

		await game.collectOperatorWinnings({ from: operator });

		const playerBalanceAfter = await web3.eth.getBalance(player);
		const operatorBalanceAfter = await web3.eth.getBalance(operator);

		assert.ok(operatorBalanceBefore.eq(web3.BigNumber.min(operatorBalanceBefore, operatorBalanceAfter)));
		assert.ok(playerBalanceAfter.eq(web3.BigNumber.min(playerBalanceBefore, playerBalanceAfter)));
	});

	it("collaborative wins", async function() {
		const game = await Game.new(playerBet);

		const secretNumber = await game.makeSecret(theNumber);

		await game.submitSecretNumber(secretNumber, { from: operator, value: operatorBet });

		// let first user bet 80% and another 20%
		const firstPlayerBet = playerBet.div(5).mul(4);
		const anotherPlayerBet = playerBet.div(5);
		const expectedPlayerReward = playerBet.plus(operatorBet).div(5).mul(4);
		const expectedAnotherPlayerReward = playerBet.plus(operatorBet).div(5);

		const playersPool = await PlayersPool.new(theNumber, game.address);

		await playersPool.bet({from: player, value: firstPlayerBet});

		await playersPool.bet({from: anotherPlayer, value: anotherPlayerBet.minus(1)});

		await playersPool.bet({from: anotherPlayer, value: 1});

		await game.submitResult(theNumber, { from: operator });

		await playersPool.claimVictory({ from: player });

		const tx1 = await playersPool.withdrawReward({from: player});
		const tx2 = await playersPool.withdrawReward({from: anotherPlayer});

		assert(tx1.logs[0].args['reward'], expectedPlayerReward);
		assert(tx2.logs[0].args['reward'], expectedAnotherPlayerReward);
	});
});