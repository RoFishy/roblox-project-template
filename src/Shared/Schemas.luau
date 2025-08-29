-- // Packages
local t = require("@Packages/t")

return {
	UserData = t.strictInterface({
		Cash = t.numberMin(0),
	}),
}
