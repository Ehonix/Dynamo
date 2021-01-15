local Property = {}
local EasingFunctions = require(script.Parent:WaitForChild("EasingFunctions"))
local Lerps = require(script.Parent:WaitForChild("Lerps"))
local NumberLerp = Lerps["number"]

function CombineLerps(lerp1, lerp2)
	return function(a)
		local V0, V1 = lerp1(a), lerp2(a)
		return Lerps[typeof(V0)](V0,V1)(a)
	end
end

function Property.new(t)
	local self = {}
	t.EasingType = t.EasingType or "Linear"
	t.EasingDirection = t.EasingDirection or "In"
	self.StartTime = t.StartTime or 0
	self.Duration = t.Duration
	local PropertyType = typeof(t.Values[1])
	local Lerp = Lerps[PropertyType]
	local EaseFunction = EasingFunctions[t.EasingDirection.. t.EasingType]
	local BezierFunction
	
	local BezierLerps = {}
	
	for i = 1, #t.Values - 1 do
		BezierLerps[i] = Lerp(t.Values[i], t.Values[i+1])
	end
	
	for i = 1, #BezierLerps - 1 do
		local newBezierLerps = {}
		for I = 1, #BezierLerps - 1 do
			newBezierLerps[I] = CombineLerps(BezierLerps[I], BezierLerps[I+1])
		end
		BezierLerps = newBezierLerps
	end
	
	BezierLerps = BezierLerps[1]
	
	self.Finished = false
	function self.Step(_time)
		if _time >= self.StartTime and not self.Finished then
			local alpha = math.min(1, (_time - self.StartTime) / t.Duration)
			local calculatedAlpha = EaseFunction(alpha)
			
			if typeof(t.Object) == "Instance" and PropertyType == "CFrame" then
				if t.Object:IsA("Model") then
					t.Object:SetPrimaryPartCFrame(BezierLerps(calculatedAlpha))
				elseif t.Object:IsA("BasePart") and t.MoveChildren then
					local descendantSpaces = {}
					for _, descendant in ipairs(t.Object:GetDescendants()) do
						if descendant:IsA("BasePart") then
							descendantSpaces[#descendantSpaces+1] = {
								Descendant = descendant,
								Space = t.Object.CFrame:ToObjectSpace(descendant.CFrame)
							}
						end
					end
					
					if t.UseInstanceSpace then
						t.Object[t.Property] = t.UseInstanceSpace.CFrame:ToWorldSpace(BezierLerps(calculatedAlpha))
					else
						t.Object[t.Property] = BezierLerps(calculatedAlpha)
					end
					
					
					for _, descendantSpace in pairs(descendantSpaces) do
						descendantSpace.Descendant.CFrame = t.Object.CFrame:ToWorldSpace(descendantSpace.Space)
					end
				else
					if t.UseInstanceSpace then
						t.Object[t.Property] = t.UseInstanceSpace.CFrame:ToWorldSpace(BezierLerps(calculatedAlpha))
					else
						t.Object[t.Property] = BezierLerps(calculatedAlpha)
					end
				end 
			else
				t.Object[t.Property] = BezierLerps(calculatedAlpha)
			end

			if alpha == 1 then
				self.Finished = true
			end
		end
	end
	return self
end

return Property