local ui_get, ui_set = ui.get, ui.set
local draw_text = client.draw_text
local draw_rectangle = client.draw_rectangle
local width, height = client.screen_size()

local last_tick = 0
local aim_table, shot_state = { }, { }

local menu = {
    is_active = ui.new_checkbox("MISC", "Settings", "Aim bot logging"),
    palette = ui.new_color_picker("MISC", "Settings", "Logging picker", 16, 22, 29, 160),

    table_size = ui.new_slider("MISC", "Settings", "Maximum amount", 2, 10, 5),
    size_x = ui.new_slider("MISC", "Settings", "X Axis", 1, width, 90, true, "px"),
    size_y = ui.new_slider("MISC", "Settings", "Y Axis", 1, height, 400, true, "px"),

    hitboxes = ui.new_checkbox("MISC", "Settings", "Lag compensated hitboxes"),
    hp_default = ui.new_color_picker("MISC", "Settings", "Target picker", 90, 227, 25, 150),

    h_backtrack = ui.new_checkbox("MISC", "Settings", "Backtrack hitboxes"),
    hp_backtrack = ui.new_color_picker("MISC", "Settings", "Backtrack picker", 89, 116, 204, 150),

    h_hp = ui.new_checkbox("MISC", "Settings", "High priority hitboxes"),
    hp_picker = ui.new_color_picker("MISC", "Settings", "High priority picker", 255, 0, 0, 150),

    hitboxes_time = ui.new_slider("MISC", "Settings", "Duration", 1, 20, 3, true, "s"),

    resolver_state = ui.reference("RAGE", "Other", "Anti-aim correction"),
    reset_table = ui.new_button("MISC", "Settings", "Reset table", function()
        aim_table = {}
    end)
}

