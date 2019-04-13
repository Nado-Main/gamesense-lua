local min_dmg_table, cache = { [0] = "Auto" }, nil

for i = 1, 26 do
    -- HP + {1-26}
    min_dmg_table[100 + i] = "HP+" .. i
end

local mdmg_num = ui.new_slider("RAGE", "Other", "Override minimum damage", 0, 126, 55, true, "", 1, min_dmg_table)
local mdmg_key = ui.new_hotkey("RAGE", "Other", "Minimim damage hotkey")

local minimum_damage = ui.reference("RAGE", "Aimbot", "Minimum damage")
local ui_get, ui_set = ui.get, ui.set

client.set_event_callback("paint", function(c)
    cache = cache ~= nil and cache or ui_get(minimum_damage)

    if ui_get(mdmg_key) then
        ui_set(minimum_damage, ui_get(mdmg_num))
        renderer.indicator(255, 255, 255, 150, "DMG")
    else
        if cache ~= nil then
            ui_set(minimum_damage, cache)
            cache = nil
        end
    end
end)
