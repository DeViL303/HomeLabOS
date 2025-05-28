-- HomeLabOS - Playstation Home Menu
-- Copyright (C) 2025 DeViL303
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, version 3.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.

g_PreloadedData = {}
g_CategoryMemoryContainer = nil
g_SearchMemoryContainer = nil

g_Tabs = {
    {
        label = "Players Online",
        category = "Players Online",
        content = {
            buttons = {
                { label = "Active Lobbies", localisedText = "kActiveLobbies", action = "view_stats" },
                { label = "Home Lab Picks", localisedText = "kPicks", action = "picks" },
                { label = "Popular Today", localisedText = "kPopularToday", action = "populartoday" },
                { label = "Who Is Online", localisedText = "kWhoIsOnline", action = "whoisonline" }
            }
        },
        selectedButton = 1
    },
    {
        label = "Male Clothing",
        category = "Male Clothing",
        content = {
            buttons = {
                { label = "Outfit", localisedText = "kOutfit", action = "male-outfit" },
                { label = "Bundle", localisedText = "kBundle", action = "male-bundle" },
                { label = "Hat", localisedText = "kHat", action = "male-hat" },
                { label = "Hair", localisedText = "kHair", action = "male-hair" },
                { label = "Torso", localisedText = "kTorso", action = "male-torso" },
                { label = "Hands", localisedText = "kHands", action = "male-hands" },
                { label = "Legs", localisedText = "kLegs", action = "male-legs" },
                { label = "Feet", localisedText = "kFeet", action = "male-feet" },
                { label = "Jewellery", localisedText = "kJewellery", action = "male-jewellery" },
                { label = "Glasses", localisedText = "kGlasses", action = "male-glasses" },
                { label = "Headphones", localisedText = "kHeadphones", action = "male-headphones" },
                { label = "Facial Hair", localisedText = "kFacialHair", action = "male-facialhair" }
            }
        },
        selectedButton = 1
    },
    {
        label = "Female Clothing",
        category = "Female Clothing",
        content = {
            buttons = {
                { label = "Outfit", localisedText = "kOutfit", action = "female-outfit" },
                { label = "Bundle", localisedText = "kBundle", action = "female-bundle" },
                { label = "Hat", localisedText = "kHat", action = "female-hat" },
                { label = "Hair", localisedText = "kHair", action = "female-hair" },
                { label = "Torso", localisedText = "kTorso", action = "female-torso" },
                { label = "Hands", localisedText = "kHands", action = "female-hands" },
                { label = "Legs", localisedText = "kLegs", action = "female-legs" },
                { label = "Feet", localisedText = "kFeet", action = "female-feet" },
                { label = "Jewellery", localisedText = "kJewellery", action = "female-jewellery" },
                { label = "Glasses", localisedText = "kGlasses", action = "female-glasses" },
                { label = "Headphones", localisedText = "kHeadphones", action = "female-headphones" }
            }
        },
        selectedButton = 1
    },
    {
        label = "Portables",
        category = "Portables",
        content = {
            buttons = {
                { label = "Companion", localisedText = "kCompanion", action = "portable-companion" },
                { label = "Locomotion", localisedText = "kLocomotion", action = "portable-locomotion" },
                { label = "Animation", localisedText = "kAnimation", action = "portable-animation" },
                { label = "Interaction", localisedText = "kInteraction", action = "portable-interaction" },
                { label = "Group", localisedText = "kGroup", action = "portable-interaction-group" },
                { label = "Soundpack", localisedText = "kSoundpack", action = "portable-soundpack" },
                { label = "Bundle", localisedText = "kBundle", action = "portable-bundle" }
            }
        },
        selectedButton = 1
    },
    {
        label = "Furniture",
        category = "Furniture",
        content = {
            buttons = {
                { label = "Appliance", localisedText = "kAppliance", action = "furniture-appliance" },
                { label = "Chair", localisedText = "kChair", action = "furniture-chair" },
                { label = "Cube", localisedText = "kCube", action = "furniture-cube" },
                { label = "Flooring", localisedText = "kFlooring", action = "furniture-flooring" },
                { label = "Footstool", localisedText = "kFootstool", action = "furniture-footstool" },
                { label = "Frame", localisedText = "kFrame", action = "furniture-frame" },
                { label = "Light", localisedText = "kLight", action = "furniture-light" },
                { label = "Ornament", localisedText = "kOrnament", action = "furniture-ornament" },
                { label = "Sofa", localisedText = "kSofa", action = "furniture-sofa" },
                { label = "Table", localisedText = "kTable", action = "furniture-table" },
                { label = "Storage", localisedText = "kStorage", action = "furniture-storage" },
                { label = "Bundle", localisedText = "kBundle", action = "furniture-bundle" }
            }
        },
        selectedButton = 1
    },
    {
        label = "Scenes",
        category = "Scenes",
        content = {
            buttons = {
                { label = "Entitlement", localisedText = "kEntitlement", action = "scene-entitlement" },
                { label = "Expansion", localisedText = "kExpansion", action = "scene-expansion" },
                { label = "Public Scenes", localisedText = "kPublicScenes", action = "public" },
                { label = "Private Scenes", localisedText = "kPrivateScenes", action = "private" }
            }
        },
        selectedButton = 1
    },
    {
        label = "Search",
        category = "Search",
        content = {
            textbox = { text = "" },
            buttons = {
                { label = "Search Now", localisedText = "kNewSearch", action = "search_now" }
            }
        },
        selectedButton = 1
    },
    {
        label = "MyInventory",
        category = "MyInventory",
        content = {
            buttons = {
                { label = "kLoadAll", localisedText = "kLoadAll", action = "kLoadAll" },
                { label = "kMyMale", localisedText = "kMyMale", action = "kMyMale" },
                { label = "kMyFemale", localisedText = "kMyFemale", action = "kMyFemale" },
                { label = "kMyPortable", localisedText = "kMyPortable", action = "kMyPortable" },
                { label = "kMyFurniture", localisedText = "kMyFurniture", action = "kMyFurniture" },
                { label = "kMyApartments", localisedText = "kMyApartments", action = "kMyApartments" }
            }
        },
        selectedButton = 1
    },
    {
        label = "Tools",
        category = "Tools",
        content = {
            buttons = {
                { label = "General", localisedText = "kPopCmds", action = "rtrc_general" },
                { label = "Presets", localisedText = "kAvtPresets", action = "rtrc_presets" },
                { label = "Console", localisedText = "kCmdConsole", action = "rtrc_console" },
                { label = "Web Browser", localisedText = "kWebBrowser", action = "open_url" }
            },
            grid_buttons = {
                ["rtrc_general"] = {
                    buttons = {
                        {
                            { {localisedText = "kDefApt", action = "home"}, {localisedText = "kMapBasicApt", action = "map basicapartment"} },
                            { {localisedText = "kRelScene", action = "reloadscene"}, {localisedText = "kTogDbgCam", action = "*debugcam"} },
                            { {localisedText = "kTelCam", action = "teleporttocamera"}, {localisedText = "kTogCmdCon", action = "*console"} },
                            { {localisedText = "kClrCmdCon", action = "cls"}, {localisedText = "kOpenWard", action = "activateWardrobe"} },
                            { {localisedText = "kOpenDbgCat", action = "displayObjectCatalogue"}, {localisedText = "kOpenPanic", action = "safescreen"} },
                            { {localisedText = "kRefLocObj", action = "objcat refresh"}, {localisedText = "kRemPort", action = "lc LocalPlayer.DebugRemovePortable('')"} },
                            { {localisedText = "kShot720p", action = "shot"}, {localisedText = "kShot1440p", action = "shothires my.tga 2 4"} },
                            { {localisedText = "kEnDevNav", action = "devnav"}, {localisedText = "kTogAdmin", action = "toggleadmin"} }
                        },
                        {
                            { {localisedText = "kInfChat", action = "adminchatrange 9999"}, {localisedText = "kDisProfFilt", action = "ProfanityFilter_Enable 0"} },
                            { {localisedText = "kLogOff", action = "logoff"}, {localisedText = "kShutHome", action = "shutdown"} },
                            { {localisedText = "kLoadMale", action = "loadavatar male_save"}, {localisedText = "kLoadFemale", action = "loadavatar female_save"} },
                            { {localisedText = "ConsoleNumLines 8", action = "ConsoleNumLines 8"}, {localisedText = "ConsoleNumLines 28", action = "ConsoleNumLines 28"} },
                            { {localisedText = "", action = ""}, {localisedText = "", action = ""} },
                            { {localisedText = "", action = ""}, {localisedText = "", action = ""} },
                            { {localisedText = "", action = ""}, {localisedText = "", action = ""} },
                            { {localisedText = "", action = ""}, {localisedText = "", action = ""} }
                        }
                    },
                    toggles = {
                        { label = "Feature 1", localisedText = "kDisAvtCol", action = "DisableCharacterCollision", state = false },
                        { label = "Feature 2", localisedText = "kEnAvtAnim", action = "AnimationEnable", state = true },
                        { label = "Feature 3", localisedText = "kWireframe", action = "wireframeenable", state = false },
                        { label = "Feature 4", localisedText = "kEnShadows", action = "shadowEnable", state = true },
                        { label = "Feature 5", localisedText = "kLighting", action = "renderOverlays", state = true },
                        { label = "Feature 6", localisedText = "kRenTransp", action = "renderSemiTrans", state = true },
                        { label = "Feature 7", localisedText = "kGlowEn", action = "GlowEnable", state = true },
                        { label = "Feature 8", localisedText = "kSunEn", action = "SunEnable", state = true },
                        { label = "Feature 9", localisedText = "", action = "", state = false },
                        { label = "Feature 10", localisedText = "", action = "", state = false },
                        { label = "Feature 11", localisedText = "", action = "", state = false },
                        { label = "Feature 12", localisedText = "", action = "", state = false },
                        { label = "Feature 13", localisedText = "kEnShowDAO", action = "showDAO", state = false },
                        { label = "Feature 14", localisedText = "kRenAvtCol", action = "localPersonDebugRenderCollisionShape", state = false },
                        { label = "Feature 15", localisedText = "kShowDynLt", action = "showDynamicLights", state = false },
                        { label = "Feature 16", localisedText = "kShowLtPrb", action = "showLightProbeData", state = false },
                        { label = "Feature 17", localisedText = "kShowLtSamp", action = "showLightProbeSamplePoints", state = false },
                        { label = "Feature 18", localisedText = "kShowModBnd", action = "showModelBounds", state = false },
                        { label = "Feature 19", localisedText = "kShowModInf", action = "showModelInfo", state = false },
                        { label = "Feature 20", localisedText = "kShowAtmDbg", action = "atmos_RenderDebugData", state = false },
                        { label = "Feature 21", localisedText = "kShowPicHks", action = "showPictureHooks", state = false },
                        { label = "Feature 22", localisedText = "kShowDbgClth", action = "debugClothingLimits", state = false },
                        { label = "Feature 23", localisedText = "", action = "", state = false },
                        { label = "Feature 24", localisedText = "", action = "", state = false },
                        { label = "Feature 25", localisedText = "kHideOSD", action = "osdhide", state = false },
                        { label = "Feature 26", localisedText = "kShowCamStk", action = "showCameraStack", state = false },
                        { label = "Feature 27", localisedText = "kDispFPS", action = "showfps", state = false },
                        { label = "Feature 28", localisedText = "kDispUptime", action = "showtimer", state = false },
                        { label = "Feature 29", localisedText = "kShowChanInf", action = "showChannelInfo", state = false },
                        { label = "Feature 30", localisedText = "kShowDynLtInf", action = "showDynamicLightInfo", state = false },
                        { label = "Feature 31", localisedText = "kVSyncTest", action = "showVsyncTest", state = false },
                        { label = "Feature 32", localisedText = "kShowObjProf", action = "ObjectProfiler", state = false },
                        { label = "Feature 33", localisedText = "kShowActProf", action = "activeProfile", state = false },
                        { label = "Feature 34", localisedText = "kEnMemStats", action = "enableMemoryStats", state = false },
                        { label = "Feature 35", localisedText = "kShowNetStats", action = "enableNetStats", state = false },
                        { label = "Feature 36", localisedText = "kShowPeers", action = "enablePeerList", state = false },
                        { label = "Feature 37", localisedText = "kShowVMView", action = "enableVMView", state = false },
                        { label = "Feature 38", localisedText = "kShowPartInf", action = "showParticleInfo", state = false },
                        { label = "Feature 39", localisedText = "kShowScrStats", action = "enableScreenStats", state = false },
                        { label = "Feature 40", localisedText = "kShowVidStats", action = "enableVideoStats", state = false },
                        { label = "Feature 41", localisedText = "kShowPPUOver", action = "enablePPUOverviewStats", state = false },
                        { label = "Feature 42", localisedText = "kShowMemSlot", action = "MemorySlotManagerProfiler", state = false },
                        { label = "Feature 43", localisedText = "kEnProfGUI", action = "profilerGUIEnable", state = false },
                        { label = "Feature 44", localisedText = "kShowPersLbl", action = "showPersonLabels", state = false },
                        { label = "Feature 45", localisedText = "kShowOSDBnd", action = "showOSDObjectBounds", state = false },
                        { label = "Feature 46", localisedText = "kShowSafe169", action = "showOsdSafeZone169", state = false },
                        { label = "Feature 47", localisedText = "kShowSafe43", action = "showOsdSafeZone43", state = false },
                        { label = "Feature 48", localisedText = "kEnVisiProf", action = "visiProfEnable", state = false }
                    }
                }
            }
        },
        selectedButton = 1
    },
    {
        label = "Settings",
        category = nil,
        content = {
            buttons = {
                { label = "System Info", localisedText = "kSystemInfo", action = "System_info" }
            },
            toggles = {
                basic_settings = {
                    { label = "Unfortunately there are no Basic HomeLabOS settings available yet", state = false },
                    { label = "But in the mean time you can play with these cool toggles!", state = true },
                    { label = "Once more testing has been done some settings", state = true },
                    { label = "might be shown here depending on requirements", state = false }
                },
                advanced_settings = {
                    { label = "Unfortunately there are no Advanced HomeLabOS settings available yet", state = false },
                    { label = "But in the mean time you can play with these cool toggles!", state = true },
                    { label = "Once more testing has been done some settings", state = true },
                    { label = "might be shown here depending on requirements", state = false }
                }
            }
        },
        selectedButton = 1
    }
}
g_ActiveTabIndex = 1


