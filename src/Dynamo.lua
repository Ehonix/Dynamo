local Dynamo = {Version = "1.0.0"}

local Animation = {}
do
	Animation.__index = Animation
	local RunService = game:GetService("RunService")

	function Animation:Disconnect(heartbeat)
		heartbeat:Disconnect()
		for _, Property in pairs(self.Properties) do
			for _, keyframe in pairs(Property.Keyframes) do
				keyframe.Passed = false
			end
		end
	end
	function Animation:Pause()
		self.PlaybackState = Enum.PlaybackState.Paused
	end

	function Animation:Cancel()
		self.PlaybackState = Enum.PlaybackState.Cancelled
	end

	function Animation:Play()
		if self.PlaybackState == Enum.PlaybackState.Playing then
			warn("TRIED PLAYING TWEEN WHEN IT IS ALREADY PLAYING")
		else
			self.PlaybackState = Enum.PlaybackState.Playing
			for _, Property in pairs(self.Properties) do
				Property:Play()
			end
			spawn(function()
				local heartbeat
				heartbeat = RunService.Heartbeat:Connect(function(step)
					if self.PlaybackState == Enum.PlaybackState.Playing then
						-- Play
						local propertiesRunning = 0
						for _, Property in pairs(self.Properties) do
							if not (Property.PlaybackState == Enum.PlaybackState.Completed) then
								Property:Step(step)
								propertiesRunning += 1
							end
						end
						-- Completed
						if propertiesRunning == 0 then
							self.PlaybackState = Enum.PlaybackState.Completed
							self.Completed:Fire()
							self:Disconnect(heartbeat)
						end
					elseif self.PlaybackState == Enum.PlaybackState.Cancelled then
						self:Disconnect(heartbeat)
					end
				end)
			end)
		end
	end
end

