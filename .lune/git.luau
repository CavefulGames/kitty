local net = require("@lune/net")

local remote = "https://github.com/CavefulGames/kitty"

local result = net.request(`{remote}.git/info/refs?service=git-upload-pack`)

local function parseGitAdvertisement(response)
    local lines = response:split("\n")
    local parsedData = {}

    -- Process the first line for service and capabilities
    local firstLine = lines[1]
    if firstLine:match("^# service=") then
        parsedData.service = firstLine:match("^# service=(.+)$")
    end

    -- Process the second line for version (optional)
    local secondLine = lines[2]
    if secondLine == "version 1" then
        parsedData.version = secondLine
    end

    -- Process the remaining lines
    local references = {}
    local capabilities = {}
    local endOfReferences = false

    for i = 3, #lines do
        local line = lines[i]
        if line == "0000" then
            endOfReferences = true
        elseif not endOfReferences then
            if line:find("capabilities^{}") then
                local capList = line:match("capabilities^{}%z*(.*)$")
                capabilities = (capList or ""):split(" ")
                parsedData.capabilities = capabilities
            else
                local objId, refName, capList = line:match("(%x+)%s+([^\0]+)%z*(.*)")
                if objId and refName then
                    table.insert(references, {
                        objectId = objId,
                        refName = refName,
                        capabilities = (capList or ""):split(" ")
                    })
                end
            end
        end
    end

    parsedData.references = references
    return parsedData
end

if result.ok then
	print(result)
	print(parseGitAdvertisement(result.body))

	result = net.request({
		url = `{remote}.git/git-upload-pack`,
		headers = { ["Content-Type"] = "application/x-git-upload-pack-request" },
		method = "POST",
		body = table.concat({
			"0054want 8b54ea385f983ca7ff2ff21aa86bcbf4b4a0814f multi_ack side-band-64k ofs-delta",
			"0032want 464b34f4677ae886741600cbf26259e90d972470",
			"0032want 8dee7ece4eb67199a5c288cdeb41232b981d6006",
			"0032want c97315796852206a5b7d8242490ba58ea4b7a80c",
			"0032want 25bb83a774023d230f206b1ae10950241e7c606c",
			"0032want 9f9de9fa0039cb8385fda3fe73ad21690748b990",
			"0032want 8a86ad8086377cd65a070d5c7ddc500961e65797",
			"00000009done"
		}, "\n")
	})

	print(result)
end
