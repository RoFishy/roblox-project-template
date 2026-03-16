-- // Packages
local Signal = require("@Packages/Signal")

local Types = require("@Core/Utility/Shared/Types")

return {
	PlayerDataChanged = Signal.new() :: Signal.Signal<Types.UserData, Types.UserData>,
}
