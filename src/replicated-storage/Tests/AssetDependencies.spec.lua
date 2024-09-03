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
	describe("SoccerDuels.getExpectedAssets", function()
		it("Returns a list of all expected assets to be in the game", function()
			local AssetDependencies = SoccerDuels.getExpectedAssets()
			assert(typeof(AssetDependencies) == "table")
		end)
		it("All expected assets are actually in the game", function()
			local success = true

			for _, AssetJson in SoccerDuels.getExpectedAssets() do
				local AssetInstance = SoccerDuels.getAsset(AssetJson.Path)
				if AssetInstance == nil then
					success = false
					warn(`[MISSING ASSET] Asset "{AssetJson.Path}" does not exist`)
				end

				if AssetJson.ClassName and not AssetInstance:IsA(AssetJson.ClassName) then
					success = false
					warn(`[INVALID ASSET] Asset "{AssetJson.Path}" is not a {AssetJson.ClassName}! It's a "{AssetInstance.ClassName}"`)
				end
			end

			assert(success)
		end)
	end)
end
