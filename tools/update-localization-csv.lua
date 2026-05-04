local lib = assert(loadfile("../tools/localization-lib.lua"))()

local mode = os.getenv("POB_LOCALIZATION_MODE") or "write"
local checkOnly = mode == "check"
local summary = lib.update(not checkOnly, {
	refresh = os.getenv("POB_LOCALIZATION_REFRESH") == "1",
})
lib.printSummary(summary, not checkOnly)

if checkOnly and lib.summaryHasFailures(summary) then
	error("Localization CSV files are not synchronized with current data")
end
