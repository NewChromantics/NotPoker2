Not Poker v2
===========
- This is a framework for making async turn-based (eg. board or card) games. A 2nd implementation after NotPoker.
- Any game implementation is done "server" side with a class derived from `TGame`, and pretty much runs from one `async RunGame` function
- "Connected" players get state json, whenever the state changes, which may include a list of actions+params they can perform (eg. if it's their turn) and send a json in response.
	- This state may also include an error, if they previously submitted an illegal action, or say, they timed out and the server has moved along.
- Games should run essentially independently (so can be run client side, in html, swift, or anywhere we can execute async javascript)
- The "Lobby" (player meta, chat, connecting & disconnecting etc) is now abstracted away, a player will join (or leave) a game from their UID.
- The server, hosting the game, will do it's own "server side" verification of this UID (ie. check with the lobby platform, check for banned users etc)
- The client will probe a Lobby api to get their uid (ie, login) get & set player meta, chat etc.
