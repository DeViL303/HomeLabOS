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
LoadLibrary("Platform")
LoadLibrary("LocalPlayer")
LoadLibrary("Person")

LoadLibrary("Texture")
LoadLibrary("SoundBank")
LoadLibrary("MemoryContainer")
LoadLibrary("HttpPostData")
LoadLibrary("Resource")
LoadLibrary("Xml")


g_UIActive = 0
g_Renderer = nil
g_PadActive = 0
g_pad = nil
g_Me = nil
g_userText = ""
gSoundBank = nil
g_SearchKeywords = ""
g_SearchRequestPending = false
g_SearchResource = nil
g_SearchContainer = nil
g_SearchPostData = nil
g_SearchRequestTime = 0
g_SearchRequestTimeout = 10000
g_RelateItemsRequestTimeout = 10000
g_CategoryRequestPending = false
g_CategoryResource = nil
g_CategoryContainer = nil
g_CategoryPostData = nil
g_CategoryRequestTime = 0
g_CategoryRequestTimeout = 2000
g_SelectedGridItem = 1
g_ActiveArea = "sidebar"
g_CategoryTabLabel = nil
g_SearchTabLabel = nil
g_PageChangeDirection = nil
g_PageChangeColumn = nil
g_TabGridsInitialized = {}
g_InventoryRefreshPending = false
g_InventoryRefreshRequests = {}
g_InventoryRefreshTimeout = 4000
g_SelectedButtonCol = 1
g_SelectedButtonRow = 1
g_SelectedLobbyItem = 1

Pad.CreatePads(0)
g_pad = Pad.GetPad(1)
g_NamePopupActive = false
g_SelectedName = nil
g_NamePopupSelectedButton = 1

Resource.Run("DATA_MANAGEMENT")
Resource.Run("CATEGORY_CONFIG")
Resource.Run("ITEM_CONTROL")
Resource.Run("UI_RENDERING")
Resource.Run("INPUT_HANDLING")
Resource.Run("POPUP")
Resource.Run("OSK")
Resource.Run("MINIOS")

function ParseResponseText(responseText)

    local lines = {}
    for line in responseText:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    if #lines < 1 then
        return nil, "Invalid response format"
    end


    local firstLine = lines[1]
    local pageData = {}
    for part in firstLine:gmatch("[^|]+") do
        table.insert(pageData, part)
    end
    if #pageData ~= 3 then
        return nil, "Invalid page data format"
    end


    local currentPage = tonumber(pageData[1]) or 1
    local totalPages = tonumber(pageData[2]) or 1
    local totalItems = tonumber(pageData[3]) or 0
    local pageInfo = string.format("Page %d of %d   Total Items %d", currentPage, totalPages, totalItems)


    local items = {}
    for i = 2, #lines do
        local id, name, thumbnail_type, category = lines[i]:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
        if id and name and thumbnail_type and category then
            table.insert(items, {
                id = id,
                name = name,
                thumbnail_type = thumbnail_type,
                category = category,
                texture_resource = nil,
                texture = nil
            })
        end
    end

    return items, currentPage, totalPages, pageInfo
end

