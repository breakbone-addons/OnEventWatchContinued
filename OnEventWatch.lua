--[[ OnEventWatch 1.3 (BCC update)

	This profiling tool estimates how long OnEvents take to run by frame.

	__ New in 1.3 __
	- Updated for Burning Crusade Classic (Interface 20505)
	- Replaced deprecated `this`, `event`, `arg1` implicit globals
	- Replaced getglobal/table.getn/table.setn with modern equivalents
	- Added BackdropTemplate support
	- Fixed FauxScrollFrame_OnVerticalScroll signature

	When you first do /onevent, it enumerates all frames and notes those with an OnEvent handler.
	It wraps those OnEvent handlers with a debugprofilestart()/debugprofilestop() to estimate
	the time it took to run.  Due to the microscopic times involved, the estimate should be
	taken as a comparative guide and not a definitive measurement.

	All further /onevent will toggle the event tracking window.  This window displays a list of
	all frames that have had events happened, the events that occured and an estimated total and
	average processing time.  You can search by frame name, by event name, and sort the columns
	by clicking on their headers.  The buttons on the bottom should be self explainatory.

	This mod is meant for infrequent use and has no hooks or frames registered until you do /onevent.
	Once done, hit the Reset button twice to Reload the UI and remove all hooks.

	As with all profiling mods, do not use this as a sole meter for mod performance.  There are
	many, many other things going on in a mod.  OnClicks, OnUpdates, OnEnter, etc can all
	contribute significantly to a mod's processing time.

	This mod can't identify what mod owns a frame, nor can it detect dynamic/on-demand frames
	created after /onevent is first run.  It will pick up anonymous frames and give them the
	name 'anonymous#'.

	The minimap button serves two purposes: As a reminder that OnEventWatch is running, and as a
	convenient way to toggle the list without a slash command.  If you'd rather not have it, you
	can delete the MyMinimapButton.lua file and it won't be created.
]]


OnEventWatch = {
	FrameList = {},		-- list of frames indexed numerically {frame,name}
	OrderedList = {},	-- list of frames+events indexed numerically (frame,event,count,time}
	Watching = nil,		-- whether we have enumerated frames and are watching yet
	SortBy = 1,			-- 1=frame, 2=event, 3=count, 4=time, 5=avg
	FrameSearch = "",	-- frame name search or "" for all
	EventSearch = "",	-- event name search or "" for all
}

OnEventWatch_Settings = {}

local list = OnEventWatch.FrameList
local MAXTIME = 1000 -- time (in milliseconds) before tossing out events

