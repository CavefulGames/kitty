
local function convertToHashedPath(tree, isFile, path, result)
	result = result or {}
	path = path or ""
	if isFile then
		result[path] = tree
	else
		for key, value in pairs(tree) do
			if type(value) == "table" then
				local newPath = path .. key
				if type(key) == "number" and value.name then
					newPath = path .. value.name
				end
				local is_file = type(key) == "number"
				convertToHashedPath(value, is_file, table.concat({newPath,is_file and "" or "/"}), result)
			end
		end
	end
	return result
end

local function fetchAssetData(path:string)

end

local assets = {}

local module = {}

function module.model(path:string) --- Load Model Asset

end

function module.material(path:string) --- Load Material Asset

end

function module.sound(path:string)

end

function module.script(path:string)

end

function module.particle(path:string)

end

function module.anim(path:string)

end

function module.path()

end

return module
