local Interpolation = {}
Interpolation.__index = Interpolation
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

function Lerp(x, y, alpha)
	return alpha * (y - x) + x
end

function LerpUDim(x, y , alpha)
	return UDim.new(Lerp(x.Scale, y.Scale, alpha), Lerp(x.Offset, y.Offset, alpha))
end

function GetDistance(a, b)
	return math.abs(a - b)
end

function Get2DDistance(a1, a2, b1, b2)
	return math.sqrt((a1 - a2)^2 + (b1 - b2)^2)
end

function Get3DDistance(a1, a2, b1, b2, c1, c2)
	return math.sqrt((a1- a2)^2 + (b1 - b2)^2 + (c1 - c2)^2)
end

function UDim2ToVector2(uDim2)
	if RunService:IsClient() then
		local mouse = Players.LocalPlayer:GetMouse()
		return Vector2.new(uDim2.X.Offset + uDim2.X.Scale * mouse.ViewSizeX, uDim2.Y.Offset + uDim2.Y.Scale * mouse.ViewSizeY)
	else
		warn("CANNOT GET SCREEN SIZE FROM SERVER. RETURNING 1")
		return 1
	end
end

function GetVector2Distance(x, y)
	return Get2DDistance(x.X, y.X, x.Y, y.Y)
end
local Distances = {
	number = GetDistance,
	["Color3"] = function(x, y)
		return Get3DDistance(x.R, y.R, x.G, y.G, x.B, y.B)
	end,
	["CFrame"] = function (x, y)
		return Get3DDistance(x.X, y.X, x.Y, y.Y, x.Z, y.Z)
	end,
	bool = GetDistance,
	["Rect"] = function (x, y)
		return Get2DDistance((x.MinX + x.MaxX)/2, (y.MinX + y.MaxX)/2, (x.MinY + x.MaxY)/2, (y.MinY + y.MaxY)/2)
	end,
	["UDim"] = function(x, y)
		warn("CANNOT GET THE DISTANCE OF AN UDIM. RETURNING 1")
		return 1
	end,
	["UDim2"] = function(x, y)
		return GetVector2Distance(UDim2ToVector2(x), UDim2ToVector2(y))
	end,
	["Vector2"] = GetVector2Distance,
	["Vector3"] = function(x, y)
		return Get3DDistance(x.X, y.X, x.Y, y.Y, x.Z, y.Z)
	end,
	["Vector2int16"] = function(x, y)
		return Get2DDistance(x.X, y.X, x.Y, y.Y)
	end
}
local Interpolations = {
	number = Lerp,
	["Color3"] = function(x, y, alpha)
		return x:lerp(y, alpha)
	end,
	["CFrame"] = function (x, y, alpha)
		return x:Lerp(y, alpha)
	end,
	bool = function (x, y, alpha)
		if alpha == 1 then
			return y
		else
			return x
		end
	end,
	["Rect"] = function (x, y, alpha)
		return Rect.new(Lerp(x.Min.X, y.Min.X, alpha), Lerp(x.Min.Y, y.Min.Y, alpha), Lerp(x.Min.X, y.Min.X, alpha), Lerp(x.Max.X, y.Max.X, alpha))
	end,
	["UDim"] = LerpUDim,
	["UDim2"] = function(x, y, alpha)
		return UDim2.new(LerpUDim(x.X, y.Y, alpha), LerpUDim(x.Y, y.Y, alpha))
	end,
	["Vector2"] = function (x, y, alpha)
		return Vector2.new(Lerp(x.X, y.X, alpha), Lerp(x.Y, y.Y, alpha))
	end,
	["Vector3"] = function(x, y, alpha)
		return Vector3.new(Lerp(x.X, y.X, alpha), Lerp(x.Y, y.Y, alpha), Lerp(x.Z, y.Z, alpha))
	end,
	["Vector2int16"] = function(x, y, alpha)
		return Vector2int16.new(Lerp(x.X, y.X, alpha), Lerp(x.Y, y.Y, alpha))
	end
}

function Interpolation.new(values, fixed)
	local newInterpolation = {}
	setmetatable(newInterpolation, Interpolation)
	newInterpolation.Values = values
	newInterpolation.Fixed = fixed
	newInterpolation.Type = typeof(newInterpolation.Values[1])
	newInterpolation.Lerp = Interpolations[newInterpolation.Type]
	newInterpolation.Dist = Distances[newInterpolation.Type]
	newInterpolation.Length, newInterpolation.Ranges, newInterpolation.Sums = newInterpolation:GetLength()
	return newInterpolation
end

function Interpolation:Interpolate(alpha, overrideFixed)
	if self.Fixed and not overrideFixed then
		local T, near = alpha * self.Length, 0
		for _, n in pairs(self.Sums) do
			if (T - n) < 0 then break end
			near = n
		end
		local set = self.Ranges[near]
		local percent = (T - near)/set[1]
		return self.Lerp(set[2], set[3], percent)
	else
		local output = self.Values
		for i = 1, #self.Values - 1 do
			local newOutput = {}
			for I = 1, #output - 1 do
				newOutput[I] = self.Lerp(output[I], output[I + 1], alpha)
			end
			output = newOutput
		end
		return output[1]
	end
end

function Interpolation:GetLength(n)
	n = n or 20
	local sum, ranges, sums = 0, {}, {}
	for i = 0, n-1 do
		local p1, p2 = self:Interpolate(i/n, true), self:Interpolate((i+1)/n, true)
		local dist = self.Dist(p1, p2)
		if i == n - 1 then
		end
		
		ranges[sum] = {dist, p1, p2}
		table.insert(sums, sum)
		sum = sum + dist
	end
	return sum, ranges, sums
end
return Interpolation