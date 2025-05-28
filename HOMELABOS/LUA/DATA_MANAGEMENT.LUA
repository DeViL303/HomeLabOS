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

g_SearchRequestPending = false
g_SearchResource = nil
g_SearchContainer = nil
g_SearchPostData = nil
g_SearchTabLabel = nil


g_CategoryRequestPending = false
g_CategoryResource = nil
g_CategoryContainer = nil
g_CategoryPostData = nil
g_CategoryTabLabel = nil


g_HelpRequestPending = false
g_HelpResource = nil
g_HelpContainer = nil
g_HelpPostData = nil
g_HelpAction = nil


g_LobbyRequestPending = false
g_LobbyResource = nil
g_LobbyContainer = nil
g_LobbyPostData = nil
g_LobbyTabLabel = nil


g_SystemInfoRequestPending = false
g_SystemInfoResource = nil
g_SystemInfoContainer = nil
g_SystemInfoPostData = nil
g_SystemInfoResponse = nil

function ResetCategoryRequest()
    g_CategoryRequestPending = false
    g_CategoryResource = nil
    if g_CategoryPostData then
        g_CategoryPostData = nil
    end
    g_CategoryTabLabel = nil
    print("[#HomeLabOS v1.01] Category request state reset")
end

function ResetSearchRequest()
    g_SearchRequestPending = false
    g_SearchResource = nil
    if g_SearchPostData then
        g_SearchPostData = nil
    end
    g_SearchTabLabel = nil
    print("[#HomeLabOS v1.01] Search request state reset")
end

function ResetHelpRequest()
    g_HelpRequestPending = false
    g_HelpResource = nil
    if g_HelpContainer then
        g_HelpContainer = nil
    end
    if g_HelpPostData then
        g_HelpPostData = nil
    end
    g_HelpAction = nil
    print("[#HomeLabOS v1.01] Help request state reset")
end

function ResetLobbyRequest()
    g_LobbyRequestPending = false
    g_LobbyResource = nil
    if g_LobbyContainer then
        g_LobbyContainer = nil
    end
    if g_LobbyPostData then
        g_LobbyPostData = nil
    end
    g_LobbyTabLabel = nil
    print("[#HomeLabOS v1.01] Lobby request state reset")
end

function ResetSystemInfoRequest()
    g_SystemInfoRequestPending = false
    if g_SystemInfoResource then
        Resource.Release(g_SystemInfoResource)
        g_SystemInfoResource = nil
    end
    if g_SystemInfoPostData then
        g_SystemInfoPostData = nil
    end
    if g_SystemInfoContainer then
        g_SystemInfoContainer = nil
    end
    print("[#HomeLabOS v1.01] System info request state reset")
end

function IsSearchRequestReady()
    if g_SearchResource and Resource.IsLoaded(g_SearchResource) then
        g_SearchRequestPending = false
        return true
    end
    return false
end

function IsCategoryRequestReady()
    if g_CategoryResource and Resource.IsLoaded(g_CategoryResource) then
        g_CategoryRequestPending = false
        return true
    end
    return false
end

function IsHelpRequestReady()
    if g_HelpResource and Resource.IsLoaded(g_HelpResource) then
        g_HelpRequestPending = false
        return true
    end
    return false
end

function IsLobbyRequestReady()
    if g_LobbyResource and Resource.IsLoaded(g_LobbyResource) then
        g_LobbyRequestPending = false
        return true
    end
    return false
end

function IsSystemInfoRequestReady()
    if g_SystemInfoResource and Resource.IsLoaded(g_SystemInfoResource) then
        g_SystemInfoRequestPending = false
        return true
    end
    return false
end


g_SentInvitesRequestPending = false
g_SentInvitesResource = nil
g_SentInvitesContainer = nil
g_SentInvitesPostData = nil

g_ReceivedInvitesRequestPending = false
g_ReceivedInvitesResource = nil
g_ReceivedInvitesContainer = nil
g_ReceivedInvitesPostData = nil

