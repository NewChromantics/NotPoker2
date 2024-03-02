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
let QuotedFilename = "(\"|')(.+\\.js)('|\")";
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

func regexp_matches(_ text:String!, _ pattern:String!, _ options:NSRegularExpression.Options = NSRegularExpression.Options.caseInsensitive) -> [NSTextCheckingResult] {
		do {
			let regex = try NSRegularExpression(pattern: pattern, options: options)
			let nsString = text as NSString
			let results = regex.matches(in: text,options: [], range: NSMakeRange(0, nsString.length))
			return results
		} catch let error as NSError {
			print("invalid regex: \(error.localizedDescription)")
			return []
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
func Substring( _ string:String, start:Int, length:Int) throws -> String
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
	let stringEnd = string.index( string.startIndex, offsetBy: start+length )
	let range = string[stringStart...stringEnd]
	let returnString = String(range)

	return returnString
}

typealias Replacer = (_ match:String)->String?//if nil is returned then replacer closure didnt want to replace the match
	/**
	 * New, replaces with a closure
	 * TODO: ⚠️️ Try to performance test if accumulative substring is faster (you += before the match + the match and so on)
	 * EXAMPLE: Swift.print("bad wolf, bad dog, Bad sheep".replace("\\b([bB]ad)\\b"){return $0.isLowerCased ? $0 : $0.lowercased()})
	 */
func string_replace_regex(_ str:String, pattern:String, options:NSRegularExpression.Options = NSRegularExpression.Options.caseInsensitive,replacer:Replacer) -> String{
//        Swift.print("RegExp.replace")
		var str = str
	regexp_matches(str, pattern).reversed().forEach() {
			let range:NSRange = $0.range(at: 1)
//            Swift.print("range: " + "\(range)")
			
			let stringRange = strRange(str, range.location, len:range.length)
			let match:String = try! Substring(str, start:range.location, length:range.length)//swift 4 upgrade, was: str.substring(with: stringRange) //TODO: ⚠️️ reuse the stringRange to get the subrange here
//            Swift.print("match: " + "\(match)")
			if let replacment:String = replacer(match) {
				str.replaceSubrange(stringRange, with: replacment)
			}
		}
		return str
	}


func ConvertImports(Source:String,importFunctionName:String) throws -> String
{
	//	gr: we can probably reduce this down to one regex
	//	import<symbols>from<script><instruction end>
	if #available(macOS 13.0, *) 
	{
		let ImportPattern = "import(\\s)+from"

		func ImportReplacement(match:String) -> String?
		{
			return match
		}
		
		var ES5Source = string_replace_regex( Source, pattern: ImportPattern, replacer: ImportReplacement )
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
	Source = ConvertExports(Source: Source, exportSymbolName:exportSymbolName )
	return Source
}
