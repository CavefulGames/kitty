local wallyapi = {}

wallyapi.GET = {}
function wallyapi.GET.package_contents(scope: string, name: string, version: string)
	return `v1/package-contents/{scope}/{name}/{version}`
end

function wallyapi.GET.package_metadata(scope: string, name: string)
	return `v1/package-metadata/{scope}/{name}`
end

function wallyapi.GET.package_search(phrase: string)
	return `v1/package-search?query={phrase}`
end

wallyapi.POST = {}
function wallyapi.POST.publish()
	return "api/v1/publish"
end

return wallyapi
