-- Script by @rodney528

-- Utility functions.

---Check's if the input is nil.
---@generic input
---@param variable any
---@param ifNil input
---@return input
local function nilCheck(variable, ifNil)
	return (type(variable) == 'nil' or variable == nil) and ifNil or variable
end

---Check's if your running on v1 instances of Psych Engine.
---@param exact? boolean If true, it will look for v1.0.4 specifically.
---@return boolean
local function isNew(exact)
	return nilCheck(exact, false) and version == '1.0.4' or version >= '1.0'
end
---Check's if your running on v0.7 instances of Psych Engine.
---@param exact? boolean If true, it will look for v0.7.3 specifically.
---@return boolean
local function isLegacy(exact)
	return nilCheck(exact, false) and version == '0.7.3' or (version <= '0.7.3' and version >= '0.7')
end
---Check's if your running on v0.6 instances of Psych Engine.
---@param exact? boolean If true, it will look for v0.6.3 specifically.
---@return boolean
local function isBeta(exact)
	return nilCheck(exact, false) and version == '0.6.3' or (version <= '0.6.3' and version >= '0.6')
end

---String interpolation in lua!
---@param ... any
---@return string
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

---Split's a piece of string into an array.
---@param text string
---@param delimiter string
---@return string[]
local function textSplit(text, delimiter)
	local splitTxt = stringSplit(text, delimiter) ---@type string[]
	for index, value in pairs(splitTxt) do
		splitTxt[index] = stringTrim(value)
	end
	return splitTxt
end

---Checks if the charting mode is active.
---@return boolean
local function isChartingMode()
	return getPropertyFromClass(f(isBeta() and '' or 'states.', 'PlayState'), 'chartingMode')
end

---A shortcut function for debugPrint with some extra stuff to it.
---@param value any What you wish to debugPrint.
---@param isDebug? boolean If true, this will only print when in charting mode.
local function trace(value, isDebug)
	if nilCheck(isDebug, false) then
		if isChartingMode() then
			debugPrint(f(value))
		end
	else -- wrapped in "f" jic you pop a single table in here
		debugPrint(f(value))
	end
end

---Returns the contents of a json file.
---@param path string The file path.
---@param printWarning? boolean If true, it will print a warning if the file doesn't exist.
---@return table | nil
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

	if not isNew() then addHaxeLibrary('JsonParser', 'haxe.format') end
	runHaxeCode(f(
		isNew() and 'import haxe.format.JsonParser;' or '',
		[[ var fileContents:String = ']], fileContents, [[';
		var jsonData = new JsonParser(fileContents).doParse();
		setVar('jsonData_varHolder', jsonData); ]]
	))

	return getProperty('jsonData_varHolder')
end

---Used to make setVar usage compatible with older versions.
---@param variable string The variable name.
---@param value any What the variable stores.
function _setVar(variable, value)
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
function _setOnScripts(variable, value, ignoreSelf, exclusions, luaOnly)
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
---@param func string The function name.
---@param arguments? any[] The function arguments.
---@param ignoreStops? boolean Wether to ignore "Function_Stop" calls.
---@param ignoreSelf? boolean Wether the script should ignore itself. Useful for preventing recursion!
---@param excludedScripts? string[] Specific scripts to not call upon.
---@param excludedValues? any[] Values to prevent from being returned.
---@param luaOnly? boolean If true, it only calls callOnLuas when on newer versions.
---@return any returnValue Note: Always returns true on 0.7.3 for some reason? Might add a workaround, but I'm unsure atm.
function _callOnScripts(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues, luaOnly)
	arguments = nilCheck(arguments, {})
	ignoreStops = nilCheck(ignoreStops, false)
	ignoreSelf = nilCheck(ignoreSelf, true)
	excludedScripts = nilCheck(excludedScripts, {})
	if isBeta() then
		return callOnLuas(func, arguments, ignoreSelf, excludedScripts)
	else
		excludedValues = nilCheck(excludedValues, {})
		if nilCheck(luaOnly, false) then
			return callOnLuas(func, arguments, ignoreSelf, excludedScripts, excludedValues)
		else
			return callOnScripts(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues)
		end
	end
end

---Checks if a property exists.
---@param variable string
---@return boolean
local function doesPropertyExist(variable)
	local lol = getProperty(variable) ---@type any
	return not (type(lol) == 'nil' or lol == variable)
end