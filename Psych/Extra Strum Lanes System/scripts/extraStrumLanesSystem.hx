import haxe.ds.StringMap;
import backend.Mods;
import flixel.group.FlxTypedGroup;
import objects.StrumNote;
import psychlua.FunkinLua;
import tjson.TJSON as Json;

/*typedef LaneInfo = {
	tag:String,
	lane:FlxTypedGroup<StrumNote>,
	attachmentVar:String,
	noteTypes:Array<String>
}*/

/**
 * centers the strum group on a x cord
 * @param strumGroup the strum group
 * @param x the new x
 * @param customWidth custom swag width
 */
function setStrumGroupX(strumGroup:FlxTypedGroup<StrumNote>, ?x:Float = 0, ?customWidth:Float = 0) {
	if (strumGroup == null) return debugPrint('setStrumGroupX: strumGroup can\'t be null!', 0xff0000);
	if (customWidth < 1) customWidth = Note.swagWidth;
	for (strumNote in strumGroup) {
		strumNote.x = x - (customWidth / 2);
		strumNote.x += customWidth * strumNote.noteData;
		strumNote.x -= (customWidth * ((strumGroup.length - 1) / 2));
	}
}
/**
 * sets relative to group set
 * @param strumNote the strum
 * @param x the new x
 * @param customWidth custom swag width
 * @param groupLength like the actually amount of strums in the group, none of the 3 bs
 */
function setStrumX(strumNote:StrumNote, ?x:Float = 0, ?customWidth:Float = 0, ?groupLength:Int = 4) {
	if (strumNote == null) return debugPrint('setStrumX: strumNote can\'t be null!', 0xff0000);
	if (customWidth < 1) customWidth = Note.swagWidth;
	var length:Int = groupLength == null ? 4 : groupLength;
	strumNote.x = x - (customWidth / 2);
	strumNote.x += customWidth * strumNote.noteData;
	strumNote.x -= (customWidth * ((length - 1) / 2));
}

// doesn't include base lanes obviously
var strumLanes:StringMap<Dynamic> = new StringMap(); // DON'T TOUCH THIS OR IT COULD BREAK THE SCRIPT!
var blankLaneInfo = function(?mustPress = null) return mustPress == null ? {
	tag: '',
	lane: null,
	attachmentVar: '',
	noteTypes: []
} : {
	tag: mustPress ? 'player' : 'opponent',
	lane: mustPress ? game.playerStrums : game.opponentStrums,
	attachmentVar: '',
	noteTypes: []
};

/**
 * creates the new strum lane, don't add "Strums" to the end of the tag name PLEASE
 * @param tag the tag name of the strum lane
 * @param attachmentVar the notes extraData var that moves notes to that strum lane, writing "gfNote" will make them apply to her
 * @param noteTypes acts like `attachmentVar` but for individual notetypes
 * @param inFront adds it in front of the base strum lanes
 */
function generateStrumLane(tag:String, attachmentVar:String, ?noteTypes:Array<String> = [], ?inFront:Bool = false) {
	if (StringTools.endsWith(tag.toLowerCase(), 'strums')) return debugPrint('generateStrumLane: Strum lane tag can\'t end with "Strums" because the script does that for you.', 0xff0000);
	else if (strumLanes.exists(tag)) return debugPrint('generateStrumLane: Strum lane tag "' + tag + '" already exists.', 0xff0000);
	else if (tag == 'opponent' || tag == 'player') return debugPrint('generateStrumLane: Strum lane tag can\'t be "' + tag + '", as it would be named as a base game strum lane.', 0xff0000);
	if (attachmentVar == '') return debugPrint('generateStrumLane: Can\'t be blank, try "gfNote" instead.', 0xff0000);
	var strumGroup:FlxTypedGroup<StrumNote> = new FlxTypedGroup();
	for (i in 0...4) { // fuck extra keys... not really
		var strumNote:StrumNote = new StrumNote(0, ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50, i, 0);
		strumNote.playAnim('static'); // jic
		strumNote.downScroll = ClientPrefs.data.downScroll;
		strumGroup.add(strumNote);
	}
	noteGroup.insert(noteGroup.members.indexOf(strumLineNotes) + (inFront ? 1 : 0), strumGroup);
	setVar(tag + 'Strums', strumGroup);
	game.setOnHScript(tag + 'Strums', strumGroup);
	strumLanes.set(tag, {
		tag: tag,
		lane: strumGroup,
		attachmentVar: attachmentVar,
		noteTypes: noteTypes == null ? [] : noteTypes
	});
	return strumLanes.get(tag);
}

function parseJson(directory:String, ?printWarming:Bool = false, ?ignoreMods:Bool = false) {
	final funnyPath:String = directory + '.json';
	final jsonContents:String = Paths.getTextFromFile(funnyPath, ignoreMods);
	final realPath:String = (ignoreMods ? '' : Paths.modFolders(Mods.currentModDirectory)) + '/' + funnyPath;
	final jsonExists:Bool = Paths.fileExists(realPath, null, ignoreMods);
	if (jsonContents != null || jsonExists) return Json.parse(jsonContents);
	else if (!jsonExists && printWarming) debugPrint('parseJson: "' + realPath + '" doesn\'t exist!', 0xff0000);
}

// `createGlobalCallback` allows use in lua, `setOnHScript` allows use in hx and `makeForBoth` is well... for both.
var makeForBoth = function(tag:String, value:Dynamic) { // using setOnLuas would crash, idk why
	createGlobalCallback(tag, value); // creates function for lua
	game.setOnHScript(tag, value); // creates function for hscript
}