SELECT = 1
BACK = 2
QUICKMENU = 3
OPTIONS = 4
DPAD_UP = 5
DPAD_DOWN = 6
NEXT_PAGE_R2 = 7
PREVIOUS_PAGE_L2 = 8
NEXT_TAB_R1 = 9
PREVIOUS_TAB_L1 = 10
NAV_DPAD_RIGHT = 11
NAV_DPAD_LEFT = 12


g_GridTextures = {}
g_DownloadingItems = {}
g_LobbyItems = {
    ["Players Online"] = {}
}
g_CategoryResponses = {
    ["MyInventory"] = "",
    ["Male Clothing"] = "",
    ["Female Clothing"] = "",
    ["Portables"] = "",
    ["Furniture"] = "",
    ["Scenes"] = "",
    ["Search"] = "",
    ["Tools"] = "",
    ["Players Online"] = ""
}
g_GridItems = {
    ["MyInventory"] = {},
    ["Male Clothing"] = {},
    ["Female Clothing"] = {},
    ["Portables"] = {},
    ["Furniture"] = {},
    ["Scenes"] = {},
    ["Search"] = {}
}
g_CategoryPageInfo = {
    ["MyInventory"] = {},
    ["Male Clothing"] = {},
    ["Female Clothing"] = {},
    ["Portables"] = {},
    ["Furniture"] = {},
    ["Scenes"] = {},
    ["Search"] = "",
    ["Players Online"] = {}
}
g_CurrentPage = {
    ["MyInventory"] = {},
    ["Male Clothing"] = {},
    ["Female Clothing"] = {},
    ["Portables"] = {},
    ["Furniture"] = {},
    ["Scenes"] = {},
    ["Search"] = {},
    ["Players Online"] = {}
}
g_TotalPages = {
    ["MyInventory"] = {},
    ["Male Clothing"] = {},
    ["Female Clothing"] = {},
    ["Portables"] = {},
    ["Furniture"] = {},
    ["Scenes"] = {},
    ["Search"] = {},
    ["Players Online"] = {}
}