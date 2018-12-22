local ui_get, ui_set = ui.get, ui.set
local draw_text = client.draw_text
local draw_rectangle = client.draw_rectangle
local width, height = client.screen_size()
local last_tick = 0

local aim_table, shot_state = { }, { }
local Elements = {
    is_active = ui.new_checkbox("MISC", "Settings", "Aim bot logging"),
    palette = ui.new_color_picker("MISC", "Settings", "Logging picker", 16, 22, 29, 160),
    hitboxes = ui.new_checkbox("MISC", "Settings", "Lag compensated hitboxes"),
    hitboxes_time = ui.new_slider("MISC", "Settings", "Duration", 1, 20, 3, true, "s"),

    table_size = ui.new_slider("MISC", "Settings", "Maximum amount", 2, 10, 5),
    size_x = ui.new_slider("MISC", "Settings", "X Axis", 1, width, 90, true, "px"),
    size_y = ui.new_slider("MISC", "Settings", "Y Axis", 1, height, 400, true, "px"),

    resolver_state = ui.reference("RAGE", "Other", "Anti-aim correction"),
    reset_table = ui.new_button("MISC", "Settings", "Reset table", function()
        aim_table = {}
    end)
}

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

local function hook_aim_event(status, m)
	if not ui_get(Elements.is_active) then
		return
    end

    if status == "aim_hit" then
        shot_state[m.id]["got"] = true
    end

    if shot_state[m.id] and shot_state[m.id]["got"] then
        for n, _ in pairs(aim_table) do
            if aim_table[n].id == m.id then
                aim_table[n]["hit"] = status
            end
        end
    end
end

client.set_event_callback("aim_hit", function(m) hook_aim_event("aim_hit", m) end)
client.set_event_callback("aim_miss", function(m) hook_aim_event("aim_miss", m) end)
client.set_event_callback("bullet_impact", function(m)
	if not ui_get(Elements.is_active) then
		return
	end

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
end)

client.set_event_callback("aim_fire", function(m)
    if ui_get(Elements.is_active) then

        local lagcomp, LC = -1, "-"
        local nick = entity.get_player_name(m.target)
        local backtrack = get_server_rate(m.backtrack)
        for i = 10, 2, -1 do aim_table[i] = aim_table[i-1] end

        if m.teleported then
            lagcomp = 2
            LC = "Breaking"
        elseif not m.teleported and backtrack < 0 then
            lagcomp = 3
            LC = "Predict (" .. math.abs(backtrack) .. "t)"
        elseif backtrack == 0 then
            lagcomp = 0
            LC = "-"
        else
            lagcomp = 1
            LC = backtrack .. " Ticks"
        end

        if ui_get(Elements.hitboxes) then
            local r, g, b, a = 90, 227, 25, 150
            if m.backtrack > 0 then r, g, b, a = 89, 116, 204, 150 end
            if m.high_priority then r, g, b, a = 255, 0, 0, 150 end

            client.draw_hitboxes(m.target, ui_get(Elements.hitboxes_time), 19, r, g, b, a, m.backtrack)
        end

        aim_table[1] = { 
            ["id"] = m.id, ["hit"] = not ui.get(Elements.resolver_state) and "aim_unknown" or 0, 
            ["player"] = string.sub(nick, 0, 14),
            ["dmg"] = m.damage, ["lc"] = LC, ["lagcomp"] = lagcomp,
            ["pri"] = (m.high_priority and "High" or "Normal")
        }

        shot_state[m.id] = { ["hit"] = false, ["time"] = globals.curtime() + TicksTime(32) + client.latency() }
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
    if not ui_get(Elements.is_active) then
        return
    end

    local x, y, d = ui_get(Elements.size_x), ui_get(Elements.size_y), 0
    local r, g, b, a = ui_get(Elements.palette)
    local n = ui_get(Elements.table_size)
    local col_sz = 24 + (16 * (#aim_table > n and n or #aim_table))

    -- Analysing table
    local width_s, nt = 0, { ["none"] = 0, ["predict"] = 0, ["breaking"] = 0, ["backtrack"] = 0 }
    for i = 1, ui_get(Elements.table_size), 1 do
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
    for i = 1, ui_get(Elements.table_size), 1 do
        d = drawTable(c, d, x, y, aim_table[i])
    end
end)

local function visibility()
    local rpc = ui_get(Elements.is_active)
    local hpc = ui_get(Elements.hitboxes)

    ui.set_visible(Elements.hitboxes, rpc)
    ui.set_visible(Elements.hitboxes_time, rpc and hpc)

    ui.set_visible(Elements.table_size, rpc)
    ui.set_visible(Elements.size_x, rpc)
    ui.set_visible(Elements.size_y, rpc)
end

visibility()
ui.set_callback(Elements.is_active, visibility)
ui.set_callback(Elements.hitboxes, visibility)