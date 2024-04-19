import psychlua.LuaUtils;
import haxe.ds.StringMap;

/*typedef PackingInfo = {
	var name:String;
	var self:Character;
	//var cache:StringMap<Character>;
	var killSelf:Dynamic; // hscript only really
}*/

var extraChars:StringMap<Dynamic> = new StringMap(); // DON'T TOUCH THIS OR IT COULD BREAK THE SCRIPT!

// Character bops B)
var onBop = function(onPercent:Int) {
	for (curChar in extraChars)
		if (curChar.self != null && onPercent % curChar.self.danceEveryNumBeats == 0 && curChar.self.animation.curAnim != null && !StringTools.startsWith(curChar.self.animation.name, 'sing'))
			if (!curChar.self.stunned && startedCountdown && generatedMusic)
				curChar.self.dance();
}
function onCountdownTick(tick:Countdown, counter:Int) {onBop(counter); return;}
function onBeatHit() {onBop(curBeat); return;}

function onUpdatePost(elapsed:Float) {
	for (curChar in extraChars)
		if (curChar.self != null && (!controls.NOTE_LEFT && !controls.NOTE_DOWN && !controls.NOTE_UP && !controls.NOTE_RIGHT) && startedCountdown && generatedMusic)
			if (!curChar.self.stunned && curChar.self.holdTimer > Conductor.stepCrochet * 0.0011 * curChar.self.singDuration && curChar.self.animation.curAnim != null && StringTools.startsWith(curChar.self.animation.name, 'sing') && !StringTools.endsWith(curChar.self.animation.name, 'miss'))
				curChar.self.dance();
	return;
}

var extraNoteCall = function(setChar:Dynamic, daNote:Note, isPlayerNote:Bool, hasMissed:Bool, ?isPre:Bool = false) {
	if (isPre && hasMissed) return;
	var funcName:String = (hasMissed ? 'extraNoteMiss' : 'extraNoteHit') + isPre ? 'Pre' : '';
	var result:Dynamic = game.callOnLuas(funcName, [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, setChar.name, isPlayerNote]);
	if (result != Function_Stop && result != Function_StopHScript && result != Function_StopAll) game.callOnHScript(funcName, [daNote, setChar, isPlayerNote]);
}
var allNoteTriggers = function(daNote:Note, hasMissed:Bool) {
	for (curChar in extraChars) {
		if (extraChars.exists(curChar.name) && curChar.self.extraData.exists('noteTypes') && curChar.self != null) {
			for (noteTypes in curChar.self.extraData.get('noteTypes')) {
				var mustPressTarget = noteTypes[1] == null ? daNote.mustPress : noteTypes[1];
				if (daNote.noteType == noteTypes[0] && daNote.mustPress == mustPressTarget) {
					extraNoteCall(curChar, daNote, mustPressTarget, hasMissed, true);
					curChar.self.isPlayer = mustPressTarget;
					var keyName:String = 'no' + (hasMissed ? 'Miss' : '') + 'Animation';
					var result:Bool = daNote.extraData.exists(keyName) ? daNote.extraData.get(keyName) : false;
					if (!result) {
						curChar.self.playAnim(singAnimations[daNote.noteData] + ((hasMissed && curChar.self.hasMissAnimations) ? 'miss' : '') + daNote.animSuffix, true);
						if (!hasMissed) curChar.self.holdTimer = 0;
					}
					extraNoteCall(curChar, daNote, mustPressTarget, hasMissed);
				}
			}
		}
	}
}
// I combined them, cause yes.
function goodNoteHit(daNote:Note) {allNoteTriggers(daNote, daNote.mustPress); return;}
function opponentNoteHit(daNote:Note) {allNoteTriggers(daNote, daNote.mustPress); return;}
function otherStrumHit(daNote:Note, strumLane) {allNoteTriggers(daNote, daNote.mustPress); return;}
function noteMiss(daNote:Note) {allNoteTriggers(daNote, daNote.mustPress); return;}
function opponentNoteMiss(daNote:Note) {allNoteTriggers(daNote, daNote.mustPress); return;} // jic

function onEventPushed(name:String, value1:String, value2:String) {
	switch (name) {
		case 'Change Extra Character':
			precacheCharacter(value1, value2);
	}
	return;
}

