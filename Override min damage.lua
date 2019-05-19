local var_cached = nil
local min_dmg_table = { [0] = "Auto" }

for i = 1, 26 do
    -- HP + {1-26}
    min_dmg_table[100 + i] = "HP+" .. i
end

local minimum_damage = ui.reference("RAGE", "Aimbot", "Minimum damage")

local is_active = ui.new_checkbox("RAGE", "Other", "Override minimum damage")
local override_key = ui.new_hotkey("RAGE", "Other", "\n damage_override_key", true)
local damage_value = ui.new_slider("RAGE", "Other", "\n damage_override_value", 0, 126, 55, true, "", 1, min_dmg_table)

local setup_visible = function(c)
    ui.set_visible(damage_value, ui.get(c))
end

client.set_event_callback("paint", function(c)
    var_cached = var_cached ~= nil and var_cached or ui.get(minimum_damage)

    if ui.get(is_active) and ui.get(override_key) then
        ui.set(minimum_damage, ui.get(damage_value))
        renderer.indicator(255, 255, 255, 150, "DMG")
    else
        if var_cached ~= nil then
            ui.set(minimum_damage, var_cached)
            var_cached = nil
        end
    end
end)

ui.set_callback(is_active, setup_visible)
setup_visible(is_active)
