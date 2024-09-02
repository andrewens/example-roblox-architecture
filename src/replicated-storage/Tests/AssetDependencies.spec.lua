local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

return function()
    describe("SoccerDuels.getAsset", function()
        it("Searches the game for a Roblox Instance and returns it", function()
            local TestFolder = Instance.new("Folder")
            TestFolder.Name = "This is a folder"
            TestFolder.Parent = workspace

            local TestAsset = Instance.new("Part")
            TestAsset.Name = "This is a Part"
            TestAsset.Parent = TestFolder

            local assetPath = `Workspace/{TestFolder.Name}/{TestAsset.Name}`
            local ShouldBeTestAsset = SoccerDuels.getAsset(assetPath)

            assert(ShouldBeTestAsset == TestAsset)

            TestFolder:Destroy()
        end)
    end)
end
