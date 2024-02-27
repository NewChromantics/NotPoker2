import JavaScriptCore	//	for Bundle.


public class JavascriptGame
{
	var module : JavascriptModule
	
	public init(_ filenameWithoutExtensionInBundle:String) throws
	{
		let scriptUrl = Bundle.main.url(forResource: filenameWithoutExtensionInBundle, withExtension: "js")
		if ( scriptUrl == nil )
		{
			throw RuntimeError("Failed to find bundle file \(filenameWithoutExtensionInBundle)")
		}
		
		let script = try! String(contentsOf: scriptUrl!)
		module = try JavascriptModule( script, moduleName: "Game" )
	}
	
	public func Call(_ functionAndArgs:String) throws -> String
	{
		let Result = try module.Call(functionAndArgs)
		//return "\(Result)"
		return Result.toString()
	}
	
	public func CallAsync(_ functionAndArgs:String) async throws -> String
	{
		let Result = try await module.CallAsync(functionAndArgs)
		return Result//.toString()
	}
}

