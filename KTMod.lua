--[[ 
####################################

KTMod By Atreyyo @ Vanillagaming.org

####################################
]]

-- libs

local HealComm = AceLibrary("HealComm-1.0")
local AceEvent = AceLibrary("AceEvent-2.0")

-- Frames

KTMod = CreateFrame('Button', "KTMod", UIParent); -- Event Frame
KTMod.Config = CreateFrame('Button', "KTMod Config Frame", UIParent); -- Config frame
KTMod.FrostBlast = CreateFrame('Button', "KTMod Frost Blast Frame", UIParent); -- Frost Blast frame
KTMod.CoKT = CreateFrame('Button', "KTMod Chains of Kel'Thuzad Frame", UIParent); -- Chains of Kel'Thuzad frame

local mcTimer = nil

-- Tables

KTMod.FrostBlast.Frames = {}
--KTMod.FrostBlast.Table = {}
KTMod.CoKT.Table = {}
KTMod.CoKT.Frames = {}
KTMod.Config.Options = KTMod.Config.Options or {}

KTMod.CoKT.CC = {
	["Mage"] = {
		["Polymorph"] = "Interface\\Icons\\Spell_Nature_Polymorph",
		["Polymorph: Turtle"] = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
		["Polymorph: Pig"] = "Interface\\Icons\\Spell_Magic_PolymorphPig",
	},
	["Priest"] = {
		["Psychic Scream"]="Interface\\Icons\\Spell_Shadow_PsychicScream",
	},
	["Warrior"] = {
		["Intimidating Shout"]="Interface\\Icons\\Intimidating Shout",
	},
	["Warlock"] = {
		["Fear"]="Interface\\Icons\\Spell_Shadow_Possession",
	},
	["Paladin"] = {
		["Hammer of Justice"]="Interface\\Icons\\Spell_Holy_SealOfMight",
	},
	["Rogue"] = {
		["Blind"] = "interface\\Icons\\Spell_Shadow_MindSteal",
	},
	["Hunter"] = {},
	["Druid"] = {},
	["Shaman"] = {},
}

KTMod.FrostBlast.Heal = {
	["Druid"] = {
		["Rejuvenation"] = {},
		["Regrowth"] = {},
		["Healing Touch"] = {},
	},
	["Priest"] = {
		["Renew"] = {},
		["Power Word: Shield"] = {},
		["Flash Heal"] = {},
		["Heal"] = {},
		["Greater Heal"] = {},
		["Prayer of Healing"] = {},
	},
	["Paladin"] = {
		["Holy Shock"] = {},
		["Flash of Light"] = {},
		["Holy Light"] = {},
	},
	["Shaman"] = {
		["Chain Heal"] = {},
		["Lesser Healing Wave"] = {},
	},
}

KTMod.Default = {
	["x"] = 150,
	["y"] = 20,
	["Frost Blast Timer"] = 6,
	["Chains of Kel'Thuzad Timer"] = 60,
	["Bar Debug"] = 0,
	["Debug Update"] = nil,
	["Frost Debug Timer"] = nil,
	["CoKT Debug Timer"] = nil,
	["Chains of Kel'Thuzad"] = nil,
	["Frost Blast"] = nil,
}

-- vars

local KTModIsEnabled = false
local KTModFightStarted = nil
local HasKTMod = {}
local KTModLastFrostBlast = nil
-- end vars

function KTMod:GetClassSpells(type)
	if type == "heal" then
		if UnitClass("player") == "Warrior" then return ""
		elseif UnitClass("player") == "Hunter" then return ""
		elseif UnitClass("player") == "Mage" then return ""
		elseif UnitClass("player") == "Rogue" then return ""
		elseif UnitClass("player") == "Warlock" then return ""
		elseif UnitClass("player") == "Druid" then return "Healing Touch"
		elseif UnitClass("player") == "Shaman" then return "Chain Heal"	
		elseif UnitClass("player") == "Priest" then return "Flash Heal"
		elseif UnitClass("player") == "Paladin" then return "Flash of Light"
		end
	elseif type == "cc" then
		if UnitClass("player") == "Warrior" then return "Intimidating Shout"
		elseif UnitClass("player") == "Hunter" then return ""
		elseif UnitClass("player") == "Mage" then return "Polymorph"
		elseif UnitClass("player") == "Rogue" then return "Blind"
		elseif UnitClass("player") == "Warlock" then return "Fear"
		elseif UnitClass("player") == "Druid" then return ""
		elseif UnitClass("player") == "Shaman" then return ""	
		elseif UnitClass("player") == "Priest" then return "Psychic Scream"
		elseif UnitClass("player") == "Paladin" then return "Hammer of Justice"
		end
	end
end

-- debuff tooltip
KTMod.tooltip = CreateFrame("GAMETOOLTIP", "DebuffScan")
KTMod.tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
KTMod.tooltipTextL = KTMod.tooltip:CreateFontString()
KTMod.tooltipTextR = KTMod.tooltip:CreateFontString()
KTMod.tooltip:AddFontStrings(KTMod.tooltipTextL,KTMod.tooltipTextR)


--register events 
KTMod:RegisterEvent("ADDON_LOADED")
KTMod:RegisterEvent("RAID_ROSTER_UPDATE")
KTMod:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
KTMod:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
KTMod:RegisterEvent("CHAT_MSG_MONSTER_YELL")
KTMod:RegisterEvent("MINIMAP_ZONE_CHANGED")
KTMod:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
KTMod:RegisterEvent("CHAT_MSG_ADDON")

function KTMod:FrostBlastCheck()
	if KTMod:RaidInCombat() then
		for i=1,GetNumRaidMembers() do
			--if KTMod:GetBuff("raid"..i,"Rejuvenation") then
			if KTMod:GetDebuff("raid"..i,"Frost Blast") then
				if KTModLastFrostBlast == nil or (GetTime()-KTModLastFrostBlast) > KTMod_Settings["Frost Blast Timer"] then
					KTModLastFrostBlast = GetTime()
					KTMod_Settings["Frost Blast"] = GetTime()
				end
				if KTMod.FrostBlast.Table == nil then
					KTMod.FrostBlast.Table = {}
				end
				if KTMod.FrostBlast.Table[UnitName("raid"..i)] == nil then
					KTMod.FrostBlast.Table[UnitName("raid"..i)] = "raid"..i
				end
			end
		end
	end
end

function KTMod:CoKTCheck()
	if KTMod:RaidInCombat() then
		for i=1,GetNumRaidMembers() do
			if KTMod:GetDebuff("raid"..i,"Chains of Kel'Thuzad") then
				if KTMod_Settings["Chains of Kel'Thuzad"] == nil or (GetTime()-KTMod_Settings["Chains of Kel'Thuzad"]) > KTMod_Settings["Chains of Kel'Thuzad Timer"] then
					KTMod_Settings["Chains of Kel'Thuzad"] = GetTime()
				end
				if KTMod.CoKT.Table[UnitName("raid"..i)] == nil then
					KTMod.CoKT.Table[UnitName("raid"..i)] = "raid"..i
				end
			end
		end
	end 
end

-- event function, will load the frames we need

