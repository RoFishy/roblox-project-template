-- // Packages
local Signal = require("@Packages/Signal")

local Types = require("@Shared/Types")

return {
	-- // Data
	PlayerDataChanged = Signal.new() :: Signal.Signal<Types.UserData, Types.UserData>,
}
