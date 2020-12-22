local toolbar = plugin:CreateToolbar("Dynamo")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StoredDynamo = script.Parent.Dynamo
-- Test Button
local newScriptButton = toolbar:CreateButton("Update", "Updates Dynamo", "rbxassetid://6123877968")
local function onNewScriptButtonClicked()
    UpdateDynamo()
end
newScriptButton.Click:Connect(onNewScriptButtonClicked)

-- Find if Dynamo is already installed
-- Update Dynamo if it isn't already by comparing source string
function UpdateDynamo()
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
end