local function g_Math(int, max, declspec)
	local int = (int > max and max or int)

	local tmp = max / int;
	local i = (declspec / tmp)
	i = (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))

	return i
end

local function g_ColorByInt(number, max)
	local Colors = {
		{ 124, 195, 13 },
		{ 176, 205, 10 },
		{ 213, 201, 19 },
		{ 220, 169, 16 },
		{ 228, 126, 10 },
		{ 229, 104, 8 },
		{ 235, 63, 6 },
		{ 237, 27, 3 },
		{ 255, 0, 0 }
	}

	i = g_Math(number, max, #Colors)
	return
		Colors[i <= 1 and 1 or i][1], 
		Colors[i <= 1 and 1 or i][2],
		Colors[i <= 1 and 1 or i][3]
end

--[[
    Example usage:

	local cl = {
	    indicator = client.draw_indicator
	}

	local function on_paint(c)
	    local c_Latency = getPing() -- Some function
	    local r, g, b = g_ColorByInt(c_Latency, 999) -- "999" Max number

	    cl.indicator(c, r, g, b, 255, "PING") -- Shows your ping
	end

	client.set_event_callback("paint", on_paint)
]]--