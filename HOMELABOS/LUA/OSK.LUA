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


g_CustomOSKActive = false
g_CustomOSKSelectedButton = 1
g_CustomOSKText = ""
g_CustomOSKCallback = nil
g_CustomOSKTitleKey = nil
g_ShiftActive = false
g_ShiftLock = false
g_LastShiftPressTime = 0
g_ShiftDoublePressThreshold = 500
g_CharSet = 0
g_MaxInputLength = 300


g_KeyboardButtons = {

    { label = "1", action = "1", shift_label = "!", shift_action = "!", circled_lower_label = "①", circled_lower_action = "①", circled_upper_label = "①", circled_upper_action = "①", localized_label = "kSymbol1", localized_action = "kSymbol1", symbols_label = "★", symbols_action = "★", arrows_symbols_label = "±", arrows_symbols_action = "±", repear_label = "ー", repear_action = "ー" },
    { label = "2", action = "2", shift_label = "@", shift_action = "@", circled_lower_label = "②", circled_lower_action = "②", circled_upper_label = "②", circled_upper_action = "②", localized_label = "kSymbol2", localized_action = "kSymbol2", symbols_label = "☆", symbols_action = "☆", arrows_symbols_label = "×", arrows_symbols_action = "×", repear_label = "ニ", repear_action = "ニ" },
    { label = "3", action = "3", shift_label = "#", shift_action = "#", circled_lower_label = "③", circled_lower_action = "③", circled_upper_label = "③", circled_upper_action = "③", localized_label = "kSymbol3", localized_action = "kSymbol3", symbols_label = "♥", symbols_action = "♥", arrows_symbols_label = "÷", arrows_symbols_action = "÷", repear_label = "ミ", repear_action = "ミ" },
    { label = "4", action = "4", shift_label = "$", shift_action = "$", circled_lower_label = "④", circled_lower_action = "④", circled_upper_label = "④", circled_upper_action = "④", localized_label = "kSymbol4", localized_action = "kSymbol4", symbols_label = "♡", symbols_action = "♡", arrows_symbols_label = "√", arrows_symbols_action = "√", repear_label = "ヨ", repear_action = "ヨ" },
    { label = "5", action = "5", shift_label = "%", shift_action = "%", circled_lower_label = "⑤", circled_lower_action = "⑤", circled_upper_label = "⑤", circled_upper_action = "⑤", localized_label = "kSymbol5", localized_action = "kSymbol5", symbols_label = "♠", symbols_action = "♠", arrows_symbols_label = "¢", arrows_symbols_action = "¢", repear_label = "コ", repear_action = "コ" },
    { label = "6", action = "6", shift_label = "^", shift_action = "^", circled_lower_label = "⑥", circled_lower_action = "⑥", circled_upper_label = "⑥", circled_upper_action = "⑥", localized_label = "kSymbol6", localized_action = "kSymbol6", symbols_label = "♣", symbols_action = "♣", arrows_symbols_label = "«", arrows_symbols_action = "«", repear_label = "ロ", repear_action = "ロ" },
    { label = "7", action = "7", shift_label = "&", shift_action = "&", circled_lower_label = "⑦", circled_lower_action = "⑦", circled_upper_label = "⑦", circled_upper_action = "⑦", localized_label = "kSymbol7", localized_action = "kSymbol7", symbols_label = "♦", symbols_action = "♦", arrows_symbols_label = "»", arrows_symbols_action = "»", repear_label = "ナ", repear_action = "ナ" },
    { label = "8", action = "8", shift_label = "*", shift_action = "*", circled_lower_label = "⑧", circled_lower_action = "⑧", circled_upper_label = "⑧", circled_upper_action = "⑧", localized_label = "kSymbol8", localized_action = "kSymbol8", symbols_label = "♢", symbols_action = "♢", arrows_symbols_label = "·", arrows_symbols_action = "·", repear_label = "ハ", repear_action = "ハ" },
    { label = "9", action = "9", shift_label = "(", shift_action = "(", circled_lower_label = "⑨", circled_lower_action = "⑨", circled_upper_label = "⑨", circled_upper_action = "⑨", localized_label = "kSymbol9", localized_action = "kSymbol9", symbols_label = "☁", symbols_action = "☁", arrows_symbols_label = "¬", arrows_symbols_action = "¬", repear_label = "力", repear_action = "力" },
    { label = "0", action = "0", shift_label = ")", shift_action = ")", circled_lower_label = "⓪", circled_lower_action = "⓪", circled_upper_label = "⓪", circled_upper_action = "⓪", localized_label = "kSymbol10", localized_action = "kSymbol10", symbols_label = "☂", symbols_action = "☂", arrows_symbols_label = "µ", arrows_symbols_action = "µ", repear_label = "ネ", repear_action = "ネ" },
    { localisedText = "kDelete", action = "backspace", repear_label = "メ", repear_action = "メ" },

    { label = "q", action = "q", shift_label = "Q", shift_action = "Q", circled_lower_label = "ⓠ", circled_lower_action = "ⓠ", circled_upper_label = "Ⓠ", circled_upper_action = "Ⓠ", localized_label = "kSymbol11", localized_action = "kSymbol11", symbols_label = "♂", symbols_action = "♂", arrows_symbols_label = "¶", arrows_symbols_action = "¶", repear_label = "キ", repear_action = "キ" },
    { label = "w", action = "w", shift_label = "W", shift_action = "W", circled_lower_label = "ⓦ", circled_lower_action = "ⓦ", circled_upper_label = "Ⓦ", circled_upper_action = "Ⓦ", localized_label = "kSymbol12", localized_action = "kSymbol12", symbols_label = "♀", symbols_action = "♀", arrows_symbols_label = "§", arrows_symbols_action = "§", repear_label = "ワ", repear_action = "ワ" },
    { label = "e", action = "e", shift_label = "E", shift_action = "E", circled_lower_label = "ⓔ", circled_lower_action = "ⓔ", circled_upper_label = "Ⓔ", circled_upper_action = "Ⓔ", localized_label = "kSymbol13", localized_action = "kSymbol13", symbols_label = "☃", symbols_action = "☃", arrows_symbols_label = "†", arrows_symbols_action = "†", repear_label = "エ", repear_action = "エ" },
    { label = "r", action = "r", shift_label = "R", shift_action = "R", circled_lower_label = "ⓡ", circled_lower_action = "ⓡ", circled_upper_label = "Ⓡ", circled_upper_action = "Ⓡ", localized_label = "kSymbol14", localized_action = "kSymbol14", symbols_label = "☎", symbols_action = "☎", arrows_symbols_label = "‡", arrows_symbols_action = "‡", repear_label = "ソ", repear_action = "ソ" },
    { label = "t", action = "t", shift_label = "T", shift_action = "T", circled_lower_label = "ⓣ", circled_lower_action = "ⓣ", circled_upper_label = "Ⓣ", circled_upper_action = "Ⓣ", localized_label = "kSymbol15", localized_action = "kSymbol15", symbols_label = "♯", symbols_action = "♯", arrows_symbols_label = "•", arrows_symbols_action = "•", repear_label = "ト", repear_action = "ト" },
    { label = "y", action = "y", shift_label = "Y", shift_action = "Y", circled_lower_label = "ⓨ", circled_lower_action = "ⓨ", circled_upper_label = "Ⓨ", circled_upper_action = "Ⓨ", localized_label = "kSymbol16", localized_action = "kSymbol16", symbols_label = "♭", symbols_action = "♭", arrows_symbols_label = "¤", arrows_symbols_action = "¤", repear_label = "ヤ", repear_action = "ヤ" },
    { label = "u", action = "u", shift_label = "U", shift_action = "U", circled_lower_label = "ⓤ", circled_lower_action = "ⓤ", circled_upper_label = "Ⓤ", circled_upper_action = "Ⓤ", localized_label = "kSymbol17", localized_action = "kSymbol17", symbols_label = "♤", symbols_action = "♤", arrows_symbols_label = "‰", arrows_symbols_action = "‰", repear_label = "ウ", repear_action = "ウ" },
    { label = "i", action = "i", shift_label = "I", shift_action = "I", circled_lower_label = "ⓘ", circled_lower_action = "ⓘ", circled_upper_label = "Ⓘ", circled_upper_action = "Ⓘ", localized_label = "kSymbol18", localized_action = "kSymbol18", symbols_label = "♧", symbols_action = "♧", arrows_symbols_label = "⁄", arrows_symbols_action = "⁄", repear_label = "イ", repear_action = "イ" },
    { label = "o", action = "o", shift_label = "O", shift_action = "O", circled_lower_label = "ⓞ", circled_lower_action = "ⓞ", circled_upper_label = "Ⓞ", circled_upper_action = "Ⓞ", localized_label = "kSymbol19", localized_action = "kSymbol19", symbols_label = "♩", symbols_action = "♩", arrows_symbols_label = "[", arrows_symbols_action = "[", repear_label = "オ", repear_action = "オ" },
    { label = "p", action = "p", shift_label = "P", shift_action = "P", circled_lower_label = "ⓟ", circled_lower_action = "ⓟ", circled_upper_label = "Ⓟ", circled_upper_action = "Ⓟ", localized_label = "kSymbol20", localized_action = "kSymbol20", symbols_label = "♬", symbols_action = "♬", arrows_symbols_label = "]", arrows_symbols_action = "]", repear_label = "ヘ", repear_action = "ヘ" },
    { localisedText = "kClear", action = "clear", repear_label = "ラ", repear_action = "ラ" },

    { label = "a", action = "a", shift_label = "A", shift_action = "A", circled_lower_label = "ⓐ", circled_lower_action = "ⓐ", circled_upper_label = "Ⓐ", circled_upper_action = "Ⓐ", localized_label = "kSymbol21", localized_action = "kSymbol21", symbols_label = "☝", symbols_action = "☝", arrows_symbols_label = "{", arrows_symbols_action = "{", repear_label = "ア", repear_action = "ア" },
    { label = "s", action = "s", shift_label = "S", shift_action = "S", circled_lower_label = "ⓢ", circled_lower_action = "ⓢ", circled_upper_label = "Ⓢ", circled_upper_action = "Ⓢ", localized_label = "kSymbol22", localized_action = "kSymbol22", symbols_label = "☞", symbols_action = "☞", arrows_symbols_label = "}", arrows_symbols_action = "}", repear_label = "ス", repear_action = "ス" },
    { label = "d", action = "d", shift_label = "D", shift_action = "D", circled_lower_label = "ⓓ", circled_lower_action = "ⓓ", circled_upper_label = "Ⓓ", circled_upper_action = "Ⓓ", localized_label = "←", localized_action = "←", symbols_label = "☜", symbols_action = "☜", arrows_symbols_label = "<", arrows_symbols_action = "<", repear_label = "チ", repear_action = "チ" },
    { label = "f", action = "f", shift_label = "F", shift_action = "F", circled_lower_label = "ⓕ", circled_lower_action = "ⓕ", circled_upper_label = "Ⓕ", circled_upper_action = "Ⓕ", localized_label = "→", localized_action = "→", symbols_label = "☟", symbols_action = "☟", arrows_symbols_label = ">", arrows_symbols_action = ">", repear_label = "フ", repear_action = "フ" },
    { label = "g", action = "g", shift_label = "G", shift_action = "G", circled_lower_label = "ⓖ", circled_lower_action = "ⓖ", circled_upper_label = "Ⓖ", circled_upper_action = "Ⓖ", localized_label = "↑", localized_action = "↑", symbols_label = "●", symbols_action = "●", arrows_symbols_label = "|", arrows_symbols_action = "|", repear_label = "ケ", repear_action = "ケ" },
    { label = "h", action = "h", shift_label = "H", shift_action = "H", circled_lower_label = "ⓗ", circled_lower_action = "ⓗ", circled_upper_label = "Ⓗ", circled_upper_action = "Ⓗ", localized_label = "↓", localized_action = "↓", symbols_label = "○", symbols_action = "○", arrows_symbols_label = "\\", arrows_symbols_action = "\\", repear_label = "ホ", repear_action = "ホ" },
    { label = "j", action = "j", shift_label = "J", shift_action = "J", circled_lower_label = "ⓙ", circled_lower_action = "ⓙ", circled_upper_label = "Ⓙ", circled_upper_action = "Ⓙ", localized_label = "↔", localized_action = "↔", symbols_label = "■", symbols_action = "■", arrows_symbols_label = "~", arrows_symbols_action = "~", repear_label = "シ", repear_action = "シ" },
    { label = "k", action = "k", shift_label = "K", shift_action = "K", circled_lower_label = "ⓚ", circled_lower_action = "ⓚ", circled_upper_label = "Ⓚ", circled_upper_action = "Ⓚ", localized_label = "↕", localized_action = "↕", symbols_label = "□", symbols_action = "□", arrows_symbols_label = "¿", arrows_symbols_action = "¿", repear_label = "ク", repear_action = "ク" },
    { label = "l", action = "l", shift_label = "L", shift_action = "L", circled_lower_label = "ⓛ", circled_lower_action = "ⓛ", circled_upper_label = "Ⓛ", circled_upper_action = "Ⓛ", localized_label = "◎", localized_action = "◎", symbols_label = "▲", symbols_action = "▲", arrows_symbols_label = "¡", arrows_symbols_action = "¡", repear_label = "リ", repear_action = "リ" },
    { label = ";", action = ";", shift_label = ":", shift_action = ":", localized_label = "⊙", localized_action = "⊙", symbols_label = "▼", symbols_action = "▼", arrows_symbols_label = "¯", arrows_symbols_action = "¯", repear_label = "ツ", repear_action = "ツ" },
    { localisedText = "kEnter", action = "enter", repear_label = "サ", repear_action = "サ" },

    { label = "z", action = "z", shift_label = "Z", shift_action = "Z", circled_lower_label = "ⓩ", circled_lower_action = "ⓩ", circled_upper_label = "Ⓩ", circled_upper_action = "Ⓩ", localized_label = "∞", localized_action = "∞", symbols_label = "◆", symbols_action = "◆", arrows_symbols_label = "°", arrows_symbols_action = "°", repear_label = "ン", repear_action = "ン" },
    { label = "x", action = "x", shift_label = "X", shift_action = "X", circled_lower_label = "ⓧ", circled_lower_action = "ⓧ", circled_upper_label = "Ⓧ", circled_upper_action = "Ⓧ", localized_label = "…", localized_action = "…", symbols_label = "◇", symbols_action = "◇", arrows_symbols_label = "²", arrows_symbols_action = "²", repear_label = "ヌ", repear_action = "ヌ" },
    { label = "c", action = "c", shift_label = "C", shift_action = "C", circled_lower_label = "ⓒ", circled_lower_action = "ⓒ", circled_upper_label = "Ⓒ", circled_upper_action = "Ⓒ", localized_label = "™", localized_action = "™", symbols_label = "♪", symbols_action = "♪", arrows_symbols_label = "³", arrows_symbols_action = "³", repear_label = "セ", repear_action = "セ" },
    { label = "v", action = "v", shift_label = "V", shift_action = "V", circled_lower_label = "ⓥ", circled_lower_action = "ⓥ", circled_upper_label = "Ⓥ", circled_upper_action = "Ⓥ", localized_label = "©", localized_action = "©", symbols_label = "♫", symbols_action = "♫", arrows_symbols_label = "¸", arrows_symbols_action = "¸", repear_label = "ソ", repear_action = "ソ" },
    { label = "b", action = "b", shift_label = "B", shift_action = "B", circled_lower_label = "ⓑ", circled_lower_action = "ⓑ", circled_upper_label = "Ⓑ", circled_upper_action = "Ⓑ", localized_label = "®", localized_action = "®", symbols_label = "△", symbols_action = "△", arrows_symbols_label = "´", arrows_symbols_action = "´", repear_label = "ビ", repear_action = "ビ" },
    { label = "n", action = "n", shift_label = "N", shift_action = "N", circled_lower_label = "ⓝ", circled_lower_action = "ⓝ", circled_upper_label = "Ⓝ", circled_upper_action = "Ⓝ", localized_label = "≈", localized_action = "≈", symbols_label = "▽", symbols_action = "▽", arrows_symbols_label = "¨", arrows_symbols_action = "¨", repear_label = "ノ", repear_action = "ノ" },
    { label = "m", action = "m", shift_label = "M", shift_action = "M", circled_lower_label = "ⓜ", circled_lower_action = "ⓜ", circled_upper_label = "Ⓜ", circled_upper_action = "Ⓜ", localized_label = "≡", localized_action = "≡", symbols_label = "♨", symbols_action = "♨", arrows_symbols_label = "", arrows_symbols_action = "", repear_label = "ム", repear_action = "ム" },
    { label = "!", action = "!", shift_label = "/", shift_action = "/", localized_label = "≠", localized_action = "≠", symbols_label = "☉", symbols_action = "☉", arrows_symbols_label = "", arrows_symbols_action = "", repear_label = "タ", repear_action = "タ" },
    { label = ",", action = ",", shift_label = "-", shift_action = "-", localized_label = "≤", localized_action = "≤", symbols_label = "¥", symbols_action = "¥", arrows_symbols_label = "", arrows_symbols_action = "", repear_label = "テ", repear_action = "テ" },
    { label = ".", action = ".", shift_label = "_", shift_action = "_", localized_label = "≥", localized_action = "≥", symbols_label = "€", symbols_action = "€", arrows_symbols_label = "", arrows_symbols_action = "", repear_label = "ヲ", repear_action = "ヲ" },
    { label = "?", action = "?", localized_label = "∥", localized_action = "∥", symbols_label = "£", symbols_action = "£", arrows_symbols_label = "", arrows_symbols_action = "", repear_label = "ヒ", repear_action = "ヒ" },

    { localisedText = "kShift", action = "shift" },
    { localisedText = "kSpace", action = "space" },
    { localisedText = "kShift", action = "shift" },
    { localisedText = "kCapsLock", action = "capslock" },
    { localisedText = "kToggleCharSet", action = "toggle" }
}


