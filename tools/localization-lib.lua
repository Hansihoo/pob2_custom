local M = { }

M.itemTypes = {
	"axe",
	"bow",
	"claw",
	"crossbow",
	"dagger",
	"fishing",
	"flail",
	"focus",
	"mace",
	"spear",
	"staff",
	"sceptre",
	"sword",
	"talisman",
	"wand",
	"body",
	"gloves",
	"helmet",
	"boots",
	"shield",
	"quiver",
	"amulet",
	"ring",
	"belt",
	"jewel",
	"flask",
	"incursionlimb",
}

M.files = {
	Gems = {
		path = "Data/Translations/ko-KR/Gems.csv",
		domains = {
			gem = true,
		},
	},
	ItemBases = {
		path = "Data/Translations/ko-KR/ItemBases.csv",
		domains = {
			base = true,
		},
	},
	Tree = {
		path = "Data/Translations/ko-KR/Tree.csv",
		domains = {
			tree_dn = true,
			tree_sd = true,
		},
	},
}

local phraseMap = {
	["added fire damage"] = "추가 화염 피해",
	["added cold damage"] = "추가 냉기 피해",
	["added lightning damage"] = "추가 번개 피해",
	["added chaos damage"] = "추가 카오스 피해",
	["ailment threshold"] = "상태 이상 한계값",
	["all elemental resistances"] = "모든 원소 저항",
	["area of effect"] = "효과 범위",
	["attack damage"] = "공격 피해",
	["attack speed"] = "공격 속도",
	["cast speed"] = "시전 속도",
	["chaos damage"] = "카오스 피해",
	["chaos resistance"] = "카오스 저항",
	["critical damage bonus"] = "치명타 피해 보너스",
	["critical hit chance"] = "치명타 확률",
	["critical strike chance"] = "치명타 확률",
	["critical strike"] = "치명타",
	["critical hits"] = "치명타",
	["cold damage"] = "냉기 피해",
	["cold resistance"] = "냉기 저항",
	["elemental damage"] = "원소 피해",
	["elemental resistances"] = "원소 저항",
	["energy shield"] = "에너지 보호막",
	["fire damage"] = "화염 피해",
	["fire resistance"] = "화염 저항",
	["flask charges"] = "플라스크 충전",
	["lightning damage"] = "번개 피해",
	["lightning resistance"] = "번개 저항",
	["maximum life"] = "최대 생명력",
	["maximum mana"] = "최대 마나",
	["melee damage"] = "근접 피해",
	["minion damage"] = "소환수 피해",
	["movement speed"] = "이동 속도",
	["physical damage"] = "물리 피해",
	["projectile damage"] = "투사체 피해",
	["projectile speed"] = "투사체 속도",
	["spell damage"] = "주문 피해",
	["stun buildup"] = "기절 누적",
	["weapon damage"] = "무기 피해",
}

