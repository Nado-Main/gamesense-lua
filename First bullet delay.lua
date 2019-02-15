local pistol_active = ui.new_checkbox("LEGIT", "Aimbot", "Pistol: First bullet delay")
local pistol_delay = ui.new_slider("LEGIT", "Aimbot", "Pistol: Reaction time", 1, 200, 100, true, "ms")

local smg_active = ui.new_checkbox("LEGIT", "Aimbot", "SMG: First bullet delay")
local smg_delay = ui.new_slider("LEGIT", "Aimbot", "SMG: Reaction time", 1, 200, 100, true, "ms")

local rifle_active = ui.new_checkbox("LEGIT", "Aimbot", "Rifle: First bullet delay")
local rifle_delay = ui.new_slider("LEGIT", "Aimbot", "Rifle: Reaction time", 1, 200, 100, true, "ms")

local shotgun_active = ui.new_checkbox("LEGIT", "Aimbot", "Shotgun: First bullet delay")
local shotgun_delay = ui.new_slider("LEGIT", "Aimbot", "Shotgun: Reaction time", 1, 200, 100, true, "ms")

local heavy_active = ui.new_checkbox("LEGIT", "Aimbot", "Heavy: First bullet delay")
local heavy_delay = ui.new_slider("LEGIT", "Aimbot", "Heavy: Reaction time", 1, 200, 100, true, "ms")

local sniper_active = ui.new_checkbox("LEGIT", "Aimbot", "Sniper: First bullet delay")
local sniper_delay = ui.new_slider("LEGIT", "Aimbot", "Sniper: Reaction time", 1, 200, 100, true, "ms")

local aim, aim_hk = ui.reference("LEGIT", "Aimbot", "Enabled")
local maximumfov = ui.reference("LEGIT", "Aimbot", "Maximum FOV")

local vector = require "libs/vector"
local vector3 = vector.Vector3

local g_local = entity.get_local_player
local aim_time, weptype = 0, -1
local attack_state = 0
local shot_info = 0

local act = {
    [true] = "Always on",
    [false] = "On hotkey"
}

local function getwpntype(t)
    if type(t) == 'table' then
        for i = 1, #t do
            if weptype == t[i] then
                return true
            end
        end
        return false
    end

    return weptype == t
end

local function getwpnstate(wptype)
    local tbl = {
        [1] = { pistol_active, pistol_delay },
        [2] = { smg_active, smg_delay },
        [3] = { rifle_active, rifle_delay },
        [4] = { shotgun_active, shotgun_delay },
        [5] = { sniper_active, sniper_delay },
        [6] = { heavy_active, heavy_delay }
    }

    if tbl[wptype] then
        return { 
            ["active"] = ui.get(tbl[wptype][1]),
            ["delay"] = ui.get(tbl[wptype][2]) / 1000
        }
    end

    return false
end

local function menu_listener(m)
    if m ~= nil then
        ui.set_callback(pistol_active, menu_listener)
        ui.set_callback(smg_active, menu_listener)
        ui.set_callback(rifle_active, menu_listener)
        ui.set_callback(shotgun_active, menu_listener)
        ui.set_callback(heavy_active, menu_listener)
        ui.set_callback(sniper_active, menu_listener)
    end

    if getwpntype({ -1, 0, 7, 8, 9, 11 }) then
        return
    end

    ui.set_visible(pistol_active, getwpntype(1))
    ui.set_visible(pistol_delay, ui.get(pistol_active) and getwpntype(1))

    ui.set_visible(smg_active, getwpntype(2))
    ui.set_visible(smg_delay, ui.get(smg_active) and getwpntype(2))

    ui.set_visible(rifle_active, getwpntype(3))
    ui.set_visible(rifle_delay, ui.get(rifle_active) and getwpntype(3))

    ui.set_visible(shotgun_active, getwpntype(4))
    ui.set_visible(shotgun_delay, ui.get(shotgun_active) and getwpntype(4))

    ui.set_visible(heavy_active, getwpntype(6))
    ui.set_visible(heavy_delay, ui.get(heavy_active) and getwpntype(6))

    ui.set_visible(sniper_active, getwpntype(5))
    ui.set_visible(sniper_delay, ui.get(sniper_active) and getwpntype(5))