function removeLastUTF8Char(str)
    if str == "" then
        return ""
    end

    local len = #str
    local pos = len

    while pos > 0 do
        local byte = string.byte(str, pos)
        if byte < 0x80 or byte >= 0xC0 then
            break
        end
        pos = pos - 1
    end

    if pos <= 0 then
        return ""
    end

    return string.sub(str, 1, pos - 1)
end

function OpenCustomOSK(callback, initialText, titleKey)
    g_CustomOSKActive = true
    g_CustomOSKSelectedButton = 1
    g_CustomOSKText = initialText or ""
    g_CustomOSKCallback = callback
    g_CustomOSKTitleKey = titleKey or "kEnterSearchKeywords"
    g_ShiftActive = false
    g_ShiftLock = false
    g_CharSet = 0
    g_LastShiftPressTime = 0
    gSoundBank:Play2d("page_flip")


    if g_pad and g_PadActive == 1 then
        g_pad:Reserve(PAD_OVERRIDE_START, OSK_CONFIRM_ACTION)
    end
end

function CloseCustomOSK(callCallback)
    if callCallback and g_CustomOSKText ~= "" and g_CustomOSKCallback then
        g_CustomOSKCallback()
    end


    if g_pad and g_PadActive == 1 then
        g_pad:UnReserveAll()
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
    end

    g_CustomOSKActive = false
    g_CustomOSKSelectedButton = 1
    g_CustomOSKText = ""
    g_CustomOSKCallback = nil
    g_CustomOSKTitleKey = nil
    g_ShiftActive = false
    g_ShiftLock = false
    g_CharSet = 0
    g_LastShiftPressTime = 0
    gSoundBank:Play2d("cancel_back")
