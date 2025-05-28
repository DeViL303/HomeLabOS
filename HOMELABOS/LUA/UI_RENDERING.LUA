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
LoadLibrary("Resource")
LoadLibrary("Texture")
LoadLibrary("User")


g_SentInvitesScrollOffset = 0

function RenderToggle(x, y, state, isSelected, label, labelX)
    local renderer = g_Renderer
    local toggleWidth = 29
    local toggleHeight = 14
    local thumbSize = 10
    local backgroundColorOff = Vector4.Create(0.5, 0.5, 0.5, 1)
    local backgroundColorOn = Vector4.Create(0, 1, 0, 1)
    local thumbColor = Vector4.Create(1, 1, 1, 1)
    local outlineColor = Vector4.Create(0, 1, 0, 1)
    local outlineBgColor = Vector4.Create(0, 0, 0, 0.95)
    local textColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)

    local toggleOffsetY = (40 - toggleHeight) / 2
    local toggleY = y + toggleOffsetY
    local toggleX = x - 11
    local outlinePadding = 1
    local outlineWidth = (toggleX + toggleWidth + 10) - labelX + 2 * outlinePadding
    local outlineHeight = 38

    if isSelected then
        renderer:DrawRect2d(
            labelX - outlinePadding, y + outlinePadding,
            labelX + outlineWidth - outlinePadding, y + outlineHeight + outlinePadding,
            outlineColor
        )
        renderer:DrawRect2d(
            labelX - outlinePadding + 1, y + outlinePadding + 1,
            labelX + outlineWidth - outlinePadding - 1, y + outlineHeight + outlinePadding - 1,
            outlineBgColor
        )
    end

    local backgroundColor = state and backgroundColorOn or backgroundColorOff
    renderer:DrawRect2d(
        toggleX, toggleY,
        toggleX + toggleWidth, toggleY + toggleHeight,
        backgroundColor
    )

    local thumbX = state and (toggleX + toggleWidth - thumbSize - 2) or (toggleX + 2)
    local thumbY = toggleY + (toggleHeight - thumbSize) / 2
    renderer:DrawRect2d(
        thumbX, thumbY,
        thumbX + thumbSize, thumbY + thumbSize,
        thumbColor
    )

    renderer:SetFontScale(0.8, -0.8)
    local labelPos = Vector4.Create(labelX + 10, y + 10, 0)
    renderer:DrawText2d(labelPos, label, textColor)
end

function RenderSmallToggle(x, y, state, isSelected, label, labelX, tileWidth)
    local renderer = g_Renderer
    local toggleWidth = 20
    local toggleHeight = 10
    local thumbSize = 8
    local backgroundColorOff = Vector4.Create(0.5, 0.5, 0.5, 1)
    local backgroundColorOn = Vector4.Create(0, 1, 0, 1)
    local thumbColor = Vector4.Create(1, 1, 1, 1)
    local textColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)

    local toggleOffsetY = (25 - toggleHeight) / 2
    local toggleY = y + toggleOffsetY
    local toggleX = x + tileWidth - toggleWidth - 5

    local backgroundColor = state and backgroundColorOn or backgroundColorOff
    renderer:DrawRect2d(
        toggleX, toggleY,
        toggleX + toggleWidth, toggleY + toggleHeight,
        backgroundColor
    )

    local thumbX = state and (toggleX + toggleWidth - thumbSize - 1) or (toggleX + 1)
    local thumbY = toggleY + (toggleHeight - thumbSize) / 2
    renderer:DrawRect2d(
        thumbX, thumbY,
        thumbX + thumbSize, thumbY + thumbSize,
        thumbColor
    )

    renderer:SetFontScale(0.7, -0.7)
    local textSize = renderer:GetTextSize(label)
    local textHeight = textSize:Y()
    local labelPosY = y + (25 - textHeight) / 2 - 12
    local labelPos = Vector4.Create(labelX + 5, labelPosY, 0)
    renderer:DrawText2d(labelPos, label, textColor)
end

function UIRenderTabs(bgX, bgY, bgWidth, topBarHeight)
    local renderer = g_Renderer
    local tabHeight = 22
    local tabY = bgY + topBarHeight - tabHeight - 5
    local tabHorizontalSpacing = 2
    local tabVerticalSpacing = 4
    local tabPadding = 25
    local currentX = bgX + 25
    local buttonHighlightBorderColor = Vector4.Create(0.0, 0.5, 0.0, 1.0)
    local buttonBgColor = Vector4.Create(0.0, 0.0, 0.0, 0.9)
    local textColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)

    renderer:SetFontScale(0.6, -0.6)
    local previousLabel = g_Me:GetLocalizedText("kPrevious")
    local previousTextSize = renderer:GetTextSize(previousLabel)
    local previousX = currentX - 8 - previousTextSize:X()
    local previousPos = Vector4.Create(previousX, tabY + 10 + tabVerticalSpacing / 2, 0)
    renderer:DrawText2d(previousPos, previousLabel, Vector4.Create(1.0, 1.0, 1.0, 0.6))

    for i, tab in ipairs(g_Tabs) do
        renderer:SetFontScale(0.8, -0.8)
        local textSize = renderer:GetTextSize(tab.label)
        local tabWidth = textSize:X() + tabPadding * 2
        local tabOffsetY = (i == g_ActiveTabIndex) and 0 or 0

        if i == g_ActiveTabIndex then
            local borderThickness = 2
            renderer:DrawRect2d(
                currentX - borderThickness, tabY + tabOffsetY - borderThickness - tabVerticalSpacing / 2,
                currentX + tabWidth + borderThickness, tabY + tabOffsetY + tabHeight + borderThickness + tabVerticalSpacing / 2,
                buttonHighlightBorderColor
            )
            renderer:DrawRect2d(
                currentX - borderThickness + 1, tabY + tabOffsetY - borderThickness + 1 - tabVerticalSpacing / 2,
                currentX + tabWidth + borderThickness - 1, tabY + tabOffsetY + tabHeight + borderThickness - 1 + tabVerticalSpacing / 2,
                buttonBgColor
            )
        else
            renderer:DrawRect2d(
                currentX, tabY + tabOffsetY - tabVerticalSpacing / 2,
                currentX + tabWidth, tabY + tabOffsetY + tabHeight + tabVerticalSpacing / 2,
                g_Colors.Black05
            )
        end

        local currentTextSize = renderer:GetTextSize(tab.label)
        local textPosX = currentX + (tabWidth - currentTextSize:X()) / 2
        local textPos = Vector4.Create(textPosX, tabY + tabOffsetY + 5, 0)
        renderer:DrawText2d(textPos, tab.label, textColor)

        currentX = currentX + tabWidth + tabHorizontalSpacing
    end
    renderer:SetFontScale(0.6, -0.6)
    local nextLabel = g_Me:GetLocalizedText("kNext")
    local nextPos = Vector4.Create(currentX + 5, tabY + 10 + tabVerticalSpacing / 2, 0)
    renderer:DrawText2d(nextPos, nextLabel, Vector4.Create(1.0, 1.0, 1.0, 0.5))
end

function UIRenderLegend(posX, posY)
    local renderer = g_Renderer
    renderer:SetFontScale(0.6, -0.6)
    local colpagenav = Vector4.Create(1.0, 1.0, 1.0, 0.60)
    local colWhite = Vector4.Create(1.0, 1.0, 1.0, 0.95)

    local activeTab = g_Tabs[g_ActiveTabIndex]
    local leftSidebarWidth = 120
    local totalItemsX = 19 + leftSidebarWidth + 10
    local bottomBarStartX = 19 + leftSidebarWidth
    local bottomBarEndX = 19 + 1242 - 16
    local pageInfoX = (bottomBarStartX + bottomBarEndX) / 2 - 120

    renderer:SetFontHorzAlignment("right")
    local textPos = Vector4.Create(posX, posY, 0)
    local controlLegend = g_Me:GetLocalizedText("kControlLegend")
    renderer:DrawText2d(textPos, controlLegend, colpagenav)

    local pageInfoStr
    if activeTab.label == "Search" then
        pageInfoStr = g_CategoryPageInfo["Search"] or "Page 1 of 1   Total Items 0"
    elseif activeTab.label == "Tools" and activeTab.content.buttons[activeTab.selectedButton].action == "rtrc_presets" then
        pageInfoStr = "Page 1 of 1   Total Items 72"
    elseif activeTab.label == "Players Online" then
        pageInfoStr = ""
    else
        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
        pageInfoStr = g_CategoryPageInfo[activeTab.label] and g_CategoryPageInfo[activeTab.label][selectedButton.action] or ""
    end

    if pageInfoStr and pageInfoStr ~= "" and pageInfoStr:match("Page %d+ of %d+") then
        local totalItems = pageInfoStr:match("Total Items (%d+)") or "0"
        renderer:SetFontHorzAlignment("left")
        local totalItemsPos = Vector4.Create(totalItemsX, posY, 0)
        renderer:DrawText2d(totalItemsPos, "Total: " .. totalItems, colWhite)

        local pageNum, totalPages = pageInfoStr:match("Page (%d+) of (%d+)")
        if pageNum and totalPages then
            local pageInfoText = "Page " .. pageNum .. " of " .. totalPages
            local previousPageLabel = g_Me:GetLocalizedText("kSymbol3")
            local previousPageTextSize = renderer:GetTextSize(previousPageLabel)
            local previousPageX = pageInfoX - previousPageTextSize:X() - 5
            local previousPagePos = Vector4.Create(previousPageX, posY, 0)
            renderer:DrawText2d(previousPagePos, previousPageLabel, colpagenav)

            local pageInfoTextSize = renderer:GetTextSize(pageInfoText)
            local pageInfoPosX = pageInfoX - pageInfoTextSize:X() / 2
            local pageInfoPos = Vector4.Create(pageInfoX + 5, posY - 1, 0)
            renderer:DrawText2d(pageInfoPos, pageInfoText, colWhite)

            local nextPageLabel = g_Me:GetLocalizedText("kSymbol4")
            local nextPageX = pageInfoX + pageInfoTextSize:X() / 2 + 47
            local nextPagePos = Vector4.Create(nextPageX, posY, 0)
            renderer:DrawText2d(nextPagePos, nextPageLabel, colpagenav)
        end
    end

    renderer:SetFontHorzAlignment("left")
