
local ref, ref_color = ui.reference("Visuals", "Colored models", "Local fake shadow")

local menu = {
    active = ui.new_checkbox("Visuals", "Colored models", "Shadow pulsating"),
    max_alpha = ui.new_slider("Visuals", "Colored models", "Maximum shadow alpha", 25, 255, 175, true),
    threhsold = ui.new_slider("Visuals", "Colored models", "Alpha threhsold", 0, 100, 25, false),
}

local act = 1
local alpha = 0

local fps_prev = 0
local last_update_time = 0
local frametimes = { }

local function get_fps()
    local rt, ft = globals.realtime(), globals.absoluteframetime()

    if ft > 0 then 
        table.insert(frametimes, 1, ft)
    end

    local count = #frametimes
    if count == 0 then
        return 0
    end

    local accum = 0
    local i = 0
    while accum < 0.5 do
        i = i + 1
        accum = accum + frametimes[i]
        if i >= count then
            break
        end
    end
    
    accum = accum / i
    
    while i < count do
        i = i + 1
        table.remove(frametimes)
    end
    
    local fps = 1 / accum
    local time_since_update = rt - last_update_time
    if math.abs(fps - fps_prev) > 4 or time_since_update > 1 then
        fps_prev = fps
        last_update_time = rt
    else
        fps = fps_prev
    end
    
    return math.floor(fps + 0.5)
end

client.set_event_callback("paint", function(c)

    if not ui.get(menu.active) then
        return
    end

    local r, g, b, a = ui.get(ref_color)
    local max_alpha = ui.get(menu.max_alpha)
    local threhsold = ui.get(menu.threhsold)

    local cur_fps = get_fps()
    local max_fps = cur_fps > 300 and cur_fps or 300
    
    local factor = max_fps / cur_fps

    if alpha > max_alpha + threhsold then act = -factor end
    if alpha < -threhsold then act = factor end

    alpha = alpha + act

    local ret = alpha

    if ret < 0 then ret = 0 end
    if ret > max_alpha or ret > 255 then
        ret = max_alpha
    end

    ui.set(ref_color, r, g, b, ret)
end)

local function menu_listener(data)
    if type(data) == "table" then
        for i = 1, #data, 1 do
            ui.set_callback(menu[data[i]], menu_listener)
        end
    end

    local is_active = ui.get(menu.active)
    ui.set_visible(menu.max_alpha, is_active)
    ui.set_visible(menu.threhsold, is_active)
end

menu_listener({ "active", "max_alpha" })