end

function ToggleCharSet()
    g_CharSet = (g_CharSet + 1) % 8
    g_ShiftActive = (g_CharSet == 1)
    g_ShiftLock = (g_CharSet == 1)
    local charSetNames = {
        [0] = "lowercase",
        [1] = "uppercase",
        [2] = "circled lowercase",
        [3] = "circled uppercase",
        [4] = "localized",
        [5] = "symbols",
        [6] = "arrows_symbols",
        [7] = "repear"
    }
    print("[#4ThePlayers] Toggled character set to: " .. charSetNames[g_CharSet])
    gSoundBank:Play2d("page_flip")
end

function UIRenderCustomOSK()
    local renderer = g_Renderer
    if g_CustomOSKActive then
        local popupWidth = 700
        local popupHeight = 308
        local popupX = (1280 - popupWidth) / 2
        local popupY = (720 - popupHeight) / 2
        local popupBgColor = Vector4.Create(0.1, 0.1, 0.1, 0.95)
        local popupBorderColor = Vector4.Create(0.0, 0.0, 0.0, 0.95)
        local colGreyBorder = Vector4.Create(0.1, 0.1, 0.1, 1.0)
        local colLegend = Vector4.Create(1.0, 1.0, 1.0, 0.70)
        local textColor = Vector4.Create(1.0, 1.0, 1.0, 1.0)
        local buttonBgColor = Vector4.Create(0.0, 0.0, 0.0, 0.9)
        local buttonHighlightBorderColor = Vector4.Create(0.0, 0.5, 0.0, 1.0)


        local dimOverlayColor = Vector4.Create(0.0, 0.0, 0.0, 0.65)
        renderer:DrawRect2d(0, 0, 1280, 720, dimOverlayColor)


        renderer:DrawRect2d(
            popupX, popupY,
            popupX + popupWidth, popupY + popupHeight,
            popupBgColor
        )


        local borderThickness = 2
        renderer:DrawRect2d(
            popupX - borderThickness, popupY - borderThickness,
            popupX + popupWidth + borderThickness, popupY + popupHeight + borderThickness,
            popupBorderColor
        )


        local greyBorderThickness = 1
        renderer:DrawRect2d(
            popupX - borderThickness - greyBorderThickness, popupY - borderThickness - greyBorderThickness,
            popupX + popupWidth + borderThickness + greyBorderThickness, popupY + popupHeight + borderThickness + greyBorderThickness,
            colGreyBorder
        )


        renderer:SetFontScale(0.8, -0.8)
        local titleText = g_Me:GetLocalizedText(g_CustomOSKTitleKey)
        local titlePos = Vector4.Create(popupX + 22, popupY + 11, 0)
        renderer:DrawText2d(titlePos, titleText, textColor)


        renderer:SetFontScale(1.1, -1.1)
        local textAreaWidth = 656
        local textAreaHeight = 33
        local textAreaX = popupX + 22
        local textAreaY = popupY + 44
        renderer:DrawRect2d(
            textAreaX, textAreaY,
            textAreaX + textAreaWidth, textAreaY + textAreaHeight,
            Vector4.Create(1.0, 1.0, 1.0, 0.1)
        )
        local textPos = Vector4.Create(textAreaX + 11, textAreaY + 5.5, 0)
        local displayText = g_CustomOSKText ~= "" and g_CustomOSKText or g_Me:GetLocalizedText("kTypeHere")
        renderer:DrawText2d(textPos, displayText, textColor)


        local buttonWidth = 55
        local buttonHeight = 28
        local buttonSpacing = 4.4
        local startX = popupX + 22
        local startY = popupY + 88
        local buttonsPerRow = {11, 11, 11, 11, 5}
        local maxButtons = #g_KeyboardButtons


        local rowWidth = 11 * buttonWidth + 10 * buttonSpacing
        local spaceButtonWidth = rowWidth - 4 * buttonWidth - 4 * buttonSpacing

        for i = 1, maxButtons do
            local button = g_KeyboardButtons[i]
            local row = 0
            local col = 0
            local buttonCount = 0
            for r = 1, #buttonsPerRow do
                if buttonCount + buttonsPerRow[r] >= i then
                    row = r - 1
                    col = i - buttonCount - 1
                    break
                end
                buttonCount = buttonCount + buttonsPerRow[r]
            end

            local buttonX
            if row < 4 then
                buttonX = startX + col * (buttonWidth + buttonSpacing)
            else
                if col == 0 then
                    buttonX = startX
                elseif col == 1 then
                    buttonX = startX + buttonWidth + buttonSpacing
                elseif col == 2 then
                    buttonX = startX + buttonWidth + spaceButtonWidth + 2 * buttonSpacing
                elseif col == 3 then
                    buttonX = startX + 2 * buttonWidth + spaceButtonWidth + 3 * buttonSpacing
                else
                    buttonX = startX + 3 * buttonWidth + spaceButtonWidth + 4 * buttonSpacing
                end
            end
            local buttonY = startY + row * (buttonHeight + buttonSpacing)
            local currentButtonWidth = (row == 4 and col == 1) and spaceButtonWidth or buttonWidth
            local currentButtonHeight = buttonHeight
            local offset = 0
            local fontScaleX = 1.0
            local fontScaleY = -1.0


            if i == g_CustomOSKSelectedButton then
                offset = 1
                currentButtonWidth = currentButtonWidth + 2
                currentButtonHeight = currentButtonHeight + 2
                buttonX = buttonX - 1
                buttonY = buttonY - 1
                fontScaleX = 1.3
                fontScaleY = -1.3
            end


            renderer:DrawRect2d(
                buttonX, buttonY,
                buttonX + currentButtonWidth, buttonY + currentButtonHeight,
                buttonBgColor
            )


            if i == g_CustomOSKSelectedButton then
                local borderThickness = 1

                renderer:DrawRect2d(
                    buttonX - borderThickness, buttonY - borderThickness,
                    buttonX + currentButtonWidth + borderThickness, buttonY,
                    buttonHighlightBorderColor
                )
                renderer:DrawRect2d(
                    buttonX - borderThickness, buttonY + currentButtonHeight,
                    buttonX + currentButtonWidth + borderThickness, buttonY + currentButtonHeight + borderThickness,
                    buttonHighlightBorderColor
                )
                renderer:DrawRect2d(
                    buttonX - borderThickness, buttonY,
                    buttonX, buttonY + currentButtonHeight,
                    buttonHighlightBorderColor
                )
                renderer:DrawRect2d(
                    buttonX + currentButtonWidth, buttonY,
                    buttonX + currentButtonWidth + borderThickness, buttonY + currentButtonHeight,
                    buttonHighlightBorderColor
                )
            end


            renderer:SetFontHorzAlignment("center")
            renderer:SetFontScale(fontScaleX, fontScaleY)
            local displayLabel
            if button.localisedText then
                displayLabel = g_Me:GetLocalizedText(button.localisedText)
            elseif g_CharSet == 0 then
                displayLabel = button.label
            elseif g_CharSet == 1 then
                displayLabel = button.shift_label or button.label
            elseif g_CharSet == 2 then
                displayLabel = button.circled_lower_label or button.label
            elseif g_CharSet == 3 then
                displayLabel = button.circled_upper_label or button.label
            elseif g_CharSet == 4 then
                displayLabel = button.localized_label and g_Me:GetLocalizedText(button.localized_label) or button.label
            elseif g_CharSet == 5 then
                displayLabel = button.symbols_label or button.label
            elseif g_CharSet == 6 then
                displayLabel = button.arrows_symbols_label or button.label
            else
                displayLabel = button.repear_label or button.label
            end
            local textPos = Vector4.Create(buttonX + currentButtonWidth / 2, buttonY + 6, 0)
            renderer:DrawText2d(textPos, displayLabel, textColor)
            renderer:SetFontHorzAlignment("left")
        end


        renderer:SetFontScale(0.66, -0.66)
        local legendY = popupY + popupHeight - 19
        local startX = popupX + 120

        renderer:SetFontHorzAlignment("right")
        local legends = {
            { text = "kBackspace", spacing = 80 },
            { text = "kSpacebar", spacing = 120 },
            { text = "kToggleSet", spacing = 80 },
            { text = "kSelect", spacing = 70 },
            { text = "kEnterButton", spacing = 70 },
            { text = "kClose", spacing = 70 }
        }

        local currentX = startX
        for i, legend in ipairs(legends) do
            legend.x = currentX
            currentX = currentX + legend.spacing
        end

        for _, legend in ipairs(legends) do
            renderer:DrawText2d(
                Vector4.Create(legend.x, legendY, 0),
                g_Me:GetLocalizedText(legend.text),
                colLegend
            )
        end
        renderer:SetFontHorzAlignment("left")
    end
