local Signal = require("@Packages/Signal")

return {
	PlayerRegistered = Signal.new() :: Signal.Signal<Player>,
	PlayerUnregistered = Signal.new() :: Signal.Signal<Player>,
}
