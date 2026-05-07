-- Path of Building
--
-- Module: Localization
-- CSV-backed display/search localization layer. Canonical data remains English.

local t_insert = table.insert
local t_concat = table.concat

local LocalizationClass = { }
LocalizationClass.__index = LocalizationClass

local function stripBOM(text)
	return text and text:gsub("^\239\187\191", "") or text
end

local function fileExists(path)
	local file = io.open(path, "rb")
	if file then
		file:close()
		return true
	end
	return false
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

local function writeEscapedCSVField(out, value)
	value = tostring(value or "")
	if value:find("[\",\r\n]") then
		out:write('"', value:gsub('"', '""'), '"')
	else
		out:write(value)
	end
end

local function normaliseKey(key)
	return tostring(key or "")
end

local function splitAliases(aliases)
	local out = { }
	if aliases and aliases ~= "" then
		for alias in aliases:gmatch("[^|]+") do
			alias = alias:gsub("^%s+", ""):gsub("%s+$", "")
			if alias ~= "" then
				t_insert(out, alias)
			end
		end
	end
	return out
end

local function logLocalization(message, ...)
	if os.getenv("POB_LOG_LOCALIZATION") == "1" and ConPrintf then
		ConPrintf("[loc] " .. message, ...)
	end
end

function LocalizationClass:ParseCSV(text)
	text = stripBOM(text or "")
	local rows = { }
	local row = { }
	local field = { }
	local inQuotes = false
	local i = 1

	local function pushField()
		t_insert(row, t_concat(field))
		field = { }
	end

	local function pushRow()
		pushField()
		t_insert(rows, row)
		row = { }
	end

	while i <= #text do
		local char = text:sub(i, i)
		if inQuotes then
			if char == '"' then
				local nextChar = text:sub(i + 1, i + 1)
				if nextChar == '"' then
					t_insert(field, '"')
					i = i + 1
				else
					inQuotes = false
				end
			else
				t_insert(field, char)
			end
		else
			if char == '"' and #field == 0 then
				inQuotes = true
			elseif char == "," then
				pushField()
			elseif char == "\n" then
				pushRow()
			elseif char ~= "\r" then
				t_insert(field, char)
			end
		end
		i = i + 1
	end

	if #field > 0 or #row > 0 then
		pushRow()
	end

	return rows
end

function LocalizationClass:GetTranslationFiles(language)
	local basePath = "Data/Translations/" .. language .. "/"
	local files = { }
	local manifestPath = basePath .. "manifest"
	local ok, manifest = pcall(LoadModule, manifestPath)
	if ok and type(manifest) == "table" then
		for _, fileName in ipairs(manifest) do
			t_insert(files, basePath .. fileName)
		end
		return files
	end

	if NewFileSearch then
		local handle = NewFileSearch(basePath .. "*.csv")
		while handle do
			t_insert(files, basePath .. handle:GetFileName())
			if not handle:NextFile() then
				break
			end
		end
	end
	return files
end

function LocalizationClass:HasLanguage(language)
	if language == "en-US" then
		return true
	end
	if fileExists("Data/Translations/" .. language .. "/manifest.lua") then
		return true
	end
	if NewFileSearch then
		return NewFileSearch("Data/Translations/" .. language .. "/*.csv") ~= nil
	end
	return false
end

function LocalizationClass:LoadLanguage(language)
	self.language = language or "en-US"
	self.translations = { }
	self.aliases = { }
	self.missing = { }
	self.missingOrder = { }
	self.stats = {
		files = 0,
		rows = 0,
		translations = 0,
		aliases = 0,
	}

	if self.language == "en-US" then
		logLocalization("language=%s fallback", self.language)
		return true
	end

	local files = self:GetTranslationFiles(self.language)
	for _, path in ipairs(files) do
		local text = readFile(path)
		if text then
			self.stats.files = self.stats.files + 1
			local rows = self:ParseCSV(text)
			local header = rows[1] or { }
			local index = { }
			for col, name in ipairs(header) do
				index[name] = col
			end
			for rowIndex = 2, #rows do
				local row = rows[rowIndex]
				self.stats.rows = self.stats.rows + 1
				local domain = row[index.domain or 1]
				local key = row[index.key or 2]
				local en = row[index.en or 3]
				local translated = row[index.ko or 4]
				local aliases = row[index.aliases or 5]
				if domain and key and translated and translated ~= "" then
					self.translations[domain] = self.translations[domain] or { }
					self.aliases[domain] = self.aliases[domain] or { }
					self.translations[domain][normaliseKey(key)] = translated
					self.aliases[domain][normaliseKey(key)] = splitAliases(aliases)
					self.stats.translations = self.stats.translations + 1
					if aliases and aliases ~= "" then
						self.stats.aliases = self.stats.aliases + 1
					end
				elseif domain and key and en and en ~= "" then
					self.translations[domain] = self.translations[domain] or { }
					self.aliases[domain] = self.aliases[domain] or { }
					self.aliases[domain][normaliseKey(key)] = splitAliases(aliases)
					if aliases and aliases ~= "" then
						self.stats.aliases = self.stats.aliases + 1
					end
				end
			end
		end
	end

	logLocalization(
		"language=%s files=%d rows=%d translations=%d aliasRows=%d",
		self.language,
		self.stats.files,
		self.stats.rows,
		self.stats.translations,
		self.stats.aliases
	)
	return true
