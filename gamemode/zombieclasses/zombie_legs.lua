CLASS.Name = "Zombie Legs"
CLASS.TranslationName = "class_zombie_legs"
CLASS.Description = "description_zombie_legs"

CLASS.Model = Model("models/player/zombie_classic.mdl")
CLASS.OverrideModel = Model("models/Zombie/Classic_legs.mdl")
CLASS.NoHead = true

CLASS.Wave = 0
CLASS.Threshold = 0
CLASS.Unlocked = true
CLASS.Hidden = true

CLASS.Health = 100
CLASS.Speed = 170
CLASS.JumpPower = 250

CLASS.CanTaunt = true

CLASS.Points = CLASS.Health/GM.LegsZombiePointRatio

CLASS.Hull = {Vector(-16, -16, 0), Vector(16, 16, 32)}
CLASS.HullDuck = {Vector(-16, -16, 0), Vector(16, 16, 32)}
CLASS.ViewOffset = Vector(0, 0, 32)
CLASS.ViewOffsetDucked = Vector(0, 0, 32)
CLASS.Mass = DEFAULT_MASS * 0.5
CLASS.CrouchedWalkSpeed = 1

CLASS.CantDuck = true

CLASS.CanFeignDeath = true

CLASS.VoicePitch = 0.65

CLASS.SWEP = "weapon_zs_zombielegs"

CLASS.BloodColor = -1

local math_random = math.random
local math_min = math.min
local math_max = math.max

local HITGROUP_LEFTLEG = HITGROUP_LEFTLEG
local HITGROUP_RIGHTLEG = HITGROUP_RIGHTLEG
local HITGROUP_GEAR = HITGROUP_GEAR
local HITGROUP_GENERIC = HITGROUP_GENERIC
local DIR_BACK = DIR_BACK
local CurTime = CurTime

local STEPSOUNDTIME_NORMAL = STEPSOUNDTIME_NORMAL
local STEPSOUNDTIME_WATER_FOOT = STEPSOUNDTIME_WATER_FOOT
local STEPSOUNDTIME_ON_LADDER = STEPSOUNDTIME_ON_LADDER
local STEPSOUNDTIME_WATER_KNEE = STEPSOUNDTIME_WATER_KNEE
local ACT_HL2MP_ZOMBIE_SLUMP_RISE = ACT_HL2MP_ZOMBIE_SLUMP_RISE
local ACT_HL2MP_IDLE_ZOMBIE = ACT_HL2MP_IDLE_ZOMBIE
local ACT_HL2MP_RUN_ZOMBIE = ACT_HL2MP_RUN_ZOMBIE

local g_tbl = {
	[1] = STEPSOUNDTIME_NORMAL,
	[2] = STEPSOUNDTIME_WATER_FOOT,
	[3] = STEPSOUNDTIME_ON_LADDER,
	[4] = STEPSOUNDTIME_WATER_KNEE,
	[5] = ACT_HL2MP_ZOMBIE_SLUMP_RISE,
	[6] = ACT_HL2MP_IDLE_ZOMBIE,
	[7] = ACT_HL2MP_RUN_ZOMBIE
}
function CLASS:DoesntGiveFear(pl)
	return pl.FeignDeath and pl.FeignDeath:IsValid()
end

function CLASS:ScalePlayerDamage(pl, hitgroup, dmginfo)
	if not dmginfo:IsBulletDamage() then return true end

	if hitgroup ~= HITGROUP_LEFTLEG and hitgroup ~= HITGROUP_RIGHTLEG and hitgroup ~= HITGROUP_GEAR and hitgroup ~= HITGROUP_GENERIC and dmginfo:GetDamagePosition().z > pl:LocalToWorld(Vector(0, 0, self.Hull[2].z * 1.33)).z then
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
	end

	return true
end

function CLASS:ShouldDrawLocalPlayer(pl)
	return true
end

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	if iFoot == 0 then
		pl:EmitSound("npc/zombie/foot1.wav", 70)
	else
		pl:EmitSound("npc/zombie/foot2.wav", 70)
	end

	return true
end

function CLASS:PlayerStepSoundTime(pl, iType, bWalking)
	local switch = {
		[g_tbl[1]] = function(pl) return 625 - pl:GetVelocity():Length() end,
		[g_tbl[2]] = function(pl) return 625 - pl:GetVelocity():Length() end,
		[g_tbl[3]] = function(pl) return 600 end,
		[g_tbl[4]] = function(pl) return 750 end
	}

	return switch[iType] and switch[iType](pl) or 450
end

function CLASS:CalcMainActivity(pl, velocity)
	local feign = pl.FeignDeath
	if feign and feign:IsValid() then
		return g_tbl[5], -1
	end

	if velocity:Length2DSqr() <= 1 then
		return g_tbl[6], -1
	end

	return g_tbl[7], -1
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local feign = pl.FeignDeath
	if feign and feign:IsValid() then
		if feign:GetState() == 1 then
			pl:SetCycle(1 - math_max(feign:GetStateEndTime() - CurTime(), 0) * 0.666)
		else
			pl:SetCycle(math_max(feign:GetStateEndTime() - CurTime(), 0) * 0.666)
		end
		pl:SetPlaybackRate(0)

		return true
	end

	local len2d = velocity:Length2D()
	if len2d > 1 then
		pl:SetPlaybackRate(math_min(len2d / maxseqgroundspeed * 0.75, 3))
	else
		pl:SetPlaybackRate(1)
	end

	return true
end

if SERVER then
	function CLASS:AltUse(pl)
		pl:StartFeignDeath()
	end

	function CLASS:IgnoreLegDamage(pl, dmginfo)
		return true
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/legs"
local math_Clamp = math.Clamp
local math_Approach = math.Approach

local render_EnableClipping = render.EnableClipping
local render_PushCustomClipPlane = render.PushCustomClipPlane
local render_PopCustomClipPlane = render.PopCustomClipPlane

-- This whole point of this is to stop drawing decals on the upper part of the model. It doesn't actually do anything to the visible model.
local undo = false
function CLASS:PrePlayerDraw(pl)
	local boneid = pl:LookupBone("ValveBiped.Bip01_Spine")
	if boneid and boneid > 0 then
		local pos, ang = pl:GetBonePosition(boneid)
		if pos then
			local normal = ang:Forward() * -1
			render_EnableClipping(true)
			render_PushCustomClipPlane(normal, normal:Dot(pos))
			undo = true
		end
	end
end

function CLASS:PostPlayerDraw(pl)
	if undo then
		render_PopCustomClipPlane()
		render_EnableClipping(false)
	end
end

function CLASS:BuildBonePositions(pl)
	local desired

	local bone = "ValveBiped.Bip01_L_Thigh"

	local wep = pl:GetActiveWeapon()
	if wep:IsValid() then
		if wep.GetSwingEndTime and wep:GetSwingEndTime() > 0 then
			desired = 1 - math_Clamp((wep:GetSwingEndTime() - CurTime()) / wep.MeleeDelay, 0, 1)
		end

		if wep:GetDTBool(3) then
			bone = "ValveBiped.Bip01_R_Thigh"
		end
	end

	desired = desired or 0

	if desired > 0 then
		pl.m_KickDelta = CosineInterpolation(0, 1, desired)
	else
		pl.m_KickDelta = math_Approach(pl.m_KickDelta or 0, desired, FrameTime() * 4)
	end

	local boneid = pl:LookupBone(bone)
	if boneid and boneid > 0 then
		pl:ManipulateBoneAngles(boneid, pl.m_KickDelta * Angle(bone == "ValveBiped.Bip01_L_Thigh" and 0 or 20, -110, 30))
	end
end
