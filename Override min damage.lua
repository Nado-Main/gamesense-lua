local cache = nil
local set_dmg_list = function()
    local damage_list = { }

    damage_list[0] = "Auto"

    for i = 1, 26 do
        -- HP + {1-26}
        -- HP = 0 -> Auto
    
        damage_list[100 + i] = "HP+" .. i
    end

    return damage_list
end

local minimum_damage = ui.reference("RAGE", "Aimbot", "Minimum damage")
local is_active = ui.new_checkbox("RAGE", "Other", "Override minimum damage")
local override_key = ui.new_hotkey("RAGE", "Other", "\n damage_override_key", true)
local damage_value = ui.new_slider("RAGE", "Other", "\n damage_override_value", 0, 126, 55, true, "", 1, set_dmg_list())

local ui_get, ui_set, is_alive = ui.get, ui.set, entity.is_alive

local function set_visible()
    ui.set_visible(damage_value, ui_get(is_active))
end

set_visible()
ui.set_callback(is_active, set_visible)

client.set_event_callback("paint", function()
    local active = ui_get(is_active) and ui_get(override_key)
    local alive = is_alive(entity.get_local_player())

    cache = cache or ui_get(minimum_damage)

    if active and alive then
        ui_set(minimum_damage, ui_get(damage_value))
        renderer.indicator(255, 255, 255, 150, "DMG: " .. ui_get(minimum_damage))
    else
        if cache ~= nil then
            ui_set(minimum_damage, cache)
            cache = nil
        end
    end
end)
