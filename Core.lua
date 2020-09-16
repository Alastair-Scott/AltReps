local addonName, addon = ...
local core = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local LibQTip = LibStub('LibQTip-1.0')
addon.LDB = LibStub("LibDataBroker-1.1", true)
addon.icon = addon.LDB and LibStub("LibDBIcon-1.0", true)
-- Lua functions
local pairs = pairs

local C_Reputation_GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo

local miniTooltip = nil
local thisToon = UnitName("player") .. " - " .. GetRealmName()
local goldTextureString = "|TInterface\\Icons\\INV_Misc_Coin_01:0|t"
local paragonLootTextureString = "|TInterface\\Icons\\Inv_misc_bag_10:0|t"

local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local FONTEND = FONT_COLOR_CODE_CLOSE
local YELLOWFONT = LIGHTYELLOW_FONT_COLOR_CODE
local GOLDFONT = NORMAL_FONT_COLOR_CODE
local BLUEFONT = "|cff00ffdd";

local factionStandings = {
  [0] = "Unknown",
  [1] = "Hated",
  [2] = "Hostile",
  [3] = "Unfriendly",
  [4] = "Neutral",
  [5] = "Friendly",
  [6] = "Honored",
  [7] = "Revered",
  [8] = "Exalted",
}

local supplyChestIds = {
  [166295] = true, -- Proudmoore Admiralty Supplies
  [166297] = true, -- Order of Embers Supplies
  [166294] = true, -- Storm's Wake Supplies
  [166300] = true, -- 7th Legion Supplies
  [166292] = true, -- Zandalari Empire Supplies
  [166282] = true, -- Talanji's Expedition Supplies
  [166290] = true, -- Voldunai Supplies
  [166299] = true, -- Honorbound Supplies
  [166298] = true, -- Champions of Azeroth Supplies
  [166245] = true, -- Tortollan Seekers Supplies
  [170061] = true, -- Rustbolt Supplies
  [169939] = true, -- Ankoan Supplies
  [169940] = true, -- Unshackled Supplies
  [174484] = true, -- Uldum Accord Supplies
  [174483] = true, -- Rajani Supplies

  [146899] = true, -- Highmountain Supplies
  [146901] = true, -- Valarjar Strongbox
  [146897] = true, -- Farondis Chest
  [146898] = true, -- Dreamweaver Cache
  [146900] = true, -- Nightfallen Cache
  [146902] = true, -- Warden's Supply Kit
  [147361] = true, -- Legionfall Chest
  [152922] = true, -- Brittle Krokul Chest
  [152923] = true, -- Gleaming Footlocker
}

