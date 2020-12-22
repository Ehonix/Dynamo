local Dynamo = {Version = "1.0.0"}

for _, subclass in ipairs(script.Parent.Subclasses:GetChildren()) do
    Dynamo[subclass.Name] = require(subclass)
end

return Dynamo