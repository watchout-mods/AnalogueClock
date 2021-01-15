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

local AnalogueClock_onclick, AnalogueClock_init, AnalogueClock_update, AnalogueClock_onenter,
	AnalogueClock_onupdate;

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
function AnalogueClock_init(parent, gtf, gtcig, gtcio, ... )
	-- Create a base frame to attach all textures to
	local frame = CreateFrame("button", "AnalogueClock", parent);
	frame:SetPoint("TOPLEFT", gtf, "TOPLEFT", offsetx, offsety);
	frame:SetWidth(size);
	frame:SetHeight(size);
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp");

	-- Border
	local bg_inset = -4.2;
	Addon.ClockBackground = frame:CreateTexture(nil, "BORDER");
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
	Addon.MinuteHand = frame:CreateTexture(nil, "ARTWORK");
	Addon.MinuteHand:SetTexture(TEXTURE_PATH .. "MinuteHand");
	Addon.MinuteHand:SetPoint("TOPLEFT", 3.5, -3.5);
	Addon.MinuteHand:SetPoint("BOTTOMRIGHT", -3.5, 3.5);

	-- Hour
	Addon.HourHand = frame:CreateTexture(nil, "ARTWORK");
	Addon.HourHand:SetTexture(TEXTURE_PATH .. "HourHand");
	Addon.HourHand:SetPoint("TOPLEFT", 3.5, -3.5);
	Addon.HourHand:SetPoint("BOTTOMRIGHT", -3.5, 3.5);

	do -- Invite glow
		local inset, ox, oy  = -10, 0.75, 0.5;
		frame._InviteGlow = frame:CreateTexture(nil, "BACKGROUND");
		frame._InviteGlow:SetTexture(gtcig:GetTexture());
		frame._InviteGlow:SetPoint("TOPLEFT", inset + ox, -inset + oy);
		frame._InviteGlow:SetPoint("BOTTOMRIGHT", -inset + ox, inset + oy);
		frame._InviteGlow:SetBlendMode("ADD");
	end

	do -- Invite overlay
		local inset, ox, oy  = -0, 6, -1;
		frame._InviteOverlay = frame:CreateTexture(nil, "OVERLAY");
		frame._InviteOverlay:SetTexture(gtcio:GetTexture());
		frame._InviteOverlay:SetPoint("TOPLEFT", inset + ox, -inset + oy);
		frame._InviteOverlay:SetPoint("BOTTOMRIGHT", -inset + ox, inset + oy);
	end

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

	frame:SetScript("OnClick", AnalogueClock_onclick);
	frame:SetScript("OnEnter", AnalogueClock_onenter);
	frame:SetScript("OnUpdate", AnalogueClock_onupdate);

	init_run = true;
	return frame;
end

function AnalogueClock_onenter(self, ...)
	GameTimeFrame:GetScript("OnEnter")(self, ...); -- run bliz function
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

local DT, FlashTimer, IsFlashing = 0, 0, true;
function AnalogueClock_onupdate(self, dt)
	DT = DT + dt;
	
	if DT > 20 then
		AnalogueClock_update(self);
		DT = 0;
	end

	-- Flashing stuff
	if GameTimeFrame.flashInvite then
		local flashIndex = TWOPI_INVITE_PULSE_SEC * FlashTimer;
		local flashValue = 0.55 + 0.4 * cos(flashIndex);
		if ( flashIndex >= TWOPI ) then
			FlashTimer = 0.0;
		else
			FlashTimer = FlashTimer + dt;
		end

		self._InviteGlow:SetAlpha(flashValue);
		self._InviteOverlay:SetAlpha(flashValue);
		IsFlashing = true;
	elseif IsFlashing then
		self._InviteGlow:SetAlpha(0);
		self._InviteOverlay:SetAlpha(0);
		IsFlashing = false;
	end
end

function Addon:OnInitialize()
	-- Cannot init frame here because Blizzard frames may not be loaded yet.
end

---
-- AceAddon on-enable handler
function Addon:OnEnable()
	if not init_run then
		self.Frame = AnalogueClock_init(MinimapCluster, GameTimeFrame, GameTimeCalendarInvitesGlow,
			GameTimeCalendarInvitesTexture);

		MinimapCluster.DisableAnalogueClock = function() return self:Disable(); end
	end

	AnalogueClock_update(self.Frame);

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