function KTMod:OnEvent()
	if event == "ADDON_LOADED" and arg1 == "KTMod" then
		KTMod_Settings = KTMod_Settings or KTMod.Default
		for k,v in pairs(KTMod.Default) do
			if KTMod_Settings[k] == nil or KTMod_Settings[k] ~= v then
				KTMod_Settings[k] = v
			end
		end
		if KTMod_Settings["Heal"] == nil then
			KTMod_Settings["Heal"] = KTMod:GetClassSpells("heal")
		end
		if KTMod_Settings["xSlider"] == nil then
			KTMod_Settings["xSlider"] = 1
		end
		if KTMod_Settings["ySlider"] == nil then
			KTMod_Settings["ySlider"] = 1
		end
		KTMod_Settings["version"] = GetAddOnMetadata("KTMod", "Version")
		KTMod_Settings["Debug Update"] = nil
		KTMod_Settings["Frost Debug Timer"] = nil
		KTMod_Settings["CoKT Debug Timer"] = nil
		KTMod_Settings["Chains of Kel'Thuzad"] = nil
		KTMod_Settings["Frost Blast"] = nil
		KTMod.FrostBlast:Main()
		KTMod.CoKT:Main()
		KTMod.Config:Init()
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r v"..KTMod_Settings["version"].." by |cffF5F54AAtreyyo |rLoaded",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r type |cFFFFFF00 /KTMod fb|r to show/hide Frost Blast window",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r type |cFFFFFF00 /KTMod cokt|r to show/hide Chains of Kel'Thuzad window",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r type |cFFFFFF00 /KTMod options|r for options menu",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r |cFFFFFF00 Hold 'Alt' key to move the windows|r",1,1,1)
		KTMod:UnregisterEvent("ADDON_LOADED")
	elseif event == "RAID_ROSTER_UPDATE" then
		SendAddonMessage("KTMod","version"..KTMod_Settings["version"],"RAID")
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		local _,_,pName,sName = string.find(arg1, "(%a+)%s*casts?%s*(.+)")
		if sName == "Shadow Fissure." then
			SendChatMessage("Shadow Fissure on me! ("..UnitName("player")..")", "SAY")
			UIErrorsFrame:AddMessage("|cFF8000FF KTMod|r Shadow Fissure on |cFF"..KTMod:GetFFClassColors(UnitName("player"))..UnitName("player"))
			SetRaidTarget("player", 8)
		end
	elseif event == "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE" then
		local _,_,pName,sName = string.find(arg1, "(%a+)%s*casts?%s*(.+)")
		if sName == "Shadow Fissure." then
			UIErrorsFrame:AddMessage("|cFF8000FF KTMod|r Shadow Fissure on |cFF"..KTMod:GetFFClassColors(pName)..pName)
			TargetByName(pName)
			SetRaidTarget("target", 8)
			TargetLastTarget()
			--SendChatMessage("FISSURE ON YOU!","WHISPER",nil,pName)
		end
	elseif event == "CHAT_MSG_MONSTER_YELL" then
		if arg1 == "Minions, servants, soldiers of the cold dark, obey the call of Kel'Thuzad!" then
			print("Kel'Thuzad encounter started!")
			if not KTModIsEnabled then 
				KTModIsEnabled = true
			end
			KTModFightStarted = GetTime()
		end
	elseif event == "MINIMAP_ZONE_CHANGED" then
		if GetMinimapZoneText() == "Kel'Thuzad Chamber" then
			if not KTModIsEnabled then
				KTModIsEnabled = true
			end
			--if UnitAffectingCombat("player") and not KTModFightStarted then
			--	KTModFightStarted = true
			--end
		else
			KTModIsEnabled = false
			KTMod:StopAllFunctions()
			KTModFightStarted = nil
		end
	elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
		if KTModIsEnabled then
			if arg1 == "Kel'Thuzad" then
				KTModIsEnabled = false
				KTMod:StopAllFunctions()
			end
		end
	elseif event == "CHAT_MSG_ADDON" then
		if arg1 == "KTMod" and string.find(arg2,"version") and UnitName("player") ~= arg4 then
			local KTModv = string.sub(arg2,8,string.len(arg2))
			HasKTMod[arg4] = KTModv
		elseif arg1 == "KTMod" and string.find(arg2,"activate") then -- /script SendAddonMessage("KTMod","activate","RAID")
			KTModIsEnabled = true
			KTMod.FrostBlast:Show()
			KTMod.CoKT:Show()
		end
	end
end

function KTMod.FrostBlast:Update()
	if KTModIsEnabled then
		KTMod:FrostBlastCheck()
		--DEFAULT_CHAT_FRAME:AddMessage("FROSTBLAST")
		if KTMod_Settings["Frost Blast"] == nil or (GetTime()-KTMod_Settings["Frost Blast"]) > KTMod_Settings["Frost Blast Timer"] then
			if KTMod.FrostBlast.Table ~= nil then 
				for name, id in pairs(KTMod.FrostBlast.Table) do
					if KTMod.FrostBlast.Frames[name] then
						KTMod.FrostBlast.Frames[name]:Hide()
					end
				end
				if KTMod.FrostBlast.Table ~= nil then
					--DEFAULT_CHAT_FRAME:AddMessage("KTMod: Cleared Frost Blast table!")
					KTMod.FrostBlast.Table = nil
				end
			end
		end
	end
	if KTMod.FrostBlast:IsVisible() then
		
		if KTMod_Settings["Bar Debug"] == 1 then
			if KTMod_Settings["Debug Update"] == nil or (GetTime()-KTMod_Settings["Debug Update"]) > 1 then
			
			KTMod.FrostBlast.Frames["Frost Blast Timer"] = KTMod.FrostBlast.Frames["Frost Blast Timer"] or KTMod.FrostBlast:Timer()
			local frame = KTMod.FrostBlast.Frames["Frost Blast Timer"]
				local p = (30-(GetTime()-KTMod_Settings["Frost Debug Timer"]))/30
				local R,G,B=0,255,0
				if p > 0.5 then
					R = (1-p)*5.1
					G = 2.55
				else
					R = 2.55
					G = p*2.5
				end
				frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"]))
				frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:SetPoint("TOPLEFT",0,-((KTMod_Settings["y"]*KTMod_Settings["ySlider"])*5)-2)
				frame.texture:SetWidth(p*((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5)))
				frame.texture:SetHeight((KTMod_Settings["y"]*KTMod_Settings["ySlider"])-4)
				frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -2)
				frame.texture:SetVertexColor(R,G,B,1)
				if math.floor(30-(GetTime()-KTMod_Settings["Frost Debug Timer"])) > 0 then
					frame.text:SetText("Frost Blast in "..math.floor(30-(GetTime()-KTMod_Settings["Frost Debug Timer"])))
				else
					frame.text:SetText("Frost Blast inc!")
				end
				frame.text:SetPoint("CENTER",(KTMod_Settings["y"]*KTMod_Settings["ySlider"])-KTMod_Settings["y"], 0)
				frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:Show()
			
			local uClass = {
					[1] = "Warrior",
					[2] = "Druid",
					[3] = "Mage",
					[4] = "Warlock",
					[5] = "Priest",
					[6] = "Rogue",
				}
			local R,G,B,p=0,255,0,100
			for i=1,5 do
				p = (math.random(1,10))/10
				if p > 0.5 then
					R = (1-p)*5.1
					G = 2.55
				else
					R = 2.55
					G = p*2.5
				end
				
				KTMod.FrostBlast.Frames["TestFrame"..i] = KTMod.FrostBlast.Frames["TestFrame"..i] or KTMod.FrostBlast:AddFrame("TestFrame"..i)
				local r, l, t, b = KTMod:ClassPos(uClass[math.random(1,6)])
				local frame = KTMod.FrostBlast.Frames["TestFrame"..i]
				frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
				frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:SetPoint("TOPLEFT",0,-((KTMod_Settings["y"]*KTMod_Settings["ySlider"])*(i-1)))
				frame.text:SetText("Test"..i.." "..math.floor(p*100).."%")
				frame.text:SetPoint("CENTER",(KTMod_Settings["y"]*KTMod_Settings["ySlider"])-KTMod_Settings["y"], 0)
				frame.icon:SetTexCoord(r, l, t, b)
				frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame.hpbar:SetWidth(p*((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5)))
				frame.hpbar:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"]-2)
				frame.texture:SetWidth(p*((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5)))
				frame.texture:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"]-2)
				frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -1)
				frame.texture:SetVertexColor(R,G,B,1)
				frame:Show()
			end
			end
		else
			for i=1,5 do
				KTMod.FrostBlast.Frames["TestFrame"..i] = KTMod.FrostBlast.Frames["TestFrame"..i] or KTMod.FrostBlast:AddFrame("TestFrame"..i)
				local frame = KTMod.FrostBlast.Frames["TestFrame"..i]
				if frame:IsVisible() then
					frame:Hide()
				end
			end
			KTMod.FrostBlast.Frames["Frost Blast Timer"] = KTMod.FrostBlast.Frames["Frost Blast Timer"] or KTMod.FrostBlast:Timer()
			local frame = KTMod.FrostBlast.Frames["Frost Blast Timer"]
			if frame:IsVisible() then
				frame:Hide()
			end
		end
		
		-- enabled check
		if KTModIsEnabled then
		if KTMod.FrostBlast.Table ~= nil then
			local i = 0
			local R,G,B,p=0,255,0,100
			for name,id in pairs(KTMod.FrostBlast.Table) do
				p = (UnitHealth(id) / UnitHealthMax(id))
				KTMod.FrostBlast.Frames[name] = KTMod.FrostBlast.Frames[name] or KTMod.FrostBlast:AddFrame(name)
				if p > 0.5 then
					R = (1-p)*5.1
					G = 2.55
				else
					R = 2.55
					G = p*2.5
				end
				--DEFAULT_CHAT_FRAME:AddMessage(UnitClass(id))
				local r, l, t, b = KTMod:ClassPos(UnitClass(id))
				local frame = KTMod.FrostBlast.Frames[name]
				frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
				frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:SetPoint("TOPLEFT",0,-((KTMod_Settings["y"]*KTMod_Settings["ySlider"])*i))
				frame.text:SetText(name.." "..math.floor(p*100).."%")
				frame.text:SetPoint("CENTER",(KTMod_Settings["y"]*KTMod_Settings["ySlider"])-KTMod_Settings["y"], 0)
				frame.icon:SetTexCoord(r, l, t, b)
				frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame.hpbar:SetWidth(p*((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5)))
				frame.hpbar:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"]-2)
				frame.texture:SetWidth(p*((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5)))
				frame.texture:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"]-2)
				frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -1)
				frame.texture:SetVertexColor(R,G,B,1)
				frame:Show()
				
				if CheckInteractDistance(id,4) then
					frame.texture:SetVertexColor(R,G,B,1)
				else
					frame.texture:SetVertexColor(1.6,1.6,1.6,0.5)
				end
				frame:Show()
				i = i+1
			end
			KTMod.FrostBlast:UpdateHeal()
		end
		
		-- Frost Blast Timer
		if KTMod_Settings["Frost Blast"] ~= nil and KTMod:RaidInCombat() then
			KTMod.FrostBlast.Frames["Frost Blast Timer"] = KTMod.FrostBlast.Frames["Frost Blast Timer"] or KTMod.FrostBlast:Timer()
			local frame = KTMod.FrostBlast.Frames["Frost Blast Timer"]
				local p = (30-(GetTime()-KTMod_Settings["Frost Blast"]))/30
				local R,G,B=0,255,0
				if p > 0.5 then
					R = (1-p)*5.1
					G = 2.55
				else
					R = 2.55
					G = p*2.5
				end
				frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"]))
				frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:SetPoint("TOPLEFT",0,-((KTMod_Settings["y"]*KTMod_Settings["ySlider"])*5)-2)
				frame.texture:SetWidth(p*((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5)))
				frame.texture:SetHeight((KTMod_Settings["y"]*KTMod_Settings["ySlider"])-4)
				frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -2)
				frame.texture:SetVertexColor(R,G,B,1)
				if math.floor(30-(GetTime()-KTMod_Settings["Frost Blast"])) > 0 then
					frame.text:SetText("Frost Blast in "..math.floor(30-(GetTime()-KTMod_Settings["Frost Blast"])))
				else
					frame.text:SetText("Frost Blast inc!")
					KTMod_Settings["Frost Blast"] = GetTime()
				end
				frame.text:SetPoint("CENTER",(KTMod_Settings["y"]*KTMod_Settings["ySlider"])-KTMod_Settings["y"], 0)
				frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:Show()
		else
			KTMod.FrostBlast.Frames["Frost Blast Timer"] = KTMod.FrostBlast.Frames["Frost Blast Timer"] or KTMod.FrostBlast:Timer()
			local frame = KTMod.FrostBlast.Frames["Frost Blast Timer"]
			if frame:IsVisible() and KTMod_Settings["Bar Debug"] ~= 1 then
				frame:Hide()
			end
			if KTMod_Settings["Frost Blast"] ~= nil then KTMod_Settings["Frost Blast"] = nil end
		end
		end -- end enable check
	end
