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
local tpath = "Interface\\Addons\\AnalogueClock\\Textures\\";
local init_run = false;

local size    = 32; -- Goldwatch
local offsetx = -1;
local offsety =  1;

---
-- Hides the Blizzard digital clock.
local function blizclockhider(self)
	self:Hide();
end

---
-- @param self (frame) usually the GameTimeFrame
local function AnalogueClock_init(self, ... )
	-- Use existing bg-texture if possible and just adjust the view
	Addon.ClockBackground = self:CreateTexture(nil, "BACKGROUND");
	Addon.ClockBackground:SetTexture(tpath.."Goldwatch")
	Addon.ClockBackground:SetTexCoord(0, 1, 0, 1);
	Addon.ClockBackground:ClearAllPoints();
	Addon.ClockBackground:SetPoint("CENTER", self, "CENTER", offsetx, offsety);
	Addon.ClockBackground:SetWidth(size + 20);
	Addon.ClockBackground:SetHeight(size + 20);
	Addon.ClockBackground:SetDrawLayer("BACKGROUND");
	
	-- Use existing highlight-texture if possible and just adjust the view
	Addon.ClockHighlight = self:CreateTexture(nil, "HIGHLIGHT");
	Addon.ClockHighlight:ClearAllPoints();
	Addon.ClockHighlight:SetPoint("CENTER", self, "CENTER", offsetx, offsety);
	Addon.ClockHighlight:SetWidth(size + 10);
	Addon.ClockHighlight:SetHeight(size + 10);
	Addon.ClockHighlight:SetTexture(self:GetHighlightTexture():GetTexture());
	
	Addon.MinuteHand = self:CreateTexture(nil, "OVERLAY");
	Addon.MinuteHand:SetTexture(tpath.."MinuteHand");
	Addon.MinuteHand:SetPoint("CENTER", self, "CENTER", offsetx, offsety);
	Addon.MinuteHand:SetWidth(size + 5);
	Addon.MinuteHand:SetHeight(size + 5);
	
	Addon.HourHand = self:CreateTexture(nil, "OVERLAY");
	Addon.HourHand:SetTexture(tpath.."HourHand");
	Addon.HourHand:SetPoint("CENTER", self, "CENTER", offsetx, offsety);
	Addon.HourHand:SetWidth(size + 5);
	Addon.HourHand:SetHeight(size + 5);
	
	--[[ No Gloss
	self.Gloss = self:CreateTexture(nil, "OVERLAY");
	self.Gloss:SetTexture(tpath.."Goldwatch_Glass");
	self.Gloss:SetTexCoord(0, 1, 0, 1);
	self.Gloss:SetPoint("CENTER", self, "CENTER", offsetx, offsety);
	self.Gloss:SetWidth(size + 20);
	self.Gloss:SetHeight(size + 20);
	self.Gloss:SetBlendMode("ADD");
	--]]
	
	-- adjust position of date display - TODO - Disabled for now
	if false and self:GetFontString() then
		local f = self:GetFontString();
		f:ClearAllPoints();
		f:SetPoint("CENTER", self, "CENTER", offsetx-1, offsety-5);
		f:SetJustifyH("CENTER");
		local ff = f:GetFont();
		f:SetFont(ff, 9);
		f:SetTextColor(1, 0, 0, 1);
	end

	init_run = true;
end

function AnalogueClock_onclick(self, button)
	if button == "RightButton" then
		-- load the time manager addon
		LoadAddOn("Blizzard_TimeManager");
		TimeManager_Toggle();
	elseif button == "MiddleButton" then
		-- placeholder
	else -- left click
		GameTimeFrame_OnClick(self);
	end
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

local DT, flashTimer = 0,0;
function AnalogueClock_onupdate(self, dt)
	DT = DT+dt;
	
	if DT > 20 then
		AnalogueClock_update(self);
		DT = 0;
	end

	-- Flashing stuff
	if GameTimeFrame.flashInvite then
		local flashIndex = TWOPI_INVITE_PULSE_SEC * self.flashTimer;
		local flashValue = 0.55 + 0.4*cos(flashIndex);
		if ( flashIndex >= TWOPI ) then
			self.flashTimer = 0.0;
		else
			self.flashTimer = self.flashTimer + dt;
		end

		GameTimeCalendarInvitesTexture:SetAlpha(flashValue);
		GameTimeCalendarInvitesGlow:SetAlpha(flashValue);
	end
end

---
-- AceAddon on-disable handler
function Addon:OnDisable()
	local self, this, backup = GameTimeFrame, self, {};
	self.DisableAnalogueClock = nil;
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
	
	gtf:SetPushedTexture(nil);
	gtf:SetNormalTexture(self.ClockBackground);
	gtf:SetHighlightTexture(self.ClockHighlight);

	gtf:SetScript("OnEnter" , AnalogueClock_onenter);
	gtf:SetScript("OnUpdate", AnalogueClock_onupdate);
	gtf:SetScript("OnClick" , AnalogueClock_onclick);

	gtf.DisableAnalogueClock = function() return self:Disable(); end
	
	AnalogueClock_update(gtf);
	
	-- Hide the Blizzard digital clock
	TimeManagerClockButton:HookScript("OnShow", blizclockhider);
	TimeManagerClockButton:Hide();

	--@alpha@
	print("|cFF00AA00AnalogueClock|r: This is an |cFFFF0000Alpha|r release. "..
		"Expect some bugs, especially in combination with other add-ons! Get "..
		"the |cFF00AA00Release|r version if you don't want to be bothered by "..
		"these.");
	--@end-alpha@
end
