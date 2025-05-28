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
LoadLibrary("Texture")
LoadLibrary("Resource")
LoadLibrary("MemoryContainer")
LoadLibrary("HttpPostData")
LoadLibrary("LocalPlayer")
LoadLibrary("Person")


function WrapTextToLines(text, maxWidth, maxLines)
    local lines = {}
    local currentLine = ""
    local words = {}

    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    for i, word in ipairs(words) do
        local testLine = currentLine == "" and word or currentLine .. " " .. word
        g_Renderer:SetFontScale(0.8, -0.8)
        local textSize = g_Renderer:GetTextSize(testLine)

        if textSize:X() <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
                currentLine = word
            else
                while g_Renderer:GetTextSize(word):X() > maxWidth and #word > 0 do
                    word = word:sub(1, -2)
                end
                table.insert(lines, word)
                currentLine = ""
            end
        end

        if #lines >= maxLines - 1 and i < #words then
            local remaining = table.concat(words, " ", i)
            while g_Renderer:GetTextSize(remaining):X() > maxWidth - g_Renderer:GetTextSize("..."):X() and #remaining > 0 do
                remaining = remaining:sub(1, -2)
            end
            if remaining ~= "" then
                table.insert(lines, remaining .. "...")
            end
            break
        end
    end

    if currentLine ~= "" and #lines < maxLines then
        table.insert(lines, currentLine)
    end

    while #lines > maxLines do
        table.remove(lines)
    end

    if #lines == maxLines and currentLine ~= "" and #words > 0 then
        local lastLine = lines[#lines]
        while g_Renderer:GetTextSize(lastLine):X() > maxWidth - g_Renderer:GetTextSize("..."):X() and #lastLine > 0 do
            lastLine = lastLine:sub(1, -2)
        end
        lines[#lines] = lastLine .. "..."
    end

    return lines
end


g_PopupActive = false
g_PopupItem = nil
g_PopupSelectedButton = 1
g_PopupRequestPending = false
g_PopupRequestTime = 0
g_PopupRequestTimeout = 5000
g_PopupResponse = nil
g_PopupPostData = nil
g_PopupResource = nil
g_PopupMemoryContainer = nil


g_PopupImageResource = nil
g_PopupImageTexture = nil
g_PopupImageIsDownloading = false
g_PopupImageUrl = nil
g_PopupImageFallbackUrl = "http://173.225.107.46/HomeLabOS_Resources/ICONS/NOIMAGE_HQ.PNG"


g_PopupButtons = {
    { localisedText = "kApplyNow", action = "apply_now" },
    { localisedText = "kSavePopup", action = "add_item" },
    { localisedText = "kRemovePopup", action = "remove_item" },
    { localisedText = "kRelatedContent", action = "related_content" },
    { localisedText = "", action = "search_by_maker" },
    { localisedText = "kDumpPopup", action = "dump_content" }
}


function categoryContainsSpecialStrings(category)
    if not category then return false end
    local lowerCategory = string.lower(category)
    if string.find(lowerCategory, "scene-") or
       string.find(lowerCategory, "private") or
       string.find(lowerCategory, "public") then
        return true
    end
    return false
end


function ActivateInterface()
    if not g_Renderer then
        g_Renderer = Renderer.Create(Vector4.Create(0, 0, 0, 0), Vector4.Create(1280, 720, 0, 0), Vector4.Create(1, 1, 1, 1), 'global')
    end
    if not g_PopupMemoryContainer then
        g_PopupMemoryContainer = MemoryContainer.Create(8192)
    end

end


function DeactivateInterface()
    if g_PopupMemoryContainer then
        g_PopupMemoryContainer = nil
    end
    if g_PopupResource then
        Resource.Release(g_PopupResource)
        g_PopupResource = nil
    end
    if g_PopupPostData then
        g_PopupPostData = nil
    end

end


function MapTypeToString(type)
    local typeMap = {
        D = "kTypeDefaultItem",
        P = "kTypePremiumItem",
        A = "kTypeAutomaticReward",
        L = "kTypeLUAReward",
        C = "kTypeCustom",
        U = "kTypeUnknown"
    }
    return g_Me:GetLocalizedText(typeMap[type] or "kTypeUnknown")
end


function ResetPopupRequest()
    if g_PopupResource then
        Resource.Release(g_PopupResource)
        g_PopupResource = nil
    end
    if g_PopupPostData then
        g_PopupPostData = nil
    end
    g_PopupRequestPending = false
    g_PopupRequestTime = 0
end

function ResetPopupImage()
    if g_PopupImageResource then
        Resource.Release(g_PopupImageResource)
        g_PopupImageResource = nil
    end
    if g_PopupItem and g_PopupItem.id then
        local namespaced_id = "popup_" .. g_PopupItem.id
        if g_GridTextures[namespaced_id] then
            if g_GridTextures[namespaced_id].resource then
                Resource.Release(g_GridTextures[namespaced_id].resource)
            end
            g_GridTextures[namespaced_id] = nil
        end
    end
    g_PopupImageTexture = nil
    g_PopupImageIsDownloading = false
    g_PopupImageUrl = nil
end

function IsPopupRequestReady()
    if not g_PopupResource then
        return false
    end
    if Resource.IsLoaded(g_PopupResource) then
        return true
    end
    return false
end


function IsPopupImageReady()
    if not g_PopupImageResource then
        return false
    end
    if Resource.IsLoaded(g_PopupImageResource) then
        return true
    end
    return false
end

function RequestPopupData(uuid, category)
    ResetPopupRequest()

    local url = "http://173.225.107.46/HomeLab_OS_API/details.php?uuid=" .. uuid .. "&category=" .. category
    if not g_PopupMemoryContainer then
        g_PopupMemoryContainer = MemoryContainer.Create(8192)
        if not g_PopupMemoryContainer then
            g_PopupResponse = g_Me:GetLocalizedText("kMemoryContainerFailed")
            return false
        end
    end

    g_PopupPostData = HttpPostData.Create(g_PopupMemoryContainer, "text/plain")
    if not g_PopupPostData then
        g_PopupResponse = g_Me:GetLocalizedText("kMemoryContainerFailed")
        return false
    end

    g_PopupPostData:SetMethod("GET")
    g_PopupPostData:Reset()
    g_PopupPostData:AddHttpHeader("Accept", "text/plain")
    g_PopupPostData:FinalizeHttpHeaders()
    g_PopupPostData:Finalize()

    g_PopupResource = Resource.Request(url, "file", g_PopupPostData)
    if not g_PopupResource then
        g_PopupPostData = nil
        g_PopupResponse = g_Me:GetLocalizedText("kEmptyResponse")
        return false
    end

    g_PopupRequestPending = true
    g_PopupRequestTime = GetInstanceTime()
    return true
end

function RequestPopupImage(uuid, thumbnail_type)
    if g_PopupImageIsDownloading then
        return
    end

    ResetPopupImage()


    if thumbnail_type == "S" then
        g_PopupImageUrl = "http://psho.me/OBJECTS/" .. uuid .. "/SMALLU.PNG"
    elseif thumbnail_type == "L" or thumbnail_type == "P" then
        g_PopupImageUrl = "http://psho.me/OBJECTS/" .. uuid .. "/LARGEU.PNG"
    else
        g_PopupImageUrl = g_PopupImageFallbackUrl
    end


    local namespaced_id = "popup_" .. uuid
    print("Requesting popup image: uuid=" .. uuid .. ", thumbnail_type=" .. tostring(thumbnail_type) .. ", url=" .. g_PopupImageUrl)


    g_GridTextures[namespaced_id] = {
        resource = Resource.RequestTexture(g_PopupImageUrl, TextureOptions.NoMipmaps),
        downloaded = false,
        failed = false,
        status_code = 0,
        texture = nil
    }

    if g_GridTextures[namespaced_id].resource then
        g_PopupImageResource = g_GridTextures[namespaced_id].resource
        g_PopupImageIsDownloading = true
    else
        g_GridTextures[namespaced_id] = nil
        g_PopupImageUrl = g_PopupImageFallbackUrl
        g_GridTextures[namespaced_id] = {
            resource = Resource.RequestTexture(g_PopupImageUrl, TextureOptions.NoMipmaps),
            downloaded = false,
            failed = false,
            status_code = 0,
            texture = nil
        }
        if g_GridTextures[namespaced_id].resource then
            g_PopupImageResource = g_GridTextures[namespaced_id].resource
            g_PopupImageIsDownloading = true
        else
            g_GridTextures[namespaced_id] = nil
            g_PopupImageIsDownloading = false
        end
    end
end
function UpdatePopupImage()
    if not g_PopupImageIsDownloading or not g_PopupImageResource then
        return
    end


    local namespaced_id = "popup_" .. (g_PopupItem and g_PopupItem.id or "")
    local texture_entry = g_GridTextures[namespaced_id]

    if not texture_entry then
        g_PopupImageIsDownloading = false
        return
    end

    print("Updating popup image: url=" .. tostring(g_PopupImageUrl) .. ", namespaced_id=" .. namespaced_id)

    if Resource.IsLoading(g_PopupImageResource) then
        local progress = Resource.GetDownloadProgress(g_PopupImageResource)
    elseif Resource.IsLoaded(g_PopupImageResource) then
        texture_entry.texture = Resource.GetData(g_PopupImageResource)
        if texture_entry.texture then
            g_PopupImageTexture = texture_entry.texture
            texture_entry.downloaded = true
            g_PopupImageIsDownloading = false
            print("Popup image loaded: " .. g_PopupImageUrl)
        else
            Resource.Release(g_PopupImageResource)
            g_PopupImageResource = nil
            texture_entry.failed = true
            g_GridTextures[namespaced_id] = nil
            if g_PopupImageUrl ~= g_PopupImageFallbackUrl then
                g_PopupImageUrl = g_PopupImageFallbackUrl
                g_GridTextures[namespaced_id] = {
                    resource = Resource.RequestTexture(g_PopupImageUrl, TextureOptions.NoMipmaps),
                    downloaded = false,
                    failed = false,
                    status_code = 0,
                    texture = nil
                }
                if g_GridTextures[namespaced_id].resource then
                    g_PopupImageResource = g_GridTextures[namespaced_id].resource
                    g_PopupImageIsDownloading = true
                    print("Retrying with fallback: " .. g_PopupImageUrl)
                else
                    g_GridTextures[namespaced_id] = nil
                    g_PopupImageIsDownloading = false
                end
            else
                g_PopupImageIsDownloading = false
            end
        end
    else
        local statusCode = Resource.GetStatusCode(g_PopupImageResource)
        Resource.Release(g_PopupImageResource)
        g_PopupImageResource = nil
        texture_entry.failed = true
        g_GridTextures[namespaced_id] = nil
        if g_PopupImageUrl ~= g_PopupImageFallbackUrl then
            g_PopupImageUrl = g_PopupImageFallbackUrl
            g_GridTextures[namespaced_id] = {
                resource = Resource.RequestTexture(g_PopupImageUrl, TextureOptions.NoMipmaps),
                downloaded = false,
                failed = false,
                status_code = 0,
                texture = nil
            }
            if g_GridTextures[namespaced_id].resource then
                g_PopupImageResource = g_GridTextures[namespaced_id].resource
                g_PopupImageIsDownloading = true
                print("Retrying with fallback: " .. g_PopupImageUrl)
            else
                g_GridTextures[namespaced_id] = nil
                g_PopupImageIsDownloading = false
            end
        else
            g_PopupImageIsDownloading = false
        end
    end
end


function ClosePopup()
    g_PopupActive = false
    g_PopupItem = nil
    g_PopupSelectedButton = 1
    g_PopupResponse = nil
    ResetPopupRequest()
    ResetPopupImage()
    g_PendingPageChangeForPopup = false
    print("Popup closed")
end


function ApplyNowAction()
    if not g_PopupItem or not g_PopupResponse then
        print("Error: No item or response available for Apply Now action")
        return
    end

    local fields = {}
    for field in g_PopupResponse:gmatch("[^|]+") do
        table.insert(fields, field)
    end
    local uuid = fields[1] or ""
    local name = fields[2] or ""
    local category = fields[4] or ""
    local thumbnail_type = g_PopupItem.thumbnail_type or ""

    if uuid == "" or category == "" then
        print("Error: Invalid item data for Apply Now action")
        return
    end

    HandleItemSelection(uuid, name, category, thumbnail_type)
    gSoundBank:Play2d("page_flip")
    ClosePopup()
end


function AddRemoveAction(action)
    if not g_PopupItem or not g_PopupResponse then
        print("Error: No item or response available for " .. action .. " action")
        return
    end

    local fields = {}
    for field in g_PopupResponse:gmatch("[^|]+") do
        table.insert(fields, field)
    end
    local uuid = fields[1] or ""
    local name = fields[2] or ""
    local category = fields[4] or ""
    local thumbnail_type = g_PopupItem.thumbnail_type or ""

    if uuid == "" or category == "" then
        print("Error: Invalid item data for " .. action .. " action")
        return
    end

    HandleItemAddRemove(uuid, name, category, thumbnail_type, action)
    gSoundBank:Play2d("page_flip")
    ClosePopup()
end


function DumpContentButtonAction()
    if not g_PopupItem or not g_PopupResponse then
        print("Error: No item or response available for Dump Content action")
        return
    end

    local fields = {}
    for field in g_PopupResponse:gmatch("[^|]+") do
        table.insert(fields, field)
    end
    local uuid = fields[1] or ""

    if uuid == "" then
        print("Error: Invalid UUID for Dump Content action")
        return
    end

    DumpContentAction(uuid)
    gSoundBank:Play2d("page_flip")
    ClosePopup()
end

function SearchByMakerAction()
    if not g_PopupItem or not g_PopupResponse then
        print("Error: No item or response available for Search by Maker action")
        return
    end

    local fields = {}
    for field in g_PopupResponse:gmatch("[^|]+") do
        table.insert(fields, field)
    end
    local maker = fields[7] or ""
    local category = fields[4] or ""

    if maker == "" or category == "" then
        print("Error: Invalid maker or category for Search by Maker action")
        return
    end


    maker = maker:gsub("^%s+", ""):gsub("%s+$", "")


    local encodedMaker = maker:gsub("%s+", "+")


    local encodedCategory = UrlEncode(category)

    ClosePopup()
    g_ActiveTabIndex = 7
    g_ActiveArea = "sidebar"
    g_SearchKeywords = maker
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
                gSoundBank:Play2d("cancel_back")
                print("Error: Search by Maker, failed to create container")
                return
            end
        end
        g_SearchPostData = HttpPostData.Create(g_SearchMemoryContainer, "text/plain")
        if not g_SearchPostData then
            gSoundBank:Play2d("cancel_back")
            print("Error: Search by Maker, failed to create post data")
            return
        end
        g_SearchPostData:SetMethod("GET")
        g_SearchPostData:Reset()
        g_SearchPostData:AddHttpHeader("Accept", "text/plain")
        g_SearchPostData:FinalizeHttpHeaders()
        g_SearchPostData:Finalize()


        local url = "http://173.225.107.46/HomeLab_OS_API/search.php?q=" .. encodedMaker .. "&c=" .. encodedCategory .. "&page=1"
        print("Initiating search with URL: " .. url)
        g_SearchResource = Resource.Request(url, "file", g_SearchPostData)
        if g_SearchResource then
            g_SearchRequestPending = true
            g_SearchTimeoutFrames = 360
            g_SearchTabLabel = "Search"
        else
            ResetSearchRequest()
            gSoundBank:Play2d("cancel_back")
            print("Error: Search by Maker, failed to request resource")
        end
    end
end


function categoryStartsWithSpecialPrefix(category)
    if not category then return false end
    local lowerCategory = string.lower(category)
    local prefixes = {"male-", "female-", "portable-", "scene-", "furniture-"}
    for _, prefix in ipairs(prefixes) do
        if string.match(lowerCategory, "^" .. prefix) then
            return true
        end
    end
    return false
end

function UIRenderPopup()
    if g_PopupActive and g_PopupItem then
        if not g_PopupRequestPending and not g_PopupResponse then
            RequestPopupData(g_PopupItem.id, g_PopupItem.category)
        end

        if not g_PopupImageIsDownloading and not g_PopupImageTexture then
            RequestPopupImage(g_PopupItem.id, g_PopupItem.thumbnail_type)
        end

        local currentTime = GetInstanceTime()
        if g_PopupRequestPending then
            if (currentTime - g_PopupRequestTime >= g_PopupRequestTimeout) then
                g_PopupResponse = g_Me:GetLocalizedText("kRequestTimedOut")
                ResetPopupRequest()
            elseif IsPopupRequestReady() then
                local memContainer = MemoryContainer.Create(g_PopupResource)
                if not memContainer then
                    g_PopupResponse = g_Me:GetLocalizedText("kMemoryContainerFailed")
                    ResetPopupRequest()
                else
                    local success, result = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                    if success and result then
                        if result and #result > 0 then
                            g_PopupResponse = result
                        else
                            g_PopupResponse = g_Me:GetLocalizedText("kEmptyResponse")
                        end
                    else
                        g_PopupResponse = g_Me:GetLocalizedText("kReadMemoryFailed")
                    end
                    ResetPopupRequest()
                end
            end
        end

        UpdatePopupImage()

        local descMaxWidth = 460
        local descMaxLines = 2
        local descLines = {g_Me:GetLocalizedText("kLoading")}
        local lineSpacing = 23
        if g_PopupResponse and g_PopupResponse ~= "" and not g_PopupResponse:find(g_Me:GetLocalizedText("kRequestTimedOut")) and not g_PopupResponse:find(g_Me:GetLocalizedText("kMemoryContainerFailed")) and not g_PopupResponse:find(g_Me:GetLocalizedText("kEmptyResponse")) and not g_PopupResponse:find(g_Me:GetLocalizedText("kReadMemoryFailed")) then
            local fields = {}
            for field in g_PopupResponse:gmatch("[^|]+") do
                table.insert(fields, field)
            end
            local desc = (fields[3] and fields[3] ~= "") and fields[3] or g_Me:GetLocalizedText("kLoading")
            descLines = WrapTextToLines(desc, descMaxWidth, descMaxLines)
        end
        local numDescLines = #descLines

        local popupWidth = 620
        local popupHeight = 540
        local popupX = (1280 - popupWidth) / 2 + 50
        local popupY = (720 - popupHeight) / 2 + 15
        local popupBgColor = Vector4.Create(0.0, 0.0, 0.0, 1.0)
        local colLegend = Vector4.Create(1.0, 1.0, 1.0, 0.70)
        local darkGreyBorderColor = Vector4.Create(0.2, 0.2, 0.2, 1.0)
        local textColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)
        local placeholderColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)
        local buttonBgColor = Vector4.Create(0.0, 0.0, 0.0, 0.9)
        local buttonHighlightBorderColor = Vector4.Create(0.0, 0.5, 0.0, 1.0)
        local buttonDarkGreyOutlineColor = Vector4.Create(0.15, 0.15, 0.15, 1.0)
        local imageBorderColor = Vector4.Create(0.1, 0.1, 0.1, 1.0)


        g_Renderer:DrawRect2d(
            popupX - 2, popupY - 2,
            popupX + popupWidth + 2, popupY + popupHeight + 2,
            darkGreyBorderColor
        )

        g_Renderer:DrawRect2d(
            popupX, popupY,
            popupX + popupWidth, popupY + popupHeight,
            popupBgColor
        )

        local imageWidth = 534
        local imageHeight = 294
        local imageX = popupX + (popupWidth - imageWidth) / 2
        local imageY = popupY + 10

        local textureWidth = (g_PopupItem.thumbnail_type == "S") and 466 or 640
        local textureHeight = (g_PopupItem.thumbnail_type == "S") and 256 or 352


        g_Renderer:DrawRect2d(
            imageX - 2, imageY - 2,
            imageX + imageWidth + 2, imageY + imageHeight + 144,
            imageBorderColor
        )

        if g_PopupImageTexture then
            local scaleX = imageWidth / textureWidth
            local scaleY = imageHeight / textureHeight
            local scale = math.min(scaleX, scaleY)
            local scaledWidth = textureWidth * scale
            local scaledHeight = textureHeight * scale
            local offsetX = (imageWidth - scaledWidth) / 2
            local offsetY = (imageHeight - scaledHeight) / 2
            local offsetX = imageX + offsetX
            local offsetY = imageY + offsetY
            local topRightX = offsetX + scaledWidth
            local topRightY = offsetY + scaledHeight
            local bottomLeft = Vector4.Create(offsetX, topRightY, 0, 0)
            local topRight = Vector4.Create(topRightX, offsetY, 0, 0)
            local rgba = Vector4.Create(1, 1, 1, 1)
            g_Renderer:DrawRect2d(bottomLeft, topRight, rgba, g_PopupImageTexture)
        else
            g_Renderer:SetFontScale(0.8, -0.8)
            g_Renderer:SetFontHorzAlignment("center")
            local loadingText = g_PopupImageIsDownloading and g_Me:GetLocalizedText("kLoading") or g_Me:GetLocalizedText("kImageUnavailable")
            g_Renderer:DrawText2d(
                Vector4.Create(imageX + imageWidth / 2, imageY + imageHeight / 2, 0),
                loadingText,
                textColor
            )
            g_Renderer:SetFontHorzAlignment("left")
        end

        g_Renderer:SetFontScale(1.0, -1.0)
        local imageCenterY = imageY + imageHeight / 2

        g_Renderer:SetFontHorzAlignment("right")
        local previousText = g_Me:GetLocalizedText("kPrevious")
        g_Renderer:DrawText2d(
            Vector4.Create(imageX - 0, imageCenterY, 0),
            previousText,
            colLegend
        )

        g_Renderer:SetFontHorzAlignment("left")
        local nextText = g_Me:GetLocalizedText("kNext")
        g_Renderer:DrawText2d(
            Vector4.Create(imageX + imageWidth + 10, imageCenterY, 0),
            nextText,
            colLegend
        )
        g_Renderer:SetFontHorzAlignment("left")

        g_Renderer:SetFontScale(0.8, -0.8)
        local textX = popupX + 40
        local textY = imageY + imageHeight + 10

        local uuid, name, desc, category, type, hdk, maker, author = g_Me:GetLocalizedText("kLoading"), g_Me:GetLocalizedText("kLoading"), g_Me:GetLocalizedText("kLoading"), g_Me:GetLocalizedText("kLoading"), g_Me:GetLocalizedText("kLoading"), g_Me:GetLocalizedText("kLoading"), g_Me:GetLocalizedText("kLoading"), g_Me:GetLocalizedText("kLoading")
        if g_PopupResponse and g_PopupResponse ~= "" and not g_PopupResponse:find(g_Me:GetLocalizedText("kRequestTimedOut")) and not g_PopupResponse:find(g_Me:GetLocalizedText("kMemoryContainerFailed")) and not g_PopupResponse:find(g_Me:GetLocalizedText("kEmptyResponse")) and not g_PopupResponse:find(g_Me:GetLocalizedText("kReadMemoryFailed")) then
            local fields = {}
            for field in g_PopupResponse:gmatch("[^|]+") do
                table.insert(fields, field)
            end
            uuid = (fields[1] and fields[1] ~= "") and fields[1] or g_Me:GetLocalizedText("kUnknown")
            name = (fields[2] and fields[2] ~= "") and fields[2] or g_Me:GetLocalizedText("kUnknown")
            desc = (fields[3] and fields[3] ~= "") and fields[3] or g_Me:GetLocalizedText("kUnknown")
            category = (fields[4] and fields[4] ~= "") and fields[4] or g_Me:GetLocalizedText("kUnknown")
            type = (fields[5] and fields[5] ~= "") and fields[5] or g_Me:GetLocalizedText("kUnknown")
            hdk = (fields[6] and fields[6] ~= "") and fields[6] or g_Me:GetLocalizedText("kUnknown")
            maker = (fields[7] and fields[7] ~= "") and fields[7] or g_Me:GetLocalizedText("kUnknown")
            author = (fields[8] and fields[8] ~= "") and fields[8] or g_Me:GetLocalizedText("kUnknown")
        end

        local textAreaBorder = 40
        local textAreaX = popupX + textAreaBorder
        local textAreaWidth = popupWidth - 2 * textAreaBorder
        local totalLines = 3 + numDescLines
        local textAreaY = textY - 5
        local textAreaHeight = totalLines * lineSpacing + 27
        local textAreaBgColor = Vector4.Create(0.1, 0.1, 0.1, 1.0)

        g_Renderer:DrawText2d(
            Vector4.Create(textX + 10, textY, 0),
            g_Me:GetLocalizedText("kNameLabel") .. tostring(name),
            textColor
        )
        for i, line in ipairs(descLines) do
            g_Renderer:DrawText2d(
                Vector4.Create(textX + 10, textY + i * lineSpacing, 0),
                (i == 1 and g_Me:GetLocalizedText("kDescriptionLabel") or "             ") .. line,
                textColor
            )
        end
        local nextY = textY + (numDescLines + 1) * lineSpacing
        g_Renderer:DrawText2d(
            Vector4.Create(textX + 10, nextY, 0),
            g_Me:GetLocalizedText("kUUIDLabel") .. tostring(uuid),
            textColor
        )
        g_Renderer:DrawText2d(
            Vector4.Create(textX + 10, nextY + lineSpacing, 0),
            g_Me:GetLocalizedText("kMakerLabel") .. tostring(maker) .. "      " .. g_Me:GetLocalizedText("kAuthorLabel") .. tostring(author),
            textColor
        )
        g_Renderer:DrawText2d(
            Vector4.Create(textX + 10, nextY + 2 * lineSpacing, 0),
            g_Me:GetLocalizedText("kCategoryLabel") .. tostring(category) .. "      " .. g_Me:GetLocalizedText("kTypeLabel") .. MapTypeToString(type) .. "      " .. g_Me:GetLocalizedText("kHDKVersionLabel") .. tostring(hdk),
            textColor
        )
        g_Renderer:SetFontScale(0.7, -0.7)

        local buttonWidth = 170
        local buttonHeight = 20
        local buttonSpacing = 10
        local totalButtonsWidth = (buttonWidth * 3) + (buttonSpacing * 2)
        local buttonStartX = popupX + (popupWidth - totalButtonsWidth) / 2
        local buttonYFirstRow = popupY + popupHeight - 80
        local buttonYSecondRow = popupY + popupHeight - 48

        for i = 1, 6 do
            local button = g_PopupButtons[i]
            local isFirstRow = i <= 3
            local buttonX = buttonStartX + ((isFirstRow and (i - 1) or (i - 4)) * (buttonWidth + buttonSpacing))
            local buttonY = isFirstRow and buttonYFirstRow or buttonYSecondRow

            g_Renderer:DrawRect2d(
                buttonX, buttonY,
                buttonX + buttonWidth, buttonY + buttonHeight,
                buttonBgColor
            )

            local borderColor = (i == g_PopupSelectedButton) and buttonHighlightBorderColor or buttonDarkGreyOutlineColor
            local borderThickness = 2
            g_Renderer:DrawRect2d(
                buttonX - borderThickness, buttonY - borderThickness,
                buttonX + buttonWidth + borderThickness, buttonY + buttonHeight + borderThickness,
                borderColor
            )
            g_Renderer:DrawRect2d(
                buttonX - borderThickness + 1, buttonY - borderThickness + 1,
                buttonX + buttonWidth + borderThickness - 1, buttonY + buttonHeight + borderThickness - 1,
                buttonBgColor
            )

            g_Renderer:SetFontHorzAlignment("center")
            local textPos = Vector4.Create(buttonX + buttonWidth / 2, buttonY + 5, 0)
            local displayLabel
            if i == 1 then
                if string.match(string.lower(category), "^furniture-") then
                    displayLabel = ""
                else
                    local labelKey = (categoryContainsSpecialStrings(category)) and "kJumpHere" or "kApplyNow"
                    displayLabel = g_Me:GetLocalizedText(labelKey)
                end
            elseif i == 2 or i == 3 then
                if categoryStartsWithSpecialPrefix(category) then
                    displayLabel = g_Me:GetLocalizedText(button.localisedText)
                else
                    displayLabel = ""
                end
            elseif i == 5 then

                displayLabel = tostring(maker)
                if displayLabel == g_Me:GetLocalizedText("kLoading") or displayLabel == g_Me:GetLocalizedText("kUnknown") then
                    displayLabel = ""
                else
                    displayLabel = g_Me:GetLocalizedText("kMoreFrom") .. " " .. string.sub(displayLabel, 1, 20)
                end
            else
                displayLabel = g_Me:GetLocalizedText(button.localisedText)
            end
            g_Renderer:DrawText2d(textPos, displayLabel, textColor)
            g_Renderer:SetFontHorzAlignment("left")
        end

        g_Renderer:SetFontScale(0.6, -0.6)
        local legendY = popupY + popupHeight - 17
        local closeX = popupX + popupWidth - 17
        local textSpacing = 55

        g_Renderer:SetFontHorzAlignment("right")
        local navigateText = g_Me:GetLocalizedText("kNavigateButton")
        g_Renderer:DrawText2d(
            Vector4.Create(closeX - 2 * textSpacing, legendY, 0),
            navigateText,
            colLegend
        )

        local selectText = g_Me:GetLocalizedText("kSelect")
        g_Renderer:DrawText2d(
            Vector4.Create(closeX - textSpacing, legendY, 0),
            selectText,
            colLegend
        )

        local dismissText = g_Me:GetLocalizedText("kClose")
        g_Renderer:DrawText2d(
            Vector4.Create(closeX, legendY, 0),
            dismissText,
            colLegend
        )
        g_Renderer:SetFontHorzAlignment("left")
    else
        g_PopupResponse = nil
        ResetPopupRequest()
        ResetPopupImage()
    end
end