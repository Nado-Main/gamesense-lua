-- credits: Valve Corporation, lua.org, "none"

--
-- todo add asserts
--       add handling for div by 0
--       change vector normalize
--       add Vector2 and Angle files / implementation
--

-- localize vars
local type = type
local error = error
local getmetatable = getmetatable
local setmetatable = setmetatable
local tostring = tostring

local math_pi = math.pi
local math_min = math.min
local math_max = math.max
local math_deg = math.deg
local math_rad = math.rad
local math_sqrt = math.sqrt
local math_sin = math.sin
local math_cos = math.cos
local math_atan = math.atan
local math_atan2 = math.atan2
local math_acos = math.acos
local math_fmod = math.fmod
local math_floor = math.floor

local entity_get_prop = entity.get_prop
local client_trace_line = client.trace_line
local client_trace_bullet = client.trace_bullet
local client_eye_position = client.eye_position
local client_camera_angles = client.camera_angles

local renderer_line = renderer.line
local renderer_text = renderer.text
local renderer_world_to_screen = renderer.world_to_screen


--set up module metatable
local M = {}

-- set up vector3 table and metatable
local Vector3 = {}

local _V3_MT   = {}
_V3_MT.__index = _V3_MT

--
-- create Vector3 object
--
function Vector3.Vector3(x, y, z)
	-- check args
	x = type(x) == "number" and x or 0
	y = type(y) == "number" and y or 0
	z = type(z) == "number" and z or 0

	return setmetatable(
		{
			x = x,
			y = y,
			z = z
		},
		_V3_MT
   )
end

-- vector2 - will receive a proper implementation in the future, for now its just a vector3 with z = 0
local Vector2 = {}
function Vector2.Vector2(x, y)
	return Vector3.Vector3(x, y, 0)
end

-- create Vector3 object from entindex
function Vector3.from_entindex(entindex)
	local x, y, z = entity_get_prop(entindex, "m_vecAbsOrigin")
	if x == nil or x == 0 then
		x, y, z = entity_get_prop(entindex, "m_vecOrigin")
	end
	if x == nil then
		return
	end
	return Vector3.Vector3(x, y, z)
end

--
-- metatable operators
--
function _V3_MT.__eq(a, b) -- equal to another vector
	return a.x == b.x and a.y == b.y and a.z == b.z
end

function _V3_MT.__unm(a) -- unary minus
	return Vector3.Vector3(
		-a.x,
		-a.y,
		-a.z
   )
end

function _V3_MT.__add(a, b) -- add another vector or number
	local a_type = type(a)
	local b_type = type(b)

	if(a_type == "table" and b_type == "table") then
		return Vector3.Vector3(
			a.x + b.x,
			a.y + b.y,
			a.z + b.z
	   )
	elseif(a_type == "table" and b_type == "number") then
		return Vector3.Vector3(
			a.x + b,
			a.y + b,
			a.z + b
	   )
	elseif(a_type == "number" and b_type == "table") then
		return Vector3.Vector3(
			a + b.x,
			a + b.y,
			a + b.z
	   )
	end
end

function _V3_MT.__sub(a, b) -- subtract another vector or number
	local a_type = type(a)
	local b_type = type(b)

	if(a_type == "table" and b_type == "table") then
		return Vector3.Vector3(
			a.x - b.x,
			a.y - b.y,
			a.z - b.z
	   )
	elseif(a_type == "table" and b_type == "number") then
		return Vector3.Vector3(
			a.x - b,
			a.y - b,
			a.z - b
	   )
	elseif(a_type == "number" and b_type == "table") then
		return Vector3.Vector3(
			a - b.x,
			a - b.y,
			a - b.z
	   )
	end
end

function _V3_MT.__mul(a, b) -- multiply by another vector or number
	local a_type = type(a)
	local b_type = type(b)

	if(a_type == "table" and b_type == "table") then
		return Vector3.Vector3(
			a.x * b.x,
			a.y * b.y,
			a.z * b.z
	   )
	elseif(a_type == "table" and b_type == "number") then
		return Vector3.Vector3(
			a.x * b,
			a.y * b,
			a.z * b
	   )
	elseif(a_type == "number" and b_type == "table") then
		return Vector3.Vector3(
			a * b.x,
			a * b.y,
			a * b.z
	   )
	end
