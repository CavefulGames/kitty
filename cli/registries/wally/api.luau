--!strict

local API = require("../../API")
local wally = require("../../manifests/wally")
local wallyapi = {
	GET = {},
	POST = {}
}

function wallyapi.GET.package_contents(scope: string, name: string, version: string)
	return API.resultOf(`v1/package-contents/{scope}/{name}/{version}`, API.jsonDecode :: API.TypedDecoder<{a: string}>)
end

function wallyapi.GET.package_metadata(scope: string, name: string)
	return API.resultOf(`v1/package-metadata/{scope}/{name}`, API.jsonDecode :: API.TypedDecoder<{
		versions: {
			wally.Wally
		}
	}>)
end

function wallyapi.GET.package_search(phrase: string)
	return API.resultOf(`v1/package-search?query={phrase}`, API.jsonDecode :: API.TypedDecoder<{
		{
			description: string,
			name: string,
			scope: string,
			versions: { string }
		}
	}>)
end

function wallyapi.POST.publish(data: {
	auth: string
})
	return API.resultOf("api/v1/publish", API.jsonEncode(data))
end

return API.from(wallyapi)
