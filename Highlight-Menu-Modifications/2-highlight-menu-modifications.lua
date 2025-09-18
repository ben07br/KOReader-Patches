local ReaderHighlight = require("apps/reader/modules/readerhighlight")
local _ = require("gettext")
local C_ = _.pgettext
local UIManager = require("ui/uimanager")
local util = require("util")
local Event = require("ui/event")
local Notification = require("ui/widget/notification")
local logger = require("logger")
local Device = require("device")
local Screen = require("device").screen


-- Store the original function to call it later if needed
local orig_init = ReaderHighlight.init

local ICON_SIZE = 20

function ReaderHighlight:init()
    orig_init(self)
    
    --- rearrange these as you like
	-- "item" structure like explained in "01_select"
    self._highlight_buttons = {
			--- start of button
        ["01_highlight"] = function(this, index) 			-- ["name for button"]=buttons get selected based on numerical order. If you change one, renumber all buttons
            return {
                icon = _("red"), -- the text that will show on the button
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE),
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","red", index)		-- the stuff it does
                    this:onClose()
                end,
            }
        end,
            --- end of button
        
        ["02_highlight"] = function(this, index)
            return {
                icon = _("orange"), --- put icon in resources/icons/mdlight
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE),
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","orange", index)
                    this:onClose()
                end,
            }
        end,
        ["03_highlight"] = function(this, index)
            return {
                icon = _("yellow"),
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE),
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","yellow", index)
                    this:onClose()
                end,
            }
        end,
        ["04_highlight"] = function(this, index)
            return {
                icon = _("green"), 
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE),  
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","green", index)
                    this:onClose()
                end,
            }
        end,
        ["05_highlight"] = function(this, index)
            return {
                icon = _("olive"), 
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE),  
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","olive", index)
                    this:onClose()
                end,
            }
        end,
        ["06_highlight"] = function(this, index)
            return {
                icon = _("cyan"),
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE),
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","cyan", index)
                    this:onClose()
                end,
            }
        end,
    
        ["07_highlight"] = function(this, index)
            return {
                icon = _("blue"),
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE),
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","blue", index)
                    this:onClose()
                end,
            }
        end,
        
        ["08_highlight"] = function(this, index)
            return {
                icon = _("purple"),
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE),
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","purple", index)
                    this:onClose()
                end,
            }
        end,
        ["09_highlight"] = function(this, index)
            return {
                icon = _("pink"),
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE), 
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","pink", index)
                    this:onClose()
                end,
            }
        end,
        ["10_highlight"] = function(this, index)
            return {
                icon = _("gray"),
                icon_width = Screen:scaleBySize(ICON_SIZE),
                icon_height = Screen:scaleBySize(ICON_SIZE),     
                callback = function()
                    this:saveHighlightFormatted(true,"lighten","gray", index)
                    this:onClose()
                end,
            }
        end,
        ["11_select"] = function(this, index)
            return {
                text = index and _("Extend") or _("Select"),
                font_size = 14,
                enabled = not (index and this.ui.annotation.annotations[index].text_edited),
                callback = function()
                    this:startSelection(index)
                    this:onClose()
                    if not Device:isTouchDevice() then
                        self:onStartHighlightIndicator()
                    end
                end,
            }
        end,
        ["12_copy"] = function(this)
            return {
                text = C_("Text", "Copy"),
                font_size = 14,
                enabled = Device:hasClipboard(),
                callback = function()
                    Device.input.setClipboardText(util.cleanupSelectedText(this.selected_text.text))
                    this:onClose()
                    UIManager:show(Notification:new{
                        text = _("Selection copied to clipboard."),
                    })
                end,
            }
        end,
        ["13_add_note"] = function(this, index)     --editting note from this screen would create new note instead of edit, 
            return {                                --so implemented a check using index to see if the note alr exists then will edit
                text = _("Note"),
                font_size = 14,
                callback = function()
                    this:addNote(nil, index)
                    this:onClose()
                end,
            }
        end,
        ["14_dictionary"] = function(this, index)
            return {
                text = _("Dictionary"),
                font_size = 14,
                callback = function()
                    this:lookupDict(index)
                end,
            }
        end,
        ["15_wikipedia"] = function(this)
            return {
                text = _("Wikipedia"),
                font_size = 14,
                callback = function()
                    UIManager:scheduleIn(0.1, function()
                        this:lookupWikipedia()
                    end)
                end,
            }
        end,
        ["16_translate"] = function(this, index)
            return {
                text = _("Translate"),
                font_size = 14,
                callback = function()
                    this:translate(index)
                end,
            }
        end,
        ["17_search"] = function(this)
            return {
                text = _("Search"),
                font_size = 14,
                callback = function()
                    this:onHighlightSearch()
                end,
            }
        end,
	}