end

function KTMod.CoKT:Update()
	if KTModIsEnabled  then
		KTMod:CoKTCheck()
	end
	if KTMod.CoKT:IsVisible() then
	
		if KTMod_Settings["Bar Debug"] == 1	then
			if KTMod_Settings["Debug Update"] == nil or (GetTime()-KTMod_Settings["Debug Update"]) > 1 then
			
			KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"] = KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"] or KTMod.CoKT:Timer()
			local frame = KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"]
				local p = (KTMod_Settings["Chains of Kel'Thuzad Timer"]-(GetTime()-KTMod_Settings["CoKT Debug Timer"]))/KTMod_Settings["Chains of Kel'Thuzad Timer"]
				local R,G,B=0,255,0
				if p > 0.5 then
					R = (1-p)*5.1
					G = 2.55
				else
					R = 2.55
					G = p*2.5
				end
				frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"]))
				frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:SetPoint("TOPLEFT",0,-((KTMod_Settings["y"]*KTMod_Settings["ySlider"])*5)-2)
				frame.texture:SetWidth(p*((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5)))
				frame.texture:SetHeight((KTMod_Settings["y"]*KTMod_Settings["ySlider"])-4)
				frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -2)
				frame.texture:SetVertexColor(R,G,B,1)
				if math.floor(KTMod_Settings["Chains of Kel'Thuzad Timer"]-(GetTime()-KTMod_Settings["CoKT Debug Timer"])) > 0 then
					frame.text:SetText("Mindcontrol in "..math.floor(KTMod_Settings["Chains of Kel'Thuzad Timer"]-(GetTime()-KTMod_Settings["CoKT Debug Timer"])))
				else
					frame.text:SetText("Mindcontrol inc!")
				end
				frame.text:SetPoint("CENTER",(KTMod_Settings["y"]*KTMod_Settings["ySlider"])-KTMod_Settings["y"], 0)
				frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:Show()
			
				local uClass = {
						[1] = "Warrior",
						[2] = "Druid",
						[3] = "Mage",
						[4] = "Warlock",
						[5] = "Priest",
						[6] = "Rogue",
					}
				local debugtextures = {
					[1] = "Interface\\Icons\\Spell_Nature_Polymorph",
					[2] = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
					[3] = "Interface\\Icons\\Spell_Magic_PolymorphPig",
					[4] = "Interface\\Icons\\Spell_Shadow_PsychicScream",
					[5] = "Interface\\Icons\\Intimidating Shout",
					[6] = "Interface\\Icons\\Spell_Shadow_Possession",
					[7] = "Interface\\Icons\\Spell_Holy_SealOfMight",
					[8] = "interface\\Icons\\Spell_Shadow_MindSteal",
				}
				for i=1,5 do
					local p = (math.random(1,10))/10
					KTMod.CoKT.Frames["TestFrame"..i] = KTMod.CoKT.Frames["TestFrame"..i] or KTMod.CoKT:AddFrame("TestFrame"..i)
					local frame = KTMod.CoKT.Frames["TestFrame"..i]
					local r, l, t, b = KTMod:ClassPos(uClass[math.random(1,6)])
					frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
					frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame:SetPoint("TOPLEFT",0,-((KTMod_Settings["y"]*KTMod_Settings["ySlider"])*(i-1)))
					frame.texture:SetWidth(KTMod_Settings["x"]*KTMod_Settings["xSlider"]-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5))
					frame.texture:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"]-2)
					frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -1)
					frame.texture:SetVertexColor(0,0,2.55,1)
					frame.text:SetText("Test"..i.." "..math.floor(p*100).."%")	
					frame.text:SetPoint("CENTER",(KTMod_Settings["y"]*KTMod_Settings["ySlider"])-KTMod_Settings["y"], 0)
					frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame.icon:SetTexCoord(r, l, t, b)
					frame.cc:SetPoint('RIGHT', (KTMod_Settings["y"]*KTMod_Settings["ySlider"])+3, 0)
					frame.cc:SetTexture(debugtextures[math.random(1,8)])
					frame.cc:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame.cc:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame.cc:Show()
					frame:Show()
				end
			end
		else
			for i=1,5 do
				KTMod.CoKT.Frames["TestFrame"..i] = KTMod.CoKT.Frames["TestFrame"..i] or KTMod.CoKT:AddFrame("TestFrame"..i)
				local frame = KTMod.CoKT.Frames["TestFrame"..i]
				if frame:IsVisible() then
					frame:Hide()
				end
			end
			KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"] = KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"] or KTMod.CoKT:Timer()
			local frame = KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"]
			if frame:IsVisible() then
				frame:Hide()
			end
		end
		
		-- check if enabled
		
		if KTModIsEnabled then
		local i = 0
		if KTMod.CoKT.Table ~= nil then
			for name, id in pairs(KTMod.CoKT.Table) do
				local p = (UnitHealth(id) / UnitHealthMax(id))
				local r, l, t, b = KTMod:ClassPos(UnitClass(id))
				if KTMod:GetDebuff(id,"Chains of Kel'Thuzad") or KTMod:GetBuff(id,"Cause Insanity")then
					KTMod.CoKT.Frames[name] = KTMod.CoKT.Frames[name] or KTMod.CoKT:AddFrame(name)
					local frame = KTMod.CoKT.Frames[name]
					frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
					frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame:SetPoint("TOPLEFT",0,-((KTMod_Settings["y"]*KTMod_Settings["ySlider"])*i))
					frame.texture:SetWidth(KTMod_Settings["x"]*KTMod_Settings["xSlider"]-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5))
					frame.texture:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -1)
					if CheckInteractDistance(id,4) then
						frame.texture:SetVertexColor(0,0,2.55,1)
					else
						frame.texture:SetVertexColor(1.6,1.6,1.6,0.5)
					end
					frame.text:SetText(name.." "..math.floor(p*100).."%")	
					frame.text:SetPoint("CENTER",(KTMod_Settings["y"]*KTMod_Settings["ySlider"])-KTMod_Settings["y"], 0)
					frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame.icon:SetTexCoord(r, l, t, b)
					frame:Show()
					for class,_ in pairs(KTMod.CoKT.CC) do
						for spell,icon in pairs(KTMod.CoKT.CC[class]) do
							if KTMod:GetDebuff(id,spell) then
								frame.cc:SetTexture(icon)
								frame.cc:SetPoint('RIGHT', (KTMod_Settings["y"]*KTMod_Settings["ySlider"])+3, 0)
								frame.cc:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
								frame.cc:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
								frame.cc:Show()
							else
								if frame.cc:GetTexture() == icon then
									frame.cc:Hide()
								end	
							end
						end
					end
					i=i+1
				else
					if KTMod.CoKT.Frames[name] then
						KTMod.CoKT.Frames[name]:Hide()
						KTMod.CoKT.Frames[name].cc:Hide()
					end
					KTMod.CoKT.Table[name] = nil
				end
			end
		end
		-- Chains of Kel'Thuzad Timer
		if KTMod_Settings["Chains of Kel'Thuzad"] ~= nil and KTMod:RaidInCombat() then
			KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"] = KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"] or KTMod.CoKT:Timer()
			local frame = KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"]
				local p = (KTMod_Settings["Chains of Kel'Thuzad Timer"]-(GetTime()-KTMod_Settings["Chains of Kel'Thuzad"]))/KTMod_Settings["Chains of Kel'Thuzad Timer"]
				local R,G,B=0,255,0
				if p > 0.5 then
					R = (1-p)*5.1
					G = 2.55
				else
					R = 2.55
					G = p*2.5
				end
				frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"]))
				frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:SetPoint("TOPLEFT",0,-((KTMod_Settings["y"]*KTMod_Settings["ySlider"])*5)-2)
				frame.texture:SetWidth(p*((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5)))
				frame.texture:SetHeight((KTMod_Settings["y"]*KTMod_Settings["ySlider"])-4)
				frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -2)
				frame.texture:SetVertexColor(R,G,B,1)
				if math.floor(KTMod_Settings["Chains of Kel'Thuzad Timer"]-(GetTime()-KTMod_Settings["Chains of Kel'Thuzad"])) > 0 then
					frame.text:SetText("Mindcontrol in "..math.floor(KTMod_Settings["Chains of Kel'Thuzad Timer"]-(GetTime()-KTMod_Settings["Chains of Kel'Thuzad"])))
				else
					frame.text:SetText("Mindcontrol inc!")
				end
				frame.text:SetPoint("CENTER",(KTMod_Settings["y"]*KTMod_Settings["ySlider"])-KTMod_Settings["y"], 0)
				frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
				frame:Show()
		else
			KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"] = KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"] or KTMod.CoKT:Timer()
			local frame = KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"]
			if frame:IsVisible() and KTMod_Settings["Bar Debug"] ~= 1 then
				frame:Hide()
			end
			if KTMod_Settings["Chains of Kel'Thuzad"] ~= nil then KTMod_Settings["Chains of Kel'Thuzad"] = nil end
		end
		end -- end if enabled
	end