local wordMap = {
	["abiding"] = "지속",
	["abyssal"] = "심연",
	["accuracy"] = "정확도",
	["acrid"] = "매캐한",
	["acrimony"] = "악감정",
	["additional"] = "추가",
	["adherent"] = "추종자",
	["adhesive"] = "점착",
	["admixed"] = "혼합",
	["admixture"] = "혼합",
	["advancing"] = "전진",
	["aegis"] = "수호",
	["aged"] = "낡은",
	["aftershock"] = "여진",
	["ailments"] = "상태 이상",
	["ailment"] = "상태 이상",
	["alchemy"] = "연금술",
	["alchemist"] = "연금술사",
	["alignment"] = "정렬",
	["all"] = "모든",
	["alloy"] = "합금",
	["allies"] = "동료",
	["ally"] = "동료",
	["amber"] = "호박",
	["ambrosia"] = "암브로시아",
	["ambush"] = "매복",
	["amethyst"] = "자수정",
	["ammo"] = "탄약",
	["amplifier"] = "증폭기",
	["amulet"] = "목걸이",
	["ancestor"] = "선조",
	["ancestral"] = "선조",
	["anchorite"] = "은둔자",
	["ancient"] = "고대",
	["antidote"] = "해독제",
	["antler"] = "뿔",
	["apocalypse"] = "종말",
	["arc"] = "전기불꽃",
	["area"] = "범위",
	["armour"] = "방어도",
	["arrow"] = "화살",
	["aid"] = "지원",
	["attack"] = "공격",
	["attacks"] = "공격",
	["attunement"] = "조율",
	["attribute"] = "능력치",
	["attributes"] = "능력치",
	["aura"] = "오라",
	["avatar"] = "화신",
	["banner"] = "깃발",
	["barrier"] = "방벽",
	["base"] = "기본",
	["bell"] = "종",
	["blinded"] = "실명",
	["bleeding"] = "출혈",
	["bleed"] = "출혈",
	["blessing"] = "축복",
	["block"] = "막기",
	["blood"] = "피",
	["bolt"] = "화살",
	["bolts"] = "화살",
	["bomb"] = "폭탄",
	["bone"] = "뼈",
	["bonus"] = "보너스",
	["boon"] = "은혜",
	["bow"] = "활",
	["brand"] = "낙인",
	["break"] = "파괴",
	["buildup"] = "누적",
	["buckler"] = "버클러",
	["burst"] = "폭발",
	["call"] = "부름",
	["caltrops"] = "마름쇠",
	["cast"] = "시전",
	["caster"] = "시전자",
	["chain"] = "연쇄",
	["chance"] = "확률",
	["chaos"] = "카오스",
	["charge"] = "충전",
	["charges"] = "충전",
	["channelling"] = "집중 유지",
	["charm"] = "참",
	["chill"] = "냉각",
	["chimes"] = "종소리",
	["citadel"] = "성채",
	["club"] = "곤봉",
	["cold"] = "냉기",
	["combat"] = "전투",
	["combustion"] = "연소",
	["companion"] = "동료",
	["concoction"] = "혼합물",
	["conservation"] = "보존",
	["critical"] = "치명타",
	["crossbow"] = "쇠뇌",
	["cry"] = "함성",
	["cuffs"] = "소맷단",
	["cuirass"] = "흉갑",
	["curse"] = "저주",
	["damage"] = "피해",
	["dead"] = "시체",
	["demon"] = "악마",
	["duration"] = "지속시간",
	["earthquake"] = "지진",
	["effect"] = "효과",
	["efficiency"] = "효율",
	["elemental"] = "원소",
	["endurance"] = "인내",
	["energy"] = "에너지",
	["evasion"] = "회피",
	["explosion"] = "폭발",
	["fire"] = "화염",
	["flame"] = "화염",
	["flames"] = "화염",
	["flask"] = "플라스크",
	["flail"] = "도리깨",
	["focus"] = "집중구",
	["freeze"] = "동결",
	["frenzy"] = "격분",
	["frost"] = "서리",
	["frozen"] = "동결",
	["gain"] = "획득",
	["gained"] = "획득",
	["gas"] = "가스",
	["gem"] = "젬",
	["grenade"] = "수류탄",
	["grenades"] = "수류탄",
	["guard"] = "수호",
	["garb"] = "복장",
	["greatblade"] = "대검",
	["hammer"] = "망치",
	["hex"] = "사술",
	["hit"] = "명중",
	["hits"] = "명중",
	["ignite"] = "점화",
	["increased"] = "증가",
	["intelligence"] = "지능",
	["javelin"] = "투창",
	["jewel"] = "주얼",
	["leggings"] = "각반",
	["leech"] = "흡수",
	["life"] = "생명력",
	["lightning"] = "번개",
	["lust"] = "욕망",
	["mail"] = "갑옷",
	["maul"] = "대형 망치",
	["mana"] = "마나",
	["mark"] = "징표",
	["mastery"] = "숙련",
	["maximum"] = "최대",
	["melee"] = "근접",
	["medal"] = "메달",
	["mine"] = "지뢰",
	["minion"] = "소환수",
	["minions"] = "소환수",
	["mitts"] = "장갑",
	["movement"] = "이동",
	["nova"] = "폭발",
	["offering"] = "공물",
	["overzealous"] = "과열된",
	["physical"] = "물리",
	["poison"] = "독",
	["power"] = "권능",
	["projectile"] = "투사체",
	["projectiles"] = "투사체",
	["quarterstaff"] = "육척봉",
	["quiver"] = "화살통",
	["rage"] = "격노",
	["raiment"] = "의복",
	["recharge"] = "재충전",
	["recoup"] = "회생",
	["reduced"] = "감소",
	["regeneration"] = "재생",
	["repulsion"] = "밀쳐내기",
	["resistance"] = "저항",
	["resistances"] = "저항",
	["ring"] = "반지",
	["robe"] = "로브",
	["adorned"] = "장식된",
	["anvil"] = "모루",
	["shield"] = "방패",
	["signet"] = "인장 반지",
	["shock"] = "감전",
	["slam"] = "강타",
	["speed"] = "속도",
	["spear"] = "창",
	["spell"] = "주문",
	["spirit"] = "정신력",
	["spirits"] = "혼령",
	["storm"] = "폭풍",
	["stun"] = "기절",
	["surrounded"] = "포위",
	["support"] = "보조",
	["tailwind"] = "순풍",
	["talisman"] = "부적",
	["threshold"] = "한계값",
	["tiara"] = "관",
	["totem"] = "토템",
	["tower"] = "타워",
	["trap"] = "덫",
	["use"] = "사용",
	["wand"] = "마법봉",
	["warrior"] = "전사",
	["weapon"] = "무기",
	["wraps"] = "손싸개",
}

