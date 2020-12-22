local toolbar = plugin:CreateToolbar("Dynamo")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StoredDynamo = script.Parent.Dynamo
-- Test Button
local newScriptButton = toolbar:CreateButton("Create Empty Script", "Create an empty script", "rbxassetid://4458901886")
local function onNewScriptButtonClicked()
	local newScript = Instance.new("Script")
	newScript.Source = ""
	newScript.Parent = game:GetService("ServerScriptService")
end
newScriptButton.Click:Connect(onNewScriptButtonClicked)

-- Find if Dynamo is already installed
-- Update Dynamo if it isn't already by comparing source string
function CreateDynamo(parent)
    local Dynamo = StoredDynamo:Clone()
    Dynamo.Parent = parent
    return Dynamo
end

local Dynamo
for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
    if not Dynamo and descendant.Name == "Dynamo" and descendant:IsA("Folder") then
        Dynamo = CreateDynamo(descendant.Parent)
        descendant:Destroy()
    end
end
if not Dynamo then
    CreateDynamo(ReplicatedStorage)
end