local limesignal = require(script.Parent.Parent.roblox_packages.limesignal)

export type Group<T> = {
	-- fields
	all: T,
	name: string,
	elementsClassName: string,
	pushEvent: limesignal.ImmutableEvent<T>,
	removeEvent: limesignal.ImmutableEvent<T>,
	n: number,
	[number]: T,
	-- methods
	__index: Group<T>,
	__tostring: (self: Group<T>) -> string,
	new: CreateGroup,
	namespace: <T>(namespace: (new: NamespaceCreateGroup) -> T) -> T,
	push: (self: Group<T>, ...T) -> (),
	remove: (self: Group<T>, ...T) -> boolean,
	clear: (self: Group<T>) -> (),
	iter: (self: Group<T>) -> typeof(ipairs({} :: { T }))
}

type BaseCreateGroup = (className: string, name: string) -> Group<any>
type NamespaceCreateGroup = ((className: "Sound") -> (_SoundGroup<any>)) & ((className: "CollisionGroup") -> CollisionGroup<any>) & BaseCreateGroup
type CreateGroup = ((className: "Sound", name: string) -> _SoundGroup) & ((className: "CollisionGroup", name: string) -> CollisionGroup) & BaseCreateGroup

-- magic groups
export type _SoundGroup<T> = {
	-- fields
	_soundGroupInstance: SoundGroup,
	-- methods
	__index: _SoundGroup<T>,
	namespace: nil,
	nest: (self: _SoundGroup<T>, other: _SoundGroup<T>) -> _SoundGroup<T>
} & Group<Sound>

export type CollisionGroup<T> = {
	-- methods
	__index: CollisionGroup<T>,
	namespace: nil,
	canCollide: (other: CollisionGroup<T>, newCollidableSetting: boolean?) -> boolean
} & Group<BasePart>

return nil
