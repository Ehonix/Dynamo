local Event = {}

function Event.new(t)
	local self = {}
	self.BindableEvent = t.BindableEvent
	self.Time = t.Time or 0
	self.Finished = false
	return self
end

return Event