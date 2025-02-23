--!strict
-- will be replaced by dirs-lune!
-- special thanks to [dirs-rs](https://github.com/dirs-dev/dirs-rs/blob/main/src/lib.rs) for informations

local process = require("@lune/process")
local pathfs = require("pathfs")

return function(): pathfs.Path?
	local path: pathfs.Path
	if process.os == "linux" then
		path = pathfs.Path.from(process.env.XDG_CACHE_HOME)
	elseif process.os == "macos" then
		path = pathfs.Path.from(process.env.HOME)
		path:push("/Library/Caches")
	elseif process.os == "window" then
		path = pathfs.Path.from(process.env.LOCALAPPDATA)
	end
	if not path then
		return nil
	end
	return path
end
