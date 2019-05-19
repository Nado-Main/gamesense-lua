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

local data = {
    var_cached = nil,
    minimum_damage = ui.reference("RAGE", "Aimbot", "Minimum damage"),

    is_active = ui.new_checkbox("RAGE", "Other", "Override minimum damage"),
    override_key = ui.new_hotkey("RAGE", "Other", "\n damage_override_key", true),
    damage_value = ui.new_slider("RAGE", "Other", "\n damage_override_value", 0, 126, 55, true, "", 1, set_dmg_list())
}

data.set_visible = function(_self)
    if not _self then
        ui.set_callback(data.is_active, data.set_visible)
    end

    ui.set_visible(data.damage_value, ui.get(data.is_active))
end

data.callback = function()
    data.var_cached = data.var_cached ~= nil and data.var_cached or ui.get(data.minimum_damage)

    if ui.get(data.is_active) and ui.get(data.override_key) then
        ui.set(data.minimum_damage, ui.get(data.damage_value))
        renderer.indicator(255, 255, 255, 150, "DMG")
    else
        if data.var_cached ~= nil then
            ui.set(data.minimum_damage, data.var_cached)
            data.var_cached = nil
        end
    end
end

data.set_visible()
client.set_event_callback("paint", data.callback)