end

function LocalizationClass:SetLanguage(language, allowWithoutUnicode)
	if language ~= "ko-KR" and language ~= "en-US" then
		language = "en-US"
	end
	if language == "ko-KR" and not allowWithoutUnicode and not self.hasUnicode then
		logLocalization("language=ko-KR rejected runtime=%s", self.runtimeReason or "unknown")
		language = "en-US"
	end
	if language == "ko-KR" and not self:HasLanguage(language) then
		logLocalization("language=ko-KR rejected missing translations")
		language = "en-US"
	end
	return self:LoadLanguage(language)
end

function LocalizationClass:DetectRuntimeCapabilities()
	local hasFeatureAPI = type(GetRuntimeFeature) == "function"
	local hasRenderAPI = type(CanRenderText) == "function"
	local legacyUtf8 = type(_G.utf8) == "table"
	local unicodeText = false
	local canRenderKorean = false
	local reason = "no runtime unicode capability"

	if hasFeatureAPI then
		local ok, value = pcall(GetRuntimeFeature, "unicodeText")
		unicodeText = ok and value == true
		if unicodeText then
			reason = "GetRuntimeFeature(unicodeText)"
		else
			reason = "GetRuntimeFeature(unicodeText)=false"
		end
	end

	if hasRenderAPI then
		local ok, value = pcall(CanRenderText, "\237\149\156\234\184\128")
		canRenderKorean = ok and value == true
		if canRenderKorean then
			reason = "CanRenderText(korean)=true"
		elseif not hasFeatureAPI then
			reason = "CanRenderText(korean)=false"
		end
	end

	if not hasFeatureAPI and not hasRenderAPI and legacyUtf8 then
		canRenderKorean = true
		reason = "legacy _G.utf8"
	end

	local supported = unicodeText or canRenderKorean
	logLocalization(
		"runtime unicodeText=%s canRenderKorean=%s legacyUtf8=%s featureAPI=%s renderAPI=%s reason=%s",
		tostring(unicodeText),
		tostring(canRenderKorean),
		tostring(legacyUtf8),
		tostring(hasFeatureAPI),
		tostring(hasRenderAPI),
		reason
	)

	return {
		hasFeatureAPI = hasFeatureAPI,
		hasRenderAPI = hasRenderAPI,
		legacyUtf8 = legacyUtf8,
		unicodeText = unicodeText,
		canRenderKorean = canRenderKorean,
		supported = supported,
		reason = reason,
	}
end

function LocalizationClass:RecordMissing(domain, key, fallback)
	if self.language == "en-US" or not domain or not key or fallback == nil or fallback == "" then
		return
	end
	local missingKey = domain .. "\t" .. normaliseKey(key)
	if not self.missing[missingKey] then
		self.missing[missingKey] = {
			domain = domain,
			key = normaliseKey(key),
			en = fallback
		}
		t_insert(self.missingOrder, missingKey)
		logLocalization("missing domain=%s key=%s fallback=%s", domain, normaliseKey(key), fallback)
	end
end

function LocalizationClass:ApplyVars(text, vars)
	if not vars then
		return text
	end
	return (text:gsub("{([%w_]+)}", function(key)
		local value = vars[key] or vars[tonumber(key)]
		return value ~= nil and tostring(value) or "{" .. key .. "}"
	end))
end

function LocalizationClass:Tr(domain, key, fallback, vars)
	key = normaliseKey(key)
	local translated = self.translations[domain] and self.translations[domain][key]
	if translated then
		return self:ApplyVars(translated, vars)
	end
	self:RecordMissing(domain, key, fallback)
	return self:ApplyVars(fallback or key, vars)
end

function LocalizationClass:Display(domain, key, fallback)
	return self:Tr(domain, key, fallback)
end

function LocalizationClass:GetAliases(domain, key)
	key = normaliseKey(key)
	return (self.aliases[domain] and self.aliases[domain][key]) or { }
end

function LocalizationClass:SearchText(domain, key, fallback, aliases)
	local parts = { }
	if fallback and fallback ~= "" then
		t_insert(parts, fallback)
	end
	local display = self:Display(domain, key, fallback)
	if display and display ~= "" and display ~= fallback then
		t_insert(parts, display)
	end
	for _, alias in ipairs(self:GetAliases(domain, key)) do
		t_insert(parts, alias)
	end
	for _, alias in ipairs(splitAliases(aliases)) do
		t_insert(parts, alias)
	end
	return StripEscapes(t_concat(parts, " "))
end

function LocalizationClass:SearchMatch(searchText, query)
	if not query or not query:match("%S") then
		return true
	end
	searchText = StripEscapes(tostring(searchText or "")):lower()
	local searchStr = tostring(query):lower():gsub("[%-%.%+%[%]%$%^%%%?%*]", "%%%0")
	local err, match = PCall(string.matchOrPattern, searchText, searchStr)
	return not err and match ~= nil
