local addonName, addon = ...
local core = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local LibQTip = LibStub('LibQTip-1.0')
addon.LDB = LibStub("LibDataBroker-1.1", true)
addon.icon = addon.LDB and LibStub("LibDBIcon-1.0", true)
-- Lua functions
local pairs = pairs
local next = next

local C_Reputation_GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo
local C_GossipInfo_GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local C_MajorFactions_GetMajorFactionData = C_MajorFactions.GetMajorFactionData
local C_MajorFactions_HasMaximumRenown = C_MajorFactions.HasMaximumRenown
local C_MajorFactions_GetRenownRewardsForLevel = C_MajorFactions.GetRenownRewardsForLevel
local C_MajorFactions_GetRenownLevels = C_MajorFactions.GetRenownLevels

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

local factionIdForOrdering = nil

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
  [9] = "Paragon"
}

local standingColours = {
  Red = {
    ["r"] = 0.53333333333333333333333333333333,
    ["g"] = 0.2039215686274509803921568627451,
    ["b"] = 0.14509803921568627450980392156863
  },
  Yellow = {
    ["r"] = 0.58823529411764705882352941176471,
    ["g"] = 0.45882352941176470588235294117647,
    ["b"] = 0
  },
  Green = {
    ["r"] = 0,
    ["g"] = 0.3921568627450980392156862745098,
    ["b"] = 0.06666666666666666666666666666667
  },
  Blue = {
    ["r"] = 0,
    ["g"] = 0.5,
    ["b"] = 0.9
  }
}

