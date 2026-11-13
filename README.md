# Neon Error Sign

A Garry's Mod addon that gives ERROR models a colour and a glow. ERROR is the placeholder Garry's Mod draws when a model's content isn't mounted. Each player picks their own look, and errors can take the colour of whoever spawned them, so you can tell who is spawning content you don't have.

Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3346062106

## Install

Subscribe on the Workshop, or copy this repository into `garrysmod/addons/neonerror/` so that `addons/neonerror/lua/autorun/client/m2ne.lua` exists. On a server, add the Workshop item to the collection. The server part only marks who spawned what.

## Settings (client console)

| ConVar | Default | What it does |
| --- | --- | --- |
| `cl_error_mode` | `0` | `0` normal (red), `1` party (cycling colours), `2` spawner's player colour, `3` spawner's physgun colour, `4` siren (red / blue), `5` custom siren (spawner's player and physgun colours) |
| `cl_error_glow` | `1` | Dynamic light on each error |
| `cl_error_glow_intensity` | `1` | Glow brightness (0-10) |
| `cl_error_missing` | `1` | Also treat models you don't have mounted as errors, not only `models/error.mdl` |

Errors with no owner (spawned by the map or the server) use your own colours in modes 2, 3 and 5. If a prop-protection addon with CPPI is installed, its owner is used.

## Layout

```
lua/autorun/client/m2ne.lua        colours, glow, error detection
lua/autorun/server/m2ne_owner.lua  networks the spawner of Sandbox-spawned entities
```

## Development

Lint with [glualint](https://github.com/FPtje/GLuaFixer): `glualint lint lua` (settings in `.glualint.json`). `addon.json` keeps the README, licence and repo config out of the Workshop pack.
