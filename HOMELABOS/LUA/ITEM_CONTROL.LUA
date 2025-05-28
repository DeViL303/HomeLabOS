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


print("[#HomeLabOS v1.01] ITEM_CONTROL.LUA loaded successfully")


local g_ClothingSaveTimer = 0
local g_ClothingSaveTimerActive = false
local g_ClothingSaveTimerDuration = 30000


SpawnFunction(function()
    while true do
        if g_ClothingSaveTimerActive then
            local currentTime = GetInstanceTime()
            if currentTime - g_ClothingSaveTimer >= g_ClothingSaveTimerDuration then

                print("[#HomeLabOS v1.01] Clothing save timer expired, sending: saveavatar latestavatar")
                SendRTMCommand("saveavatar latestavatar")
                g_ClothingSaveTimerActive = false
            end
        end
        coroutine.yield()
    end
end)


function ResetClothingSaveTimer()
    g_ClothingSaveTimer = GetInstanceTime()
    g_ClothingSaveTimerActive = true
    print("[#HomeLabOS v1.01] Clothing save timer reset to 30 seconds")
end


local rig = LocalPlayer.GetAvatarRig()
print("Player's avatar rig: " .. (rig or "Unknown"))


function SwitchGenderForClothing(targetGender, callback)
    SpawnFunction(function()

        local currentGenderStr = (rig == 1) and "male" or (rig == 2) and "female" or "unknown"
        local targetGenderStr = (targetGender == 1) and "male" or "female"


        local saveCommand = "saveavatar " .. currentGenderStr .. "_save"
        print("Sending RTM command to save current gender: " .. saveCommand)
        SendRTMCommand(saveCommand)


        local startTime = GetInstanceTime()
        while GetInstanceTime() - startTime < 100 do
            coroutine.yield()
        end


        local loadCommand = "loadavatar " .. targetGenderStr .. "_save"
        print("Sending RTM command to load target gender: " .. loadCommand)
        SendRTMCommand(loadCommand)


        startTime = GetInstanceTime()
        while GetInstanceTime() - startTime < 4000 do
            coroutine.yield()
        end


        rig = targetGender
        print("Gender switched to: " .. targetGenderStr .. " (rig = " .. rig .. ")")
        if callback then
            callback()
        end
    end)
end


