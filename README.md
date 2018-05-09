# Luanoid
New character controller intended as a replacement for Humanoid for developers who want more flexibility or control over their characters.

## Usage
The latest source is available in the `src` directory. The rig and test playground is available in `luanoid-test-place.rbxlx`, but the version of the controller in the place may not be up-to-date at all times.

To work on Luanoid, use [Rojo](https://github.com/LPGhatguy/rojo) to sync the project into the test place continually.

## Goals
* Keep state machine and controls entirely in Lua
* More predictable physics
	* Don't get flung into the ceiling
	* Rational slope behavior
	* Smoothly handle stairs
	* Sane control forces and limits
	* Newton's third law reaction forces
	* Correct friction forces
* Suitable for NPCs
	* Pathfinding support

We do expect to need some engine changes to to properly handle of the more nuanced physics behaviors like friction correctly. Lua heartbeat steps at 60 Hz but the Roblox physics engine internally steps at 240 Hz; Lua only gets to intervene once every 4 physics frames. We're using our experimentation here to inspire the design and development of more flexible and configurable types to support this.

## Non-Goals
* Support for Humanoid-specific APIs or concepts like `Tool`

## Known Limitations
This project is meant to be an alternative to Humanoids, so it doesn't use Humanoids. That currently has some drawbacks that might make this controller unsuitable for your game in its current state.

* Incompatible with avatar clothing and accessories
* Incompatible with camera control scripts that are dependent on Humanoids

Clothing and accessories is something we are hoping to support without Humanoids in the future.

## Contributing

Pull requests are welcome!

If you encounter any issues that would prevent you from using this in a game, please open an issue. That alone is a useful contribution.

## License
Luanoid is dual-licensed under the CC0 and MIT licenses. See [LICENSE-CC0](LICENSE-CC0) and [LICENSE-MIT](LICENSE-MIT) for details.