--[[
	Defines the objects that should be created (server) or to wait to exist
	(client) for facilitating client-server communication.

	The individual client/server code should handle actually interacting with
	this file, which should just serve as a specification.
]]

local ApiSpec = {
	clientMethods = {
		"requestMakeCharacter",
	},
}

return ApiSpec