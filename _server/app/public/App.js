
export default class App{

	loading = document.getElementById("loading");
	content = document.getElementById("content");

	levels = new Map();
	categories = new Map();
	level = '';
	help = false;
	io = io();

	constructor(){

	}

	async begin(){

		this.refresh();

		const left = this.content.querySelector("#controls");
		const refresh = left.querySelector(".refresh");
		const clean = left.querySelector(".clean");
		const help = document.querySelector("#left div.help");
		refresh.addEventListener('click', () => {

			if( refresh.disabled )
				return;
			refresh.disabled = true;
			this.refresh();
			setTimeout(() => { refresh.disabled = false; }, 1e3);

		});

		clean.addEventListener('click', () => {
			if( clean.disabled )
				return;
			clean.disabled = true;
			setTimeout(() => { clean.disabled = false; }, 1e3);
			this.fetch('Fwd', ['Clean']);

		});

		help.addEventListener('click', () => {
			this.help = true;
			this.drawLevel();
		});

		this.io.on('connect', () => {
			console.log("Connected to websocket");
			let url = window.location.hash;
			if( url.startsWith('#') )
				url = url.slice(1);
			this.io.emit('hookup', {
				hud : url
			});
		});
		this.io.on('Refresh', () => {
			this.refresh();
		});

	}

	async refresh(){

		let ini = await this.fetch('Fwd', ['Ini']);
		let subData = ini.data;
		if( !subData.success || !ini.success ){
			this.loading.classList.remove('hidden');
			this.content.classList.add('hidden');
			this.loading.innerText = 'Failed to load, try resetting your HUD';
			return;
		}

		const meta = subData.data[0];
		this.levels = new Map();
		this.categories = new Map();

		for( let cat of meta.cat )
			this.categories.set(cat.l, new Category(cat));
		for( let level of meta.lv ){
			if( !this.level )
				this.level = level.o;
			this.levels.set(level.o, new Level(level));
		}
		this.loading.classList.add('hidden');
		this.content.classList.remove('hidden');

		this.drawMenu();
		this.drawLevel();

	}

	async fetch( task, args ){

		let url = window.location.hash;
		if( url.startsWith('#') )
			url = url.slice(1);
		url = new URL(url);
		let host = url.host.split('.');
		if( host.at(-1) !== "io" && host.at(-2) !== "secondlife" )
			return;

		const req = await fetch('/api', {
			method : 'POST',
			headers : {
				'Content-Type' : 'application/json'
			},
			body : JSON.stringify({
				task : task,
				args : args,
				hud : url
			})
		});
		const out = await req.json();
		return out;

	}

	getCategory( label ){
		return this.categories.get(label);
	}
	getLevel( obj ){
		if( !obj )
			obj = this.level;
		return this.levels.get(obj);
	}


	onLevelClicked( event ){
		let obj = event.currentTarget.dataset.obj;
		this.setActiveLevel(obj);
	}

	async onLaunchLevel( event ){

		const button = event.currentTarget;
		if( button.disabled )
			return;

		let obj = button.dataset.obj;
		button.disabled = true;
		setTimeout(() => { button.disabled = false; }, 1e3);
		await this.fetch('Fwd', ['Launch', obj]); 

	}

