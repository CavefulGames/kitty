# `lune run kitty [command]` commands
- `init` --project: init kitty project in an existing directory
- `new` name: creates kitty project
- `add` name: add package
- `install` --yes(y): fetch packages
- `remove` name --yes(y): remove package
- `search` query: search package
- `list` --search(s): list packages
- `utils` --search(s): list utils
- `check`: check packages and ask to update packages
- `build` --output(o): build project
- `produce`: create production place rbxl which includes loader script (if it published)
- `publish`: login & publish production from kitty.toml's owner
- `status`: inspect publish status
- `push`: build project and move into temp
- `plugin`: install plugin
- `manifest-to-json`: export kitty.toml into json
- `sourcemap` --output: generate sourcemap (default file: sourcemap.json)
- `print-sourcemap`: generate sourcemap and print
- `self-update`: update kitty cli
- `typeof` --search(s) --starts-with(w): get type of given rbx class
- `reload`: runs `kitty asset reload`, `kitty bin sync`, `kitty sourcemap`
- `login`: login into current kitty.toml's owner (auth will be stored as encrypted in %LOCALDATA%)

## `wally [commands]` - for package manager (almost same as wally cli)
- `init`: creates wally.toml
- `add`: add into wally.toml
- `remove`: remove in wally.toml
- `manifest-to-json`
- `login`
- `logout`
- `publish`
- `install`: installs packages through wally.toml

## `asset [commands]` - for asset managements (inspired by git)
- `reload`: reload all temp assets
- `unload`: unload all temp assets
- `publish`: publish assets to roblox
- `import`: prompt import assets
- `add`: register assets
- `rm`: remove asset
- `mv`: move asset
- `set`: set property of asset
- `get`: get property of asset
- `edit`: edit properties of asset (with autocomplete!)

## `bin [commands]` - for rbx binaries
- `init`: initialize bin.kitty.rbxl
- `edit`: edit bin with roblox studio
- `sync`: sync bin into file system (with `.model.json`)
