---
-- TO-DOs
-- * Options to change clock faces
-- * New clock-face format
-- * 
local MAJOR, Addon = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon("AnalogueClock");

local GameTimeFrame,      rad,      cos,      max, PI
    = GameTimeFrame, math.rad, math.cos, math.max, PI;

local TWOPI = PI * 2;
local INVITE_PULSE_SEC = 1.0 / (2.0 * 1.0);
local TWOPI_INVITE_PULSE_SEC = TWOPI * INVITE_PULSE_SEC;
local TEXTURE_PATH = "Interface\\Addons\\AnalogueClock\\Textures\\";
local init_run = false;

local size    = 32; -- Goldwatch
local offsetx = -1;
local offsety =  1;

Addon.Frame = nil;
Addon.Initialized = false;

---
-- Hides self.
local function framehider(self)
	self:Hide();
end

function AnalogueClock_onclick(self, button)
	if button == "RightButton" then
		-- load the time manager addon
		LoadAddOn("Blizzard_TimeManager");
		TimeManager_Toggle();
	elseif button == "MiddleButton" then
		-- placeholder
	else -- left click
		GameTimeFrame_OnClick(GameTimeFrame);
	end
end

---
-- @param self (frame) usually the GameTimeFrame
local function AnalogueClock_init(gtf, ... )
	-- Create a base frame to attach all textures to
	local frame = CreateFrame("button");
	frame:SetPoint("TOPLEFT", gtf, "TOPLEFT", offsetx, offsety);
	frame:SetWidth(size);
	frame:SetHeight(size);
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp");

	-- Border
	local bg_inset = -4.2;
	Addon.ClockBackground = frame:CreateTexture(nil, "BACKGROUND");
	Addon.ClockBackground:SetTexture(TEXTURE_PATH .. "Goldwatch");
	Addon.ClockBackground:SetPoint("TOPLEFT", bg_inset, -bg_inset);
	Addon.ClockBackground:SetPoint("BOTTOMRIGHT", -bg_inset, bg_inset);

	-- Mouse-over highlight
	local highlight_inset = 0;
	Addon.ClockHighlight = frame:CreateTexture(nil, "HIGHLIGHT");
	Addon.ClockHighlight:SetPoint("TOPLEFT", -highlight_inset, highlight_inset - 1);
	Addon.ClockHighlight:SetPoint("BOTTOMRIGHT", highlight_inset, -highlight_inset - 1);
	Addon.ClockHighlight:SetTexture(gtf:GetHighlightTexture():GetTexture());
	Addon.ClockHighlight:SetBlendMode("ADD");

	-- Minute
	Addon.MinuteHand = frame:CreateTexture(nil, "OVERLAY");
	Addon.MinuteHand:SetTexture(TEXTURE_PATH .. "MinuteHand");
	Addon.MinuteHand:SetPoint("TOPLEFT", 3.5, -3.5);
	Addon.MinuteHand:SetPoint("BOTTOMRIGHT", -3.5, 3.5);

	-- Hour
	Addon.HourHand = frame:CreateTexture(nil, "OVERLAY");
	Addon.HourHand:SetTexture(TEXTURE_PATH .. "HourHand");
	Addon.HourHand:SetPoint("TOPLEFT", 3.5, -3.5);
	Addon.HourHand:SetPoint("BOTTOMRIGHT", -3.5, 3.5);
	
	--[[ No Gloss
	gtf.Gloss = frame:CreateTexture(nil, "OVERLAY");
	gtf.Gloss:SetTexture(TEXTURE_PATH.."Goldwatch_Glass");
	gtf.Gloss:SetTexCoord(0, 1, 0, 1);
	gtf.Gloss:SetPoint("CENTER", gtf, "CENTER", offsetx, offsety);
	gtf.Gloss:SetWidth(size + 20);
	gtf.Gloss:SetHeight(size + 20);
	gtf.Gloss:SetBlendMode("ADD");
	--]]

	-- adjust position of date display - TODO - Disabled for now
	if false and gtf:GetFontString() then
		local f = gtf:GetFontString();
		f:ClearAllPoints();
		f:SetPoint("CENTER", gtf, "CENTER", offsetx-1, offsety-5);
		f:SetJustifyH("CENTER");
		local ff = f:GetFont();
		f:SetFont(ff, 9);
		f:SetTextColor(1, 0, 0, 1);
	end

	frame:SetScript("OnClick" , AnalogueClock_onclick);

	init_run = true;
	return frame;
end

function AnalogueClock_onenter(self, ...)
	Addon.Backup.OnEnter(self, ...); -- run bliz function
	AnalogueClock_update(self, ...);
end