local defaultDB = {
  DBVersion = 14,
  MinimapIcon = { hide = false },
  Window = {},
  Options = {
    ColourReputations = true,
    MaxCharacters = 8,
    MaxExpansions = 3,
    ShowCharactersFromServerOption = 0,
    GroupCharactersByServerOption = 0,
    StandingColours = {      
			[0] = {
				["b"] = 1,
				["g"] = 1,
				["r"] = 1,
			},
      [1] = {
        ["b"] = 0.07058823529411765,
				["g"] = 0.1019607843137255,
				["r"] = 1,
			},
			[2] = {
				["b"] = 0.1764705882352941,
				["g"] = 0.3450980392156863,
				["r"] = 1,
			},
			[3] = {
				["b"] = 0.592156862745098,
				["g"] = 0.8,
				["r"] = 1,
			},
			[4] = {
				["b"] = 0.392156862745098,
				["g"] = 1,
				["r"] = 0.9803921568627451,
			},
			[5] = {
				["b"] = 0.6431372549019607,
				["g"] = 1,
				["r"] = 0.6549019607843137,
			},
			[6] = {
				["b"] = 0.3372549019607843,
				["g"] = 0.6941176470588235,
				["r"] = 0.203921568627451,
			},
			[7] = {
				["b"] = 0,
				["g"] = 0.5058823529411764,
				["r"] = 0.04313725490196078,
			},
			[8] = {
				["b"] = 0.00392156862745098,
				["g"] = 1,
				["r"] = 0,
			},
			[9] = {
				["b"] = 1,
				["g"] = 0.8666666666666667,
				["r"] = 0.05490196078431373,
			},
    }
  },
  Toons = {},
  Expansions = {
    [0] = {
      Name = "Dragonflight",
      Id = 10,
      SupplyChestValue = 3500,
      Show = true
    },
    [1] = {
      Name = "Shadowlands",
      Id = 9,
      SupplyChestValue = 3500,
      Show = true
    },
    [2] = {
      Name = "Battle for Azeroth",
      Id = 8,
      SupplyChestValue = 4000,
      Show = false
    },
    [3] = {
      Name = "Legion",
      Id = 7,
      SupplyChestValue = 750,
      Show = true
    },
    [4] = {
      Name = "Warlords of Draenor",
      Id = 6,
      Show = false
    },
    [5] = {
      Name = "Mists of Pandaria",
      Id = 5,
      Show = false
    },
    [6] = {
      Name = "Cataclysm",
      Id = 4,
      Show = false
    },
    [7] = {
      Name = "Wrath of the Lich King",
      Id = 3,
      Show = false
    },
    [8] = {
      Name = "The Burning Crusade",
      Id = 2,
      Show = false
    },
    [9] = {
      Name = "Vanilla",
      Id = 1,
      Show = false
    },
    [10] = {
      Name = "Vanilla - Steamwheedle Cartel",
      Id = 1.1,
      Show = false
    },
    [11] = {
      Name = "Vanilla - Alliance",
      Id = 1.2,
      Show = false
    },
    [12] = {
      Name = "Vanilla - Horde",
      Id = 1.3,
      Show = false
    },
    [13] = {
      Name = "Vanilla - Alliance Forces",
      Id = 1.4,
      Show = false
    },
    [14] = {
      Name = "Vanilla - Horde Forces",
      Id = 1.5,
      Show = false
    },
    [15] = {
      Name = "Other",
      Id = 0,
      Show = false
    }
  },
  Factions = {
    [2574] = {
      Name = "Dream Wardens",
      Show = true,
      ExpansionId = 10,
      For = "Alliance;Horde"
    },
    [2564] = {
      Name = "Loamm Niffen",
        Show = true,
        ExpansionId = 10,
        For = "Alliance;Horde"
    },
    [2526] = {
      Name = "Winterpelt Furbolg",
        Show = true,
        ExpansionId = 10,
        For = "Alliance;Horde"
    },
    [2503] = {
      Name = "Maruuk Centaur",
        Show = true,
        ExpansionId = 10,
        For = "Alliance;Horde"
    },
    [2507] = {
      Name = "Dragonscale Expedition",
        Show = true,
        ExpansionId = 10,
        For = "Alliance;Horde"
    },
    [2510] = {
      Name = "Valdrakken Accord",
        Show = true,
        ExpansionId = 10,
        For = "Alliance;Horde"
    },
    [2511] = {
      Name = "Iskaara Tuskarr",
        Show = true,
        ExpansionId = 10,
        For = "Alliance;Horde"
    },
    [2478] = {
      Name = "The Enlightened",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
    [2470] = {
      Name = "Death's Advance",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
    [2472] = {
      Name = "The Archivists' Codex",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
    [2464] = {
      Name = "Court of Night",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
    [2432] = {
      Name = "Ve'nari",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
    [2439] = {
      Name = "The Avowed",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
    [2413] = {
      Name = "Court of Harvesters",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
    [2407] = {
      Name = "The Ascended",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
    [2410] = {
      Name = "The Undying Army",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
    [2465] = {
      Name = "The Wild Hunt",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    },
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
  end
  if AltRepsDB.DBVersion < 3 then
    AltRepsDB.Window = defaultDB.Window
    AltRepsDB.Options = defaultDB.Options
    AltRepsDB.Factions = defaultDB.Factions
    for _, toon in pairs(AltRepsDB.Toons) do
      if toon and toon.Show == nil then
        toon.Show = true
      end
    end
  end
  if AltRepsDB.DBVersion < 4 then
    AltRepsDB.Options.MaxCharacters = defaultDB.Options.MaxCharacters
    AltRepsDB.DBVersion = 4
  end
  if AltRepsDB.DBVersion < 5 then
    for _, toon in pairs(AltRepsDB.Toons) do
      if toon and not toon.SuppliesCopperTotal == nil then
        toon.SuppliesCopperTotal = nil
      end
    end
    AltRepsDB.Expansions = defaultDB.Expansions
    AltRepsDB.Options.FontSize = nil
    AltRepsDB.DBVersion = 5
  end
  if AltRepsDB.DBVersion < 6 then
    AltRepsDB.Options.ShowCharactersFromServerOption = defaultDB.Options.ShowCharactersFromServerOption 
    AltRepsDB.Options.GroupCharactersByServerOption = defaultDB.Options.GroupCharactersByServerOption
    for toonId, toon in pairs(AltRepsDB.Toons) do
      local toonname, toonserver = toonId:match('^(.*)[-](.*)$')
      toonserver = toonserver:gsub("%s", "")
      toon.Server = toonserver
      toon.ConnectedRealm = core:GetConnectedRealms(toonserver)
      toon.SortOrder = 25
    end
    AltRepsDB.DBVersion = 6
  end
  if AltRepsDB.DBVersion < 7 then
    AltRepsDB.Expansions = defaultDB.Expansions
    AltRepsDB.Factions = defaultDB.Factions
    AltRepsDB.Options.MaxExpansions = defaultDB.Options.MaxExpansions
    AltRepsDB.DBVersion = 7
  end
  if AltRepsDB.DBVersion < 8 then
    AltRepsDB.Expansions = defaultDB.Expansions
    AltRepsDB.Factions = defaultDB.Factions
    AltRepsDB.Options.Debug = nil
    AltRepsDB.Options.ColourParagon = nil
    AltRepsDB.Options.ColourReputations = defaultDB.Options.ColourReputations
    AltRepsDB.Options.StandingColours = defaultDB.Options.StandingColours
  end
  if AltRepsDB.DBVersion < 9 then
    AltRepsDB.Expansions = defaultDB.Expansions
  end
  if AltRepsDB.DBVersion < 10 then
    AltRepsDB.Factions[2432] = {
      Name = "Ve'nari",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    }
  end
  if AltRepsDB.DBVersion < 11 then
    AltRepsDB.Factions[2470] = {
      Name = "Death's Advance",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    }
    AltRepsDB.Factions[2472] = {
      Name = "The Archivists' Codex",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    }
    AltRepsDB.Factions[2464] = {
      Name = "Court of Night",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    }
    AltRepsDB.ReputationIcon = nil
    if AltRepsDB.Options.MaxExpansions > 3 then
      AltRepsDB.Options.MaxExpansions = 3
    end
    AltRepsDB.DBVersion = 11  
  end
  if AltRepsDB.DBVersion < 12 then
    AltRepsDB.Factions[2478] = {
      Name = "The Enlightened",
        Show = true,
        ExpansionId = 9,
        For = "Alliance;Horde"
    }
    core:ResetFactionColours(AltRepsDB)
    AltRepsDB.DBVersion = 12
  end
  if AltRepsDB.DBVersion <= 13 then
    AltRepsDB.Expansions = defaultDB.Expansions
    AltRepsDB.Factions = defaultDB.Factions
    AltRepsDB.Options.MaxCharacters = defaultDB.Options.MaxCharacters
    AltRepsDB.DBVersion = 13
  end
  if AltRepsDB.DBVersion < 14 then
    AltRepsDB.Factions[2564] = {
      Name = "Loamm Niffen",
      Show = true,
      ExpansionId = 10,
      For = "Alliance;Horde"
    }
    AltRepsDB.Factions[2526] = {
      Name = "Winterpelt Furbolg",
        Show = true,
        ExpansionId = 10,
        For = "Alliance;Horde"
    }
    AltRepsDB.DBVersion = 14
  end
  if AltRepsDB.DBVersion < 15 then
    AltRepsDB.Factions[2574] = {
      Name = "Dream Wardens",
      Show = true,
      ExpansionId = 10,
      For = "Alliance;Horde"
    }
    AltRepsDB.DBVersion = 15
  end

  core.db = AltRepsDB
  
  core:ToonInit()
  core:BuildOptions()

  LibStub("AceConfig-3.0"):RegisterOptionsTable("AltReps", addon.Options, { "ar", "altreps"})
  local AceConfigDialog = LibStub("AceConfigDialog-3.0")
  core.optionsGeneralFrame = AceConfigDialog:AddToBlizOptions("AltReps", nil, nil, "General")
  core.optionsFactionsFrame = AceConfigDialog:AddToBlizOptions("AltReps", "Factions", "AltReps", "Factions")
  core.optionsCharactersFrame = AceConfigDialog:AddToBlizOptions("AltReps", "Characters", "AltReps", "Characters")

  addon.dataobject = addon.LDB and addon.LDB:NewDataObject("AltReps", {
    text = "AR",
    type = "launcher",
    icon = "Interface\\Addons\\AltReps\\icon.tga",
    OnTooltipShow = function(tooltip)
      tooltip:AddLine(GOLDFONT .. 'AltReps' .. FONTEND)
      tooltip:AddLine(YELLOWFONT .. "Left click: " .. FONTEND .. "Display character data")
      tooltip:AddLine(YELLOWFONT .. "Right click: " .. FONTEND .. "Open the configuration menu")
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
end

function core:OnEnable()
  self:RegisterEvent("PLAYER_ENTERING_WORLD", function() core:UpdateReps() end)
  self:RegisterEvent("UPDATE_FACTION", function() core:UpdateReps() end)
  self:RegisterEvent("QUEST_TURNED_IN", function() core:UpdateReps() end)
  self:RegisterEvent("MAJOR_FACTION_UNLOCKED", function() core:UpdateReps() end)
  self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", function() core:UpdateReps() end)
  self:RegisterEvent("MAJOR_FACTION_RENOWN_CATCH_UP_STATE_UPDATE", function() core:UpdateReps() end)
end

function core:OnDisable()
  -- Called when the addon is disabled
end

function core:GetWindow()
  if not core.frame then
    local f = CreateFrame("Frame","AltRepsFrame", UIParent, "BackdropTemplate")
    local titleFrame = CreateFrame("Frame","AltRepsTitleFrame", f, "BackdropTemplate")
    titleFrame:SetPoint("TOPLEFT", f ,"TOPLEFT", 0, 0)
    titleFrame:SetPoint("BOTTOMRIGHT", f ,"TOPRIGHT", 0, -20)
    titleFrame:EnableMouse(false)
    local titleTexture = titleFrame:CreateTexture(nil, "BACKGROUND")
    titleTexture:SetAllPoints()
    titleTexture:SetColorTexture(0, 0, 0, 0.9)

    local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("CENTER", 0, 0)
    title:SetText(GOLDFONT .. "AltReps: " .. FONTEND .. YELLOWFONT .. addon.version .. FONTEND)

    local frameTexture = f:CreateTexture(nil, "BACKGROUND")
    frameTexture:SetAllPoints()
    frameTexture:SetColorTexture(0, 0, 0, 0.8)

    local closeButton = CreateFrame ("button", "$parentCloseButton", titleFrame, "BackdropTemplate")
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("TOPRIGHT", titleFrame, "TOPRIGHT", -2, -2)
    closeButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
    closeButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
    closeButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
    closeButton:GetNormalTexture():SetDesaturated(true)
    closeButton:GetHighlightTexture():SetDesaturated(true)
    closeButton:GetPushedTexture():SetDesaturated(true)  
    closeButton:SetAlpha (0.7)
    closeButton:SetScript("OnClick", function() 
      f:Hide() 
    end)
    titleFrame.CloseButton = closeButton

    local configButton =  CreateFrame ("Button", "$parentConfigButton", titleFrame, "BackdropTemplate")
		configButton:SetPoint ("RIGHT", titleFrame.CloseButton, "LEFT", -2, 0)
		configButton:SetSize (16, 16)
		configButton:SetNormalTexture ([[Interface\GossipFrame\BinderGossipIcon]])
		configButton:SetHighlightTexture ([[Interface\GossipFrame\BinderGossipIcon]])
		configButton:SetPushedTexture ([[Interface\GossipFrame\BinderGossipIcon]])
		configButton:GetNormalTexture():SetDesaturated (true)
		configButton:GetHighlightTexture():SetDesaturated (true)
		configButton:GetPushedTexture():SetDesaturated (true)
		configButton:SetAlpha (0.7)
    configButton:SetScript("OnClick", function() 
      f:Hide()
      core:ShowConfig()
    end)
		titleFrame.Config = configButton

    f:SetMovable(true)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetUserPlaced(true)
    f:SetAlpha(1)
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
local displayTable = {
  
}
function core:GetTooltip(frame)
  local hasAlliance = "xyz"
  local hasHorde = "xyz"
  local toonIndex = 0
  local toonSliderValue = core.slider_horizontal and core.slider_horizontal.CurrentValue or 1
  local expansionIndex = 0
  local expansionSliderValue = core.slider_vertical and core.slider_vertical.CurrentValue or 1
  local currentToon = core.db.Toons[thisToon]
  local toonColumnWidth = 120
  local factionColumnWidth = 240
  local rowHeight = 24
  local columnIndex = 0
  local rowIndex = 0

  local sort = nil
  if factionIdForOrdering ~= nil then 
    sort = factionSort
  else
    sort = characterSort
  end

  for _, row in pairs(displayTable) do
    if row.RowFrame then
      row.RowFrame:Hide()
      if row.ChildFrames then
        for _, childFrame in pairs(row.ChildFrames) do
          if childFrame ~= nil and childFrame.Frame ~= nil then
            childFrame.Frame:Hide()
          end
        end
      end
    end
  end

  for toonId, toon in sortedPairs(core.db.Toons, sort, characterFilter) do
    if toon and toon.Show then
      toonIndex = toonIndex + 1
      if not displayTable[0] then
        local toonHeaderFrame = CreateFrame("Frame","AltRepsToonHeaderFrame", frame, "BackdropTemplate")
        toonHeaderFrame:SetPoint("TOPLEFT", frame ,"TOPLEFT", 0, -20)
        toonHeaderFrame:SetPoint("BOTTOMRIGHT", frame ,"TOPRIGHT", 0, -20 - rowHeight)
        local l = toonHeaderFrame:CreateLine()
        l:SetColorTexture(0, 0, 0 , 0.6)
        l:SetStartPoint("BOTTOMLEFT",0,0)
        l:SetEndPoint("BOTTOMRIGHT",0,0)
        l:SetThickness(1)
        displayTable[0] = {
          RowFrame = toonHeaderFrame,
          ChildFrames = {}
        }
      end

      displayTable[0].RowFrame:Show()
      
      if not displayTable[0].SummaryFrame then
        local sumamryFrame = CreateFrame("Frame","AltRepsSummaryFrame", displayTable[0].RowFrame, "BackdropTemplate")
        sumamryFrame:SetPoint("TOPLEFT", displayTable[0].RowFrame ,"TOPLEFT", 0, 0)
        sumamryFrame:SetSize(factionColumnWidth, rowHeight)
        local sumamryTitle = sumamryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        sumamryTitle:SetPoint("CENTER", 0, 0)
        sumamryFrame.Text = sumamryTitle
        sumamryFrame.Text:SetText(GOLDFONT .. "Summary" .. FONTEND)

        sumamryFrame:HookScript("OnEnter", function(self)
          ShowOverallTooltip(sumamryFrame)
        end)
        sumamryFrame:HookScript("OnLeave", function(self) 
          CloseTooltips()
        end)
        displayTable[0].SummaryFrame = sumamryFrame
      end

      if toonIndex < (core.db.Options.MaxCharacters + toonSliderValue) and toonIndex >= toonSliderValue then
        if toon.Faction == "Alliance" then hasAlliance = toon.Faction elseif toon.Faction == "Horde" then hasHorde = toon.Faction end;        
        local toonname, toonserver = toonId:match('^(.*)[-](.*)$')
        columnIndex = columnIndex + 1

        if not displayTable[0].ChildFrames[columnIndex] then
          local i = columnIndex
          local toonFrame = CreateFrame("Frame","AltRepsToonHeaderFrame"..columnIndex, displayTable[0].RowFrame, "BackdropTemplate")
          toonFrame:SetPoint("TOPLEFT", displayTable[0].RowFrame ,"TOPLEFT", factionColumnWidth + (columnIndex - 1) * toonColumnWidth, 0)
          toonFrame:SetSize(toonColumnWidth, rowHeight)
          
          toonFrame:HookScript("OnEnter", function(self)
            ShowToonTooltip(self, displayTable[0].ChildFrames[i].ToonId)
          end)
          toonFrame:HookScript("OnLeave", function(self) 
            CloseTooltips()
          end)

          displayTable[0].ChildFrames[columnIndex] = {
            Frame = toonFrame
          }
        end

        displayTable[0].ChildFrames[columnIndex].ToonId = toonId
        displayTable[0].ChildFrames[columnIndex].Frame:Show()
        if not displayTable[0].ChildFrames[columnIndex].Text then
          local text = displayTable[0].ChildFrames[columnIndex].Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
          text:SetPoint("CENTER", 0, 0)
          displayTable[0].ChildFrames[columnIndex].Text = text
        end
        displayTable[0].ChildFrames[columnIndex].Text:SetText(ClassColorise(toon.Class, toonname))
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
              rowIndex = rowIndex + 1
              if not displayTable[rowIndex] then
                local rowFrame = CreateFrame("Frame","AltRepsFactionRowFrame"..rowIndex, frame, "BackdropTemplate")
                rowFrame:SetPoint("TOPLEFT", frame ,"TOPLEFT", 0, -rowHeight - rowIndex * rowHeight)
                rowFrame:SetPoint("BOTTOMRIGHT", frame ,"TOPRIGHT", 0, -rowHeight - (rowIndex + 1) * rowHeight)
                local l = rowFrame:CreateLine()
                l:SetColorTexture(0, 0, 0, 0.6)
                l:SetStartPoint("BOTTOMLEFT", 0, 0)
                l:SetEndPoint("BOTTOMRIGHT", 0, 0)
                l:SetThickness(1)
                displayTable[rowIndex] = {
                  RowFrame = rowFrame,
                  ChildFrames = {}
                }
              end
              if not displayTable[rowIndex].ChildFrames[0] then
                local rowFrame = CreateFrame("Frame","AltRepsFactionRowHeaderFrame"..rowIndex, displayTable[rowIndex].RowFrame, "BackdropTemplate")
                rowFrame:SetPoint("TOPLEFT", displayTable[rowIndex].RowFrame, "TOPLEFT", 0, 0)
                rowFrame:SetSize(factionColumnWidth, rowHeight)
                local text = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                text:SetPoint("CENTER", 0, 0)
                rowFrame.Text = text
                displayTable[rowIndex].ChildFrames[0] = {
                  Frame = rowFrame
                }
              end
              displayTable[rowIndex].ChildFrames[0].FactionId = nil
              displayTable[rowIndex].ChildFrames[0].Frame.Text:SetText(GOLDFONT .. expansion.Name .. FONTEND)
              displayTable[rowIndex].ChildFrames[0].Frame:Show()
              displayTable[rowIndex].RowFrame:Show()
              hasExpansionRowBeenAdded = true
            end

            rowIndex = rowIndex + 1
            if not displayTable[rowIndex] then
              local rowFrame = CreateFrame("Frame","AltRepsFactionRowFrame"..rowIndex, frame, "BackdropTemplate")
              rowFrame:SetPoint("TOPLEFT", frame ,"TOPLEFT", 0, -rowHeight - rowIndex * rowHeight)
              rowFrame:SetPoint("BOTTOMRIGHT", frame ,"TOPRIGHT", 0, -rowHeight - (rowIndex + 1) * rowHeight)
              local l = rowFrame:CreateLine()
              l:SetColorTexture(0, 0, 0 , 0.6)
              l:SetStartPoint("BOTTOMLEFT",0,0)
              l:SetEndPoint("BOTTOMRIGHT",0,0)
              l:SetThickness(1)
              displayTable[rowIndex] = {
                RowFrame = rowFrame,
                ChildFrames = {}
              }
            end
            if not displayTable[rowIndex].ChildFrames[0] then
              local rowFrame = CreateFrame("Frame","AltRepsFactionRowHeaderFrame"..rowIndex, displayTable[rowIndex].RowFrame, "BackdropTemplate")
              rowFrame:SetPoint("TOPLEFT", displayTable[rowIndex].RowFrame, "TOPLEFT", 0, 0)
              rowFrame:SetSize(factionColumnWidth, rowHeight)
              local text = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
              text:SetPoint("CENTER", 0, 0)
              rowFrame.Text = text
              local r = rowIndex
              rowFrame:HookScript("OnEnter", function(self)
                ShowFactionTooltip(rowFrame, displayTable[r].ChildFrames[0].FactionId)
              end)
              rowFrame:HookScript("OnLeave", function(self) 
                CloseTooltips()
              end)
              rowFrame:HookScript("OnMouseDown", function(frame, button)
                if button == "LeftButton" then
                  core:SetFactionOrdering(displayTable[r].ChildFrames[0].FactionId)
                end
              end)
              displayTable[rowIndex].ChildFrames[0] = {
                Frame = rowFrame
              }
            end

            displayTable[rowIndex].ChildFrames[0].FactionId = factionId
            displayTable[rowIndex].ChildFrames[0].Frame.Text:SetText(YELLOWFONT .. faction.Name .. FONTEND)
            displayTable[rowIndex].ChildFrames[0].Frame:Show()
            displayTable[rowIndex].RowFrame:Show()

          end
        end
      end
    end
  end

  for tableRowIndex, row in sortedPairs(displayTable) do
    if tableRowIndex ~= 0 then 
      for tableColumnIndex, column in sortedPairs(displayTable[0].ChildFrames) do
        if tableColumnIndex < core.db.Options.MaxCharacters + 1 then
          if not displayTable[tableRowIndex].ChildFrames[tableColumnIndex] then
            local dataFrame = CreateFrame("Frame","AltRepsDataFrame"..tableRowIndex.."_"..tableColumnIndex, displayTable[tableRowIndex].RowFrame, "BackdropTemplate")
            dataFrame:SetPoint("TOPLEFT", displayTable[tableRowIndex].RowFrame, "TOPLEFT", factionColumnWidth + toonColumnWidth * (tableColumnIndex - 1), 0)
            dataFrame:SetSize(toonColumnWidth, rowHeight)
            displayTable[tableRowIndex].ChildFrames[tableColumnIndex] = {
              Frame = dataFrame
            }
          end
          local dataFrame = displayTable[tableRowIndex].ChildFrames[tableColumnIndex].Frame
          dataFrame:Show()

          if row and row.ChildFrames and row.ChildFrames[0].FactionId then
            if not dataFrame.Progress then 
              local progress = CreateFrame("StatusBar", nil, dataFrame, "BackdropTemplate")
              progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
              progress:SetPoint("CENTER", dataFrame, "CENTER", 0, 0)
              progress:SetSize(toonColumnWidth * 0.8, rowHeight * 0.7)
              local tex = progress:CreateTexture(nil, "BACKGROUND")
              tex:SetAllPoints()
              tex:SetColorTexture(0, 0, 0, 0.8)
              progress.Texture = tex          
              progress.Value = progress:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
              progress.Value:SetPoint("CENTER", progress)
              progress.Value:SetTextColor(1, 1, 1)
              core:SkinFrame(progress, nil, {0,0,0})
              dataFrame.Progress = progress

              dataFrame.Progress:HookScript("OnEnter", function(self) 
                self.Value:SetText(self.Value.rolloverText) 
                ShowToonFactionTooltip(self, { factionId = row.ChildFrames[0].FactionId, toonId = column.ToonId})
              end)
              dataFrame.Progress:HookScript("OnLeave", function(self) 
                self.Value:SetText(self.Value.standing) 
                CloseTooltips()
              end)
            end
          end

          local toon = core.db.Toons[column.ToonId]

          if not toon then
            dataFrame:Hide()
          else
            local factionId = row.ChildFrames[0].FactionId;
            local faction = core.db.Factions[factionId]
            if not toon.Reps then toon.Reps = {} end
            local rep = toon.Reps[factionId]

            if dataFrame.Progress and row and row.ChildFrames then
              if not factionId then
                dataFrame.Progress:Hide()
              else
                dataFrame.Progress:Show()
              end

              local color
              local value, threshold = 0, 0
              if rep then
                if rep.RenownLevel ~= nil then
                  dataFrame.Progress.Value.standing = rep.RenownLevel
                elseif rep.FriendTextLevel ~= nil then
                  dataFrame.Progress.Value.standing = rep.FriendTextLevel
                elseif rep.ParagonValue then
                  dataFrame.Progress.Value.standing = "Paragon"
                  if rep.HasParagonReward then dataFrame.Progress.Value.standing = dataFrame.Progress.Value.standing .. " " .. paragonLootTextureString end
                else
                  dataFrame.Progress.Value.standing = factionStandings[rep.Standing]
                end
                
                if rep.ParagonValue then
                  color = core.db.Options.StandingColours[9]
                elseif rep.RenownLevel then
                  color = core.db.Options.StandingColours[5]
                elseif rep.FriendTextLevel then
                  color = core.db.Options.StandingColours[5]
                else
                  color = core.db.Options.StandingColours[rep.Standing]
                end
      
                
                if rep.ParagonValue then
                  value = mod(rep.ParagonValue, rep.ParagonThreshold)
                  threshold = rep.ParagonThreshold
                else
                  value = rep.Current
                  threshold = rep.Max            
                end
              else
                dataFrame.Progress.Value.standing = "Unknown"
                color = core.db.Options.StandingColours[0]
              end
      
              dataFrame.Progress:SetMinMaxValues(0, threshold)
              dataFrame.Progress:SetValue(value)
      
              dataFrame.Progress.Value.rolloverText = HIGHLIGHT_FONT_COLOR_CODE.." "..format(REPUTATION_PROGRESS_FORMAT,BreakUpLargeNumbers(value),BreakUpLargeNumbers(threshold))..FONT_COLOR_CODE_CLOSE
              dataFrame.Progress.Value:SetText(dataFrame.Progress.Value.standing)
      
              dataFrame.Progress:SetStatusBarColor(color.r, color.g, color.b, 1)        
            end
          end
        end
      end
    end
  end

  local baseWidth = columnIndex * toonColumnWidth + factionColumnWidth + 10
  local baseHeight = rowHeight * rowIndex + 50
  local adjustWidth, adjustHeight = 0, 0

  local toonCount = tableLengthWithShow(core.db.Toons)
  local showHorizontalScroll = toonCount > core.db.Options.MaxCharacters

  local expansionCount = tableLengthWithShow(core.db.Expansions)
  local showVerticalScroll = expansionCount > core.db.Options.MaxExpansions

  if showHorizontalScroll then adjustHeight = 30 end
  if showVerticalScroll then adjustWidth = 10 end
    
  frame:SetSize(baseWidth + adjustWidth, baseHeight + adjustHeight)
  
  if showHorizontalScroll then
    core:GetSliderHorizontal(frame, toonCount, baseWidth + adjustWidth, baseHeight + adjustHeight)
  elseif core.slider_horizontal and core.slider_horizontal:IsShown() then
    core.slider_horizontal:Hide()
    frame:SetWidth(baseWidth)
  end

  
  if showVerticalScroll then
    core:GetSliderVertical(frame, expansionCount, baseWidth + adjustWidth, baseHeight + adjustHeight)
  elseif core.slider_vertical and core.slider_vertical:IsShown() then
    core.slider_vertical:Hide()
    frame:SetHeight(baseHeight)
  end
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
    scrollBarFrame:SetPoint("BOTTOMLEFT", frame, 15, 0)
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
  
  core.slider_horizontal:SetMinMaxValues(1, (toonCount + 1) - core.db.Options.MaxCharacters)
  core.slider_horizontal:SetSize(w*frame:GetScale() - 30, 20)
  if core.slider_horizontal.CurrentValue == nil then
    core.slider_horizontal:SetValue(1)
  end
  core.slider_horizontal:Show()
  return core.slider_horizontal
end

function core:GetSliderVertical(frame, expansionCount, w, h)
  if not core.slider_vertical then
    local scrollBarFrame = CreateFrame("Slider","AltRepsScrollBarFrameVertical", frame, "BackdropTemplate")
    scrollBarFrame:SetPoint("TOPRIGHT",frame, "TOPRIGHT", -3, -35)
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
  core.slider_vertical:SetMinMaxValues(1, (expansionCount + 1) - core.db.Options.MaxExpansions)
  core.slider_vertical:SetSize(14,h*frame:GetScale() - 50)
  if core.slider_vertical.CurrentValue == nil then
    core.slider_vertical:SetValue(1)
  end
  core.slider_vertical:Show()
  return core.slider_vertical
end


function core:SetFactionOrdering(factionId)
  if factionId == factionIdForOrdering then
    factionIdForOrdering = nil
  else
    factionIdForOrdering = factionId
  end
  core:UpdateTooltip()
end

function core:UpdateTooltip()
  if core.frame and core.frame:IsShown() then
    core:GetTooltip(core.frame)
  end
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
  local toon = core.db.Toons[thisToon]
  for factionId, _ in pairs(core.db.Factions) do
    local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfoByID(factionId)
    local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = C_Reputation_GetFactionParagonInfo(factionId)
    local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = C_GossipInfo_GetFriendshipReputation(factionId)
    local majorFactionData = C_MajorFactions_GetMajorFactionData(factionId)
    
    if majorFactionData == nil then
      majorFactionData = {} 
    end

    if not toon.Reps then toon.Reps = {} end
    if not (atWarWith and not canToggleAtWar) and name then
      local current, max, maxRenown = 0, 0, nil
      if standingID == 8 then
        current = 21000
        max = 21000
      elseif majorFactionData.isUnlocked then
        current = C_MajorFactions_HasMaximumRenown(factionId) and majorFactionData.renownLevelThreshold or majorFactionData.renownReputationEarned;
        max = majorFactionData.renownLevelThreshold
        maxRenown = #C_MajorFactions_GetRenownLevels(factionId)
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
        ParagonThreshold = threshold,
        FriendTextLevel = friendTextLevel,
        FriendText = friendText,
        RenownLevel = majorFactionData.renownLevel,
        MaxRenown = maxRenown,
      }
    end
  end
  core:UpdateTooltip()
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
  if _G.SettingsPanel:IsShown() then
    _G.SettingsPanel:Hide()
  else
    InterfaceOptionsFrame_OpenToCategory(core.optionsFactionsFrame)
    InterfaceOptionsFrame_OpenToCategory(core.optionsCharactersFrame)
    InterfaceOptionsFrame_OpenToCategory(core.optionsGeneralFrame)
  end
end

function core:ReopenConfigDisplay(frame)
  if _G.SettingsPanel:IsShown() then
    _G.SettingsPanel:Hide()
    InterfaceOptionsFrame_OpenToCategory(core.optionsFactionsFrame)
    InterfaceOptionsFrame_OpenToCategory(core.optionsCharactersFrame)
    InterfaceOptionsFrame_OpenToCategory(frame)
  end
end

function core:SkinFrame(frame,name, color)
  if IsAddOnLoaded("ElvUI") or IsAddOnLoaded("Tukui") then
    if frame.StripTextures then
      frame:StripTextures()
    end
    if frame.CreateBackdrop then
      frame:CreateBackdrop("Transparent")
    end
    if name then
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
    if color then
      if ElvUI then
        ElvUI[1]:GetModule('Skins'):HandleStatusBar(frame, color)
      end
    end
  end
end

function core:ResetFactionColours(db)
  for standingId, _ in pairs(factionStandings) do
    if standingId == 9 then
      db.Options.StandingColours[standingId] = { ["r"] = standingColours.Blue.r, ["g"] = standingColours.Blue.g, ["b"] = standingColours.Blue.b }
    elseif standingId > 4 then
      db.Options.StandingColours[standingId] = { ["r"] = standingColours.Green.r, ["g"] = standingColours.Green.g, ["b"] = standingColours.Green.b }
    elseif standingId == 4 or standingId == 0 then
      db.Options.StandingColours[standingId] = { ["r"] = standingColours.Yellow.r, ["g"] = standingColours.Yellow.g, ["b"] = standingColours.Yellow.b }
    else
      db.Options.StandingColours[standingId] = { ["r"] = standingColours.Red.r, ["g"] = standingColours.Red.g, ["b"] = standingColours.Red.b }
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
          ColourReputations = {
            type = "toggle",
            order = 5,
            name = "Colour reputations",
            desc = "Should reputations be coloured by standing? (Friendly, Honoured, etc.)",
            get = function(info) return core.db.Options.ColourReputations end,
            set = function(info, value)
              core.db.Options.ColourReputations = value
              core:UpdateTooltip()
            end,
          },
          StandingColoursHeader= {
            order = 6,
            type = "header",
            name = "Faction standing colours",
            cmdHidden = true,
          },
          ResetReputationColoursHeader= {
            order = 100,
            type = "header",
            name = "",
            cmdHidden = true,
          },
          ResetReputationColours = {
            order = 110,
            type = "execute",
            name = "Reset",
            desc = "Reset standing colours back to their defaults. ",
            confirm = function(info)
              return "Are you sure you wish to reset the standing colours back to their defaults?"
            end,
            func = function ()
              core:ResetFactionColours(core.db)
              core:BuildOptions()
              core:UpdateTooltip()
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
          MaxExpansions = {
            type = "range",
            min = 1,
            max = 3,
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

  local calculatedOrder = options.args.General.args.StandingColoursHeader.order
  for index, standingColour in sortedPairs(core.db.Options.StandingColours) do
    calculatedOrder = calculatedOrder + 1
    options.args.General.args["StandingColour_" .. index] = {
      type = "color",
      order = calculatedOrder,
      name = factionStandings[index],
      disabled = function() return not core.db.Options.ColourReputations end,
      get = function(info)
        return standingColour.r, standingColour.g, standingColour.b
      end,
      set = function(info, r, g, b)
        standingColour.r = r
        standingColour.g = g
        standingColour.b = b
        core:UpdateTooltip()
      end,
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

function ShowToonTooltip(parent, arg, ...)
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

  finishMiniTooltip(parent)
end

function ShowFactionTooltip(parent, factionId)
  if not factionId then return end
  local faction = core.db.Factions[factionId]
  if not faction then return end
  openMiniTooltip(2, "LEFT","RIGHT")
  local headerRow = miniTooltip:AddHeader()
  miniTooltip:SetCell(headerRow, 1, GOLDFONT .. faction.Name .. FONTEND)
  miniTooltip:SetCell(headerRow, 2, "ID: " .. factionId)
  miniTooltip:AddSeparator(6,0,0,0,0)
  local text
  if factionIdForOrdering and factionIdForOrdering == factionId then
    text = YELLOWFONT .. "Left click: " .. FONTEND .. "Order characters in normal order"
  else
    text = YELLOWFONT .. "Left click: " .. FONTEND .. "Order characters by decending " .. faction.Name .. " reputation."
  end
  miniTooltip:SetCell(miniTooltip:AddLine(), 1, text)

  finishMiniTooltip(parent)
end

function ShowToonFactionTooltip(parent, arg, ...)
  local factionId = arg.factionId
  local toonId = arg.toonId
  if not factionId then return end
  if not toonId then return end
  local toon = core.db.Toons[toonId]
  if not toon then return end
  local faction = core.db.Factions[factionId]
  if not faction then return end
  local rep = toon.Reps[factionId]
  openMiniTooltip(2, "LEFT","RIGHT")
  miniTooltip:SetCell(miniTooltip:AddHeader(), 1, GOLDFONT .. faction.Name .. FONTEND)
  
  local standingLine = miniTooltip:AddLine()
  
  if rep then
    if rep.RenownLevel ~= nil then
      miniTooltip:SetCell(standingLine, 1, YELLOWFONT .. "Renown: " .. FONTEND)
      miniTooltip:SetCell(standingLine, 2, rep.RenownLevel .. " / " .. (rep.MaxRenown or "0"))
    elseif rep.FriendTextLevel ~= nil then
      miniTooltip:SetCell(standingLine, 1, YELLOWFONT .. "Standing: " .. FONTEND)
      miniTooltip:SetCell(standingLine, 2, rep.FriendTextLevel)
      miniTooltip:SetCell(miniTooltip:AddLine(), 1, rep.FriendText, 2)
    else
      miniTooltip:SetCell(standingLine, 1, YELLOWFONT .. "Standing: " .. FONTEND)
      miniTooltip:SetCell(standingLine, 2, factionStandings[rep.Standing])
    end
    
    if rep.HasParagonReward ~= nil and rep.ParagonValue and rep.ParagonThreshold and rep.Standing == 8 then
      local suppliesLine = miniTooltip:AddLine()
      local goldLine = miniTooltip:AddLine()
      
      local supplyChestValue = 0
      for _, expansion in pairs(core.db.Expansions) do 
        if expansion.Id == faction.ExpansionId then
          supplyChestValue = expansion.SupplyChestValue or 0
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

    if rep.RenownLevel then
      if rep.RenownLevel ~= rep.MaxRenown then
        local rewards = C_MajorFactions_GetRenownRewardsForLevel(factionId, rep.RenownLevel + 1)
        if rewards ~= nil then
          miniTooltip:AddLine()
          miniTooltip:SetCell(miniTooltip:AddLine(), 1, YELLOWFONT .. "Next renown rewards: " .. FONTEND)
          for _, reward in pairs(rewards) do
            local rewardLine = miniTooltip:AddLine()
            miniTooltip:SetCell(rewardLine, 1, string.format("|T%d:0|t", reward.icon))
            miniTooltip:SetCell(rewardLine, 2, reward.name)
          end
        end
      end
    end

  else 
    miniTooltip:SetCell(standingLine, 1, YELLOWFONT .. "Standing: " .. FONTEND)
    miniTooltip:SetCell(standingLine, 2, "Unknown")
  end

  finishMiniTooltip(parent)
end

function ShowOverallTooltip(parent, arg, ...)
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

  miniTooltip:AddSeparator(6,0,0,0,0)
  local authorLine = miniTooltip:AddLine()
  miniTooltip:SetCell(authorLine, 1, GOLDFONT .. "Made with love by: " .. FONTEND)
  miniTooltip:SetCell(authorLine, 3, ClassColorise("PALADIN", "Eylwen"))
  finishMiniTooltip(parent)
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
  miniTooltip = LibQTip:Acquire("AltRepsIndicatorTooltip", ...)
  addon.miniTooltip = miniTooltip
  miniTooltip:Clear()
  miniTooltip:SetScale(1)
end

function finishMiniTooltip(parent)
  miniTooltip:SetAutoHideDelay(3, parent)
  miniTooltip.OnRelease = function() miniTooltip = nil end -- extra-safety: update our variable on auto-release
  miniTooltip:SmartAnchorTo(parent)
  miniTooltip:SetFrameLevel(150) -- ensure visibility when forced to overlap main tooltip
  core:SkinFrame(miniTooltip,"AltRepsIndicatorTooltip")
  miniTooltip:Show()
end

function CloseTooltips()
  if miniTooltip then
    miniTooltip:Hide()
  end
end

function tableLengthWithShow(T)
  local count = 0
  for _, v in pairs(T) do if v.Show then count = count + 1 end end
  return count
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
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

function factionSort(characterKey1, characterKey2)
  local toon1 = core.db.Toons[characterKey1]
  local toon2 = core.db.Toons[characterKey2]

  factionRep1 = toon1.Reps[factionIdForOrdering] 
  factionRep2 = toon2.Reps[factionIdForOrdering] 

  if factionRep1 ~= nil and factionRep2 ~= nil then
    if factionRep1.RenownLevel ~= nil or factionRep2.RenownLevel ~= nil then
      if (factionRep1.RenownLevel or 0) > (factionRep2.RenownLevel or 0) then
        return true
      elseif (factionRep2.RenownLevel or 0) > (factionRep1.RenownLevel or 0) then
        return false
      elseif (factionRep1.Current or 0) > (factionRep2.Current or 0) then
          return true
      end
    else
      if factionRep1.Standing > factionRep2.Standing then
        return true
      elseif factionRep2.Standing > factionRep1.Standing then
        return false
      else
        if factionRep1.Current > factionRep2.Current then
          return true
        elseif factionRep2.Current > factionRep1.Current then
          return false
        else
          if factionRep1.ParagonValue and factionRep2.ParagonValue then
            return mod(factionRep1.ParagonValue, factionRep1.ParagonThreshold)  > mod(factionRep2.ParagonValue, factionRep2.ParagonThreshold) 
          end
        end
      end
    end
  elseif factionRep1 ~= nil then
    return true
  elseif factionRep2 ~= nil then
    return false
  end
  
  characterSort(characterKey1, characterKey2)
end

function characterSort(characterKey1, characterKey2)  
  local toon1 = core.db.Toons[characterKey1]
  local toon2 = core.db.Toons[characterKey2]

  if toon1 ~= nil and toon2 == nil then
    return true
  end
  if toon1 == nil and toon2 ~= nil then
    return false
  end

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

  if toon1 ~= nil and toon1.SortOrder == nil then
    toon1.SortOrder = 25
  end
  if toon2 ~= nil and toon2.SortOrder == nil then
    toon2.SortOrder = 25
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