local function callback(status, m)
	if not ui_get(menu.is_active) then
		return
    end

    if status == "bullet_impact" then
        local g_Local = entity.get_local_player()
        local g_EntID = client.userid_to_entindex(m.userid)

        if g_Local == g_EntID and last_tick ~= globals.tickcount() then
            local m_valid = {}
            for n, _ in pairs(shot_state) do
                if not shot_state[n]["got"] and shot_state[n]["time"] > globals.curtime() then
                    m_valid[#m_valid + 1] = { ["id"] = n, ["data"] = shot_state[n] }
                end
            end
    
            if #m_valid > 0 then
                for i = 10, 2, -1 do m_valid[i] = m_valid[i-1] end
                for i = #m_valid, 1, -1 do
                    shot_state[m_valid[i].id]["got"] = true
                end
            end
    
            last_tick = globals.tickcount()
        end
        return
    end

    if status == "aim_hit" then shot_state[m.id]["got"] = true end
    if shot_state[m.id] and shot_state[m.id]["got"] then
        for n, _ in pairs(aim_table) do
            if aim_table[n].id == m.id then
                aim_table[n]["hit"] = status
            end
        end
    end
end

local function TicksTime(tick)
    return globals.tickinterval() * tick
end

local function get_server_rate(f)
    local tickrate = 64
    local cmdrate = client.get_cvar("cl_cmdrate") or 64
    local updaterate = client.get_cvar("cl_updaterate") or 64
        
    if cmdrate <= updaterate then 
        tickrate = cmdrate
    elseif updaterate <= cmdrate then 
        tickrate = updaterate
    end

    return math.floor((f * tickrate) + 0.5)
end

client.set_event_callback("aim_fire", function(m)
    if ui_get(menu.is_active) then
        local lagcomp, LC = 0, "-"
        local nick = entity.get_player_name(m.target)
        local backtrack = get_server_rate(m.backtrack)

        if m.teleported then
            lagcomp = 2
            LC = "Breaking"
        elseif not m.teleported and backtrack < 0 then
            lagcomp = 3
            LC = "Predict (" .. math.abs(backtrack) .. "t)"
        elseif backtrack ~= 0 then
            lagcomp = 1
            LC = backtrack .. " Ticks"
        end

        for i = 10, 2, -1 do 
            aim_table[i] = aim_table[i-1]
        end

        aim_table[1] = { 
            ["id"] = m.id, ["hit"] = not ui.get(menu.resolver_state) and "aim_unknown" or 0, 
            ["player"] = string.sub(nick, 0, 14),
            ["dmg"] = m.damage, ["lc"] = LC, ["lagcomp"] = lagcomp,
            ["pri"] = (m.high_priority and "High" or "Normal")
        }

        shot_state[m.id] = { 
            ["hit"] = false,
            ["time"] = globals.curtime() + TicksTime(32) + client.latency()
        }
    end

    if ui_get(menu.hitboxes) then
        local r, g, b, a = ui_get(menu.hp_default)
        if ui_get(menu.h_backtrack) and m.backtrack > 0 then r, g, b, a = ui_get(menu.hp_backtrack) end
        if ui_get(menu.h_hp) and m.high_priority then r, g, b, a = ui_get(menu.hp_picker) end

        client.draw_hitboxes(m.target, ui_get(menu.hitboxes_time), 19, r, g, b, a, m.backtrack)
    end
end)

local function drawTable(c, count, x, y, data)
    if data then
        local y = y + 4
        local pitch = x + 10
        local yaw = y + 15 + (count * 16)
        local r, g, b = 0, 0, 0

        local lagcomp = data.lagcomp == 0 and 1 or data.lagcomp
        local clx = {
            [1] = { 255, 255, 255 },
            [2] = { 255, 84, 84 },
            [3] = { 181, 181, 100 }
        }

        if data.hit == "aim_hit" then
            r, g, b = 94, 230, 75
        elseif data.hit == "aim_miss" then
            r, g, b = 255, 84, 84
        elseif data.hit == "aim_unknown" then
            r, g, b = 245, 127, 23
        else -- Doesnt registered
            r, g, b = 118, 171, 255
        end

        draw_rectangle(c, x, yaw, 2, 15, r, g, b, 255)
        draw_text(c, pitch - 3, yaw + 1, 255, 255, 255, 255, nil, 70, data.id)
        draw_text(c, pitch + 23, yaw + 1, 255, 255, 255, 255, nil, 70, data.player)
        draw_text(c, pitch + 106, yaw + 1, 255, 255, 255, 255, nil, 70, data.dmg)
        draw_text(c, pitch + 137, yaw + 1, 255, 255, 255, 255, nil, 70, data.pri)
        draw_text(c, pitch + 183, yaw + 1, clx[lagcomp][1], clx[lagcomp][2], clx[lagcomp][3], 255, nil, 70, data.lc)

        return (count + 1)
    end
end

client.set_event_callback("paint", function(c)
    if not ui_get(menu.is_active) then
        return
    end

    local x, y, d = ui_get(menu.size_x), ui_get(menu.size_y), 0
    local r, g, b, a = ui_get(menu.palette)
    local n = ui_get(menu.table_size)
    local col_sz = 24 + (16 * (#aim_table > n and n or #aim_table))

    local width_s, nt = 0, { ["none"] = 0, ["predict"] = 0, ["breaking"] = 0, ["backtrack"] = 0 }
    for i = 1, ui_get(menu.table_size), 1 do
        if aim_table[i] then
            local lc = aim_table[i].lagcomp
            if lc == 0 then
                nt["none"] = nt.none + 1
            elseif lc == 1 then
                nt["backtrack"] = nt.backtrack + 1
            elseif lc == 2 then
                nt["breaking"] = nt.breaking + 1
            elseif lc == 3 then
                nt["predict"] = nt.predict + 1
            end
        end
    end

    if nt.predict > 0 then
        width_s = 265
    elseif nt.breaking > 0 then
        width_s = 250
    elseif nt.backtrack > 0 then
        width_s = 245
    else
        width_s = 240
    end

    draw_rectangle(c, x, y, width_s, col_sz, 22, 20, 26, 100)
    draw_rectangle(c, x, y, width_s, 15, r, g, b, a)

    -- Drawing first column
    draw_text(c, x + 10, y + 8, 255, 255, 255, 255, "-c", 70, "ID")
    draw_text(c, x + 10 + 35, y + 8, 255, 255, 255, 255, "-c", 70, "PLAYER")
    draw_text(c, x + 10 + 114, y + 8, 255, 255, 255, 255, "-c", 70, "DMG")
    draw_text(c, x + 10 + 153, y + 8, 255, 255, 255, 255, "-c", 70, "PRIORITY")
    draw_text(c, x + 10 + 201, y + 8, 255, 255, 255, 255, "-c", 70, "LAG COMP")

    -- Drawing table
    for i = 1, ui_get(menu.table_size), 1 do
        d = drawTable(c, d, x, y, aim_table[i])
    end
end)

local function hook_listener(data)
    for i = 1, #data, 1 do
        client.set_event_callback(data[i], function(c) 
            callback(data[i], c)
        end)
    end
end

local function menu_listener(data)
    if type(data) == "table" then
        for i = 1, #data, 1 do
            ui.set_callback(menu[data[i]], menu_listener)
        end
        return
    end

    local rpc = ui_get(menu.is_active)

    ui.set_visible(menu.table_size, rpc)
    ui.set_visible(menu.size_x, rpc)
    ui.set_visible(menu.size_y, rpc)

    ui.set_visible(menu.h_backtrack, ui_get(menu.hitboxes))
    ui.set_visible(menu.hp_backtrack, ui_get(menu.hitboxes))
    ui.set_visible(menu.h_hp, ui_get(menu.hitboxes))
    ui.set_visible(menu.hp_picker, ui_get(menu.hitboxes))
    ui.set_visible(menu.hitboxes_time, ui_get(menu.hitboxes))
end

menu_listener({ "is_active", "hitboxes" })
hook_listener({ "aim_hit", "aim_miss", "bullet_impact" })