function AnalogueClock_update(self, ...)
	local hour, minute;
	if GetCVarBool("timeMgrUseLocalTime") then
		hour, minute = tonumber(date("%H")), tonumber(date("%M"));
	else
		hour, minute = GetGameTime();
	end
	Addon.HourHand:SetRotation(-rad(hour*30 + minute/2));
	Addon.MinuteHand:SetRotation(-rad(minute*6));
	
	local GameTooltip = GameTooltip;
	if ( GameTooltip:IsOwned(self) ) then
		GameTooltip:ClearLines();
		if ( GameTimeCalendarInvitesTexture:IsShown() ) then
			GameTooltip:AddLine(GAMETIME_TOOLTIP_CALENDAR_INVITES);
			GameTooltip:AddLine(" ");
		end
		GameTime_UpdateTooltip();
		GameTooltip:AddDoubleLine("Local date:", date("%B %d, %Y"), nil,nil,nil,1,1,1);
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(GAMETIME_TOOLTIP_TOGGLE_CALENDAR);
		GameTooltip:AddLine("Right-"..GAMETIME_TOOLTIP_TOGGLE_CLOCK);
		GameTooltip:Show();
	end
end

local DT, flashTimer = 0, 0;
function AnalogueClock_onupdate(self, dt)
	DT = DT + dt;
	
	if DT > 20 then
		AnalogueClock_update(self);
		DT = 0;
	end

	-- Flashing stuff
	if GameTimeFrame.flashInvite then
		local flashIndex = TWOPI_INVITE_PULSE_SEC * self.flashTimer;
		local flashValue = 0.55 + 0.4 * cos(flashIndex);
		if ( flashIndex >= TWOPI ) then
			self.flashTimer = 0.0;
		else
			self.flashTimer = self.flashTimer + dt;
		end

		GameTimeCalendarInvitesTexture:SetAlpha(flashValue);
		GameTimeCalendarInvitesGlow:SetAlpha(flashValue);
	end
end

function Addon:OnInitialize()
	self.Frame = AnalogueClock_init(GameTimeFrame);
end

---
-- AceAddon on-enable handler
function Addon:OnEnable()
	if not init_run then
		AnalogueClock_init(GameTimeFrame);
	end

	local gtf, backup = GameTimeFrame, {};
	self.Backup = backup;

	-- Backup current status
	--
	backup.PushedTexture = gtf:GetPushedTexture();
	backup.NormalTexture = gtf:GetNormalTexture();
	backup.HighTexture   = gtf:GetHighlightTexture();
	backup.OnEnter       = gtf:GetScript("OnEnter");
	backup.OnClick       = gtf:GetScript("OnClick");
	backup.OnUpdate      = gtf:GetScript("OnUpdate");
	backup.TMOnShow      = TimeManagerClockButton:GetScript("OnShow");

	-- MODIFY

	-- TODO: No idea how to undo, just hide and create own.
	GameTimeCalendarInvitesGlow:SetDrawLayer("BACKGROUND");
	GameTimeCalendarInvitesGlow:ClearAllPoints();
	GameTimeCalendarInvitesGlow:SetPoint("CENTER", gtf, "CENTER", offsetx+1, offsety+1);
	GameTimeCalendarInvitesGlow:SetWidth(size + 25);
	GameTimeCalendarInvitesGlow:SetHeight(size + 25);
	GameTimeCalendarInvitesTexture:SetDrawLayer("OVERLAY");
	
	--gtf:SetPushedTexture(nil);
	--gtf:SetNormalTexture(self.ClockBackground);
	--gtf:SetHighlightTexture(self.ClockHighlight);

	gtf:SetScript("OnEnter" , AnalogueClock_onenter);
	gtf:SetScript("OnUpdate", AnalogueClock_onupdate);
	gtf:SetScript("OnClick" , AnalogueClock_onclick);

	gtf.DisableAnalogueClock = function() return self:Disable(); end
	
	AnalogueClock_update(gtf);

	-- Hide the Blizzard digital clock and calendar frames
	GameTimeFrame:HookScript("OnShow", framehider);
	GameTimeFrame:Hide();
	TimeManagerClockButton:HookScript("OnShow", framehider);
	TimeManagerClockButton:Hide();

	--@alpha@
	print("|cFF00AA00AnalogueClock|r: This is an |cFFFF0000Alpha|r release. "..
		"Expect some bugs, especially in combination with other add-ons! Get "..
		"the |cFF00AA00Release|r version if you don't want to be bothered by "..
		"these.");
	--@end-alpha@
end

---
-- AceAddon on-disable handler
function Addon:OnDisable()
	GameTimeFrame.DisableAnalogueClock = nil;
end
