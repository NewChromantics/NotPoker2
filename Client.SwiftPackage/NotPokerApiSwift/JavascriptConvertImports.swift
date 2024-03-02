import Foundation

//	from https://github.com/NewChromantics/PopEngine/blob/master/src/JavascriptConvertImports.cpp

//	Popengine implements require() which makes an exports symbol for the module
//	and returns it (a module)
//	so imports need changing, and exports inside a file need converting

//	convert imports;
//		import * as Module from 'filename1'
//		import symbol from 'filename2'
//		import { symbol } from 'filename3'
//		import { symbol as NewSymbol } from 'filename4'
//	into
//		const Module = require('filename1')
//
//		const ___PrivateModule = require('filename2')
//		const symbol = ___PrivateModule.symbol;
//
//		const ___PrivateModule = require('filename3')
//		const symbol = ___PrivateModule.symbol;
//
//		const ___PrivateModule = require('filename4')
//		const NewSymbol = ___PrivateModule.symbol;


//	make a pattern for valid js symbols
let Symbol = "([a-zA-Z0-9_]+)";
let QuotedFilename = "('|\"|`)(.+\\.js)('|\"|`)";
let QuotedFilenamePopEngineJs = "(\"|')(.+\\/PopEngine\\.js)('|\")";
let Whitespace = "\\s+";
let OptionalWhitespace = "\\s*";
let Keyword = "(const|var|let|class|function|extends|async\\sfunction)";	//	prefixes which break up export, variable name etc

//	must be other cases... like new line and symbol? maybe we can use ^symbol ?
//	symbol( <-- function
//	symbol= <-- var definition
//	symbol; <-- var declaration
//	symbol{ <-- class
let VariableNameEnd = "(\\(|=|;|extends|\\{)";
/*
func ReplacementPattern2(std::stringstream& Output,std::smatch& Match) -> String
{
	//	import { $1 } from $2
	//	split symbols
	auto RawSymbolsString = Match[1].str();
	auto Filename = Match[2].str() + Match[3].str() + Match[4].str();
	
	Array<std::string> InputSymbols;
	Array<std::string> OutputSymbols;

	const std::string WhitespaceChars = " \t\n";
	

	auto AppendSymbol = [&](const std::string& Match,const char& Delin)
	{
		//	split `X as Y`
		//	to avoid matching as in class, split by whitespace, so we should have either 1 or 3 matches
		BufferArray<std::string,3> Input_As_Output;
		Soy::StringSplitByMatches( GetArrayBridge(Input_As_Output), Match, WhitespaceChars, false );

		//	no "as" in the middle
		if ( Input_As_Output.GetSize() == 1 )
		{
			Input_As_Output.PushBack( Input_As_Output[0] );
			Input_As_Output.PushBack( Input_As_Output[0] );
		}
		
		InputSymbols.PushBack( Input_As_Output[0] );
		//	as
		OutputSymbols.PushBack( Input_As_Output[2] );
		return true;
	};
	
	Soy::StringSplitByMatches( AppendSymbol, RawSymbolsString, ",", false );

	//	generate module name
	std::stringstream ModuleName;
	ModuleName << "_Module_";
	for ( auto s=0;	s<OutputSymbols.GetSize();	s++ )
		ModuleName << "_" << OutputSymbols[s];
	
	//	add module
	Output << "const " << ModuleName.str() << " = require(" << Filename << ");\n";
	
	//	add symbols
	for ( auto s=0;	s<OutputSymbols.GetSize();	s++ )
	{
		auto& InputSymbol = InputSymbols[s];
		auto& OutputSymbol = OutputSymbols[s];
		Output << "const " << OutputSymbol << " = " << ModuleName.str() << "." << InputSymbol << ";\n";
	}
}

std::string regex_replace_callback(const std::string& Input,std::regex Regex,std::function<void(std::stringstream&,std::smatch&)> Replacement)
{
	// Make a local copy
	std::string PendingInput = Input;

	// Reset resulting value
	std::stringstream Output;

	std::smatch Matches;
	while (std::regex_search(PendingInput, Matches, Regex))
	{
		// Build resulting string
		Output << Matches.prefix();
		Replacement( Output, Matches );
		
		//	next search the rest
		PendingInput = Matches.suffix();
	}
	
	//	If there is still a suffix, add it
	//Output << Matches.suffix();	//	gr: seems to be empty?
	//	add the remaining string that didn't match
	Output << PendingInput;
	
	return Output.str();
}
*/

func regexp_matches(_ text:String!, _ pattern:String!, _ options:NSRegularExpression.Options=NSRegularExpression.Options.caseInsensitive) throws -> [NSTextCheckingResult]
{
	do 
	{
		let regex = try NSRegularExpression(pattern: pattern, options: options)
		let nsString = text as NSString
		let results = regex.matches(in: text,options: [], range: NSMakeRange(0, nsString.length))
		return results
	}
	catch let error as NSError
	{
		throw RuntimeError("invalid regex: \(error.localizedDescription)")
	}
}

