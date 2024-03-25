import {Yield} from '../Games/PromiseQueue.js'
import {PromiseQueue,CreatePromise} from '../Games/PromiseQueue.js'




export default class LocalServerInterface
{
	#Server_Game;	//	current game instance
	#Server_PendingPlayerActions = {};	//	[PlayerUid] = Promise waiting to be fulfilled
	
	//	for multi local players, this needs to be a queue per client
	#Client_StateChangedQueue = new PromiseQueue('Client_StateChangedQueue');
	#Client_PlayerUid;
	
	get RunningGame()
	{
		if ( !this.#Server_Game )
			throw `Accessing .RunningGame and no game running`;
		return this.#Server_Game;
	}
	
	async Client_WaitForNextState()
	{
		return await this.#Client_StateChangedQueue.WaitForNext();
	}
	
	async Client_Connect(PlayerUid)
	{
		if ( !this.#Server_Game )
			throw `No game running`;
			
		if ( !PlayerUid )
			throw `Connect without player uid`;
			
		if ( this.#Client_PlayerUid )
			throw `Local player is already registered (${this.#Client_PlayerUid})`;
			
		const Result = await this.#Server_Game.AddPlayer(PlayerUid);
		
		//	set only if successfully joined
		this.#Client_PlayerUid = PlayerUid;
		return Result;
	}
	
	Client_SendActionReply(Action,ActionArguments)
	{
		const Reply = {};
		Reply.Action = Action;
		Reply.ActionArguments = ActionArguments;
		
		const PlayerUid = this.#Client_PlayerUid;
		if ( !this.#Server_PendingPlayerActions.hasOwnProperty(PlayerUid) )
		{
			throw `There's no pending player action`;
		}
		this.#Server_PendingPlayerActions[PlayerUid].Resolve( Reply );
	}
	
	
	async Server_SetGame(Game)
	{
		this.#Server_Game = Game;
	}
	
	
	async Server_SendMoveAndWait(PlayerUid,Move)
	{
		//return await Room.SendToPlayerAndWaitForReply('Move', Player, Move );
		if ( this.#Server_PendingPlayerActions.hasOwnProperty(PlayerUid) )
		{
			throw `There's already a pending promise for player ${PlayerUid} for new action`;
		}
		
		console.log(`Server_SendMoveAndWait`);
		const NewPromise = CreatePromise();
		this.#Server_PendingPlayerActions[PlayerUid] = NewPromise;
		
		//	notify player they have something to do (+state?)
		this.#Client_StateChangedQueue.Push(Move);
		
		//	wait for reply
		console.log(`Server waiting for reply...`);
		const Reply = await NewPromise;
		console.log(`Server got reply: ${JSON.stringify(Reply)}`);

		//	clear promise
		delete this.#Server_PendingPlayerActions[PlayerUid];
		
		return Reply;
	}
	
	async Server_BroadcastState(State)
	{
		//Room.SendToAllPlayers('State',State);
		this.#Client_StateChangedQueue.Push(State);
	}
	
	async Server_OnAction(Action)
	{
		this.#Client_StateChangedQueue.Push(Action);
	}
}



const LocalServer = new LocalServerInterface();


//	The below are naked module functions for easy swiftui usage

async function Allocate(GameName)
{
	const Module = __ImportModule(`../Games/${GameName}.js`);
	//console.log(`imported module; ${JSON.stringify(Module)}`);
	//console.log(`imported module keys; ${Object.keys(Module)}`);
	const GameConstructor = Module.default;
	console.log(`Allocating game; ${GameConstructor.name}`);
	const NewGame = new GameConstructor( console.log );
	
	LocalServer.Server_SetGame( NewGame );

	return NewGame;
}

async function Server_RunGameServer()
{
	const Game = LocalServer.RunningGame;
	
	//	wait for game to finish
	function OnStateChanged()
	{
		const State = Game.GetPublicState();
		LocalServer.Server_BroadcastState.call( LocalServer, State );
	}
	
	function SendMoveAndWait(PlayerUid,Move)
	{
		//	add state to output
		//	gr: maybe needs to be in more generic code...
		const State = Game.GetPublicState();
		const Message = Object.assign( {}, Move, State );
		return LocalServer.Server_SendMoveAndWait.call(LocalServer, PlayerUid, Message );
	}
	
	function OnAction(Action)
	{
		//	add state to output
		//	gr: maybe needs to be in more generic code...
		const State = Game.GetPublicState();
		const Message = Object.assign( {}, Action, State );
		return LocalServer.Server_OnAction.call(LocalServer, Message );
	}
		
	await Game.WaitForEnoughPlayers();
	const GameResult = await Game.RunGame( SendMoveAndWait, OnStateChanged, OnAction );
	
	LocalServer.Server_SetGame( null );
	await Yield(1*1000);
	
	return GameResult;
}

async function Client_WaitForNextState()
{
	console.log(`Client_WaitForNextState...`);
	const NewState = await LocalServer.Client_WaitForNextState();
	return JSON.stringify(NewState);
}

function Client_SendActionReply(ReplyJson)
{
	const Reply = JSON.parse(ReplyJson);
	LocalServer.Client_SendActionReply( Reply.Action, Reply.ActionArguments );
}

async function AddPlayer(PlayerUid)
{
	return await LocalServer.Client_Connect(PlayerUid);
}
