--!strict

local regex = require("@lune/regex")

return function(url): string?
	local urlParser = regex.new("^(?:https?://)?(?:www\\.)?([^/]+)")
	local domainCapture = urlParser:captures(url)
	if not domainCapture then
		return nil
	end
	local domain = domainCapture:get(1)
	if not domain then
		return nil
	end
	return domain.text
end
