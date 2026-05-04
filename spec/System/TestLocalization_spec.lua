describe("TestLocalization", function()
	local gemId = "Metadata/Items/Gems/SkillGemIceNova"

	before_each(function()
		loc:SetLanguage("ko-KR", true)
		loc:DecorateData(data)
	end)

	after_each(function()
		loc:SetLanguage("en-US", true)
		loc:DecorateData(data)
	end)

	it("parses UTF-8 CSV files with BOM, quotes, CRLF, and commas", function()
		local rows = loc:ParseCSV('\239\187\191domain,key,en,ko,aliases\r\nui,greeting,"Hello, ""World""","안녕, 세계","hello|인사"\r\n')
		assert.are.equals("domain", rows[1][1])
		assert.are.equals("greeting", rows[2][2])
		assert.are.equals('Hello, "World"', rows[2][3])
		assert.are.equals("안녕, 세계", rows[2][4])
		assert.are.equals("hello|인사", rows[2][5])
	end)

	it("falls back to English for missing translations", function()
		assert.are.equals("Unknown Label", loc:Display("ui", "missing.label", "Unknown Label"))
	end)

	it("decorates gems without changing canonical names", function()
		local gem = data.gems[gemId]
		assert.are.equals("Ice Nova", gem.name)
		assert.are.equals("얼음 폭발", gem.displayName)
		assert.True(loc:SearchMatch(gem.searchText, "Ice Nova"))
		assert.True(loc:SearchMatch(gem.searchText, "얼음"))
		assert.True(loc:SearchMatch(gem.searchText, "아이스"))
	end)

	it("decorates item bases for display and search", function()
		local base = data.itemBases["Wooden Club"]
		assert.are.equals("Wooden Club", base.name)
		assert.are.equals("나무 몽둥이", base.displayName)
		assert.True(loc:SearchMatch(base.searchText, "Wooden Club"))
		assert.True(loc:SearchMatch(base.searchText, "몽둥이"))
	end)

	it("decorates passive tree nodes without changing canonical names", function()
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
		assert.are.equals("Gathering Winds", node.dn)
		assert.are.equals("몰아치는 바람", node.displayName)
		assert.are.equals("스킬 사용 시 순풍 획득", node.displayStats[1])
		assert.True(loc:SearchMatch(node.searchText, "순풍"))
	end)
end)