local defaultDB = {
  DBVersion = 3,
  MinimapIcon = { hide = false },
  Window = {},
  Options = {
    ColourParagon = true,
    Debug = false
  },
  Toons = {},
  Expansions = {
    [0] = {
      Name = "Battle for Azeroth",
      Id = 8
    },
    [1] = {
      Name = "Legion",
      Id = 7
    }
  },
  Factions = {
    [2103] = {
        Name = "Zandalari Empire",
        Show = true,
        ExpansionId = 8,
        For = "Horde"
    },
    [2156] = {
        Name = "Talanji's Expedition",
        Show = true,
        ExpansionId = 8,
        For = "Horde"
    },
    [2157] = {
        Name = "The Honorbound",
        Show = true,
        ExpansionId = 8,
        For = "Horde"
    },
    [2158] = {
        Name = "Voldunai",
        Show = true,
        ExpansionId = 8,
        For = "Horde"
    },
    [2159] = {
        Name = "7th Legion",
        Show = true,
        ExpansionId = 8,
        For = "Alliance"
    },
    [2160] = {
        Name = "Proudmoore Admiralty",
        Show = true,
        ExpansionId = 8,
        For = "Alliance"
    },
    [2161] = {
        Name = "Order of Embers",
        Show = true,
        ExpansionId = 8,
        For = "Alliance"
    },
    [2162] = {
        Name = "Storm's Wake",
        Show = true,
        ExpansionId = 8,
        For = "Alliance"
    },
    [2163] = {
        Name = "Tortollan Seekers",
        Show = true,
        ExpansionId = 8,
        For = "Alliance;Horde"
    },
    [2164] = {
        Name = "Champions of Azeroth",
        Show = true,
        ExpansionId = 8,
        For = "Alliance;Horde"
    },
    [2373] = {
        Name = "The Unshackled",
        Show = true,
        ExpansionId = 8,
        For = "Horde"
    },
    [2391] = {
        Name = "Rustbolt Resistance",
        Show = true,
        ExpansionId = 8,
        For = "Alliance;Horde"
    },
    [2400] = {
        Name = "Waveblade Ankoan",
        Show = true,
        ExpansionId = 8,
        For = "Alliance"
    },
    [2415] = {
        Name = "Rajani",
        Show = true,
        ExpansionId = 8,
        For = "Alliance;Horde"
    },
    [2417] = {
        Name = "Uldum Accord",
        Show = true,
        ExpansionId = 8,
        For = "Alliance;Horde"
    },
    [1828] = {
      Name = "Highmountain Tribe",
      Show = true,
      ExpansionId = 7,
      For = "Alliance;Horde"
    },
    [1859] = {
        Name = "The Nightfallen",
        Show = true,
        ExpansionId = 7,
        For = "Alliance;Horde"
    },
    [1883] = {
        Name = "Dreamweavers",
        Show = true,
        ExpansionId = 7,
        For = "Alliance;Horde"
    },
    [1894] = {
        Name = "The Wardens",
        Show = true,
        ExpansionId = 7,
        For = "Alliance;Horde"
    },
    [1900] = {
        Name = "Court of Farondis",
        Show = true,
        ExpansionId = 7,
        For = "Alliance;Horde"
    },
    [1948] = {
        Name = "Valarjar",
        Show = true,
        ExpansionId = 7,
        For = "Alliance;Horde"
    },
    [2045] = {
        Name = "Armies of Legionfall",
        Show = true,
        ExpansionId = 7,
        For = "Alliance;Horde"
    },
    [2165] = {
        Name = "Army of the Light",
        Show = true,
        ExpansionId = 7,
        For = "Alliance;Horde"
    },
    [2170] = {
        Name = "Argussian Reach",
        Show = true,
        ExpansionId = 7,
        For = "Alliance;Horde"
    }
  }
}

local options = {
  name = "AltReps",
  handler = core,
  type = 'group',
  args = {
    toggle = {
      name = "Show / Hide",
      guiHidden = true,
      type = "execute",
      func = function() core:ToggleVisibility() end,
    },
    config = {
      name = "Open config",
      guiHidden = true,
      type = "execute",
      func = function() core:ShowConfig() end,
    },
    General = {
      order = 1,
      type = "group",
      name = "General settings",
      cmdHidden = true,
      args = {
        ver = {
          order = 0.5,
          type = "description",
          name = function() return "Version: AltReps " .. addon.version end,
        },
        GeneralHeader = {
          order = 2,
          type = "header",
          name = "General settings",
        },
        MinimapIcon = {
          type = "toggle",
          name = "Show minimap button",
          desc = "Show the AltReps minimap button",
          order = 3,
          hidden = function() return not addon.icon end,
          get = function(info) return not core.db.MinimapIcon.hide end,
          set = function(info, value)
            core.db.MinimapIcon.hide = not value
            addon.icon:Refresh(addonName)
          end,
        },
        Debug = {
          type = "toggle",
          name = "Debug",
          desc = "Enable debug mode",
          order = 4,
          get = function(info) return core.db.Options.Debug end,
          set = function(info, value)
            core.db.Options.Debug = value
          end,
        },
      },
    },
    Factions = {
      order = 2,
      type = "group",
      name = "Faction settings",
      cmdHidden = true,
      args = {
        ParagonValueColor = {
          type = "toggle",
          order = 10,
          name = "Colour paragon",
          desc = "Should paragon reputations be coloured differently",
          get = function(info) return core.db.Options.ColourParagon end,
          set = function(info, value)
            core.db.Options.ColourParagon = value
            core:UpdateTooltip()
          end,
        },
        FactionsHeader = {
          type = "header",
          order = 100,
          name = "Factions"
        },
      },
    },
  },
}

function core:OnInitialize()
  local versionString = GetAddOnMetadata(addonName, "version")
  addon.version = versionString

  AltRepsDB = AltRepsDB or defaultDB

  if not AltRepsDB.DBVersion or AltRepsDB.DBVersion < 1 then
    AltRepsDB = defaultDB
  elseif AltRepsDB.DBVersion < 3 then
    AltRepsDB.Window = defaultDB.Window
    AltRepsDB.Options = defaultDB.Options
    AltRepsDB.Factions = defaultDB.Factions
    AltRepsDB.DBVersion = 3
  end

  core.db = AltRepsDB

  core:BuildOptions()
  
  core:ToonInit()

  addon.dataobject = addon.LDB and addon.LDB:NewDataObject("AltReps", {
    text = "AR",
    type = "launcher",
    icon = "Interface\\Addons\\AltReps\\icon.tga",
    OnEnter = function(frame) end,
    OnLeave = function(frame) end,
    OnClick = function(frame, button)
      if button == "RightButton" then
        core:ShowConfig()
      else
        core:ToggleVisibility()
      end
    end
  })
  if addon.icon then
    addon.icon:Register(addonName, addon.dataobject, core.db.MinimapIcon)
    addon.icon:Refresh(addonName)
  end
