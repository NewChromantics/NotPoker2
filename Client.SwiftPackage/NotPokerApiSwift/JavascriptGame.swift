import JavaScriptCore
import Combine


public class JavascriptModule
{
	var context : JSContext
	var lastError : String? = nil

	public init(_ script:String) throws
	{
		context = JSContext()
		
		context.exceptionHandler = { [self] (ctx: JSContext!, value: JSValue!) in
			// type of String
			let stacktrace = value.objectForKeyedSubscript("stack").toString()
			// type of Number
			let lineNumber = value.objectForKeyedSubscript("line")
			// type of Number
			let column = value.objectForKeyedSubscript("column")
			let moreInfo = "in method \(stacktrace)Line number in file: \(lineNumber), column: \(column)"
			lastError = "Javascript Exception: \(value) \(moreInfo)"
		}
		
		//	load script - always returns undefined
		let Result = context.evaluateScript(script)
		
		if ( lastError != nil )
		{
			throw RuntimeError(lastError!)
		}
	}
	
	public func Call(_ functionAndArgs:String) throws -> JSValue
	{
		//let Code = "\(functionName)()"
		let Code = functionAndArgs
		//	call a func
		let output = context.evaluateScript(Code)
		
		//	if this returns a promise, warn
		
		return output!
	}

	public func CallAsync(_ functionAndArgs:String) async throws -> String
	{
		let JavascriptPromise = try Call(functionAndArgs)
		
		var SwiftPromise : Future<String,Error>.Promise? = nil
		
		//	create a future and capture the promise
		let SwiftFuture = Future<String,Error>()
		{
			promise in
			SwiftPromise = promise
			//promise(Result.success("Hello")
		}
		
		//	add js callbacks for .then and .catch and fulfill the promise
		//SwiftPromise!(Result.success("Hello"))
		let onFulfilled: @convention(block) (JSValue) -> Void =
		{
			value in
			let ValueString = value.toString() ?? ""
			SwiftPromise!(Result.success(ValueString))
		}
		
		let onRejected: @convention(block) (JSValue) -> Void =
		{
			value in
			let ValueError = RuntimeError( value.toString() )
			SwiftPromise!(Result.failure( ValueError ) )
			//let error = NSError(domain: key, code: 0, userInfo: [NSLocalizedDescriptionKey : "\($0)"])
			//continuation.resume(throwing: error)
			//continuation.resume(throwing: RuntimeError("async exception") )
		}
		
		let promiseArgs = [unsafeBitCast(onFulfilled, to: JSValue.self), unsafeBitCast(onRejected, to: JSValue.self)]
		
		//	chain promise with .then() and .catch()
		JavascriptPromise.invokeMethod("then", withArguments: promiseArgs)
		
		
		//return await SwiftPromise
				
		if #available(macOS 12.0, *)
		{
			let Result = await try SwiftFuture.value
			return Result
		}
		else
		{
			throw RuntimeError("Require macos 12 and above")
		}
		
		/*
		//	check result is a Promise
		return try await withCheckedThrowingContinuation{
			continuation in
			
			//continuation.resume(returning: "Hello")
			
			let onFulfilled: @convention(block) (JSValue) -> Void =
			{
				continuation.resume(returning: "Result")
			}
			
			let onRejected: @convention(block) (JSValue) -> Void =
			{
				//let error = NSError(domain: key, code: 0, userInfo: [NSLocalizedDescriptionKey : "\($0)"])
				//continuation.resume(throwing: error)
				//continuation.resume(throwing: RuntimeError("async exception") )
			}
			
			let promiseArgs = [unsafeBitCast(onFulfilled, to: JSValue.self), unsafeBitCast(onRejected, to: JSValue.self)]
			
			//	chain promise with .then() and .catch()
			//Promise.invokeMethod("then", withArguments: promiseArgs)
		}
		 */
	}

}


public class JavascriptGame
{
	var module : JavascriptModule
	
	public init(_ filenameWithoutExtensionInBundle:String) throws
	{
		let scriptUrl = Bundle.main.url(forResource: filenameWithoutExtensionInBundle, withExtension: "js")!
		let script = try! String(contentsOf: scriptUrl)
		module = try JavascriptModule( script )
		
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