function ApplyBundledClothing(uuid, category)
    SpawnFunction(function()

        local encodedCategory = UrlEncode(category)
        local url = "http://173.225.107.46/HomeLab_OS_API/details.php?uuid=" .. uuid .. "&category=" .. encodedCategory .. "&bundle"
        local container = MemoryContainer.Create(1024)
        if not container then
            print("Error: Failed to create memory container for bundle request")
            return
        end

        local postData = HttpPostData.Create(container, "text/plain")
        if not postData then
            print("Error: Failed to create post data for bundle request")
            container = nil
            return
        end

        postData:SetMethod("GET")
        postData:Reset()
        postData:AddHttpHeader("Accept", "text/plain")
        postData:FinalizeHttpHeaders()
        postData:Finalize()

        local resource = Resource.Request(url, "file", postData)
        if not resource then
            print("Error: Failed to initiate bundle request")
            postData = nil
            container = nil
            return
        end

        local startTime = GetInstanceTime()
        local timeout = 5000
        while Resource.IsLoading(resource) do
            if GetInstanceTime() - startTime >= timeout then
                print("Error: Bundle request timed out")
                Resource.Release(resource)
                postData = nil
                container = nil
                return
            end
            coroutine.yield()
        end

        if not Resource.IsLoaded(resource) then
            print("Error: Bundle request failed with status code: " .. Resource.GetStatusCode(resource))
            Resource.Release(resource)
            postData = nil
            container = nil
            return
        end


        local memContainer = MemoryContainer.Create(resource)
        if not memContainer then
            print("Error: Failed to create memory container for bundle response")
            Resource.Release(resource)
            postData = nil
            container = nil
            return
        end

        local response = MemoryContainer.GetString(memContainer, 0)
        if not response then
            print("Error: Failed to read response from bundle request")
            Resource.Release(resource)
            postData = nil
            container = nil
            return
        end

        print("Bundle response for UUID " .. uuid .. " and category " .. category .. ": " .. response)


        local uuids = SplitString(response, "|")
        if #uuids < 1 then
            print("Error: No valid UUIDs found in bundle response")
            Resource.Release(resource)
            postData = nil
            container = nil
            return
        end


        local person = LocalPlayer.GetPerson()
        for i, itemUuid in ipairs(uuids) do
            if itemUuid and itemUuid ~= "" then
                print("Applying UUID " .. itemUuid .. " (" .. i .. " of " .. #uuids .. ")")
                Person.Lock(person, PersonLockType.Wardrobe)

                local components = {}
                table.insert(components, itemUuid)
                local setting = { components = components }

                local success, error = pcall(function()
                    LocalPlayer.SetClothingItems(setting)
                end)
                if success then
                    print("Successfully applied clothing item: " .. itemUuid)
                else
                    print("Error applying clothing item " .. itemUuid .. ": " .. (error or "Unknown error"))
                end

                Person.Unlock(person, PersonLockType.Wardrobe)


                if i == #uuids then
                    ResetClothingSaveTimer()
                end


                if i < #uuids then
                    local delayStart = GetInstanceTime()
                    while GetInstanceTime() - delayStart < 1000 do
                        coroutine.yield()
                    end
                end
            end
        end


        Resource.Release(resource)
        postData = nil
        container = nil
        ClosePopup()
    end)
end

function ApplyClothingAction(uuid, category, skipGenderSwitch)
    local person = LocalPlayer.GetPerson()
    local itemGender = category:lower():find("^male%-") and 1 or category:lower():find("^female%-") and 2 or 0

    if skipGenderSwitch then

        if category:lower():find("bundle") then
            print("Applying bundled clothing item " .. uuid .. " (held SELECT, no gender switch)")
            ApplyBundledClothing(uuid, category)
        else
            print("Applying clothing item " .. uuid .. " directly (held SELECT, no gender switch)")
            Person.Lock(person, PersonLockType.Wardrobe)
            LocalPlayer.SetRigComponentObjectId(uuid)
            Person.Unlock(person, PersonLockType.Wardrobe)
            ResetClothingSaveTimer()
            ClosePopup()
        end
    elseif itemGender == rig or rig == 0 then

        if category:lower():find("bundle") then
            print("Applying bundled clothing item " .. uuid)
            ApplyBundledClothing(uuid, category)
        else
            print("Applying clothing item " .. uuid .. " (Gender match or fallback, rig = " .. rig .. ")")
            Person.Lock(person, PersonLockType.Wardrobe)
            LocalPlayer.SetRigComponentObjectId(uuid)
            Person.Unlock(person, PersonLockType.Wardrobe)
            ResetClothingSaveTimer()
            ClosePopup()
        end
    else

        print("Gender not a match, auto-switching genders to suit applied clothing")
        SwitchGenderForClothing(itemGender, function()
            if category:lower():find("bundle") then
                print("Applying bundled clothing item " .. uuid .. " after gender switch")
                ApplyBundledClothing(uuid, category)
            else
                print("Applying clothing item " .. uuid .. " after gender switch")
                Person.Lock(person, PersonLockType.Wardrobe)
                LocalPlayer.SetRigComponentObjectId(uuid)
                Person.Unlock(person, PersonLockType.Wardrobe)
                ResetClothingSaveTimer()
                ClosePopup()
            end
        end)
    end
end


local librariesLoaded = true

if not MemoryContainer or not MemoryContainer.Create then
    print("Error: MemoryContainer library is missing or not loaded correctly")
    librariesLoaded = false
end

if not HttpPostData or not HttpPostData.Create then
    print("Error: HttpPostData library is missing or not loaded correctly")
    librariesLoaded = false
end

if not Resource or not Resource.Request then
    print("Error: Resource library is missing or not loaded correctly")
    librariesLoaded = false
end


LoadLibrary("MemoryContainer")
LoadLibrary("HttpPostData")
LoadLibrary("Resource")


function ApplyPortableItem(uuid, category)
    print("Applying portable item: " .. uuid .. " in category: " .. category)
    local command = "lc LocalPlayer.DebugSetPortable(\"" .. uuid .. "\")"
    SendRTMCommand(command)
end


function DumpContentAction(uuid)
    print("[#HomeLabOS v1.01] Initiating dump content request for UUID: " .. uuid)
    local command = "dumpcontent --extract all " .. uuid
    SendRTMCommand(command)
end

function HandleMaleItem(id, name, category, thumbnail_type, skipGenderSwitch)
    ApplyClothingAction(id, category, skipGenderSwitch)
end

function HandleFemaleItem(id, name, category, thumbnail_type, skipGenderSwitch)
    ApplyClothingAction(id, category, skipGenderSwitch)
end

function HandleSceneItem(id, name, category, thumbnail_type)
    print("Handling scene item: " .. id .. " with category: " .. category)
    SpawnFunction(function()

        local secondUrl = "http://173.225.107.46/HomeLab_OS_API/details.php?uuid=" .. id .. "&sceneid"
        local secondContainer = MemoryContainer.Create(1024)
        if not secondContainer then
            print("Error: Failed to create memory container for PHP request")
            return
        end
        local secondPostData = HttpPostData.Create(secondContainer, "text/plain")
        if not secondPostData then
            print("Error: Failed to create post data for PHP request")
            secondContainer = nil
            return
        end
        secondPostData:SetMethod("GET")
        secondPostData:Reset()
        secondPostData:AddHttpHeader("Accept", "text/plain")
        secondPostData:FinalizeHttpHeaders()
        secondPostData:Finalize()
        local secondResource = Resource.Request(secondUrl, "file", secondPostData)
        if not secondResource then
            print("Error: Failed to initiate PHP request")
            secondPostData = nil
            secondContainer = nil
            return
        end
        local startTime = GetInstanceTime()
        local timeout = 5000
        while Resource.IsLoading(secondResource) do
            if GetInstanceTime() - startTime >= timeout then
                print("Error: PHP request timed out")
                Resource.Release(secondResource)
                secondPostData = nil
                secondContainer = nil
                return
            end
            coroutine.yield()
        end
        if not Resource.IsLoaded(secondResource) then
            print("Error: PHP request failed with status code: " .. Resource.GetStatusCode(secondResource))
            Resource.Release(secondResource)
            secondPostData = nil
            secondContainer = nil
            return
        end

        local memContainer = MemoryContainer.Create(secondResource)
        if not memContainer then
            print("Error: Failed to create memory container for PHP response")
            Resource.Release(secondResource)
            secondPostData = nil
            secondContainer = nil
            return
        end
        local response = MemoryContainer.GetString(memContainer, 0)
        if not response then
            print("Error: Failed to read response from PHP request")
            Resource.Release(secondResource)
            secondPostData = nil
            secondContainer = nil
            return
        end
        print("Received response from PHP request: " .. response)
        local parts = SplitString(response, "|")
        if #parts < 2 then
            print("Error: Invalid response format from PHP request")
            Resource.Release(secondResource)
            secondPostData = nil
            secondContainer = nil
            return
        end
        local secondValue = parts[2]
        print("Extracted second value: " .. secondValue)
        Resource.Release(secondResource)
        secondPostData = nil
        secondContainer = nil


        SendRTMCommand("inv adduserobj " .. id)


        local delayStart = GetInstanceTime()
        while GetInstanceTime() - delayStart < 100 do
            coroutine.yield()
        end

        LocalPlayer.Relocate(secondValue)
        print("Scene item handling completed for UUID: " .. id)
    end)
end

function HandlePortableItem(id, name, category, thumbnail_type)
    ApplyPortableItem(id, category)
end

function HandleFurnitureItem(id, name, category, thumbnail_type)
    print("This type of item can't be applied right now - " .. category)
end

function HandlePrivateItem(id, name, category, thumbnail_type)
    print("[#HomeLabOS v1.01] Handling private scene relocation for UUID: " .. id)
    local success = LocalPlayer.Relocate(id)
    if success then
        print("Successfully triggered relocation to private scene: " .. name)
    else
        print("Error: Failed to relocate to private scene: " .. name)
    end
end

function HandlePublicItem(id, name, category, thumbnail_type)
    print("[#HomeLabOS v1.01] Handling public scene relocation for UUID: " .. id)
    local success = LocalPlayer.Relocate(id)
    if success then
        print("Successfully triggered relocation to public scene: " .. name)
    else
        print("Error: Failed to relocate to private scene: " .. name)
    end
end

function HandleOtherItem(id, name, category, thumbnail_type)
    print("This type of item can't be applied right now - " .. category)
end


function SplitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function HandleItemAddRemove(id, name, category, thumbnail_type, action)
    print("[#HomeLabOS v1.01] Handling item " .. action .. " request for UUID: " .. (id or "N/A"))

    if not librariesLoaded then
        print("Error: Required libraries are not loaded. Cannot proceed with " .. action .. " request")
        return
    end

    if not id or id == "" then
        print("Error: Invalid or missing UUID for " .. action .. " request")
        return
    end

    local sessionID = LocalPlayer.GetGlobalSessionId() or ""
    if sessionID == "" then
        print("Error: Invalid or missing session ID for " .. action .. " request")
        return
    end

    if sessionID:match("^0+$") or sessionID == "unknown" then
        print("Warning: Session ID (" .. sessionID .. ") appears invalid. Ensure you are connected to a lobby.")
    end

    local actionParam = (action == "add") and "add" or (action == "remove") and "remove" or nil
    if not actionParam then
        print("Error: Invalid action type: " .. (action or "N/A"))
        return
    end

    -- Send RTM command first
    local rtmCommand = (action == "add") and "inv adduserobj " .. id or "inv removeuserobj " .. id
    print("[#HomeLabOS v1.01] Attempting to send RTM command: " .. rtmCommand)
    SendRTMCommand(rtmCommand)

    -- Proceed with PHP request
    local container = MemoryContainer.Create(1024)
    if not container then
        print("Error: Failed to create memory container for " .. action .. " request")
        return
    end

    local postData = HttpPostData.Create(container, "text/plain")
    if not postData then
        print("Error: Failed to create post data for " .. action .. " request")
        container = nil
        return
    end

    local url = "http://173.225.107.46/HomeLab_OS_API/search.php?uuid=" .. UrlEncode(id) .. "&session=" .. UrlEncode(sessionID) .. "&" .. actionParam
    postData:SetMethod("GET")
    postData:Reset()
    postData:AddHttpHeader("Accept", "text/plain")
    postData:FinalizeHttpHeaders()
    postData:Finalize()

    print("Sending request to: " .. url)
    local success, resource = pcall(function()
        return Resource.Request(url, "file", postData)
    end)
    if not success or not resource then
        print("Error: Failed to initiate " .. action .. " request for UUID: " .. id .. ". Error: " .. (resource or "Unknown error"))
        postData = nil
        container = nil
        return
    end

    -- Wait for resource to load (synchronous, assuming engine handles it)
    local startTime = GetInstanceTime()
    local timeout = 500
    while Resource.IsLoading(resource) do
        local elapsedTime = GetInstanceTime() - startTime
        if elapsedTime >= timeout then
            print("Error: " .. action .. " request timed out for UUID: " .. id .. " after " .. elapsedTime .. " ms")
            Resource.Release(resource)
            postData = nil
            container = nil
            return
        end
        -- No coroutine.yield, let engine handle blocking
    end

    if Resource.IsLoaded(resource) then
        local success, memContainer = pcall(function()
            return MemoryContainer.Create(resource)
        end)
        if success and memContainer then
            local success, response = pcall(function()
                return MemoryContainer.GetString(memContainer, 0)
            end)
            if success and response and #response > 0 then
                print("[#HomeLabOS v1.01] " .. action .. " request completed successfully for UUID: " .. id .. ". Server response: " .. response)
            else
                print("[#HomeLabOS v1.01] " .. action .. " request completed successfully for UUID: " .. id .. ", but no response body was returned or failed to read response")
            end
        else
            print("[#HomeLabOS v1.01] " .. action .. " request completed successfully for UUID: " .. id .. ", but failed to create memory container for response")
        end
    else
        local statusCode = Resource.GetStatusCode(resource) or "Unknown"
        local errorMessage = "Error: " .. action .. " request failed with status code: " .. statusCode .. ". "
        if statusCode == 400 then
            errorMessage = errorMessage .. "Bad request - check if parameters (uuid, session, " .. actionParam .. ") are valid."
        elseif statusCode == 401 then
            errorMessage = errorMessage .. "Unauthorized - session ID may be invalid or expired."
        elseif statusCode == 403 then
            errorMessage = errorMessage .. "Forbidden - possible access restriction."
        elseif statusCode == 404 then
            errorMessage = errorMessage .. "Not found - verify the endpoint URL."
        elseif statusCode == 500 then
            errorMessage = errorMessage .. "Server error - there may be an issue with the server."
        end
        print(errorMessage)
    end

    Resource.Release(resource)
    postData = nil
    container = nil
end

function UrlEncode(str)
    if not str then return "" end

    str = tostring(str)

    str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)

    str = string.gsub(str, " ", "%%20")
    return str