end

local itemLockedTime
function core:OnEnable()
  self:RegisterEvent("PLAYER_ENTERING_WORLD", function() core:UpdateReps() end)
  self:RegisterEvent("UPDATE_FACTION", function() core:UpdateReps() end)
  self:RegisterEvent("QUEST_TURNED_IN", function() core:UpdateReps() end)
  self:RegisterEvent("ITEM_LOCKED", function(_, bagId, slotId)
    if bagId and slotId then
      debug("Chest clicked: (BagId: " .. (bagId or "Unknown") .. ", SlotId: " .. (slotId or "Unknown") .. ")")
      local itemId =  GetContainerItemID(bagId, slotId)
      debug("Chest clicked: (ItemId: " .. (itemId or "Unknown") .. ")")
      if itemId and supplyChestIds[supplyChestIds] then
        debug("Chest clicked: (IsSupplyChest: " .. (supplyChestIds[supplyChestIds] or "False") .. ")")
        itemLockedTime = GetTime() 
      end
    end
  end)
  self:RegisterEvent("SHOW_LOOT_TOAST", function(_, type, _, value)
    debug("Show loot toast: (itemLockedTime: " .. (itemLockedTime or "Unknown") .. ", CurrentTime: " .. GetTime() .. ", IsSmallTimeDifference: " .. (itemLockedTime and GetTime() - itemLockedTime < 0.5) .. ", Type: " ..  (type or "Unknown") .. ", Value: " .. (value or "Unknown") ..")")
    if itemLockedTime and GetTime() - itemLockedTime < 0.5 and type == "money" then
      core.db.Toons[thisToon].SuppliesCopperTotal = (core.db.Toons[thisToon].SuppliesCopperTotal or 0) + value
      core:UpdateReps()
    end
  end)
end

function core:OnDisable()
  -- Called when the addon is disabled
end

function core:GetWindow()
  if not core.frame then
    local f = CreateFrame("Frame","AltRepsFrame", UIParent, "BasicFrameTemplate")
    f:SetMovable(true)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetUserPlaced(true)
    f:SetAlpha(0.5)
    if core.db.Window.posx and core.db.Window.posy then
      f:SetPoint("TOPLEFT",core.db.Window.posx,-core.db.Window.posy)
    else
      f:SetPoint("CENTER")
    end
    f:SetScript("OnMouseDown", function() f:StartMoving() end)
    f:SetScript("OnMouseUp", function() 
      f:StopMovingOrSizing() 
      core.db.Window.posx = f:GetLeft()
      core.db.Window.posy = UIParent:GetTop() - (f:GetTop()*f:GetScale())
    end)
    f:SetScript("OnHide", function()
      if core.tooltip then
        LibQTip:Release(core.tooltip)
        core.tooltip = nil
      end
    end)
    core:SkinFrame(f,f:GetName())
    core.frame = f
  end
end

