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


public struct ActionReply : Codable
{
	public var Action: String
	public var ActionArguments : [ActionArgumentValue] = []
	
	public init(Action: String)
	{
		self.Action = Action
	}
	
	public func encode(to encoder: Encoder) throws
	{
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Action, forKey: .Action)
		
		let arguments = ActionArguments.map( { value in
			value.ValueAsString
		})
		try container.encode( arguments, forKey: .ActionArguments )
		/*
		try container.encode(longitude, forKey: .longitude)
		
		var additionalInfo = container.nestedContainer(keyedBy: AdditionalInfoKeys.self, forKey: .additionalInfo)
		try additionalInfo.encode(elevation, forKey: .elevation)
		 */
	}
}


//	gr: don't make this encodable, the only choice here is to encode as an object
//		but we need the higher-up container to write only a value
public class ActionArgumentValue : /*Encodable,*/ Decodable, Equatable, Identifiable, Hashable, CustomStringConvertible
{
	var ValueAsString : String

	public static func == (lhs: ActionArgumentValue, rhs: ActionArgumentValue) -> Bool
	{
		lhs.ValueAsString == rhs.ValueAsString
	}
	
	public func hash(into hasher: inout Hasher)
	{
		hasher.combine(ValueAsString)
	}
	
	//	each value should be unique, so can use it as a key
	public var id : ObjectIdentifier
	{
		return ObjectIdentifier(self)
	}
	
	public var description: String
	{
		return ValueAsString
	}

	init()
	{
		ValueAsString = ""
	}
		
	required public init(from decoder: Decoder) throws
	{
		if let int = try? decoder.singleValueContainer().decode(Int.self) {
			ValueAsString = "\(int)"
			return
		}
		
		if let string = try? decoder.singleValueContainer().decode(String.self) {
			ValueAsString = string
			return
		}
		/*
		if let string = try? decoder.singleValueContainer().decode([Int].self) {
			self = .arrayOfInts(string)
			return
		}*/
		
		throw QuantumError.missingValue
	}

	/*
	public func encode(to encoder: Encoder) throws
	{
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(latitude, forKey: .latitude)
		try container.encode(longitude, forKey: .longitude)
		
		var additionalInfo = container.nestedContainer(keyedBy: AdditionalInfoKeys.self, forKey: .additionalInfo)
		try additionalInfo.encode(elevation, forKey: .elevation)
	}
	*/
	
	enum QuantumError:Error
	{
		case missingValue
	}
}

public struct ActionMeta : Decodable, CustomStringConvertible
{
	public var description: String
	{
		return "ActionMeta"
	}
	
	public var Key : String?
	//var Arguments : [[Int]]	//	array of an array in minesweeper!
	public var Arguments : [[ActionArgumentValue]]
	/*
	enum CodingKeys: String, CodingKey
	{
		case isAll = "is_all"
		case values, include
	}
	 */
}

//	https://stackoverflow.com/a/50257595/355753
//	json where we don't know the keys
//	Actions:{ Action1:{}, Action2:{}
public struct ActionList : Decodable
{
	public var Actions: [String: ActionMeta] = [:]
	

	struct ActionKey: CodingKey
	{
		var stringValue: String
		var intValue: Int?
		
		init?(stringValue: String)
		{
			self.stringValue = stringValue
		}

		init?(intValue: Int)
		{
			self.stringValue = "\(intValue)";
			self.intValue = intValue
		}
	}

	public init()
	{
	}
	
	//	manually decode object keys
	public init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: ActionKey.self)

		var actions = [String: ActionMeta]()
		
		for key in container.allKeys
		{
			if let model = try? container.decode(ActionMeta.self, forKey: key)
			{
				actions[key.stringValue] = model
			}
			else if let bool = try? container.decode(Bool.self, forKey: key)
			{
				//self.any = any
			}
		}

		self.Actions = actions
	}
	
}


public struct GameStateBase : Decodable
{
	public var GameType : String?
	public var Error : String?
	public var Actions : ActionList?
	//var BadMode : String?
	
	public init()
	{
		Error = nil
		GameType = nil
	}
	
	public init(Error: String)
	{
		self.Error = Error
	}
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