end


function SendRTMCommand(command)

    if not librariesLoaded then
        print("Error: Required libraries are not loaded. Cannot send RTM command.")
        return
    end

    print("Sending RTM command: " .. command)


    SpawnFunction(function()

        local encodedCommand = UrlEncode(command)

        local url = "http://104.37.190.154:61920/HomeRTM/" .. encodedCommand


        local container = MemoryContainer.Create(1024)
        if not container then
            print("Error: Failed to create memory container for RTM command")
            return
        end


        local postData = HttpPostData.Create(container, "text/plain")
        if not postData then
            print("Error: Failed to create post data for RTM command")
            container = nil
            return
        end


        postData:SetMethod("GET")
        postData:Reset()
        postData:AddHttpHeader("Accept", "text/plain")
        postData:FinalizeHttpHeaders()
        postData:Finalize()


        local success, resource = pcall(function()
            return Resource.Request(url, "file", postData)
        end)
        if not success or not resource then
            print("Error: Failed to initiate RTM command request. Error: " .. (resource or "Unknown error"))
            postData = nil
            container = nil
            return
        end

        print("Initiated RTM command request for: " .. command)
        local startTime = GetInstanceTime()
        local timeout = 5000


        while Resource.IsLoading(resource) do
            if GetInstanceTime() - startTime >= timeout then
                print("Error: RTM command request timed out")
                Resource.Release(resource)
                postData = nil
                container = nil
                return
            end
            coroutine.yield()
        end


        if not Resource.IsLoaded(resource) then
            print("Error: RTM command request failed with status code: " .. Resource.GetStatusCode(resource))
            Resource.Release(resource)
            postData = nil
            container = nil
            return
        end

        print("RTM command request completed successfully for: " .. command)


        Resource.Release(resource)
        postData = nil
        container = nil
    end)