local Property = {}
do
	Property.__index = Property

	local TweenService = game:GetService("TweenService")

	function Lerp(x, y, alpha)
		return alpha * (y - x) + x
	end

	function LerpUDim(x, y , alpha)
		return UDim.new(Lerp(x.Scale, y.Scale, alpha), Lerp(x.Offset, y.Offset, alpha))
	end

	local LerpPropertyFunctions = {
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

	function Dynamo:GetBezierLength(a, b, c)
		local func = LerpPropertyFunctions["Vector3"]
		local length = 0
		local last = a
		for i = 0.05, 1, 0.05 do
			local p = func(func(a, b, i), func(b, c, i), i)
			length += (a - p).Magnitude
			a = p
		end
		return length
	end

	function Property:Play()
		for _, keyframe in pairs(self.Keyframes) do
			keyframe.Passed = false
		end
		self.Time = 0
		self.PlaybackState = Enum.PlaybackState.Begin
	end

	function Property:InterpolateProperty(startValue, endValue, bezierValue, alpha)
		if bezierValue then
			local func = LerpPropertyFunctions[self.PropertyType]
			return func(func(startValue, bezierValue, alpha), func(bezierValue, endValue, alpha), alpha)
		else
			return LerpPropertyFunctions[self.PropertyType](startValue, endValue, alpha)
		end
	end

	function Property:Step(step)
		self.Time += step
		local runningKeyframes = 0
		for _, keyframe in pairs(self.Keyframes) do
			if not keyframe.Passed then
				runningKeyframes += 1
				local localTime = self.Time - keyframe.StartTime
				-- repititions are used to determine whenether the keyframe is finished or not
				local repititions = math.max(math.floor(localTime / keyframe.Duration), 0)
				localTime -= repititions * keyframe.Duration
				if localTime >= 0 and (repititions <= keyframe.RepeatCount or keyframe.RepeatCount < 0 or not keyframe.Passed) then
					local startValue = keyframe.StartValue
					local endValue = keyframe.EndValue
					local bezierValue = keyframe.BezierValue
					if keyframe.Reverses and (repititions % 2 == 0 or (repititions > keyframe.RepeatCount and keyframe.RepeatCount > 0)) then
						local _ = startValue
						startValue = endValue
						endValue = _
					end

					local alpha
					if localTime < keyframe.EndTime and (repititions <= keyframe.RepeatCount or keyframe.RepeatCount < 0) then
						alpha = TweenService:GetValue(localTime / keyframe.Duration, keyframe.EasingStyle, keyframe.EasingDirection)
					elseif not keyframe.Passed then
						alpha = 1
						keyframe.Passed = true
						keyframe.Completed:Fire()
					end

					if alpha then
						if keyframe.CFrameInfo  then
							if keyframe.CFrameInfo.UseParentSpace then
								local parentCFrame = self.Instance.Parent.CFrame
								startValue = parentCFrame:ToWorldSpace(startValue)
								endValue = parentCFrame:ToWorldSpace(endValue)
								if bezierValue then
									bezierValue = parentCFrame:ToWorldSpace(bezierValue)
								end
							end
							local objectSpaces = self:GetObjectSpaces()
							self.Instance[self.PropertyName] = self:InterpolateProperty(startValue, endValue, bezierValue, alpha)
							if keyframe.CFrameInfo.CarryChildren then
								for part, objectSpace in pairs(objectSpaces) do
									part.CFrame = self.Instance.CFrame:ToWorldSpace(objectSpace)
								end
							end
						else
							self.Instance[self.PropertyName] = self:InterpolateProperty(startValue, endValue, bezierValue, alpha)
						end
					end
				end
			end
		end
		if runningKeyframes == 0 then
			self.PlaybackState = Enum.PlaybackState.Completed
			self.Completed:Fire()
		end
	end

	function Property:GetObjectSpaces()
		local objectSpaces = {}
		for _, descendant in ipairs(self.Instance:GetDescendants()) do
			if descendant:IsA("BasePart") then
				objectSpaces[descendant] = self.Instance.CFrame:ToObjectSpace(descendant.CFrame)
			end
		end
		return objectSpaces
	end
end

function Dynamo:CreateKeyframeInfo(easingStyle, easingDirection, repeatCount, reverses)
	return{
		EasingStyle = easingStyle or Enum.EasingStyle.Linear,
		EasingDirection = easingDirection or Enum.EasingDirection.In,
		RepeatCount = repeatCount or 0,
		Reverses = reverses,
	}
end

function Dynamo:CreateCFrameInfo(carryChildren, useParentSpace)
	return {
		CarryChildren = carryChildren,
		UseParentSpace = useParentSpace,
	}
end

function Dynamo:CreateKeyframe(startValue, endValue, bezierValue, startTime, endTime, keyframeInfo, cFrameInfo)
	local newKeyframe = {}
	newKeyframe.Completed = Instance.new("BindableEvent")
	keyframeInfo = keyframeInfo or self:CreateKeyframeInfo()
	newKeyframe.EasingStyle = keyframeInfo.EasingStyle
	newKeyframe.EasingDirection = keyframeInfo.EasingDirection
	newKeyframe.RepeatCount = keyframeInfo.RepeatCount
	if keyframeInfo.Reverses then
		newKeyframe.RepeatCount *= 2
	end
	newKeyframe.Reverses = keyframeInfo.Reverses
	newKeyframe.StartTime = startTime
	newKeyframe.EndTime = endTime
	newKeyframe.StartValue = startValue
	newKeyframe.EndValue = endValue
	newKeyframe.Duration = endTime - startTime
	newKeyframe.CFrameInfo = cFrameInfo
	newKeyframe.BezierValue = bezierValue
	newKeyframe.Passed = false
	return newKeyframe
end

function Dynamo:CreateProperty(instance, propertyName, keyframes)
	local newProperty = {}
	setmetatable(newProperty, Property)
	newProperty.Keyframes = keyframes
	newProperty.Instance = instance
	newProperty.PropertyName = propertyName
	newProperty.PropertyType = typeof(instance[propertyName])
	newProperty.Completed = Instance.new("BindableEvent")
	newProperty.PlaybackState = Enum.PlaybackState.Begin
	newProperty.Time = 0
	return newProperty
end

function Dynamo:CreateAnimation(properties)
	local newAnimation = {}
	setmetatable(newAnimation, Animation)
	newAnimation.Properties = properties
	newAnimation.Completed = Instance.new("BindableEvent")
	newAnimation.PlaybackState = Enum.PlaybackState.Begin
	return newAnimation
end

return Dynamo