end

-- Frost Blast main window

function KTMod.FrostBlast:Main()
	KTMod.FrostBlast.Drag = {}
	function KTMod.FrostBlast.Drag:StartMoving()
		this:StartMoving()
		this.drag = true
	end
	
	function KTMod.FrostBlast.Drag:StopMovingOrSizing()
		this:StopMovingOrSizing()
		this.drag = false
	end
	
	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="16",
			edgeSize="4",
			insets={
				left="5",
				right="5",
				top="2",
				bottom="2"
			}
	}
	
	self:SetFrameStrata("BACKGROUND")
	self:SetWidth(KTMod_Settings["x"]*KTMod_Settings["xSlider"]) 
	self:SetHeight(KTMod_Settings["y"]) 
	self:SetPoint("CENTER",0,0)
	self:SetMovable(1)
	self:EnableMouse(1)
	self:RegisterForDrag("LeftButton")
	self:SetBackdrop(backdrop) --border around the frame
	self:SetBackdropColor(0,0,0,1)

	self:SetScript("OnDragStart", KTMod.FrostBlast.Drag.StartMoving)
	self:SetScript("OnDragStop", KTMod.FrostBlast.Drag.StopMovingOrSizing)
	self:SetScript("OnUpdate", function()
		this:EnableMouse(IsAltKeyDown())
		if not IsAltKeyDown() and this.drag then
			self.Drag:StopMovingOrSizing()
		end
		KTMod.FrostBlast:Update()
	end)

	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="16",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="2",
				bottom="2"
			}
	}
	
	self.mainframe = CreateFrame('Button', "Main Frame", self); -- Main Frame
	self.mainframe:SetWidth(KTMod_Settings["x"]*KTMod_Settings["xSlider"])
	self.mainframe:SetHeight((KTMod_Settings["y"]*5)*KTMod_Settings["ySlider"])
	self.mainframe:SetPoint("TOPLEFT",0,-(KTMod_Settings["y"])+1)
	self.mainframe:SetBackdrop(backdrop) --border around the frame
	self.mainframe:SetBackdropColor(0,0,0,1)

	self.backdrop = self:CreateTexture(nil, 'ARTWORK')
	self.backdrop:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
	self.backdrop:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"]-2)
	self.backdrop:SetPoint('TOPLEFT', 2, -2)
	self.backdrop:SetTexture(0.76,0,1.53,1)
	self.backdrop:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	
	self.text = self:CreateFontString(nil, "OVERLAY")
	self.text:SetPoint("LEFT", self, "LEFT", 5, 0)
	self.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	self.text:SetTextColor(1, 1, 1, 1)
	self.text:SetShadowOffset(2,-2)
	self.text:SetText("Frost Blast")

	-- create close button
	self.CloseButton = CreateFrame("Button",nil,self,"UIPanelCloseButton")
	self.CloseButton:SetPoint("TOPLEFT",self:GetWidth()-23,2)
	self.CloseButton:SetWidth(24)
	self.CloseButton:SetHeight(24)
	self.CloseButton:SetFrameStrata('MEDIUM')
	self.CloseButton:SetScript("OnClick", function() 
		PlaySound("igMainMenuOptionCheckBoxOn"); 
		self:Hide(); 
		KTMod_Settings["FrostBlastWin"] = 0 
		--DEFAULT_CHAT_FRAME:AddMessage("KTMod: Closing Frost Blast win".. KTMod_Settings["FrostBlastWin"])
	end)
	if KTMod_Settings["FrostBlastWin"] == nil or KTMod_Settings["FrostBlastWin"] == 0 then
		self:Hide()
	else
		self:Show()
	end
	AceEvent:RegisterEvent("HealComm_Healupdate", KTMod.FrostBlast.UpdateHeal)
end
--KTMod.FrostBlast.Table
--[[
function KTMod.FrostBlast:UpdateHeal(target)
	if KTMod.FrostBlast.Table ~= nil and KTMod.FrostBlast.Table[target] ~= nil then
		local healed = HealComm:getHeal(target)
		local health, maxHealth = UnitHealth(KTMod.FrostBlast.Table[target]), UnitHealthMax(KTMod.FrostBlast.Table[target])
		if healed > 0 and (health < maxHealth) then
			local frame = KTMod.FrostBlast.Frames[target]
			frame.incheal:Show()
			local healthWidth = frame.hpbar:GetWidth() * (health / maxHealth)
			local incWidth = frame.hpbar:GetWidth() * (healed / maxHealth)
			if (healthWidth + incWidth) > (frame.hpbar:GetWidth() * 1.3) then
				incWidth = (frame.hpbar:GetWidth() * 1.3) - healthWidth
			end
			frame.incheal:SetWidth(incWidth)
			frame.incheal:SetHeight(LunaPlayerFrame.bars["Healthbar"]:GetHeight())
			frame.incheal:ClearAllPoints()
			frame.incheal:SetPoint("TOPRIGHT", frame.hpbar, "TOPRIGHT", 0, -1)
		else
			frame.incheal:Hide()
		end
	end
end
]]

function KTMod.FrostBlast:UpdateHeal()
	--DEFAULT_CHAT_FRAME:AddMessage("Event fired")
	if KTMod.FrostBlast.Table ~= nil then
	for name,id in pairs(KTMod.FrostBlast.Table) do
				--DEFAULT_CHAT_FRAME:AddMessage("Found target "..name)
				local frame = KTMod.FrostBlast.Frames[name]
				local healed = HealComm:getHeal(name)
				local health, maxHealth = UnitHealth(id), UnitHealthMax(id)
				local healers = HealComm:getNumHeals(name)
				if healed > 0 then
				--DEFAULT_CHAT_FRAME:AddMessage("Found target "..name.." healing for "..healed)
					--print("number of healers healing "..name.." is "..healers)
					frame.incheal:Show()
					local healthWidth = frame.hpbar:GetWidth() * (health / maxHealth)
					local incWidth = frame.hpbar:GetWidth() * (healed / maxHealth)
					if (healthWidth + incWidth) > (frame.hpbar:GetWidth() * 1.3) then
						incWidth = (frame.hpbar:GetWidth() * 1.3) - healthWidth
					end
					frame.incheal:SetWidth(incWidth)
					frame.incheal:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
					frame.incheal.texture:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"]-2)
					frame.incheal.texture:SetWidth(incWidth)
					frame.incheal.text:SetText(healers)
					frame.incheal.text:SetPoint("CENTER",incWidth, 0)
					--frame.incheal:SetHeight(25)
					--frame.incheal:ClearAllPoints()
					frame.incheal:SetPoint("TOPLEFT", frame.hpbar:GetWidth()+(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2), -2)
					frame.incheal.text:Show()
				else
					frame.incheal:Hide()
					frame.incheal.text:Hide()
				end
		end
	end
end

-- Chains of Kel'Thuzad window

