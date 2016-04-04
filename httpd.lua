local M = {
	port = 80,
	timeout = 30,
	GET = { },
	POST = { }
}

local function sendError(socket, code)
	socket:send("HTTP/1.1" .. code
		.. "\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n" .. code)
	print("HTTP/1.1 " .. code)
end

local function parseForm(str)
	local ret = { }
	for k, v in string.gmatch(str, "(%w+)=([^&]*)") do
		ret[k] = v
	end
	return ret
end

local function onReceive(socket, request)
	local method, resource, query = string.match(request, "^([A-Z]+) ([^ ?]+)%??([^ ]*) HTTP/1.1")
	if method == nil or resource == nil then
		socket:close()
		return
	end
	print(method .. " " .. resource .. " HTTP/1.1")

	local requestListener = M[method][resource]
	if requestListener == nil then
		sendError(socket, "404 Not Found")
		return
	end
	
	local args
	if method == "GET" then
		args = parseForm(query)
	elseif method == "POST" then
		if not string.find(request, "Content-Type: application/x-www-form-urlencoded", 1, true) then
			sendError(socket, "501 Not Implemented")
			return
		end
		query = string.match(request, "\r\n\r\n(.*)")
		args = parseForm(query)
	end

	local response = requestListener(args)
	socket:send(response)
	print(string.match(response, "([^\r]*)"))
end

local function onSent(socket)
	socket:close()
end

local function onConnect(socket)
	socket:on("receive", onReceive)
	socket:on("sent", onSent)
end

function M.start()
	M.server = net.createServer(net.TCP, M.timeout)
	M.server:listen(M.port, onConnect)
end

function M.stop()
	M.server:close()
	M.server = nil
end

return M