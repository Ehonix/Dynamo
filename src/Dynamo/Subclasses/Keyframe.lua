local Keyframe = {}

function Keyframe.new(interpolation, startTime, endTime, easingStyle, easingDirection, carryChildren, useParentSpace)
	local newKeyframe = {}
	newKeyframe.Completed = Instance.new("BindableEvent")
	newKeyframe.EasingStyle = easingStyle or Enum.EasingStyle.Linear
	newKeyframe.EasingDirection = easingDirection or Enum.EasingDirection.In
	newKeyframe.StartTime = startTime
	newKeyframe.EndTime = endTime
	newKeyframe.Interpolation = interpolation
	newKeyframe.Duration = endTime - startTime
	newKeyframe.CarryChildren = carryChildren
	newKeyframe.UseParentSpace = useParentSpace
	newKeyframe.Passed = false
	return newKeyframe
end

return Keyframe