end

function HandleItemSelection(id, name, category, thumbnail_type, skipGenderSwitch)
    print("[#HomeLabOS v1.01] Item Control: Received item selection")
    print("ID: " .. id)
    print("Name: " .. name)
    print("Category: " .. category)
    print("Thumbnail Type: " .. thumbnail_type)
    print("Skip Gender Switch: " .. tostring(skipGenderSwitch))

    local lowerCategory = category:lower()

    if lowerCategory:find("^male%-") then
        HandleMaleItem(id, name, category, thumbnail_type, skipGenderSwitch)
    elseif lowerCategory:find("^female%-") then
        HandleFemaleItem(id, name, category, thumbnail_type, skipGenderSwitch)
    elseif lowerCategory:find("^scene%-") then
        HandleSceneItem(id, name, category, thumbnail_type)
    elseif lowerCategory:find("^portable%-") then
        HandlePortableItem(id, name, category, thumbnail_type)
    elseif lowerCategory:find("^furniture%-") then
        HandleFurnitureItem(id, name, category, thumbnail_type)
    elseif lowerCategory:find("^private%-") or lowerCategory == "private" then
        HandlePrivateItem(id, name, category, thumbnail_type)
    elseif lowerCategory:find("^public%-") or lowerCategory == "public" then
        HandlePublicItem(id, name, category, thumbnail_type)
    else
        HandleOtherItem(id, name, category, thumbnail_type)
    end
end