function ResetLobbyRequest()
    g_LobbyRequestPending = false
    g_LobbyResource = nil
    if g_LobbyContainer then
        g_LobbyContainer = nil
    end
    if g_LobbyPostData then
        g_LobbyPostData = nil
    end
    g_LobbyTabLabel = nil
    print("[#HomeLabOS v1.01] Lobby request state reset")
end


function ResetSentInvitesRequest()
    g_SentInvitesRequestPending = false
    if g_SentInvitesResource then
        Resource.Release(g_SentInvitesResource)
        g_SentInvitesResource = nil
    end
    if g_SentInvitesContainer then
        g_SentInvitesContainer = nil
    end
    if g_SentInvitesPostData then
        g_SentInvitesPostData = nil
    end
    print("[#HomeLabOS v1.01] Sent Invites request state reset")
end

function ResetReceivedInvitesRequest()
    g_ReceivedInvitesRequestPending = false
    if g_ReceivedInvitesResource then
        Resource.Release(g_ReceivedInvitesResource)
        g_ReceivedInvitesResource = nil
    end
    if g_ReceivedInvitesContainer then
        g_ReceivedInvitesContainer = nil
    end
    if g_ReceivedInvitesPostData then
        g_ReceivedInvitesPostData = nil
    end
    print("[#HomeLabOS v1.01] Received Invites request state reset")
end

function IsLobbyRequestReady()
    if g_LobbyResource and Resource.IsLoaded(g_LobbyResource) then
        g_LobbyRequestPending = false
        return true
    end
    return false
end


function IsSentInvitesRequestReady()
    if g_SentInvitesResource and Resource.IsLoaded(g_SentInvitesResource) then
        g_SentInvitesRequestPending = false
        return true
    end
    return false
end

function IsReceivedInvitesRequestReady()
    if g_ReceivedInvitesResource and Resource.IsLoaded(g_ReceivedInvitesResource) then
        g_ReceivedInvitesRequestPending = false
        return true
    end
    return false
end


g_SentInvitesRequestPending = false
g_SentInvitesResource = nil
g_SentInvitesContainer = nil
g_SentInvitesPostData = nil

g_ReceivedInvitesRequestPending = false
g_ReceivedInvitesResource = nil
g_ReceivedInvitesContainer = nil
g_ReceivedInvitesPostData = nil

function ResetLobbyRequest()
    g_LobbyRequestPending = false
    g_LobbyResource = nil
    if g_LobbyContainer then
        g_LobbyContainer = nil
    end
    if g_LobbyPostData then
        g_LobbyPostData = nil
    end
    g_LobbyTabLabel = nil
    print("[#HomeLabOS v1.01] Lobby request state reset")
end

function ResetSentInvitesRequest()
    g_SentInvitesRequestPending = false
    if g_SentInvitesResource then
        Resource.Release(g_SentInvitesResource)
        g_SentInvitesResource = nil
    end
    if g_SentInvitesContainer then
        g_SentInvitesContainer = nil
    end
    if g_SentInvitesPostData then
        g_SentInvitesPostData = nil
    end
    print("[#HomeLabOS v1.01] Sent Invites request state reset")
end

function ResetReceivedInvitesRequest()
    g_ReceivedInvitesRequestPending = false
    if g_ReceivedInvitesResource then
        Resource.Release(g_ReceivedInvitesResource)
        g_ReceivedInvitesResource = nil
    end
    if g_ReceivedInvitesContainer then
        g_ReceivedInvitesContainer = nil
    end
    if g_ReceivedInvitesPostData then
        g_ReceivedInvitesPostData = nil
    end
    print("[#HomeLabOS v1.01] Received Invites request state reset")
end

function IsLobbyRequestReady()
    if g_LobbyResource and Resource.IsLoaded(g_LobbyResource) then
        g_LobbyRequestPending = false
        return true
    end
    return false
end

