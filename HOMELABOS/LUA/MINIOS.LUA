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
LoadLibrary("SoundBank")


g_R1MenuSelectedIndex = 1
g_L1MenuSelectedIndex = 1

function UIRenderMiniMenu()
    if g_MiniMenuActive then
        local menuWidth = 130
        local menuHeight = 40
        local margin = 5
        local menuX = margin
        local menuY = margin
        local bgColor = Vector4.Create(0.0, 0.0, 0.0, 0.7)
        local textColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)
        local legendColor = Vector4.Create(1.0, 1.0, 1.0, 0.70)


        g_Renderer:DrawRect2d(
            menuX, menuY,
            menuX + menuWidth, menuY + menuHeight,
            bgColor
        )



        g_Renderer:SetFontScale(0.74, -0.74)
        g_Renderer:SetFontHorzAlignment("left")
        local legendPos = Vector4.Create(menuX +  8, menuY + menuHeight - 36, 0)
        g_Renderer:DrawText2d(legendPos, g_Me:GetLocalizedText("kHLOSMiniTitle"), legendColor)


        g_Renderer:SetFontScale(0.63, -0.63)
        local legendPos = Vector4.Create(menuX + 5, menuY + menuHeight - 16, 0)
        g_Renderer:DrawText2d(legendPos, g_Me:GetLocalizedText("kL1QuickChat"), legendColor)


        g_Renderer:SetFontScale(0.63, -0.63)
        local legendPos = Vector4.Create(menuX + 45, menuY + menuHeight - 16, 0)
        g_Renderer:DrawText2d(legendPos, g_Me:GetLocalizedText("kR1QuickEmotes"), legendColor)


        g_Renderer:SetFontScale(0.63, -0.63)
        local legendPos = Vector4.Create(menuX + 95, menuY + menuHeight - 16, 0)
        g_Renderer:DrawText2d(legendPos, g_Me:GetLocalizedText("kFullMode"), legendColor)


        if g_ShowWheelPopup then
            local popupWidth = 130
            local popupHeight = 400
            local popupX = menuX
            local popupY = menuY + 40
            local popupBgColor = Vector4.Create(0.0, 0.0, 0.0, 0.7)
            local popupTextColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)
            local highlightColor = Vector4.Create(0.0, 1.0, 0.0, 1.0)
            local bottomMargin = 10


            g_Renderer:DrawRect2d(
                popupX, popupY,
                popupX + popupWidth, popupY + popupHeight,
                popupBgColor
            )


            local gridHeight = popupHeight - bottomMargin
            local cellWidth = popupWidth / 2
            local cellHeight = gridHeight / 20


            g_Renderer:SetFontScale(0.64, -0.64)
            g_Renderer:SetFontHorzAlignment("center")


            local actions = {
                "", "Agree", "Disagree",
                "Beckon", "Bow",
                "Cheer", "Clap",
                "Frustration", "Laugh",
                "Point", "Wave",
                "Salute", "Shrug",
                "Dance", "Nod",
                "Sigh", "Whistle",
                "Taunt", "Greet",
                "Spin", "Jump",
                "Run", "Crouch",
                "Wave Left", "Wave Right",
                "Celebrate", "Flex",
                "Point Up", "Point Down",
                "Kick", "Punch",
                "Sit", "Stand",
                "Look Left", "Look Right",
                "Thumbs Up", "Thumbs Down",
                "Shake Head", "Nod Head",
                "Wave Back"
            }


            for row = 1, 20 do
                for col = 1, 2 do
                    local actionIndex = (row - 1) * 2 + col
                    if actionIndex == g_R1MenuSelectedIndex then
                        local x1 = popupX + (col - 1) * cellWidth
                        local y1 = popupY + (row - 1) * cellHeight
                        local x2 = popupX + col * cellWidth
                        local y2 = popupY + row * cellHeight


                        g_Renderer:DrawRect2d(
                            x1, y1,
                            x2, y1 + 1,
                            highlightColor
                        )

                        g_Renderer:DrawRect2d(
                            x1, y2 - 1,
                            x2, y2,
                            highlightColor
                        )

                        g_Renderer:DrawRect2d(
                            x1, y1,
                            x1 + 1, y2,
                            highlightColor
                        )

                        g_Renderer:DrawRect2d(
                            x2 - 1, y1,
                            x2, y2,
                            highlightColor
                        )
                    end
                end
            end


            for row = 1, 20 do
                for col = 1, 2 do
                    local actionIndex = (row - 1) * 2 + col
                    local textX = popupX + (col - 0.5) * cellWidth
                    local textY = popupY + (row - 0.5) * cellHeight - 7
                    local textPos = Vector4.Create(textX, textY, 0)
                    g_Renderer:DrawText2d(textPos, actions[actionIndex], popupTextColor)
                end
            end

            g_Renderer:SetFontHorzAlignment("left")
        end


        if g_ShowL1Popup then
            local popupWidth = 130
            local popupHeight = 400
            local popupX = menuX
            local popupY = menuY + 40
            local popupBgColor = Vector4.Create(0.0, 0.0, 0.0, 0.7)
            local popupTextColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)
            local highlightColor = Vector4.Create(0.0, 1.0, 0.0, 1.0)
            local bottomMargin = 20


            g_Renderer:DrawRect2d(
                popupX, popupY,
                popupX + popupWidth, popupY + popupHeight,
                popupBgColor
            )


            local gridHeight = popupHeight - bottomMargin
            local cellWidth = popupWidth / 2
            local cellHeight = gridHeight / 20


            g_Renderer:SetFontScale(0.64, -0.64)
            g_Renderer:SetFontHorzAlignment("center")


            local actions = {
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


            for row = 1, 20 do
                for col = 1, 2 do
                    local actionIndex = (row - 1) * 2 + col
                    if actionIndex == g_L1MenuSelectedIndex then
                        local x1 = popupX + (col - 1) * cellWidth
                        local y1 = popupY + (row - 1) * cellHeight
                        local x2 = popupX + col * cellWidth
                        local y2 = popupY + row * cellHeight


                        g_Renderer:DrawRect2d(
                            x1, y1,
                            x2, y1 + 1,
                            highlightColor
                        )

                        g_Renderer:DrawRect2d(
                            x1, y2 - 1,
                            x2, y2,
                            highlightColor
                        )

                        g_Renderer:DrawRect2d(
                            x1, y1,
                            x1 + 1, y2,
                            highlightColor
                        )

                        g_Renderer:DrawRect2d(
                            x2 - 1, y1,
                            x2, y2,
                            highlightColor
                        )
                    end
                end
            end


            for row = 1, 20 do
                for col = 1, 2 do
                    local actionIndex = (row - 1) * 2 + col
                    local textX = popupX + (col - 0.5) * cellWidth
                    local textY = popupY + (row - 0.5) * cellHeight - 7
                    local textPos = Vector4.Create(textX, textY, 0)
                    g_Renderer:DrawText2d(textPos, actions[actionIndex], popupTextColor)
                end
            end

            g_Renderer:SetFontHorzAlignment("left")
        end
    end
end