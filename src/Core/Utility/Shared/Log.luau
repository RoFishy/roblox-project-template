local Log = {}

function Log.CreateLogFunction(Name: string, logFn: (...string) -> ())
	return function(...: any)
		local modulePath, moduleLine = debug.info(2, "sl")
		local moduleName = modulePath:match("[^.]+$")

		logFn(`[{moduleName}][{Name}][{moduleLine}]:`, ...)
	end
end

Log.Debug = Log.CreateLogFunction("Debug", print)
Log.Info = Log.CreateLogFunction("Info", print)
Log.Warn = Log.CreateLogFunction("Warning", warn)
Log.Error = Log.CreateLogFunction("Error", function(message, ...)
	error(
		`Traceback: \n\n                {message} {...}\n\n                ------------------------------------------------`
	)
end)

return Log
