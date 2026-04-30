----- [[ Script by @rodney528 ]] -----

----- [[ Potential Ideas ]] -----

--[[

	"_runHaxe..." functions.
	"writeJson" function mayhaps?

]]--

----- [[ Utility Functions ]] -----

---Check's if the input is nil.
---@generic input
---@param variable any The data to check.
---@param ifNil input What should be returned if nil.
---@return input # The checked data.
local function nilCheck(variable, ifNil)
	return (type(variable) == 'nil' or variable == nil) and ifNil or variable
end

---Check's if your running on v1 instances of Psych Engine.
---@param exact? boolean If true, it will look for v1.0.4 specifically.
---@return boolean # The results of the check.
local function isNew(exact)
	return nilCheck(exact, false) and version == '1.0.4' or version >= '1.0'
end
---Check's if your running on v0.7 instances of Psych Engine.
---@param exact? boolean If true, it will look for v0.7.3 specifically.
---@return boolean # The results of the check.
local function isLegacy(exact)
	return nilCheck(exact, false) and version == '0.7.3' or (version <= '0.7.3' and version >= '0.7')
end
---Check's if your running on v0.6 instances of Psych Engine.
---@param exact? boolean If true, it will look for v0.6.3 specifically.
---@return boolean # The results of the check.
local function isBeta(exact)
	return nilCheck(exact, false) and version == '0.6.3' or (version <= '0.6.3' and version >= '0.6')
end
-- it would be funny to add smth like "isOutdated" but nah, lol

---String interpolation in lua!
---@param ... any The data to be interpolated.
---@return string # The interpolated data.
local function f(...)
	---@param value table
	---@return string
	local function stringifyTable(value)
		-- can't use "_setVar" because it uses "f" and I don't wanna put "f" anymore downwards than it has to be
		if isBeta() then
			runHaxeCode([[ setVar('f_varHolder', null); ]])
			setProperty('f_varHolder', value)
		else
			setVar('f_varHolder', value)
		end

		-- can't use "prepImports" here for the same reason as "_setVar"
		if not isNew() then addHaxeLibrary('Std') end
		runHaxeCode((isNew() and 'import Std;' or '') .. [[ setVar('f_varHolder', Std.string(getVar('f_varHolder'))); ]])
		return getProperty('f_varHolder')
	end

	local final = ''
	for index, value in pairs({...}) do
		local part = value
		part = type(part) == 'table' and stringifyTable(part) or tostring(part)
		part = nilCheck(part, 'nil')
		final = final .. part
	end
	return final
end

---Split's a piece of string into an array of your typing choice.
---@generic input
---@param text string The text to split.
---@param delimiter string What to split by.
---@param renderer? fun(index: integer, piece: string): input Allows you to customize how the data gets returned.
---@return input[] # The split up content.
local function textSplit(text, delimiter, renderer)
	local splitTxt = stringSplit(text, delimiter) ---@type string[]
	local finalArray = {} ---@type input[]
	for index, value in pairs(splitTxt) do
		if nilCheck(renderer, 'buh') == 'buh' then
			table.insert(finalArray, stringTrim(value))
		else
			table.insert(finalArray, renderer(stringTrim(value)))
		end
	end
	return finalArray
end

---Useful for prepping imports for runHaxeCode usage.
---@param ... string[] The imports to prep.
---@return string # If on v0.7 or higher, this returns the imports pre-prepped in the haxe language.
local function prepImports(...)
	local final = ''
	for index, path in pairs({...}) do
		if isBeta() then
			runHaxeCode(f([[
				var preppedImports:Array<String> = ']], path, [['.split('.');
				setVar('prepImports_varHolder', [preppedImports.pop(), preppedImports.join('.')]);
			]]))
			local finalzedImport = getProperty('prepImports_varHolder') ---@type string[][]
			addHaxeLibrary(finalzedImport[1], finalzedImport[2])
		else
			final = f(final, 'import ', path, ';\n')
		end
	end
	return final
end

---Checks if the charting mode is active.
---@return boolean # The state of charting mode.
local function isChartingMode()
	return getPropertyFromClass(f(isBeta() and '' or 'states.', 'PlayState'), 'chartingMode')
end

---A shortcut function for debugPrint, with some extra stuff to it.
---@todo Add "color" argument.
---@param value any What you wish to debugPrint.
---@param isDebug? boolean If true, this will only print when in charting mode or lua debug mode.
local function trace(value, isDebug)
	-- for eventual color support
	local function code()
		-- wrapped in "f" jic you pop a single table in here
		debugPrint(f(value))
	end
	if nilCheck(isDebug, false) then
		if isChartingMode() or luaDebugMode then
			code()
		end
	else
		code()
	end
end

---Returns the contents of a json file.
---##### Thanks to my friend @atlasgamer27 for helping me figure this out! lol
---@param path string The file path.
---@param printWarning? boolean If true, it will print a warning if the file doesn't exist.
---@return table | any[] | nil # The jsons contents.
local function parseJson(path, printWarning)
	local filePath = f(path, '.json')
	local fileContents = ''
	if checkFileExists(filePath) then
		fileContents = getTextFromFile(filePath) ---@type string
	else
		if printWarning then
			trace(f('File not found: ', filePath))
		end
		return nil
	end

	runHaxeCode(f(
		prepImports('haxe.format.JsonParser'),
		[[ setVar('jsonData_varHolder', new JsonParser(']], fileContents, [[').doParse()); ]]
	))
	return getProperty('jsonData_varHolder')