end

function ReaderHighlight:saveHighlightFormatted(extend_to_sentence,hlStyle,hlColor, index) --take in index too to check later
    local item = self.ui.annotation.annotations[index]
    logger.dbg("save highlight")
    if self.hold_pos and not self.selected_text then
        self:highlightFromHoldPos()
    end
    if self.selected_text and self.selected_text.pos0 and self.selected_text.pos1 then
        local pg_or_xp
        if self.ui.rolling then
            if extend_to_sentence then
                local extended_text = self.ui.document:extendXPointersToSentenceSegment(self.selected_text.pos0, self.selected_text.pos1)
                if extended_text then
                    self.selected_text = extended_text
                end
            end
            pg_or_xp = self.selected_text.pos0
        else
            pg_or_xp = self.selected_text.pos0.page
        end
        if index then  --if index exists
            local item = self.ui.annotation.annotations[index]
            self:writePdfAnnotation("delete", item) -- if old exists, delete old highlight
            item.color = hlColor                    -- apply new color
            item.drawer = hlStyle                   -- apply new style  (bc before didnt allow color changing from same menu)
            if self.ui.paging then
                self:writePdfAnnotation("save", item)
                if item.note then
                    self:writePdfAnnotation("content", item, item.note)
                end
            end
            UIManager:setDirty(self.dialog, "ui")
            self.ui:handleEvent(Event:new("AnnotationsModified", { item }))
            return index
        end
        local item = {
            page = self.ui.paging and self.selected_text.pos0.page or self.selected_text.pos0,
            pos0 = self.selected_text.pos0,
            pos1 = self.selected_text.pos1,
            text = util.cleanupSelectedText(self.selected_text.text),
            drawer = hlStyle, -- choose drawer style (e.g. underline/lighten) instead of using self.view.highlight.saved_drawer
            color = hlColor, -- choose color instead of using self.view.highlight.saved_color
			chapter = table.concat(self.ui.toc:getFullTocTitleByPage(pg_or_xp), " ▸ "), --- comment this out to get original chapter name text
            --chapter = self.ui.toc:getTocTitleByPage(pg_or_xp), -- uncomment this to get original chapter name text
        }
        if self.ui.paging then
            item.pboxes = self.selected_text.pboxes
            item.ext = self.selected_text.ext
            self:writePdfAnnotation("save", item)
        end
        local new_index = self.ui.annotation:addItem(item)
        self.view.footer:maybeUpdateFooter()
        self.ui:handleEvent(Event:new("AnnotationsModified", { item, nb_highlights_added = 1, index_modified = index }))
        return new_index
    end
end

function ReaderHighlight:addNote(text, index)
    if index then
        -- Editing an existing highlight: update its note
        if text then
            self:clear()
        end
        self:editNote(index, false, text)
        return index
    else
        -- No existing index: create new highlight and attach note
        local new_index = self:saveHighlight(true)
        if text then
            self:clear()
        end
        self:editNote(new_index, true, text)
        return new_index
    end
end