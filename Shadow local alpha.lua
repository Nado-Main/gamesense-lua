
local ref, ref_color = ui.reference("Visuals", "Colored models", "Local fake shadow")

local menu = {
    active = ui.new_checkbox("Visuals", "Colored models", "Shadow pulsating"),
    max_alpha = ui.new_slider("Visuals", "Colored models", "Maximum shadow alpha", 25, 255, 175, true),
    threshold = ui.new_slider("Visuals", "Colored models", "Alpha threshold", 0, 100, 25, false),
    speed = ui.new_slider("Visuals", "Colored models", "Alpha speed", 0, 100, 90, true, "%"),
}

local act = 1
local alpha = 0

client.set_event_callback("paint", function(c)

    if not ui.get(menu.active) then
        return
    end

    local r, g, b, a = ui.get(ref_color)
    local max_alpha = ui.get(menu.max_alpha)
    local threshold = ui.get(menu.threshold)

    local factor = 255 / ((100 - ui.get(menu.speed)) / 100) * globals.frametime()

    if alpha > max_alpha + threshold then act = -factor end
    if alpha < -threshold then act = factor end

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
    ui.set_visible(menu.threshold, is_active)
end

menu_listener({ "active", "max_alpha" })