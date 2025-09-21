local Dispatcher = require("dispatcher")
local UIManager = require("ui/uimanager")
local Event = require("ui/event")
local _ = require("gettext")

local old_addSubMenu = Dispatcher.addSubMenu

--global table for other patches to register buttons
_G._customPatchButtons = _G._customPatchButtons or {}


--global helper function for other patches
if not _G.registerCustomPatchButton then
    function _G.registerCustomPatchButton(id, title, callback, separator)
        table.insert(_G._customPatchButtons, {
            id = id,    --id for button, must be unique
            text = title, --text for button
            callback = callback, --function that the button calls when pressed
            separator = separator or false,
        })
    end
end

--override Dispatcher:addSubMenu
function Dispatcher:addSubMenu(caller, menu, location, settings)
    old_addSubMenu(self, caller, menu, location, settings) --adds original first

    -- if not _G._customPatchButtons or #_G._customPatchButtons == 0 then
    --     return
    -- end

    --places folder after "Reader"
    local insert_index = #menu + 1
    for i, item in ipairs(menu) do
        if item.text == _("Reader") then
            insert_index = i + 1
            break
        end
    end

    --custom patches folder
    local custom_patch_item = {
        text = _("Custom Patches"), --can rename if wanted
        checked_func = function()
            local loc = location[settings]
            for _, btn in ipairs(_G._customPatchButtons) do
                if loc and loc[btn.id] then return true end
            end
            return false
        end,
        sub_item_table = {},
    }

    --add each registered button
    for _, btn in ipairs(_G._customPatchButtons) do
        table.insert(custom_patch_item.sub_item_table, {
            text = btn.text,
            checked_func = function()
                return location[settings] and location[settings][btn.id]
            end,
            callback = function(touchmenu_instance)
                local value = not (location[settings] and location[settings][btn.id])
                if not location[settings] then location[settings] = {} end
                location[settings][btn.id] = value and true or nil

                if touchmenu_instance then
                    touchmenu_instance:updateItems()
                end

                -- actually update Dispatcher binding too
                local Dispatcher = require("dispatcher")
                if Dispatcher and Dispatcher.setActionEnabled then
                    Dispatcher:setActionEnabled(btn.id, value)
                end

                -- run registered behavior if enabling
                if value and btn.callback then
                    btn.callback()
                end
            end,
            separator = btn.separator -- this makes the separator line show
        })
    end

    -- Insert the folder into the menu
    table.insert(menu, insert_index, custom_patch_item)
end