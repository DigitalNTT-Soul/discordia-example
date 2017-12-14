
local fs = require('fs')
local pathjoin = require('pathjoin')
local timer = require('timer')
local http = require('coro-http')
local json = require('json')

local logger = discordia.Logger(4, '%F %T', 'discordia.log')

local client

local dir = module.dir

local splitPath, pathJoin = pathjoin.splitPath, pathjoin.pathJoin
local readFile, scandir = fs.readFileSync, fs.scandirSync
local remove = table.remove
local sub, format = string.sub, string.format

_G.json = json
_G.http = http

local mainframe = {
	listeners = {},
	modules = {},
	extentions = {
		MAINFRAME = dir .. '/',
		DATA = dir .. '/data/',
		COMMANDS = dir .. '/commands/',
		LISTENERS = dir .. '/listeners',
		LEVELS = dir .. '/data/levels/',
		MESSAGES = dir .. '/data/messages/',
		MODERATION = dir .. '/data/moderation/',
		SETTINGS = dir .. '/data/settings/'
	},
	dir = dir
}

function mainframe:info(fmt, ...)

	local str = string.format(fmt, ...)
	str = string.gsub(str, '\n', '\n                                | ')

	return logger:log(3, str)

end

function mainframe:warn(fmt, ...)

	local str = string.format(fmt, ...)
	str = string.gsub(str, '\n', '\n                                | ')

	return logger:log(2, str)

end

function mainframe:err(fmt, ...)

	local str = string.format(fmt, ...)
	str = string.gsub(str, '\n', '\n                                | ')

	return logger:log(1, str)

end

mainframe.database = {}
function mainframe.database:get(node)

	if not mainframe.firebase then mainframe:warn('Google Firebase was not Authenticated') end
	return mainframe.firebase:get(node)

end

function mainframe.database:new(node, payload)

	if not mainframe.firebase then mainframe:warn('Google Firebase was not Authenticated') end
	return mainframe.firebase:set(node, payload)

end

local users = {}

function users:new(id, level)

	--// clamp to real levels, makes forcing developer impossible, set in database
	level = math.clamp(level or 0, 0, 4)

	--// retrieve guild based info from database
	local info = mainframe.database:get('user-levels') or {}

	--// cannot set a user to a level higher than guild owner without being the bot owner
	if level > 3 and id ~= client.owner.id then return self, false end
	
	--// set the level
	info[id] = level

	--// overwrite info in the database
	mainframe.database:new('user-levels', info)

	--// update cache
	self[id] = level
	return self, true

end

function users:get(id)

	-- retrieve guild based info from database
	local info = mainframe.database:get('user-levels') or {}

	local ret = {}

	--// default to 0
	local level = info[id] or 0

	ret.level = level
	ret.name = settings.util.levels[level].name

	return ret, true

end

function mainframe:env(old)

	local env = setmetatable({
		require = require,
		client = client,
		discordia = discordia,

		mainframe = self,
		module = module,

		fs = fs,
		pathjoin = pathjoin,
		timer = timer,
		json = json,
		http = http,
		self = self,

		settings = settings,
		guilds = guilds,
		users = users
	}, { __index = _G })

	if old and type(old) == 'table' then
		for k, v in pairs(old) do
			env[k] = v
		end
	end

	return env

end

function mainframe:loadmodule(path, env)

	local code = assert(readFile(path)) --// find file and read for code
	local name = remove(splitPath(path)) --// parse name for logging purposes

	env = self:env(env)

	local module, err = loadstring(code, name, 't', env) --// compile code

	if not module then
		--// execute if error
		return client:error(err)
	end

	return module(), true
end

function mainframe:loadmodules(path)

	local ret = {}

	--// scan directory
	for k, v in scandir(path) do
		if v == 'file' and k:sub(#k - 3) == '.lua' then
			--// run loadmodule
			local res, success = mainframe:loadmodule(pathJoin(path, k))
			local name = k:sub(1, #k-4)
			if not success then
				--// error to client
				client:error('Unhandled module loading error in ' .. k)
			else
				ret[name] = res	
			end
		end
	end

	return ret

end

function mainframe:handle(name, listener)

	local path = module.dir .. '/listeners/' .. name .. '.lua'

	--// remove previous listener
	if mainframe.listeners[name] then
		client:removeListener(name, mainframe.listeners[name])
	end
	mainframe.listeners[name] = listener

	--// connect listener to client event
	client:on(name, listener)

end

function mainframe:load()

	self.listeners = self:loadmodules(module.dir .. '/listeners/') --// load all listeners
	self.commands = self:loadmodules(module.dir .. '/commands/') --// load all commands
	local firebase = self:loadmodule(module.dir .. '/utils/firebase.lua') --// initilize database

	if settings.firebase.key ~= '' then
		--// check for empty key, final failsafe for initilizing firebase, will fail if invalid information is provided
		firebase(settings.firebase.root, settings.firebase.key, { settings.firebase.email, settings.firebase.password })

		mainframe.firebase = firebase
	end

end

function init(options, callback)

	mainframe:info('Mainframe Loading Started')
	client = options.client

	--// set startup mainframe variables
	mainframe.modules = {}
	mainframe.listeners = {}
	mainframe.startup = options.start or os.time()
	discordia.extensions()

	--// set special logging and access variables in client
	client._started = os.time()
	client._latency = {[0] = 0}
	client._mainframe = mainframe
	mainframe:load() --// main initilization
	mainframe:info('Mainframe Loading Ended')
	callback()

	return mainframe
	
end

return init