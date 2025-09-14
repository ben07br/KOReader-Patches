local BlitBuffer = require("ffi/blitbuffer")
local ButtonDialog = require("ui/widget/buttondialog")
local Device = require("device")
local UIManager = require("ui/uimanager")
local util = require("util")
local _ = require("gettext")
local Screen = require("device").screen
local ReaderBookmark = require("apps/reader/modules/readerbookmark")
local ReaderHighlight = require("apps/reader/modules/readerhighlight")
local RadioButtonWidget = require("ui/widget/radiobuttonwidget")
local T = require("ffi/util").template

function ReaderBookmark:filterByEditedText()
    local item_table = {}
    for i, v in ipairs(self.ui.annotation.annotations) do
        local item = util.tableDeepCopy(v)
        item.text_orig = item.text or ""
        item.type = self.getBookmarkType(item)

        if item.text_edited then
            item.text = self:getBookmarkItemText(item)
            table.insert(item_table, item)
        end
    end
    self.show_color_only = nil
    self.show_drawer_only = nil
    self.show_edited_only = true
    self:updateBookmarkList(item_table)
end

function ReaderBookmark:filterByHighlightStyle()
    local filter_by_drawer_callback = function(drawer)
        local item_table = {}
        for i, v in ipairs(self.ui.annotation.annotations) do
            local item = util.tableDeepCopy(v)
            item.text_orig = item.text or ""
            item.type = self.getBookmarkType(item)
            if item.type == "highlight" and item.drawer == drawer then
                item.text = self:getBookmarkItemText(item)
                table.insert(item_table, item)
            end
        end
        self.show_edited_only = nil
        self.show_color_only = nil
        self.show_drawer_only = drawer
        self:updateBookmarkList(item_table)
    end

    self.ui.highlight:showHighlightStyleDialog(filter_by_drawer_callback)
end

function ReaderBookmark:filterByHighlightColor()
    local filter_callback = function(color)
        local item_table = {}

        -- iterate over all annotations, not just the current visible table
        for i, v in ipairs(self.ui.annotation.annotations) do
            local item = util.tableDeepCopy(v)
            item.text_orig = item.text or ""
            item.type = self.getBookmarkType(item)

            if item.color == color then
            -- if item.type == "highlight" and item.color == color then
                item.text = self:getBookmarkItemText(item)
                table.insert(item_table, item)
            end
        end
        self.show_edited_only = nil
        self.show_drawer_only = nil
        self.show_color_only = color
        self:updateBookmarkList(item_table)
    end

    self.ui.highlight:showHighlightColorFilterDialog(filter_callback)
end

function ReaderBookmark:filterByColorAndStyle(drawer, color)
    local item_table = {}

    for _, v in ipairs(self.ui.annotation.annotations) do
        local item = util.tableDeepCopy(v)
        item.text_orig = item.text or ""
        item.type = self.getBookmarkType(item)

        -- Only include highlights that match both filters (if set)
        if item.type == "highlight" and
           (not drawer or item.drawer == drawer) and
           (not color or item.color == color) then
            item.text = self:getBookmarkItemText(item)
            table.insert(item_table, item)
        end
    end

    -- store current active filters
    self.show_drawer_only = drawer
    self.show_color_only = color
    self.show_edited_only = nil  -- if you want edited text separate, can add later

    self:updateBookmarkList(item_table)
end

function ReaderHighlight:showHighlightColorFilterDialog(caller_callback)
    local radio_buttons = {}
    for _, v in ipairs(self.ui.highlight.highlight_colors) do
        table.insert(radio_buttons, {
            {
                text = v[1],  -- name of the color, e.g., "Yellow"
                bgcolor = BlitBuffer.colorFromName(v[2])  -- convert color name to display color
                       or BlitBuffer.Color8(0xFF, 0xFF, 0xFF), -- fallback to white
                provider = v[2], 
            },
        })
    end

    UIManager:show(RadioButtonWidget:new{
        title_text = _("Filter by highlight color"),
        width_factor = 0.5,
        radio_buttons = radio_buttons,
        callback = function(radio)
            caller_callback(radio.provider)
        end,
        colorful = true,
        dithered = true,
    })
end


function ReaderHighlight:getHighlightColorString(color) -- for bookmark list
    local highlight_colors = self.ui.highlight and self.ui.highlight.highlight_colors or {}
    for _, v in ipairs(highlight_colors) do
        if v[2] == color then
            return v[1]
        end
    end
    return color
end

function ReaderBookmark:updateBookmarkList(item_table, item_number)
    local bm_menu = self.bookmark_menu[1]

    local title
    if item_table then
        title = T(_("Bookmarks (%1)"), #item_table)
    end

    local subtitle
    if bm_menu.select_count then
        subtitle = T(_("Selected: %1"), bm_menu.select_count)
    else
        if self.show_edited_only then
            subtitle = _("Filter: edited highlighted text")
        elseif self.show_drawer_only and not self.show_color_only then 
            subtitle = _("Highlight style:") .. " " .. self.ui.highlight:getHighlightStyleString(self.show_drawer_only):lower()
        elseif self.show_color_only and not self.show_drawer_only then
            subtitle = _("Highlight color:") .. " " .. self.ui.highlight:getHighlightColorString(self.show_color_only):lower()-------------editd this
        elseif self.show_drawer_only and self.show_color_only then
            subtitle = _("Highlight:") .. " " .. self.ui.highlight:getHighlightColorString(self.show_color_only):lower()
                    .. " | "
                    .. self.ui.highlight:getHighlightStyleString(self.show_drawer_only):lower()
        elseif self.match_table then
            if self.match_table.search_str then
                subtitle = T(_("Query: %1"), self.match_table.search_str)
            else
                local types = {}
                for type, type_string in pairs(self.display_type) do
                    if self.match_table[type] then
                        table.insert(types, type_string)
                    end
                end
                table.sort(types)
                subtitle = #types > 0 and _("Bookmark type:") .. " " .. table.concat(types, ", ")
            end
        else
            subtitle = ""
        end
    end

    bm_menu:switchItemTable(title, item_table, item_number, nil, subtitle)
end
