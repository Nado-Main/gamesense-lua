local active = ui.new_checkbox("AA", "Anti-aimbot angles", "Fake angles")
local inverse_key = ui.new_hotkey("AA", "Anti-aimbot angles", "Lean yaw inverse", true)
local body_lean = ui.new_slider("AA", "Anti-aimbot angles", "Body lean", 0, 100, 55, true, "%")

local yaw, yaw_num = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local yaw_jitter, yaw_jitter_num = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")
local body, body_num = ui.reference("AA", "Anti-aimbot angles", "Body yaw")
local limit = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit")
local LBY = ui.reference("AA", "Anti-aimbot angles", "Lower body yaw")

local flag_active = ui.reference("AA", "Fake lag", "Enabled")
local flag_triggers = ui.reference("AA", "Fake lag", "Customize triggers")
local flag_limit = ui.reference("AA", "Fake lag", "Limit")

local ui_get, ui_set = ui.get, ui.set

local function ui_mset(list)
    for ref, val in pairs(list) do
        ui_set(ref, val)
    end
end

local function _callback(itself)
    local itself = ui_get(itself)

    ui.set_visible(body_lean, itself)

    ui.set_visible(yaw, not itself)
    ui.set_visible(yaw_num, not itself and ui_get(yaw) ~= "Off")
    ui.set_visible(yaw_jitter, not itself)
    ui.set_visible(yaw_jitter_num, not itself and ui_get(yaw_jitter) ~= "Off")
    ui.set_visible(body, not itself)
    ui.set_visible(body_num, not itself and ui_get(body_num) ~= "Off")
    ui.set_visible(limit, not itself)
    ui.set_visible(LBY, not itself)
end

local function get_velocity_data()
    local x, y, z = entity.get_prop(entity.get_local_player(), "m_vecVelocity")

    return math.sqrt(x^2 + y^2), (z^2 > 0)
end

client.set_event_callback("setup_command", function(cmd)
    local cmd_active, inversed = 
        ui_get(active),
        ui_get(inverse_key)
        ui_set(inverse_key, "Toggle")

    local flSpeed, in_air = get_velocity_data()
    local lean = 59 - (0.59 * ui_get(body_lean))

    if not cmd_active or in_air then return else
        _callback(active)
    end

    ui_mset({
        [yaw] = '180',
        [yaw_jitter] = 'Off',
        [body] = 'Static',
        [limit] = 60,
        [LBY] = false,
    
        -- Body lean
        [yaw_num] = inversed and -lean or lean,
        [body_num] = inversed and -180 or 180
    })

    local cmd_speed = cmd.in_duck ~= 0 and 2.941177 or 1.000001
	local sidemove = cmd.command_number % 4 < 2 and -cmd_speed or cmd_speed
	cmd.sidemove = cmd.sidemove ~= 0 and cmd.sidemove or sidemove
end)

_callback(active)
ui.set_callback(active, _callback)