end

function _V3_MT.__div(a, b) -- divide by another vector or number
	local a_type = type(a)
	local b_type = type(b)

	if(a_type == "table" and b_type == "table") then
		return Vector3.Vector3(
			a.x / b.x,
			a.y / b.y,
			a.z / b.z
	   )
	elseif(a_type == "table" and b_type == "number") then
		return Vector3.Vector3(
			a.x / b,
			a.y / b,
			a.z / b
	   )
	elseif(a_type == "number" and b_type == "table") then
		return Vector3.Vector3(
			a / b.x,
			a / b.y,
			a / b.z
	   )
	end
end

function _V3_MT.__tostring(a) -- used for 'tostring(vector3_object)'
	return "(" .. a.x .. ", " .. a.y .. ", " .. a.z .. ")"
end

--
-- metatable misc funcs
--
function _V3_MT:clear() -- zero all vector vars
	self.x = 0
	self.y = 0
	self.z = 0
end

function _V3_MT:unpack() -- returns axes as 3 seperate arguments
	return self.x, self.y, self.z
end

function _V3_MT:length_2d_sqr() -- squared 2D length
	return (self.x * self.x) + (self.y * self.y)
end

function _V3_MT:length_sqr() -- squared 3D length
	return (self.x * self.x) + (self.y * self.y) + (self.z * self.z)
end

function _V3_MT:length_2d() -- 2D length
	return math_sqrt(self:length_2d_sqr())
end

function _V3_MT:length() -- 3D length
	return math_sqrt(self:length_sqr())
end

function _V3_MT:dot(other) -- dot product
	return (self.x * other.x) + (self.y * other.y) + (self.z * other.z)
end

function _V3_MT:cross(other) -- cross product
	return Vector3.Vector3(
		(self.y * other.z) - (self.z * other.y),
		(self.z * other.x) - (self.x * other.z),
		(self.x * other.y) - (self.y * other.x)
   )
end

function _V3_MT:dist_to(other) -- 3D length to another vector
	return (other - self):length()
end

function _V3_MT:dist_to_2d(other) -- 3D length to another vector
	return (other - self):length_2d()
end

function _V3_MT:is_zero(tolerance) -- is the vector zero (within tolerance value, can pass no arg if desired)?
	tolerance = tolerance or 0.001

	return (self.x < tolerance and self.x > -tolerance
			and	self.y < tolerance and self.y > -tolerance
			and	self.z < tolerance and self.z > -tolerance)
end

function _V3_MT:normalize() -- normalizes this vector and returns the length
	local l = self:length()
	if(l <= 0) then
		return 0
	end

	self.x = self.x / l
	self.y = self.y / l
	self.z = self.z / l

	return l
end

function _V3_MT:normalize_2d() -- normalizes this vector and returns the length
	local l = self:length_2d()
	if(l <= 0) then
		return 0
	end

	self.x = self.x / l
	self.y = self.y / l
	self.z = self.z / l

	return l
end

function _V3_MT:normalize_no_len() -- normalizes this vector (no length returned)
	local l = self:length()
	if(l <= 0) then
		return
	end

	self.x = self.x / l
	self.y = self.y / l
	self.z = self.z / l
end

function _V3_MT:normalized() -- returns a normalized unit vector
	local l = self:length()
	if(l <= 0) then
		return Vector3.Vector3()
	end

	return Vector3.Vector3(
		self.x / l,
		self.y / l,
		self.z / l
   )
end

function _V3_MT:to_screen() -- returns x and y of on screen vector position
	return renderer_world_to_screen(self:unpack())
end

function _V3_MT:trace_line(other, skip_entindex) -- returns the fraction and entindex hit of a trace line
	local skip_entindex = skip_entindex ~= nil and skip_entindex or -1
	local x1, y1, z1 = self:unpack()
	local fraction, entindex_hit = client_trace_line(skip_entindex, x1, y1, z1, other:unpack())
	local vec_hit = self:lerp(other, fraction)
	return fraction, entindex_hit, vec_hit
end

