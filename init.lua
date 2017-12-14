
local discordia = require('discordia')
local fs = require('fs')
local json = require('json')

local running
local dir = module.dir
local init = {}

function init:error(err)

	print('Initilization Error: ' .. err)
	process.exit(1)

end

function init:settings()

	local settings = {}

	local file = fs.readFileSync(dir .. '/config.json')
	if not file then return settings end

	local decoded = json.parse(file)

	for k, v in pairs(decoded) do

		settings[k] = v

	end

	settings.util = require('./utils.lua')(discordia)
	return settings

end

function init:client(options)

	local client = discordia.Client(options)
	return client

end

function init:mainframe(settings)

	local code = assert(fs.readFileSync(dir .. '/mainframe.lua'))

	env = setmetatable({
		discordia = discordia,
		module = { dir = dir, path = dir .. '/mainframe.lua' },
		settings = settings,
		require = require
	}, { __index = _G })

	local frmwrk, err = loadstring(code, 'Mainframe', 't', env)

	if not frmwrk then

		self:error(err)

	end

	return frmwrk()

end

function init:start()

	local settings = self:settings()
	local client = self:client(settings['client-options'])
	local token = settings.token
	local mainframe = self:mainframe(settings)

	coroutine.wrap(mainframe)({ client = client, start = init.startup }, function()

		client:run(token)
		running = client

	end)

end

init.startup = os.time()

return init:start()