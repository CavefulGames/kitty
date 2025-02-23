local inext = require(script.Parent.Parent.inext)
local types = require(script.Parent.Parent.types)
local utils = require(script.Parent.Parent.utils)

local sharedImpl = {} :: { new: nil } & types.Group<Instance>

function sharedImpl.with(self, ...)
	self:clear()
	for _, element in {...} do
		self:add(element)
	end
	return self
end

function sharedImpl.add(self, element)
	if not element:IsA(self.className) then
		error(`Attempt to add an incorrect element('{utils.print(element)}') into a group('{self}').`)
	end
	local index = self.n + 1
	self[index] = element
	self.n = index
	return index
end

function sharedImpl.remove(self, index)
	local removedElement = table.remove(self, index)
	if removedElement then
		self.n -= 1
		return removedElement
	end
	return
end

function sharedImpl.clear(self)
	table.clear(self)
	self.n = 0
end

function sharedImpl.iter(self)
	return inext, self, 0
end

return sharedImpl
