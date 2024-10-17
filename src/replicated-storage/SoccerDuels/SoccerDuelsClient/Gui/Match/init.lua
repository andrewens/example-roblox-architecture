-- public / Client class methods
local function newMatchGui(self)
	for _, GuiModule in script:GetChildren() do
		if not (GuiModule:IsA("ModuleScript")) then
			continue
		end

		require(GuiModule).new(self)
	end
end

return {
	new = newMatchGui,
}