function core:GetTooltip(frame)
  debug("GetTooltip: Start")
  if core.tooltip then LibQTip:Release(core.tooltip) end
  local tooltip = LibQTip:Acquire("AltRepsTooltip", 1, "LEFT")
  tooltip:SetCellMarginH(0)
  tooltip.anchorframe = f
  tooltip:Clear()
  tooltip:SetScale(1)
  core.tooltip = tooltip 
  
  local header = tooltip:AddHeader('AltReps')
  local columns = localarr("columns")
  local rows = localarr("rows")
  local hasAlliance = "xyz"
  local hasHorde = "xyz"

  for toonId, toon in pairs(core.db.Toons) do
    if toon.Faction == "Alliance" then hasAlliance = toon.Faction elseif toon.Faction == "Horde" then hasHorde = toon.Faction end;
    columns[toonId] = columns[toonId] or tooltip:AddColumn("CENTER")
    local toonname, toonserver = toonId:match('^(.*)[-](.*)$')
    tooltip:SetCell(header, columns[toonId], ClassColorise(toon.Class, toonname), "CENTER")
    tooltip:SetCellScript(header, columns[toonId], "OnEnter", ShowToonTooltip, toonId)
    tooltip:SetCellScript(header, columns[toonId], "OnLeave", CloseTooltips)
  end
  for _, expansion in orderedPairs(core.db.Expansions) do
    local hasExpansionRowBeenAdded = false
    
    for factionId, faction in orderedPairs(core.db.Factions) do
      if (faction.Show and expansion.Id == faction.ExpansionId and (string.find(faction.For, hasAlliance) or string.find(faction.For, hasHorde))) then
        if not hasExpansionRowBeenAdded then
          local expansionRow = tooltip:AddLine();    
          tooltip:SetCell(expansionRow, 1, GOLDFONT .. expansion.Name .. FONTEND)
          hasExpansionRowBeenAdded = true
        end
        rows[factionId] = rows[factionId] or tooltip:AddLine();
      end
    end
  end
  for factionId, row in pairs(rows) do
    local faction = core.db.Factions[factionId]
    tooltip:SetCell(row, 1, YELLOWFONT .. faction.Name .. FONTEND)
    for toonName, toon in pairs(core.db.Toons) do
      local rep = toon.Reps[factionId]
      if rep then
        local display = ""
        if rep.ParagonValue then
          display = mod(rep.ParagonValue, rep.ParagonThreshold) .. " / " .. rep.ParagonThreshold
          if core.db.Options.ColourParagon then display = BLUEFONT .. display .. FONTEND end
          if rep.HasParagonReward then display = display .. " " .. paragonLootTextureString end
        elseif rep.Current then
          display = rep.Current .. " / " .. rep.Max
        end
        tooltip:SetCell(row, columns[toonName], format(display))
        tooltip:SetCellScript(row, columns[toonName], "OnEnter", ShowFactionTooltip, { factionId = factionId, toonId = toonName})
        tooltip:SetCellScript(row, columns[toonName], "OnLeave", CloseTooltips)
      end
    end
  end
  local hi = true
  for i=2,tooltip:GetLineCount() do
    tooltip:SetLineScript(i, "OnEnter", DoNothing)
    tooltip:SetLineScript(i, "OnLeave", DoNothing)

    if hi then
      tooltip:SetLineColor(i, 1, 1, 1, 0.1)
      hi = false
    else
      tooltip:SetLineColor(i, 0, 0, 0, 0)
      hi = true
    end
  end
  
  local w,h = tooltip:GetSize()
  frame:SetSize(w*tooltip:GetScale(),(h+20)*tooltip:GetScale())
  core:SkinFrame(tooltip,"SavedInstancesTooltip")
  LibQTip.layoutCleaner:CleanupLayouts()
  tooltip:ClearAllPoints()
  tooltip:SetPoint("BOTTOMLEFT",frame)
  tooltip:SetFrameLevel(frame:GetFrameLevel()+1)
  tooltip:Show()
  debug("GetTooltip: End")
end

function core:UpdateTooltip()
  debug("UpdateTooltip: Start")
  if core.frame and core.frame:IsShown() then
    core:GetTooltip(core.frame)
  end
  debug("UpdateTooltip: End")
end

function core:ToonInit()
  local ti = core.db.Toons[thisToon] or { }
  core.db.Toons[thisToon] = ti
  ti.LClass, ti.Class = UnitClass("player")
  ti.Faction, ti.LFaction = UnitFactionGroup("player")
end

function core:UpdateReps()
  debug("UpdateReps: Start")
  local toon = core.db.Toons[thisToon]
  for factionId, _ in pairs(core.db.Factions) do
    local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfoByID(factionId)
    local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionId)
    if not toon.Reps then toon.Reps = {} end
    if not (atWarWith and not canToggleAtWar) and name then
      toon.Reps[factionId] = {
        Current = barValue - barMin,
        Max = barMax - barMin,
        Standing = standingID,
        HasParagonReward = hasRewardPending,
        ParagonValue = currentValue,
        ParagonThreshold = threshold
      }
    end
  end
  core:UpdateTooltip()
  debug("UpdateReps: End")
end

function core:ToggleVisibility(info)
  if core.frame and core.frame:IsShown() then
    core.frame:Hide()
  else
    core:GetWindow()
    core:GetTooltip(core.frame)
    core.frame:Show()
  end
end