extension String
{
	func idx(_ index:Int) -> String.Index {
		let str = self
		return str.index(str.startIndex, offsetBy: index)/*Upgraded to swift 3-> was: startIndex.advancedBy*/
	}
}

func strRange(_ str:String,_ i:Int, len:Int)->Range<String.Index>
{
	let startIndex:String.Index = str.idx(i)
	let endIndex:String.Index = str.idx(i + len/* + 1*/)//+1 because swift 3 upgrade doesn't allow ... ranges
	let range = startIndex..<endIndex//swift 3 upgrade was-> startIndex...endIndex
	return range/*longhand -> Range(start: startIndex,end: endIndex)*/
}
func GetSubString( _ string:String, start:Int, length:Int) throws -> String
{
	if ( start < 0 )
	{
		throw RuntimeError("Substring out of range")
	}

	if ( start+length >= string.count )
	{
		throw RuntimeError("Substring out of range")
	}

	let lastIndex = start+length
	let stringStart = string.index( string.startIndex, offsetBy: start )
	let stringEnd = string.index( string.startIndex, offsetBy: start+length-1 )
	let range = string[stringStart...stringEnd]
	let returnString = String(range)

	return returnString
}


func StringFromRange(_ Haystack:String, needle:NSRange) throws -> String
{
	if ( needle.length == 0 )
	{
		return ""
	}
	return try! GetSubString( Haystack, start: needle.location, length: needle.length )
}

typealias Replacer = (_ match:String, _ captures:[String]) throws -> String

func string_replace_regex(_ str:String, pattern:String, options:NSRegularExpression.Options = NSRegularExpression.Options.caseInsensitive,replacer:Replacer) throws -> String
{
	var str = str
	//	gr: need to process in reverse, as the original string needs to be modified backwards
	let matches = try regexp_matches(str, pattern).reversed()
	matches.forEach()
	{
		match in
		
		let LineRange = match.range(at:0)
		let Line = try! StringFromRange( str, needle: LineRange )
		let CaptureCount = match.numberOfRanges-1
		var Captures : [String] = []
		for CaptureIndex in 0...CaptureCount-1
		{
			let CaptureRange = match.range(at:1+CaptureIndex)
			let Capture = try! StringFromRange( str, needle:CaptureRange )
			Captures.append( Capture )
		}

		let LineStrRange = strRange(str, LineRange.location, len:LineRange.length)
		let replacment = try! replacer( Line, Captures )
		str.replaceSubrange( LineStrRange, with: replacment)
	}
	return str
}


func string_regex_match_groups(_ str:String, pattern:String, options:NSRegularExpression.Options = NSRegularExpression.Options.caseInsensitive) throws -> [String]?
{
	var str = str
	//	gr: need to process in reverse, as the original string needs to be modified backwards
	let matches = try regexp_matches(str, pattern)
	//	expecting only one match
	if ( matches.count != 1 )
	{
		throw RuntimeError("Too many regex matches")
	}
	
	let match = matches[0]
	let LineRange = match.range(at:0)
	let Line = try! StringFromRange( str, needle: LineRange )
	let CaptureCount = match.numberOfRanges-1
	var Captures : [String] = []
	for CaptureIndex in 0...CaptureCount-1
	{
		let CaptureRange = match.range(at:1+CaptureIndex)
		let Capture = try! StringFromRange( str, needle:CaptureRange )
		Captures.append( Capture )
	}
	return Captures

}



//import RegexBuilder
@available(macOS 13.0, *)
func FilenameToModuleSymbol(_ filename:String, uidSuffix:Int) -> String
{
	var Symbol = filename;
	//	replace non-symbol chars with underscores
	//	todo: use regex
	Symbol.replace("/",with:"_")
	Symbol.replace(".",with:"_")
	return "__Module_Exports_From_\(Symbol)_\(uidSuffix)"
}

struct ImportSymbol
{
	static let Default = "default"
	var importingSymbol : String	//	if null then we use the module's whole export list
	var variable : String
}

extension String 
{
	func trim() -> String
	{
		return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
	}
}

func TrimString(_ str:String) -> String
{
	var Trimmed = str
	Trimmed.trim()
	return Trimmed
}

