--!strict
-- will be removed soon (no strong usage)

local net = require("@lune/net")
local pathfs = require("pathfs")
local context = require("context")

export type DecodedResponse<T> = net.FetchResponse & {
	decoded: T
}

export type TypedDecoder<T> = (string) -> (T)

type Target = {
	url: string,
	decoder: (string) -> (any)?,
	config: {
		body: typeof(({} :: net.FetchParams).body),
		query: typeof(({} :: net.FetchParams).headers),
		options: typeof(({} :: net.FetchParams).options),
	}?
}

local API = {}

function API.from<GET, POST>(interface: {
	GET: GET,
	POST: POST
}): (api: string?) -> (GET & POST)
	return function(api)
		if not api then
			return nil :: any
		end
		local apiPath = pathfs.Path.from(api)
		local gets = interface.GET :: any
		local posts = interface.POST :: any
		local methods = {}
		for name, fn in gets do
			methods[name] = function(...)
				local target = fn(...) :: Target
				local res = net.request(apiPath:join(target.url))
				if target.decoder then
					(res :: any).decoded = target.decoder(res.body)
				end
				return res
			end
		end
		for name, fn in posts do
			methods[name] = function(data)
				local target = fn(data) :: Target
				if not target.config then
					error(context.panic("Config must be given for POST API methods"))
				end
				return net.request({
					url = apiPath:join(target.url),
					method = "POST",
					body = target.config.body,
					query = target.config.query,
					options = target.config.options
				})
			end
		end
		return methods :: any
	end
end

API.resultOf = (function(url: string, decoderOrBody: any): net.FetchResponse
	if type(decoderOrBody) == "function" then -- decoder
		return {
			url = url,
			decoder = decoderOrBody,
		} :: any
	end
	-- body
	return {
		url = url,
		body = decoderOrBody,
	} :: any
end :: any) :: (<T>(url: string, decoder: (string) -> (T)) -> (DecodedResponse<T>))
& ((url: string, body: any) -> (net.FetchResponse))
& ((url: string) -> (net.FetchResponse))

API.jsonEncode = net.jsonEncode
API.jsonDecode = net.jsonDecode

return API
