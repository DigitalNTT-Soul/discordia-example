
--// Thanks to Tigerism for the base api

local firebase = {}

local firebaseauth = require('./utils/google-auth')

local root
local auth
local key
local refresh

local refresh_info = {}
coroutine.wrap(function()
    repeat timer.sleep(1000) until refresh_info.expires
    while true do
        timer.sleep(1000)
        if refresh_info.expires and refresh_info.expires < os.time() then
            local body = firebaseauth.refresh(refresh, key)
            refresh = body.refreshToken
            auth = body.id_token
            refresh_info.expires = os.time() + body.expires_in
            print('Authentication Token Refreshed For ' .. refresh_info.body.email)
        end
    end
end)()

setmetatable(firebase, {
    __call = function(this, dbroot, projectkey, authtab)
        root = dbroot or ''
        key = projectkey or ''
        if type(authtab) == 'table' then
            local body = firebaseauth.email(authtab[1] or '', authtab[2] or '', key)
            refresh_info.body = body
            auth = body.idToken
            refresh = body.refreshToken
            refresh_info.expires = os.time() + body.expiresIn
            self:warn('Firebase Authenticated For %s', body.email)
            this._authenticated = true
            return this
        end
    end
})

local format = string.format
local function formatNonAuth(node)
    return format('https://%s.firebaseio.com/%s.json', root, node)
end
local function formatAuth(node)
    return format('https://%s.firebaseio.com/%s.json?auth=%s', root, node, auth)
end

--// https://github.com/Tigerism/luvit-firebase/blob/master/firebase.lua#L15-L50
function firebase:request(node, method, callback, content)
    if not root or not key then return end
	local uri = auth and formatAuth(node) or formatNonAuth(node)
    local headers, body = http.request(method, uri, { { 'Content-Type', 'application/json' } }, content)
    if callback and type(callback) == 'function' then
        callback(body, headers)
    end
    return json.decode(body)
end

function firebase:get(node, callback)
	return self:request(node, 'GET', callback)
end

function firebase:set(node, content, callback)
    content = json.encode(content)
	return self:request(node, 'PUT', callback, content)
end

function firebase:update(node, content, callback)
	content = type(content) == 'table' and json.encode(content) or content
	return self:request(node, 'PATCH', callback, content)
end

function firebase:push(node, content ,callback)
	content = type(content) == 'table' and json.encode(content) or content
	return self:request(node, 'POST', callback, content)
end

function firebase:delete(node, callback)
	return self:request(node, 'DELETE', callback)
end

return firebase