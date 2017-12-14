
return {
	name = 'Help',
	description = 'Displays all commands you have access to run',
	command = 'help <command>',
	level_required = 0,
    handler = function(message, userlevel, args)

        if args[1] then
            for name, info in pairs(self.commands) do

                if info.level_required <= userlevel.level then
                    if info.name:lower() == args[1]:lower() then

                        return 0, {
                            title = info.name,
                            description = info.description .. '\n\n' .. 'Usage: `!' .. info.command .. '`\n'
                        }

                    end
                end
                
            end

            return 1, 'The command you entered: **' .. args[1]:lower() .. '** is not a valid command.'

        else

            return 1, 'Please enter a command'

        end

	end
}