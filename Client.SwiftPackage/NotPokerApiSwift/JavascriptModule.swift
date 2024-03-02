import JavaScriptCore
import Combine



//	JSContext with extra built-ins, import/export support extra and error handling
extension JSContext
{
	var context : JSContext
	{
		return self
	}
	
	var contextGroup : JSContextGroupRef
	{
		return JSContextGetGroup(context.jsGlobalContextRef)!
	}
	
	var filename : String
	{
		return name ?? ""
	}

	var lastError : String?
	{
		if ( context.exception == nil )
		{
			return nil
		}
		else
		{
			//	debugDescription always says Optional()
			//let errorMessage = context.exception.debugDescription ?? ""
			return context.exception.description
		}
	}
	
	//	make a functor (@@convention = obj-c block) to add to the context
	static let ImportModuleFunctor: @convention(block) (String) -> (JSValue?) =
	{
		importFilename in
		let context = JSContext.current()!
		let contextGroup = context.contextGroup
		
		do
		{
			let importPath = JavascriptModule.ResolveFilePath( filename:importFilename, parentFilename: context.filename )

			//let expandedPath = NSString(string: importpath).expandingTildeInPath
			print("Importing \(importPath) from \(context.filename)")
			let expandedPath = Bundle.main.url(forResource: importPath, withExtension: "")

			if ( expandedPath == nil )
			{
				throw RuntimeError("File \(expandedPath) not found")
			}
			//let fileContent = try String(contentsOfFile: expandedPath)
			let fileContent = try String(contentsOf: expandedPath!)
			
			
			//	create a new context
			let NewGlobalContext = JSGlobalContextCreateInGroup(contextGroup, nil)
			let NewContext = JSContext(jsGlobalContextRef: NewGlobalContext)!
			//NewContext.name = "\(context.name!) / \(importpath)"
			NewContext.name = importPath

			//let NewContext = JSContext()!
			let NewContextExports = NewContext.InitModuleSupport()
			
			NewContext.evaluateES6Script(fileContent)
			if ( NewContext.exception != nil )
			{
				throw RuntimeError(NewContext.lastError!)
			}
			
			print("Imported module \(expandedPath!)")
			
			return NewContextExports
			//return nil
		}
		catch
		{
			//	we cannot throw, set the exception
			let exceptionString = "\(JavascriptModule.ImportModuleFunctionSymbol)(\(importFilename)) failed; \(error.localizedDescription)"
			print(exceptionString)
			let exceptionValue = JSValue.init(newErrorFromMessage: exceptionString, in: context)
			context.exception = exceptionValue
			return nil
		}
	}
	
	
	//	make a functor (@@convention = obj-c block) to add to the context
	static let consolelogfunctor: @convention(block) (String) -> (JSValue?) =
	{
		message in
		let context = JSContext.current()!
		
		let name = context.name ?? "unnamed"
		print("JS \(name): \(message)")
		return nil
	}
	

	//	returns exports object, akin to the exported "module" in normal js
	func InitModuleSupport() -> JSValue
	{
		let global = context.globalObject!
		
		
		let NewContextExports = JSValue(newObjectIn: context)!
		global.setObject( NewContextExports, forKeyedSubscript: JavascriptModule.ModuleExportsSymbol as NSString)
		//global.setValue( NewContextExports, forProperty: ModuleExportsSymbol as NSString)

		//	register global functors
		global.setObject( JSContext.ImportModuleFunctor, forKeyedSubscript: JavascriptModule.ImportModuleFunctionSymbol as NSString)
		
		let console = JSValue(newObjectIn: context)
		console?.setValue( JSContext.consolelogfunctor, forProperty: "log" )
		global.setObject( console, forKeyedSubscript: "console" as NSString)

		
		let ExceptionHandler = { [self] (ctx: JSContext!, value: JSValue!) in
			
			let stacktrace = value.objectForKeyedSubscript("stack")?.toString() ?? ""
			let lineNumber = value.objectForKeyedSubscript("line")?.toInt32() ?? -1
			let column = value.objectForKeyedSubscript("column")?.toInt32() ?? -1
			let errorMeta = "Method=\(stacktrace); Line=\(lineNumber); column=\(column);"

			let ExceptionValue = value?.toString() ?? "???"
			
			let exceptionString = "Exception: \(ExceptionValue) \(errorMeta)"
			//print(exceptionString)
			let exceptionValue = JSValue.init(newErrorFromMessage: exceptionString, in: context)
			ctx.exception = exceptionValue!
		}
		
		//	gr: don't need this? just check exception after every call?
		//		if we use this exception handler, we need to set context's .exception
		context.exceptionHandler = ExceptionHandler
		
		return NewContextExports
	}

	func evaluateES6Script(_ originalScript:String) -> JSValue?
	{
		let ES5Script = RewriteES6ImportsAndExports(originalScript, importFunctionName: JavascriptModule.ImportModuleFunctionSymbol, exportSymbolName: JavascriptModule.ModuleExportsSymbol )
		return self.evaluateScript( ES5Script )
	}
	

}




public class JavascriptModule
{
	static let ImportModuleFunctionSymbol = "__ImportModule"
	static let ModuleExportsSymbol = "__exports"
	
	var context : JSContext
	var contextGroup : JSContextGroupRef

	//	given ./hello.js in parent Folder/file.js
	//	we should resolve to Folder/hello.js
	static func ResolveFilePath(filename:String, parentFilename:String) -> String
	{
		//	get path out of parent
		var parentPath = parentFilename.components(separatedBy: "/")
		//	pop filename from parent
		parentPath.removeLast()
		parentPath.append( filename )
		var filePath = parentPath.joined(separator: "/")
		return filePath
	}
	
	public init(_ script:String, moduleName:String) throws
	{
		contextGroup = JSContextGroupCreate()
		let globalcontext = JSGlobalContextCreateInGroup(contextGroup, nil)
		context = JSContext(jsGlobalContextRef: globalcontext)
		context.name = moduleName
				
		context.InitModuleSupport()

		//	load script - always returns undefined
		let Result = context.evaluateES6Script(script)
		
		if ( context.exception != nil )
		{
			throw RuntimeError(context.lastError!)
		}
	}
	
	public func Call(_ functionAndArgs:String) throws -> JSValue
	{
		//let Code = "\(functionName)()"
		let Code = functionAndArgs
		//	call a func
		let output = context.evaluateScript(Code)
		if ( context.exception != nil )
		{
			throw RuntimeError(context.lastError!)
		}
		
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
		
		/*
		let quadruple: @convention(block) (Int) -> Int = { input in
			return input * 4
		}
		context.setObject(quadruple, forKeyedSubscript: "quadruple" as NSString)
		 */
		
		
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