function KTMod.CoKT:Main()
	KTMod.CoKT.Drag = {}
	function KTMod.CoKT.Drag:StartMoving()
		this:StartMoving()
		this.drag = true
	end
	
	function KTMod.CoKT.Drag:StopMovingOrSizing()
		this:StopMovingOrSizing()
		this.drag = false
	end
	
	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="16",
			edgeSize="4",
			insets={
				left="5",
				right="5",
				top="2",
				bottom="2"
			}
	}
	
	self:SetFrameStrata("BACKGROUND")
	self:SetWidth(KTMod_Settings["x"]*KTMod_Settings["xSlider"]) 
	self:SetHeight(KTMod_Settings["y"]) 
	self:SetPoint("CENTER",0,0)
	self:SetMovable(1)
	self:EnableMouse(1)
	self:RegisterForDrag("LeftButton")
	self:SetBackdrop(backdrop) --border around the frame
	self:SetBackdropColor(0,0,0,1)

	self:SetScript("OnDragStart", KTMod.CoKT.Drag.StartMoving)
	self:SetScript("OnDragStop", KTMod.CoKT.Drag.StopMovingOrSizing)
	self:SetScript("OnUpdate", function()
		KTMod.CoKT:Update()
		this:EnableMouse(IsAltKeyDown())
		if not IsAltKeyDown() and this.drag then
			self.Drag:StopMovingOrSizing()
		end
	end)

	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="16",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="2",
				bottom="2"
			}
	}
	
	self.mainframe = CreateFrame('Button', "Main Frame", self); -- Main Frame
	self.mainframe:SetWidth(KTMod_Settings["x"]*KTMod_Settings["xSlider"])
	self.mainframe:SetHeight((KTMod_Settings["y"]*KTMod_Settings["ySlider"])*5)
	self.mainframe:SetPoint("TOPLEFT",0,-(KTMod_Settings["y"])+1)
	self.mainframe:SetBackdrop(backdrop) --border around the frame
	self.mainframe:SetBackdropColor(0,0,0,1)

	self.backdrop = self:CreateTexture(nil, 'ARTWORK')
	self.backdrop:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
	self.backdrop:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"]-2)
	self.backdrop:SetPoint('TOPLEFT', 2, -2)
	self.backdrop:SetTexture(0.76,0,1.53,1)
	self.backdrop:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	
	self.text = self:CreateFontString(nil, "OVERLAY")
	self.text:SetPoint("LEFT", self, "LEFT", 5, 0)
	self.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	self.text:SetTextColor(1, 1, 1, 1)
	self.text:SetShadowOffset(2,-2)
	self.text:SetText("Chains of Kel'Thuzad")

	-- create close button
	self.CloseButton = CreateFrame("Button",nil,self,"UIPanelCloseButton")
	self.CloseButton:SetPoint("TOPLEFT",self:GetWidth()-23,2)
	self.CloseButton:SetWidth(24)
	self.CloseButton:SetHeight(24)
	self.CloseButton:SetFrameStrata('MEDIUM')
	self.CloseButton:SetScript("OnClick", function() 
		PlaySound("igMainMenuOptionCheckBoxOn"); 
		self:Hide(); 
		KTMod_Settings["CoKTWin"] = 0
		--DEFAULT_CHAT_FRAME:AddMessage("KTMod: Closing CoKT".. KTMod_Settings["CoKTWin"])
	end)
	if KTMod_Settings["CoKTWin"] == nil or KTMod_Settings["CoKTWin"] == 0 then
		self:Hide()
	else
		self:Show()
	end
	
end

-- config window

function KTMod.Config:Init()

	KTMod.Config.Drag = {}
	function KTMod.Config.Drag:StartMoving()
		this:StartMoving()
		this.drag = true
	end
	
	function KTMod.Config.Drag:StopMovingOrSizing()
		this:StopMovingOrSizing()
		this.drag = false
	end

	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="16",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="2",
				bottom="2"
			}
	}
	
	self:SetFrameStrata("BACKGROUND")
	self:SetWidth(210) 
	self:SetHeight(200) 
	self:SetPoint("CENTER",0,0)
	self:EnableMouse(1)
	self:RegisterForDrag("LeftButton")
	self:SetBackdrop(backdrop) --border around the frame
	self:SetBackdropColor(0,0,0,1)
	self:SetMovable(1)
	self:SetScript("OnDragStart", KTMod.Config.Drag.StartMoving)
	self:SetScript("OnDragStop", KTMod.Config.Drag.StopMovingOrSizing)
	
	self.HealDropdown = CreateFrame("Button", "HealDropdown",self, "UIDropDownMenuTemplate")
	self.HealDropdown:SetPoint("TOPLEFT", -10 , -(KTMod_Settings["y"]*2))
	UIDropDownMenu_SetWidth(100, self.HealDropdown)
	
	self.HealRankDropdown = CreateFrame("Button", "Heal Rank Dropdown",self.HealDropdown, "UIDropDownMenuTemplate")
	self.HealRankDropdown:SetPoint("RIGHT", 80 , 0)
	UIDropDownMenu_SetWidth(65, self.HealRankDropdown)
	
	self.CCDropdown = CreateFrame("Button", "CC Dropdown",self, "UIDropDownMenuTemplate")
	self.CCDropdown:SetPoint("TOPLEFT", -10 , -(KTMod_Settings["y"]*4))
	UIDropDownMenu_SetWidth(150, self.CCDropdown)
	
	UIDropDownMenu_Initialize(self.HealDropdown, KTMod.Config.HealDrop)
	UIDropDownMenu_SetSelectedID(self.HealDropdown, KTMod_Settings["HealID"])
	
	UIDropDownMenu_Initialize(self.HealRankDropdown, KTMod.Config.HealRankDrop)
	UIDropDownMenu_SetSelectedID(self.HealRankDropdown, KTMod_Settings["HealRankID"])
	--UIDropDownMenu_SetSelectedName(self.HealRankDropdown, KTMod.FrostBlast.Heal[UnitClass("player")][KTMod_Settings["Heal"]][KTMod_Settings["HealRankID"]])
	--
	--if KTMod_Settings["HealRank"] ~= nil then
	--	UIDropDownMenu_SetSelectedName(KTMod.Config.HealRankDropdown, KTMod.FrostBlast.Heal[UnitClass("player")][KTMod_Settings["Heal"]][KTMod_Settings["HealRank"]])
	--else
	--	UIDropDownMenu_SetSelectedName(KTMod.Config.HealRankDropdown, "Rank "..getn(KTMod.FrostBlast.Heal[UnitClass("player")][KTMod_Settings["Heal"]]))
	--end

	
	UIDropDownMenu_Initialize(self.CCDropdown, KTMod.Config.CCDrop)
	UIDropDownMenu_SetSelectedID(self.CCDropdown, KTMod_Settings["CC"])
	
	local text = self:CreateFontString(nil, "OVERLAY")
	text:SetPoint("CENTER", 0, (KTMod_Settings["x"]/2)+10)
	text:SetFont("Fonts\\FRIZQT__.TTF", 12)
	text:SetTextColor(1, 1, 1, 1)
	text:SetShadowOffset(2,-2)
	text:SetText("KTMod v"..KTMod_Settings["version"].." options")
	
	local text = self:CreateFontString(nil, "OVERLAY")
	text:SetPoint("TOPLEFT", self.HealDropdown, "TOPLEFT", 20, 10)
	text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	text:SetTextColor(1, 1, 1, 1)
	text:SetShadowOffset(2,-2)
	text:SetText("Heal for click casting")
	
	local text = self:CreateFontString(nil, "OVERLAY")
	text:SetPoint("TOPLEFT", self.HealRankDropdown, "TOPLEFT", 20, 10)
	text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	text:SetTextColor(1, 1, 1, 1)
	text:SetShadowOffset(2,-2)
	text:SetText("Rank")
	
	local text = self:CreateFontString(nil, "OVERLAY")
	text:SetPoint("TOPLEFT", self.CCDropdown, "TOPLEFT", 20, 10)
	text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	text:SetTextColor(1, 1, 1, 1)
	text:SetShadowOffset(2,-2)
	text:SetText("CC spell for Chains of Kel'Thuzad")
	
	-- create close button
	self.CloseButton = CreateFrame("Button",nil,self,"UIPanelCloseButton")
	self.CloseButton:SetPoint("TOPLEFT",self:GetWidth()-23,2)
	self.CloseButton:SetWidth(24)
	self.CloseButton:SetHeight(24)
	self.CloseButton:SetFrameStrata('MEDIUM')
	self.CloseButton:SetScript("OnClick", function() 
		PlaySound("igMainMenuOptionCheckBoxOn"); 
		if KTMod_Settings["FrostBlastWin"] ~= 1 then
			KTMod.FrostBlast:Hide()
		end
		if KTMod_Settings["CoKTWin"] ~= 1 then
			KTMod.CoKT:Hide()
		end
		KTMod_Settings["Bar Debug"] = 0
		self:Hide();  
		end)
	
	local text = self:CreateFontString(nil, "OVERLAY")
	text:SetPoint("CENTER",self, "CENTER", 0, -(KTMod_Settings["x"]*0.15))
	text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	text:SetTextColor(1, 1, 1, 1)
	text:SetShadowOffset(2,-2)
	text:SetText("Window and bar size")
	
	-- slider x axis
	self.xSlider = CreateFrame("Slider", "x Slider", self, 'OptionsSliderTemplate')
	self.xSlider:SetWidth((KTMod_Settings["x"])*0.8)
	self.xSlider:SetHeight(20)
	self.xSlider:SetPoint("CENTER", self, "CENTER", 0, -(KTMod_Settings["x"]*0.30))
	self.xSlider:SetMinMaxValues(1, 2)
	self.xSlider:SetValue(KTMod_Settings["xSlider"])
	self.xSlider:SetValueStep(0.1)
	getglobal(self.xSlider:GetName() .. 'Low'):SetText('0%')
	getglobal(self.xSlider:GetName() .. 'High'):SetText('100%')
	self.xSlider:SetScript("OnValueChanged", function() 
		KTMod_Settings["xSlider"] = this:GetValue()
		for _, frame in pairs(KTMod.CoKT.Frames) do
			frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
		end
		for _, frame in pairs(KTMod.FrostBlast.Frames) do
			frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
		end
		KTMod.CoKT:SetWidth((KTMod_Settings["x"])*KTMod_Settings["xSlider"])
		KTMod.CoKT.backdrop:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
		KTMod.CoKT.mainframe:SetWidth((KTMod_Settings["x"])*KTMod_Settings["xSlider"])
		KTMod.CoKT.CloseButton:SetPoint("TOPLEFT",(KTMod_Settings["x"]*KTMod_Settings["xSlider"])-23,2)
		KTMod.FrostBlast:SetWidth((KTMod_Settings["x"])*KTMod_Settings["xSlider"])
		KTMod.FrostBlast.CloseButton:SetPoint("TOPLEFT",(KTMod_Settings["x"]*KTMod_Settings["xSlider"])-23,2)
		KTMod.FrostBlast.backdrop:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
		KTMod.FrostBlast.mainframe:SetWidth((KTMod_Settings["x"])*KTMod_Settings["xSlider"])
	end)
	self.xSlider:Show()
	
	local text = self:CreateFontString(nil, "OVERLAY")
	text:SetPoint("TOPLEFT", self.xSlider, "LEFT", -10, 5)
	text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	text:SetTextColor(1, 1, 1, 1)
	text:SetShadowOffset(2,-2)
	text:SetText("x")

	-- slider y axis
	self.ySlider = CreateFrame("Slider", "y Slider", self, 'OptionsSliderTemplate')
	self.ySlider:SetWidth((KTMod_Settings["x"])*0.8)
	self.ySlider:SetHeight(20)
	self.ySlider:SetPoint("CENTER", self, "CENTER", 0, -(KTMod_Settings["x"]*0.50))
	self.ySlider:SetMinMaxValues(1, 2)
	self.ySlider:SetValue(KTMod_Settings["ySlider"])
	self.ySlider:SetValueStep(0.1)
	getglobal(self.ySlider:GetName() .. 'Low'):SetText('0%')
	getglobal(self.ySlider:GetName() .. 'High'):SetText('100%')
	self.ySlider:SetScript("OnValueChanged", function() 
		KTMod_Settings["ySlider"] = this:GetValue()
		for _, frame in pairs(KTMod.CoKT.Frames) do
			frame:SetHeight((KTMod_Settings["y"]*KTMod_Settings["ySlider"]))
		end
		for _, frame in pairs(KTMod.FrostBlast.Frames) do
			frame:SetHeight((KTMod_Settings["y"]*KTMod_Settings["ySlider"]))
		end
		KTMod.CoKT.mainframe:SetHeight((KTMod_Settings["y"]*5)*KTMod_Settings["ySlider"])
		KTMod.FrostBlast.mainframe:SetHeight((KTMod_Settings["y"]*5)*KTMod_Settings["ySlider"])
	end)
	self.ySlider:Show()
	
	local text = self:CreateFontString(nil, "OVERLAY")
	text:SetPoint("TOPLEFT", self.ySlider, "LEFT", -10, 5)
	text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	text:SetTextColor(1, 1, 1, 1)
	text:SetShadowOffset(2,-2)
	text:SetText("y")

	self:Hide()
