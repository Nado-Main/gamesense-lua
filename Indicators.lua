local indicator = { }
indicator.__index = indicator
indicator.invoke_callback = function()
    return setmetatable({ alpha = 0, width = 0, height = 0, p_num = 0, p_time = 0 }, indicator)
end

function indicator:modulation(is_true)
    if is_true then
        if self.alpha < 248 then
            self.alpha = self.alpha + 8
        end
    else
        if self.alpha > 7 then
            self.alpha = self.alpha - 8
        end
    end

    return self.alpha
end

function indicator:process_cmd(num, time)
    if self.p_num ~= num and self.p_time < globals.realtime() then
        self.p_time = globals.realtime() + time
        self.p_num = self.p_num + (self.p_num > num and -1 or 1)
    end

    return self.p_num
end

function indicator:text(w, h, r, g, b, text)
    renderer.text(w, h, r, g, b, self.alpha, "-", 16, text)
    
    self.width = w
    self.height = h
end

function indicator:line(r, g, b, pointer)
    local w, h = self.width, self.height + 10
    if pointer == nil then pointer = self.p_num end

    if pointer > 0 then
        pointer = -11 + pointer
        renderer.rectangle(w, h, w + pointer + 2, 7, 0, 0, 0, self.alpha)
        renderer.rectangle(w + 1, h + 1, w + pointer, 5, r, g, b, self.alpha)
    end
end

-- MENU REFERENCE
local vec_data, flip = { }, true
local elems = { "Lag compensation", "Ping spike" }
local ping, ping_hk = ui.reference("MISC", "Miscellaneous", "Ping spike")

local is_active = ui.new_multiselect("MISC", "Settings", "Indicators", elems)
local picker = ui.new_color_picker("MISC", "Settings", "Indicator picker", 160, 245, 65)

-- VECTOR / ETC.. FUNCTIONS
function Length2DSqr(vec) return (vec[1]*vec[1] + vec[2]*vec[2]) end
function vecMvec(vec, vec1) return { vec[1]-vec1[1], vec[2]-vec1[2] } end
function ro(num, n) return math.floor(num * 10^(n or 0) + 0.5) / 10^(n or 0) end

function yaw_counter(count, alpha) 
    if alpha > 0 then
        return count + 1
    else
        return count
    end
end

function contains(tab, val)
    for index, value in ipairs(ui.get(tab)) do
        if value == val then return true end
    end

    return false
end

function get_player_velocity(Entity)
    local vx = entity.get_prop(Entity, "m_vecVelocity[0]")
    local vy = entity.get_prop(Entity, "m_vecVelocity[1]")

    return math.floor(math.min(10000, math.sqrt(vx*vx + vy*vy) + 0.5))
end

function is_pingspiking()
    return (ui.get(ping) and ui.get(ping_hk))
end

function ping_state(Entity, ic)
    local g_CCSPlayerResource = entity.get_all("CCSPlayerResource")[1]
    local client_latency = entity.get_prop(g_CCSPlayerResource, string.format("%03d", Entity))

    local max_unlag = client.get_cvar("sv_maxunlag") * 1000
    local ping = client_latency <= max_unlag and client_latency or max_unlag

    if not is_pingspiking() then
        ping = 0
    end

    latency = ic:process_cmd(ping, 0.005)
    max_unlag = max_unlag / 1000
    decimal = 21 * max_unlag

    return (latency / decimal), client_latency
end

-- CALLBACKS
local lagcomp = indicator.invoke_callback()
local pingspike = indicator.invoke_callback()

client.set_event_callback("run_command", function(cmd)
    local g_Local = entity.get_local_player()
    if g_Local ~= nil and cmd.chokedcommands == 0 then

        local x, y, z = entity.get_prop(g_Local, "m_vecOrigin")
        vec_data[flip and 0 or 1] = { x, y }

        flip = not flip
        
    end
end)

client.set_event_callback("paint", function()
    local g_Local = entity.get_local_player()
    if g_Local == nil or not entity.is_alive(g_Local) then
        return
    end

    local r, g, b = ui.get(picker)
    local x, y = client.screen_size()
    local csx, y = 0, y / 2

    -- LAG COMP
    if contains(is_active, elems[1]) and (vec_data[0] and vec_data[1]) then
        local shoud_break = get_player_velocity(g_Local) > 280
        local lag_dst = Length2DSqr(vecMvec(vec_data[0], vec_data[1]))

        csx = yaw_counter(csx, lagcomp.alpha)
        lagcomp:modulation(shoud_break)
        lagcomp:text(12, y + (csx * 20), 235, 235, 235, "LAGCOMP  [" .. ro(lag_dst, 1) .. "]")

        lag_dst = lag_dst - 64 * 64 -- m_flTeleportDistanceSqr (4096)
        lag_dst = lag_dst < 0 and 0 or lag_dst / 30
        lag_dst = lag_dst > 62 and 62 or lag_dst

        lagcomp:process_cmd(lag_dst, 0.01)
        lagcomp:line(r, g, b)
    end

    -- PING SPIKE
    if contains(is_active, elems[2]) then

        local latency, cl = ping_state(g_Local, pingspike)
        csx = yaw_counter(csx, pingspike.alpha)

        pingspike:modulation(is_pingspiking())
        pingspike:text(12, y + (csx * 20), 235, 235, 235, "PING  [" .. cl .. " MS]")
        pingspike:line(r, g, b, latency)

    end
end)