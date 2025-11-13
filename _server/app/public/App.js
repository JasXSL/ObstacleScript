export default class App{

	loading = document.getElementById("loading");
	content = document.getElementById("content");

	levels = new Map();
	categories = new Map();
	level = '';

	constructor(){

	}

	async begin(){

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

	onLaunchLevel( event ){

		let obj = event.currentTarget.dataset.obj;
		console.log("Todo: launch level: " + obj);

	}

	drawMenu(){

		const left = this.content.querySelector("#left");

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

			if( cat !== preCat ){
				makeEl("h3", {
					"text" : ucFirst(cat.label),
					"class" : "category"
				}, left);
				preCat = cat;
			}

			let color = cat.color;
			if( color.startsWith('#') )
				color = color.slice(1);
			let r = parseInt(color.slice(0,2), 16);
			let g = parseInt(color.slice(2,4), 16);
			let b = parseInt(color.slice(4,6), 16);
			r = Math.min(255, r+50), g = Math.min(255, g+50), b = Math.min(255, b+50);
			let startColor = `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;

			let c = ["level"];
			if( level.obj === this.level )
				c.push("active");

			let div = makeEl("div", {
				"text" : level.name,
				"class" : c,
				"dataset" : {obj:level.obj},
				"style" : 'background:linear-gradient(to bottom, '+startColor+' 0%, '+cat.color+' 100%)'
			}, left);
			div.addEventListener("click", this.onLevelClicked.bind(this));
			
		}

	}

	setActiveLevel( obj, drawLevel = true ){
		this.level = obj;
		this.drawMenu();
		if( drawLevel )
			this.drawLevel();
	}

	drawLevel(){

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
		if( level.landImpact > 0 )
			makeEl("div", {
				text : "Land Impact: " + level.landImpact,
				class : 'landImpact'
			}, metaDiv);
		let category = makeEl("div", {
			class : 'category',
			style:"background:"+cat.color
		}, metaDiv);
		makeEl("strong", {text : ucFirst(level.category)}, category);
		makeEl("span", {text : cat.desc}, category);
		
		makeEl("p", {
			class : "desc",
			text : level.desc
		}, right);

		makeEl("br", {}, right);

		let launch = makeEl("input", {
			type : "button",
			value : "> Launch Level <",
			class : "rez",
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
