
function handler()
    
    self:info('Logged in as: ' .. client.user.fullname)

end

self:handle('ready', handler)