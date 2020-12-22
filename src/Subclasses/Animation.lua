local Animation = {}
Animation.__index = Animation

local RunService = game:GetService("RunService")

function Animation.new(properties, looped)
	local newAnimation = {}
	setmetatable(newAnimation, Animation)
	newAnimation.Properties = properties
	newAnimation.Looped = looped
	newAnimation.Completed = Instance.new("BindableEvent")
	newAnimation.PlaybackState = Enum.PlaybackState.Begin
	return newAnimation
end

function Animation:UnlockKeyframes()
	for _, Property in pairs(self.Properties) do
		for _, keyframe in pairs(Property.Keyframes) do
			keyframe.Passed = false
		end
	end
end

function Animation:PlayProperties()
	for _, Property in pairs(self.Properties) do
		Property:Play()
	end
end
function Animation:Disconnect(heartbeat)
	heartbeat:Disconnect()
	self:UnlockKeyframes()
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
		self:PlayProperties()
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
						if self.Looped then
							self:PlayProperties()
						else
							self.PlaybackState = Enum.PlaybackState.Completed
							self.Completed:Fire()
							self:Disconnect(heartbeat)
						end

					end
				elseif self.PlaybackState == Enum.PlaybackState.Cancelled then
					self:Disconnect(heartbeat)
				end
			end)
		end)
	end
end

return Animation