end

---Used to make setVar usage compatible with older versions.
---@param variable string The variable name.
---@param value any What the variable stores.
local function _setVar(variable, value)
	if isBeta() then
		runHaxeCode(f('setVar("',  variable,  '", null);'))
		setProperty(variable, value)
	else
		setVar(variable, value)
	end
end

---Used to make setOnScripts usage compatible with older versions.
---@param variable string The variable name.
---@param value any What the variable stores.
---@param ignoreSelf? boolean Wether to not set the variable on itself.
---@param exclusions? string[] Specific scripts to not set the variable for.
---@param luaOnly? boolean If true, it only calls setOnLuas when on newer versions.
local function _setOnScripts(variable, value, ignoreSelf, exclusions, luaOnly)
	if isBeta() then
		_setVar('setOnLuas_varHolder', {variable, value})
		runHaxeCode([[
			var varHolder:Array<Dynamic> = getVar('setOnLuas_varHolder');
			game.setOnLuas(varHolder[0], varHolder[1]);
			varHolder.resize(0);
		]])
	else
		ignoreSelf = nilCheck(ignoreSelf, false)
		exclusions = nilCheck(exclusions, {})
		if nilCheck(luaOnly, false) then
			setOnLuas(variable, value, ignoreSelf, exclusions)
		else
			setOnScripts(variable, value, ignoreSelf, exclusions)
		end
	end
end

---Used to make callOnScripts usage compatible with older versions.
---@todo Add a workaround for v0.7 always returning true.
---@param func string The function name.
---@param arguments? any[] The function arguments.
---@param ignoreStops? boolean Wether to ignore "Function_Stop" calls.
---@param ignoreSelf? boolean Wether the script should ignore itself. Useful for preventing recursion!
---@param excludedScripts? string[] Specific scripts to not call upon.
---@param excludedValues? any[] Values to prevent from being returned.
---@param luaOnly? boolean If true, it only calls callOnLuas when on newer versions.
---@return any # Note: Always returns true on v0.7 for some reason? Might add a workaround, but I'm unsure atm.
local function _callOnScripts(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues, luaOnly)
	arguments = nilCheck(arguments, {})
	ignoreStops = nilCheck(ignoreStops, false)
	ignoreSelf = nilCheck(ignoreSelf, true)
	excludedScripts = nilCheck(excludedScripts, {})
	if isBeta() then
		return callOnLuas(func, arguments, ignoreSelf, excludedScripts)
	else
		excludedValues = nilCheck(excludedValues, {})
		if nilCheck(luaOnly, false) then
			return callOnLuas(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues)
		else
			return callOnScripts(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues)
		end
	end
end

---Checks if a property exists.
---@param variable string The property to check.
---@return boolean # Wether it exists.
local function doesPropertyExist(variable)
	local lol = getProperty(variable) ---@type any
	return not (type(lol) == 'nil' or lol == variable)
end

----- [[ Example Uses ]] -----

-- simple debug trace for version range
trace(f(
	'\nIs New: ', isNew(true), ' (v1.0.4)\n',
	'Is Legacy: ', isLegacy(true), ' (v0.7.3)\n',
	'Is Beta: ', isBeta(true), ' (v0.6.3)\n',
	'Is Outdated: ', version < '0.6', ' (v0.5.2)'
), true)

-- below v0.6 warning message
if version < '0.6' then
	trace(f(
		'\nHey, this script only works on Psych v0.6 and above!\n',
		'Psych v', version, ' isn\'t compatible with the script whatsoever!'
	))
	return close(true)
elseif not (isNew(true) or isLegacy(true) or isBeta(true)) then
	trace(f(
		'\nHey, this script might not work properly on Psych v', version, '!\n',
		'If you wish for the script to work appropriately, please use versions...\n',
		'v0.6.3, v0.7.3 or v1.0.4! If the script works perfectly fine, then just ignore this message.'
	), true)
end

-- basic example on how to use prepImports
runHaxeCode(f(
	prepImports('flixel.addons.display.FlxBackdrop'),
	[[ var ahh:FlxBackdrop = new FlxBackdrop(Paths.image('characters/BOYFRIEND')); ]]
))
-- maybe make the second arg be runHaxeCode?
-- "_runHaxeCode" with prepImports built in?

-- cool type definitioning
local integers = textSplit('1, 2, 3', ',',
	function (index, piece)
		return math.floor(tonumber(piece))
	end
)
trace(integers) -- returns "{1, 2, 3}"

---@param index integer
---@param piece string
---@return number
function sampleFunc(index, piece) return tonumber(piece) end
local numbers = textSplit('12, 0.45, 0.3', ',', sampleFunc)
trace(numbers) -- returns "{12, 0.45, 0.3}"

-- JSON PARSING, BITCH!
parseJson('characters/bf', true) -- if missing, prints "File not found: characters/bf.json"

-- property existence check
getProperty('gf.x') -- in older versions, this returns "gf.x"???
getProperty('gf.x') -- in newer versions, this returns `nil`
doesPropertyExist('gf.x') -- returns a bool
-- way more consistent!