func ExtractSymbols(_ symbolsString:String,moduleExportsSymbol:String) throws -> [ImportSymbol]
{
	func SplitSingleSymbol(origSymbolString:String) throws -> ImportSymbol
	{
		var symbolString = origSymbolString
		symbolString = symbolString.trim()
		let InsideBraces = symbolString.starts(with: "{")
		//	if we're not importing symbols, then we are just importing the default
		let ImportingSymbols = InsideBraces
		symbolString = symbolString.trimmingCharacters(in: ["{","}"])

		//	are we renaming the imported symbol?
		//	x as y
		//	* as z
		//	*
		//	abc
		let SplitByAs = symbolString.components(separatedBy:" as ").map(TrimString)
		if ( SplitByAs.count > 2 )
		{
			throw RuntimeError("import symbol with as, split more than once")
		}
		
		var ImportingSymbol = SplitByAs[0]
		if ( ImportingSymbol == "*" )
		{
			ImportingSymbol = "\(moduleExportsSymbol)"
		}
		else if ( InsideBraces )
		{
			ImportingSymbol = "\(moduleExportsSymbol).\(ImportingSymbol)"
		}
		else
		{
			ImportingSymbol = "\(moduleExportsSymbol).\(ImportSymbol.Default)"
		}

		var Variable = ImportingSymbol
		if ( SplitByAs.count == 2 )
		{
			Variable = SplitByAs[1]
		}
		else
		{
			Variable = SplitByAs[0]
		}
		
		return ImportSymbol(importingSymbol: ImportingSymbol, variable: Variable)
	}
	
	var SymbolStrings = symbolsString.components(separatedBy: [","])
	return try! SymbolStrings.map(SplitSingleSymbol)
}


func ConvertImports(Source:String,importFunctionName:String) throws -> String
{
	//	gr: we can probably reduce this down to one regex
	//	import<symbols>from<script><instruction end>
	if #available(macOS 13.0, *) 
	{
		let Whitespace = "\\s*";
		let Quote = "[\\\"'`]"
		let ImportPattern = "import(.+)from\(Whitespace)\(Quote){1}(.+)\(Quote){1}"

		//	to make some things simpler when importing the same file, but don't want conflicting symbols, add a counter
		var ImportCounter = 0
		func ImportReplacement(match:String,captures:[String]) throws -> String
		{
			let SymbolsString = captures[0];
			let Filename = captures[1]
			let ModuleSymbol = FilenameToModuleSymbol(Filename,uidSuffix:ImportCounter)
			let Symbols = try! ExtractSymbols( SymbolsString, moduleExportsSymbol: ModuleSymbol )
			
			//print("Matched \(match)<----")
			//print("  Symbols=\(SymbolsString)<----")
			//print("  ExtractedSymbols=\(Symbols)<----")
			//print("  Filename=\(captures[1])<----")
			
			let ModuleObjectReplacement = "const \(ModuleSymbol) = \(JavascriptModule.ImportModuleFunctionSymbol)(`\(Filename)`);"
			//print("  ModuleObjectReplacement=\(ModuleObjectReplacement)<----")
			
			var ReplacementString = ModuleObjectReplacement
			//ReplacementString += "\n"
			for symbol in Symbols
			{
				ReplacementString += "const \(symbol.variable) = \(symbol.importingSymbol); "
				//ReplacementString += "\n"
			}
			//print(ReplacementString+"\n\n")

			ImportCounter += 1
			
			return ReplacementString
		}
		
		var ES5Source = try! string_replace_regex( Source, pattern: ImportPattern, replacer: ImportReplacement )
		return ES5Source
	}
	else
	{
		throw RuntimeError("No regex")
	}


	/*
	//	special case to catch PopEngine.js, which is how we import in web
	std::stringstream ImportPatternPop;	ImportPatternPop << "import" << Whitespace << "Pop" << Whitespace << "from" << Whitespace << QuotedFilenamePopEngineJs;
	std::string ReplacementPatternPop("/* import Pop from $1$2$3 */");
	
	//	import * as X from QUOTEFILENAMEQUOTE
	std::stringstream ImportPattern0;	ImportPattern0 << "import" << Whitespace << "\\*" << Whitespace << "as" << Whitespace << Symbol << Whitespace << "from" << Whitespace << QuotedFilename;
	std::string ReplacementPattern0("const $1 = require($2$3$4);");

	//	import X from QUOTEFILENAMEQUOTE
	std::stringstream ImportPattern1;	ImportPattern1 << "import" << Whitespace << Symbol << Whitespace << "from" << Whitespace << QuotedFilename;
	std::string ReplacementPattern1("const $1_Module = require($2$3$4); const $1 = $1_Module.default;");
	
	//	import {X} from QUOTEFILENAMEQUOTE
	std::stringstream ImportPattern2;	ImportPattern2 << "import" << OptionalWhitespace << "\\{([^}]*)\\}" << OptionalWhitespace << "from" << Whitespace << QuotedFilename;
	//	gr: needs special case to replaceop
	//std::string ReplacementPattern2("/* symbols: $1 */");
	
	//	$0 whole string match
	//	$1 capture group 0 etc
	Source = std::regex_replace(Source, std::regex(ImportPatternPop.str()), ReplacementPatternPop );
	Source = std::regex_replace(Source, std::regex(ImportPattern0.str()), ReplacementPattern0 );
	Source = std::regex_replace(Source, std::regex(ImportPattern1.str()), ReplacementPattern1 );
	Source = regex_replace_callback(Source, std::regex(ImportPattern2.str()), ReplacementPattern2 );
	
	//std::Debug << std::endl << std::endl << "new source; "  << std::endl << Source << std::endl<< std::endl;
	 */
	return Source;
}