function onEvent(name:String, value1:String, value2:String) {
	switch (name) {
		// Was gonna just use the base "Change Character" event, but I couldn't figure out a good system for the last character (value1) called.
		case 'Change Extra Character':
			if (extraChars.exists(value1) && extraChars.get(value1).self != null) {
				final curChar = extraChars.get(value1);
				precacheCharacter(value1, value2);
				final prevProp = {
					x: curChar.self.x - curChar.self.positionArray[0],
					y: curChar.self.y - curChar.self.positionArray[1],
					alpha: curChar.self.alpha,
					player: curChar.self.isPlayer,
					noteTypes: curChar.self.extraData.get('noteTypes'),
					order: game.members.indexOf(curChar.self)
				};
				removeCharacter(value1);
				makeCharacter(value1, value2, [prevProp.x, prevProp.y], prevProp.player, prevProp.noteTypes);
				/*addCharacter(value1);
				remove(curChar.self, true);*/
				insert(prevProp.order, curChar.self);
			}
		case 'Play Extra Animation':
			var char:Character = extraChars.exists(value2) ? extraChars.get(value2).self : null;
			if (char != null) {
				char.playAnim(value1, true);
				char.specialAnim = true;
			}
	}
	return;
}

var setupChar = function(tag:String, char:Character, noteTypes:Array<Dynamic>) {
	setVar(tag, char);
	char.extraData.set('noteTypes', noteTypes);
	game.setOnScripts(tag + 'Name', char.curCharacter);
	extraChars.set(tag, {name: tag, self: char, /*cache: new StringMap(),*/ killSelf: function() { removeCharacter(tag); }});
}

// Possible full on precache system in the future?
function precacheCharacter(setChar:String, addToCache:String) {
	game.addCharacterToList(addToCache, 2); // 2 means gf, so it all just goes to her, lol
}

/**
 * @param tag The `Character` objects tag.
 * @param character The character's json file name.
 * @param charPos The x and y position. `[20, 50]`
 * @param isPlayer Ok so in this case just look at this as is facing left.
 * @param noteTypes Notes that make the character sing. `[["the note type name", "true is player, false is opponent and null is for both"], etc]`
 */
function makeCharacter(tag:String, character:String, ?charPos:Array<Float> = null, ?isPlayer:Bool = false, ?noteTypes:Array<Dynamic> = null) {
	if (tag == 'dad' || tag == 'gf' || tag == 'boyfriend') return debugPrint('makeCharacter: You can\'t use their names dummy! XD');
	else if (tag.length < 1 || tag == null) return debugPrint('makeCharacter: The name can\'t be blank!');
	else if (extraChars.exists(tag) && extraChars.get(tag).self == null) return debugPrint('makeCharacter: This name is already in use!');
	charPos = charPos == null ? (isPlayer ? [BF_X + 350, BF_Y] : [DAD_X - 350, DAD_Y]) : charPos;
	noteTypes = noteTypes == null ? [['No Animation', isPlayer]] : noteTypes;

	var char:Character = new Character(charPos[0], charPos[1], character, isPlayer);
	char.x += char.positionArray[0];
	char.y += char.positionArray[1];
	char.dance();
	
	setupChar(tag, char, noteTypes);
}

/**
 * @param tag The `Character` objects tag.
 * @param front Should they spawn in the very front?
 */
function addCharacter(tag:String, ?front:Bool = false) {
	if (extraChars.exists(tag)) {
		var char = extraChars.get(tag).self;
		if (front) add(char);
		else insert(game.members.indexOf(LuaUtils.getLowestCharacterGroup()), char);
	}
}

/**
 * @param tag The `Character` objects tag.
 * @param destroy Should they he completely removed?
 */
function removeCharacter(tag:String, ?destroy:Bool = true) {
	if (extraChars.exists(tag))
		if (destroy) {
			var char = extraChars.get(tag).self;
			removeVar(tag);
			game.setOnScripts(tag + 'Name', null);
			char.kill();
			extraChars.remove(tag);
			char.destroy();
		} else remove(extraChars.get(tag).self);
}

/**
 * @param tag The `Character` objects tag.
 * @param char The character themselves.
 * @param noteTypes Notes that make the character sing. `[["the note type name", "true is player, false is opponent and null is for both"], etc]`
 */
function importCharacter(tag:String, char:Character, ?noteTypes:Array<Dynamic> = null) {
	if (tag == 'dad' || tag == 'gf' || tag == 'boyfriend') return debugPrint('importCharacter: You can\'t use their names dummy! XD');
	else if (char == dad || char == gf || char == boyfriend) return debugPrint('importCharacter: You can\'t import them dummy! XD');
	else if (tag.length < 1 || tag == null) return debugPrint('importCharacter: The name can\'t be blank!');
	else if (extraChars.exists(tag) && extraChars.get(tag).self == null) return debugPrint('importCharacter: This name is already in use!');
	noteTypes = noteTypes == null ? [['No Animation', char.isPlayer]] : noteTypes;

	setupChar(tag, char, noteTypes);
	return extraChars.get(tag); // return jic
}

