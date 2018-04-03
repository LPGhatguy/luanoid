# Luanoid
New character controller intended as a replacement for Humanoid for developers who want more flexibility or control over their characters.

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

We do expect to need some engine changes to to properly handle of the more nuanced physics behaviors like friction correctly. Lua heartbeat steps at 60 Hz but the Roblox physics engine internally steps at 240 Hz; Lua only gets to intervene once every 4 physics frames. We're using our experimentation here to inspire the design and development of more flexible and configurable types to support this.

## Non-Goals
* Support for Humanoid-specific APIs or concepts like `Tool`

## Known Limitations
This project is meant to be an alternative to Humanoids, so it doesn't use Humanoids. That currently has some drawbacks that might make this controller unsuitable for your game in its current state.

* Incompatible with Avatar clothing and accessories
* Incompatible with control scripts that are dependent on Humanoids

Clothing and accessories is something we are hoping to support without Humanoids in the future.* Suitability for NPCs

## License
Luanoid is available under the [TODO] license.