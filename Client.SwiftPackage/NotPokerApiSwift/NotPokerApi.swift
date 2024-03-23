import SwiftUI
import JavaScriptCore

struct RuntimeError: LocalizedError 
{
	let description: String

	init(_ description: String) {
		self.description = description
	}

	var errorDescription: String? {
		description
	}
}



//	wrapper for a string, but strongly typed
public struct PlayerUid
{
	public var Uid : String
	
	public init(_ Name:String)
	{
		Uid = "\(Name)_Uid"
	}
}

public struct PlayerMeta
{
	public var Uid : PlayerUid
	public var Name : String
	//	icons, colours, etc
}

public struct ActionReply
{
	public var Action : String
	
	//	gr; this can be multiple types! as we typically send json... this may need to change so server always takes strings :/
	public var Arguments : [String]
}

/*
	The lobby is the API to user login, player data etc, using whatever service underneath
*/
public class Lobby
{
	public func AuthoriseUser(PlayerName:String) async throws -> PlayerUid
	{
		return PlayerUid(PlayerName)
	}
	
	public func GetPlayerMeta(Player:PlayerUid) async throws -> PlayerMeta
	{
		return PlayerMeta( Uid: Player, Name: "Users Name")
	}
}


/*
	The main interface to a game is connecting to a "Server" (a server could also be local)

	Then waiting for state & actions
*/
public protocol GameServer
{
	func Join(Player:PlayerUid) async throws
	
	func WaitForNextState() async throws -> String
	
	func SendActionReply(_ Reply: ActionReply) throws
}


public class GameServer_Null : GameServer
{
	public init()
	{
	}
	
	public func Join(Player:PlayerUid) async throws
	{
		throw RuntimeError("GameServer_Null::Join")
	}
	
	public func WaitForNextState() async throws -> String
	{
		throw RuntimeError("GameServer_Null::WaitForNextState")
	}
	
	public func SendActionReply(_ Reply: ActionReply) throws
	{
		throw RuntimeError("GameServer_Null::SendActionReply")
	}
	
}