function ParseLobbyResponse(responseText)
    local lines = {}
    for line in responseText:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    if #lines < 1 then
        print("[ParseLobbyResponse] Invalid lobby response format: No lines found")
        return nil, "Invalid lobby response format"
    end

    local firstLine = lines[1]
    local pageData = {}
    for part in firstLine:gmatch("[^|]+") do
        table.insert(pageData, part)
    end
    local currentPage, totalPages, pageInfo
    if #pageData == 3 and firstLine:match("Page %d+ of %d+") then
        currentPage, totalPages = firstLine:match("Page (%d+) of (%d+)")
        currentPage = tonumber(currentPage) or 1
        totalPages = tonumber(totalPages) or 1
        pageInfo = firstLine
        table.remove(lines, 1)
    else
        currentPage = 1
        totalPages = 1
        pageInfo = "Page 1 of 1   Total Items " .. #lines
    end

    local items = {}
    local buttons = {}
    local activeTab = g_Tabs[g_ActiveTabIndex]
    local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
    local isWhoIsOnline = selectedButton and selectedButton.action == "whoisonline"

    for _, line in ipairs(lines) do
        if isWhoIsOnline then
            local name, status = line:match("^([^|]+)|([^|]+)$")
            local buttonLabel, buttonText, buttonLocalisedText, buttonAction = line:match("^Button|([^|]+)|([^|]+)|([^|]+)$")
            if name and status then
                table.insert(items, {
                    name = name,
                    status = status,
                    texture_resource = nil,
                    texture = nil
                })
            elseif buttonLabel and buttonText and buttonLocalisedText and buttonAction then
                table.insert(buttons, {
                    label = buttonLabel,
                    localisedText = buttonLocalisedText,
                    action = buttonAction
                })
            end
        else
            local trimmedDecID, psvName, lobbyName, accessType, clientCount, imagePath, upTime = line:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)")
            if trimmedDecID then
                table.insert(items, {
                    trimmedDecID = trimmedDecID,
                    imagePath = imagePath,
                    lobbyName = lobbyName,
                    accessType = accessType,
                    clientCount = clientCount,
                    psvName = psvName,
                    upTime = upTime,
                    texture_resource = nil,
                    texture = nil
                })
            end
        end
    end

    print("[ParseLobbyResponse] Parsed " .. #items .. " items and " .. #buttons .. " buttons")
    return items, currentPage, totalPages, pageInfo, buttons
end

function UpdateGridItems(tabLabel, responseText)
    local items, currentPage, totalPages, pageInfo = ParseResponseText(responseText)
    if not items then
        return
    end


    local gridItems = g_GridItems[tabLabel] or {}
    g_GridItems[tabLabel] = gridItems


    for i = 1, #gridItems do
        local item = gridItems[i]
        item.id = nil
        item.name = nil
        item.thumbnail_type = nil
        item.category = nil
        item.texture_resource = nil
        item.texture = nil
    end


    for i, newItem in ipairs(items) do
        local item = gridItems[i]
        if not item then
            item = {}
            gridItems[i] = item
        end
        item.id = newItem.id
        item.name = newItem.name
        item.thumbnail_type = newItem.thumbnail_type
        item.category = newItem.category
        item.texture_resource = nil
        item.texture = nil
    end


    while #gridItems > #items do
        table.remove(gridItems)
    end


    local activeTab = g_Tabs[g_ActiveTabIndex]
    if activeTab and activeTab.label == tabLabel then
        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
        if selectedButton then
            g_CategoryPageInfo[tabLabel][selectedButton.action] = pageInfo
            g_TotalPages[tabLabel][selectedButton.action] = totalPages
            g_CurrentPage[tabLabel][selectedButton.action] = currentPage
        end
    end
end

function UpdateLobbyItems(tabLabel, responseText)
    local items, currentPage, totalPages, pageInfo, buttons = ParseLobbyResponse(responseText)
    if not items then
        return
    end


    local lobbyItems = g_LobbyItems[tabLabel] or {}
    g_LobbyItems[tabLabel] = lobbyItems


    for i = 1, #lobbyItems do
        local item = lobbyItems[i]
        item.trimmedDecID = nil
        item.psvName = nil
        item.lobbyName = nil
        item.accessType = nil
        item.clientCount = nil
        item.imagePath = nil
        item.upTime = nil
        item.name = nil
        item.status = nil
        item.texture_resource = nil
        item.texture = nil
    end


    for i, newItem in ipairs(items) do
        local item = lobbyItems[i]
        if not item then
            item = {}
            lobbyItems[i] = item
        end
        if newItem.trimmedDecID then
            item.trimmedDecID = newItem.trimmedDecID
            item.psvName = newItem.psvName
            item.lobbyName = newItem.lobbyName
            item.accessType = newItem.accessType
            item.clientCount = newItem.clientCount
            item.imagePath = newItem.imagePath
            item.upTime = newItem.upTime
        elseif newItem.name then
            item.name = newItem.name
            item.status = newItem.status
        end
        item.texture_resource = nil
        item.texture = nil
    end


    while #lobbyItems > #items do
        table.remove(lobbyItems)
    end


    local activeTab = g_Tabs[g_ActiveTabIndex]
    if activeTab and activeTab.label == tabLabel and activeTab.content.buttons[activeTab.selectedButton].action == "whoisonline" then
        g_LobbyItems[tabLabel].buttons = buttons
    end


    if activeTab and activeTab.label == tabLabel then
        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
        if selectedButton then
            g_CategoryPageInfo[tabLabel][selectedButton.action] = pageInfo
            g_TotalPages[tabLabel][selectedButton.action] = totalPages
            g_CurrentPage[tabLabel][selectedButton.action] = currentPage
        end
    end
end

function CreatePlaceholderData(subcategory)
    local items = {
        {
            id = "placeholder-" .. subcategory,
            name = "Loading...",
            thumbnail_type = "P",
            category = subcategory,
            texture_resource = nil,
            texture = nil
        }
    }
    local currentPage = 1
    local totalPages = 1
    local totalItems = 1
    local pageInfo = string.format("Page %d of %d   Total Items %d", currentPage, totalPages, totalItems)
    return {
        items = items,
        currentPage = currentPage,
        totalPages = totalPages,
        pageInfo = pageInfo
    }
end

function ActivateInterface()
    g_Renderer = Renderer.Create(Vector4.Create(0, 0, 0, 0), Vector4.Create(1280, 720, 0, 0), Vector4.Create(1, 1, 1, 1), 'global')
    if not g_Renderer then
        return
    end
    local screen_size = g_Renderer:GetSize()
    local screen_half_size = screen_size * 0.5
    g_Renderer:SetScale(Vector4.Create(1, -1))
    g_Renderer:Camera2dSetPosition(screen_half_size)
    g_Renderer:SetFontScale(1, -1)

    if not g_CategoryMemoryContainer then
        g_CategoryMemoryContainer = MemoryContainer.Create(4096)
        if not g_CategoryMemoryContainer then
            print("Error: Failed to create g_CategoryMemoryContainer")
        end
    end
    if not g_SearchMemoryContainer then
        g_SearchMemoryContainer = MemoryContainer.Create(4096)
        if not g_SearchMemoryContainer then
            print("Error: Failed to create g_SearchMemoryContainer")
        end
    end
    g_Me = Object.GetMe()
    if not g_Me then
        return
    end

    if g_pad == nil then
        Pad.CreatePads(0)
        g_pad = Pad.GetPad(1)
    end
    PadActivate()

    gSoundBank = SoundBank.Find("SOUND")


    g_PreloadedData = {}
    g_PreloadedData["MyInventory"] = {}
    local subcategories = {"kLoadAll", "kMyMale", "kMyFemale", "kMyPortable", "kMyFurniture", "kMyApartments"}
    for _, subcategory in ipairs(subcategories) do
        g_PreloadedData["MyInventory"][subcategory] = CreatePlaceholderData(subcategory)
    end


    g_GridItems["Tools_Presets"] = {}
    for i = 1, 72 do
        table.insert(g_GridItems["Tools_Presets"], {
            id = "preset_" .. i,
            image_id = i,
            name = "Preset " .. i,
            thumbnail_type = "P",
            category = "Presets",
            texture_resource = nil,
            texture = nil
        })
    end
    g_CategoryPageInfo["Tools_Presets"] = "Page 1 of 1   Total Items 72"

    g_UIActive = 1


    local activeTab = g_Tabs[g_ActiveTabIndex]
    if activeTab and activeTab.label == "Players Online" then
        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
        if selectedButton and selectedButton.action == "view_stats" then
            RequestLobbyData("view_stats")
        end
    end
end

function DeactivateInterface()

    if g_CategoryMemoryContainer then
        g_CategoryMemoryContainer = nil
    end
    if g_SearchMemoryContainer then
        g_SearchMemoryContainer = nil
    end

    g_UIActive = 0

    if g_Renderer then
        g_Renderer = nil
    end
    PadDeactivate()
    gSoundBank = nil
end

function OnDestroy()
    g_PreloadedData = nil

    g_UIActive = 0

    g_GridItems = {}
    g_LobbyItems = {}
end

function PadActivate()
    if g_pad == nil then
        Pad.CreatePads(0)
        g_pad = Pad.GetPad(1)
    end
    if g_pad then
        g_pad:Reserve(PAD_ACCEPT, SELECT)
        g_pad:Reserve(PAD_DECLINE, BACK)
        g_pad:Reserve(PAD_TRIANGLE, QUICKMENU)
        g_pad:Reserve(PAD_SQUARE, OPTIONS)
        g_pad:Reserve(PAD_DPAD_UP, DPAD_UP)
        g_pad:Reserve(PAD_DPAD_DOWN, DPAD_DOWN)
        g_pad:Reserve(PAD_R2_SHOULDER, NEXT_PAGE_R2)
        g_pad:Reserve(PAD_L2_SHOULDER, PREVIOUS_PAGE_L2)
        g_pad:Reserve(PAD_R1_SHOULDER, NEXT_TAB_R1)
        g_pad:Reserve(PAD_L1_SHOULDER, PREVIOUS_TAB_L1)
        g_pad:Reserve(PAD_DPAD_LEFT, NAV_DPAD_LEFT)
        g_pad:Reserve(PAD_DPAD_RIGHT, NAV_DPAD_RIGHT)
        g_PadActive = 1
    end
end

function PadDeactivate()
    if g_pad then
        g_pad:UnReserveAll()
        g_PadActive = 0
    end
end


function OnUpdate()
    MainRender()
    if g_UIActive == 1 then
        UIUpdate()
    end

    if not g_InterfaceActivated then
        g_ActivationFrameCount = (g_ActivationFrameCount or 0) + 1
        if g_ActivationFrameCount >= 1 then
            ActivateInterface()
            g_InterfaceActivated = true
        end
    end
end

function MainRender()
    if g_UIActive == 1 then
        if g_MiniStateActive then
        elseif g_MiniMenuActive then
            UIRenderMiniMenu()
        else
            UIRender()
        end
    end
end

function OnMove()
end

function OnVisibilityChange()
end

function OnListenerReceivedData() end
function OnSendWelcomeMessage() end
function OnAddPlayer() end
function OnRemovePlayer() end
function OnCanLocalPlayerJoin() return true end
function OnLocalPlayerUpdateGameplay() end