end

function LocalizationClass:DecorateData(gameData)
	if not gameData then
		return
	end

	if gameData.gems then
		for gemId, gem in pairs(gameData.gems) do
			gem.displayName = self:Display("gem", gemId, gem.name)
			gem.searchText = self:SearchText("gem", gemId, gem.name)
		end
	end

	if gameData.skills then
		for skillId, skill in pairs(gameData.skills) do
			if skill.name then
				skill.displayName = self:Display("skill", skillId, skill.name)
			end
			if skill.description then
				skill.displayDescription = self:Display("skill_description", skillId, skill.description)
			end
		end
	end

	if gameData.itemBases then
		for name, base in pairs(gameData.itemBases) do
			base.name = base.name or name
			base.displayName = self:Display("base", name, name)
			base.searchText = self:SearchText("base", name, name)
		end
	end

	if gameData.itemBaseLists then
		for _, list in pairs(gameData.itemBaseLists) do
			for _, entry in ipairs(list) do
				if entry.base then
					entry.label = (entry.base.displayName or entry.name):gsub(" %(.+%)", "")
					entry.searchFilter = entry.base.searchText or entry.name
				end
			end
		end
	end
end

function LocalizationClass:DecorateTree(tree)
	if not tree or not tree.nodes then
		return
	end
	for _, node in pairs(tree.nodes) do
		if node.id and node.dn then
			local nodeKey = tostring(node.id)
			node.displayName = self:Display("tree_dn", nodeKey, node.dn)
			node.displayStats = { }
			local searchParts = { node.dn, node.displayName }
			for index, line in ipairs(node.sd or { }) do
				local lineKey = nodeKey .. ":" .. index
				node.displayStats[index] = self:Display("tree_sd", lineKey, line)
				t_insert(searchParts, line)
				t_insert(searchParts, node.displayStats[index])
			end
			node.searchText = StripEscapes(t_concat(searchParts, " "))
		end
	end
end

function LocalizationClass:WriteRuntimeSmokeReport(gameData)
	local path = os.getenv("POB_LOCALIZATION_SMOKE_FILE")
	if not path or path == "" then
		return
	end

	local out = io.open(path, "wb")
	if not out then
		logLocalization("failed to write runtime smoke report: %s", path)
		return
	end

	local function row(key, value)
		writeEscapedCSVField(out, key)
		out:write(",")
		writeEscapedCSVField(out, value)
		out:write("\n")
	end

	local sampleGem = gameData and gameData.gems and gameData.gems["Metadata/Items/Gems/SkillGemIceNova"]
	local sampleBase = gameData and gameData.itemBases and gameData.itemBases["Chain Tiara"]

	row("language", self.language)
	row("hasUnicode", tostring(self.hasUnicode))
	row("runtimeReason", self.runtimeReason or "")
	row("translationFiles", self.stats and self.stats.files or 0)
	row("translationRows", self.stats and self.stats.rows or 0)
	if sampleGem then
		row("sampleGem.name", sampleGem.name)
		row("sampleGem.displayName", sampleGem.displayName)
		row("sampleGem.searchText", sampleGem.searchText)
	end
	if sampleBase then
		row("sampleBase.name", sampleBase.name)
		row("sampleBase.displayName", sampleBase.displayName)
		row("sampleBase.searchText", sampleBase.searchText)
	end

	out:close()
	logLocalization("runtime smoke report written: %s", path)
end

function LocalizationClass:WriteMissing(userPath)
	if self.language == "en-US" or #self.missingOrder == 0 then
		return
	end
	if not (os.getenv("POB_REPORT_MISSING_TRANSLATIONS") == "1" or launch and launch.devMode) then
		return
	end
	local path = (userPath and userPath ~= "" and userPath or "") .. "missing-" .. self.language .. ".csv"
	local out = io.open(path, "wb")
	if not out then
		return
	end
	out:write("domain,key,en,ko,aliases\n")
	for _, missingKey in ipairs(self.missingOrder) do
		local row = self.missing[missingKey]
		writeEscapedCSVField(out, row.domain)
		out:write(",")
		writeEscapedCSVField(out, row.key)
		out:write(",")
		writeEscapedCSVField(out, row.en)
		out:write(",,\n")
	end
	out:close()
	logLocalization("wrote missing report path=%s rows=%d", path, #self.missingOrder)
end

local requestedLanguage = os.getenv("POB_LANG")
loc = setmetatable({
	hasUnicode = false,
	language = "en-US",
	translations = { },
	aliases = { },
	missing = { },
	missingOrder = { },
}, LocalizationClass)

loc.runtime = loc:DetectRuntimeCapabilities()
loc.hasUnicode = loc.runtime.supported
loc.runtimeReason = loc.runtime.reason

if requestedLanguage == "en-US" then
	loc:SetLanguage("en-US", true)
elseif requestedLanguage == "ko-KR" then
	loc:SetLanguage("ko-KR")
elseif loc.hasUnicode and loc:HasLanguage("ko-KR") then
	loc:SetLanguage("ko-KR")
else
	loc:SetLanguage("en-US", true)
end

return loc
