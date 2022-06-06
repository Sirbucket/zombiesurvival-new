CLASS.Name = "Fast Zombie"
CLASS.TranslationName = "class_fast_zombie"
CLASS.Description = "description_fast_zombie"
CLASS.Help = "controls_fast_zombie"

CLASS.BetterVersion = "Lacerator"

CLASS.Model = Model("models/player/zombie_fast.mdl")

CLASS.Wave = 3 / 6
CLASS.Infliction = 0.5 -- We auto-unlock this class if 50% of humans are dead regardless of what wave it is.
CLASS.Revives = true

CLASS.Health = 150
CLASS.Speed = 255
CLASS.SWEP = "weapon_zs_fastzombie"

CLASS.Points = CLASS.Health/GM.NoHeadboxZombiePointRatio

CLASS.CanTaunt = true

CLASS.Hull = {Vector(-16, -16, 0), Vector(16, 16, 58)}
CLASS.HullDuck = {Vector(-16, -16, 0), Vector(16, 16, 32)}
CLASS.ViewOffset = Vector(0, 0, 50)
CLASS.ViewOffsetDucked = Vector(0, 0, 24)

CLASS.PainSounds = {"NPC_FastZombie.Pain"}
CLASS.DeathSounds = {"npc/fast_zombie/leap1.wav"} --{"NPC_FastZombie.Die"}

CLASS.VoicePitch = 0.75

CLASS.NoFallDamage = true
CLASS.NoFallSlowdown = true

local math_random = math.random
local math_min = math.min
local math_Clamp = math.Clamp
local CurTime = CurTime

local STEPSOUNDTIME_NORMAL = STEPSOUNDTIME_NORMAL
local STEPSOUNDTIME_WATER_FOOT = STEPSOUNDTIME_WATER_FOOT
local STEPSOUNDTIME_ON_LADDER = STEPSOUNDTIME_ON_LADDER
local STEPSOUNDTIME_WATER_KNEE = STEPSOUNDTIME_WATER_KNEE
local ACT_ZOMBIE_CLIMB_UP = ACT_ZOMBIE_CLIMB_UP
local ACT_ZOMBIE_LEAP_START = ACT_ZOMBIE_LEAP_START
local ACT_ZOMBIE_LEAPING = ACT_ZOMBIE_LEAPING
local ACT_HL2MP_RUN_ZOMBIE = ACT_HL2MP_RUN_ZOMBIE
local ACT_HL2MP_RUN_ZOMBIE_FAST = ACT_HL2MP_RUN_ZOMBIE_FAST
local ACT_HL2MP_IDLE_CROUCH_ZOMBIE = ACT_HL2MP_IDLE_CROUCH_ZOMBIE
local ACT_HL2MP_WALK_CROUCH_ZOMBIE_01 = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
local ACT_GMOD_GESTURE_RANGE_FRENZY = ACT_GMOD_GESTURE_RANGE_FRENZY
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local PLAYERANIMEVENT_RELOAD = PLAYERANIMEVENT_RELOAD
local ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL
local ACT_INVALID = ACT_INVALID

local g_tbl = {
	[1] = STEPSOUNDTIME_NORMAL,
	[2] = STEPSOUNDTIME_WATER_FOOT,
	[3] = STEPSOUNDTIME_ON_LADDER,
	[4] = STEPSOUNDTIME_WATER_KNEE,
	[5] = ACT_ZOMBIE_CLIMB_UP,
	[6] = ACT_ZOMBIE_LEAP_START,
	[7] = ACT_ZOMBIE_LEAPING,
	[8] = ACT_HL2MP_RUN_ZOMBIE,
	[9] = ACT_HL2MP_RUN_ZOMBIE_FAST,
	[10] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[11] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01,
	[12] = ACT_GMOD_GESTURE_RANGE_FRENZY,
	[13] = GESTURE_SLOT_ATTACK_AND_RELOAD,
	[14] = PLAYERANIMEVENT_ATTACK_PRIMARY,
	[15] = PLAYERANIMEVENT_RELOAD,
	[16] = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL,
	[17] = ACT_INVALID
}

function CLASS:Move(pl, mv)
	local wep = pl:GetActiveWeapon()
	if wep.Move and wep:Move(mv) then
		return true
	end

	if mv:GetForwardSpeed() <= 0 then
		mv:SetMaxSpeed(math_min(mv:GetMaxSpeed(), 90))
		mv:SetMaxClientSpeed(math_min(mv:GetMaxClientSpeed(), 90))
	end
end

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	if iFoot == 0 then
		pl:EmitSound("npc/fast_zombie/foot1.wav", 70)
	else
		pl:EmitSound("npc/fast_zombie/foot3.wav", 70)
	end

	return true
end

function CLASS:PlayerStepSoundTime(pl, iType, bWalking)
	local switch = {
		[g_tbl[1]] = function(pl) return 450 - pl:GetVelocity():Length() end,
		[g_tbl[2]] = function(pl) return 450 - pl:GetVelocity():Length() end,
		[g_tbl[3]] = function(pl) return 400 end, 
		[g_tbl[4]] = function(pl) return 550 end
	}

	return switch[iType] and switch[iType](pl) or 250
end