end

local function get_nearest()
    local players = entity.get_players(true)

    local own_x, own_y, own_z = client.eye_position()
    local own_pitch, own_yaw = client.camera_angles()
    local closest_enemy, closest_distance = nil, 999999999
            
    for i = 1, #players do
        local player = players[i]
        local m_bvis = false

        for i = 0, 13 do
            if client.visible(entity.hitbox_position(player, i)) then
                m_bvis = true
                break
            end
        end

        local isProtected = entity.get_prop(player, "m_bGunGameImmunity")

        if isProtected == 0 and m_bvis then
            local enemy_x, enemy_y, enemy_z = entity.hitbox_position(player, 0)
            local x, y, z = enemy_x - own_x, enemy_y - own_y, enemy_z - own_z 

            local yaw = (math.atan2(y, x) * 180 / math.pi)
            local pitch = -(math.atan2(z, math.sqrt(math.pow(x, 2) + math.pow(y, 2))) * 180 / math.pi)

            local yaw_dif = math.abs(own_yaw % 360 - yaw % 360) % 360
            local pitch_dif = math.abs(own_pitch - pitch) % 360
                
            if yaw_dif > 180 then 
                yaw_dif = 360 - yaw_dif
            end

            local real_dif = math.sqrt(math.pow(yaw_dif, 2) + math.pow(pitch_dif, 2))

            if closest_distance > real_dif then
                closest_distance = real_dif
                closest_enemy = players[i]
            end
        end
    end

    if closest_enemy ~= nil then
        return closest_enemy, closest_distance
    end

	return nil, nil
end

local function get_crosshair_entity()
    local skip_entindex = g_local()
    local max_distance = 8192

    local pitch, yaw = client.camera_angles()

    local fwd = vector3.angle_forward(vector3(pitch, yaw, 0))
    local start_pos = vector3(client.eye_position())
    local end_pos = start_pos + (fwd * max_distance)

    local fraction, entindex_hit, pos_hit = start_pos:trace_line(end_pos, skip_entindex)

    if entindex_hit == 0 then
        return nil
    end

    return { entindex_hit, pos_hit, fraction }
end

client.set_event_callback("setup_command", function(cmd)
    if not ui.get(aim) then
        return
    end

    local enemy, dist, wpn_state = get_nearest()
    local wpn_state = getwpnstate(weptype)
    local m_iShotsFired = entity.get_prop(g_local(), "m_iShotsFired")

    if type(wpn_state) ~= "table" then
        ui.set(aim_hk, act[false])
        return
    end

    if attack_state ~= cmd.in_attack then
        attack_state = cmd.in_attack
        if attack_state == 1 then
            aim_time = globals.realtime() + wpn_state.delay
        end
    end

    if shot_info ~= m_iShotsFired then
        shot_info, aim_time = m_iShotsFired, 0
        ui.set(aim_hk, act[false])
    end

    local await = (aim_time > globals.realtime())

    if wpn_state.active and enemy then
        ui.set(aim_hk, act[await])
        if await and ui.get(maximumfov) / 10 >= dist then
            local crosshair = get_crosshair_entity()
            cmd.in_attack = crosshair ~= nil and crosshair[1] == enemy
        end
        
    end
end)

client.set_event_callback("item_equip", function(c)
    local localplayer = entity.get_local_player()
    local nice_uid_lachflip = client.userid_to_entindex(c.userid)

    if localplayer ~= nice_uid_lachflip then
        return
    end

    if c.weptype ~= weptype then
        weptype = c.weptype
        menu_listener()
    end
end)

menu_listener(true)