end


local buttonHoldStates = {
    [NAV_DPAD_RIGHT] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [NAV_DPAD_LEFT] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [DPAD_UP] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [DPAD_DOWN] = { isHolding = false, holdTime = 0, repeatTime = 0 },
    [OPTIONS] = { isHolding = false, holdTime = 0, repeatTime = 0 }
}
local HOLD_THRESHOLD = 0.4
local REPEAT_INTERVAL = 0.1


local function PerformOSKNavigation(direction)
    local buttonsPerRow = {11, 11, 11, 11, 5}
    local totalButtons = #g_KeyboardButtons
    local currentRow, currentCol, buttonCount = 0, 0, 0
    for i = 1, #buttonsPerRow do
        if buttonCount + buttonsPerRow[i] >= g_CustomOSKSelectedButton then
            currentRow = i - 1
            currentCol = g_CustomOSKSelectedButton - buttonCount - 1
            break
        end
        buttonCount = buttonCount + buttonsPerRow[i]
    end

    if direction == "right" then
        local newCol = currentCol + 1
        if newCol < buttonsPerRow[currentRow + 1] then
            g_CustomOSKSelectedButton = g_CustomOSKSelectedButton + 1
        else
            g_CustomOSKSelectedButton = buttonCount + 1
        end
        gSoundBank:Play2d("page_flip")
        print("[#4ThePlayers] Custom OSK selected button (right): " .. g_CustomOSKSelectedButton)
    elseif direction == "left" then
        local newCol = currentCol - 1
        if newCol >= 0 then
            g_CustomOSKSelectedButton = g_CustomOSKSelectedButton - 1
        else
            g_CustomOSKSelectedButton = buttonCount + buttonsPerRow[currentRow + 1]
        end
        gSoundBank:Play2d("page_flip")
        print("[#4ThePlayers] Custom OSK selected button (left): " .. g_CustomOSKSelectedButton)
    elseif direction == "up" then
        if currentRow > 0 then
            local targetRow = currentRow - 1
            local targetRowButtons = buttonsPerRow[targetRow + 1]
            local targetCol = math.min(currentCol, targetRowButtons - 1)
            local targetButtonCount = 0
            for i = 1, targetRow do
                targetButtonCount = targetButtonCount + buttonsPerRow[i]
            end
            g_CustomOSKSelectedButton = targetButtonCount + targetCol + 1
            gSoundBank:Play2d("page_flip")
            print("[#4ThePlayers] Custom OSK selected button (up): " .. g_CustomOSKSelectedButton)
        else
            gSoundBank:Play2d("cancel_back")
            print("[#4ThePlayers] Cannot move up: at top row")
        end
    elseif direction == "down" then
        if currentRow < 4 then
            local targetRow = currentRow + 1
            local targetRowButtons = buttonsPerRow[targetRow + 1]
            local targetCol
            if currentRow == 3 and currentCol >= 1 and currentCol <= 7 then
                targetRow = 4
                targetCol = 1
                local targetButtonCount = 0
                for i = 1, targetRow do
                    targetButtonCount = targetButtonCount + buttonsPerRow[i]
                end
                g_CustomOSKSelectedButton = targetButtonCount + targetCol + 1
            else
                targetCol = math.min(currentCol, targetRowButtons - 1)
                local targetButtonCount = 0
                for i = 1, targetRow do
                    targetButtonCount = targetButtonCount + buttonsPerRow[i]
                end
                g_CustomOSKSelectedButton = targetButtonCount + targetCol + 1
            end
            gSoundBank:Play2d("page_flip")
            print("[#4ThePlayers] Custom OSK selected button (down): " .. g_CustomOSKSelectedButton)
        else
            gSoundBank:Play2d("cancel_back")
            print("[#4ThePlayers] Cannot move down: at bottom row")
        end
    end
