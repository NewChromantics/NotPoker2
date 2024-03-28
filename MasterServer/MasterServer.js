/*
	The master server is an public opaque API to the services.
 
	This should be able to scale horizontally.
*/
import * as Express from 'express';
import * as Api from './Api.js'
import * as Params from './Params.js'



const CorsOrigin = Params.GetParam('CorsOrigin','*' );
const ErrorStatusCode = Params.GetInt('ErrorStatusCode',400);
const StaticFilesPath = Params.GetParam('StaticFilesPath','./');
const ListenPort = Params.GetInt('PORT',8888);	//	$PORT -> env PORT on google cloud
try
{
	const AllEnv = JSON.stringify(process.env,null,'\t');
	//console.log(`env (all) ${AllEnv}`);
}
catch(e)
{
	console.log(`env (all) error -> ${e}`);
}


//	gr: for sloppy, we can only expose one port (I think), so we share the http server
const SharingHttpServer = true;

//	artifact server
const HttpServerApp = Express.default();
//HttpServerApp.get('/', function (req, res) { res.redirect('/index.html') });
//HttpServerApp.get('/', function (req, res) { res.redirect('/index.html') });
HttpServerApp.get('/', HandleRoot );

HttpServerApp.get(`/${Api.EndPoint_ListPublicGameChoices}`,HandleListPublicGameChoices);
HttpServerApp.get(`/${Api.EndPoint_JoinPublicGame}`,HandleJoinPublicGame);
HttpServerApp.use('/', Express.static(StaticFilesPath));

const HttpServer = HttpServerApp.listen( ListenPort, () => console.log( `Http server on ${JSON.stringify(HttpServer.address())}` ) );



async function HandleRequest(Request,Response,Functor)
{
	try
	{
		const Output = await Functor();
		
		if ( typeof Output == typeof 'string' )
		{
			Response.statusCode = 200;
			Response.setHeader('Content-Type','text/plain');
			Response.setHeader('Access-Control-Allow-Origin',CorsOrigin);
			Response.end(Output);
			return;
		}
		else if ( typeof Output == typeof {} )
		{
			const Json = JSON.stringify( Output, null, '\t' );
			Response.setHeader('Content-Type','application/json');
			Response.setHeader('Access-Control-Allow-Origin',CorsOrigin);
			Response.end(Json);
			return;
		}
		throw `Unhandled output type(${typeof Output}); ${Output}`;
	}
	catch (e)
	{
		console.log(`HandleRegister error -> ${e}`);
		Response.statusCode = ErrorStatusCode;
		Response.setHeader('Content-Type','text/plain');
		Response.end(`Error ${e}`);
	}
}


async function HandleRoot(Request,Response)
{
	async function Run()
	{
		return 'Wrong turn at Albuquerque?';
	}
	await HandleRequest( Request, Response, Run );
	
}



async function HandleListPublicGameChoices(Request,Response)
{
	async function Run()
	{
		const GameChoices = {};
		GameChoices.GameTypes = ['Minesweeper'];
		return GameChoices;
	}
	await HandleRequest( Request, Response, Run );
	
}


async function HandleJoinPublicGame(Request,Response)
{
	async function Run()
	{
		throw `No servers running`;
	}
	await HandleRequest( Request, Response, Run );
	
}