var ran:Bool = false;
var iHateEverything = function() {
	if (ran) return; ran = true;
	makeForBoth('setStrumGroupX', setStrumGroupX);
	makeForBoth('setStrumX', setStrumX);
	var extraStrumInfo = parseJson('data/' + Paths.formatToSongPath(PlayState.SONG.song) + '/extraStrumInfo');
	if (extraStrumInfo == null) return;
	else if (extraStrumInfo.info == null) return debugPrint('extraStrumInfo: \"info\" part of the json is null', 0xff0000);
	var strumLane;
	for (info in extraStrumInfo.info) {
		strumLane = generateStrumLane(info.tag, info.attachmentVar, info.noteTypes, info.inFront);
		if (strumLane == null) return;
		setStrumGroupX(strumLane.lane, FlxG.width / 2);
		for (strumNote in strumLane.lane) strumNote.screenCenter(0x10);
	}
	if (strumLane == null) return; // jic
	for (daNote in unspawnNotes) {
		if (daNote != null) {
			var strumLane = getStrumLane(daNote);
			if (strumLane == null || strumLane.lane == null) daNote.extraData.set('setStrumLane', blankLaneInfo(daNote.mustPress));
			else daNote.extraData.set('setStrumLane', strumLane);
		}
	}
	game.callOnScripts('onStrumLaneCreation', [strumLane.tag]);
};

function onCreatePost() {
	makeForBoth('setStrumGroupX', setStrumGroupX);
	makeForBoth('setStrumX', setStrumX);
	// iHateEverything();
}
function onSongStart() iHateEverything();
function onCountdownTick() iHateEverything();

function callNoteHit(daNote:Note, strumLane) {
	final ogMustPress:Bool = daNote.mustPress;
	daNote.mustPress = false;
	var callScript = function(daNote:Note, ?isPre:Bool = false) {
		var funcNames:String = 'otherStrumHit' + (isPre ? 'Pre' : '');
		daNote.mustPress = ogMustPress;
		var result:Dynamic = game.callOnLuas(funcNames, [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, strumLane.tag]);
		if (result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) game.callOnHScript(funcNames, [daNote, strumLane]);
		daNote.mustPress = false;
	}

	callScript(daNote, true);

	if (daNote.mustPress) daNote.wasGoodHit = true;

	if (Paths.formatToSongPath(PlayState.SONG.song) != 'tutorial' && !daNote.musPress) game.camZooming = true;

	if (!daNote.noAnimation) {
		var char:Character = null;
		var animCheck:String = 'hey';
		if (daNote.gfNote) {
			char = gf;
			animCheck = 'cheer';
		}
		if (char != null) {
			char.playAnim(singAnimations[daNote.noteData] + daNote.animSuffix, true);
			char.holdTimer = 0;
			if (daNote.noteType == 'Hey!' && char.animOffsets.exists(animCheck)) {
				char.playAnim(animCheck, true);
				char.specialAnim = true;
				char.heyTimer = 0.6;
			}
		}
	}

	// daNote.mustPress = ogMustPress;
	strumLane.lane.members[daNote.noteData].playAnim('confirm', true);
	if ((daNote.mustPress && cpuControlled) || !daNote.mustPress) strumLane.lane.members[daNote.noteData].resetAnim = Conductor.stepCrochet * 1.25 / 1000 / playbackRate;
	// daNote.mustPress = false;
	if (!daNote.mustPress) daNote.hitByOpponent = true;

	vocals.volume = 1;
	callScript(daNote);
	if (!daNote.isSustainNote) game.invalidateNote(daNote);
}

function getStrumLane(daNote:Note) {
	if (daNote != null) {
		for (curLane in strumLanes) {
			var hasAttachment:Bool = daNote.extraData.exists(curLane.attachmentVar) && daNote.extraData.get(curLane.attachmentVar);
			if (curLane.attachmentVar == 'gfNote') hasAttachment = daNote.gfNote;
			var noteTypeUsed:Bool = false;
			for (noteType in curLane.noteTypes) {
				if (noteType != null && noteType != '' && noteType != daNote.noteType) {
					noteTypeUsed = false;
					break;
				} else noteTypeUsed = true;
			}
			if (hasAttachment || noteTypeUsed) return curLane;
			return blankLaneInfo(daNote.mustPress);
		}
	}
	return blankLaneInfo();
}

function onUpdatePost(elapsed:Float) {
	if (generatedMusic && !inCutscene && notes.length > 0 && startedCountdown) {
		var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
		notes.forEachAlive(function(daNote:Note) {
			var strumLane = getStrumLane(daNote);
			var strumGroup:FlxTypedGroup<StrumNote> = strumLane.lane;
			if (strumLane == null || strumGroup == null)
				return daNote.extraData.set('setStrumLane', blankLaneInfo(daNote.mustPress));
			else daNote.extraData.set('setStrumLane', strumLane);
			final setStrumLaneTag = daNote.extraData.exists('setStrumLane') ? daNote.extraData.get('setStrumLane').tag : '';
			if (setStrumLaneTag == 'opponent' || setStrumLaneTag == 'player' || setStrumLaneTag == '') return;
			var strum:StrumNote = strumGroup.members[daNote.noteData];
			daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);
			daNote.ignoreNote = true;
			if (daNote.strumTime <= Conductor.songPosition) callNoteHit(daNote, strumLane);
			daNote.ignoreNote = false;
			if (daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);
			daNote.ignoreNote = true;
		});
	}
}