end

function KTMod.Config:HealDrop()
	local info={}
	local i=1
	if KTMod.FrostBlast.Heal[UnitClass("player")] then
	for k,v in pairs(KTMod.FrostBlast.Heal[UnitClass("player")]) do
		info.text=k
		info.value=i
		info.func= function () UIDropDownMenu_SetSelectedID(KTMod.Config.HealDropdown, this:GetID())
			KTMod_Settings["Heal"] = this:GetText()
			KTMod_Settings["HealID"] = this:GetID()
			KTMod.Config:HealRankDrop()
			UIDropDownMenu_SetSelectedName(KTMod.Config.HealRankDropdown, "Rank "..getn(KTMod.FrostBlast.Heal[UnitClass("player")][KTMod_Settings["Heal"]]))
			KTMod_Settings["HealRank"] = UIDropDownMenu_GetText(KTMod.Config.HealRankDropdown)
		end
		info.checked = nil
		info.checkable = nil
		UIDropDownMenu_AddButton(info, 1)
		i=i+1
	end
	end
end

function KTMod.Config:HealRankDrop()
	local info={}
	local i=1
	if KTMod.FrostBlast.Heal[UnitClass("player")] then
	for k,v in pairs(KTMod.FrostBlast.Heal[UnitClass("player")][KTMod_Settings["Heal"]]) do
		info.text=v
		info.value=i
		info.func= function () UIDropDownMenu_SetSelectedID(KTMod.Config.HealRankDropdown, this:GetID())
			KTMod_Settings["HealRankID"] = this:GetID()
			KTMod_Settings["HealRank"] = this:GetText()
		end
		info.checked = nil
		info.checkable = nil
		UIDropDownMenu_AddButton(info, 1)
		i=i+1
	end
	end
end

function KTMod.Config:CCDrop()
	local info={}
	local i=1
	for k,v in pairs(KTMod.CoKT.CC[UnitClass("player")]) do
		info.text=k
		info.value=i
		info.func= function () UIDropDownMenu_SetSelectedID(KTMod.Config.CCDropdown, this:GetID())
			KTMod_Settings["CC"] = this:GetID()
		end
		info.checked = nil
		info.checkable = nil
		UIDropDownMenu_AddButton(info, 1)
		i=i+1
	end
end

-- creates the frames

function KTMod.FrostBlast:AddFrame(name)
	local frame = CreateFrame('Button', name, KTMod.FrostBlast.mainframe)
	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="8",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="0",
				bottom="0"
			}
	}
	--frame:SetBackdrop(backdrop)
	frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
	frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame:SetBackdropColor(0,0,0,0.6)
	frame.hpbar = CreateFrame('Button', nil, frame)
	frame.hpbar:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5))
	frame.hpbar:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.hpbar:SetPoint('TOPLEFT', 0, -1)
	frame.hpbar:SetFrameLevel(2)
	
	frame.texture = frame.hpbar:CreateTexture(nil, 'ARTWORK')
	frame.texture:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5))
	frame.texture:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -1)
	frame.texture:SetTexture("Interface\\AddOns\\KTMod\\texture\\LiteStep.tga")
	frame.texture:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	frame.icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
	frame.icon:SetPoint('LEFT', 2, 0)
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetPoint("CENTER",0, 0)
	frame.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
	frame.text:SetTextColor(1, 1, 1, 1)
	frame.text:SetShadowOffset(1,-1)
	frame.text:SetText(name)
	frame.incheal = CreateFrame('Button', nil, frame)
	frame.incheal:SetWidth(((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5)) / 5)
	frame.incheal:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.incheal:SetPoint('TOPRIGHT', frame.hpbar, 'TOPRIGHT', 1, -1)
	frame.incheal.texture = frame.incheal:CreateTexture(nil, 'ARTWORK')
	frame.incheal.texture:SetWidth(frame.incheal:GetWidth())
	frame.incheal.texture:SetHeight(frame.incheal:GetHeight())
	frame.incheal.texture:SetTexture("Interface\\AddOns\\KTMod\\texture\\LiteStep.tga")
	frame.incheal.texture:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	frame.incheal.texture:SetVertexColor(0.67,0.9,0.15,0.8)
	frame.incheal.texture:SetPoint('TOPLEFT', 0,0)
	frame.incheal.text = frame:CreateFontString(nil, "OVERLAY")
	frame.incheal.text:SetPoint("LEFT",13, 0)
	frame.incheal.text:SetFont("Fonts\\FRIZQT__.TTF", 18)
	frame.incheal.text:SetTextColor(1, 1, 1, 1)
	frame.incheal.text:SetShadowOffset(1,-1)
	frame.incheal.text:SetText("")
	frame.incheal:SetFrameLevel(2)
	frame.incheal:Hide()
	frame:SetScript("OnClick", function()
				if KTMod_Settings["Bar Debug"] ~= 1 then
					if KTMod_Settings["Heal"] == nil then
						KTMod_Settings["Heal"] = KTMod:GetClassSpells("heal")
					end
					TargetUnit(KTMod.FrostBlast.Table[name])
					if KTMod_Settings["HealRank"] then
						CastSpellByName(KTMod_Settings["Heal"].."("..KTMod_Settings["HealRank"]..")")
					else
						CastSpellByName(KTMod_Settings["Heal"])
					end
				else
					if UIDropDownMenu_GetText(KTMod.Config.HealDropdown) then
						if UIDropDownMenu_GetText(KTMod.Config.HealRankDropdown) then
							DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r "..UIDropDownMenu_GetText(KTMod.Config.HealDropdown).." "..UIDropDownMenu_GetText(KTMod.Config.HealRankDropdown).." is set as your healing spell!")
						else
							DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r "..UIDropDownMenu_GetText(KTMod.Config.HealDropdown).." is set as your healing spell!")
						end
					else
						DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r no healing spell has been selected!")
					end
				end
		end)
	return frame
