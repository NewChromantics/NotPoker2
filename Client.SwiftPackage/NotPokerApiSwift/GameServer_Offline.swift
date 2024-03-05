import SwiftUI
import JavaScriptCore
import Combine //	future


class GrahamsPromise<T>
{
	var result : T? = nil
	var error : Error? = nil
	
	
	public func Wait() async throws -> T
	{
		//	spin! yuck!
		while ( true )
		{
			await try! Task.sleep(nanoseconds: 1_000_000)
			if ( result != nil )
			{
				return result!
			}
			if ( error != nil )
			{
				throw error!
			}
		}
	}
	
	public func resolve(_ value:T)
	{
		result = value
	}
	
	public func reject(_ exception:Error)
	{
		error = exception
	}
}


//	the offline server runs a javascript game.... somehow!
//		- javascriptcore in swift & run the js?
//		- Popengine+jscore and use CAPI?
//		- Popengine+jscore and use websocket to local?
public class GameServer_Offline : GameServer
{
	//	server stuff
	var Server_GameModule : JavascriptGame
	var Server_GameInstance : String? = nil
	var Server_GameStartPromise = GrahamsPromise<String>()
	
	//	client stuff

	//	startup the offline game so we know it's usable
	public init(gameType:String) throws
	{
		Server_GameModule = try JavascriptGame("GameServer_Offline.js")
		
		Task
		{
			do
			{
				print("running new game server...")
				await try! RunGameServer(gameType)
				print("running new game server finished.")
			}
			catch
			{
				print("Game server error; \(error.localizedDescription)")
			}
		}
	}
	
	func RunGameServer(_ gameType:String) async throws
	{
		while ( true )
		{
			do
			{
				//	alloc a game
				Server_GameInstance = await try! Server_GameModule.CallAsync("Allocate('\(gameType)')");
				Server_GameStartPromise.resolve(Server_GameInstance!)
			}
			catch
			{
				Server_GameStartPromise.reject( error )
				//	rethrow
				throw error
			}
			print("Allocate() -> \(Server_GameInstance)")
			/*
			 function OnStateChanged()
			 {
			 const State = Game.GetPublicState();
			 LocalServer.Server_BroadcastState.call( LocalServer, State );
			 }
			 
			 const SendMoveAndWait = LocalServer.Server_SendMoveAndWait.bind(LocalServer);
			 const OnAction = LocalServer.Server_OnAction.bind(LocalServer);
			 
			 const GameResult = await Game.RunGame( SendMoveAndWait, OnStateChanged, OnAction );
			 */
			
			while ( true )
			{
				var GameState = try await Server_GameModule.CallAsync("WaitForNextGameState()")
				print("WaitForNextGameState() -> \(GameState)")

				//	if end of game, break
				await Task.sleep(100)
			}
			
			var GameResult = try await Server_GameModule.CallAsync("WaitForGameFinish()");
			print("GameResult -> \(GameResult)")
			
			Server_GameInstance = nil
			
			await Task.sleep(1*1000)
		}
	}
			
	
	public func Join(Player:PlayerUid) async throws
	{
		//	wait for javascript to bootup
		print("\(Player) joining game, waiting for bootup...")
		await try! Server_GameStartPromise.Wait()
		
		print("\(Player) joining game...")

		var AddResult = try await Server_GameModule.CallAsync("AddPlayer('\(Player.Uid)')")
		print("AddPlayer() -> \(AddResult)")
	}
	
	public func WaitForNextState() async throws
	{
		//	wait forever
		while ( true )
		{
			try await Task.sleep(nanoseconds: 1000*1_000_000)	//	1_000_000ns = 1ms
			print("Waiting for next state...")
		}
	}
	
	public func SendActionReply(_ Reply: ActionReply) throws
	{
		throw RuntimeError("Todo: SendActionReply to offline game")
	}
	
}

