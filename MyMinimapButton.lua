--[[ MyMinimapButton v0.8 (BCC update)

	This is an embedded library intended to be used by other mods.
	It's not a standalone mod.

	Updated for BCC: replaced `this`, `arg1`, `getglobal`, `table.getn`,
	`for i in` with modern equivalents.
]]

local version = 0.8

if not MyMinimapButton or MyMinimapButton.Version < version then

  MyMinimapButton = {

	Version = version,

	Create = function(self, modName, modSettings, initSettings)
		if not modName or _G[modName .. "MinimapButton"] then
			return
		end
		initSettings = initSettings or {}
		modSettings = modSettings or {}
		self.Buttons = self.Buttons or {}

		local frameName = modName .. "MinimapButton"
		local frame = CreateFrame("Button", frameName, Minimap)
		frame:SetWidth(31)
		frame:SetHeight(31)
		frame:SetFrameStrata("LOW")
		frame:SetToplevel(true)
		frame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
		frame:SetPoint("TOPLEFT", Minimap, "TOPLEFT")
		local icon = frame:CreateTexture(frameName .. "Icon", "BACKGROUND")
		icon:SetTexture(initSettings.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
		icon:SetWidth(20)
		icon:SetHeight(20)
		icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -5)
		local overlay = frame:CreateTexture(frameName .. "Overlay", "OVERLAY")
		overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
		overlay:SetWidth(53)
		overlay:SetHeight(53)
		overlay:SetPoint("TOPLEFT", frame, "TOPLEFT")

		frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		frame:SetScript("OnClick", self.OnClick)
		frame:SetScript("OnMouseDown", self.OnMouseDown)
		frame:SetScript("OnMouseUp", self.OnMouseUp)
		frame:SetScript("OnEnter", self.OnEnter)
		frame:SetScript("OnLeave", self.OnLeave)

		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", self.OnDragStart)
		frame:SetScript("OnDragStop", self.OnDragStop)

		frame.tooltipTitle = modName
		frame.leftClick = initSettings.left
		frame.rightClick = initSettings.right
		frame.tooltipText = initSettings.tooltip

		local firstUse = true
		for _ in pairs(modSettings) do
			firstUse = false
			break
		end
		if firstUse then
			modSettings.drag = initSettings.drag or "CIRCLE"
			modSettings.enabled = initSettings.enabled or 1
			modSettings.position = initSettings.position or self:GetDefaultPosition()
			modSettings.locked = initSettings.locked or nil
		end
		frame.modSettings = modSettings

		table.insert(self.Buttons, modName)
		self:SetEnable(modName, modSettings.enabled)
	end,

	SetIcon = function(self, modName, value)
		if value and _G[modName .. "MinimapButton"] then
			_G[modName .. "MinimapButtonIcon"]:SetTexture(value)
		end
	end,

	SetLeftClick = function(self, modName, value)
		if value and _G[modName .. "MinimapButton"] then
			_G[modName .. "MinimapButton"].leftClick = value
		end
	end,

	SetRightClick = function(self, modName, value)
		if value and _G[modName .. "MinimapButton"] then
			_G[modName .. "MinimapButton"].rightClick = value
		end
	end,

	SetDrag = function(self, modName, value)
		local button = _G[modName .. "MinimapButton"]
		if button and (value == "CIRCLE" or value == "SQUARE") then
			button.modSettings.drag = value
			self:Move(modName)
		end
	end,

	SetLock = function(self, modName, value)
		local button = _G[modName .. "MinimapButton"]
		if value == 0 then value = nil end
		if button then
			button.modSettings.locked = (value and 1) or nil
		end
	end,

	SetEnable = function(self, modName, value)
		local button = _G[modName .. "MinimapButton"]
		if value == 0 then value = nil end
		if button then
			button.modSettings.enabled = (value and 1) or nil
			if value then
				button:Show()
				self:Move(modName, nil, 1)
			else
				button:Hide()
			end
		end
	end,

	GetSetting = function(self, modName, setting)
		local button = _G[modName .. "MinimapButton"]
		setting = string.lower(setting or "")
		if button and button.modSettings[setting] then
			return button.modSettings[setting]
		end
	end,

	SetTooltip = function(self, modName, value)
		local button = _G[modName .. "MinimapButton"]
		if button and value then
			button.tooltipText = value
		end
	end,

	Move = function(self, modName, newPosition, force)
		local button = _G[modName .. "MinimapButton"]
		if button and (not button.modSettings.locked or force) then
			button.modSettings.position = newPosition or button.modSettings.position
			local xpos, ypos
			local angle = button.modSettings.position
			if button.modSettings.drag == "SQUARE" then
				xpos = 110 * cos(angle)
				ypos = 110 * sin(angle)
				xpos = math.max(-82, math.min(xpos, 84))
				ypos = math.max(-86, math.min(ypos, 82))
			else
				xpos = 80 * cos(angle)
				ypos = 80 * sin(angle)
			end
			button:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 54 - xpos, ypos - 54)
		end
	end,

	Debug = function(self, modName)
		DEFAULT_CHAT_FRAME:AddMessage("MyMinimapButton version = " .. self.Version)
		if modName then
			DEFAULT_CHAT_FRAME:AddMessage("Button: \"" .. modName .. "\"")
			local button = _G[modName .. "MinimapButton"]
			if button then
				DEFAULT_CHAT_FRAME:AddMessage("position = " .. tostring(button.modSettings.position))
				DEFAULT_CHAT_FRAME:AddMessage("enabled = " .. tostring(button.modSettings.enabled))
				DEFAULT_CHAT_FRAME:AddMessage("drag = " .. tostring(button.modSettings.drag))
				DEFAULT_CHAT_FRAME:AddMessage("locked = " .. tostring(button.modSettings.locked))
			else
				DEFAULT_CHAT_FRAME:AddMessage("button not defined")
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("Buttons created:")
			for i = 1, #self.Buttons do
				DEFAULT_CHAT_FRAME:AddMessage("\"" .. self.Buttons[i] .. "\"")
			end
		end
	end,

	--[[ Internal functions ]]

	GetDefaultPosition = function(self)
		local position = 0
		local found = true

		while found do
			found = false
			for i = 1, #self.Buttons do
				if _G[self.Buttons[i] .. "MinimapButton"].modSettings.position == position then
					position = position + 20
					found = true
				end
			end
			if position > 340 then break end
		end
		return position
	end,

	OnMouseDown = function(self)
		_G[self:GetName() .. "Icon"]:SetTexCoord(.1, .9, .1, .9)
	end,

	OnMouseUp = function(self)
		_G[self:GetName() .. "Icon"]:SetTexCoord(0, 1, 0, 1)
	end,

	OnEnter = function(self)
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip:AddLine(self.tooltipTitle)
		GameTooltip:AddLine(self.tooltipText, .8, .8, .8, 1)
		GameTooltip:Show()
	end,

	OnLeave = function(self)
		GameTooltip:Hide()
	end,

	OnDragStart = function(self)
		MyMinimapButton.OnMouseDown(self)
		self:LockHighlight()
		self:SetScript("OnUpdate", MyMinimapButton.OnDragUpdate)
	end,

	OnDragStop = function(self)
		self:SetScript("OnUpdate", nil)
		self:UnlockHighlight()
		MyMinimapButton.OnMouseUp(self)
	end,

	OnDragUpdate = function(self)
		local xpos, ypos = GetCursorPosition()
		local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
		xpos = xmin - xpos / Minimap:GetEffectiveScale() + 70
		ypos = ypos / Minimap:GetEffectiveScale() - ymin - 70
		self.modSettings.position = math.deg(math.atan2(ypos, xpos))
		local modName = string.gsub(self:GetName() or "", "MinimapButton$", "")
		MyMinimapButton:Move(modName)
	end,

	OnClick = function(self, button)
		if button == "LeftButton" and self.leftClick then
			self.leftClick()
		elseif button == "RightButton" and self.rightClick then
			self.rightClick()
		end
	end

  }

end