end

function KTMod.CoKT:AddFrame(name)
	local frame = CreateFrame('Button', name, KTMod.CoKT.mainframe)
	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="8",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="0",
				bottom="0"
			}
	}
	--frame:SetBackdrop(backdrop)
	frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
	frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame:SetBackdropColor(0,0,0,0.6)
	frame.texture = frame:CreateTexture(nil, 'ARTWORK')
	frame.texture:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5))
	frame.texture:SetHeight(KTMod_Settings["y"])
	frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -1)
	frame.texture:SetTexture("Interface\\AddOns\\KTMod\\texture\\LiteStep.tga")
	frame.texture:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	frame.icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
	frame.icon:SetPoint('LEFT', 2, 0)
	frame.cc = frame:CreateTexture(nil, 'ARTWORK')
	frame.cc:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.cc:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.cc:SetPoint('RIGHT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+3, 0)
	frame.cc:Hide()
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetPoint("CENTER",0, 0)
	frame.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
	frame.text:SetTextColor(1, 1, 1, 1)
	frame.text:SetShadowOffset(1,-1)
	frame.text:SetText(name)
	frame:SetScript("OnClick", function()
			if KTMod_Settings["Bar Debug"] ~= 1 then
				if KTMod_Settings["CC"] == nil then
					KTMod_Settings["CC"] = KTMod:GetClassSpells("CC")
				end
				--DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r Casting "..UIDropDownMenu_GetText(KTMod.Config.CCDropdown).." on "..name)
				TargetUnit(KTMod.CoKT.Table[name])
				if UIDropDownMenu_GetText(KTMod.Config.CCDropdown) then
					CastSpellByName(UIDropDownMenu_GetText(KTMod.Config.CCDropdown))
				else
					DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r You have to add a spell to use in the options menu first! /ktmod options")
				end
			else
				if UIDropDownMenu_GetText(KTMod.Config.CCDropdown) then
					DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r "..UIDropDownMenu_GetText(KTMod.Config.CCDropdown).." is set as your cc spell!")
				else
					DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r no cc spell has been selected!")
				end
			end
		end)
	return frame
end

function KTMod.FrostBlast:Timer()
	local frame = CreateFrame('Button', "Frost Blast Timer", KTMod.FrostBlast.mainframe)
	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="8",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="0",
				bottom="0"
			}
	}
	frame:SetBackdrop(backdrop)
	frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
	frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame:SetBackdropColor(0,0,0,0.9)
	frame.texture = frame:CreateTexture(nil, 'ARTWORK')
	frame.texture:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5))
	frame.texture:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -2)
	frame.texture:SetTexture("Interface\\AddOns\\KTMod\\texture\\LiteStep.tga")
	frame.texture:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	frame.icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.icon:SetTexture("Interface\\Icons\\Spell_Frost_FrostNova")
	frame.icon:SetPoint('LEFT', 2, 0)
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetPoint("CENTER",0, 0)
	frame.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
	frame.text:SetTextColor(1, 1, 1, 1)
	frame.text:SetShadowOffset(1,-1)
	frame.text:SetText("Possible Frost Blast in ")
	return frame
end

