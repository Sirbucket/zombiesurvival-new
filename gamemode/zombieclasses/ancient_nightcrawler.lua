CLASS.Base = "shadow_lurker"

CLASS.Name = "Ancient Nightcrawler"
CLASS.TranslationName = "class_ancient_nightcrawler"
CLASS.Description = "description_ancient_nightcrawler"
CLASS.Help = "controls_ancient_nightcrawler"

CLASS.Model = Model("models/Zombie/Classic_torso.mdl")
CLASS.OverrideModel = Model("models/player/skeleton.mdl")

CLASS.SWEP = "weapon_zs_ancient_nightcrawler"

CLASS.Wave = 5/6
CLASS.Hidden = false
CLASS.NoHideMainModel = false
CLASS.ModelScale = 1.2

CLASS.Health = 400
CLASS.Speed = 160

CLASS.VoicePitch = 0.65

CLASS.SkeletalRes = true


local math_random = math.random

if SERVER then
    local bit_band = bit.band
    local DMG_BULLET = DMG_BULLET
    local DMG_SLASH = DMG_SLASH
    local DMG_CLUB = DMG_CLUB
	function CLASS:OnSecondWind(pl)
		pl:EmitSound("npc/zombie/zombie_voice_idle"..math_random(14)..".wav", 100, 85)
	end
    function CLASS:ProcessDamage(pl, dmginfo)
		if bit_band(dmginfo:GetDamageType(), DMG_BULLET) ~= 0 then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.36)
		elseif bit_band(dmginfo:GetDamageType(), DMG_SLASH) == 0 and bit_band(dmginfo:GetDamageType(), DMG_CLUB) == 0 then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.45)
		end
	end
end

if CLIENT then
    local math_Rand = math.Rand
	CLASS.Icon = "zombiesurvival/killicons/torso"
    
    local function CreateBoneOffsets(pl)
        pl.m_NightmareBoneOffsetsNext = CurTime() + math_Rand(0.02, 0.1)
    
        local offsets = {}
        local angs = {}
        for i=1, pl:GetBoneCount() - 1 do
            if math_random(3) == 3 then
                offsets[i] = VectorRand():GetNormalized() * math_Rand(0.5, 3)
            end
            if math_random(5) == 5 then
                angs[i] = Angle(math_Rand(-5, 5), math_Rand(-15, 15), math_Rand(-5, 5))
            end
        end
        pl.m_NightmareBoneOffsets = offsets
        pl.m_NightmareBoneAngles = angs
    end
    
    function CLASS:BuildBonePositions(pl)
        if not pl.m_NightmareBoneOffsets or CurTime() >= pl.m_NightmareBoneOffsetsNext then
            CreateBoneOffsets(pl)
        end
    
        local offsets = pl.m_NightmareBoneOffsets
        local angs = pl.m_NightmareBoneAngles
        for i=1, pl:GetBoneCount() - 1 do
            if offsets[i] then
                pl:ManipulateBonePosition(i, offsets[i])
            end
            if angs[i] then
                pl:ManipulateBoneAngles(i, angs[i])
            end
        end
    end
    local render_SetBlend = render.SetBlend
    local render_SetColorModulation = render.SetColorModulation
    local render_SetMaterial = render.SetMaterial
    local render_DrawSprite = render.DrawSprite
    local render_ModelMaterialOverride = render.ModelMaterialOverride
    local angle_zero = angle_zero
    local LocalToWorld = LocalToWorld

    local colGlow = Color(255, 0, 0)
    local matGlow = Material("sprites/glow04_noz")
    local matBlack = CreateMaterial("shadowlurkersheet", "UnlitGeneric", {["$basetexture"] = "Tools/toolsblack", ["$model"] = 1})
    local vecEyeLeft = Vector(5, -3.5, -1)
    local vecEyeRight = Vector(5, -3.5, 1)
    function CLASS:PrePlayerDraw(pl)
        render_SetColorModulation(0.1, 0.1, 0.1)
        render_SetBlend(0.45)
    end
    
    function CLASS:PostPlayerDraw(pl)
        render_SetColorModulation(1, 1, 1)
        render_SetBlend(1)
    end
    function CLASS:PrePlayerDrawOverrideModel(pl)
        render_SetColorModulation(0.1, 0.1, 0.1)
        render_ModelMaterialOverride(matBlack)
    end
    
    function CLASS:PostPlayerDrawOverrideModel(pl)
        render_SetColorModulation(1, 1, 1)
        render_ModelMaterialOverride(nil)

        if pl == MySelf and not pl:ShouldDrawLocalPlayer() or pl.SpawnProtection then return end

        local pos, ang = pl:GetBonePositionMatrixed(5)
        if pos then
            render_SetMaterial(matGlow)
            render_DrawSprite(LocalToWorld(vecEyeLeft, angle_zero, pos, ang), 4, 4, colGlow)
            render_DrawSprite(LocalToWorld(vecEyeRight, angle_zero, pos, ang), 4, 4, colGlow)
        end
    end
end