function IsSentInvitesRequestReady()
    if g_SentInvitesResource and Resource.IsLoaded(g_SentInvitesResource) then
        g_SentInvitesRequestPending = false
        return true
    end
    return false
end

function IsReceivedInvitesRequestReady()
    if g_ReceivedInvitesResource and Resource.IsLoaded(g_ReceivedInvitesResource) then
        g_ReceivedInvitesRequestPending = false
        return true
    end
    return false
end

function RequestLobbyData(action)
    ResetLobbyRequest()
    ResetSentInvitesRequest()
    ResetReceivedInvitesRequest()

    local sessionID = LocalPlayer.GetGlobalSessionId() or "unknown"
    local myName = LocalPlayer.GetPerson() or "Unknown"
    local url
    if action == "view_stats" then
        url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?current"
    elseif action == "picks" then
        url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?picks"
    elseif action == "populartoday" then
        url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?popular"
    elseif action == "whoisonline" then

        local whoIsOnlineItems = {}
        local friendsItems = {}
        local sentInvitesItems = {}
        local receivedInvitesItems = {}


        print("[#HomeLabOS v1.01] Fetching friends list for Friends Online")
        local friends = LocalPlayer.GetFriends() or {}
        for _, friend in ipairs(friends) do
            local friendName = User.GetName(friend) or "UnknownFriend"
            table.insert(friendsItems, {
                name = friendName,
                status = "Online",
                texture_resource = nil,
                texture = nil
            })
            print("[#HomeLabOS v1.01] Added friend: " .. friendName)
        end
        print("[#HomeLabOS v1.01] Friends Online: Retrieved " .. #friendsItems .. " friends")


        g_LobbyItems["Players Online"] = g_LobbyItems["Players Online"] or {}
        g_LobbyItems["Players Online"].friends = friendsItems
        g_CategoryPageInfo["Players Online"] = g_CategoryPageInfo["Players Online"] or {}
        g_CategoryPageInfo["Players Online"]["friendsonline"] = "Page 1 of 1   Total Items " .. #friendsItems
        g_TotalPages["Players Online"] = g_TotalPages["Players Online"] or {}
        g_TotalPages["Players Online"]["friendsonline"] = 1
        g_CurrentPage["Players Online"] = g_CurrentPage["Players Online"] or {}
        g_CurrentPage["Players Online"]["friendsonline"] = 1


        url = "http://173.225.107.46/HomeLab_OS_API/lobbies.php?players"
        print("[#HomeLabOS v1.01] Initiating whoisonline API request to: " .. url)
        g_LobbyContainer = MemoryContainer.Create(4096)
        if not g_LobbyContainer then
            print("[#HomeLabOS v1.01] Error: Failed to create memory container for whoisonline request")
            g_LobbyItems["Players Online"].whoIsOnline = {}
            g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items 0"
            g_TotalPages["Players Online"]["whoisonline"] = 1
            g_CurrentPage["Players Online"]["whoisonline"] = 1
            g_LobbyItems["Players Online"].sentInvites = sentInvitesItems
            g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items 0"
            g_TotalPages["Players Online"]["sentinvites"] = 1
            g_CurrentPage["Players Online"]["sentinvites"] = 1
            g_LobbyItems["Players Online"].receivedInvites = receivedInvitesItems
            g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items 0"
            g_TotalPages["Players Online"]["receivedinvites"] = 1
            g_CurrentPage["Players Online"]["receivedinvites"] = 1
            g_LobbyTabLabel = "Players Online"
            print("[#HomeLabOS v1.01] whoisonline request failed: No memory container")
            return false
        end

        g_LobbyPostData = HttpPostData.Create(g_LobbyContainer, "text/plain")
        if not g_LobbyPostData then
            print("[#HomeLabOS v1.01] Error: Failed to create post data for whoisonline request")
            g_LobbyContainer = nil
            g_LobbyItems["Players Online"].whoIsOnline = {}
            g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items 0"
            g_TotalPages["Players Online"]["whoisonline"] = 1
            g_CurrentPage["Players Online"]["whoisonline"] = 1
            g_LobbyItems["Players Online"].sentInvites = sentInvitesItems
            g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items 0"
            g_TotalPages["Players Online"]["sentinvites"] = 1
            g_CurrentPage["Players Online"]["sentinvites"] = 1
            g_LobbyItems["Players Online"].receivedInvites = receivedInvitesItems
            g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items 0"
            g_TotalPages["Players Online"]["receivedinvites"] = 1
            g_CurrentPage["Players Online"]["receivedinvites"] = 1
            g_LobbyTabLabel = "Players Online"
            print("[#HomeLabOS v1.01] whoisonline request failed: No post data")
            return false
        end

        g_LobbyPostData:SetMethod("GET")
        g_LobbyPostData:Reset()
        g_LobbyPostData:AddHttpHeader("Accept", "text/plain")
        g_LobbyPostData:FinalizeHttpHeaders()
        g_LobbyPostData:Finalize()

        g_LobbyResource = Resource.Request(url, "file", g_LobbyPostData)
        if not g_LobbyResource then
            print("[#HomeLabOS v1.01] Error: Failed to initiate whoisonline API request")
            g_LobbyPostData = nil
            g_LobbyContainer = nil
            g_LobbyItems["Players Online"].whoIsOnline = {}
            g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items 0"
            g_TotalPages["Players Online"]["whoisonline"] = 1
            g_CurrentPage["Players Online"]["whoisonline"] = 1
            g_LobbyItems["Players Online"].sentInvites = sentInvitesItems
            g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items 0"
            g_TotalPages["Players Online"]["sentinvites"] = 1
            g_CurrentPage["Players Online"]["sentinvites"] = 1
            g_LobbyItems["Players Online"].receivedInvites = receivedInvitesItems
            g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items 0"
            g_TotalPages["Players Online"]["receivedinvites"] = 1
            g_CurrentPage["Players Online"]["receivedinvites"] = 1
            g_LobbyTabLabel = "Players Online"
            print("[#HomeLabOS v1.01] whoisonline request failed: Resource request failed")
            return false
        end


        g_LobbyItems["Players Online"].whoIsOnline = whoIsOnlineItems
        g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items 0"
        g_TotalPages["Players Online"]["whoisonline"] = 1
        g_CurrentPage["Players Online"]["whoisonline"] = 1
        g_LobbyItems["Players Online"].sentInvites = sentInvitesItems
        g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items 0"
        g_TotalPages["Players Online"]["sentinvites"] = 1
        g_CurrentPage["Players Online"]["sentinvites"] = 1
        g_LobbyItems["Players Online"].receivedInvites = receivedInvitesItems
        g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items 0"
        g_TotalPages["Players Online"]["receivedinvites"] = 1
        g_CurrentPage["Players Online"]["receivedinvites"] = 1
        g_LobbyTabLabel = "Players Online"
        g_LobbyRequestPending = true
        print("[#HomeLabOS v1.01] Initiated whoisonline request, waiting for API response. Friends Online: " .. #friendsItems .. " items")


        local startTime = GetInstanceTime()
        while g_LobbyRequestPending and (GetInstanceTime() - startTime) < 3000 do

            if IsLobbyRequestReady() then
                local memContainer = MemoryContainer.Create(g_LobbyResource)
                if memContainer then
                    local success, result = pcall(function() return MemoryContainer.GetString(memContainer, 0) end)
                    if success and result then
                        print("[#HomeLabOS v1.01] Successfully read whoisonline response in RequestLobbyData: " .. tostring(result))
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

                                local myNameStr = tostring(myName)
                                if myNameStr ~= "Unknown" and playerName:find("^" .. myNameStr, 1, true) then
                                    g_MyNameIs = playerName
                                    print("[#HomeLabOS v1.01] Updated g_MyNameIs to: " .. playerName)
                                end
                            end
                        end
                        g_LobbyItems["Players Online"].whoIsOnline = whoIsOnlineItems
                        g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items " .. #whoIsOnlineItems
                        print("[#HomeLabOS v1.01] Total players added: " .. #whoIsOnlineItems)
                    else
                        print("[#HomeLabOS v1.01] Error: Failed to read memory container for whoisonline in RequestLobbyData: " .. tostring(result))
                        g_LobbyItems["Players Online"].whoIsOnline = {}
                        g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items 0"
                    end
                    memContainer = nil
                else
                    print("[#HomeLabOS v1.01] Error: Failed to create memory container for whoisonline in RequestLobbyData")
                    g_LobbyItems["Players Online"].whoIsOnline = {}
                    g_CategoryPageInfo["Players Online"]["whoisonline"] = "Page 1 of 1   Total Items 0"
                end
                Resource.Release(g_LobbyResource)
                g_LobbyPostData = nil
                g_LobbyContainer = nil
                g_LobbyResource = nil
                g_LobbyRequestPending = false
            end
        end
        if g_LobbyRequestPending then
            print("[#HomeLabOS v1.01] Who Is Online request timed out after 3 seconds, will process in UIUpdate")
        end


        local sentInvitesUrl = "http://173.225.107.46/HomeLab_OS_API/checkinvites.php?sessionid=" .. UrlEncode(sessionID) .. "&myname=" .. UrlEncode(myName) .. "&type=sent"
        print("[#HomeLabOS v1.01] Initiating sent invites API request to: " .. sentInvitesUrl)
        g_SentInvitesContainer = MemoryContainer.Create(4096)
        if not g_SentInvitesContainer then
            print("[#HomeLabOS v1.01] Error: Failed to create memory container for sent invites request")
            sentInvitesItems = {}
        else
            g_SentInvitesPostData = HttpPostData.Create(g_SentInvitesContainer, "text/plain")
            if not g_SentInvitesPostData then
                print("[#HomeLabOS v1.01] Error: Failed to create post data for sent invites request")
                g_SentInvitesContainer = nil
                sentInvitesItems = {}
            else
                g_SentInvitesPostData:SetMethod("GET")
                g_SentInvitesPostData:Reset()
                g_SentInvitesPostData:AddHttpHeader("Accept", "text/plain")
                g_SentInvitesPostData:FinalizeHttpHeaders()
                g_SentInvitesPostData:Finalize()
                g_SentInvitesResource = Resource.Request(sentInvitesUrl, "file", g_SentInvitesPostData)
                if not g_SentInvitesResource then
                    print("[#HomeLabOS v1.01] Error: Failed to initiate sent invites API request")
                    g_SentInvitesPostData = nil
                    g_SentInvitesContainer = nil
                    sentInvitesItems = {}
                else
                    g_SentInvitesRequestPending = true
                    print("[#HomeLabOS v1.01] Sent invites request initiated, will process in UIUpdate")
                end
            end
        end


        local receivedInvitesUrl = "http://173.225.107.46/HomeLab_OS_API/checkinvites.php?sessionid=" .. UrlEncode(sessionID) .. "&myname=" .. UrlEncode(myName) .. "&type=received"
        print("[#HomeLabOS v1.01] Initiating received invites API request to: " .. receivedInvitesUrl)
        g_ReceivedInvitesContainer = MemoryContainer.Create(4096)
        if not g_ReceivedInvitesContainer then
            print("[#HomeLabOS v1.01] Error: Failed to create memory container for received invites request")
            receivedInvitesItems = {}
        else
            g_ReceivedInvitesPostData = HttpPostData.Create(g_ReceivedInvitesContainer, "text/plain")
            if not g_ReceivedInvitesPostData then
                print("[#HomeLabOS v1.01] Error: Failed to create post data for received invites request")
                g_ReceivedInvitesContainer = nil
                receivedInvitesItems = {}
            else
                g_ReceivedInvitesPostData:SetMethod("GET")
                g_ReceivedInvitesPostData:Reset()
                g_ReceivedInvitesPostData:AddHttpHeader("Accept", "text/plain")
                g_ReceivedInvitesPostData:FinalizeHttpHeaders()
                g_ReceivedInvitesPostData:Finalize()
                g_ReceivedInvitesResource = Resource.Request(receivedInvitesUrl, "file", g_ReceivedInvitesPostData)
                if not g_ReceivedInvitesResource then
                    print("[#HomeLabOS v1.01] Error: Failed to initiate received invites API request")
                    g_ReceivedInvitesPostData = nil
                    g_ReceivedInvitesContainer = nil
                    receivedInvitesItems = {}
                else
                    g_ReceivedInvitesRequestPending = true
                    print("[#HomeLabOS v1.01] Received invites request initiated, will process in UIUpdate")
                end
            end
        end


        g_LobbyItems["Players Online"].sentInvites = sentInvitesItems
        g_CategoryPageInfo["Players Online"]["sentinvites"] = "Page 1 of 1   Total Items " .. #sentInvitesItems
        g_LobbyItems["Players Online"].receivedInvites = receivedInvitesItems
        g_CategoryPageInfo["Players Online"]["receivedinvites"] = "Page 1 of 1   Total Items " .. #receivedInvitesItems
        print("[#HomeLabOS v1.01] Requests initiated. Friends Online: " .. #friendsItems .. ", Sent Invites: " .. #sentInvitesItems .. ", Received Invites: " .. #receivedInvitesItems .. " items")
        return true
    else
        print("[#HomeLabOS v1.01] Error: Invalid action for lobby request: " .. tostring(action))
        return false
    end

    g_LobbyContainer = MemoryContainer.Create(4096)
    if not g_LobbyContainer then
        print("[#HomeLabOS v1.01] Error: Failed to create memory container for lobby request")
        return false
    end

    g_LobbyPostData = HttpPostData.Create(g_LobbyContainer, "text/plain")
    if not g_LobbyPostData then
        print("[#HomeLabOS v1.01] Error: Failed to create post data for lobby request")
        g_LobbyContainer = nil
        return false
    end

    g_LobbyPostData:SetMethod("GET")
    g_LobbyPostData:Reset()
    g_LobbyPostData:AddHttpHeader("Accept", "text/plain")
    g_LobbyPostData:FinalizeHttpHeaders()
    g_LobbyPostData:Finalize()

    g_LobbyResource = Resource.Request(url, "file", g_LobbyPostData)
    if not g_LobbyResource then
        print("[#HomeLabOS v1.01] Error: Failed to initiate lobby request")
        g_LobbyPostData = nil
        g_LobbyContainer = nil
        return false
    end

    g_LobbyRequestPending = true
    g_LobbyTabLabel = "Players Online"
    print("[#HomeLabOS v1.01] Initiated lobby request for action: " .. action .. " with URL: " .. url)
    return true
end
function RequestSystemInfo()
    ResetSystemInfoRequest()

    local url = "http://173.225.107.46/HomeLab_OS_API/details.php?about_v101"

    g_SystemInfoContainer = MemoryContainer.Create(8192)
    if not g_SystemInfoContainer then
        print("[#HomeLabOS v1.01] Error: Failed to create memory container for system info request")
        return false
    end

    g_SystemInfoPostData = HttpPostData.Create(g_SystemInfoContainer, "text/plain")
    if not g_SystemInfoPostData then
        print("[#HomeLabOS v1.01] Error: Failed to create post data for system info request")
        g_SystemInfoContainer = nil
        return false
    end

    g_SystemInfoPostData:SetMethod("GET")
    g_SystemInfoPostData:Reset()
    g_SystemInfoPostData:AddHttpHeader("Accept", "text/plain")
    g_SystemInfoPostData:FinalizeHttpHeaders()
    g_SystemInfoPostData:Finalize()

    g_SystemInfoResource = Resource.Request(url, "file", g_SystemInfoPostData)
    if not g_SystemInfoResource then
        print("[#HomeLabOS v1.01] Error: Failed to initiate system info request")
        g_SystemInfoPostData = nil
        g_SystemInfoContainer = nil
        return false
    end

    g_SystemInfoRequestPending = true
    print("[#HomeLabOS v1.01] Initiated system info request")
    return true
end


g_Colors = {
    White = Vector4.Create(1.0, 1.0, 1.0, 1.0),
    White80 = Vector4.Create(1.0, 1.0, 1.0, 0.80),
    White70 = Vector4.Create(1.0, 1.0, 1.0, 0.70),
    Black95 = Vector4.Create(0.0, 0.0, 0.0, 0.95),
    Black85 = Vector4.Create(0.0, 0.0, 0.0, 0.92),
    BlackSolid = Vector4.Create(0.0, 0.0, 0.0, 1.0),
    GreenHighlight = Vector4.Create(0.0, 0.5, 0.0, 1.0),
    DimOverlay = Vector4.Create(0.0, 0.0, 0.0, 0.65),
    DarkGrey = Vector4.Create(0.1, 0.1, 0.1, 1.0),
    DarkGrey15 = Vector4.Create(0.15, 0.15, 0.15, 1.0),
    LightGrey = Vector4.Create(0.8, 0.8, 0.8, 0.9),
    MediumGrey = Vector4.Create(0.2, 0.2, 0.2, 0.9),
    Black05 = Vector4.Create(0.05, 0.05, 0.05, 0.98)
}

function ParsePageInfo(pageInfo)
    local currentPage, totalPages = pageInfo:match("Page (%d+) of (%d+)")
    if currentPage and totalPages then
        return tonumber(currentPage), tonumber(totalPages)
    end
    return nil, nil
end

function TrimTextToFit(text, maxWidth)
    local trimmedText = text
    local textSize = g_Renderer:GetTextSize(trimmedText)
    if textSize:X() <= maxWidth then
        return trimmedText
    end

    trimmedText = trimmedText .. "..."
    while textSize:X() > maxWidth and #trimmedText > 3 do
        trimmedText = trimmedText:sub(1, -5) .. "..."
        textSize = g_Renderer:GetTextSize(trimmedText)
    end
    return trimmedText
end

function IsGridTab(label)
    return label == "Male Clothing" or label == "Female Clothing" or label == "Portables" or label == "Furniture" or label == "Scenes" or label == "Search" or label == "MyInventory"
end

function ClearTextureCache()
    for id, textureEntry in pairs(g_GridTextures) do
        if textureEntry.resource then
            Resource.Release(textureEntry.resource)
        end
        g_GridTextures[id] = nil
    end
    g_GridTextures = {}
    g_DownloadingItems = {}
end

function ClearTabTextures(tabLabel)
    local items
    if tabLabel == "Players Online" then
        items = g_LobbyItems[tabLabel] or {}
    else
        items = g_GridItems[tabLabel] or {}
    end

    for idx, item in ipairs(items) do
        local itemId = item.id or item.trimmedDecID
        if itemId and g_GridTextures[itemId] then
            if g_GridTextures[itemId].resource then
                Resource.Release(g_GridTextures[itemId].resource)
            end
            g_GridTextures[itemId] = nil
        end
        item.texture_resource = nil
        item.texture = nil
    end

    for i = #g_DownloadingItems, 1, -1 do
        if g_DownloadingItems[i].tabLabel == tabLabel then
            local idx = g_DownloadingItems[i].index
            local item = items[idx]
            if item then
                local itemId = item.id or item.trimmedDecID
                if itemId and g_GridTextures[itemId] and g_GridTextures[itemId].resource then
                    Resource.Release(g_GridTextures[itemId].resource)
                    g_GridTextures[itemId] = nil
                end
                item.texture_resource = nil
                item.texture = nil
            end
            table.remove(g_DownloadingItems, i)
        end
    end
end