function core:ShowConfig()
  if _G.InterfaceOptionsFrame:IsShown() then
    _G.InterfaceOptionsFrame:Hide()
  else
    InterfaceOptionsFrame_OpenToCategory(core.optionsFactionsFrame)
    InterfaceOptionsFrame_OpenToCategory(core.optionsGeneralFrame)
  end
end

function core:SkinFrame(frame,name)
  if IsAddOnLoaded("ElvUI") or IsAddOnLoaded("Tukui") then
    if frame.StripTextures then
      frame:StripTextures()
    end
    if frame.SetTemplate then
      frame:SetTemplate("Transparent")
    end
    local close = _G[name.."CloseButton"] or frame.CloseButton
    if close and close.SetAlpha then
      if ElvUI then
        ElvUI[1]:GetModule('Skins'):HandleCloseButton(close)
      end
      if Tukui and Tukui[1] and Tukui[1].SkinCloseButton then
        Tukui[1].SkinCloseButton(close)
      end
      close:SetAlpha(1)
    end
  end
end

function core:BuildOptions()
  local calculatedOrder = options.args.Factions.args.FactionsHeader.order
  for _ , expansion in orderedPairs(core.db.Expansions) do
    calculatedOrder = calculatedOrder + 1
    options.args.Factions.args["Expansion"..expansion.Id] = {
      type = "group",
      order = calculatedOrder,
      name = expansion.Name,
      args = {},
    }
    for factionId, faction in orderedPairs(core.db.Factions) do
      if expansion.Id == faction.ExpansionId then
        calculatedOrder = calculatedOrder + 1
        options.args.Factions.args["Expansion"..expansion.Id].args["Faction"..factionId] = {
          type = "toggle",
          order = calculatedOrder,
          name = faction.Name,
          get = function(info)
            return core.db.Factions[factionId].Show
          end,
          set = function(info, value)
            core.db.Factions[factionId].Show = value
            core:UpdateTooltip()
          end,
        }
      end
    end
  end

  LibStub("AceConfig-3.0"):RegisterOptionsTable("AltReps", options, { "ar", "altreps"})
  local AceConfigDialog = LibStub("AceConfigDialog-3.0")
  core.optionsGeneralFrame = AceConfigDialog:AddToBlizOptions("AltReps", nil, nil, "General")
  core.optionsFactionsFrame = AceConfigDialog:AddToBlizOptions("AltReps", "Factions", "AltReps", "Factions")
end

function ShowToonTooltip(cell, arg, ...)
  local toonId = arg
  if not toonId then return end
  local toon = core.db.Toons[toonId]
  if not toon then return end
  openMiniTooltip(2, "LEFT","RIGHT")
  local ftex = ""
  if toon.Faction == "Alliance" then
    ftex = "\124TInterface\\TargetingFrame\\UI-PVP-Alliance:0:0:0:0:100:100:0:50:0:55\124t "
  elseif toon.Faction == "Horde" then
    ftex = "\124TInterface\\TargetingFrame\\UI-PVP-Horde:0:0:0:0:100:100:10:70:0:55\124t"
  end
  miniTooltip:SetCell(miniTooltip:AddHeader(), 1,ftex..ClassColorise(toon.Class, toonId))
  
  local totalSuppliesLine = miniTooltip:AddLine()
  miniTooltip:SetCell(totalSuppliesLine, 1, YELLOWFONT .. "Total supply chests: " .. FONTEND)
  local suppliesCount = 0
  for factionId, rep in pairs(toon.Reps) do
    if rep.HasParagonReward ~= nil and rep.ParagonValue and rep.ParagonThreshold and rep.Standing == 8 then
      local supplies = math.floor(rep.ParagonValue / rep.ParagonThreshold)
      if rep.HasParagonReward then supplies = supplies - 1 end
      suppliesCount = suppliesCount + supplies
    end
  end
  miniTooltip:SetCell(totalSuppliesLine, 2, suppliesCount)

  local totalSuppliesGoldLine = miniTooltip:AddLine()
  miniTooltip:SetCell(totalSuppliesGoldLine, 1, YELLOWFONT .. "Gold from supplies: " .. FONTEND)
  local goldTotal = toon.SuppliesCopperTotal or 0
  miniTooltip:SetCell(totalSuppliesGoldLine, 2, GetCoinTextureString(goldTotal))

  finishMiniTooltip()
end