function CLASS:ScalePlayerDamage(pl, hitgroup, dmginfo)
	return true
end

function CLASS:IgnoreLegDamage(pl, dmginfo)
	return true
end

function CLASS:CalcMainActivity(pl, velocity)
	local wep = pl:GetActiveWeapon()
	if not wep:IsValid() or not wep.GetClimbing or not wep.GetPounceTime then return end

	if wep:GetClimbing() then
		return g_tbl[5], -1
	end

	if wep:GetPounceTime() > 0 then
		return g_tbl[6], -1
	end

	if not pl:OnGround() or pl:WaterLevel() >= 3 then
		return g_tbl[7], -1
	end

	local speed = velocity:Length2DSqr()

	if speed <= 1 and wep:IsRoaring() then
		return 1, pl:LookupSequence("menu_zombie_01")
	end

	if speed > 256 and wep:GetSwinging() then --16^2
		return g_tbl[8], -1
	end

	if pl:Crouching() then
		return speed <= 1 and g_tbl[10] or g_tbl[11], -1
	end

	return g_tbl[9], -1
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local wep = pl:GetActiveWeapon()
	if not wep:IsValid() or not wep.GetClimbing or not wep.GetPounceTime then return end

	if wep.GetSwinging and wep:GetSwinging() then
		if not pl.PlayingFZSwing then
			pl.PlayingFZSwing = true
			pl:AnimRestartGesture(g_tbl[13], g_tbl[12])
		end
	elseif pl.PlayingFZSwing then
		pl.PlayingFZSwing = false
		pl:AnimResetGestureSlot(g_tbl[13])
	end

	if wep:GetClimbing() then
		local vel = pl:GetVelocity()
		local speed = vel:LengthSqr()
		if speed > 64 then --8^2
			pl:SetPlaybackRate(math_Clamp(speed / 25600, 0, 1) * (vel.z < 0 and -1 or 1)) --160^2
		else
			pl:SetPlaybackRate(0)
		end

		return true
	end

	if wep.GetPounceTime and wep:GetPounceTime() > 0 then
		pl:SetPlaybackRate(0.25)

		if not pl.m_PrevFrameCycle then
			pl.m_PrevFrameCycle = true
			pl:SetCycle(0)
		end

		return true
	elseif pl.m_PrevFrameCycle then
		pl.m_PrevFrameCycle = nil
	end

	if not pl:OnGround() or pl:WaterLevel() >= 3 then
		pl:SetPlaybackRate(1)

		if pl:GetCycle() >= 1 then
			pl:SetCycle(pl:GetCycle() - 1)
		end

		return true
	end

	if wep:IsRoaring() and velocity:Length2DSqr() <= 1 then
		pl:SetPlaybackRate(0)
		pl:SetCycle(math_Clamp(1 - (wep:GetRoarEndTime() - CurTime()) / wep.RoarTime, 0, 1) * 0.9)

		return true
	end
end

function CLASS:DoAnimationEvent(pl, event, data)
	local switch = {
		[g_tbl[14]] = function(pl)
			pl:AnimRestartGesture(g_tbl[13], g_tbl[16], true)
			return g_tbl[17]
		end,
		[g_tbl[15]] = function(pl)
			return g_tbl[17]
		end
	}
	
	return switch[event] and switch[event](pl)
end

if SERVER then
	local timer_Simple = timer.Simple
	function CLASS:ReviveCallback(pl, attacker, dmginfo)
		if math_random(2) == 2 or not pl:ShouldReviveFrom(dmginfo, self.Hull[2].z * 0.4) then return false end

		local classtable = math_random(3) == 3 and GAMEMODE.ZombieClasses["Fast Zombie Legs"] or GAMEMODE.ZombieClasses["Fast Zombie Torso"]
		if classtable then
			pl:RemoveStatus("overridemodel", false, true)
			local deathclass = pl.DeathClass or pl:GetZombieClass()
			pl:SetZombieClass(classtable.Index)
			pl:DoHulls(classtable.Index, TEAM_UNDEAD)
			pl.DeathClass = deathclass

			pl:EmitSound("physics/flesh/flesh_bloody_break.wav", 100, 75)

			pl:Gib()
			pl.Gibbed = nil

			timer_Simple(0, function()
				if IsValid(pl) then
					pl:SecondWind()
				end
			end)

			return true
		end

		return false
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/fastzombie"

local math_NormalizeAngle = math.NormalizeAngle
local math_AngleDifference = math.AngleDifference
local math_Clamp = math.Clamp

function CLASS:CreateMove(pl, cmd)
	local wep = pl:GetActiveWeapon()
	if wep:IsValid() and wep.IsPouncing then
		if wep.m_ViewAngles and wep:IsPouncing() then
			local maxdiff = FrameTime() * 20
			local mindiff = -maxdiff
			local originalangles = wep.m_ViewAngles
			local viewangles = cmd:GetViewAngles()

			local diff = math_AngleDifference(viewangles.yaw, originalangles.yaw)
			if diff > maxdiff or diff < mindiff then
				viewangles.yaw = math_NormalizeAngle(originalangles.yaw + math_Clamp(diff, mindiff, maxdiff))
			end

			wep.m_ViewAngles = viewangles

			cmd:SetViewAngles(viewangles)
		end
	end
end
