local Keyframe = {}

function Keyframe.new(interpolation, startTime, endTime, easingStyle, easingDirection, repeatCount, reverses, carryChildren, useParentSpace)
	local newKeyframe = {}
	newKeyframe.Completed = Instance.new("BindableEvent")
	newKeyframe.EasingStyle = easingStyle or Enum.EasingStyle.Linear
	newKeyframe.EasingDirection = easingDirection or Enum.EasingDirection.In
	newKeyframe.RepeatCount = repeatCount or 0
	if reverses then
		newKeyframe.RepeatCount *= 2
	end
	newKeyframe.Reverses = reverses
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