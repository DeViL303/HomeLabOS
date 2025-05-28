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

LoadLibrary("Vector4")
LoadLibrary("Renderer")
LoadLibrary("Pad")
LoadLibrary("Object")
LoadLibrary("LocalPlayer")
LoadLibrary("Person")
LoadLibrary("Sound")
LoadLibrary("Texture")
LoadLibrary("SoundBank")
LoadLibrary("SceneInfo")
LoadLibrary("MemoryContainer")
LoadLibrary("HttpPostData")
LoadLibrary("Resource")

Resource.Run("OSK")

g_PendingPageChangeForPopup = false
g_Slot1UUID = nil
g_ShowWheelPopup = false
g_ShowL1Popup = false
g_R1MenuSelectedIndex = 1
g_L1MenuSelectedIndex = 1
g_SelectPressTime = nil
g_SelectPressItem = nil
g_MiniPopupActive = false
g_HQImageResource = nil
g_HQImageTexture = nil
g_HQImageIsDownloading = false
g_DPadReserved = false
g_MiniStateActive = false
exitingMiniState = false

g_LastGridLoadTime = 0
g_GridLoadCooldown = 0.5
g_SelectedTable = 1
g_SelectedWhoIsOnlineItem = 1
g_SelectedFriendsOnlineItem = 1

g_InvitePopupActive = false
g_InvitePopupSelectedButton = 1
g_SelectedInviteItem = nil

g_MyNameIs = ""
g_MyCurrentInstanceCode = ""
g_MyCurrentLocation = ""


g_DeleteInviteContainer = nil
g_LastDeleteRequestTime = 0
g_DeleteRequestQueue = {}
g_DeleteRequestDelay = 0.5

local sessionID = LocalPlayer.GetGlobalSessionId() or "unknown"

local buttonHoldStates = {
    [DPAD_UP] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [DPAD_DOWN] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [NAV_DPAD_LEFT] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [NAV_DPAD_RIGHT] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [PREVIOUS_TAB_L1] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [NEXT_TAB_R1] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [OPTIONS] = { isHolding = false, holdTime = 0 },
    [BACK] = { isHolding = false, holdTime = 0, cacheCleared = false, gameExited = false, pendingCacheClear = false, startedInGrid = false },
    [QUICKMENU] = { isHolding = false, holdTime = 0, sceneReloadTriggered = false }
}
local HOLD_THRESHOLD = 0.5
local REPEAT_INTERVAL = 0.22
local OPTIONS_CLEAR_CACHE_THRESHOLD = 1.0
local OPTIONS_EXIT_GAME_THRESHOLD = 3.0


local lastTabChangeTime = 0
local TAB_CHANGE_COOLDOWN = 0.5


function CommandConsoleOSKCallback()
    local command = g_CustomOSKText
    if command ~= "" then
        print("[#HomeLabOS v1.01] Sending command via RTM: " .. command)
        SendRTMCommand(command)
    else
        print("[#HomeLabOS v1.01] No command entered")
    end
end

local function PerformSidebarNavigation(direction)
    local activeTab = g_Tabs[g_ActiveTabIndex]
    local maxIndex = #activeTab.content.buttons
    local minButton = 1

    local oldSelectedButton = activeTab.selectedButton
    local oldSelectedAction = oldSelectedButton > 0 and activeTab.content.buttons[oldSelectedButton].action or nil

    if direction == "up" then
        if activeTab.selectedButton > minButton then
            gSoundBank:Play2d("page_flip")
            activeTab.selectedButton = activeTab.selectedButton - 1
        else
            gSoundBank:Play2d("cancel_back")
        end
    elseif direction == "down" then
        if activeTab.selectedButton < maxIndex then
            gSoundBank:Play2d("page_flip")
            activeTab.selectedButton = activeTab.selectedButton + 1
        else
            gSoundBank:Play2d("cancel_back")
        end
    end

    if oldSelectedButton ~= activeTab.selectedButton then
        ClearTabTextures(activeTab.label)
        local newSelectedAction = activeTab.content.buttons[activeTab.selectedButton].action

        if (oldSelectedAction == "rtrc_console" or oldSelectedAction == "open_url") and g_CustomOSKActive then
            CloseCustomOSK(false)
            print("[#HomeLabOS v1.01] Closed OSK when leaving " .. oldSelectedAction)
        end

        if activeTab.label == "Players Online" then
            RequestLobbyData(newSelectedAction)
        elseif IsGridTab(activeTab.label) then
            LoadGridForSelectedButton(activeTab)
        end
    end

    local newSelectedAction = activeTab.content.buttons[activeTab.selectedButton].action

    if activeTab.label == "Tools" and oldSelectedAction == "rtrc_presets" and newSelectedAction ~= "rtrc_presets" then
        ClearTabTextures("Tools_Presets")
    end
end

local function PerformGridNavigation(direction)
    local activeTab = g_Tabs[g_ActiveTabIndex]
    local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
    local isPresets = (activeTab.label == "Tools" and selectedAction == "rtrc_presets")
    local cols = isPresets and 12 or 6
    local total_items = isPresets and 72 or #g_GridItems[activeTab.label]

    if direction == "left" then
        if (g_SelectedGridItem - 1) % cols == 0 then
            g_ActiveArea = "sidebar"
            gSoundBank:Play2d("page_flip")
        else
            g_SelectedGridItem = g_SelectedGridItem - 1
            gSoundBank:Play2d("page_flip")
        end
    elseif direction == "right" then
        g_SelectedGridItem = g_SelectedGridItem + 1
        if g_SelectedGridItem > total_items then
            g_SelectedGridItem = 1
        end
        gSoundBank:Play2d("page_flip")
    elseif direction == "up" then
        local new_index = g_SelectedGridItem - cols
        if new_index >= 1 then
            g_SelectedGridItem = new_index
            gSoundBank:Play2d("page_flip")
        else
            gSoundBank:Play2d("cancel_back")
            if not isPresets and not g_CategoryRequestPending and not g_SearchRequestPending then
                ChangePageBack()
            end
        end
    elseif direction == "down" then
        local new_index = g_SelectedGridItem + cols
        if new_index <= total_items then
            g_SelectedGridItem = new_index
            gSoundBank:Play2d("page_flip")
        else
            gSoundBank:Play2d("cancel_back")
            if not isPresets and not g_CategoryRequestPending and not g_SearchRequestPending then
                ChangePageForward()
            end
        end
    end
end

local function PerformButtonGridNavigation(direction)
    local activeTab = g_Tabs[g_ActiveTabIndex]
    local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
    local isRtrcGeneral = (activeTab.label == "Tools" and selectedAction == "rtrc_general")
    local isToggles = (g_ActiveArea == "toggles")

    local maxRows = isRtrcGeneral and (isToggles and 12 or 4) or 4
    local maxCols = isRtrcGeneral and (isToggles and 4 or 8) or 8

    if direction == "left" then
        if g_SelectedButtonCol > 1 then
            g_SelectedButtonCol = g_SelectedButtonCol - 1
            gSoundBank:Play2d("page_flip")
        else
            g_ActiveArea = "sidebar"
            gSoundBank:Play2d("page_flip")
        end
    elseif direction == "right" then
        if g_SelectedButtonCol < maxCols then
            g_SelectedButtonCol = g_SelectedButtonCol + 1
            gSoundBank:Play2d("page_flip")
        else
            gSoundBank:Play2d("cancel_back")
        end
    elseif direction == "up" then
        if g_SelectedButtonRow > 1 then
            g_SelectedButtonRow = g_SelectedButtonRow - 1
            gSoundBank:Play2d("page_flip")
        elseif isToggles and isRtrcGeneral then
            g_ActiveArea = "grid"
            g_SelectedButtonRow = 4
            g_SelectedButtonCol = math.min(g_SelectedButtonCol, 8)
            gSoundBank:Play2d("page_flip")
        else
            gSoundBank:Play2d("cancel_back")
        end
    elseif direction == "down" then
        if g_SelectedButtonRow < maxRows then
            g_SelectedButtonRow = g_SelectedButtonRow + 1
            gSoundBank:Play2d("page_flip")
        elseif isRtrcGeneral and not isToggles then
            g_ActiveArea = "toggles"
            g_SelectedButtonRow = 1
            g_SelectedButtonCol = math.min(g_SelectedButtonCol, 4)
            gSoundBank:Play2d("page_flip")
        else
            gSoundBank:Play2d("cancel_back")
        end
    end
end

local function PerformPopupNavigation(direction)
    if direction == "left" then
        g_PopupSelectedButton = g_PopupSelectedButton - 1
        if g_PopupSelectedButton < 1 then
            g_PopupSelectedButton = 6
        end
        gSoundBank:Play2d("page_flip")
    elseif direction == "right" then
        g_PopupSelectedButton = g_PopupSelectedButton + 1
        if g_PopupSelectedButton > 6 then
            g_PopupSelectedButton = 1
        end
        gSoundBank:Play2d("page_flip")
    elseif direction == "up" then
        if g_PopupSelectedButton <= 3 then
            g_PopupSelectedButton = g_PopupSelectedButton + 3
        else
            g_PopupSelectedButton = g_PopupSelectedButton - 3
        end
        gSoundBank:Play2d("page_flip")
    elseif direction == "down" then
        if g_PopupSelectedButton <= 3 then
            g_PopupSelectedButton = g_PopupSelectedButton + 3
        else
            g_PopupSelectedButton = g_PopupSelectedButton - 3
        end
        gSoundBank:Play2d("page_flip")
    end
end

local function PerformMiniMenuNavigation(direction, menu)
    local selectedIndex = (menu == "R1") and g_R1MenuSelectedIndex or g_L1MenuSelectedIndex
    local newIndex = selectedIndex

    if direction == "left" then
        newIndex = selectedIndex - 1
        if newIndex < 1 then newIndex = 40 end
    elseif direction == "right" then
        newIndex = selectedIndex + 1
        if newIndex > 40 then newIndex = 1 end
    elseif direction == "up" then
        newIndex = selectedIndex - 2
        if newIndex < 1 then newIndex = selectedIndex + 38 end
    elseif direction == "down" then
        newIndex = selectedIndex + 2
        if newIndex > 40 then newIndex = selectedIndex - 38 end
    end

    if newIndex ~= selectedIndex then
        if menu == "R1" then
            g_R1MenuSelectedIndex = newIndex
        else
            g_L1MenuSelectedIndex = newIndex
        end
        gSoundBank:Play2d("page_flip")
    end
end

local function PerformPopupItemCycle(direction)
    local activeTab = g_Tabs[g_ActiveTabIndex]
    local items
    local selectedIndex


    if activeTab.label == "Players Online" then
        items = g_LobbyItems["Players Online"] or {}
        selectedIndex = g_SelectedLobbyItem
    else
        items = g_GridItems[activeTab.label] or {}
        selectedIndex = g_SelectedGridItem
    end


    if #items > 0 then

        if direction == "previous" then
            selectedIndex = selectedIndex - 1
            if selectedIndex < 1 then
                selectedIndex = #items
            end
        elseif direction == "next" then
            selectedIndex = selectedIndex + 1
            if selectedIndex > #items then
                selectedIndex = 1
            end
        end


        local item = items[selectedIndex]
        if item then

            local category
            if activeTab.label == "Players Online" then
                category = item.accessType or "unknown"
                g_SelectedLobbyItem = selectedIndex
            else
                category = item.category or activeTab.content.buttons[activeTab.selectedButton].action or "unknown"
                g_SelectedGridItem = selectedIndex
            end


            g_PopupItem = {
                id = item.id or item.lobbyName,
                name = item.name or item.psvName,
                category = category,
                thumbnail_type = item.thumbnail_type or (activeTab.label == "Players Online" and "L" or nil)
            }


            g_PopupResponse = nil
            ResetPopupRequest()
            ResetPopupImage()
            gSoundBank:Play2d("page_flip")
        end
    else

        gSoundBank:Play2d("cancel_back")
    end
end

