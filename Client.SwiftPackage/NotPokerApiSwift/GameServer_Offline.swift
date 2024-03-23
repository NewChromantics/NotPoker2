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

			var GameResult = try await Server_GameModule.CallAsync("Server_RunGameServer()");
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
	
	public func WaitForNextState() async throws -> String
	{
		let NewState = try await Server_GameModule.CallAsync("Client_WaitForNextState()")
		print("Client_WaitForNextState() -> \(NewState)")
		return NewState
	}
	
	public func SendActionReply(_ Reply: ActionReply) throws
	{
		let ReplyJsonBytes = try! JSONEncoder().encode(Reply)
		let ReplyJson = String(data: ReplyJsonBytes, encoding: .utf8)!
		print("reply action json sending to js; \(ReplyJson) ")
		
		try Server_GameModule.Call("Client_SendActionReply(`\(ReplyJson)`)");
	}
	
}

