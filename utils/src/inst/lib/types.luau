export type Group<T, ALL = T> = {
	all: ALL,
	name: string,
	className: string,
	n: number,
	[number]: T,
	-- methods
	__index: Group<T, ALL>,
	new: (className: string, name: string) -> Group<T, ALL>,
	with: (self: Group<T, ALL>, ...T) -> Group<T, ALL>,
	add: (self: Group<T, ALL>, element: T) -> number,
	remove: (self: Group<T, ALL>, index: number) -> T?,
	clear: (self: Group<T, ALL>) -> (),
	iter: (self: Group<T, ALL>) -> (typeof(ipairs({} :: { T })), { T }, number),
	destroy: (self: Group<T, ALL>) -> ()
}

return nil