function PerformListNavigation(direction)
    local activeTab = g_Tabs[g_ActiveTabIndex]
    if activeTab.label ~= "Players Online" then
        return
    end
    local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action

    if selectedAction == "whoisonline" then
        local whoIsOnlineItems = g_LobbyItems["Players Online"].whoIsOnline or {}
        local friendsItems = g_LobbyItems["Players Online"].friends or {}
        local sentInvitesItems = g_LobbyItems["Players Online"].sentInvites or {}
        local receivedInvitesItems = g_LobbyItems["Players Online"].receivedInvites or {}
        local maxDisplayRows = 16
        local maxInviteRows = 7

        if direction == "up" then
            if g_SelectedTable == 1 and #whoIsOnlineItems > 0 then
                if g_SelectedWhoIsOnlineItem > 1 then
                    g_SelectedWhoIsOnlineItem = g_SelectedWhoIsOnlineItem - 1

                    if g_SelectedWhoIsOnlineItem < g_WhoIsOnlineScrollOffset + 1 then
                        g_WhoIsOnlineScrollOffset = math.max(0, g_SelectedWhoIsOnlineItem - 1)
                    end
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            elseif g_SelectedTable == 2 and #friendsItems > 0 then
                if g_SelectedFriendsOnlineItem > 1 then
                    g_SelectedFriendsOnlineItem = g_SelectedFriendsOnlineItem - 1

                    if g_SelectedFriendsOnlineItem < g_FriendsOnlineScrollOffset + 1 then
                        g_FriendsOnlineScrollOffset = math.max(0, g_SelectedFriendsOnlineItem - 1)
                    end
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            elseif g_SelectedTable == 3 and #sentInvitesItems > 0 then
                if g_SelectedSentInvitesItem > 1 then
                    g_SelectedSentInvitesItem = g_SelectedSentInvitesItem - 1
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            elseif g_SelectedTable == 4 and #receivedInvitesItems > 0 then
                if g_SelectedReceivedInvitesItem > 1 then
                    g_SelectedReceivedInvitesItem = g_SelectedReceivedInvitesItem - 1
                    gSoundBank:Play2d("page_flip")



                elseif #sentInvitesItems > 0 then
                    g_SelectedTable = 3
                    g_SelectedSentInvitesItem = 1
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            else
                gSoundBank:Play2d("cancel_back")
            end
        elseif direction == "down" then
            if g_SelectedTable == 1 and #whoIsOnlineItems > 0 then
                if g_SelectedWhoIsOnlineItem < #whoIsOnlineItems then
                    g_SelectedWhoIsOnlineItem = g_SelectedWhoIsOnlineItem + 1

                    if g_SelectedWhoIsOnlineItem > g_WhoIsOnlineScrollOffset + maxDisplayRows then
                        g_WhoIsOnlineScrollOffset = math.min(g_SelectedWhoIsOnlineItem - maxDisplayRows, #whoIsOnlineItems - maxDisplayRows)
                    end
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            elseif g_SelectedTable == 2 and #friendsItems > 0 then
                if g_SelectedFriendsOnlineItem < #friendsItems then
                    g_SelectedFriendsOnlineItem = g_SelectedFriendsOnlineItem + 1

                    if g_SelectedFriendsOnlineItem > g_FriendsOnlineScrollOffset + maxDisplayRows then
                        g_FriendsOnlineScrollOffset = math.min(g_SelectedFriendsOnlineItem - maxDisplayRows, #friendsItems - maxDisplayRows)
                    end
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            elseif g_SelectedTable == 3 and #sentInvitesItems > 0 then
                if g_SelectedSentInvitesItem < math.min(#sentInvitesItems, maxInviteRows) then
                    g_SelectedSentInvitesItem = g_SelectedSentInvitesItem + 1
                    gSoundBank:Play2d("page_flip")



                elseif #receivedInvitesItems > 0 then
                    g_SelectedTable = 4
                    g_SelectedReceivedInvitesItem = 1
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            elseif g_SelectedTable == 4 and #receivedInvitesItems > 0 then
                if g_SelectedReceivedInvitesItem < math.min(#receivedInvitesItems, maxInviteRows) then
                    g_SelectedReceivedInvitesItem = g_SelectedReceivedInvitesItem + 1
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            else
                gSoundBank:Play2d("cancel_back")
            end
        elseif direction == "left" then
            if g_SelectedTable == 2 then
                if #whoIsOnlineItems > 0 then
                    g_SelectedTable = 1
                    g_SelectedWhoIsOnlineItem = 1
                    g_WhoIsOnlineScrollOffset = 0
                    gSoundBank:Play2d("page_flip")
                else
                    g_ActiveArea = "sidebar"
                    gSoundBank:Play2d("page_flip")
                end
            elseif g_SelectedTable == 3 then
                if #whoIsOnlineItems > 0 then
                    g_SelectedTable = 1
                    g_SelectedWhoIsOnlineItem = 1
                    g_WhoIsOnlineScrollOffset = 0
                    gSoundBank:Play2d("page_flip")
                else
                    g_ActiveArea = "sidebar"
                    gSoundBank:Play2d("page_flip")
                end
            elseif g_SelectedTable == 4 then
                if #sentInvitesItems > 0 then
                    g_SelectedTable = 3
                    g_SelectedSentInvitesItem = 1
                    gSoundBank:Play2d("page_flip")






                elseif #whoIsOnlineItems > 0 then
                    g_SelectedTable = 1
                    g_SelectedWhoIsOnlineItem = 1
                    g_WhoIsOnlineScrollOffset = 0
                    gSoundBank:Play2d("page_flip")
                else
                    g_ActiveArea = "sidebar"
                    gSoundBank:Play2d("page_flip")
                end
            else
                g_ActiveArea = "sidebar"
                gSoundBank:Play2d("page_flip")
            end
        elseif direction == "right" then
            if g_SelectedTable == 1 then
                if #sentInvitesItems > 0 then
                    g_SelectedTable = 3
                    g_SelectedSentInvitesItem = 1
                    gSoundBank:Play2d("page_flip")
                elseif #receivedInvitesItems > 0 then
                    g_SelectedTable = 4
                    g_SelectedReceivedInvitesItem = 1
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end

















            elseif g_SelectedTable == 2 then
                if #sentInvitesItems > 0 then
                    g_SelectedTable = 3
                    g_SelectedSentInvitesItem = 1
                    gSoundBank:Play2d("page_flip")
                elseif #receivedInvitesItems > 0 then
                    g_SelectedTable = 4
                    g_SelectedReceivedInvitesItem = 1
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            elseif g_SelectedTable == 3 then
                if #receivedInvitesItems > 0 then
                    g_SelectedTable = 4
                    g_SelectedReceivedInvitesItem = 1
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            else
                gSoundBank:Play2d("cancel_back")
            end
        end
    else

        local total_items = #g_LobbyItems["Players Online"]
        if total_items == 0 then
            return
        end
        if direction == "up" then
            if g_SelectedLobbyItem > 1 then
                g_SelectedLobbyItem = g_SelectedLobbyItem - 1
            else
                g_SelectedLobbyItem = total_items
            end
            gSoundBank:Play2d("page_flip")
        elseif direction == "down" then
            if g_SelectedLobbyItem < total_items then
                g_SelectedLobbyItem = g_SelectedLobbyItem + 1
            else
                g_SelectedLobbyItem = 1
            end
            gSoundBank:Play2d("page_flip")
        elseif direction == "left" then
            g_ActiveArea = "sidebar"
            gSoundBank:Play2d("page_flip")
        elseif direction == "right" then
            gSoundBank:Play2d("cancel_back")
        end
    end
end

function PerformTabNavigation(direction)
    local currentTime = GetInstanceTime()

    lastTabChangeTime = currentTime

    local oldTabIndex = g_ActiveTabIndex
    local oldTabLabel = g_Tabs[oldTabIndex].label
    local oldSelectedAction = g_Tabs[oldTabIndex].content.buttons[g_Tabs[oldTabIndex].selectedButton].action

    if direction == "previous" then
        g_ActiveTabIndex = g_ActiveTabIndex - 1
        if g_ActiveTabIndex < 1 then
            g_ActiveTabIndex = #g_Tabs
        end
    elseif direction == "next" then
        g_ActiveTabIndex = g_ActiveTabIndex + 1
        if g_ActiveTabIndex > #g_Tabs then
            g_ActiveTabIndex = 1
        end
    end

    g_ActiveArea = "sidebar"
    local activeTab = g_Tabs[g_ActiveTabIndex]

    if oldTabLabel == "Tools" and (oldSelectedAction == "rtrc_console" or oldSelectedAction == "open_url") and g_CustomOSKActive then
        CloseCustomOSK(false)
        print("[#HomeLabOS v1.01] Closed OSK when leaving Tools tab from " .. oldSelectedAction)
    end


    if oldTabLabel == "Search" then
        g_CategoryPageInfo["Search"] = "Page 1 of 1   Total Items 0"
        g_CurrentPage["Search"] = 1
        g_TotalPages["Search"] = 1
        g_GridItems["Search"] = {}
        g_SearchKeywords = ""
        local searchTab = g_Tabs[7]
        if searchTab and searchTab.content.textbox then
            searchTab.content.textbox.text = ""
        end
    elseif IsGridTab(oldTabLabel) or oldTabLabel == "MyInventory" then
        ClearTabTextures(oldTabLabel)
        g_GridItems[oldTabLabel] = nil
    elseif oldTabLabel == "Players Online" then
        ClearTabTextures(oldTabLabel)
        g_LobbyItems[oldTabLabel] = nil
    elseif oldTabLabel == "Tools" and oldSelectedAction == "rtrc_presets" then
        ClearTabTextures("Tools_Presets")
    end


    if activeTab.label == "Search" then
        if not g_CategoryPageInfo["Search"] or g_CategoryPageInfo["Search"] == "" then
            g_CategoryPageInfo["Search"] = "Page 1 of 1   Total Items 0"
            g_CurrentPage["Search"] = 1
            g_TotalPages["Search"] = 1
            g_GridItems["Search"] = {}
        end
    end

    if activeTab.label == "Players Online" then
        local newSelectedAction = activeTab.content.buttons[activeTab.selectedButton].action
        RequestLobbyData(newSelectedAction)
    else
        LoadGridForSelectedButton(activeTab)
    end
    gSoundBank:Play2d("page_flip")
end

function SearchNowOSKCallback()
    local txt = g_CustomOSKText
    if txt ~= "" then
        g_SearchKeywords = txt
        local searchTab = g_Tabs[7]
        if searchTab and searchTab.content.textbox then
            searchTab.content.textbox.text = txt
        end
        if not g_SearchRequestPending then
            g_CurrentPage["Search"] = 1
            ClearTabTextures("Search")
            if not g_SearchMemoryContainer then
                g_SearchMemoryContainer = MemoryContainer.Create(4096)
                if not g_SearchMemoryContainer then
                    print("Error: Failed to create memory container")
                    return
                end
            end
            g_SearchPostData = HttpPostData.Create(g_SearchMemoryContainer, "text/plain")
            if not g_SearchPostData then
                print("Error: Failed to create post data")
                return
            end
            g_SearchPostData:SetMethod("GET")
            g_SearchPostData:Reset()
            g_SearchPostData:AddHttpHeader("Accept", "text/plain")
            g_SearchPostData:FinalizeHttpHeaders()
            g_SearchPostData:Finalize()
            local encodedKeywords = txt:gsub(" ", "+")
            local url = "http://173.225.107.46/HomeLab_OS_API/search.php?q=" .. encodedKeywords .. "&page=1"
            print("Initiating search with URL: " .. url)
            g_SearchResource = Resource.Request(url, "file", g_SearchPostData)
            if g_SearchResource then
                g_SearchRequestPending = true
                g_SearchTimeoutFrames = 360
                g_SearchTabLabel = "Search"
                print("Search request sent successfully")
            else
                ResetSearchRequest()
                print("Error: Failed to request resource")
            end
        end
    else
        print("No search keywords entered")
    end
end

function OpenURLOSKCallback()
    local url = g_CustomOSKText
    if url ~= "" then
        local command = "openurl " .. url
        print("[#HomeLabOS v1.01] Sending command via RTM: " .. command)
        SendRTMCommand(command)
    else
        print("[#HomeLabOS v1.01] No URL entered")
    end
end

function ProcessDeleteInviteQueue()
    local currentTime = GetInstanceTime()
    if #g_DeleteRequestQueue > 0 and (currentTime - g_LastDeleteRequestTime) >= g_DeleteRequestDelay then
        local request = table.remove(g_DeleteRequestQueue, 1)
        local url = request.url
        local inviteType = request.inviteType
        local name = request.name
        local instanceCode = request.instanceCode
        local index = request.index


        if not g_DeleteInviteContainer then
            g_DeleteInviteContainer = MemoryContainer.Create(1024)
            if not g_DeleteInviteContainer then
                print("[#HomeLabOS v1.01] Error: Failed to create memory container for delete invite")
                return
            end
        end


        local postData = HttpPostData.Create(g_DeleteInviteContainer, "text/plain")
        if not postData then
            print("[#HomeLabOS v1.01] Error: Failed to create post data for delete invite")
            return
        end

        postData:SetMethod("GET")
        postData:Reset()
        postData:AddHttpHeader("Accept", "text/plain")
        postData:FinalizeHttpHeaders()
        postData:Finalize()


        local resource = Resource.Request(url, "file", postData)
        if resource then
            print("[#HomeLabOS v1.01] Sent delete invite request for " .. name .. " (" .. inviteType .. ")")
            g_LastDeleteRequestTime = currentTime


            local items = (inviteType == "sent") and g_LobbyItems["Players Online"].sentInvites or g_LobbyItems["Players Online"].receivedInvites
            if items[index] and items[index].name == name and items[index].instanceCode == instanceCode then
                table.remove(items, index)
                print("[#HomeLabOS v1.01] Removed invite for " .. name .. " (" .. inviteType .. ") from UI")
            else
                print("[#HomeLabOS v1.01] Warning: Invite index mismatch for " .. name .. " (" .. inviteType .. ")")
            end


            local pageInfoKey = (inviteType == "sent") and "sentinvites" or "receivedinvites"
            g_CategoryPageInfo["Players Online"][pageInfoKey] = "Page 1 of 1   Total Items " .. #items


            if inviteType == "sent" then
                g_SelectedSentInvitesItem = math.min(g_SelectedSentInvitesItem, #items > 0 and #items or 1)
            else
                g_SelectedReceivedInvitesItem = math.min(g_SelectedReceivedInvitesItem, #items > 0 and #items or 1)
            end


            g_InvitePopupActive = false
            g_InvitePopupSelectedButton = 1
            g_SelectedInviteItem = nil


            UIRender()
        else
            print("[#HomeLabOS v1.01] Error: Failed to initiate delete invite request for " .. name .. " (" .. inviteType .. ")")
        end


        postData = nil
    end
end

function ChangePageForward()
    local activeTab = g_Tabs[g_ActiveTabIndex]
    local category = activeTab.category
    if activeTab.label == "Search" then
        if g_SearchKeywords == "" or g_SearchKeywords == nil then
            print("[#HomeLabOS v1.01] Cannot change page: No search keywords provided")
            gSoundBank:Play2d("cancel_back")
            return
        end
        if g_TotalPages["Search"] and g_TotalPages["Search"] > 0 then
            local currentPage = g_CurrentPage["Search"] or 1
            local newPage = currentPage + 1
            if newPage > g_TotalPages["Search"] then
                newPage = 1
            end
            g_PageChangeInProgress = true
            g_CurrentPage["Search"] = newPage
            g_SelectedGridItem = 1
            g_GridItems["Search"] = {}
            local encodedKeywords = g_SearchKeywords:gsub(" ", "+")
            local url = "http://173.225.107.46/HomeLab_OS_API/search.php?q=" .. encodedKeywords .. "&page=" .. newPage
            if not g_SearchMemoryContainer then
                g_SearchMemoryContainer = MemoryContainer.Create(4096)
                if not g_SearchMemoryContainer then
                    print("Error: Failed to create g_SearchMemoryContainer")
                    g_PageChangeInProgress = false
                    return
                end
            end
            g_SearchPostData = HttpPostData.Create(g_SearchMemoryContainer, "text/plain")
            if g_SearchPostData then
                g_SearchPostData:SetMethod("GET")
                g_SearchPostData:Reset()
                g_SearchPostData:AddHttpHeader("Accept", "text/plain")
                g_SearchPostData:FinalizeHttpHeaders()
                g_SearchPostData:Finalize()
                g_SearchResource = Resource.Request(url, "file", g_SearchPostData)
                if g_SearchResource then
                    ClearTabTextures(activeTab.label)
                    g_SearchRequestPending = true
                    g_SearchRequestTime = GetInstanceTime()
                    g_SearchTabLabel = "Search"
                    if g_PopupActive then
                        g_PendingPageChangeForPopup = true
                    end
                else
                    ResetSearchRequest()
                    g_PageChangeInProgress = false
                end
            else
                g_PageChangeInProgress = false
            end
        else
            print("[#HomeLabOS v1.01] Cannot change page: No valid search results")
            gSoundBank:Play2d("cancel_back")
        end
    elseif activeTab.label == "Players Online" then
        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
        if g_TotalPages["Players Online"] and g_TotalPages["Players Online"][selectedButton.action] and g_TotalPages["Players Online"][selectedButton.action] > 0 then
            local currentPage = g_CurrentPage["Players Online"][selectedButton.action] or 1
            local newPage = currentPage + 1
            if newPage > g_TotalPages["Players Online"][selectedButton.action] then
                newPage = 1
            end
            g_PageChangeInProgress = true
            g_CurrentPage["Players Online"][selectedButton.action] = newPage
            g_LobbyItems["Players Online"] = {}
            local url
            if selectedButton.action == "view_stats" then
                url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?current&page=" .. newPage
            elseif selectedButton.action == "picks" then
                url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?picks&page=" .. newPage
            elseif selectedButton.action == "populartoday" then
                url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?popular&page=" .. newPage
            elseif selectedButton.action == "invitesystem" then
                url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?players&page=" .. newPage
            end
            if url then
                if not g_LobbyContainer then
                    g_LobbyContainer = MemoryContainer.Create(4096)
                    if not g_LobbyContainer then
                        print("Error: Failed to create g_LobbyContainer")
                        g_PageChangeInProgress = false
                        return
                    end
                end
                g_LobbyPostData = HttpPostData.Create(g_LobbyContainer, "text/plain")
                if g_LobbyPostData then
                    g_LobbyPostData:SetMethod("GET")
                    g_LobbyPostData:Reset()
                    g_LobbyPostData:AddHttpHeader("Accept", "text/plain")
                    g_LobbyPostData:FinalizeHttpHeaders()
                    g_LobbyPostData:Finalize()
                    g_LobbyResource = Resource.Request(url, "file", g_LobbyPostData)
                    if g_LobbyResource then
                        ClearTabTextures(activeTab.label)
                        g_LobbyRequestPending = true
                        g_LobbyTabLabel = "Players Online"
                        if g_PopupActive then
                            g_PendingPageChangeForPopup = true
                        end
                    else
                        ResetLobbyRequest()
                        g_PageChangeInProgress = false
                        print("Error: Failed to initiate lobby request for page " .. newPage)
                    end
                else
                    g_PageChangeInProgress = false
                    print("Error: Failed to create post data for page " .. newPage)
                end
            end
        end
    elseif IsGridTab(activeTab.label) and category then
        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
        if selectedButton and selectedButton.action ~= "refresh_inventory" and g_TotalPages[category] and g_TotalPages[category][selectedButton.action] then
            local currentPage = g_CurrentPage[category][selectedButton.action] or 1
            local totalPages = g_TotalPages[category][selectedButton.action] or 1
            local newPage = currentPage + 1
            if newPage > totalPages then
                newPage = 1
            end
            print("Changing to next page: " .. newPage .. " of " .. totalPages .. " for " .. selectedButton.action)
            g_PageChangeInProgress = true
            g_SelectedGridItem = 1
            g_CurrentPage[category][selectedButton.action] = newPage
            local url = "http://173.225.107.46/HomeLab_OS_API/search.php?c=" .. selectedButton.action .. "&page=" .. newPage
            if category == "MyInventory" then
                url = url .. "&session=" .. sessionID
            end
            if not g_CategoryMemoryContainer then
                g_CategoryMemoryContainer = MemoryContainer.Create(4096)
                if not g_CategoryMemoryContainer then
                    print("Error: Failed to create g_CategoryMemoryContainer")
                    g_PageChangeInProgress = false
                    return
                end
            end
            g_CategoryPostData = HttpPostData.Create(g_CategoryMemoryContainer, "text/plain")
            if g_CategoryPostData then
                g_CategoryPostData:SetMethod("GET")
                g_CategoryPostData:Reset()
                g_CategoryPostData:AddHttpHeader("Accept", "text/plain")
                g_CategoryPostData:FinalizeHttpHeaders()
                g_CategoryPostData:Finalize()
                g_CategoryResource = Resource.Request(url, "file", g_CategoryPostData)
                if g_CategoryResource then
                    ClearTabTextures(activeTab.label)
                    g_CategoryRequestPending = true
                    g_CategoryRequestTime = GetInstanceTime()
                    g_CategoryTabLabel = activeTab.label
                    if g_PopupActive then
                        g_PendingPageChangeForPopup = true
                    end
                else
                    ResetCategoryRequest()
                    g_PageChangeInProgress = false
                    print("Error: Failed to initiate category request for page " .. newPage)
                end
            else
                g_PageChangeInProgress = false
                print("Error: Failed to create post data for page " .. newPage)
            end
        else
            print("Cannot change page: Invalid button or missing page data for " .. (selectedButton and selectedButton.action or "unknown"))
        end
    end
end

function ChangePageBack()
    local activeTab = g_Tabs[g_ActiveTabIndex]
    local category = activeTab.category
    if activeTab.label == "Search" then
        if g_SearchKeywords == "" or g_SearchKeywords == nil then
            print("[#HomeLabOS v1.01] Cannot change page: No search keywords provided")
            gSoundBank:Play2d("cancel_back")
            return
        end
        if g_TotalPages["Search"] and g_TotalPages["Search"] > 0 then
            local currentPage = g_CurrentPage["Search"] or 1
            local newPage = currentPage - 1
            if newPage < 1 then
                newPage = g_TotalPages["Search"]
            end
            g_PageChangeInProgress = true
            g_CurrentPage["Search"] = newPage
            g_SelectedGridItem = 1
            local encodedKeywords = g_SearchKeywords:gsub(" ", "+")
            local url = "http://173.225.107.46/HomeLab_OS_API/search.php?q=" .. encodedKeywords .. "&page=" .. newPage
            if not g_SearchMemoryContainer then
                g_SearchMemoryContainer = MemoryContainer.Create(4096)
                if not g_SearchMemoryContainer then
                    print("Error: Failed to create g_SearchMemoryContainer")
                    g_PageChangeInProgress = false
                    return
                end
            end
            g_SearchPostData = HttpPostData.Create(g_SearchMemoryContainer, "text/plain")
            if g_SearchPostData then
                g_SearchPostData:SetMethod("GET")
                g_SearchPostData:Reset()
                g_SearchPostData:AddHttpHeader("Accept", "text/plain")
                g_SearchPostData:FinalizeHttpHeaders()
                g_SearchPostData:Finalize()
                g_SearchResource = Resource.Request(url, "file", g_SearchPostData)
                if g_SearchResource then
                    ClearTabTextures(activeTab.label)
                    g_SearchRequestPending = true
                    g_SearchRequestTime = GetInstanceTime()
                    g_SearchTabLabel = "Search"
                    if g_PopupActive then
                        g_PendingPageChangeForPopup = true
                    end
                else
                    ResetSearchRequest()
                    g_PageChangeInProgress = false
                end
            else
                g_PageChangeInProgress = false
            end
        else
            print("[#HomeLabOS v1.01] Cannot change page: No valid search results")
            gSoundBank:Play2d("cancel_back")
        end
    elseif activeTab.label == "Players Online" then
        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
        if g_TotalPages["Players Online"] and g_TotalPages["Players Online"][selectedButton.action] and g_TotalPages["Players Online"][selectedButton.action] > 0 then
            local currentPage = g_CurrentPage["Players Online"][selectedButton.action] or 1
            local newPage = currentPage - 1
            if newPage < 1 then
                newPage = g_TotalPages["Players Online"][selectedButton.action]
            end
            g_PageChangeInProgress = true
            g_CurrentPage["Players Online"][selectedButton.action] = newPage
            g_LobbyItems["Players Online"] = {}
            local url
            if selectedButton.action == "view_stats" then
                url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?current&page=" .. newPage
            elseif selectedButton.action == "picks" then
                url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?picks&page=" .. newPage
            elseif selectedButton.action == "populartoday" then
                url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?popular&page=" .. newPage
            elseif selectedButton.action == "invitesystem" then
                url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?players&page=" .. newPage
            end
            if url then
                if not g_LobbyContainer then
                    g_LobbyContainer = MemoryContainer.Create(4096)
                    if not g_LobbyContainer then
                        print("Error: Failed to create g_LobbyContainer")
                        g_PageChangeInProgress = false
                        return
                    end
                end
                g_LobbyPostData = HttpPostData.Create(g_LobbyContainer, "text/plain")
                if g_LobbyPostData then
                    g_LobbyPostData:SetMethod("GET")
                    g_LobbyPostData:Reset()
                    g_LobbyPostData:AddHttpHeader("Accept", "text/plain")
                    g_LobbyPostData:FinalizeHttpHeaders()
                    g_LobbyPostData:Finalize()
                    g_LobbyResource = Resource.Request(url, "file", g_LobbyPostData)
                    if g_LobbyResource then
                        ClearTabTextures(activeTab.label)
                        g_LobbyRequestPending = true
                        g_LobbyTabLabel = "Players Online"
                        if g_PopupActive then
                            g_PendingPageChangeForPopup = true
                        end
                    else
                        ResetLobbyRequest()
                        g_PageChangeInProgress = false
                        print("Error: Failed to initiate lobby request for page " .. newPage)
                    end
                else
                    g_PageChangeInProgress = false
                    print("Error: Failed to create post data for page " .. newPage)
                end
            end
        end
    elseif IsGridTab(activeTab.label) and category then
        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
        if selectedButton and selectedButton.action ~= "refresh_inventory" and g_TotalPages[category] and g_TotalPages[category][selectedButton.action] then
            local currentPage = g_CurrentPage[category][selectedButton.action] or 1
            local totalPages = g_TotalPages[category][selectedButton.action] or 1
            local newPage = currentPage - 1
            if newPage < 1 then
                newPage = totalPages
            end
            print("Changing to previous page: " .. newPage .. " of " .. totalPages .. " for " .. selectedButton.action)
            g_PageChangeInProgress = true
            g_SelectedGridItem = 1
            g_CurrentPage[category][selectedButton.action] = newPage
            local url = "http://173.225.107.46/HomeLab_OS_API/search.php?c=" .. selectedButton.action .. "&page=" .. newPage
            if category == "MyInventory" then
                url = url .. "&session=" .. sessionID
            end
            if not g_CategoryMemoryContainer then
                g_CategoryMemoryContainer = MemoryContainer.Create(4096)
                if not g_CategoryMemoryContainer then
                    print("Error: Failed to create g_CategoryMemoryContainer")
                    g_PageChangeInProgress = false
                    return
                end
            end
            g_CategoryPostData = HttpPostData.Create(g_CategoryMemoryContainer, "text/plain")
            if g_CategoryPostData then
                g_CategoryPostData:SetMethod("GET")
                g_CategoryPostData:Reset()
                g_CategoryPostData:AddHttpHeader("Accept", "text/plain")
                g_CategoryPostData:FinalizeHttpHeaders()
                g_CategoryPostData:Finalize()
                g_CategoryResource = Resource.Request(url, "file", g_CategoryPostData)
                if g_CategoryResource then
                    ClearTabTextures(activeTab.label)
                    g_CategoryRequestPending = true
                    g_CategoryRequestTime = GetInstanceTime()
                    g_CategoryTabLabel = activeTab.label
                    if g_PopupActive then
                        g_PendingPageChangeForPopup = true
                    end
                else
                    ResetCategoryRequest()
                    g_PageChangeInProgress = false
                    print("Error: Failed to initiate category request for page " .. newPage)
                end
            else
                g_PageChangeInProgress = false
                print("Error: Failed to create post data for page " .. newPage)
            end
        else
            print("Cannot change page: Invalid button or missing page data for " .. (selectedButton and selectedButton.action or "unknown"))
        end
    end
end

function LoadGridForSelectedButton(activeTab)
    local currentTime = GetInstanceTime()
    g_LastGridLoadTime = currentTime

    local category = activeTab.category
    local action = activeTab.content.buttons[activeTab.selectedButton].action
    local sessionID = LocalPlayer.GetGlobalSessionId() or "unknown"


    if activeTab.label == "Search" and (g_SearchKeywords == "" or g_SearchKeywords == nil) then
        print("[#HomeLabOS v1.01] Skipping grid load for Search tab: No search keywords provided")
        g_GridItems["Search"] = {}
        g_CategoryResponses["Search"] = ""
        g_CurrentPage["Search"] = nil
        g_TotalPages["Search"] = nil
        g_CategoryPageInfo["Search"] = ""
        return
    end

    if IsGridTab(activeTab.label) and category then
        ClearTabTextures(activeTab.label)
        g_GridItems[activeTab.label] = {}
        g_SelectedGridItem = 1


        if type(category) ~= "string" then
            print("[#HomeLabOS v1.01] Error: Invalid category type for " .. activeTab.label .. ", expected string, got " .. type(category))
            return
        end
        if type(g_CurrentPage[category]) ~= "table" then
            print("[#HomeLabOS v1.01] Warning: g_CurrentPage[" .. category .. "] is not a table, resetting to empty table")
            g_CurrentPage[category] = {}
        end
        if type(g_TotalPages[category]) ~= "table" then
            print("[#HomeLabOS v1.01] Warning: g_TotalPages[" .. category .. "] is not a table, resetting to empty table")
            g_TotalPages[category] = {}
        end
        if type(g_CategoryPageInfo[category]) ~= "table" then
            print("[#HomeLabOS v1.01] Warning: g_CategoryPageInfo[" .. category .. "] is not a table, resetting to empty table")
            g_CategoryPageInfo[category] = {}
        end


        local page = g_CurrentPage[category][action] or 1

        local url
        if activeTab.label == "Search" then
            local encodedKeywords = g_SearchKeywords:gsub(" ", "+")
            url = "http://173.225.107.46/HomeLab_OS_API/search.php?q=" .. encodedKeywords .. "&page=" .. page
        else
            url = "http://173.225.107.46/HomeLab_OS_API/search.php?c=" .. action .. "&page=" .. page
            if category == "MyInventory" then
                url = url .. "&session=" .. sessionID
            end
        end

        if not g_CategoryMemoryContainer then
            g_CategoryMemoryContainer = MemoryContainer.Create(4096)
            if not g_CategoryMemoryContainer then
                print("Error: Failed to create g_CategoryMemoryContainer")
                return
            end
        end

        g_CategoryPostData = HttpPostData.Create(g_CategoryMemoryContainer, "text/plain")
        if g_CategoryPostData then
            g_CategoryPostData:SetMethod("GET")
            g_CategoryPostData:Reset()
            g_CategoryPostData:AddHttpHeader("Accept", "text/plain")
            g_CategoryPostData:FinalizeHttpHeaders()
            g_CategoryPostData:Finalize()
            g_CategoryResource = Resource.Request(url, "file", g_CategoryPostData)
            if g_CategoryResource then
                g_CategoryRequestPending = true
                g_CategoryRequestTime = GetInstanceTime()
                g_CategoryTabLabel = activeTab.label
                print("[#HomeLabOS v1.01] Requested grid data for " .. activeTab.label .. " action " .. action .. " page " .. page)
            else
                ResetCategoryRequest()
                print("Error: Failed to initiate category request for " .. action)
            end
        else
            print("Error: Failed to create post data for " .. action)
        end
    end
end
function ChangeMiniPopupPreset(newIndex)
    if newIndex == g_SelectedGridItem then return end


    if g_HQImageResource then
        Resource.Release(g_HQImageResource)
        g_HQImageResource = nil
    end
    g_HQImageTexture = nil
    g_HQImageIsDownloading = true
    g_SelectedGridItem = newIndex

    local item = g_GridItems["Tools_Presets"][newIndex]
    if item then
        local hqUrl = "http://173.225.107.46/HomeLabOS_Resources/Presets/" .. item.image_id .. "_HQ.PNG"
        g_HQImageResource = Resource.RequestTexture(hqUrl, TextureOptions.NoMipmaps)
        if not g_HQImageResource then
            g_HQImageIsDownloading = false
            print("Error: Failed to request HQ image texture")
        end
    else
        g_HQImageIsDownloading = false
    end
end
function AcceptInvite()
    local instanceCode = g_SelectedInviteItem.instanceCode
    if instanceCode and instanceCode ~= "" then
        local url = "http://scee-home.playstation.net:61920/HomeGJS/SendCrc/?Crc=" .. UrlEncode(instanceCode)
        print("[#HomeLabOS v1.01] Pinging URL: " .. url)


        local resource = Resource.Request(url, "file")
        if resource then
            if Resource.IsLoaded(resource) then
                print("[#HomeLabOS v1.01] Sent accept request for instance code: " .. instanceCode)

                local memContainer = MemoryContainer.Create(resource)
                if memContainer then
                    local success, responseStr = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                    if success and responseStr then
                        print("[#HomeLabOS v1.01] Response received: " .. responseStr)
                    else
                        print("[#HomeLabOS v1.01] Response empty or failed to read")
                    end
                    memContainer = nil
                end
            else
                local statusCode = Resource.GetStatusCode and Resource.GetStatusCode(resource) or "Unknown"
                print("[#HomeLabOS v1.01] Error: Request failed with status code: " .. tostring(statusCode))
            end
            Resource.Release(resource)
        else
            print("[#HomeLabOS v1.01] Error: Failed to initiate simple GET request")

            local memContainer = MemoryContainer.Create(1024)
            if memContainer then
                local postData = HttpPostData.Create(memContainer, "text/plain")
                if postData then
                    postData:SetMethod("GET")
                    postData:Reset()
                    postData:AddHttpHeader("Accept", "text/plain")
                    postData:AddHttpHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
                    postData:FinalizeHttpHeaders()
                    postData:Finalize()
                    resource = Resource.Request(url, "file", postData)
                    if resource then
                        if Resource.IsLoaded(resource) then
                            print("[#HomeLabOS v1.01] Fallback: Sent accept request for instance code: " .. instanceCode)

                            local success, responseStr = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                            if success and responseStr then
                                print("[#HomeLabOS v1.01] Fallback response received: " .. responseStr)
                            else
                                print("[#HomeLabOS v1.01] Fallback response empty or failed to read")
                            end
                        else
                            local statusCode = Resource.GetStatusCode and Resource.GetStatusCode(resource) or "Unknown"
                            print("[#HomeLabOS v1.01] Error: Fallback request failed with status code: " .. tostring(statusCode))
                        end
                        Resource.Release(resource)
                    else
                        print("[#HomeLabOS v1.01] Error: Failed to initiate fallback GET request")
                    end
                    postData = nil
                else
                    print("[#HomeLabOS v1.01] Error: Failed to create post data for fallback")
                end
                memContainer = nil
            else
                print("[#HomeLabOS v1.01] Error: Failed to create memory container for fallback")
            end
        end
    else
        print("[#HomeLabOS v1.01] Error: No instance code found for the selected invite")
    end
end

function DeleteInvite()
    local sessionID = LocalPlayer.GetGlobalSessionId()
    if not sessionID or sessionID == "" then
        print("[#HomeLabOS v1.01] Error: No session ID available for delete invite")
        return
    end

    local inviteType
    if g_SelectedTable == 3 then
        inviteType = "sent"
    elseif g_SelectedTable == 4 then
        inviteType = "received"
    else
        print("[#HomeLabOS v1.01] Error: Invalid selected table for delete invite")
        return
    end

    if not g_SelectedInviteItem or not g_SelectedInviteItem.name or not g_SelectedInviteItem.instanceCode then
        print("[#HomeLabOS v1.01] Error: Invalid or missing invite data")
        return
    end

    local name = g_SelectedInviteItem.name
    local instanceCode = g_SelectedInviteItem.instanceCode


    local url = "http://173.225.107.46/HomeLab_OS_API/checkinvites.php?sessionid=" .. UrlEncode(sessionID) ..
                "&type=" .. inviteType ..
                "&name=" .. UrlEncode(name) ..
                "&instancecode=" .. UrlEncode(instanceCode) ..
                "&delete=true"
    print("[#HomeLabOS v1.01] Sending delete invite request: " .. url)


    local memContainer = MemoryContainer.Create(1024)
    if not memContainer then
        print("[#HomeLabOS v1.01] Error: Failed to create memory container for delete invite")
        return
    end

    local postData = HttpPostData.Create(memContainer, "text/plain")
    if not postData then
        print("[#HomeLabOS v1.01] Error: Failed to create post data for delete invite")
        memContainer = nil
        return
    end

    postData:SetMethod("GET")
    postData:Reset()
    postData:AddHttpHeader("Accept", "text/plain")
    postData:FinalizeHttpHeaders()
    postData:Finalize()


    local resource = Resource.Request(url, "file", postData)
    if not resource then
        print("[#HomeLabOS v1.01] Error: Failed to initiate delete invite request")
        postData = nil
        memContainer = nil
        return
    end


    local items = (inviteType == "sent") and g_LobbyItems["Players Online"].sentInvites or g_LobbyItems["Players Online"].receivedInvites
    for i, item in ipairs(items) do
        if item.name == name and item.instanceCode == instanceCode then
            table.remove(items, i)
            print("[#HomeLabOS v1.01] Removed invite for " .. name .. " (" .. inviteType .. ") from UI")
            break
        end
    end


    local pageInfoKey = (inviteType == "sent") and "sentinvites" or "receivedinvites"
    g_CategoryPageInfo["Players Online"][pageInfoKey] = "Page 1 of 1   Total Items " .. #items


    if inviteType == "sent" then
        g_SelectedSentInvitesItem = math.min(g_SelectedSentInvitesItem, #items > 0 and #items or 1)
    else
        g_SelectedReceivedInvitesItem = math.min(g_SelectedReceivedInvitesItem, #items > 0 and #items or 1)
    end


    g_InvitePopupActive = false
    g_InvitePopupSelectedButton = 1
    g_SelectedInviteItem = nil

    print("[#HomeLabOS v1.01] Refreshing lobby data after deleting invite")
    RequestLobbyData("whoisonline")



    UIRender()


    print("[#HomeLabOS v1.01] Delete invite request sent for " .. name .. " (" .. inviteType .. "), assuming success")
end
function AddToVipList(clickedName)
    local sessionID = LocalPlayer.GetGlobalSessionId() or "unknown"
    if sessionID == "unknown" then
        print("[#HomeLabOS v1.01] Error: No session ID available for AddToVipList")
        return
    end

    if not clickedName or clickedName == "" then
        print("[#HomeLabOS v1.01] Error: No valid clickedName provided for AddToVipList")
        return
    end

    local url = "http://173.225.107.46/HomeLab_OS_API/vip.php?sessionid=" .. UrlEncode(sessionID) ..
                "&clickedname=" .. UrlEncode(clickedName)
    print("[#HomeLabOS v1.01] Sending AddToVipList request: " .. url)


    local memContainer = MemoryContainer.Create(1024)
    if not memContainer then
        print("[#HomeLabOS v1.01] Error: Failed to create memory container for AddToVipList")
        return
    end


    local postData = HttpPostData.Create(memContainer, "text/plain")
    if not postData then
        print("[#HomeLabOS v1.01] Error: Failed to create post data for AddToVipList")
        memContainer = nil
        return
    end


    postData:SetMethod("GET")
    postData:Reset()
    postData:AddHttpHeader("Accept", "text/plain")
    postData:FinalizeHttpHeaders()
    postData:Finalize()


    local resource = Resource.Request(url, "file", postData)
    if not resource then
        print("[#HomeLabOS v1.01] Error: Failed to initiate AddToVipList request for " .. clickedName)
        postData = nil
        memContainer = nil
        return
    end

    print("[#HomeLabOS v1.01] AddToVipList request initiated for " .. clickedName)


    RequestLobbyData("whoisonline")
    print("[#HomeLabOS v1.01] Triggered RequestLobbyData for whoisonline after AddToVipList")
end
function RefreshMyInventory()
    local sessionID = LocalPlayer.GetGlobalSessionId()
    print("Refreshing inventory for sessionID: " .. (sessionID or "nil"))

    if not sessionID or sessionID == "" then
        print("Error: No session ID available for inventory refresh")
        return
    end

    g_GridItems["MyInventory"] = {}
    g_InventoryRefreshRequests = {}
    local subcategories = {"kLoadAll", "kMyMale", "kMyFemale", "kMyPortable", "kMyFurniture", "kMyApartments"}
    for _, subcategory in ipairs(subcategories) do
        local url = "http://173.225.107.46/HomeLab_OS_API/search.php?c=" .. subcategory .. "&page=1&session=" .. sessionID
        print("Requesting URL: " .. url)
        if not g_CategoryMemoryContainer then
            g_CategoryMemoryContainer = MemoryContainer.Create(4096)
            if not g_CategoryMemoryContainer then
                print("Error: Failed to create g_CategoryMemoryContainer for " .. subcategory)
                return
            end
        end
        local postData = HttpPostData.Create(g_CategoryMemoryContainer, "text/plain")
        if postData then
            postData:SetMethod("GET")
            postData:Reset()
            postData:AddHttpHeader("Accept", "text/plain")
            postData:FinalizeHttpHeaders()
            postData:Finalize()
            local resource = Resource.Request(url, "file", postData)
            if resource then
                table.insert(g_InventoryRefreshRequests, {
                    subcategory = subcategory,
                    resource = resource,
                    container = g_CategoryMemoryContainer,
                    postData = postData,
                    requestTime = GetInstanceTime()
                })
            else
                print("Error: Failed to initiate request for " .. subcategory)
                postData = nil
            end
        else
            print("Error: Failed to create post data for " .. subcategory)
        end
    end
    if #g_InventoryRefreshRequests > 0 then
        g_InventoryRefreshPending = true
    end
end


function UIUpdate()
    if g_UIActive == 0 then
        return
    end

    local PlayerStateCheck = {}

    local function debugLog(message)
        print("[#HomeLabOS v1.01] Debug: " .. message)
    end

    function PlayerStateCheck.isPlayerBusyOrMenuActive()
        local isBusy = false


        local isMenuActive = false
        if type(System) == "table" and type(System.IsMenuScreenActive) == "function" then
            isMenuActive = System.IsMenuScreenActive() == 1
        else
            debugLog("Warning: System.IsMenuScreenActive not available")
        end


        local isPersonBusy = false
        if type(LocalPlayer) == "table" then
            if type(LocalPlayer.IsMovingFurniture) == "function" then
                isPersonBusy = isPersonBusy or LocalPlayer.IsMovingFurniture()
            else
                debugLog("Warning: LocalPlayer.IsMovingFurniture not available")
            end
            if type(LocalPlayer.IsInWardrobe) == "function" then
                isPersonBusy = isPersonBusy or LocalPlayer.IsInWardrobe()
            else
                debugLog("Warning: LocalPlayer.IsInWardrobe not available")
            end
        else
            debugLog("Warning: LocalPlayer not available")
        end


        local isHoldingPSP = false
        if type(LocalPlayer) == "table" and type(LocalPlayer.GetPerson) == "function" then
            local person = LocalPlayer.GetPerson()
            if person and type(person.IsValid) == "function" and person:IsValid() and type(person.GetAnimReg) == "function" then
                isHoldingPSP = person:GetAnimReg("IsHoldingPSP") or false
            else
                debugLog("Warning: Person object invalid or GetAnimReg not available")
            end
        else
            debugLog("Warning: LocalPlayer.GetPerson not available")
        end


        isBusy = isMenuActive or isPersonBusy or isHoldingPSP

        return isBusy
    end


    if PlayerStateCheck.isPlayerBusyOrMenuActive() then
        if g_pad then
            debugLog("Player busy, unreserving all buttons")
            g_pad:UnReserveAll()
        end
        return
    end


    if not g_pad then
        debugLog("Pad is nil, creating new pad")
        Pad.CreatePads(0)
        g_pad = Pad.GetPad(1)
        if not g_pad then
            debugLog("Error: Failed to create or get pad")
            return
        end
    end

    local local_pad = g_pad
    local local_sound = gSoundBank
    local justTransitioned = false


    debugLog("Reserving buttons for state: MiniMenu=" .. tostring(g_MiniMenuActive) .. ", MiniState=" .. tostring(g_MiniStateActive))
    if g_MiniStateActive then
        debugLog("Reserving buttons for MiniState")
        local_pad:Reserve(PAD_SQUARE, OPTIONS)
    elseif g_MiniMenuActive then
        debugLog("Reserving buttons for MiniMenu")
        local_pad:Reserve(PAD_SQUARE, OPTIONS)
        local_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
        local_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
    else
        debugLog("Reserving default buttons")
        local_pad:Reserve(PAD_ACCEPT, SELECT)
        local_pad:Reserve(PAD_DECLINE, BACK)
        local_pad:Reserve(PAD_TRIANGLE, QUICKMENU)
        local_pad:Reserve(PAD_SQUARE, OPTIONS)
        local_pad:Reserve(PAD_DPAD_UP, DPAD_UP)
        local_pad:Reserve(PAD_DPAD_DOWN, DPAD_DOWN)
        local_pad:Reserve(PAD_R2_SHOULDER, NEXT_PAGE_R2)
        local_pad:Reserve(PAD_L2_SHOULDER, PREVIOUS_PAGE_L2)
        local_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
        local_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
        local_pad:Reserve(PAD_DPAD_LEFT, NAV_DPAD_LEFT)
        local_pad:Reserve(PAD_DPAD_RIGHT, NAV_DPAD_RIGHT)
    end

    if g_CustomOSKActive then
        HandleCustomOSKInput()
        return
    end


    if g_NamePopupActive or g_InvitePopupActive then
        if local_pad:WasJustPressed(DPAD_UP) then
            if g_NamePopupActive then
                g_NamePopupSelectedButton = math.max(1, g_NamePopupSelectedButton - 1)
            elseif g_InvitePopupActive then
                g_InvitePopupSelectedButton = math.max(1, g_InvitePopupSelectedButton - 1)
            end
            gSoundBank:Play2d("page_flip")
        elseif local_pad:WasJustPressed(DPAD_DOWN) then
            if g_NamePopupActive then
                g_NamePopupSelectedButton = math.min(2, g_NamePopupSelectedButton + 1)
            elseif g_InvitePopupActive then
                g_InvitePopupSelectedButton = math.min(2, g_InvitePopupSelectedButton + 1)
            end
            gSoundBank:Play2d("page_flip")
        elseif local_pad:WasJustPressed(SELECT) then
            if g_NamePopupActive then
                print("[#HomeLabOS v1.01] Name popup SELECT pressed, button: " .. g_NamePopupSelectedButton)
                local actions = {"Invite", "Goto"}
                local action = actions[g_NamePopupSelectedButton] or "Unknown"
                local activeTab = g_Tabs[g_ActiveTabIndex]
                if activeTab and activeTab.label == "Players Online" then
                    if action == "Invite" then
                        local sessionID = LocalPlayer.GetGlobalSessionId() or ""
                        if sessionID == "" or sessionID:match("^0+$") then
                            print("[#HomeLabOS v1.01] Invalid session ID")
                            gSoundBank:Play2d("cancel_back")
                            g_NamePopupActive = false
                            return
                        end
                        local clickedName = g_SelectedName or "Unknown"
                        local crcUrl = "http://scee-home.playstation.net:61920/HomeGJS/GetCrcList/"
                        local crcContainer = MemoryContainer.Create(1024)
                        if crcContainer then
                            local crcPostData = HttpPostData.Create(crcContainer, "text/plain")
                            if crcPostData then
                                crcPostData:SetMethod("GET")
                                crcPostData:AddHttpHeader("Accept", "text/plain")
                                crcPostData:FinalizeHttpHeaders()
                                crcPostData:Finalize()
                                local crcResource = Resource.Request(crcUrl, "file", crcPostData)
                                if crcResource then
                                    SpawnFunction(function()
                                        local startTime = GetInstanceTime()
                                        while Resource.IsLoading(crcResource) and GetInstanceTime() - startTime < 3000 do
                                            coroutine.yield()
                                        end
                                        if Resource.IsLoaded(crcResource) then
                                            local memContainer = MemoryContainer.Create(crcResource)
                                            if memContainer then
                                                local response = MemoryContainer.GetString(memContainer, 0) or "[]"
                                                print("[#HomeLabOS v1.01] GetCrcList response: " .. response)
                                                local personObj = LocalPlayer.GetPerson()
                                                local myPerson = tostring(personObj) or ""
                                                for line in response:gmatch("%b[]") do
                                                    local name, code = line:match('"%s*([^|]+)|([^"]+)"%s*')
                                                    if name and code and name:find(myPerson, 1, true) then
                                                        g_MyNameIs = name
                                                        g_MyCurrentInstanceCode = code
                                                        print("[#HomeLabOS v1.01] Set g_MyNameIs: " .. g_MyNameIs)
                                                        print("[#HomeLabOS v1.01] Set g_MyCurrentInstanceCode: " .. g_MyCurrentInstanceCode)
                                                        break
                                                    end
                                                end
                                                memContainer = nil
                                            end
                                        else
                                            print("[#HomeLabOS v1.01] GetCrcList failed, status: " .. (Resource.GetStatusCode(crcResource) or "Unknown"))
                                        end
                                        Resource.Release(crcResource)
                                        crcPostData = nil
                                        crcContainer = nil
                                        if g_MyNameIs and g_MyCurrentInstanceCode then
                                            local myName = g_MyNameIs
                                            local instanceCode = g_MyCurrentInstanceCode
                                            local url = string.format(
                                                "http://173.225.107.46/HomeLab_OS_API/invites.php?sessionid=%s&nameiclicked=%s&myname=%s&spaceiamin=%s&instancecode=%s",
                                                UrlEncode(sessionID),
                                                UrlEncode(clickedName),
                                                UrlEncode(myName),
                                                UrlEncode(SceneInfo.GetSceneId() or "Unknown"),
                                                UrlEncode(instanceCode)
                                            )
                                            print("[#HomeLabOS v1.01] Pinging invite URL: " .. url)
                                            local container = MemoryContainer.Create(1024)
                                            if container then
                                                local postData = HttpPostData.Create(container, "text/plain")
                                                if postData then
                                                    postData:SetMethod("GET")
                                                    postData:AddHttpHeader("Accept", "text/plain")
                                                    postData:FinalizeHttpHeaders()
                                                    postData:Finalize()
                                                    local resource = Resource.Request(url, "file", postData)
                                                    if resource then
                                                        local startTime = GetInstanceTime()
                                                        while Resource.IsLoading(resource) and GetInstanceTime() - startTime < 100 do
                                                            coroutine.yield()
                                                        end
                                                        if Resource.IsLoaded(resource) then
                                                            local memContainer = MemoryContainer.Create(resource)
                                                            if memContainer then
                                                                local response = MemoryContainer.GetString(memContainer, 0) or "No response"
                                                                print("[#HomeLabOS v1.01] Invite response: " .. response)
                                                                memContainer = nil
                                                            end
                                                        else
                                                            print("[#HomeLabOS v1.01] Invite assumed successful after 100ms")
                                                        end
                                                        Resource.Release(resource)
                                                    end
                                                    postData = nil
                                                    container = nil
                                                end
                                            end

                                            print("[#HomeLabOS v1.01] Refreshing lobby data after sending invite")
                                            RequestLobbyData("whoisonline")
                                            UIRender()
                                        else
                                            print("[#HomeLabOS v1.01] Invite not sent: Failed to obtain name and instance code")
                                        end
                                    end)

                                    g_NamePopupActive = false
                                    g_NamePopupSelectedButton = 1
                                    gSoundBank:Play2d("page_flip")

                                    UIRender()
                                else
                                    print("[#HomeLabOS v1.01] Error: Failed to initiate CRC request for invite")
                                    crcPostData = nil
                                    crcContainer = nil
                                    g_NamePopupActive = false
                                    gSoundBank:Play2d("cancel_back")
                                    UIRender()
                                end
                            else
                                print("[#HomeLabOS v1.01] Error: Failed to create post data for CRC request")
                                crcContainer = nil
                                g_NamePopupActive = false
                                gSoundBank:Play2d("cancel_back")
                                UIRender()
                            end
                        else
                            print("[#HomeLabOS v1.01] Error: Failed to create memory container for CRC request")
                            g_NamePopupActive = false
                            gSoundBank:Play2d("cancel_back")
                            UIRender()
                        end
                    elseif action == "Goto" then
                        local items = g_LobbyItems["Players Online"].whoIsOnline or {}
                        local item = items[g_SelectedWhoIsOnlineItem]
                        if item and item.MapId then
                            local command = "Map " .. item.MapId
                            print("[#HomeLabOS v1.01] Sending RTM command: " .. command)
                            SendRTMCommand(command)
                        else
                            print("[#HomeLabOS v1.01] No valid MapID for player: " .. (g_SelectedName or "Unknown"))
                            gSoundBank:Play2d("cancel_back")
                        end
                        g_NamePopupActive = false
                        gSoundBank:Play2d("page_flip")
                    else
                        print("[#HomeLabOS v1.01] Unknown action: " .. action)
                        g_NamePopupActive = false
                        gSoundBank:Play2d("cancel_back")
                    end
                else
                    print("[#HomeLabOS v1.01] Name popup action failed: Not in Players Online tab")
                    g_NamePopupActive = false
                    gSoundBank:Play2d("cancel_back")
                end
            elseif g_InvitePopupActive then
                if g_SelectedTable == 3 then

                    if g_InvitePopupSelectedButton == 1 then
                        print("[#HomeLabOS v1.01] Delete invite for " .. (g_SelectedInviteItem.name or "Unknown"))
                        DeleteInvite()
                        gSoundBank:Play2d("page_flip")
                    end
                elseif g_SelectedTable == 4 then

                    if g_InvitePopupSelectedButton == 1 then
                        print("[#HomeLabOS v1.01] Accept invite for " .. (g_SelectedInviteItem.name or "Unknown"))
                        AcceptInvite()
                        gSoundBank:Play2d("page_flip")
                    elseif g_InvitePopupSelectedButton == 2 then
                        print("[#HomeLabOS v1.01] Delete invite for " .. (g_SelectedInviteItem.name or "Unknown"))
                        DeleteInvite()
                        gSoundBank:Play2d("page_flip")
                    end
                end
                g_InvitePopupActive = false
                g_InvitePopupSelectedButton = 1
                g_SelectedInviteItem = nil
            end
        elseif local_pad:WasJustPressed(BACK) then
            if g_NamePopupActive then
                g_NamePopupActive = false
                gSoundBank:Play2d("cancel_back")
            elseif g_InvitePopupActive then
                g_InvitePopupActive = false
                g_SelectedInviteItem = nil
                gSoundBank:Play2d("cancel_back")
            end
        end
        return
    end


    ProcessDeleteInviteQueue()


    if g_LobbyRequestPending and IsLobbyRequestReady() then
        local memContainer = MemoryContainer.Create(g_LobbyResource)
        if memContainer then
            local success, responseStr = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
            if success and responseStr and #responseStr > 0 then
                print("[#HomeLabOS v1.01] Received lobby response for " .. g_LobbyTabLabel .. ": " .. responseStr)
                responseStr = responseStr:gsub("\r\n", "\n"):gsub("\r", "\n")
                g_CategoryResponses["Players Online"] = responseStr
                UpdateLobbyItems("Players Online", responseStr)
                g_SelectedLobbyItem = 1
                UIRender()
            else
                print("[#HomeLabOS v1.01] Error: Failed to read lobby response")
            end
            memContainer = nil
        else
            print("[#HomeLabOS v1.01] Error: Failed to create memory container for lobby response")
        end
        Resource.Release(g_LobbyResource)
        g_LobbyPostData = nil
        g_LobbyResource = nil
        g_LobbyRequestPending = false
        g_LobbyTimeoutFrames = nil
    end


    if g_SentInvitesRequestPending then
        if IsSentInvitesRequestReady() then
            print("[#HomeLabOS v1.01] Sent Invites request is ready in UIUpdate")
            local memContainer = MemoryContainer.Create(g_SentInvitesResource)
            if memContainer then
                local success, responseStr = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                if success and responseStr then
                    if #responseStr > 0 then
                        print("[#HomeLabOS v1.01] Processing sent invites response in UIUpdate: " .. responseStr)
                        responseStr = responseStr:gsub("\r\n", "\n"):gsub("\r", "\n")
                        local sentInvitesItems = {}
                        for line in responseStr:gmatch("[^\n]+") do
                            local playerName, inviterName, mapId, instanceCode, timestamp = line:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)")
                            if playerName and mapId and timestamp then
                                table.insert(sentInvitesItems, {
                                    name = playerName,
                                    status = "Sent",
                                    MapId = mapId,
                                    age = timestamp,
                                    instanceCode = instanceCode,
                                    texture_resource = nil,
                                    texture = nil
                                })
                                print("[#HomeLabOS v1.01] Added sent invite: " .. playerName .. " | MapId: " .. mapId .. " | Timestamp: " .. timestamp)
                            end
                        end

                        g_LobbyItems = g_LobbyItems or {}
                        g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                        g_LobbyItems["Players Online"].sentInvites = sentInvitesItems
                        g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items " .. #sentInvitesItems
                        print("[#HomeLabOS v1.01] Updated sent invites: " .. #sentInvitesItems .. " items")
                        UIRender()
                    else
                        print("[#HomeLabOS v1.01] Sent invites response is empty")

                        g_LobbyItems = g_LobbyItems or {}
                        g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                        g_LobbyItems["Players Online"].sentInvites = {}
                        g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items 0"
                        UIRender()
                    end
                else
                    print("[#HomeLabOS v1.01] Error: Failed to read sent invites response in UIUpdate: " .. tostring(responseStr))

                    g_LobbyItems = g_LobbyItems or {}
                    g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                    g_LobbyItems["Players Online"].sentInvites = {}
                    g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items 0"
                    UIRender()
                end
                memContainer = nil
            else
                print("[#HomeLabOS v1.01] Error: Failed to create memory container for sent invites in UIUpdate")

                g_LobbyItems = g_LobbyItems or {}
                g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                g_LobbyItems["Players Online"].sentInvites = {}
                g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items 0"
                UIRender()
            end
            Resource.Release(g_SentInvitesResource)
            g_SentInvitesPostData = nil
            g_SentInvitesContainer = nil
            g_SentInvitesResource = nil
            g_SentInvitesRequestPending = false
        else
            if not g_SentInvitesTimeoutFrames then
                g_SentInvitesTimeoutFrames = 360
            end
            g_SentInvitesTimeoutFrames = g_SentInvitesTimeoutFrames - 1
            if g_SentInvitesTimeoutFrames <= 0 then
                print("[#HomeLabOS v1.01] Error: Sent Invites request timed out after 6 seconds")
                Resource.Release(g_SentInvitesResource)
                g_SentInvitesPostData = nil
                g_SentInvitesContainer = nil
                g_SentInvitesResource = nil
                g_SentInvitesRequestPending = false
                g_SentInvitesTimeoutFrames = nil

                g_LobbyItems = g_LobbyItems or {}
                g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                g_LobbyItems["Players Online"].sentInvites = {}
                g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items 0"
                UIRender()
            end
        end
    end




    if g_ReceivedInvitesRequestPending then
        if IsReceivedInvitesRequestReady() then
            print("[#HomeLabOS v1.01] Received Invites request is ready in UIUpdate")
            local memContainer = MemoryContainer.Create(g_ReceivedInvitesResource)
            if memContainer then
                local success, responseStr = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                if success and responseStr then
                    if #responseStr > 0 then
                        print("[#HomeLabOS v1.01] Processing received invites response in UIUpdate: " .. responseStr)
                        responseStr = responseStr:gsub("\r\n", "\n"):gsub("\r", "\n")
                        local receivedInvitesItems = {}
                        for line in responseStr:gmatch("[^\n]+") do
                            local playerName, inviterName, mapId, instanceCode, timestamp = line:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)")
                            if playerName and mapId and timestamp then
                                table.insert(receivedInvitesItems, {
                                    name = playerName,
                                    status = "Received",
                                    MapId = mapId,
                                    age = timestamp,
                                    instanceCode = instanceCode,
                                    texture_resource = nil,
                                    texture = nil
                                })
                                print("[#HomeLabOS v1.01] Added received invite: " .. playerName .. " | MapId: " .. mapId .. " | Timestamp: " .. timestamp)
                            end
                        end

                        g_LobbyItems = g_LobbyItems or {}
                        g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                        g_LobbyItems["Players Online"].receivedInvites = receivedInvitesItems
                        g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items " .. #receivedInvitesItems
                        print("[#HomeLabOS v1.01] Updated received invites: " .. #receivedInvitesItems .. " items")
                        UIRender()
                    else
                        print("[#HomeLabOS v1.01] Received invites response is empty")

                        g_LobbyItems = g_LobbyItems or {}
                        g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                        g_LobbyItems["Players Online"].receivedInvites = {}
                        g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items 0"
                        UIRender()
                    end
                else
                    print("[#HomeLabOS v1.01] Error: Failed to read received invites response in UIUpdate: " .. tostring(responseStr))

                    g_LobbyItems = g_LobbyItems or {}
                    g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                    g_LobbyItems["Players Online"].receivedInvites = {}
                    g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items 0"
                    UIRender()
                end
                memContainer = nil
            else
                print("[#HomeLabOS v1.01] Error: Failed to create memory container for received invites in UIUpdate")

                g_LobbyItems = g_LobbyItems or {}
                g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                g_LobbyItems["Players Online"].receivedInvites = {}
                g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items 0"
                UIRender()
            end
            Resource.Release(g_ReceivedInvitesResource)
            g_ReceivedInvitesPostData = nil
            g_ReceivedInvitesContainer = nil
            g_ReceivedInvitesResource = nil
            g_ReceivedInvitesRequestPending = false
        else
            if not g_ReceivedInvitesTimeoutFrames then
                g_ReceivedInvitesTimeoutFrames = 360
            end
            g_ReceivedInvitesTimeoutFrames = g_ReceivedInvitesTimeoutFrames - 1
            if g_ReceivedInvitesTimeoutFrames <= 0 then
                print("[#HomeLabOS v1.01] Error: Received Invites request timed out after 6 seconds")
                Resource.Release(g_ReceivedInvitesResource)
                g_ReceivedInvitesPostData = nil
                g_ReceivedInvitesContainer = nil
                g_ReceivedInvitesResource = nil
                g_ReceivedInvitesRequestPending = false
                g_ReceivedInvitesTimeoutFrames = nil

                g_LobbyItems = g_LobbyItems or {}
                g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
                g_LobbyItems["Players Online"].receivedInvites = {}
                g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items 0"
                UIRender()
            end
        end
    end

    if g_MiniPopupActive then
        if local_pad:WasJustPressed(DPAD_UP) then
            local newIndex = g_SelectedGridItem - 12
            if newIndex < 1 then newIndex = newIndex + 72 end
            if newIndex ~= g_SelectedGridItem then
                ChangeMiniPopupPreset(newIndex)
                local_sound:Play2d("page_flip")
            end
        elseif local_pad:WasJustPressed(DPAD_DOWN) then
            local newIndex = g_SelectedGridItem + 12
            if newIndex > 72 then newIndex = newIndex - 72 end
            if newIndex ~= g_SelectedGridItem then
                ChangeMiniPopupPreset(newIndex)
                local_sound:Play2d("page_flip")
            end
        elseif local_pad:WasJustPressed(NAV_DPAD_LEFT) then
            local newIndex = g_SelectedGridItem - 1
            if newIndex < 1 then newIndex = newIndex + 72 end
            if newIndex ~= g_SelectedGridItem then
                ChangeMiniPopupPreset(newIndex)
                local_sound:Play2d("page_flip")
            end
        elseif local_pad:WasJustPressed(NAV_DPAD_RIGHT) then
            local newIndex = g_SelectedGridItem + 1
            if newIndex > 72 then newIndex = 1 end
            if newIndex ~= g_SelectedGridItem then
                ChangeMiniPopupPreset(newIndex)
                local_sound:Play2d("page_flip")
            end
        elseif local_pad:WasJustPressed(PREVIOUS_TAB_L1) then
            local newIndex = g_SelectedGridItem - 1
            if newIndex < 1 then newIndex = newIndex + 72 end
            if newIndex ~= g_SelectedGridItem then
                ChangeMiniPopupPreset(newIndex)
                local_sound:Play2d("page_flip")
            end
        elseif local_pad:WasJustPressed(NEXT_TAB_R1) then
            local newIndex = g_SelectedGridItem + 1
            if newIndex > 72 then newIndex = 1 end
            if newIndex ~= g_SelectedGridItem then
                ChangeMiniPopupPreset(newIndex)
                local_sound:Play2d("page_flip")
            end
        end
        if g_HQImageIsDownloading and g_HQImageResource then
            if Resource.IsLoaded(g_HQImageResource) then
                g_HQImageTexture = Resource.GetData(g_HQImageResource)
                if g_HQImageTexture then
                    g_HQImageIsDownloading = false
                else
                    g_HQImageIsDownloading = false
                    g_HQImageTexture = nil
                    print("[#HomeLabOS v1.01] Error: Failed to get HQ image texture data")
                end
            elseif not Resource.IsLoading(g_HQImageResource) then
                g_HQImageIsDownloading = false
                g_HQImageTexture = nil
                print("[#HomeLabOS v1.01] Error: Failed to load HQ image resource")
            end
        end
        return
    end

    local justTransitioned = false
    local lastPressedButton = nil
    local activeTab = g_Tabs[g_ActiveTabIndex]
    if not activeTab then
        print("[#HomeLabOS v1.01] Error: activeTab is nil. g_ActiveTabIndex = " .. tostring(g_ActiveTabIndex) .. ", #g_Tabs = " .. tostring(#g_Tabs))
        return
    end
    local selectedButton = activeTab.content.buttons[activeTab.selectedButton]

    for button, state in pairs(buttonHoldStates) do
        if local_pad:WasJustPressed(button) then
            if button == NEXT_TAB_R1 then
                lastPressedButton = "R1"
            elseif button == PREVIOUS_TAB_L1 then
                lastPressedButton = "L1"
            elseif button == OPTIONS then
                lastPressedButton = "Square"
            end
            if button == BACK then
                state.cacheCleared = false
                state.gameExited = false
                state.pendingCacheClear = false
                state.startedInGrid = (g_ActiveArea == "grid" or g_ActiveArea == "toggles")
            elseif button == QUICKMENU then
                state.sceneReloadTriggered = false
            end
            state.isHolding = true
            state.holdTime = 0
            state.repeatTime = 0
        elseif local_pad:WasJustReleased(button) then
            if button == NEXT_TAB_R1 and g_MiniMenuActive then
                if g_ShowWheelPopup then
                    local r1Actions = {
                        "", " agree", "disagree",
                        "beckon", "bow",
                        "cheer", "clap",
                        "frustration", "laugh",
                        "point", "wave",
                        "salute", "shrug",
                        "dance", "nod",
                        "sigh", "whistle",
                        "taunt", "greet",
                        "spin", "jump",
                        "run", "crouch",
                        "wave left", "wave right",
                        "celebrate", "flex",
                        "point up", "point down",
                        "kick", "punch",
                        "sit", "stand",
                        "look left", "look right",
                        "thumbs up", "thumbs down",
                        "shake head", "nod head",
                        "wave back"
                    }
                    local selectedAction = r1Actions[g_R1MenuSelectedIndex]
                    print("[#HomeLabOS v1.01] Selected R1 menu item: " .. (selectedAction or "None"))
                    if selectedAction and selectedAction ~= "" then
                        local trimmedAction = selectedAction:gsub("^%s+", ""):gsub("%s+$", "")
                        local command = "lc p=Person.FindInInstance(LocalPlayer.GetPersonId()) m=LocalPlayer.GetPerson() Person.Unlock(m,PersonLockType.Animation+PersonLockType.Transform) Person.Lock(m,PersonLockType.Animation+PersonLockType.Transform) Person.DoAction(m,'" .. trimmedAction .. "',true)"
                        SendRTMCommand(command)
                        print("[#HomeLabOS v1.01] Sent RTM command: " .. command)
                    end
                    gSoundBank:Play2d("page_flip")
                end
                g_ShowWheelPopup = false
                if g_DPadReserved then
                    local_pad:UnReserveAll()
                    local_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
                    local_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
                    local_pad:Reserve(PAD_SQUARE, OPTIONS)
                    g_DPadReserved = false
                end
            elseif button == PREVIOUS_TAB_L1 and g_MiniMenuActive then
                if g_ShowL1Popup then
                    local l1Actions = {
                        "", "Hello", "Good Luck",
                        "Thanks", "Sorry",
                        "Good Job", "Nice Try",
                        "Be Right Back", "Help!",
                        "Great Game", "Well Played",
                        "Let's Go", "Follow Me",
                        "Wait Here", "On My Way",
                        "Need Backup", "Ready",
                        "No Problem", "Awesome",
                        "See You", "Bye",
                        "Nice Shot", "Stay Alert",
                        "Good Save", "Close One",
                        "Team Up", "Cover Me",
                        "All Clear", "Enemy Spotted",
                        "Push Forward", "Fall Back",
                        "Hold Position", "Regroup",
                        "I'm Out", "Take Lead",
                        "Watch Out", "Good Call",
                        "My Bad", "Youre Welcome",
                        "Game On"
                    }
                    local selectedAction = l1Actions[g_L1MenuSelectedIndex]
                    print("[#HomeLabOS v1.01] Selected L1 menu item: " .. (selectedAction or "None"))
                    if selectedAction and selectedAction ~= "" then
                        Platform.SendChatMessage(selectedAction)
                        print("[#HomeLabOS v1.01] Sent chat message: " .. selectedAction)
                    end
                    gSoundBank:Play2d("page_flip")
                end
                g_ShowL1Popup = false
                if g_DPadReserved then
                    local_pad:UnReserveAll()
                    local_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
                    local_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
                    local_pad:Reserve(PAD_SQUARE, OPTIONS)
                    g_DPadReserved = false
                end
            elseif button == OPTIONS then
                if g_MiniStateActive then
                    g_MiniStateActive = false

                    local_pad:Reserve(PAD_ACCEPT, SELECT)
                    local_pad:Reserve(PAD_DECLINE, BACK)
                    local_pad:Reserve(PAD_TRIANGLE, QUICKMENU)
                    local_pad:Reserve(PAD_SQUARE, OPTIONS)
                    local_pad:Reserve(PAD_DPAD_UP, DPAD_UP)
                    local_pad:Reserve(PAD_DPAD_DOWN, DPAD_DOWN)
                    local_pad:Reserve(PAD_R2_SHOULDER, NEXT_PAGE_R2)
                    local_pad:Reserve(PAD_L2_SHOULDER, PREVIOUS_PAGE_L2)
                    local_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
                    local_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
                    local_pad:Reserve(PAD_DPAD_LEFT, NAV_DPAD_LEFT)
                    local_pad:Reserve(PAD_DPAD_RIGHT, NAV_DPAD_RIGHT)
                    print("[#HomeLabOS v1.01] Exited mini state")
                    local_sound:Play2d("page_flip")
                elseif not g_MiniStateActive and state.holdTime < 3.0 then
                    if g_MiniMenuActive then
                        if lastPressedButton == "L1" then
                        else
                            local_sound:Play2d("page_flip")
                            g_MiniMenuActive = false
                            g_ShowWheelPopup = false
                            g_ShowL1Popup = false
                            g_R1MenuSelectedIndex = 1
                            g_L1MenuSelectedIndex = 1

                            local_pad:Reserve(PAD_ACCEPT, SELECT)
                            local_pad:Reserve(PAD_DECLINE, BACK)
                            local_pad:Reserve(PAD_TRIANGLE, QUICKMENU)
                            local_pad:Reserve(PAD_SQUARE, OPTIONS)
                            local_pad:Reserve(PAD_DPAD_UP, DPAD_UP)
                            local_pad:Reserve(PAD_DPAD_DOWN, DPAD_DOWN)
                            local_pad:Reserve(PAD_R2_SHOULDER, NEXT_PAGE_R2)
                            local_pad:Reserve(PAD_L2_SHOULDER, PREVIOUS_PAGE_L2)
                            local_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
                            local_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
                            local_pad:Reserve(PAD_DPAD_LEFT, NAV_DPAD_LEFT)
                            local_pad:Reserve(PAD_DPAD_RIGHT, NAV_DPAD_RIGHT)
                        end
                    elseif not g_CustomOSKActive then
                        local_sound:Play2d("page_flip")
                        g_MiniMenuActive = true
                        local_pad:UnReserveAll()
                        local_pad:Reserve(PAD_SQUARE, OPTIONS)
                        local_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
                        local_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
                    end
                end
                state.isHolding = false
                state.holdTime = 0
                state.repeatTime = 0
            end
            if button == BACK then
                state.pendingCacheClear = false
                state.startedInGrid = false
            elseif button == QUICKMENU then
                state.sceneReloadTriggered = false
            end
        elseif state.isHolding and local_pad:IsHeld(button) then
            state.holdTime = state.holdTime + GetDeltaTime()
            if button == OPTIONS then
                if state.holdTime >= 3.0 and not g_MiniStateActive then
                    g_MiniStateActive = true
                    g_MiniMenuActive = false
                    local_pad:UnReserveAll()
                    local_pad:Reserve(PAD_SQUARE, OPTIONS)
                    print("[#HomeLabOS v1.01] Entered mini state")
                    local_sound:Play2d("page_flip")
                end
            elseif button == BACK and not state.gameExited then
                if state.holdTime >= OPTIONS_EXIT_GAME_THRESHOLD then
                    local_sound:Play2d("cancel_back")
                    g_UIActive = 0
                    local_pad:UnReserveAll()
                    ApplyPortableItem("30303030-30303030-30303030-00000006", "portable-companion")
                    state.gameExited = true
                elseif state.holdTime >= OPTIONS_CLEAR_CACHE_THRESHOLD and not g_MiniMenuActive and not state.cacheCleared and g_ActiveArea ~= "grid" and g_ActiveArea ~= "toggles" then
                    state.pendingCacheClear = true
                end
            elseif button == QUICKMENU then
                if not g_PopupActive and not g_MiniMenuActive then
                    if state.holdTime >= 3.0 and not state.sceneReloadTriggered then
                        local sceneId = SceneInfo.GetSceneId()
                        if sceneId then
                            local command = "map " .. sceneId
                            SendRTMCommand(command)
                            print("[#HomeLabOS v1.01] Sent scene reload command: " .. command)
                            state.sceneReloadTriggered = true
                            local_sound:Play2d("page_flip")
                        else
                            print("[#HomeLabOS v1.01] Error: Could not get current scene ID")
                        end
                    end
                end
            elseif button ~= OPTIONS and button ~= BACK then
                if state.holdTime >= HOLD_THRESHOLD then
                    state.repeatTime = state.repeatTime + GetDeltaTime()
                    if state.repeatTime >= REPEAT_INTERVAL then
                        state.repeatTime = state.repeatTime - REPEAT_INTERVAL
                        if g_PopupActive then
                            if button == NAV_DPAD_LEFT then
                                PerformPopupNavigation("left")
                            elseif button == NAV_DPAD_RIGHT then
                                PerformPopupNavigation("right")
                            elseif button == DPAD_UP then
                                PerformPopupNavigation("up")
                            elseif button == DPAD_DOWN then
                                PerformPopupNavigation("down")
                            elseif button == PREVIOUS_TAB_L1 and not g_PopupRequestPending then
                                PerformPopupItemCycle("previous")
                            elseif button == NEXT_TAB_R1 and not g_PopupRequestPending then
                                PerformPopupItemCycle("next")
                            end
                        elseif not g_MiniMenuActive then
                            if button == NAV_DPAD_LEFT then
                                if activeTab.label == "Players Online" then
                                    PerformListNavigation("left")
                                elseif activeTab.content.grid_buttons and activeTab.content.grid_buttons[activeTab.content.buttons[activeTab.selectedButton].action] then
                                    PerformButtonGridNavigation("left")
                                else
                                    PerformGridNavigation("left")
                                end
                            elseif button == NAV_DPAD_RIGHT then
                                if activeTab.label == "Players Online" then
                                    PerformListNavigation("right")
                                elseif activeTab.content.grid_buttons and activeTab.content.grid_buttons[activeTab.content.buttons[activeTab.selectedButton].action] then
                                    PerformButtonGridNavigation("right")
                                else
                                    PerformGridNavigation("right")
                                end
                            elseif button == DPAD_UP then
                                if activeTab.label == "Players Online" then
                                    PerformListNavigation("up")
                                elseif activeTab.content.grid_buttons and activeTab.content.grid_buttons[activeTab.content.buttons[activeTab.selectedButton].action] then
                                    PerformButtonGridNavigation("up")
                                else
                                    PerformGridNavigation("up")
                                end
                            elseif button == DPAD_DOWN then
                                if activeTab.label == "Players Online" then
                                    PerformListNavigation("down")
                                elseif activeTab.content.grid_buttons and activeTab.content.grid_buttons[activeTab.content.buttons[activeTab.selectedButton].action] then
                                    PerformButtonGridNavigation("down")
                                else
                                    PerformGridNavigation("down")
                                end
                            elseif button == PREVIOUS_TAB_L1 then
                                PerformTabNavigation("previous")
                                activeTab = g_Tabs[g_ActiveTabIndex]
                                if not activeTab then
                                    print("[#HomeLabOS v1.01] Error: activeTab is nil after PerformTabNavigation('previous'). g_ActiveTabIndex = " .. tostring(g_ActiveTabIndex) .. ", #g_Tabs = " .. tostring(#g_Tabs))
                                    return
                                end
                            elseif button == NEXT_TAB_R1 then
                                PerformTabNavigation("next")
                                activeTab = g_Tabs[g_ActiveTabIndex]
                                if not activeTab then
                                    print("[#HomeLabOS v1.01] Error: activeTab is nil after PerformTabNavigation('next'). g_ActiveTabIndex = " .. tostring(g_ActiveTabIndex) .. ", #g_Tabs = " .. tostring(#g_Tabs))
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if g_MiniMenuActive then
        if local_pad:IsHeld(NEXT_TAB_R1) then
            g_ShowWheelPopup = true
        end
        if local_pad:IsHeld(PREVIOUS_TAB_L1) then
            g_ShowL1Popup = true
        end
        local isShowingPopup = g_ShowWheelPopup or g_ShowL1Popup
        if isShowingPopup and not g_DPadReserved then
            local_pad:Reserve(PAD_DPAD_UP, DPAD_UP)
            local_pad:Reserve(PAD_DPAD_DOWN, DPAD_DOWN)
            local_pad:Reserve(PAD_DPAD_LEFT, NAV_DPAD_LEFT)
            local_pad:Reserve(PAD_DPAD_RIGHT, NAV_DPAD_RIGHT)
            local_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
            local_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
            local_pad:Reserve(PAD_SQUARE, OPTIONS)
            g_DPadReserved = true
        elseif not isShowingPopup and g_DPadReserved then
            local_pad:UnReserveAll()
            local_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
            local_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
            local_pad:Reserve(PAD_SQUARE, OPTIONS)
            g_DPadReserved = false
        end
    end

    if g_MiniMenuActive and (g_ShowWheelPopup or g_ShowL1Popup) then
        if local_pad:WasJustPressed(DPAD_UP) then
            PerformMiniMenuNavigation("up", g_ShowWheelPopup and "R1" or "L1")
        elseif local_pad:WasJustPressed(DPAD_DOWN) then
            PerformMiniMenuNavigation("down", g_ShowWheelPopup and "R1" or "L1")
        elseif local_pad:WasJustPressed(NAV_DPAD_LEFT) then
            PerformMiniMenuNavigation("left", g_ShowWheelPopup and "R1" or "L1")
        elseif local_pad:WasJustPressed(NAV_DPAD_RIGHT) then
            PerformMiniMenuNavigation("right", g_ShowWheelPopup and "R1" or "L1")
        end
    end

    if local_pad:WasJustPressed(BACK) then
        if g_PopupActive then
            g_PopupActive = false
            g_PopupItem = nil
            g_PopupSelectedButton = 1
            g_PopupResponse = nil
            ResetPopupRequest()
            ResetPopupImage()
            g_PendingPageChangeForPopup = false
            local_sound:Play2d("cancel_back")
        elseif g_ActiveArea == "grid" or g_ActiveArea == "toggles" then
            g_ActiveArea = "sidebar"
            local_sound:Play2d("cancel_back")
        elseif g_ActiveArea == "sidebar" then
            print("[#HomeLabOS v1.01] Already back to sidebar")
            local_sound:Play2d("cancel_back")
        end
    end

    if local_pad:WasJustPressed(NEXT_TAB_R1) then
        if not g_MiniMenuActive then
            if g_PopupActive and not g_PopupRequestPending then
                PerformPopupItemCycle("next")
            elseif not g_PopupActive then
                PerformTabNavigation("next")
            end
        end
    elseif local_pad:WasJustPressed(PREVIOUS_TAB_L1) then
        if not g_MiniMenuActive then
            if g_PopupActive and not g_PopupRequestPending then
                PerformPopupItemCycle("previous")
            elseif not g_PopupActive then
                PerformTabNavigation("previous")
            end
        end
    end

    if activeTab and activeTab.content then
        if g_ActiveArea == "sidebar" and not g_MiniMenuActive then
            if local_pad:WasJustPressed(DPAD_DOWN) then
                PerformSidebarNavigation("down")
                if activeTab.label == "Tools" and g_CustomOSKActive then
                    local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
                    if selectedAction ~= "open_url" and selectedAction ~= "rtrc_console" then
                        g_CustomOSKActive = false
                    end
                end
            elseif local_pad:WasJustPressed(DPAD_UP) then
                PerformSidebarNavigation("up")
                if activeTab.label == "Tools" and g_CustomOSKActive then
                    local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
                    if selectedAction ~= "open_url" and selectedAction ~= "rtrc_console" then
                        g_CustomOSKActive = false
                    end
                end
            elseif local_pad:WasJustPressed(NAV_DPAD_RIGHT) then
                local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
                if activeTab.label == "Settings" and (selectedAction == "basic_settings" or selectedAction == "advanced_settings") then
                    g_ActiveArea = "toggles"
                    g_SelectedToggle = 1
                    justTransitioned = true
                    local_sound:Play2d("page_flip")
                elseif activeTab.label == "Players Online" then
                    local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
                    if selectedAction == "whoisonline" then
                        local whoIsOnlineItems = g_LobbyItems["Players Online"].whoIsOnline or {}
                        local friendsItems = g_LobbyItems["Players Online"].friends or {}
                        if #whoIsOnlineItems > 0 or #friendsItems > 0 then
                            g_ActiveArea = "grid"
                            if #whoIsOnlineItems > 0 then
                                g_SelectedTable = 1
                                g_SelectedWhoIsOnlineItem = 1
                            else
                                g_SelectedTable = 2
                                g_SelectedFriendsOnlineItem = 1
                            end
                            justTransitioned = true
                            local_sound:Play2d("page_flip")
                        end
                    else
                        if g_LobbyItems["Players Online"] and #g_LobbyItems["Players Online"] > 0 then
                            g_ActiveArea = "grid"
                            g_SelectedLobbyItem = 1
                            justTransitioned = true
                            local_sound:Play2d("page_flip")
                        end
                    end
                elseif (IsGridTab(activeTab.label) and g_GridItems[activeTab.label] and #g_GridItems[activeTab.label] > 0) or
                       (activeTab.label == "Tools" and selectedAction == "rtrc_presets") or
                       (activeTab.content.grid_buttons and activeTab.content.grid_buttons[selectedAction]) then
                    g_ActiveArea = "grid"
                    if activeTab.content.grid_buttons and activeTab.content.grid_buttons[selectedAction] then
                        g_SelectedButtonCol = 1
                        g_SelectedButtonRow = 1
                    else
                        g_SelectedGridItem = 1
                    end
                    justTransitioned = true
                    local_sound:Play2d("page_flip")
                end
            end
        elseif g_ActiveArea == "toggles" and not justTransitioned then
            if local_pad:WasJustPressed(DPAD_UP) then
                if activeTab.label == "Settings" then
                    g_SelectedToggle = math.max(1, g_SelectedToggle - 1)
                    local_sound:Play2d("page_flip")
                elseif activeTab.label == "Tools" and activeTab.content.grid_buttons and activeTab.content.grid_buttons.rtrc_general then
                    PerformButtonGridNavigation("up")
                end
            elseif local_pad:WasJustPressed(DPAD_DOWN) then
                if activeTab.label == "Settings" then
                    g_SelectedToggle = math.min(#activeTab.content.toggles.basic_settings, g_SelectedToggle + 1)
                    local_sound:Play2d("page_flip")
                elseif activeTab.label == "Tools" and activeTab.content.grid_buttons and activeTab.content.grid_buttons.rtrc_general then
                    PerformButtonGridNavigation("down")
                end
            elseif local_pad:WasJustPressed(NAV_DPAD_LEFT) then
                if activeTab.label == "Tools" and activeTab.content.grid_buttons and activeTab.content.grid_buttons.rtrc_general then
                    PerformButtonGridNavigation("left")
                else
                    g_ActiveArea = "sidebar"
                    local_sound:Play2d("page_flip")
                end
            elseif local_pad:WasJustPressed(NAV_DPAD_RIGHT) then
                if activeTab.label == "Tools" and activeTab.content.grid_buttons and activeTab.content.grid_buttons.rtrc_general then
                    PerformButtonGridNavigation("right")
                end
            elseif local_pad:WasJustPressed(SELECT) then
                if activeTab.label == "Settings" and activeTab.content.toggles and activeTab.content.toggles.basic_settings then
                    local toggle = activeTab.content.toggles.basic_settings[g_SelectedToggle]
                    if toggle then
                        toggle.state = not toggle.state
                        local_sound:Play2d("page_flip")
                    end
                elseif activeTab.label == "Tools" and activeTab.content.grid_buttons and activeTab.content.grid_buttons.rtrc_general then
                    local toggleIndex = (g_SelectedButtonRow - 1) * 4 + g_SelectedButtonCol
                    local toggle = activeTab.content.grid_buttons.rtrc_general.toggles[toggleIndex]
                    if toggle then
                        toggle.state = not toggle.state
                        local_sound:Play2d("page_flip")
                        if toggle.action then
                            local command = toggle.action .. " " .. (toggle.state and "1" or "0")
                            print("[#HomeLabOS v1.01] Sending RTM command: " .. command)
                            SendRTMCommand(command)
                        end
                    end
                end
            end
        end

        if g_PopupActive then
            if local_pad:WasJustPressed(NAV_DPAD_LEFT) then
                PerformPopupNavigation("left")
            elseif local_pad:WasJustPressed(NAV_DPAD_RIGHT) then
                PerformPopupNavigation("right")
            elseif local_pad:WasJustPressed(DPAD_UP) then
                PerformPopupNavigation("up")
            elseif local_pad:WasJustPressed(DPAD_DOWN) then
                PerformPopupNavigation("down")
            elseif local_pad:WasJustPressed(PREVIOUS_TAB_L1) and activeTab.label == "Players Online" and not g_PopupRequestPending then
                PerformPopupItemCycle("previous")
            elseif local_pad:WasJustPressed(NEXT_PAGE_R2) and activeTab.label == "Players Online" and not g_PopupRequestPending then
                PerformPopupItemCycle("next")
            end
        elseif not g_MiniMenuActive then
            if g_ActiveArea == "grid" and not justTransitioned then
                if activeTab.label == "Players Online" then
                    if local_pad:WasJustPressed(DPAD_UP) then
                        PerformListNavigation("up")
                    elseif local_pad:WasJustPressed(DPAD_DOWN) then
                        PerformListNavigation("down")
                    elseif local_pad:WasJustPressed(NAV_DPAD_LEFT) then
                        PerformListNavigation("left")
                    elseif local_pad:WasJustPressed(NAV_DPAD_RIGHT) then
                        PerformListNavigation("right")
                    end
                elseif local_pad:WasJustPressed(NAV_DPAD_LEFT) then
                    if activeTab.content.grid_buttons and activeTab.content.grid_buttons[activeTab.content.buttons[activeTab.selectedButton].action] then
                        PerformButtonGridNavigation("left")
                    else
                        PerformGridNavigation("left")
                    end
                elseif local_pad:WasJustPressed(NAV_DPAD_RIGHT) then
                    if activeTab.content.grid_buttons and activeTab.content.grid_buttons[activeTab.content.buttons[activeTab.selectedButton].action] then
                        PerformButtonGridNavigation("right")
                    else
                        PerformGridNavigation("right")
                    end
                elseif local_pad:WasJustPressed(DPAD_UP) then
                    if activeTab.content.grid_buttons and activeTab.content.grid_buttons[activeTab.content.buttons[activeTab.selectedButton].action] then
                        PerformButtonGridNavigation("up")
                    else
                        PerformGridNavigation("up")
                    end
                elseif local_pad:WasJustPressed(DPAD_DOWN) then
                    if activeTab.content.grid_buttons and activeTab.content.grid_buttons[activeTab.content.buttons[activeTab.selectedButton].action] then
                        PerformButtonGridNavigation("down")
                    else
                        PerformGridNavigation("down")
                    end
                end
            end
        end

        if local_pad:WasJustPressed(SELECT) then
            local_sound:Play2d("page_flip")
            if g_PopupActive and not g_MiniMenuActive then
                local selectedButton = g_PopupButtons[g_PopupSelectedButton]
                if selectedButton and selectedButton.action then
                    if selectedButton.action == "apply_now" then
                        ApplyNowAction()
                        local_sound:Play2d("page_flip")
                    elseif selectedButton.action == "add_item" then
                        AddRemoveAction("add")
                        local_sound:Play2d("page_flip")
                    elseif selectedButton.action == "remove_item" then
                        AddRemoveAction("remove")
                        local_sound:Play2d("page_flip")
                    elseif selectedButton.action == "related_content" then
                        local item = g_PopupItem
                        if item and item.id then
                            ClosePopup()
                            g_ActiveTabIndex = 7
                            g_ActiveArea = "sidebar"
                            g_SearchKeywords = item.id
                            ClearTabTextures("Search")
                            g_CategoryResponses["Search"] = ""
                            g_GridItems["Search"] = {}
                            g_CurrentPage["Search"] = 1
                            g_TotalPages["Search"] = nil
                            g_CategoryPageInfo["Search"] = ""
                            if not g_SearchRequestPending then
                                if not g_SearchMemoryContainer then
                                    g_SearchMemoryContainer = MemoryContainer.Create(4096)
                                    if not g_SearchMemoryContainer then
                                        local_sound:Play2d("cancel_back")
                                        print("[#HomeLabOS v1.01] Error: Related Content search, failed to create container")
                                        return
                                    end
                                end
                                g_SearchPostData = HttpPostData.Create(g_SearchMemoryContainer, "text/plain")
                                if not g_SearchPostData then
                                    local_sound:Play2d("cancel_back")
                                    print("[#HomeLabOS v1.01] Error: Related Content search, failed to create post data")
                                    return
                                end
                                g_SearchPostData:SetMethod("GET")
                                g_SearchPostData:Reset()
                                g_SearchPostData:AddHttpHeader("Accept", "text/plain")
                                g_SearchPostData:FinalizeHttpHeaders()
                                g_SearchPostData:Finalize()
                                local encodedKeywords = g_SearchKeywords:gsub(" ", "+")
                                local url = "http://173.225.107.46/HomeLab_OS_API/relateditems.php?uuid=" .. encodedKeywords .. "&page=1"
                                g_SearchResource = Resource.Request(url, "file", g_SearchPostData)
                                if g_SearchResource then
                                    g_SearchRequestPending = true
                                    g_SearchTimeoutFrames = 360
                                    g_SearchTabLabel = "Search"
                                else
                                    ResetSearchRequest()
                                    local_sound:Play2d("cancel_back")
                                    print("[#HomeLabOS v1.01] Error: Related Content search, failed to request resource")
                                end
                            end
                        else
                            print("[#HomeLabOS v1.01] Error: No valid item UUID for Related Content search")
                            ClosePopup()
                            g_ActiveTabIndex = 7
                            g_ActiveArea = "sidebar"
                        end
                        local_sound:Play2d("page_flip")
                    elseif selectedButton.action == "search_by_maker" then
                        SearchByMakerAction()
                        local_sound:Play2d("page_flip")
                    elseif selectedButton.action == "dump_content" then
                        DumpContentButtonAction()
                        local_sound:Play2d("page_flip")
                    end
                end
            elseif not g_MiniMenuActive then
                if g_ActiveArea == "sidebar" then
                    local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
                    if activeTab.label == "Settings" and (selectedAction == "basic_settings" or selectedAction == "advanced_settings") then
                        g_ActiveArea = "toggles"
                        g_SelectedToggle = 1
                        justTransitioned = true
                        local_sound:Play2d("page_flip")
                    elseif activeTab.label == "Search" and activeTab.content.buttons[activeTab.selectedButton] then
                        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
                        if selectedButton.action == "search_now" then
                            OpenCustomOSK(SearchNowOSKCallback, g_SearchKeywords, "kEnterSearchKeywords")
                        elseif selectedButton.action == "analyze" then
                            ClearTabTextures("Search")
                            g_CategoryResponses["Search"] = ""
                            g_GridItems["Search"] = {}
                            g_SearchKeywords = ""
                            if activeTab.content.textbox then
                                activeTab.content.textbox.text = ""
                            end
                            g_CurrentPage["Search"] = nil
                            g_TotalPages["Search"] = nil
                            g_CategoryPageInfo["Search"] = ""
                            g_ActiveArea = "sidebar"
                        end
                    elseif activeTab.label == "Tools" and activeTab.content.buttons[activeTab.selectedButton] then
                        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
                        if selectedButton.action == "open_url" then
                            OpenCustomOSK(OpenURLOSKCallback, g_URLInput or "http://", "kEnterURL")
                        elseif selectedButton.action == "rtrc_console" then
                            OpenCustomOSK(CommandConsoleOSKCallback, g_CommandInput or "", "kEnterCommand")
                        end
                    elseif (IsGridTab(activeTab.label) and g_GridItems[activeTab.label] and #g_GridItems[activeTab.label] > 0) or
                           (activeTab.label == "Tools" and selectedAction == "rtrc_presets") or
                           (activeTab.content.grid_buttons and activeTab.content.grid_buttons[selectedAction]) then
                        g_ActiveArea = "grid"
                        if activeTab.content.grid_buttons and activeTab.content.grid_buttons[selectedAction] then
                            g_SelectedButtonCol = 1
                            g_SelectedButtonRow = 1
                        else
                            g_SelectedGridItem = 1
                        end
                        justTransitioned = true
                        local_sound:Play2d("page_flip")
                    end
                elseif g_ActiveArea == "grid" then
                    local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
                    if activeTab.label == "Players Online" then
                        if selectedAction == "whoisonline" then
                            local items
                            local selectedIndex
                            if g_SelectedTable == 1 then
                                items = g_LobbyItems["Players Online"].whoIsOnline or {}
                                selectedIndex = g_SelectedWhoIsOnlineItem
                            elseif g_SelectedTable == 2 then
                                items = g_LobbyItems["Players Online"].friends or {}
                                selectedIndex = g_SelectedFriendsOnlineItem
                            elseif g_SelectedTable == 3 then
                                items = g_LobbyItems["Players Online"].sentInvites or {}
                                selectedIndex = g_SelectedSentInvitesItem
                            elseif g_SelectedTable == 4 then
                                items = g_LobbyItems["Players Online"].receivedInvites or {}
                                selectedIndex = g_SelectedReceivedInvitesItem
                            end
                            local selectedItem = items[selectedIndex]
                            if selectedItem then
                                if g_SelectedTable == 1 or g_SelectedTable == 2 then
                                    local name = selectedItem.name
                                    print("[#HomeLabOS v1.01] Selected name: " .. name)
                                    g_SelectedName = name
                                    g_NamePopupActive = true
                                    g_NamePopupSelectedButton = 1
                                    RenderNameClickPopup(name)
                                elseif g_SelectedTable == 3 or g_SelectedTable == 4 then
                                    g_SelectedInviteItem = selectedItem
                                    g_InvitePopupActive = true
                                    g_InvitePopupSelectedButton = 1
                                    RenderInviteActionPopup(name)
                                end
                            end
                        else
                            local item = g_LobbyItems["Players Online"][g_SelectedLobbyItem]
                            if item and item.trimmedDecID then
                                local command = "map " .. item.lobbyName
                                print("[#HomeLabOS v1.01] Sending RTM command: " .. command)
                                SendRTMCommand(command)
                            else
                                print("[#HomeLabOS v1.01] Error: No valid lobby ID found for selected item")
                            end
                        end
                    elseif activeTab.content.grid_buttons and activeTab.content.grid_buttons[selectedAction] then
                        local gridDef = activeTab.content.grid_buttons[selectedAction]
                        if selectedAction == "rtrc_general" then
                            local buttonIndex = (g_SelectedButtonRow - 1) * 8 + g_SelectedButtonCol
                            local setIndex = math.ceil(buttonIndex / 16)
                            local indexInSet = buttonIndex - (setIndex - 1) * 16
                            local colInSet = math.ceil(indexInSet / 2)
                            local rowInSet = indexInSet % 2 == 1 and 1 or 2
                            local button = gridDef.buttons[setIndex][colInSet][rowInSet]
                            if button and button.action then
                                print("[#HomeLabOS v1.01] Sending RTM command for action: " .. button.action)
                                SendRTMCommand(button.action)
                                local_sound:Play2d("page_flip")
                            end
                        else
                            local setIndex = g_SelectedButtonRow <= 2 and 1 or 2
                            local rowInSet = g_SelectedButtonRow <= 2 and g_SelectedButtonRow or g_SelectedButtonRow - 2
                            local button = gridDef.buttons[setIndex][g_SelectedButtonCol][rowInSet]
                            if button and button.action then
                                print("[#HomeLabOS v1.01] Performing action: " .. button.action)
                            end
                        end
                    elseif activeTab.label == "Tools" and selectedAction == "rtrc_presets" then
                        local item = g_GridItems["Tools_Presets"][g_SelectedGridItem]
                        if item then
                            local command_name = item.name:gsub("%s+", "")
                            local command = "loadavatar%20HLOS\\" .. command_name
                            SendRTMCommand(command)
                            print("[#HomeLabOS v1.01] Sent command: " .. command)
                        end
                    elseif IsGridTab(activeTab.label) then
                        local item = g_GridItems[activeTab.label][g_SelectedGridItem]
                        if item then
                            local category = item.category or selectedAction or "N/A"
                            g_SelectPressItem = {
                                id = item.id or "N/A",
                                name = item.name or "N/A",
                                category = category,
                                thumbnail_type = item.thumbnail_type or "N/A"
                            }
                            g_SelectPressTime = GetInstanceTime()
                        end
                    end
                end
            end
        end

        if local_pad:WasJustReleased(SELECT) then
            if g_SelectPressItem and not g_PopupActive and not g_MiniMenuActive and g_ActiveArea == "grid" then
                local holdTime = GetInstanceTime() - g_SelectPressTime
                local skipGenderSwitch = (holdTime >= 1000)
                HandleItemSelection(
                    g_SelectPressItem.id,
                    g_SelectPressItem.name,
                    g_SelectPressItem.category,
                    g_SelectPressItem.thumbnail_type,
                    skipGenderSwitch
                )
                g_SelectPressItem = nil
                g_SelectPressTime = nil
                local_sound:Play2d("page_flip")
            end
        end

        if local_pad:WasJustPressed(QUICKMENU) then
            if g_PopupActive then
                ClosePopup()
                local_sound:Play2d("cancel_back")
            elseif not g_MiniMenuActive and g_ActiveArea == "grid" then
                if activeTab.label == "Players Online" then
                    local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
                    if selectedAction == "whoisonline" then
                        local items
                        local selectedIndex
                        if g_SelectedTable == 1 then
                            items = g_LobbyItems["Players Online"].whoIsOnline or {}
                            selectedIndex = g_SelectedWhoIsOnlineItem
                        elseif g_SelectedTable == 2 then
                            items = g_LobbyItems["Players Online"].friends or {}
                            selectedIndex = g_SelectedFriendsOnlineItem
                        elseif g_SelectedTable == 3 then
                            items = g_LobbyItems["Players Online"].sentInvites or {}
                            selectedIndex = g_SelectedSentInvitesItem
                        elseif g_SelectedTable == 4 then
                            items = g_LobbyItems["Players Online"].receivedInvites or {}
                            selectedIndex = g_SelectedReceivedInvitesItem
                        end
                        local selectedItem = items[selectedIndex]
                        if selectedItem then
                            if g_SelectedTable == 1 or g_SelectedTable == 2 then
                                local name = selectedItem.name
                                print("[#HomeLabOS v1.01] Selected name: " .. name)
                                g_SelectedName = name
                                g_NamePopupActive = true
                                g_NamePopupSelectedButton = 1
                                RenderNameClickPopup(name)
                                local_sound:Play2d("page_flip")
                            elseif g_SelectedTable == 3 or g_SelectedTable == 4 then
                                g_SelectedInviteItem = selectedItem
                                g_InvitePopupActive = true
                                g_InvitePopupSelectedButton = 1
                                RenderInviteActionPopup(name)
                                local_sound:Play2d("page_flip")
                            end
                        else
                            print("[#HomeLabOS v1.01] Error: No valid player selected in whoisonline")
                            local_sound:Play2d("cancel_back")
                        end
                    else
                        local item = g_LobbyItems["Players Online"][g_SelectedLobbyItem]
                        if item and item.trimmedDecID then
                            g_PopupActive = true
                            g_PopupItem = {
                                id = item.lobbyName,
                                name = item.psvName,
                                category = item.accessType,
                                thumbnail_type = "L"
                            }
                            g_PopupSelectedButton = 1
                            g_PopupResponse = nil
                            ResetPopupRequest()
                            ResetPopupImage()
                            local_sound:Play2d("page_flip")
                        else
                            print("[#HomeLabOS v1.01] Error: No valid lobby item selected for popup")
                        end
                    end
                elseif activeTab.label == "Tools" and selectedButton.action == "rtrc_presets" then
                    local item = g_GridItems["Tools_Presets"][g_SelectedGridItem]
                    if item then
                        g_MiniPopupActive = true
                        g_HQImageIsDownloading = true
                        local hqUrl = "http://173.225.107.46/HomeLabOS_Resources/Presets/" .. item.image_id .. "_HQ.PNG"
                        g_HQImageResource = Resource.RequestTexture(hqUrl, TextureOptions.NoMipmaps)
                        if not g_HQImageResource then
                            g_HQImageIsDownloading = false
                            print("[#HomeLabOS v1.01] Error: Failed to request HQ image texture")
                        end
                        local_sound:Play2d("page_flip")
                    end
                elseif IsGridTab(activeTab.label) then
                    local item = g_GridItems[activeTab.label][g_SelectedGridItem]
                    if item then
                        local thumbnailurl
                        if item.thumbnail_type == "S" then
                            thumbnailurl = "http://173.225.107.46/HomeLabOS_Resources/OBJECTS/" .. item.id .. "/SMALLO.PNG"
                        elseif item.thumbnail_type == "L" then
                            thumbnailurl = "http://173.225.107.46/HomeLabOS_Resources/OBJECTS/" .. item.id .. "/LARGEO.PNG"
                        elseif item.thumbnail_type == "P" then
                            thumbnailurl = "http://173.225.107.46/HomeLabOS_Resources/ICONS/BLACKNOIMAGE.PNG"
                        else
                            thumbnailurl = "http://173.225.107.46/HomeLabOS_Resources/ICONS/BLACKNOIMAGE.PNG"
                        end
                        local category = item.category or activeTab.content.buttons[activeTab.selectedButton].action or "unknown"
                        g_PopupActive = true
                        g_PopupItem = {
                            id = item.id,
                            name = item.name,
                            category = category,
                            thumbnail_type = item.thumbnail_type
                        }
                        g_PopupSelectedButton = 1
                        g_PopupResponse = nil
                        ResetPopupRequest()
                        ResetPopupImage()
                        local_sound:Play2d("page_flip")
                    end
                end
            end
        end

        if local_pad:WasJustPressed(PREVIOUS_PAGE_L2) and not g_PopupActive and not g_MiniMenuActive then
            if activeTab.label ~= "Players Online" then
                local_sound:Play2d("cancel_back")
                if not g_CategoryRequestPending and not g_SearchRequestPending and not g_LobbyRequestPending then
                    ChangePageBack()
                end
            else
                local_sound:Play2d("cancel_back")
            end
        elseif local_pad:WasJustPressed(NEXT_PAGE_R2) and not g_PopupActive and not g_MiniMenuActive then
            if activeTab.label ~= "Players Online" then
                local_sound:Play2d("cancel_back")
                if not g_CategoryRequestPending and not g_SearchRequestPending and not g_LobbyRequestPending then
                    ChangePageForward()
                end
            else
                local_sound:Play2d("cancel_back")
            end
        end
    end

    if g_CategoryRequestPending and g_CategoryResource then
        if not g_CategoryTimeoutFrames then
            g_CategoryTimeoutFrames = 360
        end
        g_CategoryTimeoutFrames = g_CategoryTimeoutFrames - 1
        if g_CategoryTimeoutFrames <= 0 then
            print("[#HomeLabOS v1.01] Error: Category request timed out after 3 seconds")
            ResetCategoryRequest()
            g_PageChangeInProgress = false
            g_CategoryTimeoutFrames = nil
        elseif Resource.IsLoaded(g_CategoryResource) then
            local memContainer = MemoryContainer.Create(g_CategoryResource)
            if memContainer then
                local success, responseStr = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                if success and responseStr and #responseStr > 0 then
                    print("[#HomeLabOS v1.01] Received category response: " .. responseStr)
                    responseStr = responseStr:gsub("\r\n", "\n"):gsub("\r", "\n")
                    local items, currentPage, totalPages, pageInfo = ParseResponseText(responseStr)
                    if items then
                        print("[#HomeLabOS v1.01] Parsed " .. #items .. " items from category response")
                        local activeTab = g_Tabs[g_ActiveTabIndex]
                        if activeTab.label == g_CategoryTabLabel then
                            ClearTabTextures(activeTab.label)
                            g_GridItems[activeTab.label] = items
                            g_SelectedGridItem = 1
                            if #items > 0 then
                                g_Slot1UUID = items[1].id
                            else
                                g_Slot1UUID = nil
                            end
                            g_CategoryPageInfo[activeTab.category][activeTab.content.buttons[activeTab.selectedButton].action] = pageInfo
                            g_TotalPages[activeTab.category][activeTab.content.buttons[activeTab.selectedButton].action] = totalPages
                            g_CurrentPage[activeTab.category][activeTab.content.buttons[activeTab.selectedButton].action] = currentPage
                            print("[#HomeLabOS v1.01] Updated grid for " .. activeTab.label .. ": Page " .. currentPage .. " of " .. totalPages .. ", " .. #items .. " items")
                            UIRender()
                        end
                    else
                        print("[#HomeLabOS v1.01] Error: Failed to parse category response")
                    end
                else
                    print("[#HomeLabOS v1.01] Error: Failed to read category response")
                end
                memContainer = nil
            end
            Resource.Release(g_CategoryResource)
            g_CategoryPostData = nil
            g_CategoryResource = nil
            g_CategoryRequestPending = false
            g_PageChangeInProgress = false
            g_CategoryTimeoutFrames = nil
        end
    end

    if g_SearchRequestPending and g_SearchResource then
        if not g_SearchTimeoutFrames then
            g_SearchTimeoutFrames = 360
        end
        g_SearchTimeoutFrames = g_SearchTimeoutFrames - 1
        if g_SearchTimeoutFrames <= 0 then
            print("[#HomeLabOS v1.01] Error: Search request timed out after 3 seconds")
            ResetSearchRequest()
            g_PageChangeInProgress = false
            g_SearchTimeoutFrames = nil
        elseif Resource.IsLoaded(g_SearchResource) then
            local memContainer = MemoryContainer.Create(g_SearchResource)
            if memContainer then
                local success, responseStr = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                if success and responseStr and #responseStr > 0 then
                    print("[#HomeLabOS v1.01] Received search response: " .. responseStr)
                    responseStr = responseStr:gsub("\r\n", "\n"):gsub("\r", "\n")
                    local items, currentPage, totalPages, pageInfo = ParseResponseText(responseStr)
                    if items then
                        print("[#HomeLabOS v1.01] Parsed " .. #items .. " items from search response")
                        if g_SearchTabLabel == "Search" then
                            ClearTabTextures("Search")
                            g_GridItems["Search"] = items
                            g_SelectedGridItem = 1
                            if #items > 0 then
                                g_Slot1UUID = items[1].id
                            else
                                g_Slot1UUID = nil
                            end
                            g_CategoryPageInfo["Search"] = pageInfo
                            g_TotalPages["Search"] = totalPages
                            g_CurrentPage["Search"] = currentPage
                            print("[#HomeLabOS v1.01] Updated grid for Search: Page " .. currentPage .. " of " .. totalPages .. ", " .. #items .. " items")
                            UIRender()
                        else
                            print("[#HomeLabOS v1.01] Search response not processed: g_SearchTabLabel is not 'Search'")
                        end
                    else
                        print("[#HomeLabOS v1.01] Error: Failed to parse search response")
                    end
                else
                    print("[#HomeLabOS v1.01] Error: Failed to read search response")
                end
                memContainer = nil
            end
            Resource.Release(g_SearchResource)
            g_SearchPostData = nil
            g_SearchResource = nil
            g_SearchRequestPending = false
            g_PageChangeInProgress = false
            g_SearchTimeoutFrames = nil
        end
    end

    if g_InventoryRefreshPending then
        for i = #g_InventoryRefreshRequests, 1, -1 do
            local request = g_InventoryRefreshRequests[i]
            if not request.timeoutFrames then
                request.timeoutFrames = 360
            end
            request.timeoutFrames = request.timeoutFrames - 1
            if request.timeoutFrames <= 0 then
                print("[#HomeLabOS v1.01] Error: Inventory refresh request for " .. request.subcategory .. " timed out after 3 seconds")
                Resource.Release(request.resource)
                request.postData = nil
                table.remove(g_InventoryRefreshRequests, i)
            elseif Resource.IsLoaded(request.resource) then
                local memContainer = MemoryContainer.Create(request.resource)
                if memContainer then
                    local success, responseStr = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                    if success and responseStr and #responseStr > 0 then
                        print("[#HomeLabOS v1.01] Received inventory response for " .. request.subcategory .. ": " .. responseStr)
                        responseStr = responseStr:gsub("\r\n", "\n"):gsub("\r", "\n")
                        local items, currentPage, totalPages, pageInfo = ParseResponseText(responseStr)
                        if items then
                            print("[#HomeLabOS v1.01] Parsed " .. #items .. " items for " .. request.subcategory)
                            g_PreloadedData["MyInventory"][request.subcategory] = {
                                items = items,
                                currentPage = currentPage,
                                totalPages = totalPages,
                                pageInfo = pageInfo
                            }
                            g_CurrentPage["MyInventory"] = g_CurrentPage["MyInventory"] or {}
                            g_TotalPages["MyInventory"] = g_TotalPages["MyInventory"] or {}
                            g_CategoryPageInfo["MyInventory"] = g_CategoryPageInfo["MyInventory"] or {}
                            g_CurrentPage["MyInventory"][request.subcategory] = currentPage
                            g_TotalPages["MyInventory"][request.subcategory] = totalPages
                            g_CategoryPageInfo["MyInventory"][request.subcategory] = pageInfo
                            print("[#HomeLabOS v1.01] Updated inventory data for " .. request.subcategory .. ": Page " .. currentPage .. " of " .. totalPages .. ", " .. #items .. " items")
                            local activeTab = g_Tabs[g_ActiveTabIndex]
                            if activeTab and activeTab.label == "MyInventory" and activeTab.content.buttons[activeTab.selectedButton].action == request.subcategory then
                                g_GridItems[activeTab.label] = items
                                g_SelectedGridItem = 1
                                if #items > 0 then
                                    g_Slot1UUID = items[1].id
                                else
                                    g_Slot1UUID = nil
                                end
                                UIRender()
                            end
                        else
                            print("[#HomeLabOS v1.01] Error: Failed to parse response for " .. request.subcategory)
                        end
                    else
                        print("[#HomeLabOS v1.01] Error: Failed to read response for " .. request.subcategory)
                    end
                    memContainer = nil
                end
                Resource.Release(request.resource)
                request.postData = nil
                table.remove(g_InventoryRefreshRequests, i)
            end
        end
        if #g_InventoryRefreshRequests == 0 then
            g_InventoryRefreshPending = false
        end
    end
end