end

function RequestGridItemTexture(item, tabLabel, index)
    if g_GridTextures[item.id or item.trimmedDecID] and (g_GridTextures[item.id or item.trimmedDecID].downloaded or g_GridTextures[item.id or item.trimmedDecID].failed) then
        return
    end

    local maxConcurrentDownloads = 12
    if #g_DownloadingItems >= maxConcurrentDownloads then
        return
    end

    local url
    local fallbackUrl = "http://psho.me/ICONS/NOIMAGE.PNG"
    local fallbackAvatarUrl = "http://173.225.107.46/HomeLabOS_Resources/Presets/NOIMAGE.PNG"

    if tabLabel == "Tools_Presets" then
        if index > 48 then
            url = fallbackAvatarUrl
        else
            url = "http://173.225.107.46/HomeLabOS_Resources/Presets/" .. item.image_id .. ".PNG"
        end
    elseif tabLabel == "Players Online" then
        if item.imagePath == "Not found" then
            url = nil
        else
            url = "http://scee-home.playstation.net/c.home/prod2/live2/Scenes/" .. item.imagePath
        end
    else
        if item.thumbnail_type == "S" then
            url = "http://173.225.107.46/HomeLabOS_Resources/OBJECTS/" .. item.id .. "/SMALLO.PNG"
        elseif item.thumbnail_type == "L" or item.thumbnail_type == "P" then
            url = "http://173.225.107.46/HomeLabOS_Resources/OBJECTS/" .. item.id .. "/LARGEO.PNG"
        else
            url = fallbackUrl
        end
    end

    if url then
        local resource = Resource.RequestTexture(url, TextureOptions.Default)
        if resource then
            g_GridTextures[item.id or item.trimmedDecID] = {
                resource = resource,
                downloaded = false,
                failed = false,
                status_code = 0,
                texture = nil
            }
            item.texture_resource = resource
            table.insert(g_DownloadingItems, { tabLabel = tabLabel, index = index })
        else
            g_GridTextures[item.id or item.trimmedDecID] = {
                resource = nil,
                downloaded = false,
                failed = true,
                status_code = 0,
                texture = nil
            }
            if tabLabel ~= "Players Online" and url ~= fallbackUrl then
                resource = Resource.RequestTexture(fallbackUrl, TextureOptions.Default)
                if resource then
                    g_GridTextures[item.id or item.trimmedDecID].resource = resource
                    g_GridTextures[item.id or item.trimmedDecID].failed = false
                    item.texture_resource = resource
                    table.insert(g_DownloadingItems, { tabLabel = tabLabel, index = index })
                end
            end
        end
    else
        g_GridTextures[item.id or item.trimmedDecID] = {
            resource = nil,
            downloaded = false,
            failed = true,
            status_code = 0,
            texture = nil
        }
    end
end

function RenderInviteActionPopup(name)
    local renderer = g_Renderer
    local popupWidth = 200
    local buttonHeight = 30
    local spacing = 10
    local padding = 20
    local nameHeight = 30
    local outlineThickness = 1
    local borderThickness = 2


    local buttonLabels
    local numButtons
    if g_SelectedTable == 3 then

        buttonLabels = {"Delete"}
        numButtons = 1
    else

        buttonLabels = {"Accept", "Delete"}
        numButtons = 2
    end


    local popupHeight = nameHeight + (numButtons * buttonHeight) + ((numButtons - 1) * spacing) + padding
    local popupX = (1280 - popupWidth) / 2 + 340
    local popupY = (720 - popupHeight) / 2 - 80


    renderer:DrawRect2d(
        popupX - outlineThickness,
        popupY - outlineThickness,
        popupX + popupWidth + outlineThickness,
        popupY + popupHeight + outlineThickness,
        Vector4.Create(1, 1, 1, 1)
    )


    renderer:DrawRect2d(popupX, popupY, popupX + popupWidth, popupY + popupHeight, Vector4.Create(0, 0, 0, 1))


    local nameText = "Selected: " .. (name or g_SelectedName or "")
    renderer:SetFontScale(0.8, -0.8)
    local textSize = renderer:GetTextSize(nameText)
    local textX = popupX + (popupWidth - textSize:X()) / 2
    local textY = popupY + 10
    renderer:DrawText2d(Vector4.Create(textX, textY, 0), nameText, Vector4.Create(1, 1, 1, 1))


    if g_InvitePopupSelectedButton > numButtons then
        g_InvitePopupSelectedButton = numButtons
    elseif g_InvitePopupSelectedButton < 1 then
        g_InvitePopupSelectedButton = 1
    end


    for i = 1, numButtons do
        local buttonY = popupY + 40 + (i - 1) * (buttonHeight + spacing)
        local isSelected = (i == g_InvitePopupSelectedButton)


        local outlineColor = isSelected and Vector4.Create(0, 1, 0, 1) or Vector4.Create(0.5, 0.5, 0.5, 1)
        renderer:DrawRect2d(
            popupX + 5,
            buttonY,
            popupX + popupWidth - 5,
            buttonY + buttonHeight,
            outlineColor
        )


        renderer:DrawRect2d(
            popupX + 5 + borderThickness,
            buttonY + borderThickness,
            popupX + popupWidth - 5 - borderThickness,
            buttonY + buttonHeight - borderThickness,
            Vector4.Create(0, 0, 0, 1)
        )


        local buttonText = buttonLabels[i]
        local textSize = renderer:GetTextSize(buttonText)
        local textX = popupX + (popupWidth - textSize:X()) / 2
        local textY = buttonY + (buttonHeight - textSize:Y()) / 2 - 12
        renderer:DrawText2d(Vector4.Create(textX, textY, 0), buttonText, Vector4.Create(1, 1, 1, 1))
    end
