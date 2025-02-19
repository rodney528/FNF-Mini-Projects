-- Script by @rodney528

local internalSettings = { -- This is for smaller stuff in the script that don't make a lot of sense to be able to change mid-song.
	blacklistedNoteTypes = { -- These noteTypes will not trigger displacement if listed.
		'Hey!',
		'No Animation'
	},
	sustainDisplacement = true, -- With this on the camera will slowly lose its displacement instead of just moving back at the end of a note.
	cleanerMovement = true -- Makes the movement look cleaner and less jittery.
}

-- Cool 0.6.3 backwards compatibility bullshit! `nil` for auto set. If it doesn't set automatically feel free to manually set it.
local above07 = nil
local below07 = nil

local function setupVars()
	-- These are options you can customize.
	stupidVar('displacementOffset', {x = 30, y = 30}) -- X and Y displacement offset.
	stupidVar('canSnapOnMiss', true) -- Do you want the camera to snap to the selected `camPointChars.play` character on miss?
	stupidVar('allowCamIdleBop', true) -- Remade the cool cam idle bop movement that Blantados did for his version!
	stupidVar('camVelocity', { -- Change camera speed when hitting notes (reverts when none are being hit).
		active = true,
		mult = 1.5
	})

	-- These are NOT options, these are vars the script uses for stuff.
	stupidVar('camPointChars', { -- Who the camera should point at for general characters.
		oppo = {'dad', 'dad', 'opponent'},
		play = {'boyfriend', 'bf', 'boyfriend'}
	})
	stupidVar('whosActive', {oppo = true, play = true}) -- Who has the displacement?
	stupidVar('ifCamLocked', { -- Cool cam lock stuff.
		oppo = {active = false, x = 0, y = 0},
		play = {active = false, x = 0, y = 0}
	})
	stupidVar('allowBothPresses', false) -- Allows opponent and player note hit to cause camera displacement no matter the section when enabled. Recommended for `ifCamLocked` stuff.
	stupidVar('forceSectionDetection', nil) -- If true only player hits trigger displacement, false for opponent and `nil` to disable (doesn't ignore `allowBothPresses`).
	stupidVar('forceCameraTarget', {nil, nil, nil}) -- Has the same setup as the camPointChars stuff. Setting one of the values to nil makes it check camPointChars instead.
	stupidVar('forceCameraSection', nil) -- It's basically forceSectionDetection but for who the camera goes to instead.

	if below07 or above07 then
		stupidVar('targetOffset', {x = 0, y = 0}) -- For 0.6.3 to work.
	end
end

-- !! DON'T TOUCH ANYTHING BELOW THIS POINT !! --

---setVar basically
---@param varName string
---@param value any
function stupidVar(varName, value)
	if below07 then
		runHaxeCode("setVar('" .. tostring(varName) .. "', null);")
		setProperty(varName, value)
	else
		setVar(varName, value)
	end
end

---setOnScripts basically
---@param varName string
---@param value any
function dumbSet(varName, value)
	if below07 then
		stupidVar('setOnLuas_varHolder', {varName, value})
		runHaxeCode([[
			game.setOnLuas(getVar('setOnLuas_varHolder')[0], getVar('setOnLuas_varHolder')[1]);
			removeVar('setOnLuas_varHolder');
		]])
	else
		setOnScripts(varName, value)
	end
end

-- cool funny functions

---@param variable any The `variable` you want to check.
---@param ifNil any What should be returned if the `variable` is `nil`.
---@param shouldBe? 'number'|'string'|'boolean' What should be the `variable` type be?
---@return any ifNil Shall return `ifNil`.
function checkVarData(variable, ifNil, shouldBe)
	if shouldBe == 'number' then
		local nilTest = tonumber(variable)
		return type(nilTest) == 'number' and nilTest or ifNil
	elseif shouldBe == 'string' then return tostring(variable)
	elseif shouldBe == 'boolean' then
		if type(variable) == 'boolean' then return variable
		elseif type(variable) == 'string' then
			local nilTest = stringTrim(variable:lower())
			if nilTest == 'true' then return true -- screw coding
			elseif nilTest == 'false' then return false end
			return ifNil
		elseif type(variable) == 'number' then
			if variable >= 1 then return true -- screw coding
			elseif variable <= 0 then return false end
			return ifNil -- jic
		else return ifNil end
	end
	local nilTest = variable
	if variable == nil or #variable < 1 then nilTest = ifNil end
	return nilTest
end

-- Converts extra key `noteData` into 4 key.
---@param noteData number The `noteData`.
---@param maniaVar number The variable thats states the current amount of keys.
---@return number noteData Returns the `noteData` after the 4 key conversion.
function noteDataEKConverter(noteData, maniaVar)
	if maniaVar == 1 then
		if noteData == 0 then return 2
		else return noteData end

	elseif maniaVar == 2 then
		if noteData == 1 then return 3
		else return noteData end

	elseif maniaVar == 3 then
		if noteData == 1 then return 2
		elseif noteData == 2 then return 3
		else return noteData end

	-- elseif maniaVar == 4 then

	elseif maniaVar == 5 then
		if noteData == 3 then return 2
		elseif noteData == 4 then return 3
		else return noteData end

	elseif maniaVar == 6 then
		if noteData == 1 then return 2
		elseif noteData == 2 then return 3
		elseif noteData == 3 then return 0
		elseif noteData == 4 then return 1
		elseif noteData == 5 then return 3
		else return noteData end

	elseif maniaVar == 7 then
		if noteData == 1 then return 2
		elseif noteData == 2 then return 3
		elseif noteData == 3 then return 2
		elseif noteData == 4 then return 0
		elseif noteData == 5 then return 1
		elseif noteData == 6 then return 3
		else return noteData end

	elseif maniaVar == 8 then
		if noteData == 4 then return 0
		elseif noteData == 5 then return 1
		elseif noteData == 6 then return 2
		elseif noteData == 7 then return 3
		else return noteData end

	elseif maniaVar == 9 then
		if noteData == 4 then return 2
		elseif noteData == 5 then return 0
		elseif noteData == 6 then return 1
		elseif noteData == 7 then return 2
		elseif noteData == 8 then return 3
		else return noteData end

	else
		return noteData
	end
end

local function camFolPosTag()
	local tag = below07 and 'camFollowPos.' or 'camGame.scroll.'
	return {
		x = tag .. 'x',
		y = tag .. 'y'
	}
end

---@param x number
---@param y number
---@param isPos boolean
function setCamPos(x, y, isPos)
	if checkVarData(isPos, false, 'boolean') then
		setProperty(camFolPosTag().x, checkVarData(x - (below07 and 0 or (screenWidth / 2)), getProperty(camFolPosTag().x), 'number'))
		setProperty(camFolPosTag().y, checkVarData(y - (below07 and 0 or (screenHeight / 2)), getProperty(camFolPosTag().y), 'number'))
	else
		setProperty('camFollow.x', checkVarData(x, getCamPos().x, 'number'))
		setProperty('camFollow.y', checkVarData(y, getCamPos().y, 'number'))
	end
end

---@param isPos boolean
---@return number
function getCamPos(isPos)
	if checkVarData(isPos, false, 'boolean') then
		return {
			x = getProperty(camFolPosTag().x) + (below07 and 0 or (screenWidth / 2)),
			y = getProperty(camFolPosTag().y) + (below07 and 0 or (screenHeight / 2))
		}
	else
		return {
			x = getProperty('camFollow.x'),
			y = getProperty('camFollow.y')
		}
	end
end

---@param x number
---@param y number
---@param isPos boolean
function adjustCamPos(x, y, isPos)
	isPos = checkVarData(isPos, false, 'boolean')
	setCamPos(
		getCamPos(isPos).x + checkVarData(x, 0, 'number'),
		getCamPos(isPos).y + checkVarData(y, 0, 'number'),
		isPos
	)
end

---@param x number
---@param y number
function setCamOffset(x, y)
	if below07 then
		setProperty('targetOffset.x', checkVarData(x, getCamOffset().x, 'number'))
		setProperty('targetOffset.y', checkVarData(y, getCamOffset().y, 'number'))
	else
		setProperty('camGame.targetOffset.x', checkVarData(x, getCamOffset().x, 'number'))
		setProperty('camGame.targetOffset.y', checkVarData(y, getCamOffset().y, 'number'))
	end
end

---@return number
function getCamOffset()
	if below07 then
		return {
			x = getProperty('targetOffset.x'),
			y = getProperty('targetOffset.y')
		}
	else
		return {
			x = getProperty('camGame.targetOffset.x'),
			y = getProperty('camGame.targetOffset.y')
		}
	end
end

local triggerVelocity = false
local function cancelTriggers()
	cancelTimer('cool cam return')
	cancelTimer('cam after bop')
	cancelTween('cleanSustainDisplacementX')
	cancelTween('cleanSustainDisplacementY')
	triggerVelocity = false
	updateCameraInfo(true)
end

local lastFocus = ''
local cameraDetection = mustHitSection
local sectionDetection = cameraDetection
local function callCamPoint2Func(character, stopCall)
	if character ~= lastFocus and not checkVarData(stopCall, false, 'boolean') then
		local setSection = gfSection and nil or sectionDetection
		if below07 then
			callOnLuas('camPointingTo', {character, setSection})
		else
			callOnScripts('camPointingTo', {character, setSection})
		end
		-- lags a fuck ton
		-- if not below07 then runHaxeFunction('callCamPoint2Func', {character, setSection}) end
		lastFocus = character
		cancelTriggers()
	end
end

local function updateDetectionVars()
	-- !!! FUCKING DIE YOU PIECE OF SHIT !!! --
	if tostring((getProperty('forceCameraSection'))) == 'nil' or getProperty('forceCameraSection') == 'forceCameraSection' then
		cameraDetection = mustHitSection
	else
		cameraDetection = getProperty('forceCameraSection')
	end
	if tostring((getProperty('forceSectionDetection'))) == 'nil' or getProperty('forceSectionDetection') == 'forceSectionDetection' then
		sectionDetection = cameraDetection
	else
		sectionDetection = getProperty('forceSectionDetection')
	end
end

---Check if the character exists.
---@param charName string
---@return boolean
local function charExists(charName)
	return type(getProperty(charName .. '.x')) == 'number'
	-- return runHaxeCode([[
	-- 	var charName:String = ']] .. charName .. [[';
	-- 	return switch (charName) {
	-- 		case 'gf': game.gf != null;
	-- 		case 'dad': game.dad != null;
	-- 		case 'boyfriend': game.boyfriend != null;
	-- 		default: game.getLuaObject(charName, false) != null;
	-- 	}
	-- ]])
end

---Double checks for it hide gf is enabled in the stage json.
---@param charName string
---@return string
local function gfCheck(charName)
	if charName == 'gf' then
		if charExists('gf') then
			return charName
		else
			return mustHitSection and 'boyfriend' or 'dad'
		end
	else
		return charName
	end
end

-- If `ifCamLocked` local has `active` set to `true`.
---@param isP1 boolean Is it player or opponent who hit the note?
function setLockedCamPos(isP1) -- Need to maybe change the internals.
	if getProperty('ifCamLocked.oppo.active') and not isP1 then
		setCamPos(getProperty('ifCamLocked.oppo.x'), getProperty('ifCamLocked.oppo.y'))
	end
	if getProperty('ifCamLocked.play.active') and isP1 then
		setCamPos(getProperty('ifCamLocked.play.x'), getProperty('ifCamLocked.play.y'))
	end
end

-- Basically the same thing from source but in lua now ig?
---@param stopCall? boolean
---@param updatePos? boolean
function updateCameraInfo(stopCall, updatePos)
	-- if not getProperty('isCameraOnForcedPos') then
		setCamOffset(0, 0)
		stopCall = checkVarData(stopCall, false, 'boolean')
		updatePos = checkVarData(updatePos, false, 'boolean')
		if getProperty('ifCamLocked.' .. (sectionDetection and 'play' or 'oppo') .. '.active') and updatePos then
			setLockedCamPos(mustHitSection)
			callCamPoint2Func(sectionDetection and 'playerLock' or 'opponentLock', stopCall)
		else
			if updatePos then
				setToCharCamPosition(getProperty('curChar')[1], {getProperty('curChar')[2], getProperty('curChar')[3]}, true, stopCall)
			end
		end
	-- end
end

local focusThingy = gfSection and 'gf' or (mustHitSection and 'boyfriend' or 'dad')
---@param character string
---@param offset table.string
---@param setPos boolean
---@param stopCall boolean
function setToCharCamPosition(character, offset, setPos, stopCall)
	---@param one number
	---@param operator string
	---@param two number
	---@return number
	local function doMathStupid(one, operator, two)
		-- Fuck math, why does bf do - while dad and gf do + on x like WTF?!?!!
		one, two = checkVarData(one, 0, 'number'), checkVarData(two, 0, 'number')
		if operator == '+' then return one + two -- Addition
		elseif operator == '-' then return one - two -- Subtraction
		elseif operator == '*' then return one * two -- Multiplication
		elseif operator == '/' then return one / two -- Division
		end
	end

	character = gfCheck(character)
	if charExists(character) then
		local mainOffset = checkVarData(offset[1], (focusThingy == 'boyfriend' and 'bf' or focusThingy), 'string')
		local stageOffset = (offset[2] == 'original' and (mainOffset == 'dad' and 'opponent' or mainOffset == 'gf' and 'girlfriend' or mainOffset == 'bf' and 'boyfriend') or tostring(offset[2]))
		setPos = checkVarData(setPos, true, 'boolean')

		local camPos = {x = 0, y = 0}
		-- set camera to then characters camera position
		local camera = {position = checkVarData(getProperty(character .. '.cameraPosition'), {0, 0}), offset = checkVarData(getProperty(stageOffset .. 'CameraOffset'), {0, 0})}
		camPos.x = getMidpointX(character) + (mainOffset == 'gf' and 0 or (mainOffset == 'dad' and 150 or -100))
		camPos.y = getMidpointY(character) + (mainOffset == 'gf' and 0 or (mainOffset == 'dad' and -100 or -100))
		camPos.x = doMathStupid(camPos.x, (mainOffset == 'bf' and '-' or '+'), checkVarData(camera.position[1], 0, 'number'))
		camPos.y = camPos.y + checkVarData(camera.position[2], 0, 'number')
		if checkVarData(stageOffset, 'none', 'string') == 'none' or (mustHitSection and getProperty('ifCamLocked.play.active') or getProperty('ifCamLocked.oppo.active')) then
		else -- Funny code magic man!
			if stageOffset == 'boyfriend' or stageOffset == 'girlfriend' or stageOffset == 'opponent' then
				camPos.x = camPos.x + checkVarData(camera.offset[1], 0, 'number')
				camPos.y = camPos.y + checkVarData(camera.offset[2], 0, 'number')
			end
		end
		local camTag = 'camFollow' .. (setPos and '' or 'Fake')
		setProperty(camTag .. '.x', camPos.x * getProperty(character .. '.scrollFactor.x'))
		setProperty(camTag .. '.y', camPos.y * getProperty(character .. '.scrollFactor.y'))
		if setPos then callCamPoint2Func(character, checkVarData(stopCall, false, 'boolean')) end
	end
end

function clamp(x, min, max) return math.max(min, math.min(x, max)) end

function turnIntoPercent(mainValue, maxValue, outOf)
	return (mainValue / maxValue) * (outOf == nil and 100 or outOf)
end

function textSplit(str, delimiter)
	local splitTxt = stringSplit(str, delimiter)
	for index, value in pairs(splitTxt) do
		splitTxt[index] = stringTrim(value)
	end
	return splitTxt
end

function onCreate()
	if above07 == nil then
		above07 = version >= '0.7.3'
	end
	if below07 == nil then
		below07 = version <= '0.6.3'
	end
	if version <= '0.6.2' then -- still not 0.7 so yeah ¯\_(ツ)_/¯
		debugPrint([[
			Hey, your using version ]] .. version .. [[!
			This script only supports versions 0.6.3 and latest (being 0.7.3 as of rn).
			Please use those versions of psych for the script to work properly!
			If you think the script will be fine just remove the return line and close function.
		]])
		return close(true)
	end
	setupVars()

	if not below07 then
		runHaxeCode([[
			function gfCheck(charName:String) {
				if (charName == 'gf') return game.gf != null ? 'gf' : (mustHitSection ? 'boyfriend' : 'dad');
				else return charName;
			}
			function getObject(charName:String) {
				return switch(gfCheck(charName)) {
					case 'dad': game.dad;
					case 'gf': game.gf;
					case 'boyfriend': game.boyfriend;
					default: game.getLuaObject(charName, false);
				}
			}
			function callCamPoint2Func(charName:String, setSection:Bool) game.callOnHScript('camPointingTo', [getObject(charName), setSection]);
		]])
	end

	dumbSet('savedCamLockPoses', {})
end

local function forceTargetCheck(index, state)
	local useForce = type(getProperty('forceCameraTarget')[index]) == 'string'
	return useForce and getProperty('forceCameraTarget')[index] or getProperty('camPointChars.' .. (state and 'play' or 'oppo'))[index]
end

function onCreatePost()
	updateDetectionVars()
	stupidVar('curChar', {
		gfSection and 'gf' or (cameraDetection and forceTargetCheck(1, true) or forceTargetCheck(1, false)),
		gfSection and 'gf' or (cameraDetection and forceTargetCheck(2, true) or forceTargetCheck(2, false)),
		gfSection and 'girlfriend' or (cameraDetection and forceTargetCheck(3, true) or forceTargetCheck(3, false))
	})
	updateCameraInfo(false, true)
end

local savedCamLockPositions = {
	-- ['Example'] = {x = 0, y = 0}
}

---@param membersIndex number Note index.
---@param keyAmount number Amount of keys.
function moveCamNoteDir(membersIndex, keyAmount)
	local gfNote = getPropertyFromGroup('notes', membersIndex, 'gfNote') -- Checks if gf is singing.
	if (gfSection and gfNote) or ((not gfSection and not gfNote) or getProperty('curChar')[1] == 'gf') then
		local noAllow = false
		for index, value in pairs(internalSettings.blacklistedNoteTypes) do
			if getPropertyFromGroup('notes', membersIndex, 'noteType') == value then
				noAllow = true break
			end
		end
		if noAllow then return end
	else
		return
	end

	-- if not getProperty('isCameraOnForcedPos') then
		cancelTriggers()
		updateCameraInfo()
		-- Add your own thing if you want if you have custom options for instance.
		if getProperty('whosActive.' .. (getPropertyFromGroup('notes', membersIndex, 'mustPress') and 'play' or 'oppo')) --[[ and getModSetting('camMoveInNoteDir') ]] then
			local sustainLength = getPropertyFromGroup('notes', membersIndex, 'sustainLength') / 1000 -- When the camera should return to the default position.
			local isSustainNote = getPropertyFromGroup('notes', membersIndex, 'isSustainNote') -- For sustain bullshit.
			local percentMath = 1
			if internalSettings.sustainDisplacement and isSustainNote then
				local maths = getPropertyFromGroup('notes', membersIndex, 'strumTime') - getPropertyFromGroup('notes', membersIndex, 'parent.strumTime')
				percentMath = turnIntoPercent(getPropertyFromGroup('notes', membersIndex, 'parent.sustainLength') - maths, getPropertyFromGroup('notes', membersIndex, 'parent.sustainLength'), 1)
			end
			percentMath = clamp(percentMath, 0, 1)
			--[[ if internalSettings.sustainDisplacement and internalSettings.cleanerMovement then
				if not isSustainNote then
					doTweenX('cleanSustainDisplacementX', below07 and 'targetOffset' or 'camGame.targetOffset', 0, sustainLength, 'linear')
					doTweenY('cleanSustainDisplacementY', below07 and 'targetOffset' or 'camGame.targetOffset', 0, sustainLength, 'linear')
				else
					return
				end
			end ]]
			local calculatedDisplacement = {
				x = getProperty('displacementOffset.x') * percentMath,
				y = getProperty('displacementOffset.y') * percentMath
			}
			local appliedMoveForce = { -- `table` which has the applied `displacementOffset` force.
				{-calculatedDisplacement.x, 0},
				{0, calculatedDisplacement.y},
				{0, -calculatedDisplacement.y},
				{calculatedDisplacement.x, 0}
			}
			triggerVelocity = true
			local noteData = getPropertyFromGroup('notes', membersIndex, 'noteData') -- For which direction it should go in.
			local convertedData = noteDataEKConverter(noteData, checkVarData(keyAmount, 4, 'number')) -- Kinda useless since there are no EK 0.7+ mods.
			setCamOffset(appliedMoveForce[convertedData + 1][1] / getProperty('camGame.zoom'), appliedMoveForce[convertedData + 1][2] / getProperty('camGame.zoom'))
			-- Is only really for using math to get when camera to return at the of the note.
			if internalSettings.sustainDisplacement then
				if not isSustainNote then
					runTimer('cool cam return', (sustainLength > 0 and sustainLength or ((stepCrochet / 1000) * 1.6)) / playbackRate)
				end
			else
				runTimer('cool cam return', ((stepCrochet / 1000) * (isSustainNote and (internalSettings.cleanerMovement and 1 or 0.6) or 1.6)) / playbackRate)
			end
		end
		-- flushSaveData("NOW'S YOUR CHANCE TO TAKE A [[BIG SHIT]]")
	-- end
end

local function sharedNoteHit(membersIndex, keyAmount)
	if (not getProperty('allowBothPresses') and sectionDetection == getPropertyFromGroup('notes', membersIndex, 'mustPress')) or getProperty('allowBothPresses') then
		moveCamNoteDir(membersIndex, keyAmount)
	end
end
function goodNoteHit(membersIndex, noteData, noteType, isSustainNote) sharedNoteHit(membersIndex, getProperty('playerStrums.length')) end
function opponentNoteHit(membersIndex, noteData, noteType, isSustainNote) sharedNoteHit(membersIndex, getProperty('opponentStrums.length')) end
function otherStrumHit(membersIndex, noteData, noteType, isSustainNote, strumLaneTag) sharedNoteHit(membersIndex, getProperty(strumLaneTag .. 'Strums.length')) end

local function sharedNoteMiss(membersIndex, noteData, noteType, isSustainNote)
	local mustPress = getPropertyFromGroup('notes', membersIndex, 'mustPress')
	if getProperty('canSnapOnMiss') and flashingLights and sectionDetection == mustPress and getProperty('whosActive.' .. (mustPress and 'play' or 'oppo')) --[[ and not getProperty('isCameraOnForcedPos') ]] then
		cancelTriggers()
		updateCameraInfo(true)
		triggerEvent('Snap Camera Position')
		if getProperty('camZooming') then setProperty('camGame.zoom', getProperty('defaultCamZoom')) end
	end
	triggerVelocity = false
end
function noteMiss(membersIndex, noteData, noteType, isSustainNote) sharedNoteMiss(membersIndex, noteData, noteType, isSustainNote) end
function noteMissPress(direction) sharedNoteMiss(nil, direction, '', false) end

function onCountdownStarted()
	-- fake cam pos stuff for "Manage Cam Dir Position Lock"
	stupidVar('camFollowFake', {x = 0, y = 0})
end

function onSectionHit()
	updateDetectionVars()
	setProperty('curChar', {
		gfSection and 'gf' or (cameraDetection and forceTargetCheck(1, true) or forceTargetCheck(1, false)),
		gfSection and 'gf' or (cameraDetection and forceTargetCheck(2, true) or forceTargetCheck(2, false)),
		gfSection and 'girlfriend' or (cameraDetection and forceTargetCheck(3, true) or forceTargetCheck(3, false))
	})
	updateCameraInfo(false, true)
end

function onUpdate(elapsed)
	dumbSet('camDisplaceOffset', {
		x = getProperty('displacementOffset.x'),
		y = getProperty('displacementOffset.y')
	})
end

function onUpdatePost(elapsed)
	updateDetectionVars()
	if startedCountdown and not inGameOver and type(getPropertyFromClass('flixel.FlxG', 'camera.target.x')) == 'number' then
		local speedThing = (triggerVelocity and getProperty('camVelocity.active')) and (getProperty('camVelocity.mult') / getProperty('camGame.zoom')) or 1
		if not getProperty('inCutscene') then
			local function bound(value, min, max) return math.max(min, math.min(max, value)) end
			local lerpVal = bound(elapsed * 2.4 * (getProperty('cameraSpeed') * speedThing) * playbackRate, 0, 1)
			local function lerp(a, b, ratio) return a + ratio * (b - a) end
			if below07 then
				setProperty('camFollowPos.x', lerp(getCamPos(true).x, getCamPos().x + getCamOffset().x, lerpVal))
				setProperty('camFollowPos.y', lerp(getCamPos(true).y, getCamPos().y + getCamOffset().y, lerpVal))
			else
				setCamPos(
					lerp(getCamPos(true).x, getCamPos().x + getCamOffset().x, lerpVal),
					lerp(getCamPos(true).y, getCamPos().y + getCamOffset().y, lerpVal),
					true
				)
			end
		end
		-- debugPrint(getProperty('camGame.followLerp'))
	end
end

local function camIdleBop(onPercent)
	if (getProperty('allowCamIdleBop') and startedCountdown) then
		if not charExists(getProperty(getProperty('curChar')[1])) then return end
		local cur = {beatNums = getProperty(getProperty('curChar')[1] .. '.danceEveryNumBeats'), anim = getProperty(getProperty('curChar')[1] .. '.animation.name')}
		local function addIdleSuffix(anim) return anim .. getProperty(getProperty('curChar')[1] .. '.idleSuffix') end
		if --[[ not getProperty('isCameraOnForcedPos') and ]] not getProperty('inCutscene') then
			if getProperty(getProperty('curChar')[1] .. '.danceIdle') then
				if onPercent % cur.beatNums == 0 then -- after bop
					if cur.anim == addIdleSuffix('danceLeft') then
						cancelTriggers()
						updateCameraInfo(true)
						setCamOffset((camDisplaceOffset.x / 2) / getProperty('camGame.zoom'), (-camDisplaceOffset.y / 2) / getProperty('camGame.zoom'))
						runTimer('cam after bop', (crochet / 1000) / 2)
					elseif cur.anim == addIdleSuffix('danceRight') then
						cancelTriggers()
						updateCameraInfo(true)
						setCamOffset((-camDisplaceOffset.x / 2) / getProperty('camGame.zoom'), (-camDisplaceOffset.y / 2) / getProperty('camGame.zoom'))
						runTimer('cam after bop', (crochet / 1000) / 2)
					end
				end
			else
				if cur.anim == addIdleSuffix('idle') then
					if onPercent % cur.beatNums == 0 then
						cancelTriggers()
						updateCameraInfo(true)
						setCamOffset(0, (camDisplaceOffset.y / 2) / getProperty('camGame.zoom'))
						runTimer('cam after bop', (crochet / 1000) / 2)
					end
				end
			end
		end
	end
end

function onCountdownTick(counter) camIdleBop(counter) end
function onBeatHit() camIdleBop(curBeat) end

function onTimerCompleted(tag, loops, loopsLeft)
	-- if not getProperty('isCameraOnForcedPos') then
		if tag == 'cool cam return' then
			triggerVelocity = false
			updateCameraInfo(true)
		end

		if tag == 'cam after bop' then
			updateCameraInfo(true)
		end
	-- end
end

function onEvent(name, value1, value2, eventTime)
	if name == 'Camera Set Target' then
		local splitContents = {v1 = {}, v2 = {}}
		splitContents.v1 = textSplit(value1, ',')
		splitContents.v2 = textSplit(value2, ',')
		setToCharCamPosition(splitContents.v1[1], {splitContents.v2[1], splitContents.v2[2]}, true)
	end

	if name == 'Camera Follow Pos' then
		local pos = {x = tonumber(value1), y = tonumber(value2)}
		if type(pos.x) ~= 'number' or type(pos.y) ~= 'number' then
			setProperty('ifCamLocked.oppo.active', false)
			setProperty('ifCamLocked.play.active', false)
		else
			-- setProperty('isCameraOnForcedPos', false)
			setProperty('ifCamLocked.oppo.active', true)
			setProperty('ifCamLocked.oppo.x', pos.x)
			setProperty('ifCamLocked.oppo.y', pos.y)
			setProperty('ifCamLocked.play.active', true)
			setProperty('ifCamLocked.play.x', pos.x)
			setProperty('ifCamLocked.play.y', pos.y)
		end
	end

	if name == 'Manage Cam Point Chars' then
		local splitContents = {v1 = {}, v2 = {}}
		splitContents.v1 = textSplit(value1, ',')
		splitContents.v2 = textSplit(value2, ',')

		for i = 1, 3 do
			setProperty('camPointChars.oppo[' .. (i - 1) ..']', checkVarData(splitContents.v1[i], getProperty('camPointChars.oppo')[i], 'string'))
			setProperty('camPointChars.play[' .. (i - 1) ..']', checkVarData(splitContents.v2[i], getProperty('camPointChars.play')[i], 'string'))
		end
		if value1 == 'default' then
			setProperty('camPointChars.oppo', {'dad', 'dad', 'opponent'})
		end
		if value2 == 'default' then
			setProperty('camPointChars.play', {'boyfriend', 'bf', 'boyfriend'})
		end
	end

	if name == 'Manage Cam Dir Properties' then
		local splitContents = {v1 = {}, v2 = {}}
		splitContents.v1 = textSplit(value1, ',')
		splitContents.v2 = textSplit(value2, ',')

		setProperty('displacementOffset.x', checkVarData(splitContents.v1[1], getProperty('displacementOffset.x'), 'number'))
		setProperty('displacementOffset.y', checkVarData(splitContents.v1[2], getProperty('displacementOffset.y'), 'number'))
		if splitContents.v1[3] == 'player' then
			setProperty('whosActive.oppo', false)
			setProperty('whosActive.play', true)
		elseif splitContents.v1[3] == 'opponent' then
			setProperty('whosActive.oppo', true)
			setProperty('whosActive.play', false)
		elseif splitContents.v1[3] == 'both' then
			setProperty('whosActive.oppo', true)
			setProperty('whosActive.play', true)
		elseif splitContents.v1[3] == 'none' then
			setProperty('whosActive.oppo', false)
			setProperty('whosActive.play', false)
		else
			if checkVarData(splitContents.v1[3], nil, 'string') ~= nil then
				debugPrint('Please put "player", "opponent", "both" or "none".')
				debugPrint('Action "' .. splitContents.v1[3] .. '" is not a selectable thing.')
			end
		end

		setProperty('camVelocity.active', checkVarData(splitContents.v2[1], getProperty('camVelocity.active'), 'boolean'))
		setProperty('camVelocity.mult', checkVarData(splitContents.v2[2], getProperty('camVelocity.mult'), 'number'))
	end

	if name == 'Manage Cam Dir Position Lock' then
		local splitContents = {v1 = {}, v2 = {}}
		splitContents.v1 = textSplit(value1, ',')
		splitContents.v2 = textSplit(value2, ',')

		if type(tonumber(splitContents.v1[1])) == 'number' then
			setProperty('ifCamLocked.oppo.active', true)
			setProperty('ifCamLocked.oppo.x', checkVarData(splitContents.v1[1], getProperty('ifCamLocked.oppo.x'), 'number'))
			setProperty('ifCamLocked.oppo.y', checkVarData(splitContents.v1[2], getProperty('ifCamLocked.oppo.y'), 'number'))
		elseif splitContents.v1[1] == 'previous' then
			setProperty('ifCamLocked.oppo.active', true)
		elseif splitContents.v1[1] == 'from char' then
			setToCharCamPosition(splitContents.v1[2], {splitContents.v1[3], splitContents.v1[4]}, false, true)
			setProperty('ifCamLocked.oppo.x', checkVarData(getProperty('camFollowFake.x'), getProperty('ifCamLocked.oppo.x'), 'number'))
			setProperty('ifCamLocked.oppo.y', checkVarData(getProperty('camFollowFake.y'), getProperty('ifCamLocked.oppo.y'), 'number'))
			setProperty('ifCamLocked.oppo.active', true)
		elseif splitContents.v1[1] == 'load from save' or splitContents.v1[1] == 'load' then
			setProperty('ifCamLocked.oppo.x', checkVarData(savedCamLockPositions[splitContents.v1[2]].x, getProperty('ifCamLocked.oppo.x'), 'number'))
			setProperty('ifCamLocked.oppo.y', checkVarData(savedCamLockPositions[splitContents.v1[2]].y, getProperty('ifCamLocked.oppo.y'), 'number'))
			setProperty('ifCamLocked.oppo.active', true)
		else
			setProperty('ifCamLocked.oppo.active', false)
		end

		if type(tonumber(splitContents.v2[1])) == 'number' then
			setProperty('ifCamLocked.play.active', true)
			setProperty('ifCamLocked.play.x', checkVarData(splitContents.v2[1], getProperty('ifCamLocked.play.x'), 'number'))
			setProperty('ifCamLocked.play.y', checkVarData(splitContents.v2[2], getProperty('ifCamLocked.play.y'), 'number'))
		elseif splitContents.v2[1] == 'previous' then
			setProperty('ifCamLocked.play.active', true)
		elseif splitContents.v2[1] == 'from char' then
			setToCharCamPosition(splitContents.v2[2], {splitContents.v2[3], splitContents.v2[4]}, false, true)
			setProperty('ifCamLocked.play.x', checkVarData(getProperty('camFollowFake.x'), getProperty('ifCamLocked.play.x'), 'number'))
			setProperty('ifCamLocked.play.y', checkVarData(getProperty('camFollowFake.y'), getProperty('ifCamLocked.play.y'), 'number'))
			setProperty('ifCamLocked.play.active', true)
		elseif splitContents.v2[1] == 'load from save' or splitContents.v2[1] == 'load' then
			setProperty('ifCamLocked.play.x', checkVarData(savedCamLockPositions[splitContents.v2[2]].x, getProperty('ifCamLocked.play.x'), 'number'))
			setProperty('ifCamLocked.play.y', checkVarData(savedCamLockPositions[splitContents.v2[2]].y, getProperty('ifCamLocked.play.y'), 'number'))
			setProperty('ifCamLocked.play.active', true)
		else
			setProperty('ifCamLocked.play.active', false)
		end
	end

	if name == 'Manage Saved Lock Positions' then
		local splitContents = {v1 = {}, v2 = {}}
		splitContents.v1 = textSplit(value1, ',')
		splitContents.v2 = textSplit(value2, ',')

		if splitContents.v1[1] == 'new' then
			savedCamLockPositions[splitContents.v1[2]] = {
				x = tonumber(splitContents.v2[1]),
				y = tonumber(splitContents.v2[2])
			}
		elseif splitContents.v1[1] == 'edit' then
			savedCamLockPositions[splitContents.v1[2]].x = tonumber(splitContents.v2[1])
			savedCamLockPositions[splitContents.v1[2]].y = tonumber(splitContents.v2[2])
		end
		dumbSet('savedCamLockPoses', savedCamLockPositions)
		if getPropertyFromClass((below07 and '' or 'states.') .. 'PlayState', 'chartingMode') then debugPrint(splitContents.v1[2] .. ': ' .. savedCamLockPoses[splitContents.v1[2]]) end
	end

	if name == 'Snap Camera Position' then
		setCamOffset(0, 0)
		setCamPos(getCamPos().x, getCamPos().y, true)
	end
end