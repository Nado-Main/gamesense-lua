local ui_get, ui_set = ui.get, ui.set
local selection = { "Can shoot", "Speed threshold", "In fire" }
local sm_selection = { "Default", "Auto duck", "Slow motion" }

local quickstop = ui.reference("RAGE", "Other", "Quick stop")
local quickstop_in_fire = ui.reference("RAGE", "Other", "Quick stop in fire")

local qs = ui.new_multiselect("RAGE", "Other", "Override quick stop", selection)
local qs_mode = ui.new_combobox("RAGE", "Other", "Quick stop mode", sm_selection)
local qs_speed_threshold = ui.new_slider("RAGE", "Other", "Quick stop speed threshold", 1, 100, 10, true, "u/")

local function conds(tab, val)
    for index, value in ipairs(ui_get(qs)) do
        if value == val then 
            return true
        end
    end

    return false
end

local function can_shoot()
    local lcal = entity.get_local_player()
    local weapon = entity.get_player_weapon(lcal)

	if not entity.is_alive(lcal) or weapon == nil then
		return nil
	end

    local m_nTickBase = entity.get_prop(lcal, "m_nTickBase")
    local m_flNextPrimaryAttack = entity.get_prop(weapon, "m_flNextPrimaryAttack")

    return (m_flNextPrimaryAttack <= m_nTickBase * globals.tickinterval())
end

local function get_quickstop()
    local matches = {
        [sm_selection[1]] = "On",
        [sm_selection[2]] = "On + duck",
        [sm_selection[3]] = "On + slow motion"
    }

    return matches[ui_get(qs_mode)]
end

local function is_ent_moving(ground_check, speed)
    local lcal = entity.get_local_player()
    local x, y, z = entity.get_prop(lcal, "m_vecVelocity")
    local f_check = math.sqrt(x*x + y*y + z*z) > speed

    return ground_check and (f_check and not math.sqrt(z^2)) or f_check
end

client.set_event_callback("setup_command", function()
    local stop_state = true
    local f_cont, s_cont, t_cont = 
        conds(qs, selection[1]), 
        conds(qs, selection[2]),
        conds(qs, selection[3])

    if f_cont or s_cont then
        ui_set(quickstop_in_fire, t_cont)
    end

    if s_cont then
        local threshold = ui_get(qs_speed_threshold)
        stop_state = is_ent_moving(false, threshold)
    end

	if f_cont then
		if (s_cont and stop_state) or not s_cont then
			stop_state = can_shoot()
        end
    else
        if not s_cont then
            return
        end
    end

	ui_set(quickstop, (stop_state and get_quickstop() or "Off"))
end)

local function visibility()
    local f_cont, s_cont = 
        conds(qs, selection[1]), 
        conds(qs, selection[2])

    -- Menu
    ui.set_visible(qs_mode, f_cont or s_cont)
    ui.set_visible(qs_speed_threshold, s_cont)
    ui.set_visible(quickstop, not (f_cont or s_cont))
end

visibility()
ui.set_callback(qs, visibility)