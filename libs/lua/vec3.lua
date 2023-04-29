
local Vector3 = {}
Vector3.__index = Vector3

function Vector3.new (x, y, z)
  local v = {}
  setmetatable(v, Vector3)
  v.x = x or 0
  v.y = y or 0
  v.z = z or 0
  return v
end

function Vector3:__add (v)
  local r = Vector3.new()
  r.x = self.x + v.x
  r.y = self.y + v.y
  r.z = self.z + v.z
  return r
end


function Vector3:__sub (v)
  local r = Vector3.new()
  r.x = self.x - v.x
  r.y = self.y - v.y
  r.z = self.z - v.z
  return r
end

function Vector3:__mul (v)
  local r = Vector3.new()
  if type(v) == "table" then 
    r.x = self.x * v.x
    r.y = self.y * v.y
    r.z = self.z * v.z
  elseif type(v) == "number" then
    r.x = self.x * v
    r.y = self.y * v
    r.z = self.z * v
  end
  return r
end

function Vector3:__div (v)
  local r = Vector3.new()
  if type(v) == "table" then 
    r.x = self.x / v.x
    r.y = self.y / v.y
    r.z = self.z / v.z
  elseif type(v) == "number" then
    r.x = self.x / v
    r.y = self.y / v
    r.z = self.z / v
  end
  return r
end

function Vector3:dot (v)
  local r =
    self.x * v.x +
    self.y * v.y +
    self.z * v.z
  return r
end

function Vector3:norm ()
  local r = math.sqrt(
    self.x * self.x +
    self.y * self.y +
    self.z * self.z)
  return r
end

function Vector3:unit ()
  local n = self:norm()
  local r = self / n
  return r
end





local vec3 = {}


function vec3.new()
	local v = Vector3.new(1,1,1);
  return v
end


return vec3

-- color = Vector3.new(1,1,1)