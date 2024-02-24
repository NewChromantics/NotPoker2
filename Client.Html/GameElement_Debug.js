/*
	this is a base web component for NotPoker games

	this also implements a debug-webcomponent which works for any game

*/
import {CreatePromise,Yield} from '../Games/PromiseQueue.js'

const DebugElementCss=
`
	:root
	{
		font: "Helvetica";
	}

	.Json
	{
		font: monospace, "Courier New";
		font-size:	0.8em;
		opacity: 0.5;
	}

	*
	{
		min-width: 1em;
		min-height: 1em;
		xxbackground:red;
		margin: 0.1em;
		padding: 0.1em;
	}

	.Title
	{
		font-size:	1.5em;
		border-bottom:	1px solid #eee;
	}

	#Actions > .Action
	{
		border:	1px solid #eee;
		padding:	1em;
		zbackground: lime;
	}
`;

class GameElement_Base extends HTMLElement
{
	SetState(State)
	{
		throw `GameElement needs to handle new state ${JSON.stringify(State)}`;
	}
}

export default class GameElement_Debug extends GameElement_Base
{
	#StateElement;
	#ActionsElement;
	#StyleElement;
	#State = {};
	#CurrentActionMeta = null;
	
	constructor()
	{
		super();
		
		
	}
	
	static get ElementName()
	{
		return 'game-debug';
	}
	
	get StyleCss()
	{
		return DebugElementCss;
	}
	
	connectedCallback()
	{
		this.attachShadow({mode: 'open'});
		//this.shadowRoot.appendChild(template.content.cloneNode(true));
		this.#InitialiseDom( this.shadowRoot );
	}
	
	#InitialiseDom(RootElement)
	{
		this.#StyleElement = document.createElement('style');
		RootElement.appendChild(this.#StyleElement);
		this.#StyleElement.textContent = this.StyleCss;
		
		this.#StateElement = document.createElement('div');
		RootElement.appendChild(this.#StateElement);
		this.#StateElement.id = 'State';
		
		this.#ActionsElement = document.createElement('div');
		RootElement.appendChild(this.#ActionsElement);
		this.#ActionsElement.id = 'Actions';
		
		this.UpdateActionElements(null);
	}
	
	UpdateActionElements(OnActionTriggered)
	{
		//	clear all children
		this.#ActionsElement.textContent = '';
		
		if ( !this.#CurrentActionMeta )
			return;
	
		//	if there's no callback, this is not for this player
		const ForThisPlayer = (OnActionTriggered !=null);
		
		const Title = document.createElement('label');
		this.#ActionsElement.appendChild(Title);
		Title.className = 'Title';
		Title.textContent = `Action on player ${this.#CurrentActionMeta.Player}`;
		
		const Json = document.createElement('div');
		this.#ActionsElement.appendChild(Json);
		Json.className = 'Json';
		Json.textContent = JSON.stringify(this.#CurrentActionMeta);
		
		//	make a button for each action
		for ( let ActionKey in this.#CurrentActionMeta.Actions )
		{
			const ActionDiv = document.createElement('div');
			this.#ActionsElement.appendChild(ActionDiv);
			ActionDiv.className = 'Action';
			
			const Meta = this.#CurrentActionMeta.Actions[ActionKey];
			const Arguments = Meta.Arguments;
			
			const Label = document.createElement('label');
			ActionDiv.appendChild(Label);
			Label.textContent = `${ActionKey}`;
			
			//	make argument choices
			const ArgumentElements = [];
			for ( let ArgumentOptions of Arguments )
			{
				const Select = document.createElement('select');
				ActionDiv.appendChild(Select);
				function MakeOption(Value)
				{
					const Option = document.createElement('option');
					Option.value = Value;
					Option.textContent = `${Value}`;
					Select.appendChild(Option);
				}
				ArgumentOptions.forEach( MakeOption );
				ArgumentElements.push(Select);
			}
			
			//	dont make a button if the player can't trigger it
			if ( OnActionTriggered )
			{
				const Button = document.createElement('button');
				ActionDiv.appendChild(Button);
				Button.textContent = `${ActionKey}`;
				
				function OnClicked()
				{
					function GetArgumentValue(Select)
					{
						const Value = Select.value;
						return Value;
					}
					const ArgumentValues = ArgumentElements.map(GetArgumentValue);
					OnActionTriggered( ActionKey, ArgumentValues );
				}
				Button.onclick = OnClicked;
			}
		}
		
	}
	
	UpdateStateElements()
	{
		//	clear
		this.#StateElement.textContent = '';
		//this.#StateElement.textContent = JSON.stringify(this.#State);

		const Title = document.createElement('label');
		this.#StateElement.appendChild(Title);
		Title.className = 'Title';
		Title.textContent = `Game State`;
		
		const Json = document.createElement('div');
		this.#StateElement.appendChild(Json);
		Json.className = 'Json';
		Json.textContent = JSON.stringify(this.#State);

		//	make a section for each bit of meta
		for ( let StateKey in this.#State )
		{
			const StateItemDiv = document.createElement('div');
			this.#StateElement.appendChild(StateItemDiv);
			StateItemDiv.classList.add('StateItem',StateKey);
			
			const Label = document.createElement('label');
			StateItemDiv.appendChild(Label);
			Label.textContent = `${StateKey}`;
			
			const Value = this.#State[StateKey];
			const ValueElement = document.createElement('span');
			StateItemDiv.appendChild(ValueElement);
			ValueElement.textContent = `${JSON.stringify(Value)}`;
		}
	}
	
	async SetState(State)
	{
		console.log(`New State`,State);
		
		//	clear actions
		await this.SetAction(null,false);
		
		//	update graphics
		this.#State = State;
		this.UpdateStateElements();
	}
	
	async SetAction(Action,ForThisPlayer)
	{
		console.log(`New Action`,Action);
		this.#CurrentActionMeta = Action;
		if ( !this.#CurrentActionMeta )
			return;
		
		const ReplyPromise = CreatePromise();
		
		function OnActionTriggered(Action,ActionArguments)
		{
			const Reply = {};
			Reply.Action = Action;
			Reply.ActionArguments = ActionArguments;
			ReplyPromise.Resolve( Reply );
		}
		
		//	gr: need to detect when the keys have no actions
		//		we currently get .BadMove when there's an error. We probably should change
		//		this so the new actions come with meta, rather than 2 steps
		const AnyUserActions = Object.keys(Action).filter( Key => Key!='BadMove'&&Key!='Player' ).length > 0;

		const WaitingForTrigger = ForThisPlayer && AnyUserActions;
		this.UpdateActionElements( WaitingForTrigger ? OnActionTriggered : null );
		
		if ( !WaitingForTrigger )
		{
			await Yield(2*1000);
			ReplyPromise.Resolve();
		}
		
		return await ReplyPromise;
	}
		
}

	
window.customElements.define( GameElement_Debug.ElementName, GameElement_Debug );
