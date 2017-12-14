
function handler(message)

	if message.author.bot and settings['ignore-bot-messages'] then return end
	
	if message.author.discriminator == '0000' and settings['ignore-webhook-messages'] then return end

	local prefix = settings.prefix

	local level = users:get(message.author.id)

	for name, info in pairs(self.commands) do

		local parse = {
			name = info.name:lower(),
			level = info.level_required,
			handler = info.handler
		}
		
		local cmd, args = message.content:match('(%S+)%s*(.*)')

		if cmd:sub(1, #prefix) == prefix then

			local rancmd = cmd:sub(#prefix + 1):lower()

			if rancmd == parse.name then

				local cmdargs = {}
				if args then
					for arg in string.gmatch(args, '[^' .. settings.batch .. ']+') do
						table.insert(cmdargs, arg)
					end
				end

				if level.level >= parse.level then

					local success, err = pcall(function()

						local code, embed, delete = parse.handler(message, level, cmdargs)

						-- Status Codes:
						-- 0: success
						-- 1: error

						local newembed = type(embed) == 'table' and embed or { description = embed }
						
						if code == 0 then

							response = message.channel:send({ embed = newembed })

						elseif code == 1 then

							newembed.title = 'Command Error'

							response = message.channel:send({ embed = newembed })
							self:err(embed)

						end

					end)

					if not success then

						message.channel:send({ embed = {
							title = 'Command Error',
							description = 'Unknown Error Occured.'
						} })

						self:err(err)

					end

				else

					message.channel:send({ embed = {
						title = 'Command Error',
						description = 'This command is limited to users **' .. settings.util.levels[parse.level].name .. '** and above.\nYour level is **' .. level.name .. '**'
					} })

				end

			end

		end

	end

end

self:handle('messageCreate', handler)