	drawMenu(){

		const left = this.content.querySelector("#left > div.content");

		let levels = Array.from(this.levels.values());
		levels.sort((a,b) => {
			if( a.category !== b.category )
				return a.category < b.category ? -1 : 1;
			if( a.name === b.name )
				return 0;
			return a.name < b.name ? -1 : 1;
		});

		left.replaceChildren();

		let preCat;

		for( let level of this.levels.values() ){
			
			let cat = this.getCategory(level.category);
			if( !cat )
				cat = new Category();

			let color = cat.color;
			if( color.startsWith('#') )
				color = color.slice(1);
			let r = parseInt(color.slice(0,2), 16);
			let g = parseInt(color.slice(2,4), 16);
			let b = parseInt(color.slice(4,6), 16);
			r = Math.min(255, r+25), g = Math.min(255, g+25), b = Math.min(255, b+25);
			let startColor = `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
			
			r = parseInt(color.slice(0,2), 16);
			g = parseInt(color.slice(2,4), 16);
			b = parseInt(color.slice(4,6), 16);
			r = Math.max(0, r-100), g = Math.max(0, g-100), b = Math.max(0, b-100);
			let textColor = `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;


			if( cat !== preCat ){
				makeEl("h3", {
					"text" : String(cat.label).toUpperCase(),
					"class" : "category",
					"style" : 'color:'+textColor
				}, left);
				preCat = cat;
			}

			
			let c = ["level", "inputButton"];
			if( level.obj === this.level )
				c.push("active");

			let style = 'background:linear-gradient(to bottom, '+startColor+' 0%, #'+color+' 100%); color:'+textColor;
			let div = makeEl("div", {
				"text" : level.name,
				"class" : c,
				"dataset" : {obj:level.obj},
				"style" : style
			}, left);
			div.addEventListener("click", this.onLevelClicked.bind(this));
			
		}

		let div = makeEl("div", {
			"text" : "Search Marketplace",
			"class" : ["inputButton"],
			"style" : 'background:linear-gradient(to bottom, #FFF 0%, #DDD 100%)'
		}, left);
		div.addEventListener("click", () => {
			window.location = "https://marketplace.secondlife.com/en-US/products/search?utf8=%E2%9C%93&search%5Bkeywords%5D=xmod+level&search%5Bcategory_id%5D=&search%5Bmaturity_level%5D=GMA";
		});

	}

	setActiveLevel( obj, drawLevel = true ){

		this.help = false;
		this.level = obj;
		this.drawMenu();
		if( drawLevel )
			this.drawLevel();

	}

	drawHelp(){

		document.querySelectorAll("#left div.level").forEach(e => e.classList.remove("active"));

		const right = this.content.querySelector("#right");
		right.replaceChildren();

		let wrap = makeEl("div", {
			class : "help"
		}, right);
		makeEl("h1", {
			text : "Help"
		}, wrap);

		makeEl("p", {
			text : "To host a level, select the level in the menu to the left. Then click Launch Level. This will spawn the level above you in your current sim, and teleport you to the level controller."
		}, wrap);

		makeEl("h3", {
			text : "Level Controller"
		}, wrap);

		makeEl("p", {
			text : "The level controller looks different depending on the game mode you are playing, but usually has a list of players above it. Click the level controller to manage the level:",
		}, wrap);

		let list = makeEl("ul", {
			class : "levelController"
		}, wrap);

		makeEl("li", {text : "[Rst Players] Kicks all players from the game."}, list);
		makeEl("li", {text : "[Clean Up] Cleans up all non static objects. Use the clean up button in the HUD to fully clear a level."}, list);
		makeEl("li", {text : "[INV. ALL] Invites all nearby players to the level."}, list);
		makeEl("li", {text : "[INV. Player] Invites a specific player to the level."}, list);
		makeEl("li", {text : "[REM. Player] Removes a player."}, list);
		makeEl("li", {text : "[START GAME] Starts the game with the active players."}, list);
		let maintenance = makeEl("li", {text : "[Maintenance] Takes you to the maintenance menu."}, list);
		let subList = makeEl("ul", {
			class : "maintenance"
		}, maintenance);
		makeEl("li", {text : "[Assets] Updates the level assets from your HUD."}, subList);
		makeEl("li", {text : "[Scripts] Updates all scripts and assets from your HUD."}, subList);
		makeEl("li", {text : "[Players] Makes sure the players have the latest attachments from the level."}, subList);

		makeEl("h3", {
			text : "FAQ"
		}, wrap);

		let faq = makeEl("ul", {
			class : "faq"
		}, wrap);
		makeEl("li", {html : "Does the host have to be in the level?<br /><i>No, but they have to remain in their sim as their HUD is used in running the level.</i>"}, faq);

	}