/**
 * If `type` is "set" then `input` should be `[[String, Bool], etc]`.    
 * If `type` is "add" then `input` should be `[String, Bool]`.    
 * If `type` is "remove" then `input` should be `String`.    
 * If `type` is "replace" then `input` should be `[[String, Bool], [String, Bool]]`.
 * @param tag The `Character` objects tag.
 * @param input Notes that make the character sing. `[["the note type name", "true is player, false is opponent and null is for both"], etc]`
 * @param type Should it set, add, remove or replace?
 */
function setCharNoteTypes(tag:String, ?input:Dynamic = null, ?type:String = 'set') {
	if (extraChars.exists(tag) && extraChars.get(tag).self != null && input != null) {
		final curChar = extraChars.get(tag).self;
		if (type == 'set' && Std.isOfType(input[0], Array)) curChar.extraData.set('noteTypes', input);
		else if (type == 'add' && Std.isOfType(input[0], String)) curChar.extraData.get('noteTypes').push(input);
		// else if (type == 'remove' && Std.isOfType(input, String)) curChar.extraData.get('noteTypes').remove(input); // not done
		//else if (type == 'replace' && (Std.isOfType(input[0], Array) && Std.isOfType(input[1], Array)))
		// not done
	}
}

/**
 * @param noteType The name of a noteType.
 * @param haveAnim Should the note have animations play?
 * @param mustPress Wanna specify opponent or player?
 * @param effectExtras Effect extra chars or just the base ones?
 */
function shouldNotePlayAnim(noteType:String, ?haveAnim:Bool = null, ?mustPress:Bool = null, ?effectExtras:Bool = false) {
	if (haveAnim != null) {
		if (noteType == 'Alt Animation' || noteType == 'Hey!' || noteType == 'GF Sing' || noteType == 'No Animation') return debugPrint('shouldNotePlayAnim: You can\'t use the "' + noteType + '" noteType!');
		else {
			var extraCheck = function(daNote:Note, haveAnim:Bool) {
				if (effectExtras && daNote.extraData.exists('noAnimation') && daNote.extraData.exists('noMissAnimation')) {
					daNote.extraData.set('noAnimation', !haveAnim);
					daNote.extraData.set('noMissAnimation', !haveAnim);
				} else {
					daNote.noAnimation = !haveAnim;
					daNote.noMissAnimation = !haveAnim;
				}
			}
			for (daNote in unspawnNotes) {
				if ((daNote.noteType == noteType) && (daNote.mustPress == mustPress || mustPress == null)) {
					extraCheck(daNote, haveAnim);
				}
			}
			for (daNote in notes) {
				if ((daNote.noteType == noteType) && (daNote.mustPress == mustPress || mustPress == null)) {
					extraCheck(daNote, haveAnim);
				}
			}
		}
	} else return debugPrint('shouldNotePlayAnim: haveAnim can\'t be null!');
}

// `createGlobalCallback` allows use in lua, `setOnHScript` allows use in hx and `makeForBoth` is well... for both.
var makeForBoth = function(tag:String, value:Dynamic) { // using setOnLuas would crash, idk why
	createGlobalCallback(tag, value); // creates function for lua
	game.setOnHScript(tag, value); // creates function for hscript
}

// I hate psych
makeForBoth('precacheCharacter', precacheCharacter);
createGlobalCallback('makeCharacter', makeCharacter);
createGlobalCallback('addCharacter', addCharacter);
createGlobalCallback('removeCharacter', removeCharacter);
game.setOnHScript('importCharacter', importCharacter);
makeForBoth('setCharNoteTypes', setCharNoteTypes);
makeForBoth('shouldNotePlayAnim', shouldNotePlayAnim);
function onCreatePost() {
	makeForBoth('precacheCharacter', precacheCharacter);
	createGlobalCallback('makeCharacter', makeCharacter);
	createGlobalCallback('addCharacter', addCharacter);
	createGlobalCallback('removeCharacter', removeCharacter);
	game.setOnHScript('importCharacter', importCharacter);
	makeForBoth('setCharNoteTypes', setCharNoteTypes);
	makeForBoth('shouldNotePlayAnim', shouldNotePlayAnim);
	return;
}