SlashCmdList["ONEVENTWATCH"] = function(msg)
	if not OnEventWatch.Watching then
		local f = EnumerateFrames()
		local anon = 0
		while f do
			f = EnumerateFrames(f)
			if f and f.GetName and f:GetName() and f:GetScript("OnEvent") then
				table.insert(list, {frame = f, name = f:GetName()})
				f.old = f:GetScript("OnEvent")
				f.events = {}
				f:SetScript("OnEvent", OnEventWatch.HookedOnEvent)
			elseif f and f.GetName and f:GetScript("OnEvent") then
				table.insert(list, {frame = f, name = "anonymous" .. anon})
				f.old = f:GetScript("OnEvent")
				f.events = {}
				f:SetScript("OnEvent", OnEventWatch.HookedOnEvent)
				anon = anon + 1
			end
		end
		OnEventWatch.Watching = 1
		DEFAULT_CHAT_FRAME:AddMessage(#list .. " frames have an OnEvent.")
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Now watching OnEvents. /onevent will now toggle event tracking window.")
		DEFAULT_CHAT_FRAME:AddMessage("NOTE: This only watches OnEvents.  There is much more happening in mods beyond OnEvent.  Do not use this or any tool as the sole meter to mod performance.")
		if MyMinimapButton then
			MyMinimapButton:Create("OnEventWatch", OnEventWatch_Settings)
			MyMinimapButton:SetIcon("OnEventWatch", "Interface\\Icons\\INV_Misc_Spyglass_03")
			MyMinimapButton:SetLeftClick("OnEventWatch", SlashCmdList["ONEVENTWATCH"])
			MyMinimapButton:SetRightClick("OnEventWatch", SlashCmdList["ONEVENTWATCH"])
		end
	else
		if OnEventWatchFrame:IsVisible() then
			OnEventWatchFrame:Hide()
		else
			OnEventWatch.OrderList()
			OnEventWatchFrame:Show()
		end
	end
end
SLASH_ONEVENTWATCH1 = "/onevent"

-- wrapper to all OnEvents
function OnEventWatch.HookedOnEvent(frame, eventName, ...)
	if eventName then
		if not frame.events[eventName] then
			frame.events[eventName] = { count = 0, time = 0 }
		end
	end
	local memory = gcinfo()
	debugprofilestart()
	if frame.old then
		frame.old(frame, eventName, ...)
	end
	local stopTime = debugprofilestop()
	if eventName and gcinfo() >= memory and stopTime < MAXTIME then
		frame.events[eventName].time = frame.events[eventName].time + stopTime
		frame.events[eventName].count = frame.events[eventName].count + 1
	end
end

-- sortBy=1-5 which field to change sort to, dontReset=1/nil whether to not return to top of list
function OnEventWatch.OrderList(sortBy, dontReset)
	OnEventWatch.SortBy = sortBy or OnEventWatch.SortBy
	local order = OnEventWatch.OrderedList

	-- nil entries but not tables, to avoid garbage creation
	for i = 1, #order do
		order[i].event = nil
		order[i].frame = nil
		order[i].count = nil
		order[i].time = nil
	end

	local orderIndex = 1
	for i = 1, #list do
		for j, _ in pairs(list[i].frame.events) do
			if string.find(list[i].name or "", OnEventWatch.FrameSearch) and string.find(j, OnEventWatch.EventSearch) then
				list[i].frame.events[j].count = max(1, list[i].frame.events[j].count)
				if not order[orderIndex] then
					order[orderIndex] = {}
				end
				order[orderIndex].frame = list[i].name
				order[orderIndex].event = j
				order[orderIndex].count = list[i].frame.events[j].count
				order[orderIndex].time = list[i].frame.events[j].time
				orderIndex = orderIndex + 1
			end
		end
	end

	-- Trim the ordered list to current size (replaces table.setn)
	for i = orderIndex, #order do
		order[i] = nil
	end

	if OnEventWatch.SortBy == 1 then
		table.sort(order, function(e1, e2) if e1 and e2 then return e1.frame < e2.frame end return false end)
	elseif OnEventWatch.SortBy == 2 then
		table.sort(order, function(e1, e2) if e1 and e2 then return e1.event < e2.event end return false end)
	elseif OnEventWatch.SortBy == 3 then
		table.sort(order, function(e1, e2) if e1 and e2 then return e1.count > e2.count end return false end)
	elseif OnEventWatch.SortBy == 4 then
		table.sort(order, function(e1, e2) if e1 and e2 then return e1.time > e2.time end return false end)
	elseif OnEventWatch.SortBy == 5 then
		table.sort(order, function(e1, e2) if e1 and e2 then return (e1.time / e1.count) > (e2.time / e2.count) end return false end)
	end

	if not dontReset then
		OnEventWatchScrollFrameScrollBar:SetValue(0)
	end
	OnEventWatch.ScrollFrameUpdate()
end

local function formattime(number)
	if number < .001 then
		return string.format("%1.2fns", number * 1000000)
	elseif number < .1 then
		return string.format("%1.2f\194\181s", number * 1000)
	elseif number < 1000 then
		return string.format("%1.2fms", number)
	elseif number < 1000000 then
		return string.format("%1.2fsec", number / 1000)
	else
		return string.format("%1.2fmin", number / 1000 / 60)
	end
end

function OnEventWatch.ScrollFrameUpdate()
	local offset = FauxScrollFrame_GetOffset(OnEventWatchScrollFrame)
	local watch = OnEventWatch.OrderedList
	FauxScrollFrame_Update(OnEventWatchScrollFrame, #watch, 20, 16)
	for i = 1, 20 do
		local idx = offset + i
		if idx <= #watch then
			_G["OnEventWatchEntry" .. i .. "Frame"]:SetText(watch[idx].frame)
			_G["OnEventWatchEntry" .. i .. "Event"]:SetText(watch[idx].event)
			_G["OnEventWatchEntry" .. i .. "Count"]:SetText(watch[idx].count)
			_G["OnEventWatchEntry" .. i .. "Time"]:SetText(formattime(watch[idx].time))
			_G["OnEventWatchEntry" .. i .. "AvgTime"]:SetText(formattime(watch[idx].time / watch[idx].count))
			_G["OnEventWatchEntry" .. i]:Show()
		else
			_G["OnEventWatchEntry" .. i]:Hide()
		end
	end
end

-- pressing enter in an editbox updates list by search criteria
function OnEventWatch.OnEnterPressed()
	OnEventWatch.FrameSearch = OnEventWatchFrameSearch:GetText() or ""
	OnEventWatch.EventSearch = OnEventWatchEventSearch:GetText() or ""
	OnEventWatch.OrderList()
end

-- onclick for all buttons along bottom
function OnEventWatch.OnButtonClick(self)
	local id = self:GetID()
	if id == 1 then -- "All"
		OnEventWatchFrameSearch:SetText("")
		OnEventWatchEventSearch:SetText("")
	elseif id == 2 then -- "Reset"
		for i = 1, #list do
			list[i].frame.events = {}
		end
	elseif id == 3 then -- "Stop"
		StaticPopupDialogs["ONEVENTWATCH"] = {
			text = "OnEventWatch will reload the UI to remove all active hooks.\n\nDo you want to reload the UI now?",
			button1 = "Yes", button2 = "No", showAlert = 1, timeout = 0, whileDead = 1, OnAccept = ReloadUI
		}
		StaticPopup_Show("ONEVENTWATCH")
	elseif id == 4 then -- "Ok"
		OnEventWatchFrame:Hide()
		return
	end
	OnEventWatch.OnEnterPressed()
end

-- updates list every .33 seconds while list is shown
function OnEventWatch.OnUpdate(self, elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer > .33 then
		self.timer = 0
		OnEventWatch.OrderList(nil, 1)
	end
end

-- if shift key is down, "link" clicked event to chat edit box
function OnEventWatch.EventOnClick(self)
	if IsShiftKeyDown() then
		local idx = FauxScrollFrame_GetOffset(OnEventWatchScrollFrame) + self:GetID()
		local watch = OnEventWatch.OrderedList
		local editBox = ChatFrame1EditBox or (ChatFrame1 and ChatFrame1.editBox)
		if idx <= #watch and editBox and editBox:IsVisible() then
			editBox:Insert(string.format("frame:%s event:%s count:%s time:%s avg:%s",
				watch[idx].frame, watch[idx].event, watch[idx].count,
				formattime(watch[idx].time), formattime(watch[idx].time / watch[idx].count)))
		end
	end
end

-- Header click handler
function OnEventWatch.OnHeaderClick(self)
	OnEventWatch.OrderList(self:GetID())
end
