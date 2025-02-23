export type BaseCache<T> = {
	holder: Folder,
	template: T,
	spawned: { [T]: boolean? },
	size: number,
	manager: PrivateBaseCacheManager<any, T, any>,
	primaryPartExists: boolean?,
}

export type PrivateBaseCacheManager<SELF, T, M> = {
	init: ((self: SELF & M, config: M?) -> ())?,
	get: (self: SELF & M) -> T,
	free: ((self: SELF & M, object: T) -> ())?,
}

export type BaseCacheManager<T, M=nil> = PrivateBaseCacheManager<BaseCache<T> & { expand: (self: any, amount: number) -> () }, T, M>

export type InstanceCache<T> = typeof(setmetatable(
	{} :: BaseCache<T & Instance>,
	{} :: InstanceCacheImpl
))

export type InstanceCacheImpl = {
	__index: InstanceCacheImpl,
	spawn: <T>(self: InstanceCache<T>) -> T,
	despawn: <T>(self: InstanceCache<T>, object: T & Instance, resetParent: boolean?) -> (),
	expand: <T>(self: InstanceCache<T>, amount: number) -> (),
	delete: <T>(self: InstanceCache<T>) -> (),
}

export type PartCache<T> = typeof(setmetatable(
	{} :: BaseCache<T & BasePart>,
	{} :: PartCacheImpl
))

export type PartCacheImpl = {
	__index: PartCacheImpl,
	spawn: <T>(self: PartCache<T>, partCFrame: CFrame?) -> T,
	despawn: <T>(self: PartCache<T>, object: T & BasePart, resetParent: boolean?) -> (),
	expand: <T>(self: PartCache<T>, amount: number) -> (),
	delete: <T>(self: PartCache<T>) -> (),
}

export type ModelCache<T> = typeof(setmetatable(
	{} :: BaseCache<T & Model>,
	{} :: ModelCacheImpl
))

export type ModelCacheImpl = {
	__index: ModelCacheImpl,
	spawn: <T>(self: ModelCache<T>, partCFrame: CFrame) -> Model,
	despawn: <T>(self: ModelCache<T>, object: T & Model, resetParent: boolean?) -> (),
	expand: <T>(self: ModelCache<T>, amount: number) -> (),
	delete: <T>(self: ModelCache<T>) -> (),
}

export type CreateCacheFn = (<T, M>(
	template: T & BasePart,
	size: number,
	cacheManager: BaseCacheManager<T, M>,
	cacheManagerConfig: M?,
	debugName: string?,
	parent: Instance?
) -> PartCache<T>) & (<T, M>(
	template: T & Model,
	size: number,
	cacheManager: BaseCacheManager<T, M>,
	cacheManagerConfig: M?,
	debugName: string?,
	parent: Instance?
) -> ModelCache<T>) & (<T, M>(
	template: T & Instance,
	size: number,
	cacheManager: BaseCacheManager<T, M>,
	cacheManagerConfig: M?,
	debugName: string?,
	parent: Instance?
) -> InstanceCache<T>)

return nil
