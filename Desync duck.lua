local get_local = entity.get_local_player
local menu = {
    cache = nil,
    is_active = ui.new_checkbox("AA", "Other", "Desync duck"),
    hotkey = ui.new_hotkey("AA", "Other", "Desync duck hotkey", true),

    airduck = ui.reference("MISC", "Miscellaneous", "Air duck"),
    flag_limit = ui.reference("aa", "Fake lag", "Limit")
}

local function get_flags()
    local flags = entity.get_prop(get_local(), "m_fFlags")
    local on_ground, in_duck = 
        bit.band(flags, 1) == 1,
        bit.band(flags, 2) == 2

    return on_ground, in_duck
end

client.set_event_callback("paint", function()
    state = -1 -- Unknown

    if ui.get(menu.is_active) and ui.get(menu.hotkey) then
        local on_ground, in_duck = get_flags()
        if on_ground and not in_duck then -- 0: Standing | 1: Running
            local x, y = entity.get_prop(get_local(), "m_vecVelocity")
            local velocity = math.floor(math.min(10000, math.sqrt(x^2 + y^2) + 0.5))

            state = (velocity > 1.0 and 1 or 0)
        end

        if on_ground == false then state = 2 end -- Jumping
        if on_ground and in_duck then state = 3 end -- Crouching
    end

    if menu.cache == nil then
        menu["cache"] = ui.get(menu.flag_limit)
    end

    if state == 2 then -- Jump state check
        ui.set(menu.flag_limit, 15)
        ui.set(menu.airduck, "On")
    else
        ui.set(menu.airduck, "Off")
        if menu.cache ~= nil then
            ui.set(menu.flag_limit, menu.cache)
            menu["cache"] = nil
        end
    end
end)