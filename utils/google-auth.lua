local http = require('coro-http')
local json = require('json')

local function identify(appstr, payload, key)
	local uri = string.format('https://www.googleapis.com/identitytoolkit/v3/relyingparty/%s?key=%s', appstr, key)
	local datastring = json.encode(payload)
	local res, body = http.request('POST', uri, { { 'Content-Type', 'application/json' }, { 'Content-Length', #datastring } }, datastring)
	if res.code ~= 200 then print('Failed To Retrieve Firebase Auth Token: ' .. res.code .. ' "' .. body .. '"') process:exit() end
	return json.decode(body)
end

local function emailauth(email, password, key)
	return identify("verifyPassword",{ email = email, password = password, returnSecureToken = true }, key)
end

local function refresh(rtoken, key)
	local uri = string.format('https://securetoken.googleapis.com/v1/token?key=%s', key)
	local datastring = json.encode({
		grant_type = "refresh_token",
		refresh_token = rtoken
	})
	local res, body = http.request('POST', uri, { { 'Content-Type', 'application/x-www-form-urlencoded' } }, datastring)
	if res.code ~= 200 then print('Failed To Refresh Firebase Auth Token: ' .. res.code .. ' "' .. body .. '"') process:exit() end
	return json.decode(body)
end

return {
	email = emailauth,
	refresh = refresh
}