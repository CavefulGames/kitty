--!strict
type Object = {
    [any]: any
}

type DirOptions = {
    showHidden: boolean,
    depth: number,
    colors: boolean,
}

type baseLog = (data: any, ...any) -> ()

export type Console = {
    assert: (value: any, ...any) -> (),
    count: (label: string?) -> (),
    countReset: (table: string?) -> (),
    debug: baseLog,
    dir: (object: Object, options: DirOptions) -> (),
    dirxml: (...any) -> (),
    error: baseLog,
    group: (...any) -> (),
    groupCollapsed: () -> (),
    groupEnd: () -> (),
    info: baseLog,
    log: baseLog,
    table: (table: Object) -> (any),
    time: (label: string?) -> (),
    timeEnd: (label: string?) -> (),
    timeLog: (label: string?, ...any) -> (),
    trace: (message: any, ...any) -> (),
    tree: (top: Instance | string, child: { [any]: any }?) -> (),
    warn: baseLog,
}

return {}