function _V3_MT:trace_bullet(other, from_player)
	local x1, y1, z1 = self:unpack()
	return client_trace_bullet(from_player, x1, y1, z1, other:unpack())
end

function _V3_MT:draw_text(r, g, b, a, ...) -- draws a text at the position, intended for quickly debugging something
	local wx, wy = self:to_screen()
	if wx ~= nil then
		renderer_text(wx, wy, r, g, b, a, "c", 0, ...)
		return true
	end
	return false
end

function _V3_MT:draw_line(other, r, g, b, a, width) -- draws a text at the position, intended for quickly debugging something
	local width = width or 1
	if r == nil then
		r, g, b, a = 255, 255, 255, 255
	end
	local wx1, wy1 = self:to_screen()
	local wx2, wy2 = other:to_screen()

	if wx1 ~= nil and wx2 ~= nil then
		--client_draw_text(nil, wx, wy, r, g, b, a, "c", 0, ...)
		if width > 1 then
			wx1, wy1, wx2, wy2 = math_floor(wx1-width/2), math_floor(wy1-width/2), math_floor(wx2-width/2), math_floor(wy2-width/2)
		end
		for i=1, width, 0.5 do
			renderer_line(wx1+(i-1), wy1, wx2+(i-1), wy2, r, g, b, a/2)
			renderer_line(wx1, wy1+(i-1), wx2, wy2+(i-1), r-5, g-5, b-5, a/2)
		end
		return true
	end
	return false
end

function _V3_MT:lerp(other, percentage) -- returns a new vector
	return (other - self) * percentage + self
end

function _V3_MT:clone() --returns a new vector with the same properties
	return Vector3(self:unpack())
end

function _V3_MT:vector_angles(other) -- returns a new vector
	--https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/mathlib/mathlib_base.cpp#L535-L563
	local origin_x, origin_y, origin_z
	local target_x, target_y, target_z
	if other == nil then
		target_x, target_y, target_z = self.x, self.y, self.z
		origin_x, origin_y, origin_z = client_eye_position()
		if origin_x == nil then
			return
		end
	else
		target_x, target_y, target_z = other.x, other.y, other.z
		origin_x, origin_y, origin_z = self.x, self.y, self.z
	end

	--calculate delta of vectors
	local delta_x, delta_y, delta_z = target_x-origin_x, target_y-origin_y, target_z-origin_z

	if delta_x == 0 and delta_y == 0 then
		return (delta_z > 0 and 270 or 90), 0
	else
		--calculate yaw
		local yaw = math_deg(math_atan2(delta_y, delta_x))

		--calculate pitch
		local hyp = math_sqrt(delta_x*delta_x + delta_y*delta_y)
		local pitch = math_deg(math_atan2(-delta_z, hyp))

		return Vector2.Vector2(pitch, yaw)
	end
end

function _V3_MT:get_fov(start_pos, pitch, yaw)
	if start_pos == nil then start_pos = Vector3.Vector3(client_eye_position()) end
	local viewangles
	if getmetatable(pitch) == _V3_MT then
		viewangles = pitch
	elseif type(pitch) == "number" and type(yaw) == "number" then
		viewangles = Vector2.Vector2(pitch, yaw)
	elseif pitch == nil then
		viewangles = Vector2.Vector2(client_camera_angles())
	end

	local viewangles_target = start_pos:vector_angles(self)
	return (viewangles-viewangles_target):length_2d()
end

function _V3_MT:in_fov(fov, start_pos, pitch, yaw)
	if fov == nil then error("Invalid arguments: FOV is required") end

	return fov > self:get_fov(start_pos, pitch, yaw)
end

--
-- other math funcs
--
function Vector3.clamp(cur_val, min_val, max_val) -- clamp number within 'min_val' and 'max_val'
	return math_min(math_max(cur_val, min_val), max_val)
end

function Vector3.normalize_angle(angle) -- ensures angle axis is within [-180, 180]
	-- bad number
	if(angle ~= angle or angle == 1/0) then
		return 0
	end

	-- nothing to do, angle is in bounds
	if(angle >= -180 and angle <= 180) then
		return angle
	end

	-- bring into range
	local out = math_fmod(math_fmod(angle + 360, 360), 360)
	if(out > 180) then
		out = out - 360
	end

	return out
