local httpService = game:GetService("HttpService")

local InterfaceManager = {} do
	InterfaceManager.Folder = "FluentSettings"
    InterfaceManager.Settings = {
        Theme = "Dark",
        Acrylic = true,
        Transparency = true,
        MenuKeybind = "LeftControl"
    }

    function InterfaceManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

    function InterfaceManager:SetLibrary(library)
		self.Library = library
	end

    function InterfaceManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split("/")
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, "/", 1, idx)
		end

		table.insert(paths, self.Folder)
		table.insert(paths, self.Folder .. "/settings")

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

    function InterfaceManager:SaveSettings()
        writefile(self.Folder .. "/options.json", httpService:JSONEncode(InterfaceManager.Settings))
    end

    function InterfaceManager:LoadSettings()
        local path = self.Folder .. "/options.json"
        if isfile(path) then
            local data = readfile(path)
            local success, decoded = pcall(httpService.JSONDecode, httpService, data)

            if success then
                for i, v in next, decoded do
                    InterfaceManager.Settings[i] = v
                end
            end
        end
    end

    function InterfaceManager:BuildInterfaceSection(tab)
        assert(self.Library, "Must set InterfaceManager.Library")
		local Library = self.Library
        local Settings = InterfaceManager.Settings

        InterfaceManager:LoadSettings()

		local section = tab:AddSection("Interface")

		local InterfaceTheme = section:AddDropdown("InterfaceTheme", {
			Title = "Theme",
			Description = "Changes the interface theme.",
			Values = Library.Themes,
			Default = Settings.Theme,
			Callback = function(Value)
				Library:SetTheme(Value)
                Settings.Theme = Value
                InterfaceManager:SaveSettings()
			end
		})

        InterfaceTheme:SetValue(Settings.Theme)
	
		if Library.UseAcrylic then
			section:AddToggle("AcrylicToggle", {
				Title = "Acrylic",
				Description = "The blurred background requires graphic quality 8+",
				Default = Settings.Acrylic,
				Callback = function(Value)
					Library:ToggleAcrylic(Value)
                    Settings.Acrylic = Value
                    InterfaceManager:SaveSettings()
				end
			})
		end
	
		section:AddToggle("TransparentToggle", {
			Title = "Transparency",
			Description = "Makes the interface transparent.",
			Default = Settings.Transparency,
			Callback = function(Value)
				Library:ToggleTransparency(Value)
				Settings.Transparency = Value
                InterfaceManager:SaveSettings()
			end
		})
	
		local MenuKeybind = section:AddKeybind("MenuKeybind", { Title = "Minimize Bind", Default = Settings.MenuKeybind })
		MenuKeybind:OnChanged(function()
			Settings.MenuKeybind = MenuKeybind.Value
            InterfaceManager:SaveSettings()
		end)
		Library.MinimizeKeybind = MenuKeybind
    end

	function InterfaceManager:BuildServerConfig(tab)
		local section = tab:AddSection("Server")

		local CopyServerID = section:AddButton({
			Title = "Copy Server ID",
			Description = "Copy the current PlaceId and ServerId to clipboard",
			Callback = function()
				local placeId = game.PlaceId
				local serverId = game.JobId
				local serverCode = string.format("%d,%s", placeId, serverId)
		
				setclipboard(serverCode)
		
				Fluent:Notify({
					Title = "Server Code Copied",
					Content = "The PlaceId and ServerId code has been copied to your clipboard.",
					Duration = 5
				})
			end
		})
		
		local InputServerID = section:AddInput("Input Server ID", {
			Title = "Input Server ID",
			Default = "",
			Placeholder = "Enter the PlaceId,ServerId",
			Numeric = false,
			Finished = false,
			Callback = function(Value)
				print("Input changed:", Value)
			end
		})
		
		InputServerID:OnChanged(function()
			print("Input updated:", InputServerID.Value)
		end)
		
		local TeleportToInput = section:AddButton({
			Title = "Teleport to Server",
			Description = "Teleport your character to the coordinates in the input",
			Callback = function()
				local inputText = InputServerID.Value
				local coords = {}
		
				if inputText and inputText:match("^(%d+),([%w-]+)$") then
					for value in inputText:gmatch("([^,]+)") do
						table.insert(coords, value)
					end
		
					local placeId = tonumber(coords[1])
					local serverId = coords[2]
		
					if placeId and serverId then
						local success, message = pcall(function()
							TeleportService:TeleportToPlaceInstance(placeId, serverId, game.Players.LocalPlayer)
						end)
		
						if success then
							Fluent:Notify({
								Title = "Teleporting...",
								Content = "Teleporting to the specified server...",
								Duration = 5
							})
						else
							Fluent:Notify({
								Title = "Error",
								Content = "Failed to teleport. Please check the PlaceId and ServerId.",
								Duration = 5
							})
						end
					else
						Fluent:Notify({
							Title = "Invalid Input",
							Content = "Please enter a valid PlaceId,ServerId in the correct format.",
							Duration = 5
						})
					end
				else
					Fluent:Notify({
						Title = "Invalid Format",
						Content = "Please enter the correct format: PlaceId,ServerId",
						Duration = 5
					})
				end
			end
		})
	end
end

return InterfaceManager