function KTMod.CoKT:Timer()
	local frame = CreateFrame('Button', "Chains of Kel'Thuzad Timer", KTMod.CoKT.mainframe)
	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="8",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="0",
				bottom="0"
			}
	}
	frame:SetBackdrop(backdrop)
	frame:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-4)
	frame:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame:SetBackdropColor(0,0,0,0.9)
	frame.texture = frame:CreateTexture(nil, 'ARTWORK')
	frame.texture:SetWidth((KTMod_Settings["x"]*KTMod_Settings["xSlider"])-(KTMod_Settings["y"]*KTMod_Settings["ySlider"]+5))
	frame.texture:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.texture:SetPoint('TOPLEFT', KTMod_Settings["y"]*KTMod_Settings["ySlider"]+2, -2)
	frame.texture:SetTexture("Interface\\AddOns\\KTMod\\texture\\LiteStep.tga")
	frame.texture:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	frame.icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon:SetWidth(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.icon:SetHeight(KTMod_Settings["y"]*KTMod_Settings["ySlider"])
	frame.icon:SetTexture("Interface\\Icons\\INV_Belt_18")
	frame.icon:SetPoint('LEFT', 2, 0)
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetPoint("CENTER",0, 0)
	frame.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
	frame.text:SetTextColor(1, 1, 1, 1)
	frame.text:SetShadowOffset(1,-1)
	frame.text:SetText("Mindcontrol in ")
	return frame
end

function KTMod:GetSpellRanks()
	if KTMod.FrostBlast.Heal[UnitClass("player")] then
		for heal,_ in pairs(KTMod.FrostBlast.Heal[UnitClass("player")]) do
		local numSpells = 0
		local numTables = 0
		for i=1,GetNumSpellTabs() do
			local _,_,n = GetSpellTabInfo(i)
			numSpells=numSpells+n
		end
		for a=1,numSpells do
			local spell,rank = GetSpellName(a,"BOOKTYPE_SPELL")
			if spell == heal then
				numTables = numTables+1
				KTMod.FrostBlast.Heal[UnitClass("player")][heal][numTables] = rank
			end
		end

		end
	end
end

function KTMod:GetBuff(name,buff,stacks)
	local a=1
	while UnitBuff(name,a) do
		local _, s = UnitBuff(name,a)
   		KTMod.tooltip:SetOwner(UIParent, "ANCHOR_NONE");
		KTMod.tooltip:ClearLines()
   		KTMod.tooltip:SetUnitBuff(name,a)
		local text = KTMod.tooltipTextL:GetText()
		if text == buff then 
			if stacks == 1 then
				return s
			else
				return true 
			end
		end
		a=a+1
	end
	return false
end

function KTMod:GetDebuff(name,buff,stacks)
	local a=1
	while UnitDebuff(name,a) do
		local _, s = UnitDebuff(name,a)
   		KTMod.tooltip:SetOwner(UIParent, "ANCHOR_NONE");
		KTMod.tooltip:ClearLines()
   		KTMod.tooltip:SetUnitDebuff(name,a)
		local text = KTMod.tooltipTextL:GetText()
		if text == buff then 
			if stacks == 1 then
				return s
			else
				return true 
			end
		end
		a=a+1
	end
	return false
end

function KTMod:ClassPos(class)
	if(class=="Warrior") then return 0, 0.25, 0, 0.25;	end
	if(class=="Mage")    then return 0.25, 0.5, 0,	0.25;	end
	if(class=="Rogue")   then return 0.5,  0.75,    0,	0.25;	end
	if(class=="Druid")   then return 0.75, 1,       0,	0.25;	end
	if(class=="Hunter")  then return 0,    0.25,    0.25,	0.5;	end
	if(class=="Shaman")  then return 0.25, 0.5,     0.25,	0.5;	end
	if(class=="Priest")  then return 0.5,  0.75,    0.25,	0.5;	end
	if(class=="Warlock") then return 0.75, 1,       0.25,	0.5;	end
	if(class=="Paladin") then return 0,    0.25,    0.5,	0.75;	end
	return 0.25, 0.5, 0.5, 0.75	-- Returns empty next one, so blank
end

-- function to format time into 00:00

function KTMod:time(left)
	local min = math.floor(left / 60)
	local sec = math.floor(math.mod(left, 60))

	if (this.min == min and this.sec == sec) then
		return nil
	end

	this.min = min
	this.sec = sec

	return string.format("%02d:%02s", min, sec)
end

function KTMod:GetClassColors(name)
	if name == UnitName("player") then
		if UnitClass("player") == "Warrior" then return 0.78, 0.61, 0.43,1
		elseif UnitClass("player") == "Hunter" then return 0.67, 0.83, 0.45
		elseif UnitClass("player") == "Mage" then return 0.41, 0.80, 0.94
		elseif UnitClass("player") == "Rogue" then return 1.00, 0.96, 0.41
		elseif UnitClass("player") == "Warlock" then return 0.58, 0.51, 0.79,1
		elseif UnitClass("player") == "Druid" then return 1, 0.49, 0.04,1
		elseif UnitClass("player") == "Shaman" then return 0.0, 0.44, 0.87	
		elseif UnitClass("player") == "Priest" then return 1.00, 1.00, 1.00
		elseif UnitClass("player") == "Paladin" then return 0.96, 0.55, 0.73
		end
	end
	if GetRaidRosterInfo(1) then
		for i=1,GetNumRaidMembers() do
			if UnitName("raid"..i) == name then
				if UnitClass("raid"..i) == "Warrior" then return 0.78, 0.61, 0.43,1
				elseif UnitClass("raid"..i) == "Hunter" then return 0.67, 0.83, 0.45
				elseif UnitClass("raid"..i) == "Mage" then return 0.41, 0.80, 0.94
				elseif UnitClass("raid"..i) == "Rogue" then return 1.00, 0.96, 0.41
				elseif UnitClass("raid"..i) == "Warlock" then return 0.58, 0.51, 0.79,1
				elseif UnitClass("raid"..i) == "Druid" then return 1, 0.49, 0.04,1
				elseif UnitClass("raid"..i) == "Shaman" then return 0.0, 0.44, 0.87	
				elseif UnitClass("raid"..i) == "Priest" then return 1.00, 1.00, 1.00
				elseif UnitClass("raid"..i) == "Paladin" then return 0.96, 0.55, 0.73
				end
			end
		end
	end
end

function KTMod:GetFFClassColors(name)
	for i=1,GetNumRaidMembers() do
		if UnitName("raid"..i) == name then
			if UnitClass("raid"..i) == "Warrior" then return "C79C6E"
			elseif UnitClass("raid"..i) == "Hunter" then return "ABD473"
			elseif UnitClass("raid"..i) == "Mage" then return "69CCF0"
			elseif UnitClass("raid"..i) == "Rogue" then return "FFF569"
			elseif UnitClass("raid"..i) == "Warlock" then return "9482C9"
			elseif UnitClass("raid"..i) == "Druid" then return "FF7D0A"
			elseif UnitClass("raid"..i) == "Shaman" then return "F781F3"
			elseif UnitClass("raid"..i) == "Priest" then return "FFFFFF"
			elseif UnitClass("raid"..i) == "Paladin" then return "F781F3"
			end
		end
	end
	return "FFFFFF"
end

function KTMod:InRaidCheck(name)
	if GetRaidRosterInfo(1) then
		for i=1,GetNumRaidMembers() do
			if name == UnitName("raid"..i) then
				return true
			end
		end
		return false
	end
end

function KTMod:RaidInCombat()
	if GetRaidRosterInfo(1) then
		for i=1,GetNumRaidMembers() do
			if UnitAffectingCombat("raid"..i) then
				return true
			end
		end
		return false
	end
end



function KTMod:ClearDB()
	if GetRaidRosterInfo(1) then
		for name,_ in pairs(KTMod_table) do
			if name ~= UnitName("player") and not KTMod:InRaidCheck(name) then
				KTMod_frames[name]:Hide()
				KTMod_table[name]=nil
			end
		end
	else
		for name,_ in pairs(KTMod_table) do
			if name ~= UnitName("player") and not KTMod:InRaidCheck(name) then
				KTMod_frames[name]:Hide()
				KTMod_table[name]=nil
			end
		end
	end
end

function KTMod:msg(text)
	local channel, chatnumber = ChatFrameEditBox.chatType
	if channel == "WHISPER" then
		chatnumber = ChatFrameEditBox.tellTarget
	elseif channel == "CHANNEL" then
		chatnumber = ChatFrameEditBox.channelTarget
	end
	SendChatMessage(text, channel, nil, chatnumber)

end
-- update and onevent who will trigger the update and event functions

-- slash commands

function KTMod.slash(arg1)
	if arg1 == nil or arg1 == "" then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r type |cFFFFFF00 /KTMod fb|r to show/hide Frost Blast window",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r type |cFFFFFF00 /KTMod cokt|r to show/hide Chains of Kel'Thuzad window",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r type |cFFFFFF00 /KTMod options|r for options menu",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r type |cFFFFFF00 /KTMod version|r to do a version check for the raid",1,1,1)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r |cFFFFFF00 Hold 'Alt' key to move the windows|r",1,1,1)
		else
		if arg1 == "fb" then
			if KTMod.FrostBlast:IsVisible() then
				KTMod.FrostBlast:Hide()
				KTMod_Settings["FrostBlastWin"] = 0
			else
				KTMod.FrostBlast:Show()
				KTMod_Settings["FrostBlastWin"] = 1
			end
		elseif arg1 == "cokt" then
			if KTMod.CoKT:IsVisible() then
				KTMod.CoKT:Hide()
				KTMod_Settings["CoKTWin"] = 0
			else
				KTMod.CoKT:Show()
				KTMod_Settings["CoKTWin"] = 1
			end
		elseif arg1 == "options" then
			KTMod:GetSpellRanks()
			KTMod_Settings["Bar Debug"] = 1
			KTMod.FrostBlast:Show()
			KTMod.CoKT:Show()
			KTMod.Config:Show()
		elseif arg1 == "version" then
			KTMod:version()
		else
			DEFAULT_CHAT_FRAME:AddMessage(arg1)
			DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r unknown command",1,0.3,0.3);
		end
	end
end

SlashCmdList['KTMod_SLASH'] = KTMod.slash
SLASH_KTMod_SLASH1 = '/ktmod'
SLASH_KTMod_SLASH2 = '/KTMOD'

function KTMod:Update()
	if KTMod_Settings["Debug Update"] == nil or (GetTime()-KTMod_Settings["Debug Update"]) > 1 then
		KTMod_Settings["Debug Update"] = GetTime()
		if KTMod_Settings["Frost Debug Timer"] == nil or (GetTime()-KTMod_Settings["Frost Debug Timer"]) > 30 then
			KTMod_Settings["Frost Debug Timer"] = GetTime()
		end
		if KTMod_Settings["CoKT Debug Timer"] == nil or (GetTime()-KTMod_Settings["CoKT Debug Timer"]) > 60 then
			KTMod_Settings["CoKT Debug Timer"] = GetTime()
		end
	end
	
	if KTModIsEnabled then
		if UnitAffectingCombat("player") and klhtm then
			if mcTimer == nil or (GetTime()-mcTimer) > 55 then
				for i=1,GetNumRaidMembers() do
					if KTMod:GetDebuff("raid"..i,"Chains of Kel'Thuzad") then
						if UnitName("raid"..i) == UnitName("player") then
							klhtm:ResetRaidThreat()
						end
						mcTimer = GetTime()
					end
				end
			end
		end
		if KTModFightStarted ~= nil and (GetTime()-KTModFightStarted) > 315 then
			KTModFightStarted = nil
			KTMod_Settings["Frost Blast"] = GetTime() -- /script KTMod_Settings["Frost Blast"] = GetTime()
		end
		if not KTMod:RaidInCombat() and KTMod_Settings["Frost Blast"] ~= nil then
			KTMod_Settings["Frost Blast"] = nil
		end
	else
	end
end

function KTMod:StopAllFunctions()
	if KTMod.FrostBlast.Frames["Frost Blast Timer"] and KTMod.FrostBlast.Frames["Frost Blast Timer"]:IsVisible() then
		KTMod.FrostBlast.Frames["Frost Blast Timer"]:Hide()
		KTMod_Settings["Frost Blast"] = nil
		KTModLastFrostBlast = nil
	end
	if KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"] and KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"]:IsVisible() then
		KTMod.CoKT.Frames["Chains of Kel'Thuzad Timer"]:Hide()
		KTMod_Settings["Chains of Kel'Thuzad"] = nil
	end
end

function KTMod:enable()
	if not KTModIsEnabled then
		KTModIsEnabled = true
		print("KTmod is now Enabled")
	else
		print("KTmod is already Enabled")
	end
end
function KTMod:version()
	local KTModv = ""
	local i = 0
	local count=0
	if GetRaidRosterInfo(1) then
		if HasKTMod ~= nil then
			DEFAULT_CHAT_FRAME:AddMessage("--[ |cFF8000FF KTMod "..KTMod_Settings["version"].."|r version check")
			for n,v in pairs(HasKTMod) do
				if KTMod:InRaidCheck(n) then
					KTModv = KTModv.."|cff"..KTMod:GetFFClassColors(n)..n.."|r v"..v..", "
					i=i+1
					if i == 5 then
						DEFAULT_CHAT_FRAME:AddMessage(KTModv)
						KTModv = ""
						i=0
					end
					count=count+1
				end
			end
			if KTModv ~= "" and KTModv ~= nil then
				DEFAULT_CHAT_FRAME:AddMessage(KTModv)
				
			end
			DEFAULT_CHAT_FRAME:AddMessage("--[ Total ["..count.."/"..GetNumRaidMembers().."] has KTMod.")
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFF8000FF KTMod:|r no players have KTMod.")
		end
	end
end

KTMod:SetScript("OnUpdate", KTMod.Update)
KTMod:SetScript("OnEvent", KTMod.OnEvent)