function ShowFactionTooltip(cell, arg, ...)
  local factionId = arg.factionId
  local toonId = arg.toonId
  if not factionId then return end
  if not toonId then return end
  local toon = core.db.Toons[toonId]
  if not toon then return end
  local faction = core.db.Factions[factionId]
  if not faction then return end
  local rep = toon.Reps[factionId]
  if not rep then return end
  openMiniTooltip(2, "LEFT","RIGHT")
  local ftex = ""
  miniTooltip:SetCell(miniTooltip:AddHeader(), 1, GOLDFONT .. faction.Name .. FONTEND)
  
  local standingLine = miniTooltip:AddLine()
  miniTooltip:SetCell(standingLine, 1, YELLOWFONT .. "Standing: " .. FONTEND)
  miniTooltip:SetCell(standingLine, 2, factionStandings[rep.Standing])
  
  if rep.HasParagonReward ~= nil and rep.ParagonValue and rep.ParagonThreshold and rep.Standing == 8 then
    local standingLine = miniTooltip:AddLine()
    local supplies = math.floor(rep.ParagonValue / rep.ParagonThreshold)
    if rep.HasParagonReward then supplies = supplies - 1 end
    miniTooltip:SetCell(standingLine, 1, YELLOWFONT .. "Supplies: " .. FONTEND)
    miniTooltip:SetCell(standingLine, 2, supplies)

    if rep.HasParagonReward then
      local suppliesAvailableLine = miniTooltip:AddLine()
      local supplies = math.floor(rep.ParagonValue / rep.ParagonThreshold)
      miniTooltip:SetCell(suppliesAvailableLine, 1, YELLOWFONT .. "Supply chest available: " .. FONTEND)
      miniTooltip:SetCell(suppliesAvailableLine, 2, "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t")
    end
  end

  finishMiniTooltip()
end

function debug(...)
  if core.db.Options.Debug then
    chatMsg(...)
  end
end

function chatMsg(...)
  DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000"..addonName.."\124r: "..string.format(...))
end

function localarr(name) -- save on memory churn by reusing arrays in updates
  name = "localarr#"..name
  core[name] = core[name] or {}
  return wipe(core[name])
end

function ClassColorise(class, targetstring)
  local c = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class]
  if c.colorStr then
    c = "|c"..c.colorStr
  else
    c = ColorCodeOpen( c )
  end
  return c .. targetstring .. FONTEND
end


function ColorCodeOpenRGB(r,g,b,a)
  return format("|c%02x%02x%02x%02x", math.floor(a * 255), math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

function ColorCodeOpen(color)
  return ColorCodeOpenRGB(color[1] or color.r,
    color[2] or color.g,
    color[3] or color.b,
    color[4] or color.a or 1)
end

function openMiniTooltip(...)
  miniTooltip = LibQTip:Acquire("SavedInstancesIndicatorTooltip", ...)
  addon.miniTooltip = miniTooltip
  miniTooltip:Clear()
  miniTooltip:SetScale(1)
end

function finishMiniTooltip(parent)
  parent = parent or core.tooltip
  miniTooltip:SetAutoHideDelay(0.1, parent)
  miniTooltip.OnRelease = function() miniTooltip = nil end -- extra-safety: update our variable on auto-release
  miniTooltip:SmartAnchorTo(parent)
  miniTooltip:SetFrameLevel(150) -- ensure visibility when forced to overlap main tooltip
  core:SkinFrame(miniTooltip,"SavedInstancesIndicatorTooltip")
  miniTooltip:Show()
end

function CloseTooltips()
  if miniTooltip then
    miniTooltip:Hide()
  end
end

function __genOrderedIndex( t )
  local orderedIndex = {}
  for key in pairs(t) do
      table.insert( orderedIndex, key )
  end
  table.sort( orderedIndex )
  return orderedIndex
end

function orderedNext(t, state)
  -- Equivalent of the next function, but returns the keys in the alphabetic
  -- order. We use a temporary ordered key table that is stored in the
  -- table being iterated.

  local key = nil
  --print("orderedNext: state = "..tostring(state) )
  if state == nil then
      -- the first time, generate the index
      t.__orderedIndex = __genOrderedIndex( t )
      key = t.__orderedIndex[1]
  else
      -- fetch the next value
      for i = 1,table.getn(t.__orderedIndex) do
          if t.__orderedIndex[i] == state then
              key = t.__orderedIndex[i+1]
          end
      end
  end

  if key then
      return key, t[key]
  end

  -- no more value to return, cleanup
  t.__orderedIndex = nil
  return
end

function orderedPairs(t)
  -- Equivalent of the pairs() function on tables. Allows to iterate
  -- in order
  return orderedNext, t, nil
end