end
local normalize_angle = Vector3.normalize_angle

function Vector3.vector_to_angle(forward) -- vector -> euler angle
	local pitch, yaw

	local l = forward:length()
	if(l > 0) then
		pitch = math_deg(math_atan(-forward.z, l))
		yaw = math_deg(math_atan(forward.y, forward.x))
	else
		if(forward.x > 0) then
			pitch = 270
		else
			pitch = 90
		end

		yaw = 0
	end

	return Vector3.Vector2(pitch, yaw)
end

function Vector3.angle_forward(angle) -- angle -> direction vector (forward)
	local pitch, yaw = angle.x, angle.y
	local cos_pitch = math_cos(math_rad(pitch))
	local cos_yaw = math_cos(math_rad(yaw))

	local sin_yaw = math_sin(math_rad(yaw))
	local sin_pitch = math_sin(math_rad(pitch))

	return Vector3.Vector3(
		cos_pitch * cos_yaw,
		cos_pitch * sin_yaw,
		-sin_pitch
   )
end

function Vector3.angle_right(angle) -- angle -> direction vector (right)
	local sin_pitch = math_sin(math_rad(angle.x))
	local cos_pitch = math_cos(math_rad(angle.x))
	local sin_yaw = math_sin(math_rad(angle.y))
	local cos_yaw = math_cos(math_rad(angle.y))
	local sin_roll = math_sin(math_rad(angle.z))
	local cos_roll = math_cos(math_rad(angle.z))

	return Vector3.Vector3(
		-1.0 * sin_roll * sin_pitch * cos_yaw + -1.0 * cos_roll * -sin_yaw,
		-1.0 * sin_roll * sin_pitch * sin_yaw + -1.0 * cos_roll * cos_yaw,
		-1.0 * sin_roll * cos_pitch
   )
end

function Vector3.angle_up(angle) -- angle -> direction vector (up)
	local sin_pitch = math_sin(math_rad(angle.x))
	local cos_pitch = math_cos(math_rad(angle.x))
	local sin_yaw = math_sin(math_rad(angle.y))
	local cos_yaw = math_cos(math_rad(angle.y))
	local sin_roll = math_sin(math_rad(angle.z))
	local cos_roll = math_cos(math_rad(angle.z))

	return Vector3.Vector3(
		cos_roll * sin_pitch * cos_yaw + -sin_roll * -sin_yaw,
		cos_roll * sin_pitch * sin_yaw + -sin_roll * cos_yaw,
		cos_roll * cos_pitch
   )
end

function Vector3.angle_to_vectors(angle)
	return Vector3.angle_forward(angle), Vector3.angle_right(angle), Vector3.angle_up(angle)
end

function Vector3.angle_diff(dest, src)
	local delta = math_fmod(dest-src, 360)
	if dest > src then
		if delta >= 180 then
			delta = delta - 360
		end
	else
		if delta <= -180 then
			delta = delta + 360
		end
	end
	return delta
end

function Vector3.angle_approach(target, value, speed)
	target = normalize_angle(target)
	value = normalize_angle(value)

	local delta = target - value

	-- Speed is assumed to be positive
	if speed < 0 then
		speed = -speed
	end

	if delta < -180 then
		delta = delta + 360
	elseif delta > 180 then
		delta = delta - 360
	end

	if delta > speed then
		value = value + speed
	elseif delta < -speed then
		value = value - speed
	else
		value = target
	end

	return value
end

--function Vector3.get_FOV(view_angles, start_pos, end_pos) -- get fov to a vector (needs client view angles, start position (or client eye position for example) and the end position)
--	local fwd = Vector3.angle_forward(view_angles)
--	local delta = (end_pos - start_pos):normalized()
--	local fov = math_acos(fwd:dot(delta) / delta:length())
--
--	return math_max(0, math_deg(fov))
--end

M.Vector3 = setmetatable(Vector3, {__call = function(_, ...) return Vector3.Vector3(...) end})
M.vector3 = M.Vector3

M.Vector2 = setmetatable(Vector2, {__call = function(_, ...) return Vector2.Vector2(...) end})
M.vector2 = M.Vector2

return M
