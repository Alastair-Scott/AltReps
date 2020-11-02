local addonName, addon = ...
local core = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local LibQTip = LibStub('LibQTip-1.0')
addon.LDB = LibStub("LibDataBroker-1.1", true)
addon.icon = addon.LDB and LibStub("LibDBIcon-1.0", true)
-- Lua functions
local pairs = pairs

local C_Reputation_GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo

local miniTooltip = nil
local thisServer = GetRealmName()
local thisToon = UnitName("player") .. " - " .. thisServer
local goldTextureString = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local paragonLootTextureString = "|TInterface\\Icons\\Inv_misc_bag_10:0|t"

local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local FONTEND = FONT_COLOR_CODE_CLOSE
local YELLOWFONT = LIGHTYELLOW_FONT_COLOR_CODE
local GOLDFONT = NORMAL_FONT_COLOR_CODE
local BLUEFONT = "|cff00ffdd";

local connectedRealms = {}

local showCharacterServerOptions = {
  [0] = "Show all",
  [1] = "This server only",
  [2] = "This connected realm"
}

local groupCharacterServerOptions = {
  [0] = "Do not group",
  [1] = "Server",
  [2] = "Connected realm"
}

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

local defaultDB = {
  DBVersion = 7,
  MinimapIcon = { hide = false },
  Window = {},
  Options = {
    ColourParagon = true,
    Debug = false,
    MaxCharacters = 12,
    MaxExpansions = 3,
    ReputationIcon = true,
    ShowCharactersFromServerOption = 0,
    GroupCharactersByServerOption = 0
  },
  Toons = {},
  Expansions = {
    [0] = {
      Name = "Battle for Azeroth",
      Id = 8,
      SupplyChestValue = 4000,
      Show = true
    },
    [1] = {
      Name = "Legion",
      Id = 7,
      SupplyChestValue = 750,
      Show = true
    },
    [2] = {
      Name = "Warlords of Draenor",
      Id = 6,
      Show = false
    },
    [3] = {
      Name = "Mists of Pandaria",
      Id = 5,
      Show = false
    },
    [4] = {
      Name = "Cataclysm",
      Id = 4,
      Show = false
    },
    [5] = {
      Name = "Wrath of the Lich King",
      Id = 3,
      Show = false
    },
    [6] = {
      Name = "The Burning Crusade",
      Id = 2,
      Show = false
    },
    [7] = {
      Name = "Vanilla",
      Id = 1,
      Show = false
    },
    [8] = {
      Name = "Vanilla - Steamwheedle Cartel",
      Id = 1.1,
      Show = false
    },
    [9] = {
      Name = "Vanilla - Alliance",
      Id = 1.2,
      Show = false
    },
    [10] = {
      Name = "Vanilla - Horde",
      Id = 1.3,
      Show = false
    },
    [11] = {
      Name = "Vanilla - Alliance Forces",
      Id = 1.4,
      Show = false
    },
    [12] = {
      Name = "Vanilla - Horde Forces",
      Id = 1.5,
      Show = false
    },
    [13] = {
      Name = "Other",
      Id = 0,
      Show = false
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
    },
    [1850] = {
        Name = "The Saberstalkers",
        Show = false,
        ExpansionId = 6,
        For = "Alliance;Horde"
    },
    [1849] = {
        Name = "Order of the Awakened",
        Show = false,
        ExpansionId = 6,
        For = "Alliance;Horde"
    },
    [1847] = {
        Name = "Hand of the Prophet",
        Show = false,
        ExpansionId = 6,
        For = "Alliance"
    },
    [1848] = {
        Name = "Vol'jin's Headhunters",
        Show = false,
        ExpansionId = 6,
        For = "Horde"
    },
    [1731] = {
        Name = "Council of Exarchs",
        Show = false,
        ExpansionId = 6,
        For = "Alliance"
    },
    [1445] = {
        Name = "Frostwolf Orcs",
        Show = false,
        ExpansionId = 6,
        For = "Horde"
    },
    [1515] = {
        Name = "Arakkoa Outcasts",
        Show = false,
        ExpansionId = 6,
        For = "Alliance;Horde"
    },
    [1711] = {
        Name = "Steamwheedle Preservation Society",
        Show = false,
        ExpansionId = 6,
        For = "Alliance;Horde"
    },
    [1681] = {
        Name = "Vol'jin's Spear",
        Show = false,
        ExpansionId = 6,
        For = "Horde"
    },
    [1682] = {
        Name = "Wrynn's Vanguard",
        Show = false,
        ExpansionId = 6,
        For = "Alliance"
    },
    [1302] = {
        Name = "The Anglers",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1341] = {
        Name = "The August Celestials",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1269] = {
        Name = "Golden Lotus",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1387] = {
        Name = "Kirin Tor Offensive",
        Show = false,
        ExpansionId = 5,
        For = "Alliance"
    },
    [1388] = {
        Name = "Sunreaver Onslaught",
        Show = false,
        ExpansionId = 5,
        For = "Horde"
    },
    [1337] = {
        Name = "The Klaxx",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1345] = {
        Name = "The Lorewalkers",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1376] = {
        Name = "Operation: Shieldwall",
        Show = false,
        ExpansionId = 5,
        For = "Alliance"
    },
    [1375] = {
        Name = "Dominance Offensive",
        Show = false,
        ExpansionId = 5,
        For = "Horde"
    },
    [1271] = {
        Name = "Order of the Cloud Serpent",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1492] = {
        Name = "Emperor Shaohao",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1270] = {
        Name = "Shado-Pan",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1435] = {
        Name = "Shado-Pan Assault",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1272] = {
        Name = "The Tillers",
        Show = false,
        ExpansionId = 5,
        For = "Alliance;Horde"
    },
    [1204] = {
        Name = "Avengers of Hyjal",
        Show = false,
        ExpansionId = 4,
        For = "Alliance;Horde"
    },
    [1158] = {
        Name = "Guardians of Hyjal",
        Show = false,
        ExpansionId = 4,
        For = "Alliance;Horde"
    },
    [1171] = {
        Name = "Therazane",
        Show = false,
        ExpansionId = 4,
        For = "Alliance;Horde"
    },
    [1173] = {
        Name = "Ramkahen",
        Show = false,
        ExpansionId = 4,
        For = "Alliance;Horde"
    },
    [1135] = {
        Name = "The Earthen Ring",
        Show = false,
        ExpansionId = 4,
        For = "Alliance;Horde"
    },
    [1174] = {
        Name = "Wildhammer Clan",
        Show = false,
        ExpansionId = 4,
        For = "Alliance"
    },
    [1172] = {
        Name = "Dragonmaw Clan",
        Show = false,
        ExpansionId = 4,
        For = "Horde"
    },
    [1177] = {
        Name = "Baradin's Wardens",
        Show = false,
        ExpansionId = 4,
        For = "Alliance"
    },
    [1178] = {
        Name = "Hellscream's Reach",
        Show = false,
        ExpansionId = 4,
        For = "Horde"
    },
    [1052] = {
        Name = "Horde Expedition",
        Show = false,
        ExpansionId = 3,
        For = "Horde"
    },
    [1067] = {
        Name = "The Hand of Vengeance",
        Show = false,
        ExpansionId = 3,
        For = "Horde"
    },
    [1085] = {
        Name = "Warsong Offensive",
        Show = false,
        ExpansionId = 3,
        For = "Horde"
    },
    [1064] = {
        Name = "The Taunka",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1124] = {
        Name = "The Sunreavers",
        Show = false,
        ExpansionId = 3,
        For = "Horde"
    },
    [1037] = {
        Name = "Alliance Vanguard",
        Show = false,
        ExpansionId = 3,
        For = "Alliance"
    },
    [1050] = {
        Name = "Valiance Expedition",
        Show = false,
        ExpansionId = 3,
        For = "Alliance"
    },
    [1068] = {
        Name = "Explorers' League",
        Show = false,
        ExpansionId = 3,
        For = "Alliance"
    },
    [1126] = {
        Name = "The Frostborn",
        Show = false,
        ExpansionId = 3,
        For = "Alliance"
    },
    [1094] = {
        Name = "The Silver Covenant",
        Show = false,
        ExpansionId = 3,
        For = "Alliance"
    },
    [1073] = {
        Name = "The Kalu'ak",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1104] = {
        Name = "The Frenzyheart Tribe",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1105] = {
        Name = "The Oracles",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1119] = {
        Name = "The Sons of Hodir",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1091] = {
        Name = "The Wyrmrest Accord",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1090] = {
        Name = "Kirin Tor",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1106] = {
        Name = "Argent Crusade",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1098] = {
        Name = "Knights of the Ebon Blade",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1156] = {
        Name = "The Ashen Verdict",
        Show = false,
        ExpansionId = 3,
        For = "Alliance;Horde"
    },
    [1015] = {
        Name = "Netherwing",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [942] = {
        Name = "Cenarion Expedition",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [1031] = {
        Name = "Sha'tari Skyguard",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [941] = {
        Name = "The Mag'har",
        Show = false,
        ExpansionId = 2,
        For = "Horde"
    },
    [933] = {
        Name = "The Consortium",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [934] = {
        Name = "The Scryers",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [932] = {
        Name = "The Aldor",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [989] = {
        Name = "Keepers of Time",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [935] = {
        Name = "The Sha'tar",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [1038] = {
        Name = "Ogri'la",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [970] = {
        Name = "Sporeggar",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [990] = {
        Name = "The Scale of the Sands",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [1077] = {
        Name = "Shattered Sun Offensive",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [978] = {
        Name = "Kurenai",
        Show = false,
        ExpansionId = 2,
        For = "Alliance"
    },
    [1011] = {
        Name = "Lower City",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [1012] = {
        Name = "Ashtongue Deathsworn",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [947] = {
        Name = "Thrallmar",
        Show = false,
        ExpansionId = 2,
        For = "Horde"
    },
    [967] = {
        Name = "The Violet Eye",
        Show = false,
        ExpansionId = 2,
        For = "Alliance;Horde"
    },
    [946] = {
        Name = "Honor Hold",
        Show = false,
        ExpansionId = 2,
        For = "Alliance"
    },
    [922] = {
        Name = "Tranquillien",
        Show = false,
        ExpansionId = 2,
        For = "Horde"
    },
    [349] = {
        Name = "Ravenholdt",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [87] = {
        Name = "Bloodsail Buccaneers",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [910] = {
        Name = "Brood of Nozdormu",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [529] = {
        Name = "Argent Dawn",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [749] = {
        Name = "Hydraxian Waterlords",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [609] = {
        Name = "Cenarion Circle",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [59] = {
        Name = "Thorium Brotherhood",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [576] = {
        Name = "Timbermaw Hold",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [270] = {
        Name = "Zandalar Tribe",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [909] = {
        Name = "Darkmoon Faire",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [809] = {
        Name = "Shen'dralar",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [92] = {
        Name = "Gelkis Clan Centaur",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [93] = {
        Name = "Magram Clan Centaur",
        Show = false,
        ExpansionId = 1,
        For = "Alliance;Horde"
    },
    [21] = {
        Name = "Booty Bay",
        Show = false,
        ExpansionId = 1.1,
        For = "Alliance;Horde"
    },
    [369] = {
        Name = "Gadgetzan",
        Show = false,
        ExpansionId = 1.1,
        For = "Alliance;Horde"
    },
    [470] = {
        Name = "Ratchet",
        Show = false,
        ExpansionId = 1.1,
        For = "Alliance;Horde"
    },
    [577] = {
        Name = "Everlook",
        Show = false,
        ExpansionId = 1.1,
        For = "Alliance;Horde"
    },
    [1134] = {
        Name = "Gilneas",
        Show = false,
        ExpansionId = 1.2,
        For = "Alliance"
    },
    [1353] = {
        Name = "Tushui Pandaren",
        Show = false,
        ExpansionId = 1.2,
        For = "Alliance"
    },
    [47] = {
        Name = "Ironforge",
        Show = false,
        ExpansionId = 1.2,
        For = "Alliance"
    },
    [72] = {
        Name = "Stormwind",
        Show = false,
        ExpansionId = 1.2,
        For = "Alliance"
    },
    [54] = {
        Name = "Gnomeregan",
        Show = false,
        ExpansionId = 1.2,
        For = "Alliance"
    },
    [69] = {
        Name = "Darnassus",
        Show = false,
        ExpansionId = 1.2,
        For = "Alliance"
    },
    [930] = {
        Name = "Exodar",
        Show = false,
        ExpansionId = 1.2,
        For = "Alliance"
    },
    [911] = {
        Name = "Silvermoon City",
        Show = false,
        ExpansionId = 1.3,
        For = "Horde"
    },
    [81] = {
        Name = "Thunder Bluff",
        Show = false,
        ExpansionId = 1.3,
        For = "Horde"
    },
    [1133] = {
        Name = "Bilgewater Cartel",
        Show = false,
        ExpansionId = 1.3,
        For = "Horde"
    },
    [1352] = {
        Name = "Huojin Pandaren",
        Show = false,
        ExpansionId = 1.3,
        For = "Horde"
    },
    [530] = {
        Name = "Darkspear Trolls",
        Show = false,
        ExpansionId = 1.3,
        For = "Horde"
    },
    [76] = {
        Name = "Orgrimmar",
        Show = false,
        ExpansionId = 1.3,
        For = "Horde"
    },
    [68] = {
        Name = "Undercity",
        Show = false,
        ExpansionId = 1.3,
        For = "Horde"
    },
    [1682] = {
        Name = "Wrynn's Vanguard",
        Show = false,
        ExpansionId = 1.4,
        For = "Alliance"
    },
    [890] = {
        Name = "Silverwing Sentinels",
        Show = false,
        ExpansionId = 1.4,
        For = "Alliance"
    },
    [509] = {
        Name = "The League of Arathor",
        Show = false,
        ExpansionId = 1.4,
        For = "Alliance"
    },
    [730] = {
        Name = "Stormpike Guard",
        Show = false,
        ExpansionId = 1.4,
        For = "Alliance"
    },
    [1681] = {
        Name = "Vol'jin's Spear",
        Show = false,
        ExpansionId = 1.5,
        For = "Horde"
    },
    [510] = {
        Name = "The Defilers",
        Show = false,
        ExpansionId = 1.5,
        For = "Horde"
    },
    [729] = {
        Name = "Frostwolf Clan",
        Show = false,
        ExpansionId = 1.5,
        For = "Horde"
    },
    [889] = {
        Name = "Warsong Outriders",
        Show = false,
        ExpansionId = 1.5,
        For = "Horde"
    },
    [589] = {
        Name = "Wintersaber Trainers",
        Show = false,
        ExpansionId = 0,
        For = "Alliance;Horde"
    },
    [70] = {
        Name = "Syndicate",
        Show = false,
        ExpansionId = 0,
        For = "Alliance;Horde"
    },
  }
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
    for _, toon in pairs(AltRepsDB.Toons) do
      if toon and toon.Show == nil then
        toon.Show = true
      end
    end
  elseif AltRepsDB.DBVersion < 4 then
    AltRepsDB.Options.MaxCharacters = defaultDB.Options.MaxCharacters
    AltRepsDB.DBVersion = 4
  elseif AltRepsDB.DBVersion < 5 then
    for _, toon in pairs(AltRepsDB.Toons) do
      if toon and not toon.SuppliesCopperTotal == nil then
        toon.SuppliesCopperTotal = nil
      end
    end
    AltRepsDB.Expansions = defaultDB.Expansions
    AltRepsDB.Options.FontSize = nil
    AltRepsDB.DBVersion = 5
  elseif AltRepsDB.DBVersion < 6 then
    AltRepsDB.Options.ShowCharactersFromServerOption = defaultDB.Options.ShowCharactersFromServerOption 
    AltRepsDB.Options.GroupCharactersByServerOption = defaultDB.Options.GroupCharactersByServerOption
    AltRepsDB.Options.ReputationIcon = defaultDB.Options.ReputationIcon
    for toonId, toon in pairs(AltRepsDB.Toons) do
      local toonname, toonserver = toonId:match('^(.*)[-](.*)$')
      toonserver = toonserver:gsub("%s", "")
      toon.Server = toonserver
      toon.ConnectedRealm = core:GetConnectedRealms(toonserver)
      toon.SortOrder = 25
    end
    AltRepsDB.DBVersion = 6
  elseif AltRepsDB.DBVersion < 7 then
    AltRepsDB.Expansions = defaultDB.Expansions
    AltRepsDB.Factions = defaultDB.Factions
    AltRepsDB.Options.MaxExpansions = defaultDB.Options.MaxExpansions
    AltRepsDB.DBVersion = 7
  end

  core.db = AltRepsDB
  
  core:ToonInit()
  core:BuildOptions()

  LibStub("AceConfig-3.0"):RegisterOptionsTable("AltReps", addon.Options, { "ar", "altreps"})
  local AceConfigDialog = LibStub("AceConfigDialog-3.0")
  core.optionsGeneralFrame = AceConfigDialog:AddToBlizOptions("AltReps", nil, nil, "General")
  core.optionsFactionsFrame = AceConfigDialog:AddToBlizOptions("AltReps", "Factions", "AltReps", "Factions")
  core.optionsCharactersFrame = AceConfigDialog:AddToBlizOptions("AltReps", "Characters", "AltReps", "Characters")

  core.infoTooltip = LibQTip:Acquire("AltRepsInfoTooltip", 2, "LEFT")
  core.infoTooltip:AddHeader(GOLDFONT .. 'AltReps' .. FONTEND)
  core.infoTooltip:SetCell(core.infoTooltip:AddLine(), 1, YELLOWFONT .. "Left click: " .. FONTEND .. "Display character data")
  core.infoTooltip:SetCell(core.infoTooltip:AddLine(), 1, YELLOWFONT .. "Right click: " .. FONTEND .. "Open the configuration menu")

  addon.dataobject = addon.LDB and addon.LDB:NewDataObject("AltReps", {
    text = "AR",
    type = "launcher",
    icon = "Interface\\Addons\\AltReps\\icon.tga",
    OnEnter = function(frame)
      core.infoTooltip:SmartAnchorTo(frame)
      core.infoTooltip:Show()
     end,
    OnLeave = function(frame)
      core.infoTooltip:Hide()
    end,
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

  local repFrame = _G["ReputationFrame"]
  local repIcon = CreateFrame("Button", "AltRepsReputationWindowButton", repFrame)
  repIcon:SetSize(24, 24)
  repIcon:SetPoint("TOPRIGHT", -17, -29)
  repIcon:SetNormalTexture("Interface\\Addons\\AltReps\\icon.tga")
	repIcon:SetHighlightTexture("Interface\\BUTTONS\\UI-Common-MouseHilight")
  repIcon:SetScript("OnEnter", function (self) 
    core.infoTooltip:SmartAnchorTo(self)
    core.infoTooltip:Show()
  end)
	repIcon:SetScript("OnLeave", function (self)
    core.infoTooltip:Hide()
  end)
  repIcon:SetScript("OnMouseUp", function (self, button)
    if button == "RightButton" then
      core:ShowConfig()
    else
      core:ToggleVisibility()
    end
  end)
  core.repIcon = repIcon
  core:SetReputationIconVisibility(core.db.Options.ReputationIcon)
end

function core:OnEnable()
  self:RegisterEvent("PLAYER_ENTERING_WORLD", function() core:UpdateReps() end)
  self:RegisterEvent("UPDATE_FACTION", function() core:UpdateReps() end)
  self:RegisterEvent("QUEST_TURNED_IN", function() core:UpdateReps() end)
end

function core:OnDisable()
  -- Called when the addon is disabled
end

function core:GetWindow()
  if not core.frame then
    local f = CreateFrame("Frame","AltRepsFrame", UIParent, "BasicFrameTemplate, BackdropTemplate")
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
    f:SetScript("OnKeyDown", function(self,key)
      if key == "ESCAPE" then
        f:SetPropagateKeyboardInput(false)
        f:Hide()
      end
    end)
    f:EnableMouseWheel(true);
    f:SetScript("OnMouseWheel", function(self, delta)
      local ctrlDown  = IsControlKeyDown();
      local slider
      if ctrlDown then 
        slider = core.slider_horizontal 
      else
        slider = core.slider_vertical
      end

      if slider and slider:IsShown() then
        local currentValue = slider:GetValue()
        local minValue, maxValue = slider:GetMinMaxValues()
        local stepValue = self.step or 1
      
        if delta < 0 and currentValue < maxValue then
          slider:SetValue(min(maxValue, currentValue + stepValue))
        elseif delta > 0 and currentValue > minValue then
          slider:SetValue(max(minValue, currentValue - stepValue))
        end
      end
    end)
    f:EnableKeyboard(true)
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
  tooltip:SetCellScript(header, 1, "OnEnter", ShowOverallTooltip)
  local columns = localarr("columns")
  local rows = localarr("rows")
  local hasAlliance = "xyz"
  local hasHorde = "xyz"

  local toonIndex = 0
  local toonSliderValue = core.slider_horizontal and core.slider_horizontal.CurrentValue or 1
  local expansionIndex = 0
  local expansionSliderValue = core.slider_vertical and core.slider_vertical.CurrentValue or 1
  local currentToon = core.db.Toons[thisToon]
  
  for toonId, toon in sortedPairs(core.db.Toons, characterSort, characterFilter) do
    if toon and toon.Show then
      toonIndex = toonIndex + 1
      if toonIndex < (core.db.Options.MaxCharacters + toonSliderValue) and toonIndex >= toonSliderValue then
        if toon.Faction == "Alliance" then hasAlliance = toon.Faction elseif toon.Faction == "Horde" then hasHorde = toon.Faction end;
        columns[toonId] = columns[toonId] or tooltip:AddColumn("CENTER")
        local toonname, toonserver = toonId:match('^(.*)[-](.*)$')
        tooltip:SetCell(header, columns[toonId], ClassColorise(toon.Class, toonname), "CENTER")
        tooltip:SetCellScript(header, columns[toonId], "OnEnter", ShowToonTooltip, toonId)
        tooltip:SetCellScript(header, columns[toonId], "OnLeave", CloseTooltips)
      end
    end
  end
  for _, expansion in sortedPairs(core.db.Expansions) do
    if expansion and expansion.Show then
      expansionIndex = expansionIndex + 1
      if expansionIndex < (core.db.Options.MaxExpansions + expansionSliderValue) and expansionIndex >= expansionSliderValue then
        local hasExpansionRowBeenAdded = false
        for factionId, faction in sortedPairs(core.db.Factions) do
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
    end
  end
  for factionId, row in pairs(rows) do
    local faction = core.db.Factions[factionId]
    tooltip:SetCell(row, 1, YELLOWFONT .. faction.Name .. FONTEND)
    for toonName, toon in pairs(core.db.Toons) do
      if toon and toon.Show and columns[toonName] then
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
  core:SkinFrame(tooltip,"AltRepsTooltip")
  LibQTip.layoutCleaner:CleanupLayouts()
  tooltip:ClearAllPoints()
  tooltip:SetPoint("TOPLEFT",frame, "TOPLEFT", 0, -20)
  tooltip:SetFrameLevel(frame:GetFrameLevel()+1)
  core.tooltip.OnRelease = function() core.tooltip = nil end
  -- tooltip:UpdateScrolling(300)
  tooltip:Show()

  local w,h = frame:GetSize()

  local toonCount = tablelength(core.db.Toons)
  if toonCount > core.db.Options.MaxCharacters then
    core:GetSliderHorizontal(frame, toonCount, w, h)
  elseif core.slider_horizontal and core.slider_horizontal:IsShown() then
    core.slider_horizontal:Hide()
  end

  local expansionCount = tablelength(core.db.Expansions)
  if expansionCount > core.db.Options.MaxExpansions then
    core:GetSliderVertical(frame, expansionCount, w, h)
  elseif core.slider_vertical and core.slider_vertical:IsShown() then
    core.slider_vertical:Hide()
  end

  debug("GetTooltip: End")
end

local BACKDROP_SLIDER = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	tile = true,
	tileEdge = true,
	tileSize = 8,
	edgeSize = 8,
	insets = { left = 3, right = 3, top = 6, bottom = 6 },
};

function core:GetSliderHorizontal(frame, toonCount, w, h)
  if not core.slider_horizontal then
    local scrollBarFrame = CreateFrame("Slider","AltRepsScrollBarFrameHorizontal", frame, "BackdropTemplate")
    scrollBarFrame:SetPoint("BOTTOMLEFT",frame)
    scrollBarFrame:SetFrameLevel(frame:GetFrameLevel()+2)
    scrollBarFrame:SetOrientation('HORIZONTAL')
    scrollBarFrame:SetBackdrop(BACKDROP_SLIDER)
    scrollBarFrame:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Horizontal]])
    
    scrollBarFrame:SetValueStep(1)
    scrollBarFrame:SetScript("OnValueChanged", function(self,value,arg1)
      local rounded = round(value)
      if not (core.slider_horizontal.CurrentValue == rounded) then
        core.slider_horizontal.CurrentValue = rounded
        core:UpdateTooltip()
      end
    end)
    core.slider_horizontal = scrollBarFrame
  end
  frame:SetHeight(h + 20)
  core.slider_horizontal:SetMinMaxValues(1, (toonCount + 1) - core.db.Options.MaxCharacters)
  core.slider_horizontal:SetSize(w*frame:GetScale(),20)
  if core.slider_horizontal.CurrentValue == nil then
    core.slider_horizontal:SetValue(1)
  end
  core.slider_horizontal:Show()
  return core.slider_horizontal
end

function core:GetSliderVertical(frame, expansionCount, w, h)
  if not core.slider_vertical then
    local scrollBarFrame = CreateFrame("Slider","AltRepsScrollBarFrameVertical", frame, "BackdropTemplate")
    scrollBarFrame:SetPoint("TOPRIGHT",frame, "TOPRIGHT", -3, -20)
    scrollBarFrame:SetFrameLevel(frame:GetFrameLevel()+2)
    scrollBarFrame:SetOrientation('VERTICAL')
    scrollBarFrame:SetBackdrop(BACKDROP_SLIDER)
    scrollBarFrame:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Vertical]])
    
    scrollBarFrame:SetValueStep(1)
    scrollBarFrame:SetScript("OnValueChanged", function(self,value,arg1)
      local rounded = round(value)
      if not (core.slider_vertical.CurrentValue == rounded) then
        core.slider_vertical.CurrentValue = rounded
        core:UpdateTooltip()
      end
    end)
    core.slider_vertical = scrollBarFrame
  end
  frame:SetWidth(w + 20)
  core.slider_vertical:SetMinMaxValues(1, (expansionCount + 1) - core.db.Options.MaxExpansions)
  core.slider_vertical:SetSize(14,(h - 20)*frame:GetScale())
  if core.slider_vertical.CurrentValue == nil then
    core.slider_vertical:SetValue(1)
  end
  core.slider_vertical:Show()
  return core.slider_vertical
end

function core:UpdateTooltip()
  debug("UpdateTooltip: Start")
  if core.frame and core.frame:IsShown() then
    core:GetTooltip(core.frame)
  end
  debug("UpdateTooltip: End")
end

function core:ToonInit()
  local ti = core.db.Toons[thisToon] or { Show = true, SortOrder = 25 }
  core.db.Toons[thisToon] = ti
  ti.LClass, ti.Class = UnitClass("player")
  ti.Faction, ti.LFaction = UnitFactionGroup("player")
  ti.Server = thisServer
  ti.ConnectedRealm = core:GetConnectedRealms(thisServer)
end

function core:UpdateReps()
  debug("UpdateReps: Start")
  local toon = core.db.Toons[thisToon]
  for factionId, _ in pairs(core.db.Factions) do
    local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfoByID(factionId)
    local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionId)
    if not toon.Reps then toon.Reps = {} end
    if not (atWarWith and not canToggleAtWar) and name then
      local current, max = 0, 0
      if standingID == 8 then 
        current = 21000
        max = 21000
      else
        current = barValue - barMin
        max = barMax - barMin
      end
      toon.Reps[factionId] = {
        Current = current,
        Max = max,
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
    core.frame:SetPropagateKeyboardInput(true)
  end
end

function core:ShowConfig()
  if _G.InterfaceOptionsFrame:IsShown() then
    _G.InterfaceOptionsFrame:Hide()
  else
    InterfaceOptionsFrame_OpenToCategory(core.optionsFactionsFrame)
    InterfaceOptionsFrame_OpenToCategory(core.optionsCharactersFrame)
    InterfaceOptionsFrame_OpenToCategory(core.optionsGeneralFrame)
  end
end

function core:ReopenConfigDisplay(frame)
  if _G.InterfaceOptionsFrame:IsShown() then
    _G.InterfaceOptionsFrame:Hide()
    InterfaceOptionsFrame_OpenToCategory(core.optionsFactionsFrame)
    InterfaceOptionsFrame_OpenToCategory(core.optionsCharactersFrame)
    InterfaceOptionsFrame_OpenToCategory(frame)
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
          ReputationIcon = {
            type = "toggle",
            name = "Show reputation tab button",
            desc = "Show the AltReps button on the reputation tab",
            order = 4,
            get = function(info) return core.db.Options.ReputationIcon end,
            set = function(info, value)
              core.db.Options.ReputationIcon = value
              core:SetReputationIconVisibility(value)
            end,
          },
          GeneralHeader = {
            order = 20,
            type = "header",
            name = "Advanced settings",
          },
          Debug = {
            type = "toggle",
            name = "Debug",
            desc = "Enable debug mode",
            order = 21,
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
          GeneralSettings = {
            type = "header",
            order = 1,
            name = "General settings"
          },
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
          MaxExpansions = {
            type = "range",
            min = 1,
            max = 4,
            step = 1,
            order = 10,
            name = "Max Expansions",
            desc = "How many expansions should be shown at once before scrolling is enabled",
            get = function(info) return core.db.Options.MaxExpansions end,
            set = function(info, value)
              core.db.Options.MaxExpansions = value
              if core.slider_vertical then
                core.slider_vertical:SetValue(1)
              end
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
      Characters = {
        order = 2,
        type = "group",
        name = "Character settings",
        cmdHidden = true,
        args = {
          GeneralSettings = {
            type = "header",
            order = 10,
            name = "General settings"
          },
          MaxCharacters = {
            type = "range",
            min = 2,
            max = 20,
            step = 1,
            order = 10,
            name = "Max Characters",
            desc = "How many characters should be shown at once before scrolling is enabled",
            get = function(info) return core.db.Options.MaxCharacters end,
            set = function(info, value)
              core.db.Options.MaxCharacters = value
              if core.slider_horizontal then
                core.slider_horizontal:SetValue(1)
              end
              core:UpdateTooltip()
            end,
          },
          ShowCharactersFromServers = {
            type = "select",
            values = showCharacterServerOptions,
            order = 20,
            name = "Characters to show",
            desc = "Should we show characters based on their server",
            get = function(info) return core.db.Options.ShowCharactersFromServerOption end,
            set = function(info, value)
              core.db.Options.ShowCharactersFromServerOption = value
              core:UpdateTooltip()
            end,
          },
          GroupCharactersByServers = {
            type = "select",
            values = groupCharacterServerOptions,
            order = 30,
            name = "Character grouping",
            desc = "Should we group characters based on their server",
            get = function(info) return core.db.Options.GroupCharactersByServerOption end,
            set = function(info, value)
              core.db.Options.GroupCharactersByServerOption = value
              core:UpdateTooltip()
            end,
          },
          CharactersHeader = {
            type = "header",
            order = 100,
            name = "Characters"
          },
        },
      },
    },
  }
  local calculatedOrder = options.args.Factions.args.FactionsHeader.order + 100
  for _ , expansion in sortedPairs(core.db.Expansions) do
    calculatedOrder = calculatedOrder + 1
    options.args.Factions.args["Expansion"..expansion.Id] = {
      type = "group",
      order = calculatedOrder,
      name = expansion.Name,
      args = {
        GeneralSettings = {
          type = "header",
          order = 10,
          name = "General settings"
        },
        ShowExpansion = {
          type = "toggle",
          order = 20,
          name = "Show",
          desc = "Should we show reputations from this expansion?",
          get = function(info)
            return expansion.Show
          end,
          set = function(info, value)
            expansion.Show = value
            for factionId, faction in sortedPairs(core.db.Factions) do
              if expansion.Id == faction.ExpansionId then
                faction.Show = value
              end
            end
            core:UpdateTooltip()
          end,
        },
        ReputationsSettings = {
          type = "header",
          order = 30,
          name = "Reputations"
        },
      },
    }
    for factionId, faction in sortedPairs(core.db.Factions) do
      if expansion.Id == faction.ExpansionId then
        calculatedOrder = calculatedOrder + 1
        options.args.Factions.args["Expansion"..expansion.Id].args["Faction"..factionId] = {
          type = "toggle",
          order = calculatedOrder,
          name = faction.Name,
          get = function(info)
            return faction.Show
          end,
          set = function(info, value)
            faction.Show = value
            local showExpansion = false
            for factionId, faction in sortedPairs(core.db.Factions) do
              if expansion.Id == faction.ExpansionId then
                showExpansion = faction.Show
                if showExpansion then break end
              end
            end
            expansion.Show = showExpansion
            core:UpdateTooltip()
          end,
        }
      end
    end
  end

  local calculatedCharactersOrder = options.args.Characters.args.CharactersHeader.order
  for characterName, character in sortedPairs(core.db.Toons) do
    calculatedCharactersOrder = calculatedCharactersOrder + 1
    local formattedName = ClassColorise(character.Class, characterName)
    options.args.Characters.args[formattedName] = {
      type = "group",
      order = calculatedCharactersOrder,
      name = formattedName,
      args = {
        GeneralHeader = {
          order = 2,
          type = "header",
          name = "General settings",
        },
        Show = {
          type = "toggle",
          order = 10,
          name = "Show",
          get = function(info)
            return character.Show 
          end,
          set = function(info, value)
            character.Show = value
            core:UpdateTooltip()
          end,
        },
        SortOrder = {
          type = "range",
          min = 1,
          max = 50,
          step = 1,
          order = 20,
          name = "Sort order",
          desc = "What is the priority of displaying this character? (1 - Highest priority, 50 - Lowest priority)",
          get = function(info)
            return character.SortOrder 
          end,
          set = function(info, value)
            character.SortOrder = value
            core:UpdateTooltip()
          end,
        },
        AdvancedHeader = {
          order = 100,
          type = "header",
          name = "Advanced settings",
        },
        Forget = {
          order = 110,
          type = "execute",
          name = "Forget",
          desc = "Forget " .. characterName,
          hidden = function() return characterName == thisToon end,
          confirm = function(info)
            return "Are you sure you wish to forget " .. characterName .. "?"
          end,
          func = function(info)
            if character then
              core.db.Toons[characterName] = nil
              core:BuildOptions()
              core:UpdateTooltip()
              core:ReopenConfigDisplay(core.optionsCharactersFrame)
            end
          end,
        },
      },
    }   
  end
  addon.Options = addon.Options or {}
  for k, v in pairs(options) do
    addon.Options[k] = v
  end
end

function core:GetConnectedRealms(server)
  if server and not connectedRealms[server] then
    local servers = GetAutoCompleteRealms(server)
    for _, v in sortedPairs(servers) do
      connectedRealms[v] = table.concat(servers, ';')
    end
  end
  return connectedRealms[server]
end

function core:SetReputationIconVisibility(visibilityState)
  if core.repIcon then
    if visibilityState then
      core.repIcon:Show()
    else
      core.repIcon:Hide()
    end
  end
end

function ShowToonTooltip(cell, arg, ...)
  local toonId = arg
  if not toonId then return end
  local toon = core.db.Toons[toonId]
  if not toon then return end
  openMiniTooltip(3, "LEFT", "RIGHT", "RIGHT")
  local ftex = ""
  if toon.Faction == "Alliance" then
    ftex = "\124TInterface\\TargetingFrame\\UI-PVP-Alliance:0:0:0:0:100:100:0:50:0:55\124t "
  elseif toon.Faction == "Horde" then
    ftex = "\124TInterface\\TargetingFrame\\UI-PVP-Horde:0:0:0:0:100:100:10:70:0:55\124t"
  end
  miniTooltip:SetCell(miniTooltip:AddHeader(), 1, ClassColorise(toon.Class, toonId) .. ftex)

  miniTooltip:AddSeparator(6,0,0,0,0)

  local rowNumber = miniTooltip:AddLine()
  miniTooltip:SetCell(rowNumber, 1, GOLDFONT .. "Supply chests" .. FONTEND)
  miniTooltip:SetCell(rowNumber, 2, YELLOWFONT .. "Opened" .. FONTEND)
  miniTooltip:SetCell(rowNumber, 3, YELLOWFONT .. "Gold earned (Approx.)" .. FONTEND)

  local totalSupplies, totalGold = 0, 0
  for expansionIndex, expansion in sortedPairs(core.db.Expansions) do
    if expansion and expansion.SupplyChestValue then
      local expansionSupplies, expansionGold = 0, 0
      for factionId, faction in sortedPairs(core.db.Factions) do
        if expansion.Id == faction.ExpansionId then
          local rep = toon.Reps[factionId]
          if rep and rep.HasParagonReward ~= nil and rep.ParagonValue and rep.ParagonThreshold and rep.Standing == 8 then
            local supplies = math.floor(rep.ParagonValue / rep.ParagonThreshold)
            if rep.HasParagonReward then supplies = supplies - 1 end
            expansionSupplies = expansionSupplies + supplies
            totalSupplies = totalSupplies + supplies
            expansionGold = expansionGold + supplies * expansion.SupplyChestValue
            totalGold = totalGold + supplies * expansion.SupplyChestValue
          end
        end
      end

      rowNumber = miniTooltip:AddLine()
      miniTooltip:SetCell(rowNumber, 1, YELLOWFONT .. expansion.Name .. FONTEND)
      miniTooltip:SetCell(rowNumber, 2, expansionSupplies)
      miniTooltip:SetCell(rowNumber, 3, comma_value(expansionGold) .. " " .. goldTextureString)
    end
  end
  
  rowNumber = miniTooltip:AddLine()
  miniTooltip:SetCell(rowNumber, 1, YELLOWFONT .. "Total" .. FONTEND)
  miniTooltip:SetCell(rowNumber, 2, totalSupplies)
  miniTooltip:SetCell(rowNumber, 3, comma_value(totalGold) .. " " .. goldTextureString)

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
    local suppliesLine = miniTooltip:AddLine()
    local goldLine = miniTooltip:AddLine()
    
    local supplyChestValue = 0
    for _, expansion in pairs(core.db.Expansions) do 
      if expansion.Id == faction.ExpansionId then
        supplyChestValue = expansion.SupplyChestValue
      end
    end

    local supplies = math.floor(rep.ParagonValue / rep.ParagonThreshold)
    if rep.HasParagonReward then supplies = supplies - 1 end
    miniTooltip:SetCell(suppliesLine, 1, YELLOWFONT .. "Supplies: " .. FONTEND)
    miniTooltip:SetCell(suppliesLine, 2, supplies)
    
    miniTooltip:SetCell(goldLine, 1, YELLOWFONT .. "Gold (Approx.): " .. FONTEND)
    miniTooltip:SetCell(goldLine, 2, comma_value(supplies * supplyChestValue) .. " " .. goldTextureString)

    if rep.HasParagonReward then
      local suppliesAvailableLine = miniTooltip:AddLine()
      local supplies = math.floor(rep.ParagonValue / rep.ParagonThreshold)
      miniTooltip:SetCell(suppliesAvailableLine, 1, YELLOWFONT .. "Supply chest available: " .. FONTEND)
      miniTooltip:SetCell(suppliesAvailableLine, 2, "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t")
    end
  end

  finishMiniTooltip()
end

function ShowOverallTooltip(cell, arg, ...)
  openMiniTooltip(3, "LEFT", "RIGHT", "RIGHT")
  miniTooltip:SetCell(miniTooltip:AddHeader(), 1, GOLDFONT .. "AltReps: " .. FONTEND .. YELLOWFONT .. addon.version .. FONTEND)

  miniTooltip:AddSeparator(6,0,0,0,0)

  local rowNumber = miniTooltip:AddLine()
  miniTooltip:SetCell(rowNumber, 1, GOLDFONT .. "Supply chests" .. FONTEND)
  miniTooltip:SetCell(rowNumber, 2, YELLOWFONT .. "Opened" .. FONTEND)
  miniTooltip:SetCell(rowNumber, 3, YELLOWFONT .. "Gold earned (Approx.)" .. FONTEND)

  local totalSupplies, totalGold = 0, 0
  for expansionIndex, expansion in sortedPairs(core.db.Expansions) do
    if expansion and expansion.SupplyChestValue then
      local expansionSupplies, expansionGold = 0, 0
      for factionId, faction in sortedPairs(core.db.Factions) do
        if expansion.Id == faction.ExpansionId then
          for toonId, toon in sortedPairs(core.db.Toons) do
            local rep = toon.Reps[factionId]
            if rep and rep.HasParagonReward ~= nil and rep.ParagonValue and rep.ParagonThreshold and rep.Standing == 8 then
              local supplies = math.floor(rep.ParagonValue / rep.ParagonThreshold)
              if rep.HasParagonReward then supplies = supplies - 1 end
              expansionSupplies = expansionSupplies + supplies
              totalSupplies = totalSupplies + supplies
              expansionGold = expansionGold + supplies * expansion.SupplyChestValue
              totalGold = totalGold + supplies * expansion.SupplyChestValue
            end
          end
        end
      end

      rowNumber = miniTooltip:AddLine()
      miniTooltip:SetCell(rowNumber, 1, YELLOWFONT .. expansion.Name .. FONTEND)
      miniTooltip:SetCell(rowNumber, 2, expansionSupplies)
      miniTooltip:SetCell(rowNumber, 3, comma_value(expansionGold) .. " " .. goldTextureString)
    end
  end
  
  rowNumber = miniTooltip:AddLine()
  miniTooltip:SetCell(rowNumber, 1, YELLOWFONT .. "Total" .. FONTEND)
  miniTooltip:SetCell(rowNumber, 2, totalSupplies)
  miniTooltip:SetCell(rowNumber, 3, comma_value(totalGold) .. " " .. goldTextureString)

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

function tablelength(T)
  local count = 0
  for _, v in pairs(T) do if v.Show then count = count + 1 end end
  return count
end

function comma_value(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function round(x)
  return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function sortedPairs(t, sortFunction, filterFunction)
  local a = {}
  for n in pairs(t) do 
    if filterFunction == nil or filterFunction(n) then
      table.insert(a, n)
    end
  end
  table.sort(a, sortFunction)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function characterSort(characterKey1, characterKey2)  
  local toon1 = core.db.Toons[characterKey1]
  local toon2 = core.db.Toons[characterKey2]

  if characterKey1 == thisToon then
    return true
  end
  if characterKey2 == thisToon then
    return false
  end

  if core.db.Options.GroupCharactersByServerOption == 1 then
    if toon1.Server ~= toon2.Server then
      if toon1.Server == thisServer then
        return true
      end
      if toon2.Server == thisServer then
        return false
      end
      return toon1.Server < toon2.Server
    end
  end
  
  if core.db.Options.GroupCharactersByServerOption == 2 then
    local thisConnectedRealm = core:GetConnectedRealms(thisServer)
    if toon1.ConnectedRealm ~= toon2.ConnectedRealm then
      if toon1.ConnectedRealm == thisConnectedRealm then
        return true
      end
      if toon2.ConnectedRealm == thisConnectedRealm  then
        return false
      end
      return toon1.ConnectedRealm < toon2.ConnectedRealm
    end
  end

  if toon1.SortOrder ~= toon2.SortOrder then
    return toon1.SortOrder < toon2.SortOrder
  end

  return characterKey1 < characterKey2
end

function characterFilter(characterKey)
  local toon = core.db.Toons[characterKey]
  if core.db.Options.ShowCharactersFromServerOption == 1 then
    if toon.Server ~= thisServer then return false end
  end

  if core.db.Options.ShowCharactersFromServerOption == 2 then
    local thisConnectedRealm = core:GetConnectedRealms(thisServer)
    if toon.ConnectedRealm ~= thisConnectedRealm then return false end
  end

  return true
end