end


local function DeleteCharacter()
    g_CustomOSKText = removeLastUTF8Char(g_CustomOSKText)
    if not g_ShiftLock then
        g_ShiftActive = false
        if g_CharSet == 1 then g_CharSet = 0 end
    end
    gSoundBank:Play2d("page_flip")
end

function HandleCustomOSKInput()
    if not g_CustomOSKActive or not g_pad then
        return
    end

    for button, state in pairs(buttonHoldStates) do
        if g_pad:WasJustPressed(button) then
            state.isHolding = true
            state.holdTime = 0
            state.repeatTime = 0
            if button == OPTIONS then
                DeleteCharacter()
            end
        elseif g_pad:WasJustReleased(button) then
            state.isHolding = false
            state.holdTime = 0
            state.repeatTime = 0
        elseif state.isHolding and g_pad:IsHeld(button) then
            state.holdTime = state.holdTime + GetDeltaTime()
            if state.holdTime >= HOLD_THRESHOLD then
                state.repeatTime = state.repeatTime + GetDeltaTime()
                if state.repeatTime >= REPEAT_INTERVAL then
                    state.repeatTime = state.repeatTime - REPEAT_INTERVAL
                    if button == NAV_DPAD_RIGHT then
                        PerformOSKNavigation("right")
                    elseif button == NAV_DPAD_LEFT then
                        PerformOSKNavigation("left")
                    elseif button == DPAD_UP then
                        PerformOSKNavigation("up")
                    elseif button == DPAD_DOWN then
                        PerformOSKNavigation("down")
                    elseif button == OPTIONS then
                        DeleteCharacter()
                    end
                end
            end
        end
    end

    if g_pad:WasJustPressed(PAD_OVERRIDE_START) then
        CloseCustomOSK(true)
        return
    elseif g_pad:WasJustPressed(NAV_DPAD_RIGHT) then
        PerformOSKNavigation("right")
    elseif g_pad:WasJustPressed(NAV_DPAD_LEFT) then
        PerformOSKNavigation("left")
    elseif g_pad:WasJustPressed(DPAD_UP) then
        PerformOSKNavigation("up")
    elseif g_pad:WasJustPressed(DPAD_DOWN) then
        PerformOSKNavigation("down")
    elseif g_pad:WasJustPressed(NEXT_PAGE_R2) then
        ToggleCharSet()
    elseif g_pad:WasJustPressed(QUICKMENU) then
        if #g_CustomOSKText < g_MaxInputLength then
            g_CustomOSKText = g_CustomOSKText .. " "
            if not g_ShiftLock then
                g_ShiftActive = false
                if g_CharSet == 1 then g_CharSet = 0 end
            end
            gSoundBank:Play2d("page_flip")
        else
            gSoundBank:Play2d("cancel_back")
        end
    elseif (g_pad:WasJustPressed(SELECT) or g_pad:WasJustPressed(ACCEPT)) and not g_pad:WasJustPressed(PAD_OVERRIDE_START) then
        local button = g_KeyboardButtons[g_CustomOSKSelectedButton]
        if button.action == "shift" then
            local currentTime = GetInstanceTime()
            if g_ShiftLock then
                g_ShiftLock = false
                g_ShiftActive = false
                g_CharSet = 0
                g_LastShiftPressTime = 0
            elseif currentTime - g_LastShiftPressTime < g_ShiftDoublePressThreshold then
                g_ShiftLock = true
                g_ShiftActive = true
                g_CharSet = 1
                g_LastShiftPressTime = 0
            else
                g_ShiftActive = true
                g_CharSet = 1
                g_LastShiftPressTime = currentTime
            end
            gSoundBank:Play2d("page_flip")
        elseif button.action == "capslock" then
            g_ShiftLock = not g_ShiftLock
            g_ShiftActive = g_ShiftLock
            g_CharSet = g_ShiftLock and 1 or 0
            g_LastShiftPressTime = 0
            gSoundBank:Play2d("page_flip")
        elseif button.action == "toggle" then
            ToggleCharSet()
        elseif button.action == "backspace" then
            g_CustomOSKText = removeLastUTF8Char(g_CustomOSKText)
            if not g_ShiftLock then
                g_ShiftActive = false
                if g_CharSet == 1 then g_CharSet = 0 end
            end
            gSoundBank:Play2d("page_flip")
        elseif button.action == "space" then
            if #g_CustomOSKText < g_MaxInputLength then
                g_CustomOSKText = g_CustomOSKText .. " "
                if not g_ShiftLock then
                    g_ShiftActive = false
                    if g_CharSet == 1 then g_CharSet = 0 end
                end
                gSoundBank:Play2d("page_flip")
            else
                gSoundBank:Play2d("cancel_back")
            end
        elseif button.action == "enter" then
            CloseCustomOSK(true)
            return
        elseif button.action == "clear" then
            g_CustomOSKText = ""
            if not g_ShiftLock then
                g_ShiftActive = false
                if g_CharSet == 1 then g_CharSet = 0 end
            end
            gSoundBank:Play2d("page_flip")
        else
            if #g_CustomOSKText < g_MaxInputLength then
                local char
                if g_CharSet == 0 then
                    char = button.action
                elseif g_CharSet == 1 then
                    char = button.shift_action or button.action
                elseif g_CharSet == 2 then
                    char = button.circled_lower_action or button.action
                elseif g_CharSet == 3 then
                    char = button.circled_upper_action or button.action
                elseif g_CharSet == 4 then
                    char = button.localized_action and g_Me:GetLocalizedText(button.localized_action) or button.action
                elseif g_CharSet == 5 then
                    char = button.symbols_action or button.action
                elseif g_CharSet == 6 then
                    char = button.arrows_symbols_action or button.action
                else
                    char = button.repear_action or button.action
                end
                if char and char ~= "" then
                    g_CustomOSKText = g_CustomOSKText .. char
                    if not g_ShiftLock then
                        g_ShiftActive = false
                        if g_CharSet == 1 then g_CharSet = 0 end
                    end
                    gSoundBank:Play2d("page_flip")
                else
                    gSoundBank:Play2d("cancel_back")
                end
            else
                gSoundBank:Play2d("cancel_back")
            end
        end
    elseif g_pad:WasJustPressed(BACK) then
        CloseCustomOSK(false)
    end
end