local exactMap = {
	["Ice Nova"] = "얼음 폭발",
	["Leap Slam"] = "도약 강타",
	["Spark"] = "번개불꽃",
	["Fireball"] = "화염구",
	["Gathering Winds"] = "몰아치는 바람",
	["Gain Tailwind on Skill use"] = "스킬 사용 시 순풍 획득",
	["Lose all Tailwind when Hit"] = "명중당하면 모든 순풍 상실",
	["Wooden Club"] = "나무 몽둥이",
}

local function stripBOM(text)
	return text and text:gsub("^\239\187\191", "") or text
end

local function readFile(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local text = file:read("*a")
	file:close()
	return text
end

local function writeFile(path, text)
	local file = assert(io.open(path, "wb"))
	file:write(text)
	file:close()
end

local function patternEscape(text)
	return tostring(text):gsub("([^%w])", "%%%1")
end

local function csvEscape(value)
	value = tostring(value or "")
	if value:find("[\",\r\n]") then
		return '"' .. value:gsub('"', '""') .. '"'
	end
	return value
end

local function parseCSV(text)
	text = stripBOM(text or "")
	local rows = { }
	local row = { }
	local field = { }
	local inQuotes = false
	local i = 1

	local function pushField()
		row[#row + 1] = table.concat(field)
		field = { }
	end

	local function pushRow()
		pushField()
		rows[#rows + 1] = row
		row = { }
	end

	while i <= #text do
		local char = text:sub(i, i)
		if inQuotes then
			if char == '"' then
				local nextChar = text:sub(i + 1, i + 1)
				if nextChar == '"' then
					field[#field + 1] = '"'
					i = i + 1
				else
					inQuotes = false
				end
			else
				field[#field + 1] = char
			end
		else
			if char == '"' and #field == 0 then
				inQuotes = true
			elseif char == "," then
				pushField()
			elseif char == "\n" then
				pushRow()
			elseif char ~= "\r" then
				field[#field + 1] = char
			end
		end
		i = i + 1
	end

	if #field > 0 or #row > 0 then
		pushRow()
	end

	return rows
end

local function loadCSV(path)
	local text = readFile(path)
	local byKey = { }
	local order = { }
	local duplicates = 0
	if not text then
		return byKey, order, duplicates
	end
	local rows = parseCSV(text)
	local header = rows[1] or { }
	local index = { }
	for col, name in ipairs(header) do
		index[name] = col
	end
	for i = 2, #rows do
		local row = rows[i]
		local entry = {
			domain = row[index.domain or 1] or "",
			key = row[index.key or 2] or "",
			en = row[index.en or 3] or "",
			ko = row[index.ko or 4] or "",
			aliases = row[index.aliases or 5] or "",
		}
		if entry.domain ~= "" and entry.key ~= "" then
			local id = entry.domain .. "\t" .. entry.key
			if byKey[id] then
				duplicates = duplicates + 1
			else
				order[#order + 1] = id
			end
			byKey[id] = entry
		end
	end
	return byKey, order, duplicates
end

local function writeCSV(path, rows)
	table.sort(rows, function(a, b)
		if a.domain == b.domain then
			return a.key < b.key
		end
		return a.domain < b.domain
	end)

	local out = { "domain,key,en,ko,aliases\n" }
	for _, row in ipairs(rows) do
		out[#out + 1] = table.concat({
			csvEscape(row.domain),
			csvEscape(row.key),
			csvEscape(row.en),
			csvEscape(row.ko),
			csvEscape(row.aliases),
		}, ",") .. "\n"
	end
	writeFile(path, table.concat(out))
end

local function sortedPhrases()
	local list = { }
	for phrase, translated in pairs(phraseMap) do
		list[#list + 1] = { phrase = phrase, translated = translated }
	end
	table.sort(list, function(a, b)
		return #a.phrase > #b.phrase
	end)
	return list
end

local phraseList = sortedPhrases()

local function translateWords(text)
	local out = text
	for _, item in ipairs(phraseList) do
		out = out:gsub(patternEscape(item.phrase), item.translated)
		out = out:gsub(patternEscape((item.phrase:gsub("^%l", string.upper))), item.translated)
		out = out:gsub(patternEscape((item.phrase:gsub("(%a)([%w']*)", function(first, rest)
			return first:upper() .. rest:lower()
		end))), item.translated)
	end
	out = out:gsub("(%a[%a']*)", function(word)
		return wordMap[word:lower()] or word
	end)
	out = out:gsub("%s+of%s+", "의 ")
	out = out:gsub("%s+and%s+", " 및 ")
	out = out:gsub("%s+with%s+", " 보유 ")
	out = out:gsub("%s+from%s+", "에서 ")
	out = out:gsub("%s+while%s+", " 동안 ")
	out = out:gsub("%s+to%s+", "에 ")
	out = out:gsub("%s+on%s+", " 시 ")
	out = out:gsub("%s+for%s+", " 동안 ")
	out = out:gsub("%s+vs%s+", " 상대 ")
	out = out:gsub("%s+", " ")
	return out:gsub("^%s+", ""):gsub("%s+$", "")
end

function M.translate(domain, english)
	if not english or english == "" then
		return ""
	end
	if exactMap[english] then
		return exactMap[english]
	end
	local translated = translateWords(english)
	if translated == english and domain == "tree_sd" then
		return english
	end
	return translated
end

local function addCandidate(candidates, domain, key, english)
	if key and key ~= "" and english and english ~= "" then
		candidates[#candidates + 1] = {
			domain = domain,
			key = tostring(key),
			en = english,
			ko = M.translate(domain, english),
			aliases = "",
		}
	end
end

function M.extractCandidates()
	local candidates = { }

	local gems = assert(loadfile("Data/Gems.lua"))()
	for gemId, gem in pairs(gems) do
		addCandidate(candidates, "gem", gemId, gem.name)
	end

	local itemBases = { }
	for _, itemType in ipairs(M.itemTypes) do
		local chunk = assert(loadfile("Data/Bases/" .. itemType .. ".lua"))
		chunk(itemBases)
	end
	for name in pairs(itemBases) do
		addCandidate(candidates, "base", name, name)
	end

	assert(loadfile("GameVersions.lua"))()
	local tree = assert(loadfile("TreeData/" .. latestTreeVersion .. "/tree.lua"))()
	for _, node in pairs(tree.nodes or { }) do
		local nodeId = node.skill or node.id
		if nodeId and node.name then
			addCandidate(candidates, "tree_dn", nodeId, node.name)
			for index, stat in ipairs(node.stats or { }) do
				addCandidate(candidates, "tree_sd", tostring(nodeId) .. ":" .. index, stat)
			end
		end
	end

	return candidates
end

local function candidatesForFile(candidates, config)
	local out = { }
	for _, candidate in ipairs(candidates) do
		if config.domains[candidate.domain] then
			out[#out + 1] = candidate
		end
	end
	return out
end

local function validateFile(path, candidates)
	local existing, _, duplicates = loadCSV(path)
	local wanted = { }
	local missing = 0
	local stale = 0
	local blank = 0
	for _, candidate in ipairs(candidates) do
		local id = candidate.domain .. "\t" .. candidate.key
		wanted[id] = true
		local row = existing[id]
		if not row then
			missing = missing + 1
		else
			if row.en ~= candidate.en then
				stale = stale + 1
			end
			if row.ko == "" then
				blank = blank + 1
			end
		end
	end
	local orphaned = 0
	for id in pairs(existing) do
		if not wanted[id] then
			orphaned = orphaned + 1
		end
	end
	return {
		missing = missing,
		stale = stale,
		blank = blank,
		orphaned = orphaned,
		duplicates = duplicates,
	}
end

local function mergeFile(path, candidates, options)
	options = options or { }
	local existing = loadCSV(path)
	local rows = { }
	local preserved = 0
	local generated = 0
	for _, candidate in ipairs(candidates) do
		local id = candidate.domain .. "\t" .. candidate.key
		local old = existing[id]
		local row = {
			domain = candidate.domain,
			key = candidate.key,
			en = candidate.en,
			ko = candidate.ko,
			aliases = candidate.aliases,
		}
		if old and old.ko and old.ko ~= "" and not options.refresh then
			row.ko = old.ko
			preserved = preserved + 1
		else
			generated = generated + 1
		end
		if old and old.aliases and old.aliases ~= "" then
			row.aliases = old.aliases
		end
		rows[#rows + 1] = row
	end
	writeCSV(path, rows)
	return {
		rows = #rows,
		preserved = preserved,
		generated = generated,
	}
end

local function writeManifest()
	writeFile("Data/Translations/ko-KR/manifest.lua", table.concat({
		"return {\n",
		"\t\"Gems.csv\",\n",
		"\t\"ItemBases.csv\",\n",
		"\t\"Tree.csv\",\n",
		"}\n",
	}))
end

function M.update(writeMode, options)
	options = options or { }
	local candidates = M.extractCandidates()
	local summary = {
		total = #candidates,
		files = { },
	}

	for name, config in pairs(M.files) do
		local fileCandidates = candidatesForFile(candidates, config)
		if writeMode then
			summary.files[name] = mergeFile(config.path, fileCandidates, options)
		else
			summary.files[name] = validateFile(config.path, fileCandidates)
		end
		summary.files[name].path = config.path
		summary.files[name].expected = #fileCandidates
	end

	if writeMode then
		writeManifest()
	end

	return summary
end

function M.summaryHasFailures(summary)
	for _, fileSummary in pairs(summary.files or { }) do
		if (fileSummary.missing or 0) > 0
			or (fileSummary.stale or 0) > 0
			or (fileSummary.blank or 0) > 0
			or (fileSummary.orphaned or 0) > 0
			or (fileSummary.duplicates or 0) > 0 then
			return true
		end
	end
	return false
end

function M.printSummary(summary, writeMode)
	print(string.format("Localization candidates: %d", summary.total or 0))
	local names = { }
	for name in pairs(summary.files or { }) do
		names[#names + 1] = name
	end
	table.sort(names)
	for _, name in ipairs(names) do
		local fileSummary = summary.files[name]
		if writeMode then
			print(string.format(
				"%s: rows=%d preserved=%d generated=%d path=%s",
				name,
				fileSummary.rows or 0,
				fileSummary.preserved or 0,
				fileSummary.generated or 0,
				fileSummary.path
			))
		else
			print(string.format(
				"%s: expected=%d missing=%d stale=%d blank=%d orphaned=%d duplicates=%d path=%s",
				name,
				fileSummary.expected or 0,
				fileSummary.missing or 0,
				fileSummary.stale or 0,
				fileSummary.blank or 0,
				fileSummary.orphaned or 0,
				fileSummary.duplicates or 0,
				fileSummary.path
			))
		end
	end
end

return M
