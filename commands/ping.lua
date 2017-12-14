
return {
	name = 'Ping',
	description = 'Displays the current ping between the bot and discord',
	command = 'ping',
	level_required = 4,
	handler = function(message, userlevel, args)

		return 0, {
			title = 'Discord Latency [From Client]',
			description = 'API: ' .. math.abs(math.ceil((os.time() - message.createdAt) * 1000)) .. 'ms\nGateway: ' .. (client._latency[0] == 0 and 'Not Received' or client._latency[0] .. 'ms')
		}
		
	end
}