	drawLevel(){

		if( this.help ){
			this.drawHelp();
			return;
		}
		if( !this.levels.size )
			return;

		const right = this.content.querySelector("#right");
		right.replaceChildren();
		let level = this.getLevel();
		if( !level ){
			this.setActiveLevel(this.levels.values().next().value.obj, false);
			level = this.getLevel();
		}

		let cat = this.getCategory(level.category);
		if( !cat )
			cat = new Category();


		makeEl("h1", {
			text : level.name
		}, right);

		if( level.creator )
			makeEl("p", {
				class : "subtitle",
				text : "By " + level.creator
			}, right);

		let metaDiv = makeEl("div", {
			class : "meta"
		}, right);
		makeEl("div", {
			text : level.minPl + " - " + level.maxPl + " players",
			class : 'playerCount'
		}, metaDiv);
		makeEl("div", {
			text : "Version " + level.version,
			class : 'version'
		}, metaDiv);
		if( level.landImpact > 0 )
			makeEl("div", {
				text : "Land Impact: " + level.landImpact,
				class : 'landImpact'
			}, metaDiv);


		
		makeEl("p", {
			class : "desc",
			text : '"'+level.desc+'"'
		}, right);

		makeEl("br", {}, right);

		let category = makeEl("p", {
			class : "category",
		}, right);
		makeEl("strong", {text : ucFirst(level.category)}, category);
		makeEl("br", {}, category);
		makeEl("span", {text : cat.desc}, category);

		makeEl("br", {}, right);

		let launch = makeEl("input", {
			type : "button",
			value : "> Launch Level <",
			class : ["rez","inputButton"],
			dataset : {obj : level.obj}
		}, right);
		launch.addEventListener("click", this.onLaunchLevel.bind(this));

	}



}


class Level{

	obj = ''; 			// Unique object in rezzer
	name = '';			// Name of the level
	category = '';		// Category of the level
	maxPl = 16;			// Max players in the level
	minPl = 1;			// Min players in the level
	desc = '';
	creator = '';
	landImpact = 0;
	version = '';

	constructor( data = {} ){
		if( typeof data !== "object" || data === null )
			data = {};

		this.maxPl = Math.trunc(data.ma) || 16;
		this.minPl = Math.trunc(data.mi) || 1;

		this.category = String(data.c).trim().toLowerCase() || "wipeout";
		this.creator = String(data.cr).trim() || "Unknown";
		this.desc = String(data.d).trim() || "No description";
		this.landImpact = Math.trunc(data.l) || 0;
		this.name = String(data.n).trim() || "Unknown";
		this.obj = String(data.o).trim() || "";
		this.version = String(data.v).trim() || "0";

	}

}

class Category{

	label = '';
	desc = '';
	color = '#FFFFFF';

	constructor( data = {} ){
		if( typeof data !== "object" || data === null )
			data = {};

		this.label = data.l || '';
		this.desc = data.d || '';
		this.color = data.c || '#FFFFFF';

	}

}


function makeEl( type, props = {}, parent ){
	let out = document.createElement(type);
	for( let prop in props ){
		
		if( prop === "class" ){
			let c = props[prop];
			if( !Array.isArray(c) )
				c = [c];
			out.classList.add(...c);
		}
		else if( prop === "text" )
			out.innerText = props[prop];
		else if( prop === "html" )
			out.innerHTML = props[prop];
		else if( prop === "dataset" ){
			for( let key in props[prop] )
				out.dataset[key] = props[prop][key];
		}
		else
			out[prop] = props[prop];
		
	}

	if( parent )
		parent.appendChild(out);

	return out;

}

function ucFirst( input ){
	return input.charAt(0).toUpperCase() + input.slice(1);
}
