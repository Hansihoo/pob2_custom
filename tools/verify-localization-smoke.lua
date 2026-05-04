local function fail(message)
	error(message, 2)
end

local function expectEqual(label, expected, actual)
	if actual ~= expected then
		fail(string.format("%s: expected '%s', got '%s'", label, tostring(expected), tostring(actual)))
	end
end

local function expectTrue(label, value)
	if not value then
		fail(label .. ": expected true")
	end
end

local function expectNil(label, value)
	if value ~= nil then
		fail(string.format("%s: expected nil, got '%s'", label, tostring(value)))
	end
end

_G.utf8 = { }

local localizationLogs = { }
function ConPrintf(format, ...)
	localizationLogs[#localizationLogs + 1] = string.format(format, ...)
end

function StripEscapes(value)
	return tostring(value or "")
end

function PCall(func, ...)
	local result = { pcall(func, ...) }
	if result[1] then
		table.remove(result, 1)
		return nil, unpack(result)
	end
	return result[2]
end

function string.matchOrPattern(value, pattern)
	return string.match(value, pattern)
end

function LoadModule(fileName, ...)
	if not fileName:match("%.lua$") then
		fileName = fileName .. ".lua"
	end
	local chunk, err = loadfile(fileName)
	if not chunk then
		fail("LoadModule failed for " .. fileName .. ": " .. tostring(err))
	end
	return chunk(...)
end

local loc = LoadModule("Modules/Localization")
expectEqual("default language", "ko-KR", loc.language)
expectTrue("translation files loaded", loc.stats.files > 0)
expectTrue("translation rows loaded", loc.stats.rows > 0)
expectTrue("translations loaded", loc.stats.translations > 0)
if os.getenv("POB_LOG_LOCALIZATION") == "1" then
	expectTrue("localization load log emitted", #localizationLogs > 0)
end

local rows = loc:ParseCSV('\239\187\191domain,key,en,ko,aliases\r\nui,greeting,"Hello, ""World""","안녕, 세계","hello|인사"\r\n')
expectEqual("csv header", "domain", rows[1][1])
expectEqual("csv key", "greeting", rows[2][2])
expectEqual("csv quoted en", 'Hello, "World"', rows[2][3])
expectEqual("csv quoted ko", "안녕, 세계", rows[2][4])
expectEqual("csv aliases", "hello|인사", rows[2][5])

loc:SetLanguage("ko-KR", true)
expectTrue("translation stats reset on load", loc.stats.translations > 0)
expectEqual("fallback display", "Unknown Label", loc:Display("ui", "missing.label", "Unknown Label"))
expectEqual("variable fallback", "Hello Ranger", loc:Tr("ui", "hello.name", "Hello {name}", { name = "Ranger" }))

local gemId = "Metadata/Items/Gems/SkillGemIceNova"
local data = {
	gems = {
		[gemId] = {
			name = "Ice Nova",
		},
	},
	gemForBaseName = {
		["Ice Nova"] = gemId,
	},
	itemBases = {
		["Wooden Club"] = {
		},
	},
	itemBaseLists = {
		oneHandMaces = {
			{
				name = "Wooden Club",
			},
		},
	},
}
data.itemBaseLists.oneHandMaces[1].base = data.itemBases["Wooden Club"]

loc:DecorateData(data)

local gem = data.gems[gemId]
expectEqual("canonical gem name", "Ice Nova", gem.name)
expectEqual("translated gem display", "얼음 폭발", gem.displayName)
expectEqual("canonical gem index", gemId, data.gemForBaseName["Ice Nova"])
expectNil("no translated gem canonical index", data.gemForBaseName["얼음 폭발"])
expectTrue("gem English search", loc:SearchMatch(gem.searchText, "Ice Nova"))
expectTrue("gem Korean search", loc:SearchMatch(gem.searchText, "얼음"))
expectTrue("gem alias search", loc:SearchMatch(gem.searchText, "아이스"))

local base = data.itemBases["Wooden Club"]
expectEqual("canonical base name", "Wooden Club", base.name)
expectEqual("translated base display", "나무 몽둥이", base.displayName)
expectTrue("base English search", loc:SearchMatch(base.searchText, "Wooden Club"))
expectTrue("base Korean search", loc:SearchMatch(base.searchText, "몽둥이"))
expectEqual("base list label", "나무 몽둥이", data.itemBaseLists.oneHandMaces[1].label)

local tree = {
	nodes = {
		[30] = {
			id = 30,
			dn = "Gathering Winds",
			sd = { "Gain Tailwind on Skill use" },
		},
	},
}
loc:DecorateTree(tree)
local node = tree.nodes[30]
expectEqual("canonical node name", "Gathering Winds", node.dn)
expectEqual("translated node display", "몰아치는 바람", node.displayName)
expectEqual("translated node stat", "스킬 사용 시 순풍 획득", node.displayStats[1])
expectTrue("tree Korean search", loc:SearchMatch(node.searchText, "순풍"))

loc:SetLanguage("en-US", true)
loc:DecorateData(data)
expectEqual("English fallback gem display", "Ice Nova", gem.displayName)
expectEqual("English fallback base display", "Wooden Club", base.displayName)

print("Localization smoke verification passed")
io.stdout:flush()
