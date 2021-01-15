local RunService = game:GetService("RunService")

local Property = require(script.Property)
local Event = require(script.Event)

local Dynamo = {}

local StepTypes = {
	Heartbeat = true,
	RenderStepped = true,
}

function Dynamo.Move(instance, CF)
	local descendantSpaces = {}
	if instance:IsA("BasePart") then
		descendantSpaces[1] = {
			Descendant = instance,
			Space = instance.CFrame:ToObjectSpace(instance.CFrame)
		}
	end
	
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendantSpaces[#descendantSpaces+1] = {
				Descendant = descendant,
			Space = instance.CFrame:ToObjectSpace(descendant.CFrame)
			}
		end
	end

	for _, descendantSpace in pairs(descendantSpaces) do
		descendantSpace.Descendant.CFrame = CF:ToWorldSpace(descendantSpace.Space)
	end
end

function Dynamo.new(data, properties, events)
	local Duration = 0
	data = data or {}
	properties = properties or {}
	events = events or {}
	
	for i, v in pairs(properties) do
		properties[i] = Property.new(v)
		local d = properties[i].Duration + properties[i].StartTime
		if d then
			if d > Duration then
				Duration = d
			end
		else
			error("DYNAMO PROPERTY MISSING DURATION")
		end
	end
	
	for i, v in pairs(events) do
		events[i] = Event.new(v)
	end
	
	local self = {}
	self.PlaybackState = Enum.PlaybackState.Begin

	self.Completed = Instance.new("BindableEvent")
	self.Played = Instance.new("BindableEvent")
	self.Paused = Instance.new("BindableEvent")
	self.Cancelled = Instance.new("BindableEvent")
	self.Repeated = Instance.new("BindableEvent")

	self.Speed = data.Speed or 1
	data.Repeat = math.floor(data.Repeat or 0)
	
	self.Time = 0
	self.TimesRepeated = 0
	
	local StepEvent
	if StepTypes[data.StepType] then
		StepEvent = RunService[data.StepType]
	else
		StepEvent = RunService.Heartbeat
	end

	local runConnection
	
	local function Stop()
		runConnection:Disconnect()
		runConnection = nil
	end
	
	local function ResetObjects()
		for _, property in pairs(properties) do
			property.Finished = false
		end
		for _, event in pairs(events) do
			event.Finished = false
		end
	end
	
	local function Reset()
		self.Time = 0
		ResetObjects()
	end
	
	function self.Play()
		if not runConnection then
			runConnection = StepEvent:Connect(function(step)
				self.Time += step * self.Speed

				for _, property in pairs(properties) do
					property.Step(self.Time)
				end

				for _, event in pairs(events) do
					if self.Time >= event.Time and not event.Finished then
						event.Finished = true
						event.BindableEvent:Fire()
					end
				end

				if self.Time >= Duration then
					if self.TimesRepeated == data.Repeat then
						Stop()
						Reset()
						self.Completed:Fire()
					else
						self.TimesRepeated += 1
						self.Time -= Duration
						ResetObjects()
						self.Repeated:Fire()
					end
				end
			end)
			self.Played:Fire()
		end
	end

	function self.Pause()
		if runConnection then
			Stop()
			self.PlaybackState = Enum.PlaybackState.Paused
			self.Paused:Fire()
		end
	end

	function self.Cancel()
		if runConnection then
			Stop()
			Reset()
			self.PlaybackState = Enum.PlaybackState.Cancelled
			self.Cancelled:Fire()
		end
	end

	return self
end
return Dynamo