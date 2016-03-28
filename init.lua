httpd = require("httpd")

local pin = 0

httpd.GET["/"] = function(args)
	local level = gpio.read(pin);
	return table.concat({
		"HTTP/1.1 OK",
		"Content-Type: text/html",
		"Connection: close",
		"",
		"<!DOCTYPE html>",
		"<html>",
		"<head>",
		"<meta name=viewport content=\"width=device-width, initial-scale=1\">",
		"<title>LED</title>",
		"</head>",
		"<body>",
		"<p>The LED is " .. (level == 0 and "on" or "off") .. ".</p>",
		"<form action=\"set\" method=\"POST\">",
		"<input type=\"hidden\" name=\"level\" value=\"" .. (level > 0 and 0 or 1) .. "\"/>",
		"<input type=\"submit\" value=\"Turn " .. (level > 0 and "On" or "Off") .. "\"/>",
		"</form>",
		"</html>"
	}, "\r\n")
end

httpd.POST["/set"] = function(args)
	gpio.write(pin, args.level)
	return table.concat({
		"HTTP/1.1 303 See Other",
		"Location: /",
		"Connection: close",
		""
	}, "\r\n")
end

gpio.write(0, 1)
httpd.start()
print("Ready")