//	export let A = B;		let A = ... exports.A = A;
//	export function C(...
//	export const D;
//	export
func ConvertExports(Source:String,exportSymbolName:String) -> String
{
	return Source
	
	func ExportReplacement(match:String,captures:[String]) throws -> String
	{
		print("export match: "+match)
		return "/*\(match)*/"
	}
	
	let Whitespace = "\\s*";
	let ExportPattern = "[\\s|^]export\(Whitespace)(default)?\(Whitespace)"
	var ES5Source = try! string_replace_regex( Source, pattern: ExportPattern, replacer: ExportReplacement )
	
	print(ES5Source)
	
	return ES5Source
	
	/*
	//	moving export to AFTER the declaration is hard.
	//	so instead, find all the exports, declare them all at the end
	//	of the file, and then just clean the declarations
	auto DefaultMaybe = "\\s*(default)?";

	//	export DECL VAR=
	std::stringstream ExportPattern0;	ExportPattern0 << "export" << DefaultMaybe << Whitespace << Keyword << Whitespace << Symbol << OptionalWhitespace << VariableNameEnd;
	std::string ReplacementPattern0("$2 $3 $4");

	//	export Symbol;
	std::stringstream ExportPattern1;	ExportPattern1 << "export" << DefaultMaybe << Whitespace << Symbol << OptionalWhitespace << ";";
	std::string ReplacementPattern1("/*export$1 $2;*/");

	//	get all the export symbols
	Array<std::string> ExportSymbols;
	std::string DefaultExportSymbol;
	
	auto ExtractSymbolsFromRegex = [&](std::stringstream& RegexPattern,int SymbolMatchIndex)
	{
		int DefaultMatchIndex = 1;
		std::smatch SearchMatch;
		std::string SearchingSource = Source;
		auto PatternString = RegexPattern.str();
		while ( std::regex_search( SearchingSource, SearchMatch, std::regex(PatternString) ) )
		{
			//auto IsDefault = SearchMatch[DefaultMatchIndex].str().length() > 0;
			auto IsDefault = SearchMatch[DefaultMatchIndex].matched;
			auto Symbol = SearchMatch[SymbolMatchIndex].str();
			auto Matched = SearchMatch[0].matched;
			//	gr: this is sometimes matching empty groups (per line?)
			if ( Symbol.length() )
				ExportSymbols.PushBack( Symbol );
			if ( IsDefault )
				DefaultExportSymbol = Symbol;
				
			SearchingSource = SearchMatch.suffix();
		}
	};
	ExtractSymbolsFromRegex(ExportPattern0,3);
	ExtractSymbolsFromRegex(ExportPattern1,2);
	

	std::stringstream NewExports;
	if ( !ExportSymbols.IsEmpty() )
	{
		if ( DefaultExportSymbol.empty() )
			throw Soy::AssertException("Missing default export");
			
		NewExports << "\n\n//	Generated exports\n";
		
		//	will generate bad syntax if no default symbol
		if ( !DefaultExportSymbol.empty() )
			NewExports << "exports.default = " << DefaultExportSymbol << ";\n";
			
		for ( auto e=0;	e<ExportSymbols.GetSize();	e++ )
		{
			NewExports << "exports." << ExportSymbols[e] << " = " << ExportSymbols[e] << ";\n";
		}
	}

	//	now replace the matches (ie, strip out export & default)
	Source = std::regex_replace(Source, std::regex(ExportPattern0.str()), ReplacementPattern0 );
	Source = std::regex_replace(Source, std::regex(ExportPattern1.str()), ReplacementPattern1 );
	
	Source += NewExports.str();
	
	//std::Debug << "Replaced exports...\n\n" << Source << std::endl;
	*/
	return Source;
}


//	convert ES6 imports to custom import & export symbols
public func RewriteES6ImportsAndExports(_ originalScript:String,importFunctionName:String,exportSymbolName:String) -> String
{
	var Source = originalScript
	Source = try! ConvertImports(Source:Source, importFunctionName:importFunctionName )
	Source = try! ConvertExports(Source: Source, exportSymbolName:exportSymbolName )
	return Source
}