end
function UIRenderPageContent(bgX, bgY, bgWidth, bgHeight, topBarHeight)
    local renderer = g_Renderer
    local highlightAlpha = (g_ActiveArea == "sidebar") and 0.85 or 0.60
    local colHighlight = Vector4.Create(0.0, 0.4, 0.0, highlightAlpha)
    local buttonHighlightBorderColor = Vector4.Create(0.0, 0.5, 0.0, 1.0)
    local buttonBgColor = Vector4.Create(0.0, 0.0, 0.0, 0.9)
    local textColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)
    local whiteOutlineColor = Vector4.Create(1.0, 1.0, 1.0, 0.4)
    local blackInnerColor = Vector4.Create(0.0, 0.0, 0.0, 1.0)

    local activeTab = g_Tabs[g_ActiveTabIndex]
    if activeTab and activeTab.content then
        local sidebarWidth = 120
        local sidebarHeight = (bgY + bgHeight) - (bgY + topBarHeight)
        local sidebarX = bgX
        local sidebarY = bgY + topBarHeight
        renderer:DrawRect2d(
            sidebarX, sidebarY,
            sidebarX + sidebarWidth, sidebarY + sidebarHeight,
            g_Colors.Black85
        )

        local buttonWidth = 110
        local buttonHeight = 26
        local buttonY = bgY + 90
        local outlineThickness = (g_ActiveArea == "sidebar") and 2 or 1

        if activeTab.label == "Search" and activeTab.content.textbox then
            local textbox = activeTab.content.textbox
            local textboxX = bgX + 5
            local textboxPos = Vector4.Create(textboxX, buttonY, 0)
            textbox.pos = textboxPos

            renderer:SetFontScale(0.8, -0.8)
            local displayText = textbox.text ~= "" and textbox.text or g_Me:GetLocalizedText("")
            local currentTextSize = renderer:GetTextSize(displayText)
            local textPosX = textboxX + (buttonWidth - currentTextSize:X()) / 2
            local textPos = Vector4.Create(textPosX, buttonY + 5, 0)
            renderer:DrawText2d(textPos, displayText, textColor)
            buttonY = buttonY + buttonHeight + 5
        end

        for i, button in ipairs(activeTab.content.buttons) do
            local buttonX = bgX + 5
            local buttonPos = Vector4.Create(buttonX, buttonY, 0)
            button.pos = buttonPos

            renderer:SetFontScale(0.8, -0.8)

            if i == activeTab.selectedButton then
                renderer:DrawRect2d(
                    buttonX - outlineThickness, buttonY - outlineThickness,
                    buttonX + buttonWidth + outlineThickness, buttonY + buttonHeight + outlineThickness,
                    buttonHighlightBorderColor
                )
                renderer:DrawRect2d(
                    buttonX - outlineThickness + 1, buttonY - outlineThickness + 1,
                    buttonX + buttonWidth + outlineThickness - 1, buttonY + buttonHeight + outlineThickness - 1,
                    buttonBgColor
                )
            end

            local buttonText = g_Me:GetLocalizedText(button.localisedText)
            local currentTextSize = renderer:GetTextSize(buttonText)
            local textPosX = buttonX + (buttonWidth - currentTextSize:X()) / 2
            local textPos = Vector4.Create(textPosX, buttonY + 5, 0)
            renderer:DrawText2d(textPos, buttonText, textColor)
            buttonY = buttonY + buttonHeight + 5
        end

        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
        local selectedAction = selectedButton and selectedButton.action

        if activeTab.label == "Players Online" then
    local isLoading = g_LobbyRequestPending

    if isLoading then

        if selectedAction == "whoisonline" and IsLobbyRequestReady() then
            print("[#HomeLabOS v1.01] Lobby request ready, processing whoisonline response")
            local whoIsOnlineItems = {}
            local memContainer = MemoryContainer.Create(g_LobbyResource)
            if memContainer then
                local success, result = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                if success and result then
                    print("[#HomeLabOS v1.01] Successfully read response: " .. tostring(result))
                    for line in result:gmatch("[^\r\n]+") do
                        local playerName, mapId = line:match("^%s*(.-)|(.*)%s*$")
                        if playerName and playerName ~= "" and mapId then
                            table.insert(whoIsOnlineItems, {
                                name = playerName,
                                status = "Online",
                                MapId = mapId,
                                texture_resource = nil,
                                texture = nil
                            })
                            print("[#HomeLabOS v1.01] Added player: " .. playerName .. " | MapId: " .. mapId)
                        end
                    end
                    g_LobbyItems["Players Online"].whoIsOnline = whoIsOnlineItems
                    g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items " .. #whoIsOnlineItems
                    print("[#HomeLabOS v1.01] Total players added: " .. #whoIsOnlineItems)
                else
                    print("[#HomeLabOS v1.01] Error: Failed to read memory container for whoisonline: " .. tostring(result))
                    g_LobbyItems["Players Online"].whoIsOnline = {}
                    g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items 0"
                end
                memContainer = nil
            else
                print("[#HomeLabOS v1.01] Error: Failed to create memory container for whoisonline")
                g_LobbyItems["Players Online"].whoIsOnline = {}
                g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items 0"
            end

            if g_LobbyPostData then
                g_LobbyPostData = nil
            end
            if g_LobbyContainer then
                g_LobbyContainer = nil
            end
            if g_LobbyResource then
                Resource.Release(g_LobbyResource)
                g_LobbyResource = nil
            end
            g_LobbyRequestPending = false
        end


        if g_LobbyRequestPending then
            print("[#HomeLabOS v1.01] Lobby request still pending, displaying loading message")
            renderer:SetFontScale(1.4, -1.4)
            local loadingText = g_Me:GetLocalizedText("kLoading")
            local textSize = renderer:GetTextSize(loadingText)
            local textPos = Vector4.Create(
                bgX + (bgWidth - textSize:X()) / 2 + 65,
                bgY + (bgHeight - textSize:Y()) / 2,
                0
            )
            renderer:DrawText2d(textPos, loadingText, textColor)
        end
    elseif selectedAction == "whoisonline" and not isLoading then

        local listX = bgX + sidebarWidth + 10
        local listY = bgY + topBarHeight + 40
        local listWidthWhoIsOnline = 550
        local listWidthFriends = 220
        local listWidthSentInvites = 530
        local listWidthReceivedInvites = 530
        local headerHeight = 22
        local rowHeight = 30
        local gap = 3
        local maxDisplayRowsWhoIsOnline = 16
        local maxDisplayRowsSentInvites = 7
        local maxDisplayRowsReceivedInvites = 7
        local rowBgColor1 = Vector4.Create(0.0, 0.0, 0.0, 0.5)
        local rowBgColor2 = Vector4.Create(0.15, 0.15, 0.15, 0.5)
        local headerBgColor = Vector4.Create(0.25, 0.25, 0.25, 0.7)
        local friendsListX = listX + listWidthWhoIsOnline + 10
        local sentInvitesListX = friendsListX + listWidthFriends - 220
        local sentInvitesTableHeight = 25 + headerHeight + maxDisplayRowsSentInvites * (rowHeight + gap) - gap
        local listYReceivedInvites = listY + sentInvitesTableHeight + 20
        local borderColor = g_Colors.LightGrey


        g_WhoIsOnlineScrollOffset = g_WhoIsOnlineScrollOffset or 0
        g_FriendsOnlineScrollOffset = g_FriendsOnlineScrollOffset or 0
        g_SentInvitesScrollOffset = g_SentInvitesScrollOffset or 0
        g_ReceivedInvitesScrollOffset = g_ReceivedInvitesScrollOffset or 0


        local function renderTable(tableX, title, listY, isFriendsTable, isSentInvitesTable, isReceivedInvitesTable, scrollOffset, listWidth, maxDisplayRows)

            local titleY = listY - 25
            local tableHeight = 25 + headerHeight + maxDisplayRows * (rowHeight + gap) - gap
            local borderThickness = 1


            renderer:DrawRect2d(
                tableX - borderThickness, titleY - borderThickness,
                tableX + listWidth + borderThickness, titleY,
                borderColor
            )
            renderer:DrawRect2d(
                tableX - borderThickness, titleY + tableHeight,
                tableX + listWidth + borderThickness, titleY + tableHeight + borderThickness,
                borderColor
            )
            renderer:DrawRect2d(
                tableX - borderThickness, titleY - borderThickness,
                tableX, titleY + tableHeight + borderThickness,
                borderColor
            )
            renderer:DrawRect2d(
                tableX + listWidth, titleY - borderThickness,
                tableX + listWidth + borderThickness, titleY + tableHeight + borderThickness,
                borderColor
            )


            renderer:SetFontScale(0.9, -0.9)
            local titleText = title
            local titleSize = renderer:GetTextSize(titleText)
            local titleX = tableX + (listWidth - titleSize:X()) / 2
            renderer:DrawText2d(Vector4.Create(titleX, titleY + 3, 0), titleText, textColor)


            local headers, columnWidths
            if isFriendsTable then
                headers = {"Playername", "Status"}
                columnWidths = {145, 100}
            elseif isSentInvitesTable then
                headers = {"Sent to", "Status", "MapID", "Age"}
                columnWidths = {220, 70, 190, 60}
			elseif isReceivedInvitesTable then
                headers = {"Received from", "Status", "MapID", "Age"}
                columnWidths = {220, 70, 190, 60}
            else
                headers = {"Playername", "Status", "MapID"}
                columnWidths = {220, 70, 240}
            end


            renderer:SetFontScale(0.7, -0.7)
            renderer:DrawRect2d(tableX, listY, tableX + listWidth, listY + headerHeight, headerBgColor)
            local currentX = tableX
            for i, header in ipairs(headers) do
                local textSize = renderer:GetTextSize(header)
                local textY = listY + (headerHeight - textSize:Y()) / 2 - 15
                renderer:DrawText2d(Vector4.Create(currentX + 5, textY, 0), header, textColor)
                currentX = currentX + columnWidths[i]
            end


            local items
            if isReceivedInvitesTable then
                items = g_LobbyItems[activeTab.label] and g_LobbyItems[activeTab.label].receivedInvites or {}
            elseif isSentInvitesTable then
                items = g_LobbyItems[activeTab.label] and g_LobbyItems[activeTab.label].sentInvites or {}
            elseif isFriendsTable then
                items = g_LobbyItems[activeTab.label] and g_LobbyItems[activeTab.label].friends or {}
            else
                items = g_LobbyItems[activeTab.label] and g_LobbyItems[activeTab.label].whoIsOnline or {}
            end
            items = items or {}


            for i = 1, maxDisplayRows do
                local rowY = listY + headerHeight + (i - 1) * (rowHeight + gap)
                local bgColor = (i % 2 == 1) and rowBgColor1 or rowBgColor2
                renderer:DrawRect2d(tableX, rowY, tableX + listWidth, rowY + rowHeight, bgColor)
            end


            local startIndex = scrollOffset + 1
            local endIndex = math.min(scrollOffset + maxDisplayRows, #items)
            if #items == 0 then
                renderer:SetFontScale(1.0, -1.0)
                local noItemsText = isReceivedInvitesTable and "No invites received" or (isSentInvitesTable and "No invites sent" or (isFriendsTable and "No friends online" or "No players online"))
                local textSize = renderer:GetTextSize(noItemsText)
                local textPos = Vector4.Create(
                    tableX + (listWidth - textSize:X()) / 2,
                    listY + headerHeight + (maxDisplayRows * (rowHeight + gap) - gap) / 2 - 10,
                    0
                )
                renderer:DrawText2d(textPos, noItemsText, textColor)
            else
                for i = startIndex, endIndex do
                    local item = items[i]
                    local displayIndex = i - scrollOffset
                    local rowY = listY + headerHeight + (displayIndex - 1) * (rowHeight + gap)


                    if g_ActiveArea == "grid" and g_SelectedTable == (isReceivedInvitesTable and 4 or (isSentInvitesTable and 3 or (isFriendsTable and 2 or 1))) then
                        local selectedItem = isReceivedInvitesTable and g_SelectedReceivedInvitesItem or (isSentInvitesTable and g_SelectedSentInvitesItem or (isFriendsTable and g_SelectedFriendsOnlineItem or g_SelectedWhoIsOnlineItem))
                        if i == selectedItem then
                            local borderThickness = 2
                            local borderColor = g_Colors.GreenHighlight

                            renderer:DrawRect2d(
                                tableX + 2, rowY + 2,
                                tableX + listWidth - 2, rowY + 2 + borderThickness,
                                borderColor
                            )

                            renderer:DrawRect2d(
                                tableX + 2, rowY + rowHeight - 2 - borderThickness,
                                tableX + listWidth - 2, rowY + rowHeight - 2,
                                borderColor
                            )

                            renderer:DrawRect2d(
                                tableX + 2, rowY + 2,
                                tableX + 2 + borderThickness, rowY + rowHeight - 2,
                                borderColor
                            )

                            renderer:DrawRect2d(
                                tableX + listWidth - 2 - borderThickness, rowY + 2,
                                tableX + listWidth - 2, rowY + rowHeight - 2,
                                borderColor
                            )
                        end
                    end


                    local currentX = tableX
                    for col = 1, #headers do
                        local text
                        if col == 1 then
                            text = item.name or "N/A"
                        elseif col == 2 then
                            text = item.status or "N/A"
                        elseif col == 3 and not isFriendsTable then
                            text = item.MapId or "N/A"
                        elseif col == 4 and (isSentInvitesTable or isReceivedInvitesTable) then
                            text = item.age or "N/A"
                        end
                        if text then
                            renderer:DrawText2d(Vector4.Create(currentX + 5, rowY + 10, 0), text, textColor)
                        end
                        currentX = currentX + columnWidths[col]
                    end
                end
            end
        end


        renderTable(listX, "Players Currently Online", listY, false, false, false, g_WhoIsOnlineScrollOffset, listWidthWhoIsOnline, maxDisplayRowsWhoIsOnline)





        renderTable(sentInvitesListX, "Sent Invites", listY, false, true, false, g_SentInvitesScrollOffset, listWidthSentInvites, maxDisplayRowsSentInvites)


        renderTable(sentInvitesListX, "Received Invites", listYReceivedInvites, false, false, true, g_ReceivedInvitesScrollOffset, listWidthReceivedInvites, maxDisplayRowsReceivedInvites)

    elseif #g_LobbyItems[activeTab.label] > 0 or not isLoading then

        local items = g_LobbyItems[activeTab.label]
        for idx, item in ipairs(items) do
            if not item.texture and not (g_GridTextures[item.trimmedDecID] and g_GridTextures[item.trimmedDecID].failed) then
                RequestGridItemTexture(item, "Players Online", idx)
            end
        end

        for i = #g_DownloadingItems, 1, -1 do
            local download = g_DownloadingItems[i]
            if download.tabLabel == "Players Online" then
                local item = items[download.index]
                if item then
                    local textureEntry = g_GridTextures[item.trimmedDecID]
                    if textureEntry then
                        if Resource.IsLoaded(textureEntry.resource) then
                            textureEntry.downloaded = true
                            textureEntry.texture = Resource.GetData(textureEntry.resource)
                            if textureEntry.texture then
                                item.texture = textureEntry.texture
                            else
                                textureEntry.failed = true
                                textureEntry.status_code = 0
                                Resource.Release(textureEntry.resource)
                                textureEntry.resource = nil
                                item.texture_resource = nil
                                g_GridTextures[item.trimmedDecID] = nil
                            end
                            table.remove(g_DownloadingItems, i)
                        elseif not Resource.IsLoading(textureEntry.resource) then
                            local statusCode = Resource.GetStatusCode(textureEntry.resource)
                            textureEntry.failed = true
                            textureEntry.status_code = statusCode
                            Resource.Release(textureEntry.resource)
                            textureEntry.resource = nil
                            item.texture_resource = nil
                            table.remove(g_DownloadingItems, i)
                        end
                    else
                        table.remove(g_DownloadingItems, i)
                    end
                else
                    table.remove(g_DownloadingItems, i)
                end
            end
        end

        local tableX = bgX + sidebarWidth + 10
        local tableY = bgY + topBarHeight + 10
        local headerHeight = 26
        local rowHeight = 52
        local gap = 4
        local columnWidths = {110, 80, 450, 240, 70, 80, 60}
        local headers
        if selectedAction == "picks" or selectedAction == "populartoday" then
            headers = {"Thumbnail", "SceneID", "Name", "MapID", "Type", "Last Played", "Rank"}
        else
            headers = {"Thumbnail", "SceneID", "Name", "MapID", "Type", "Uptime", "Players"}
        end
        local headerBgColor = Vector4.Create(0.25, 0.25, 0.25, 0.7)
        local rowBgColor1 = Vector4.Create(0.0, 0.0, 0.0, 0.5)
        local rowBgColor2 = Vector4.Create(0.15, 0.15, 0.15, 0.5)

        local totalWidth = 0
        for _, width in ipairs(columnWidths) do
            totalWidth = totalWidth + width
        end

        renderer:SetFontScale(0.7, -0.7)
        renderer:DrawRect2d(tableX, tableY, tableX + totalWidth, tableY + headerHeight, headerBgColor)
        local currentX = tableX
        for i, header in ipairs(headers) do
            local textSize = renderer:GetTextSize(header)
            local textY = tableY + (headerHeight - textSize:Y()) / 2 - 18
            renderer:DrawText2d(Vector4.Create(currentX + 5, textY, 0), header, textColor)
            currentX = currentX + columnWidths[i]
        end
        renderer:SetFontScale(0.8, -0.8)

        for i = 1, 10 do
            local rowY = tableY + headerHeight + (i - 1) * (rowHeight + gap)
            local bgColor = (i % 2 == 1) and rowBgColor1 or rowBgColor2
            renderer:DrawRect2d(tableX, rowY, tableX + totalWidth, rowY + rowHeight, bgColor)

            if i == g_SelectedLobbyItem and g_ActiveArea == "grid" then
                local borderThickness = 2
                local borderColor = g_Colors.GreenHighlight
                renderer:DrawRect2d(
                    tableX - borderThickness, rowY - borderThickness,
                    tableX + totalWidth + borderThickness, rowY,
                    borderColor
                )
                renderer:DrawRect2d(
                    tableX - borderThickness, rowY + rowHeight,
                    tableX + totalWidth + borderThickness, rowY + rowHeight + borderThickness,
                    borderColor
                )
                renderer:DrawRect2d(
                    tableX - borderThickness, rowY - borderThickness,
                    tableX, rowY + rowHeight + borderThickness,
                    borderColor
                )
                renderer:DrawRect2d(
                    tableX + totalWidth, rowY - borderThickness,
                    tableX + totalWidth + borderThickness, rowY + rowHeight + borderThickness,
                    borderColor
                )
            end

            local item = items[i]
            if item then
                currentX = tableX
                local textureEntry = g_GridTextures[item.trimmedDecID]
                if textureEntry and textureEntry.downloaded and textureEntry.texture then
                    local texture = textureEntry.texture
                    local textureWidth = texture:GetWidth()
                    local textureHeight = texture:GetHeight()
                    local cellWidth = columnWidths[1]
                    local cellHeight = rowHeight
                    local scale = math.min(cellWidth / textureWidth, cellHeight / textureHeight)
                    local renderWidth = textureWidth * scale
                    local renderHeight = textureHeight * scale
                    local offsetX = (cellWidth - renderWidth) / 2
                    local offsetY = (cellHeight - renderHeight) / 2
                    local topLeftX = currentX + offsetX
                    local topLeftY = rowY + offsetY
                    local bottomRightX = topLeftX + renderWidth
                    local bottomRightY = topLeftY + renderHeight
                    renderer:DrawRect2d(
                        Vector4.Create(topLeftX, bottomRightY, 0, 0),
                        Vector4.Create(bottomRightX, topLeftY, 0, 0),
                        Vector4.Create(1, 1, 1, 1),
                        texture
                    )
                else
                    local statusText = "No Image"
                    if textureEntry and not textureEntry.failed then
                        statusText = "Loading..."
                    end
                    renderer:DrawText2d(Vector4.Create(currentX + 0, rowY + 17, 0), statusText, textColor)
                end
                currentX = currentX + columnWidths[1]
                renderer:DrawText2d(Vector4.Create(currentX + 5, rowY + 17, 0), item.trimmedDecID or "N/A", textColor)
                currentX = currentX + columnWidths[2]
                renderer:DrawText2d(Vector4.Create(currentX + 5, rowY + 17, 0), item.psvName or "N/A", textColor)
                currentX = currentX + columnWidths[3]
                renderer:DrawText2d(Vector4.Create(currentX + 5, rowY + 17, 0), item.lobbyName or "N/A", textColor)
                currentX = currentX + columnWidths[4]
                renderer:DrawText2d(Vector4.Create(currentX + 5, rowY + 17, 0), item.accessType or "N/A", textColor)
                currentX = currentX + columnWidths[5]
                renderer:DrawText2d(Vector4.Create(currentX + 5, rowY + 17, 0), tostring(item.upTime or "N/A"), textColor)
                currentX = currentX + columnWidths[6]
                renderer:DrawText2d(Vector4.Create(currentX + 5, rowY + 17, 0), tostring(item.clientCount or 0), textColor)
            end
        end
    else
        renderer:SetFontScale(1.0, -1.0)
        local noItemsText = "No items to display"
        local textSize = renderer:GetTextSize(noItemsText)
        local textPos = Vector4.Create(
            bgX + (bgWidth - textSize:X()) / 2 + 65,
            bgY + (bgHeight - textSize:Y()) / 2,
            0
        )
        renderer:DrawText2d(textPos, noItemsText, textColor)
    end


        elseif activeTab.label == "Tools" and selectedAction == "rtrc_presets" then
            local items = g_GridItems["Tools_Presets"] or {}
            local rows = 6
            local cols = 12
            local itemWidth = 80
            local itemHeight = 80
            local spacingX = 11
            local spacingY = 8
            local labelHeight = 10
            local startX = bgX + sidebarWidth + 8
            local startY = bgY + topBarHeight + 8

            for idx = 1, math.min(#items, 72) do
                local item = items[idx]
                if not item.texture and not (g_GridTextures[item.id] and g_GridTextures[item.id].failed) then
                    RequestGridItemTexture(item, "Tools_Presets", idx)
                end
            end

            for i = #g_DownloadingItems, 1, -1 do
                local download = g_DownloadingItems[i]
                local downloadingTabLabel = download.tabLabel
                local downloadingIdx = download.index
                if downloadingTabLabel == "Tools_Presets" and downloadingIdx <= #items then
                    local item = items[downloadingIdx]
                    local textureEntry = g_GridTextures[item.id]
                    if textureEntry then
                        if Resource.IsLoading(textureEntry.resource) then
                        elseif Resource.IsLoaded(textureEntry.resource) then
                            textureEntry.downloaded = true
                            textureEntry.texture = Resource.GetData(textureEntry.resource)
                            if textureEntry.texture then
                                item.texture = textureEntry.texture
                                item.texture_resource = textureEntry.resource
                            else
                                textureEntry.failed = true
                                textureEntry.status_code = 0
                                Resource.Release(textureEntry.resource)
                                textureEntry.resource = nil
                                item.texture_resource = nil
                                g_GridTextures[item.id] = nil
                            end
                            table.remove(g_DownloadingItems, i)
                        else
                            local statusCode = Resource.GetStatusCode(textureEntry.resource)
                            textureEntry.failed = true
                            textureEntry.status_code = statusCode
                            Resource.Release(textureEntry.resource)
                            textureEntry.resource = nil
                            item.texture_resource = nil
                            local fallbackUrl = "http://psho.me/ICONS/NOIMAGE.PNG"
                            local resource = Resource.RequestTexture(fallbackUrl, TextureOptions.Default)
                            if resource then
                                textureEntry.resource = resource
                                textureEntry.failed = false
                                textureEntry.downloaded = false
                                item.texture_resource = resource
                            else
                                table.remove(g_DownloadingItems, i)
                                g_GridTextures[item.id] = nil
                            end
                        end
                    else
                        table.remove(g_DownloadingItems, i)
                    end
                else
                    local item = g_GridItems[downloadingTabLabel] and g_GridItems[downloadingTabLabel][downloadingIdx]
                    if item and g_GridTextures[item.id] and g_GridTextures[item.id].resource then
                        Resource.Release(g_GridTextures[item.id].resource)
                        g_GridTextures[item.id] = nil
                        item.texture_resource = nil
                    end
                    table.remove(g_DownloadingItems, i)
                end
            end

            for idx = 1, math.min(#items, 72) do
                local item = items[idx]
                local row = math.floor((idx - 1) / cols)
                local col = (idx - 1) % cols
                local isHighlighted = (g_ActiveArea == "grid" and idx == g_SelectedGridItem)
                local highlightOffsetX = isHighlighted and 5 or 0
                local highlightOffsetY = isHighlighted and 3 or 0
                local itemX = startX + col * (itemWidth + spacingX) - highlightOffsetX
                local itemY = startY + row * (itemHeight + spacingY + labelHeight) - highlightOffsetY
                local renderWidth = itemWidth + 2 * highlightOffsetX
                local renderHeight = itemHeight + 2 * highlightOffsetX

                if not item.texture then
                    renderer:DrawRect2d(
                        itemX, itemY,
                        itemX + renderWidth, itemY + renderHeight,
                        g_Colors.White
                    )
                end

                if item.texture then
                    local textureWidth = item.texture:GetWidth()
                    local textureHeight = item.texture:GetHeight()
                    local scaleX = renderWidth / textureWidth
                    local scaleY = renderHeight / textureHeight
                    local scale = math.min(scaleX, scaleY)
                    local scaledWidth = textureWidth * scale
                    local scaledHeight = textureHeight * scale
                    local offsetX = (renderWidth - scaledWidth) / 2
                    local offsetY = (renderHeight - scaledHeight) / 2
                    local bottomLeftX = itemX + offsetX
                    local bottomLeftY = itemY + offsetY
                    local topRightX = bottomLeftX + scaledWidth
                    local topRightY = bottomLeftY + scaledHeight
                    local bottomLeft = Vector4.Create(bottomLeftX, topRightY, 0, 0)
                    local topRight = Vector4.Create(topRightX, bottomLeftY, 0, 0)
                    local rgba = Vector4.Create(1, 1, 1, 1)
                    renderer:DrawRect2d(bottomLeft, topRight, rgba, item.texture)
                end

                local trimmedName = TrimTextToFit(item.name, renderWidth - 5)
                local labelPos = Vector4.Create(
                    itemX + renderWidth / 2,
                    itemY + renderHeight + 1 + (isHighlighted and -1 or 0),
                    0
                )
                renderer:SetFontScale(0.65, -0.65)
                renderer:SetFontHorzAlignment("center")
                renderer:DrawText2d(labelPos, trimmedName, g_Colors.White)
                renderer:SetFontHorzAlignment("left")

                if isHighlighted then
                    local borderThickness = 3
                    local highlightYBottom = itemY + renderHeight + labelHeight + 0
                    renderer:DrawRect2d(
                        itemX - borderThickness, itemY - borderThickness + 1,
                        itemX + renderWidth + borderThickness, itemY + 1,
                        g_Colors.GreenHighlight
                    )
                    renderer:DrawRect2d(
                        itemX - borderThickness, highlightYBottom + 1,
                        itemX + renderWidth + borderThickness, highlightYBottom + borderThickness + 1,
                        g_Colors.GreenHighlight
                    )
                    renderer:DrawRect2d(
                        itemX - borderThickness, itemY - borderThickness + 1,
                        itemX, highlightYBottom + borderThickness + 1,
                        g_Colors.GreenHighlight
                    )
                    renderer:DrawRect2d(
                        itemX + renderWidth, itemY - borderThickness + 1,
                        itemX + renderWidth + borderThickness, highlightYBottom + borderThickness + 1,
                        g_Colors.GreenHighlight
                    )
                end
            end
        elseif activeTab.label == "Tools" and selectedAction == "rtrc_general" then
            local gridDef = activeTab.content.grid_buttons[selectedAction]
            local buttonSets = gridDef.buttons
            local columnWidth = 128
            local spacingX = 9
            local buttonHeight = 25
            local spacingY = 10
            local startX = bgX + 128 + 6 + 5 - 10
            local tabHeight = 22
            local tabY = bgY + topBarHeight - tabHeight - 5
            local startY = tabY + tabHeight + 5 + 5 + 23

            renderer:SetFontScale(0.9, -0.9)
            local commandsLabelText = "Basics"
            local commandsTextSize = renderer:GetTextSize(commandsLabelText)
            local commandsTextPos = Vector4.Create(
                startX + (columnWidth * 8 + spacingX * 7 - commandsTextSize:X()) / 2,
                startY - 20,
                0
            )
            renderer:DrawText2d(commandsTextPos, commandsLabelText, textColor)

            local rows = 4
            local cols = 8
            local buttonIndex = 1

            for row = 1, rows do
                for col = 1, cols do
                    local setIndex = math.ceil(buttonIndex / 16)
                    local indexInSet = buttonIndex - (setIndex - 1) * 16
                    local colInSet = math.ceil(indexInSet / 2)
                    local rowInSet = indexInSet % 2 == 1 and 1 or 2
                    local button = buttonSets[setIndex][colInSet][rowInSet]
                    if button then
                        local buttonX = startX + (col - 1) * (columnWidth + spacingX)
                        local buttonY = startY + (row - 1) * (buttonHeight + spacingY)
                        renderer:DrawRect2d(
                            buttonX - 1, buttonY - 1,
                            buttonX + columnWidth + 1, buttonY + buttonHeight + 1,
                            whiteOutlineColor
                        )
                        renderer:DrawRect2d(
                            buttonX, buttonY,
                            buttonX + columnWidth, buttonY + buttonHeight,
                            blackInnerColor
                        )
                        local isSelected = (g_ActiveArea == "grid" and col == g_SelectedButtonCol and row == g_SelectedButtonRow)
                        if isSelected then
                            renderer:DrawRect2d(buttonX - 2, buttonY - 2, buttonX + columnWidth + 2, buttonY + buttonHeight + 2, buttonHighlightBorderColor)
                            renderer:DrawRect2d(buttonX, buttonY, buttonX + columnWidth, buttonY + buttonHeight, buttonBgColor)
                        else
                            renderer:DrawRect2d(buttonX, buttonY, buttonX + columnWidth, buttonY + buttonHeight, g_Colors.Black05)
                        end
                        renderer:SetFontScale(0.7, -0.7)
                        local buttonText = g_Me:GetLocalizedText(button.localisedText)
                        local buttonTextSize = renderer:GetTextSize(buttonText)
                        local buttonTextPos = Vector4.Create(
                            buttonX + (columnWidth - buttonTextSize:X()) / 2,
                            buttonY + (buttonHeight - buttonTextSize:Y()) / 2 - 12,
                            0
                        )
                        renderer:DrawText2d(buttonTextPos, buttonText, textColor)
                        buttonIndex = buttonIndex + 1
                    end
                end
            end

            local toggles = gridDef.toggles
            if toggles then
                local toggleRows = 8
                local toggleCols = 4
                local toggleTileWidth = 265
                local toggleTileHeight = 25
                local toggleSpacingX = 10
                local toggleSpacingY = 5
                local toggleStartX = startX
                local toggleStartY = startY + 4 * (buttonHeight + spacingY) + 20
                local gapHeight = 25

                renderer:SetFontScale(0.9, -0.9)
                local basicsLabelText = "Toggles"
                local basicsTextSize = renderer:GetTextSize(basicsLabelText)
                local basicsTextPos = Vector4.Create(
                    toggleStartX + (toggleTileWidth * 4 + toggleSpacingX * 3 - basicsTextSize:X()) / 2,
                    toggleStartY - 20,
                    0
                )
                renderer:DrawText2d(basicsTextPos, basicsLabelText, textColor)

                for idx = 1, #toggles do
                    local toggle = toggles[idx]
                    local row = math.floor((idx - 1) / toggleCols) + 1
                    local col = (idx - 1) % toggleCols + 1
                    local gapOffset = 0
                    if row > 6 then
                        gapOffset = 2 * gapHeight
                    elseif row > 3 then
                        gapOffset = gapHeight
                    end
                    local toggleX = toggleStartX + (col - 1) * (toggleTileWidth + toggleSpacingX)
                    local toggleY = toggleStartY + (row - 1) * (toggleTileHeight + toggleSpacingY) + gapOffset

                    if row == 4 and col == 1 then
                        renderer:SetFontScale(0.9, -0.9)
                        local placeholderLabelText = "3D Overlays"
                        local placeholderTextSize = renderer:GetTextSize(placeholderLabelText)
                        local placeholderTextPos = Vector4.Create(
                            toggleStartX + (toggleTileWidth * 4 + toggleSpacingX * 3 - placeholderTextSize:X()) / 2,
                            toggleY - 18,
                            0
                        )
                        renderer:DrawText2d(placeholderTextPos, placeholderLabelText, textColor)
                    end
                    if row == 7 and col == 1 then
                        renderer:SetFontScale(0.9, -0.9)
                        local placeholderLabelText = "2D Overlays"
                        local placeholderTextSize = renderer:GetTextSize(placeholderLabelText)
                        local placeholderTextPos = Vector4.Create(
                            toggleStartX + (toggleTileWidth * 4 + toggleSpacingX * 3 - placeholderTextSize:X()) / 2,
                            toggleY - 18,
                            0
                        )
                        renderer:DrawText2d(placeholderTextPos, placeholderLabelText, textColor)
                    end

                    renderer:DrawRect2d(
                        toggleX - 1, toggleY - 1,
                        toggleX + toggleTileWidth + 1, toggleY + toggleTileHeight + 1,
                        whiteOutlineColor
                    )
                    renderer:DrawRect2d(
                        toggleX, toggleY,
                        toggleX + toggleTileWidth, toggleY + toggleTileHeight,
                        blackInnerColor
                    )
                    local isSelected = (g_ActiveArea == "toggles" and col == g_SelectedButtonCol and row == g_SelectedButtonRow)
                    if isSelected then
                        renderer:DrawRect2d(
                            toggleX - 2, toggleY - 2,
                            toggleX + toggleTileWidth + 2, toggleY + toggleTileHeight + 2,
                            buttonHighlightBorderColor
                        )
                        renderer:DrawRect2d(
                            toggleX, toggleY,
                            toggleX + toggleTileWidth, toggleY + toggleTileHeight,
                            buttonBgColor
                        )
                    else
                        renderer:DrawRect2d(
                            toggleX, toggleY,
                            toggleX + toggleTileWidth, toggleY + toggleTileHeight,
                            g_Colors.Black05
                        )
                    end
                    local labelText = g_Me:GetLocalizedText(toggle.localisedText)
                    RenderSmallToggle(toggleX, toggleY, toggle.state, isSelected, labelText, toggleX, toggleTileWidth)
                end
            end
        elseif activeTab.label == "Male Clothing" or
               activeTab.label == "Female Clothing" or
               activeTab.label == "Portables" or
               activeTab.label == "Furniture" or
               activeTab.label == "Scenes" or
               activeTab.label == "Search" or
               activeTab.label == "MyInventory" then
            local items = g_GridItems[activeTab.label] or {}
            local responseText = g_CategoryResponses[activeTab.label]
            local isLoading = g_CategoryRequestPending or g_PageChangeInProgress or
                              (activeTab.label == "Search" and g_SearchRequestPending) or
                              (activeTab.label == "MyInventory" and g_InventoryRefreshPending)

            if isLoading then
                renderer:SetFontScale(1.4, -1.4)
                local loadingText = g_Me:GetLocalizedText("kLoading")
                local textSize = renderer:GetTextSize(loadingText)
                local textPos = Vector4.Create(
                    bgX + (bgWidth - textSize:X()) / 2 + 65,
                    bgY + (bgHeight - textSize:Y()) / 2,
                    0
                )
                renderer:DrawText2d(textPos, loadingText, textColor)
            else
                if responseText and responseText ~= "" then
                    if responseText == g_Me:GetLocalizedText("kRequestTimedOut") or
                       responseText == g_Me:GetLocalizedText("kMemoryContainerFailed") or
                       responseText == g_Me:GetLocalizedText("kEmptyResponse") or
                       responseText == g_Me:GetLocalizedText("kReadMemoryFailed") then
                        local responseAreaX = bgX + 10
                        local responseAreaWidth = bgWidth - 20
                        local responseAreaY = bgY + 40
                        local responseAreaHeight = bgHeight - 48
                        local responseBgColor = Vector4.Create(0.0, 0.0, 0.0, 0.85)
                        renderer:DrawRect2d(
                            responseAreaX, responseAreaY,
                            responseAreaX + responseAreaWidth, responseAreaY + responseAreaHeight,
                            responseBgColor
                        )
                        local textPos = Vector4.Create(responseAreaX + 10, responseAreaY + 10, 0)
                        renderer:DrawText2d(textPos, responseText, g_Colors.White80)
                    else
                        if #items == 0 then
                            local lines = {}
                            for line in responseText:gmatch("[^\r\n]+") do
                                table.insert(lines, line)
                            end
                            if #lines >= 1 then
                                local pageInfo = lines[1]
                                local currentPageStr, totalPagesStr = pageInfo:match("Page (%d+) of (%d+)")
                                if currentPageStr and totalPagesStr then
                                    local currentPage = tonumber(currentPageStr) or 1
                                    local totalPages = tonumber(totalPagesStr) or 1
                                    if activeTab.label == "Search" then
                                        g_CurrentPage["Search"] = currentPage
                                        g_TotalPages["Search"] = totalPages
                                        g_CategoryPageInfo["Search"] = pageInfo
                                    else
                                        local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
                                        if selectedButton then
                                            g_CurrentPage[activeTab.label] = g_CurrentPage[activeTab.label] or {}
                                            g_CurrentPage[activeTab.label][selectedButton.action] = currentPage
                                            g_TotalPages[activeTab.label] = g_TotalPages[activeTab.label] or {}
                                            g_TotalPages[activeTab.label][selectedButton.action] = totalPages
                                            g_CategoryPageInfo[activeTab.label] = g_CategoryPageInfo[activeTab.label] or {}
                                            g_CategoryPageInfo[activeTab.label][selectedButton.action] = pageInfo
                                        end
                                    end
                                end
                                for idx = 2, #lines do
                                    local id, name, thumbnail_type, category = lines[idx]:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
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
                                g_GridItems[activeTab.label] = items
                            end
                        end
                    end
                end

                if #items > 0 then
                    local rows = 5
                    local cols = 6
                    local itemWidth = 170
                    local itemHeight = 94
                    local spacingX = 13
                    local spacingY = 9
                    local labelHeight = 16
                    local tabHeight = 25
                    local tabY = bgY + topBarHeight - tabHeight - 5
                    local startX = bgX + 128 + 6 + 5 - 10 + 2
                    local startY = tabY + tabHeight + 5 + 5 + 3

                    for idx, item in ipairs(items) do
                        if not item.texture and not (g_GridTextures[item.id] and g_GridTextures[item.id].failed) then
                            RequestGridItemTexture(item, activeTab.label, idx)
                        end
                    end

                    for i = #g_DownloadingItems, 1, -1 do
                        local download = g_DownloadingItems[i]
                        local downloadingTabLabel = download.tabLabel
                        local downloadingIdx = download.index
                        if downloadingTabLabel == activeTab.label and downloadingIdx <= #items then
                            local item = items[downloadingIdx]
                            local textureEntry = g_GridTextures[item.id]
                            if textureEntry then
                                if Resource.IsLoading(textureEntry.resource) then
                                elseif Resource.IsLoaded(textureEntry.resource) then
                                    textureEntry.downloaded = true
                                    textureEntry.texture = Resource.GetData(textureEntry.resource)
                                    if textureEntry.texture then
                                        item.texture = textureEntry.texture
                                        item.texture_resource = textureEntry.resource
                                    else
                                        textureEntry.failed = true
                                        textureEntry.status_code = 0
                                        Resource.Release(textureEntry.resource)
                                        textureEntry.resource = nil
                                        item.texture_resource = nil
                                        g_GridTextures[item.id] = nil
                                    end
                                    table.remove(g_DownloadingItems, i)
                                else
                                    local statusCode = Resource.GetStatusCode(textureEntry.resource)
                                    textureEntry.failed = true
                                    textureEntry.status_code = statusCode
                                    Resource.Release(textureEntry.resource)
                                    textureEntry.resource = nil
                                    item.texture_resource = nil
                                    local fallbackUrl = "http://psho.me/ICONS/NOIMAGE.PNG"
                                    local resource = Resource.RequestTexture(fallbackUrl, TextureOptions.Default)
                                    if resource then
                                        textureEntry.resource = resource
                                        textureEntry.failed = false
                                        textureEntry.downloaded = false
                                        item.texture_resource = resource
                                    else
                                        table.remove(g_DownloadingItems, i)
                                        g_GridTextures[item.id] = nil
                                    end
                                end
                            else
                                table.remove(g_DownloadingItems, i)
                            end
                        else
                            local item = g_GridItems[downloadingTabLabel] and g_GridItems[downloadingTabLabel][downloadingIdx]
                            if item and g_GridTextures[item.id] and g_GridTextures[item.id].resource then
                                Resource.Release(g_GridTextures[item.id].resource)
                                g_GridTextures[item.id] = nil
                                item.texture_resource = nil
                            end
                            table.remove(g_DownloadingItems, i)
                        end
                    end

                    for idx, item in ipairs(items) do
                        local row = math.floor((idx - 1) / cols)
                        local col = (idx - 1) % cols
                        local isHighlighted = (g_ActiveArea == "grid" and idx == g_SelectedGridItem)
                        local highlightOffsetX = isHighlighted and 5 or 0
                        local highlightOffsetY = isHighlighted and 3 or 0
                        local itemX = startX + col * (itemWidth + spacingX) - highlightOffsetX
                        local itemY = startY + row * (itemHeight + spacingY + labelHeight) - highlightOffsetY
                        local renderWidth = itemWidth + 2 * highlightOffsetX
                        local renderHeight = itemHeight + 2 * highlightOffsetX

                        if not item.texture then
                            renderer:DrawRect2d(
                                itemX, itemY,
                                itemX + renderWidth, itemY + renderHeight,
                                g_Colors.White
                            )
                        end

                        if item.texture then
                            local textureWidth = item.texture:GetWidth()
                            local textureHeight = item.texture:GetHeight()
                            local scaleX = renderWidth / textureWidth
                            local scaleY = renderHeight / textureHeight
                            local scale = math.min(scaleX, scaleY)
                            local scaledWidth = textureWidth * scale
                            local scaledHeight = textureHeight * scale
                            local offsetX = (renderWidth - scaledWidth) / 2
                            local offsetY = (renderHeight - scaledHeight) / 2
                            local bottomLeftX = itemX + offsetX
                            local bottomLeftY = itemY + offsetY
                            local topRightX = bottomLeftX + scaledWidth
                            local topRightY = bottomLeftY + scaledHeight
                            local bottomLeft = Vector4.Create(bottomLeftX, topRightY, 0, 0)
                            local topRight = Vector4.Create(topRightX, bottomLeftY, 0, 0)
                            local rgba = Vector4.Create(1, 1, 1, 1)
                            renderer:DrawRect2d(bottomLeft, topRight, rgba, item.texture)
                        else
                            renderer:SetFontScale(0.7, -0.7)
                            renderer:SetFontHorzAlignment("center")
                            local isDownloading = false
                            for _, download in ipairs(g_DownloadingItems) do
                                if download.tabLabel == activeTab.label and download.index == idx then
                                    isDownloading = true
                                    break
                                end
                            end
                            local loadingText = isDownloading and g_Me:GetLocalizedText("kLoading") or g_Me:GetLocalizedText("kImageUnavailable")
                            renderer:DrawText2d(
                                Vector4.Create(itemX + renderWidth / 2, itemY + renderHeight / 2, 0),
                                loadingText,
                                Vector4.Create(1.0, 1.0, 1.0, 1.0)
                            )
                            renderer:SetFontHorzAlignment("left")
                        end

                        local trimmedName = TrimTextToFit(item.name, renderWidth - 5)
                        local labelPos = Vector4.Create(
                            itemX + renderWidth / 2,
                            itemY + renderHeight + 3 + (isHighlighted and -1 or 0),
                            0
                        )
                        renderer:SetFontScale(0.7, -0.7)
                        renderer:SetFontHorzAlignment("center")
                        renderer:DrawText2d(labelPos, trimmedName, g_Colors.White)
                        renderer:SetFontHorzAlignment("left")

                        if isHighlighted then
                            local borderThickness = 3
                            local highlightYBottom = itemY + renderHeight + labelHeight - 2
                            renderer:DrawRect2d(
                                itemX - borderThickness, itemY - borderThickness + 1,
                                itemX + renderWidth + borderThickness, itemY + 1,
                                g_Colors.GreenHighlight
                            )
                            renderer:DrawRect2d(
                                itemX - borderThickness, highlightYBottom + 1,
                                itemX + renderWidth + borderThickness, highlightYBottom + borderThickness + 1,
                                g_Colors.GreenHighlight
                            )
                            renderer:DrawRect2d(
                                itemX - borderThickness, itemY - borderThickness + 1,
                                itemX, highlightYBottom + borderThickness + 1,
                                g_Colors.GreenHighlight
                            )
                            renderer:DrawRect2d(
                                itemX + renderWidth, itemY - borderThickness + 1,
                                itemX + renderWidth + borderThickness, highlightYBottom + borderThickness + 1,
                                g_Colors.GreenHighlight
                            )
                        end
                    end

                    if activeTab.label == "Male Clothing" or
                       activeTab.label == "Female Clothing" or
                       activeTab.label == "Portables" or
                       activeTab.label == "Furniture" or
                       activeTab.label == "Scenes" or
                       activeTab.label == "Search" or
                       activeTab.label == "MyInventory" then
                        local currentPage, totalPages
                        if activeTab.label == "Search" then
                            currentPage = g_CurrentPage["Search"] or 1
                            totalPages = g_TotalPages["Search"] or 1
                        else
                            local selectedButton = activeTab.content.buttons[activeTab.selectedButton]
                            if selectedButton and g_CurrentPage[activeTab.label] and g_TotalPages[activeTab.label] then
                                currentPage = g_CurrentPage[activeTab.label][selectedButton.action] or 1
                                totalPages = g_TotalPages[activeTab.label][selectedButton.action] or 1
                            else
                                currentPage = 1
                                totalPages = 1
                            end
                        end
                        if totalPages > 1 then
                            local scrollbarWidth = 5
                            local rightBarWidth = 16
                            local rightBarX = bgX + bgWidth - rightBarWidth
                            local scrollbarX = rightBarX + (rightBarWidth - scrollbarWidth) / 2
                            local scrollbarY = startY
                            local itemHeight = 94
                            local spacingY = 9
                            local labelHeight = 16
                            local gridHeight = 5 * (itemHeight + spacingY + labelHeight) - spacingY
                            local scrollbarHeight = math.min(bgHeight - topBarHeight - (startY - bgY), gridHeight)
                            local minThumbHeight = 20
                            renderer:DrawRect2d(
                                scrollbarX, scrollbarY,
                                scrollbarX + scrollbarWidth, scrollbarY + scrollbarHeight,
                                g_Colors.MediumGrey
                            )
                            local itemsPerPage = 30
                            local thumbHeight = math.max(minThumbHeight, (itemsPerPage / (itemsPerPage * totalPages)) * scrollbarHeight)
                            local thumbY = scrollbarY + ((currentPage - 1) / math.max(1, totalPages - 1)) * (scrollbarHeight - thumbHeight)
                            renderer:DrawRect2d(
                                scrollbarX, thumbY,
                                scrollbarX + scrollbarWidth, thumbY + thumbHeight,
                                g_Colors.LightGrey
                            )
                        end
                    end
                end
            end
        elseif activeTab.label == "Settings" then
            local selectedAction = activeTab.content.buttons[activeTab.selectedButton].action
            if selectedAction == "basic_settings" then
                local toggles = activeTab.content.toggles.basic_settings
                    if toggles then
                        local toggleStartX = bgX + 630
                        local toggleStartY = bgY + topBarHeight + 10
                        local toggleSpacing = 40
                        for i, toggle in ipairs(toggles) do
                            local toggleY = toggleStartY + (i - 1) * toggleSpacing
                            RenderToggle(toggleStartX, toggleY + 15, toggle.state, g_ActiveArea == "toggles" and i == g_SelectedToggle, toggle.label, bgX + 130)
                        end
                    end
                elseif selectedAction == "advanced_settings" then
                    local toggles = activeTab.content.toggles.advanced_settings
                    if toggles then
                        local toggleStartX = bgX + 630
                        local toggleStartY = bgY + topBarHeight + 10
                        local toggleSpacing = 40
                        for i, toggle in ipairs(toggles) do
                            local toggleY = toggleStartY + (i - 1) * toggleSpacing
                            RenderToggle(toggleStartX, toggleY + 15, toggle.state, g_ActiveArea == "toggles" and i == g_SelectedToggle, toggle.label, bgX + 130)
                        end
                    end
                elseif selectedAction == "System_info" then
                    if g_SystemInfoRequestPending and IsSystemInfoRequestReady() then
                        local memContainer = MemoryContainer.Create(g_SystemInfoResource)
                        if memContainer then
                            local success, result = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                            if success and result then
                                g_SystemInfoResponse = result
                            else
                                g_SystemInfoResponse = "Error: Failed to read memory container"
                            end
                            memContainer = nil
                        else
                            g_SystemInfoResponse = "Error: Failed to create memory container"
                        end
                        ResetSystemInfoRequest()
                    end
                    if not g_SystemInfoRequestPending and not g_SystemInfoResponse then
                        RequestSystemInfo()
                    end
                    if g_SystemInfoRequestPending then
                        renderer:SetFontScale(1.4, -1.4)
                        local loadingText = g_Me:GetLocalizedText("kLoading")
                        local textSize = renderer:GetTextSize(loadingText)
                        local textPos = Vector4.Create(
                            bgX + (bgWidth - textSize:X()) / 2 + 65,
                            bgY + (bgHeight - textSize:Y()) / 2,
                            0
                        )
                        renderer:DrawText2d(textPos, loadingText, textColor)
                    elseif g_SystemInfoResponse then
                        local marginX = 200
                        local marginY = 50
                        local textAreaX = bgX + marginX
                        local textAreaY = bgY + topBarHeight + marginY
                        local textAreaWidth = bgWidth - 2 * marginX
                        local textAreaHeight = bgHeight - topBarHeight - 2 * marginY
                        local lines = {}
                        for line in g_SystemInfoResponse:gmatch("[^\r\n]+") do
                            table.insert(lines, line)
                        end
                        local scales = { H1 = 1.6, P = 0.8, H2 = 1.4, H3 = 1.2, H4 = 1.0, C1 = 1.2, C2 = 1.0, C3 = 0.8 }
                        local alignments = { H1 = "center", P = "left", H2 = "left", H3 = "center", H4 = "center", C1 = "center", C2 = "center", C3 = "center" }
                        local baseLineHeights = { H1 = 30, P = 20, H2 = 25, H3 = 25, H4 = 25, C1 = 25, C2 = 20, C3 = 15 }
                        local extraGaps = { H1 = 30, P = 0, H2 = 25, H3 = 15, H4 = 10, C1 = 0, C2 = 0, C3 = 0 }
                        local imageSizes = { I1 = {640, 480}, I2 = {480, 360}, I3 = {320, 176} }
                        local yPos = textAreaY
                        for _, line in ipairs(lines) do
                            local prefix, content = line:match("^(%w+)|(.*)$")
                            if prefix and content then
                                content = content:match("^%s*(.-)%s*$")
                                if imageSizes[prefix] then
                                    local url = content
                                    local size = imageSizes[prefix]
                                    local imageWidth, imageHeight = size[1], size[2]
                                    if not g_SystemInfoImages then g_SystemInfoImages = {} end
                                    if not g_SystemInfoImages[url] then
                                        local resource = Resource.RequestTexture(url, TextureOptions.Default)
                                        if resource then
                                            g_SystemInfoImages[url] = { resource = resource, loaded = false, failed = false, texture = nil }
                                        else
                                            g_SystemInfoImages[url] = { resource = nil, loaded = false, failed = true, texture = nil }
                                        end
                                    end
                                    local imageEntry = g_SystemInfoImages[url]
                                    if imageEntry then
                                        if not imageEntry.loaded and not imageEntry.failed then
                                            if Resource.IsLoaded(imageEntry.resource) then
                                                imageEntry.texture = Resource.GetData(imageEntry.resource)
                                                if imageEntry.texture then
                                                    imageEntry.loaded = true
                                                else
                                                    imageEntry.failed = true
                                                    Resource.Release(imageEntry.resource)
                                                    imageEntry.resource = nil
                                                end
                                            elseif not Resource.IsLoading(imageEntry.resource) then
                                                imageEntry.failed = true
                                                Resource.Release(imageEntry.resource)
                                                imageEntry.resource = nil
                                            end
                                        end
                                        if imageEntry.loaded then
                                            local xPos = bgX + (bgWidth - imageWidth) / 2
                                            local bottomLeft = Vector4.Create(xPos, yPos + imageHeight, 0, 0)
                                            local topRight = Vector4.Create(xPos + imageWidth, yPos, 0, 0)
                                            renderer:DrawRect2d(bottomLeft, topRight, Vector4.Create(1, 1, 1, 1), imageEntry.texture)
                                            yPos = yPos + imageHeight + 20
                                        elseif imageEntry.failed then
                                            renderer:SetFontScale(0.8, -0.8)
                                            local errorText = "Failed to load image"
                                            local textWidth = renderer:GetTextSize(errorText):X()
                                            local xPos = bgX + (bgWidth - textWidth) / 2
                                            renderer:DrawText2d(Vector4.Create(xPos, yPos, 0), errorText, textColor)
                                            yPos = yPos + 20
                                        else
                                            renderer:SetFontScale(0.8, -0.8)
                                            local loadingText = "Loading image..."
                                            local textWidth = renderer:GetTextSize(loadingText):X()
                                            local xPos = bgX + (bgWidth - textWidth) / 2
                                            renderer:DrawText2d(Vector4.Create(xPos, yPos, 0), loadingText, textColor)
                                            yPos = yPos + 20
                                        end
                                    end
                                else
                                    local scale = scales[prefix] or 0.8
                                    local alignment = alignments[prefix] or "left"
                                    local lineHeight = baseLineHeights[prefix] or 20
                                    local extraGap = extraGaps[prefix] or 0
                                    renderer:SetFontScale(scale, -scale)
                                    renderer:SetFontHorzAlignment(alignment)
                                    local textWidth = renderer:GetTextSize(content):X()
                                    local xPos
                                    if alignment == "center" then
                                        xPos = bgX + (bgWidth - textWidth) / 2
                                    else
                                        xPos = textAreaX
                                    end
                                    renderer:DrawText2d(Vector4.Create(xPos, yPos, 0), content, textColor)
                                    yPos = yPos + lineHeight + extraGap
                                end
                            end
                        end
                    else
                        renderer:SetFontScale(1.0, -1.0)
                        local noDataText = "No system info available"
                        local textSize = renderer:GetTextSize(noDataText)
                        local textPos = Vector4.Create(
                            bgX + (bgWidth - textSize:X()) / 2 + 65,
                            bgY + (bgHeight - textSize:Y()) / 2,
                            0
                        )
                        renderer:DrawText2d(textPos, noDataText, textColor)
                    end
                end
            end
        end
    end


function RenderNameClickPopup(name)
    local renderer = g_Renderer
    local popupWidth = 200
    local buttonHeight = 30
    local spacing = 10
    local padding = 20
    local nameHeight = 30
    local outlineThickness = 1
    local borderThickness = 2


    local buttonLabels = {"Invite"}
    local mapId = nil
    if g_SelectedTable == 1 then
        local whoIsOnlineItems = g_LobbyItems["Players Online"] and g_LobbyItems["Players Online"].whoIsOnline or {}
        local selectedItem = whoIsOnlineItems[g_SelectedWhoIsOnlineItem]
        if selectedItem then
            mapId = selectedItem.MapId
        end
    end

    if mapId and mapId ~= "InPrivateSpace" then
        buttonLabels = {"Invite", "Goto"}
    end


    local numButtons = #buttonLabels
    local popupHeight = nameHeight + (numButtons * buttonHeight) + ((numButtons - 1) * spacing) + padding
    local popupX = (1280 - popupWidth) / 2 - 200
    local popupY = (720 - popupHeight) / 2


    renderer:DrawRect2d(
        popupX - outlineThickness,
        popupY - outlineThickness,
        popupX + popupWidth + outlineThickness,
        popupY + popupHeight + outlineThickness,
        Vector4.Create(1, 1, 1, 1)
    )


    renderer:DrawRect2d(popupX, popupY, popupX + popupWidth, popupY + popupHeight, Vector4.Create(0, 0, 0, 1))


    local nameText = "Selected: " .. (name or g_SelectedName or "")
    renderer:SetFontScale(0.8, -0.8)
    local textSize = renderer:GetTextSize(nameText)
    local textX = popupX + (popupWidth - textSize:X()) / 2
    local textY = popupY + 10
    renderer:DrawText2d(Vector4.Create(textX, textY, 0), nameText, Vector4.Create(1, 1, 1, 1))


    if g_NamePopupSelectedButton > numButtons then
        g_NamePopupSelectedButton = numButtons
    elseif g_NamePopupSelectedButton < 1 then
        g_NamePopupSelectedButton = 1
    end


    for i = 1, numButtons do
        local buttonY = popupY + 40 + (i - 1) * (buttonHeight + spacing)
        local isSelected = (i == g_NamePopupSelectedButton)
        local outlineColor = isSelected and Vector4.Create(0, 1, 0, 1) or Vector4.Create(0.5, 0.5, 0.5, 1)
        renderer:DrawRect2d(
            popupX + 5,
            buttonY,
            popupX + popupWidth - 5,
            buttonY + buttonHeight,
            outlineColor
        )
        renderer:DrawRect2d(
            popupX + 5 + borderThickness,
            buttonY + borderThickness,
            popupX + popupWidth - 5 - borderThickness,
            buttonY + buttonHeight - borderThickness,
            Vector4.Create(0, 0, 0, 1)
        )
        local buttonText = buttonLabels[i]
        local textSize = renderer:GetTextSize(buttonText)
        local textX = popupX + (popupWidth - textSize:X()) / 2
        local textY = buttonY + (buttonHeight - textSize:Y()) / 2 - 12
        renderer:DrawText2d(Vector4.Create(textX, textY, 0), buttonText, Vector4.Create(1, 1, 1, 1))
    end
end
function UIRenderMiniPopup()
    if not g_MiniPopupActive then
        return
    end

    local renderer = g_Renderer
    local miniPopupWidth = 360
    local miniPopupHeight = 395
    local miniPopupX = (1280 - miniPopupWidth) / 2 + 48
    local miniPopupY = (720 - miniPopupHeight) / 2 + 20
    local imageSize = 348
    local imageX = miniPopupX + (miniPopupWidth - imageSize) / 2
    local imageY = miniPopupY + (miniPopupHeight - imageSize) / 2 - 20


    renderer:DrawRect2d(
        miniPopupX, miniPopupY,
        miniPopupX + miniPopupWidth, miniPopupY + miniPopupHeight,
        Vector4.Create(0, 0, 0, 1)
    )

    if g_HQImageTexture then

        local bottomLeft = Vector4.Create(imageX, imageY + imageSize, 0, 0)
        local topRight = Vector4.Create(imageX + imageSize, imageY, 0, 0)
        renderer:DrawRect2d(bottomLeft, topRight, Vector4.Create(1, 1, 1, 1), g_HQImageTexture)
    else
        renderer:SetFontScale(1.0, -1.0)
        local text
        if g_HQImageIsDownloading then
            text = g_Me:GetLocalizedText("kLoading")
        else
            text = "Image not available"
        end
        local textSize = renderer:GetTextSize(text)
        local textX = miniPopupX + (miniPopupWidth - textSize:X()) / 2
        local textY = miniPopupY + (miniPopupHeight - textSize:Y()) / 2
        renderer:DrawText2d(Vector4.Create(textX, textY, 0), text, Vector4.Create(1, 1, 1, 1))
    end


    if g_SelectedGridItem and g_GridItems["Tools_Presets"] and g_GridItems["Tools_Presets"][g_SelectedGridItem] then
        local item = g_GridItems["Tools_Presets"][g_SelectedGridItem]
        local name = item.name or ""
        renderer:SetFontScale(1.0, -1.0)
        local maxTextWidth = 340
        local trimmedName = TrimTextToFit(name, maxTextWidth)
        local textPosX = miniPopupX + miniPopupWidth / 2
        local textPosY = imageY + imageSize + 15
        renderer:SetFontHorzAlignment("center")
        renderer:DrawText2d(Vector4.Create(textPosX, textPosY, 0), trimmedName, Vector4.Create(1, 1, 1, 1))
        renderer:SetFontHorzAlignment("left")
    end


    renderer:SetFontScale(0.6, -0.6)
    local applyText = g_Me:GetLocalizedText("kSelect")
    local closeText = g_Me:GetLocalizedText("kClose")
    local leftCenterX = miniPopupX + miniPopupWidth / 4
    local rightCenterX = miniPopupX + 3 * miniPopupWidth / 4
    local legendY = miniPopupY + 375
    renderer:SetFontHorzAlignment("center")
    renderer:DrawText2d(Vector4.Create(leftCenterX, legendY, 0), applyText, Vector4.Create(1, 1, 1, 1))
    renderer:DrawText2d(Vector4.Create(rightCenterX, legendY, 0), closeText, Vector4.Create(1, 1, 1, 1))
    renderer:SetFontHorzAlignment("left")
end

function UIRender()
    local renderer = g_Renderer
    local colGreen = Vector4.Create(0.0, 0.6, 0.6, 1.0)

    local bgWidth = 1242
    local bgHeight = 680
    local bgX = (1280 - bgWidth) / 2
    local bgY = (720 - bgHeight) / 2
    local topBarHeight = 60


    local borderColor = Vector4.Create(0.1, 0.1, 0.1, 1.0)
    local borderThickness = 2



    renderer:DrawRect2d(
        bgX - borderThickness, bgY - borderThickness,
        bgX + bgWidth + borderThickness, bgY,
        borderColor
    )

    renderer:DrawRect2d(
        bgX - borderThickness, bgY + bgHeight,
        bgX + bgWidth + borderThickness, bgY + bgHeight + borderThickness,
        borderColor
    )

    renderer:DrawRect2d(
        bgX - borderThickness, bgY - borderThickness,
        bgX, bgY + bgHeight + borderThickness,
        borderColor
    )

    renderer:DrawRect2d(
        bgX + bgWidth, bgY - borderThickness,
        bgX + bgWidth + borderThickness, bgY + bgHeight + borderThickness,
        borderColor
    )


    renderer:DrawRect2d(bgX, bgY, bgX + bgWidth, bgY + bgHeight, g_Colors.Black85)

    renderer:DrawRect2d(
        bgX, bgY,
        bgX + bgWidth, bgY + topBarHeight,
        g_Colors.Black95
    )

    renderer:SetFontScale(0.7, -0.7)
    local kNameLabel = g_Me:GetLocalizedText("kHLOSTitle")
    local kNamePos = Vector4.Create(bgX + 10, bgY + 10, 0)
    renderer:DrawText2d(kNamePos, kNameLabel, Vector4.Create(1.0, 1.0, 1.0, 0.95))

    local rightBarWidth = 16
    renderer:DrawRect2d(
        bgX + bgWidth - rightBarWidth, bgY,
        bgX + bgWidth, bgY + bgHeight,
        g_Colors.Black85
    )

    local leftSidebarWidth = 120
    local bottomBarHeight = 20
    renderer:DrawRect2d(
        bgX + leftSidebarWidth, bgY + bgHeight - bottomBarHeight,
        bgX + bgWidth - rightBarWidth, bgY + bgHeight,
        g_Colors.Black95
    )

    renderer:SetFontScale(0.7, -0.7)
    UIRenderTabs(bgX + 128, bgY, bgWidth, topBarHeight)
    UIRenderPageContent(bgX, bgY, bgWidth, bgHeight, topBarHeight)
    renderer:SetFontScale(0.8, -0.8)
    UIRenderLegend(bgX + bgWidth - 40, bgY + bgHeight - 20 - bottomBarHeight + 25)

    if g_PopupActive then
        renderer:DrawRect2d(20, 20, 1260, 700, g_Colors.DimOverlay)
    end

	if g_InvitePopupActive then
        RenderInviteActionPopup(g_SelectedInviteItem.name)
    end

    if g_NamePopupActive then
        RenderNameClickPopup()
    end

    UIRenderPopup()
    UIRenderCustomOSK()
    UIRenderMiniPopup()
end

function MainRender()
    if g_UIActive == 1 then
        if g_MiniMenuActive then
            UIRenderMiniMenu()
        else
            UIRender()
        end
    end
end