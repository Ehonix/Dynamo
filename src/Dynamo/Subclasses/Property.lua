local Property = {}
Property.__index = Property

local TweenService = game:GetService("TweenService")

function Property.new(instance, propertyName, keyframes, looped)
	local newProperty = {}
	setmetatable(newProperty, Property)
	newProperty.Keyframes = keyframes
	newProperty.Length = 0
	for _, keyframe in pairs(keyframes) do
		newProperty.Length = math.max(newProperty.Length, keyframe.EndTime)
	end
	newProperty.Instance = instance
	newProperty.PropertyName = propertyName
	newProperty.PropertyType = typeof(instance[propertyName])
	newProperty.Completed = Instance.new("BindableEvent")
	newProperty.PlaybackState = Enum.PlaybackState.Begin
	newProperty.Time = 0
	newProperty.Looped = looped
	return newProperty
end

function Property:Reset()
	for _, keyframe in pairs(self.Keyframes) do
		keyframe.Passed = false
	end
	self.Time = 0
	self.PlaybackState = Enum.PlaybackState.Begin
end

function Property:Step(step)
	self.Time += step
	if self.Looped then
		self.Time -= self.Length * math.floor(self.Time / self.Length)
	end
	local runningKeyframes = 0
	for _, keyframe in pairs(self.Keyframes) do
		if not keyframe.Passed then
			runningKeyframes += 1
			local localTime = self.Time - keyframe.StartTime
			-- repititions are used to determine whenether the keyframe is finished or not
			local repititions = math.max(math.floor(localTime / keyframe.Duration), 0)
			localTime -= repititions * keyframe.Duration
			if localTime >= 0 and not keyframe.Passed then
				local alpha
				if localTime < keyframe.EndTime then
					alpha = TweenService:GetValue(localTime / keyframe.Duration, keyframe.EasingStyle, keyframe.EasingDirection)
				elseif not keyframe.Passed then
					alpha = 1
					keyframe.Passed = true
					keyframe.Completed:Fire()
				end

				if alpha then
					if self.PropertyType == "CFrame"  then
						if keyframe.UseParentSpace then
							local parentCFrame = self.Instance.Parent.CFrame
							for _, value in pairs(keyframe.Interpolation.Values) do
								value = parentCFrame:ToWorldSpace(value)
							end
						end
						local objectSpaces = self:GetObjectSpaces()
						self.Instance[self.PropertyName] = keyframe.Interpolation:Interpolate(alpha)
						if keyframe.CarryChildren then
							for part, objectSpace in pairs(objectSpaces) do
								part.CFrame = self.Instance.CFrame:ToWorldSpace(objectSpace)
							end
						end
					else
						self.Instance[self.PropertyName] = keyframe.Interpolation:Interpolate(alpha)
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

return Property