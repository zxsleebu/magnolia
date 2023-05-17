local v2, v3 = require("libs.vectors")()
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")

---@class entity_t
---@field m_bEligibleForScreenHighlight number 
---@field m_flMaxFallVelocity number 
---@field m_flLastMadeNoiseTime number 
---@field m_flUseLookAtAngle number 
---@field m_flFadeScale number 
---@field m_fadeMaxDist number 
---@field m_fadeMinDist number 
---@field m_bIsAutoaimTarget number 
---@field m_bSpottedByMask table 
---@field m_bSpottedBy table 
---@field m_bSpotted number 
---@field m_bAlternateSorting number 
---@field m_bAnimatedEveryTick number 
---@field m_bSimulatedEveryTick number 
---@field m_iTextureFrameIndex number 
---@field m_Collision table 
---@field m_vecSpecifiedSurroundingMaxs vec3_t 
---@field m_vecSpecifiedSurroundingMins vec3_t 
---@field m_triggerBloat number 
---@field m_nSurroundType number 
---@field m_usSolidFlags number 
---@field m_nSolidType number 
---@field m_vecMaxs vec3_t 
---@field m_vecMins vec3_t 
---@field movetype number 
---@field m_iName string 
---@field m_iParentAttachment number 
---@field m_hEffectEntity entity_t 
---@field m_hOwnerEntity entity_t 
---@field m_CollisionGroup number 
---@field m_iPendingTeamNum number 
---@field m_iTeamNum number 
---@field m_clrRender number 
---@field m_nRenderFX number 
---@field m_nRenderMode number 
---@field m_fEffects number 
---@field m_nModelIndex number 
---@field m_angRotation vec3_t 
---@field m_vecOrigin vec3_t 
---@field m_cellZ number 
---@field m_cellY number 
---@field m_cellX number 
---@field m_cellbits number 
---@field m_flSimulationTime number 
---@field m_flAnimTime number 
---@field m_viewtarget vec3_t 
---@field m_blinktoggle number 
---@field m_flexWeight table 
---@field m_nWaterLevel number 
---@field m_flDuckSpeed number 
---@field m_flDuckAmount number 
---@field m_bShouldDrawPlayerWhileUsingViewEntity number 
---@field m_hViewEntity entity_t 
---@field m_vphysicsCollisionState number 
---@field m_hColorCorrectionCtrl entity_t 
---@field m_hPostProcessCtrl entity_t 
---@field m_ladderSurfaceProps number 
---@field m_vecLadderNormal vec3_t 
---@field m_szLastPlaceName string 
---@field m_iCoachingTeam number 
---@field m_hObserverTarget entity_t 
---@field m_iDeathPostEffect number 
---@field m_uCameraManGraphs number 
---@field m_bCameraManScoreBoard number 
---@field m_bCameraManOverview number 
---@field m_bCameraManXRay number 
---@field m_bActiveCameraMan number 
---@field m_iObserverMode number 
---@field m_fFlags number 
---@field m_flMaxspeed number 
---@field m_iBonusChallenge number 
---@field m_iBonusProgress number 
---@field m_iAmmo table 
---@field m_lifeState number 
---@field m_iHealth number 
---@field m_hGroundEntity entity_t 
---@field m_hUseEntity entity_t 
---@field m_hVehicle entity_t
---@field m_afPhysicsFlags number 
---@field m_hZoomOwner entity_t 
---@field m_iDefaultFOV number 
---@field m_flFOVTime number 
---@field m_iFOVStart number 
---@field m_iFOV number 
---@field m_hTonemapController number 
---@field m_flLaggedMovementValue number 
---@field m_fForceTeam number 
---@field m_flNextDecalTime number 
---@field m_flDeathTime number 
---@field m_bConstraintPastRadius number 
---@field m_flConstraintSpeedFactor number 
---@field m_flConstraintWidth number 
---@field m_flConstraintRadius number 
---@field m_vecConstraintCenter vec3_t 
---@field m_hConstraintEntity entity_t 
---@field m_vecBaseVelocity vec3_t 
---@field m_vecVelocity vec3_t 
---@field m_hLastWeapon entity_t
---@field m_nNextThinkTick number 
---@field m_nTickBase number 
---@field m_fOnTarget number 
---@field m_flFriction number 
---@field m_vecViewOffset vec3_t
---@field m_bAllowAutoMovement number 
---@field m_flStepSize number 
---@field m_bPoisoned number 
---@field m_bWearingSuit number 
---@field m_bDrawViewmodel number 
---@field m_aimPunchAngleVel vec3_t 
---@field m_aimPunchAngle vec3_t 
---@field m_viewPunchAngle vec3_t 
---@field m_flFallVelocity number 
---@field m_nJumpTimeMsecs number 
---@field m_nDuckJumpTimeMsecs number 
---@field m_nDuckTimeMsecs number 
---@field m_bInDuckJump number 
---@field m_flLastDuckTime number 
---@field m_bDucking number 
---@field m_bDucked number 
---@field m_flFOVRate number 
---@field m_iHideHUD number 
---@field m_chAreaPortalBits table 
---@field m_chAreaBits table 
---@field m_hMyWearables entity_t[]
---@field m_hMyWeapons entity_t[]
---@field m_nRelativeDirectionOfLastInjury number 
---@field m_flTimeOfLastInjury number 
---@field m_hActiveWeapon entity_t
---@field m_LastHitGroup number 
---@field m_flNextAttack number 
---@field m_flLastExoJumpTime number 
---@field m_flHealthShotBoostExpirationTime number 
---@field m_hSurvivalAssassinationTarget entity_t 
---@field m_nSurvivalTeam number 
---@field m_vecSpawnRappellingRopeOrigin vec3_t 
---@field m_bIsSpawnRappelling number 
---@field m_bHideTargetID number 
---@field m_flThirdpersonRecoil number 
---@field m_bStrafing number 
---@field m_flLowerBodyYawTarget number 
---@field m_unTotalRoundDamageDealt number 
---@field m_iNumRoundKillsHeadshots number 
---@field m_bIsLookingAtWeapon number 
---@field m_bIsHoldingLookAtWeapon number 
---@field m_nDeathCamMusic number 
---@field m_nLastConcurrentKilled number 
---@field m_nLastKillerIndex number 
---@field m_bHud_RadarHidden number 
---@field m_bHud_MiniScoreHidden number 
---@field m_bIsAssassinationTarget number 
---@field m_flAutoMoveTargetTime number 
---@field m_flAutoMoveStartTime number 
---@field m_vecAutomoveTargetEnd vec3_t 
---@field m_iControlledBotEntIndex number 
---@field m_bCanControlObservedBot number 
---@field m_bHasControlledBotThisRound number 
---@field m_bIsControllingBot number 
---@field m_unFreezetimeEndEquipmentValue number 
---@field m_unRoundStartEquipmentValue number 
---@field m_unCurrentEquipmentValue number 
---@field m_cycleLatch number 
---@field m_hPlayerPing number 
---@field m_hRagdoll entity_t
---@field m_flProgressBarStartTime number 
---@field m_iProgressBarDuration number 
---@field m_flFlashMaxAlpha number 
---@field m_flFlashDuration number 
---@field m_nHeavyAssaultSuitCooldownRemaining number 
---@field m_bHasHeavyArmor number 
---@field m_bHasHelmet number 
---@field m_unMusicID number 
---@field m_bHasParachute number 
---@field m_passiveItems table 
---@field m_rank table 
---@field m_iMatchStats_EnemiesFlashed table 
---@field m_iMatchStats_UtilityDamage table 
---@field m_iMatchStats_CashEarned table 
---@field m_iMatchStats_Objective table 
---@field m_iMatchStats_HeadShotKills table 
---@field m_iMatchStats_Assists table 
---@field m_iMatchStats_Deaths table 
---@field m_iMatchStats_LiveTime table 
---@field m_iMatchStats_KillReward table 
---@field m_iMatchStats_MoneySaved table 
---@field m_iMatchStats_EquipmentValue table 
---@field m_nPersonaDataPublicLevel table
---@field m_iMatchStats_Damage table 
---@field m_iMatchStats_Kills table 
---@field m_bIsPlayerGhost number 
---@field m_flDetectedByEnemySensorTime number 
---@field m_flGuardianTooFarDistFrac number 
---@field m_isCurrentGunGameTeamLeader number 
---@field m_isCurrentGunGameLeader number 
---@field m_bCanMoveDuringFreezePeriod number 
---@field m_flGroundAccelLinearFracLastTime number 
---@field m_bIsRescuing number 
---@field m_hCarriedHostageProp entity_t 
---@field m_hCarriedHostage entity_t 
---@field m_szArmsModel string 
---@field m_fMolotovDamageTime number 
---@field m_fMolotovUseTime number 
---@field m_iNumRoundKills number 
---@field m_iNumGunGameKillsWithCurrentWeapon number 
---@field m_iNumGunGameTRKillPoints number 
---@field m_iGunGameProgressiveWeaponIndex number 
---@field m_bMadeFinalGunGameProgressiveKill number 
---@field m_bHasMovedSinceSpawn number 
---@field m_bGunGameImmunity number 
---@field m_fImmuneToGunGameDamageTime number 
---@field m_bResumeZoom number 
---@field m_nIsAutoMounting number 
---@field m_bIsWalking number 
---@field m_bIsScoped number 
---@field m_iBlockingUseActionInProgress number 
---@field m_bIsGrabbingHostage number 
---@field m_bIsDefusing number 
---@field m_bInHostageRescueZone number 
---@field m_bHasNightVision number 
---@field m_bNightVisionOn number 
---@field m_bHasDefuser number 
---@field m_angEyeAngles vec3_t 
---@field m_ArmorValue number 
---@field m_iClass number 
---@field m_iMoveState number 
---@field m_bKilledByTaser number 
---@field m_bInNoDefuseArea number 
---@field m_bInBuyZone number 
---@field m_bInBombZone number 
---@field m_totalHitsOnServer number 
---@field m_iStartAccount number 
---@field m_iAccount number 
---@field m_iPlayerState number 
---@field m_bIsRespawningForDMBonus number 
---@field m_bWaitForNoAttack number 
---@field m_iThrowGrenadeCounter number 
---@field m_iSecondaryAddon number 
---@field m_iPrimaryAddon number 
---@field m_iAddonBits number 
---@field m_iWeaponPurchasesThisMatch table 
---@field m_nQuestProgressReason number 
---@field m_unActiveQuestId number 
---@field m_iWeaponPurchasesThisRound table 
---@field m_bPlayerDominatingMe table 
---@field m_bPlayerDominated table 
---@field m_flVelocityModifier number 
---@field m_bDuckOverride number 
---@field m_nNumFastDucks number 
---@field m_iShotsFired number 
---@field m_iDirection number 
---@field m_flStamina number 
---@field m_flNextPrimaryAttack number
---@field m_flNextSecondaryAttack number

local interface = require("libs.interfaces")()

local IClientEntityList = interface.new("client", "VClientEntityList003", {
    GetClientEntity = {3, "void*(__thiscall*)(void*, int)"},
})

---@param index number
---@return ffi.ctype*
entitylist.get_client_entity = function(index)
    ---@diagnostic disable-next-line: undefined-field
    return IClientEntityList:GetClientEntity(index)
end
local entitylist_get_players_o = entitylist.get_players
entitylist.get_players = function (type)
    local players = entitylist_get_players_o(type)
    local new = {}
    for i = 1, #players do
        new[i] = players[i]
    end
    return new
end
---@param steam_id string
---@return entity_t?
entitylist.get_entity_by_steam_id = function (steam_id)
    for _, player in pairs(entitylist.get_players(2)) do
        if player:get_info().steam_id64 == steam_id then
            return player
        end
    end
end

---@param flag number
entity_t.get_flag = function (self, flag)
    return bit.band(self.m_fFlags, flag) ~= 0
end

---@return boolean
entity_t.is_on_ground = function (self)
    return self:get_flag(1)
end

---@return vec3_t
entity_t.get_velocity = function (self)
    return self.m_vecVelocity
end

---@return vec3_t
entity_t.get_origin = function (self)
    return self.m_vecOrigin
end

entity_t.get_info = function (self)
    return engine.get_player_info(self:get_index())
end

entity_t.can_shoot = function (self)
    local tickbase = self.m_nTickBase * globalvars.get_interval_per_tick()
    if self.m_flNextAttack >= tickbase then
        return false
    end
    local weapon = self:get_weapon()
    if not weapon then return false end
    if weapon.entity.m_flNextPrimaryAttack >= tickbase then
        return false
    end
    if weapon.entity.m_flNextSecondaryAttack >= tickbase then
        return false
    end
    return true
end

do
    local ccsplayer = ffi.cast("int*",
        (client.find_pattern("client.dll", "55 8B EC 83 E4 F8 83 EC 18 56 57 8B F9 89 7C 24 0C") or error("wrong ccsplayer sig")) + 0x47)
    local raw_get_abs_origin = ffi.cast("float*(__thiscall*)(void*)", ffi.cast("int*", ccsplayer[0] + 0x28)[0])
    ---@return vec3_t?
    entity_t.get_abs_origin = function (self)
        local address = self[0]
        if not address then return end
        local origin = raw_get_abs_origin(self[0])
        return v3(origin[0], origin[1], origin[2])
    end
end

entity_t.get_eye_pos = function(self)
    return self:get_abs_origin() + self.m_vecViewOffset
end

---@param attacker entity_t
entity_t.is_hittable_by = function(self, attacker)
    --!SELF IS THE VICTIM
    --!ATTACKER IS USUALLY THE LOCAL PLAYER
    local from = attacker:get_eye_pos() + v3(0, 0, 10)
    local to = self:get_player_hitbox_pos(0)
    if not to then return end
    local trace_result = trace.line(attacker:get_index(), 0x46004003, from, to)
    if trace_result.hit_entity_index == self:get_index() then
        return true
    end
    return false
end

---@param cmd? usercmd_t
entity_t.is_shooting = function(self, cmd)
    local lp = entitylist.get_local_player()
    local is_shooting = (lp.m_iShotsFired >= 1) and self:can_shoot()
    if self == lp and cmd then
        is_shooting = is_shooting and bit.band(cmd.buttons, 1) ~= 0
    end
    return is_shooting
end

ffi.cdef[[
    struct WeaponInfo_t{
        char pad1[6];
        uint8_t class;
        char pad2[13];
        int max_clip;	
        char pad3[12];
        int max_ammo;
        char pad4[96];
        char* hud_name;			
        char* name;		
        char pad5[56];
        int type;
    };
]]
do
    local raw_get_weapon_data = ffi.cast("struct WeaponInfo_t*(__thiscall*)(void*)", client.find_pattern("client.dll", "55 8B EC 81 EC ? ? ? ? 53 8B D9 56 57 8D 8B ? ? ? ? 85 C9 75 04")
        or error("failed to find get_weapon_data"))
    local weapon_groups = {
        "knife",
        "pistols",
        "smg",
        "rifle",
        "shotguns",
        "sniper",
        "rifle",
        "c4",
        "placeholder",
        "grenade",
        "unknown"
    }
    local group_by_name = {
        awp = "awp",
        ssg08 = "scout",
        g3sg1 = "auto",
        scar20 = "auto",
        deagle = "deagle",
        taser = "taser",
        c4 = "c4"
    }
    ---@param index? number
    ---@return { entity: entity_t, class: number, name: string, type: number, group: "knife"|"pistols"|"smg"|"rifle"|"shotguns"|"sniper"|"awp"|"auto"|"deagle"|"taser"|"scout"|"rifle"|"c4"|"placeholder"|"grenade"|"revolver"|"unknown" }
    entity_t.get_weapon = function (self, index)
        local weapon
        if index ~= nil then
            weapon = self.m_hMyWeapons[index]
        else
            weapon = self.m_hActiveWeapon
        end
        local data = raw_get_weapon_data(weapon[0])
        local name = ffi.string(data.name):gsub("weapon_", "")
        local group = weapon_groups[data.type + 1]
        if group_by_name[name] then
            group = group_by_name[name] end
        if ffi.string(data.hud_name):find("REVOLVER") then
            group = "revolver" end
        return {
            entity = weapon,
            class = data.class,
            name = name,
            type = data.type,
            group = group,
        }
    end
end

local netvar_table_list = {
    "AI_BaseNPC",
    "WeaponAK47",
    "BaseAnimating", "BaseAnimatingOverlay", "BaseAttributableItem", "BaseButton", "BaseCombatCharacter",
    "BaseCombatWeapon", "BaseCSGrenade", "BaseCSGrenadeProjectile", "BaseDoor", "BaseEntity",
    "BaseFlex", "BaseGrenade", "BaseParticleEntity", "BasePlayer", "BasePropDoor",
    "BaseTeamObjectiveResource", "BaseTempEntity", "BaseToggle", "BaseTrigger", "BaseViewModel",
    "BaseVPhysicsTrigger", "BaseWeaponWorldModel",
    "Beam",
    "BeamSpotlight",
    "BoneFollower",
    "BRC4Target",
    "WeaponBreachCharge",
    "BreachChargeProjectile",
    "BreakableProp", "BreakableSurface",
    "WeaponBumpMine",
    "BumpMineProjectile",
    "WeaponC4",
    "CascadeLight",
    "CChicken",
    "ColorCorrection", "ColorCorrectionVolume",
    "CSGameRulesProxy", "CSPlayer", "CSPlayerResource", "CSRagdoll", "CSTeam",
    "DangerZone", "DangerZoneController",
    "WeaponDEagle",
    "DecoyGrenade", "DecoyProjectile",
    "Drone", "Dronegun",
    "DynamicLight", "DynamicProp",
    "EconEntity",
    "WearableItem",
    "Embers",
    "EntityDissolve", "EntityFlame", "EntityFreezing", "EntityParticleTrail",
    "EnvAmbientLight",
    "DetailController",
    "EnvDOFController", "EnvGasCanister", "EnvParticleScript", "EnvProjectedTexture",
    "QuadraticBeam",
    "EnvScreenEffect", "EnvScreenOverlay", "EnvTonemapController",
    "EnvWind",
    "FEPlayerDecal",
    "FireCrackerBlast", "FireSmoke", "FireTrail",
    "CFish",
    "WeaponFists",
    "Flashbang",
    "FogController",
    "FootstepControl",
    "Func_Dust", "Func_LOD", "FuncAreaPortalWindow", "FuncBrush", "FuncConveyor",
    "FuncLadder", "FuncMonitor", "FuncMoveLinear", "FuncOccluder", "FuncReflectiveGlass",
    "FuncRotating", "FuncSmokeVolume", "FuncTrackTrain",
    "GameRulesProxy",
    "GrassBurn",
    "HandleTest",
    "HEGrenade",
    "CHostage",
    "HostageCarriableProp",
    "IncendiaryGrenade",
    "Inferno",
    "InfoLadderDismount", "InfoMapRegion", "InfoOverlayAccessor",
    "Item_Healthshot", "ItemCash", "ItemDogtags",
    "WeaponKnife", "WeaponKnifeGG",
    "LightGlow",
    "MapVetoPickController",
    "MaterialModifyControl",
    "WeaponMelee",
    "MolotovGrenade", "MolotovProjectile",
    "MovieDisplay",
    "ParadropChopper",
    "ParticleFire",
    "ParticlePerformanceMonitor",
    "ParticleSystem",
    "PhysBox", "PhysBoxMultiplayer", "PhysicsProp", "PhysicsPropMultiplayer", "PhysMagnet",
    "PhysPropAmmoBox", "PhysPropLootCrate", "PhysPropRadarJammer", "PhysPropWeaponUpgrade",
    "PlantedC4",
    "Plasma",
    "PlayerPing", "PlayerResource",
    "PointCamera", "PointCommentaryNode", "PointWorldText",
    "PoseController",
    "PostProcessController",
    "Precipitation",
    "PrecipitationBlocker",
    "PredictedViewModel",
    "Prop_Hallucination", "PropCounter", "PropDoorRotating", "PropJeep", "PropVehicleDriveable",
    "RagdollManager", "Ragdoll", "Ragdoll_Attached",
    "RopeKeyframe",
    "WeaponSCAR17",
    "SceneEntity",
    "SensorGrenade", "SensorGrenadeProjectile",
    "ShadowControl",
    "SlideshowDisplay",
    "SmokeGrenade", "SmokeGrenadeProjectile", "SmokeStack",
    "Snowball",
    "SnowballPile", "SnowballProjectile",
    "SpatialEntity",
    "SpotlightEnd",
    "Sprite", "SpriteOriented", "SpriteTrail",
    "StatueProp",
    "SteamJet",
    "Sun",
    "SunlightShadowControl",
    "SurvivalSpawnChopper",
    "WeaponTablet",
    "Team",
    "TeamplayRoundBasedRulesProxy",
    "TEArmorRicochet",
    "ProxyToggle",
    "TestTraceline",
    "TEWorldDecal",
    "TriggerPlayerMovement", "TriggerSoundOperator",
    "VGuiScreen",
    "VoteController",
    "WaterBullet",
    "WaterLODControl",
    "WeaponAug", "WeaponAWP", "WeaponBaseItem", "WeaponBizon", "WeaponCSBase",
    "WeaponCSBaseGun", "WeaponCycler", "WeaponElite", "WeaponFamas", "WeaponFiveSeven",
    "WeaponG3SG1", "WeaponGalil", "WeaponGalilAR", "WeaponGlock", "WeaponHKP2000",
    "WeaponM249", "WeaponM3", "WeaponM4A1", "WeaponMAC10", "WeaponMag7",
    "WeaponMP5Navy", "WeaponMP7", "WeaponMP9", "WeaponNegev", "WeaponNOVA",
    "WeaponP228", "WeaponP250", "WeaponP90", "WeaponSawedoff", "WeaponSCAR20",
    "WeaponScout", "WeaponSG550", "WeaponSG552", "WeaponSG556", "WeaponShield",
    "WeaponSSG08", "WeaponTaser", "WeaponTec9", "WeaponTMP", "WeaponUMP45",
    "WeaponUSP", "WeaponXM1014", "WeaponZoneRepulsor",
    "WORLD",
    "WorldVguiText",
    "DustTrail",
    "MovieExplosion",
    "ParticleSmokeGrenade",
    "RocketTrail",
    "SmokeTrail",
    "SporeExplosion",
    "SporeTrail",
    "AnimTimeMustBeFirst",
    "CollisionProperty"
}
for i = 1, #netvar_table_list do
    netvar_table_list[i] = "DT_" .. netvar_table_list[i]
end

---@alias __netvar_t { type: string, offset: number, table_type?: string }
---@type table<string, __netvar_t>
local netvar_cache = {
    m_flPoseParameter = { type = "table" },
    m_flEncodedController = { type = "table" },
    m_flexWeight = { type = "table" },
    m_iAmmo = { type = "table" },
    m_bCPIsVisible = { type = "table" },
    m_flLazyCapPerc = { type = "table" },
    m_iTeamIcons = { type = "table" },
    m_iTeamOverlays = { type = "table" },
    m_iTeamReqCappers = { type = "table" },
    m_flTeamCapTime = { type = "table" },
    m_iPreviousPoints = { type = "table" },
    m_bTeamCanCap = { type = "table" },
    m_iTeamBaseIcons = { type = "table" },
    m_iBaseControlPoints = { type = "table" },
    m_bInMiniRound = { type = "table" },
    m_iWarnOnCap = { type = "table" },
    m_flPathDistance = { type = "table" },
    m_iNumTeamMembers = { type = "table" },
    m_iCappingTeam = { type = "table" },
    m_iTeamInZone = { type = "table" },
    m_bBlocked = { type = "table" },
    m_iOwner = { type = "table" },
    m_iMatchStats_Kills = { type = "table" },
    m_iMatchStats_Damage = { type = "table" },
    m_iMatchStats_EquipmentValue = { type = "table" },
    m_iMatchStats_MoneySaved = { type = "table" },
    m_iMatchStats_KillReward = { type = "table" },
    m_iMatchStats_LiveTime = { type = "table" },
    m_iMatchStats_Deaths = { type = "table" },
    m_iMatchStats_Assists = { type = "table" },
    m_iMatchStats_HeadShotKills = { type = "table" },
    m_iMatchStats_Objective = { type = "table" },
    m_iMatchStats_CashEarned = { type = "table" },
    m_iMatchStats_UtilityDamage = { type = "table" },
    m_iMatchStats_EnemiesFlashed = { type = "table" },
    m_hMyWeapons = { type = "table" },
    m_nPersonaDataPublicLevel = { type = "table" },
    m_vecViewOffset = {
        type = "vector",
        offset = 264
    }
}
local netvar_types = {
    b = "bool",
    i = "int",
    f = "float",
    v = "vector",
    a = "angle",
    h = "entity",
    n = "int"
}

---@param netvar string
---@return __netvar_t?
local initialize_netvar = function(netvar)
    if netvar_cache[netvar] and netvar_cache[netvar].offset then
        return netvar_cache[netvar]
    end
    for _, table_name in pairs(netvar_table_list) do
        local offset = se.get_netvar(table_name, netvar)
        if offset and offset ~= 0 then
            local netvar_type = netvar_types[netvar:sub(3, 3)]
            if netvar_type == "float" and netvar:sub(3, 4) ~= "fl" then
                netvar_type = "int"
            end
            if netvar_cache[netvar] and netvar_cache[netvar].type == "table" then
                netvar_cache[netvar] = {
                    offset = offset,
                    type = "table",
                    table_type = netvar_type
                }
                return netvar_cache[netvar]
            end
            netvar_cache[netvar] = {
                offset = offset,
                type = netvar_type
            }
            return netvar_cache[netvar]
        end
    end
end

local netvar_table_mt = {
    ---@param self { netvar: __netvar_t, entity: entity_t }
    __index = errors.handle(function(self, key)
        if type(key) ~= "number" then
            error("netvar table index must be a number")
        end
        local offset = self.netvar.offset + key * 4
        if self.netvar.table_type == "entity" then
            return entitylist.get_entity_from_handle(self.entity:get_prop_int(offset))
        end
        return self.entity["get_prop_"..self.netvar.table_type](self.entity, offset)
    end, "netvar_table_t.__index"),
    __newindex = function (self, key, value)
        if type(key) ~= "number" then
            error("netvar table index must be a number")
        end
        local offset = self.netvar.offset + key * 4
        return self.entity["set_prop_"..self.netvar.table_type](self.entity, offset, value)
    end
}
local netvar_table_t = {
    new = function (entity, netvar)
        return setmetatable({
            netvar = netvar,
            entity = entity,
        }, netvar_table_mt)
    end
}

---@param prop string
entity_t.__get_prop = errors.handle(function(self, prop)
    local netvar = initialize_netvar(prop)
    if not netvar then
        error("failed to init " .. prop .. " netvar")
    end
    if netvar.type == "table" then
        return netvar_table_t.new(self, netvar)
    end
    if netvar.type == "entity" then
        return entitylist.get_entity_from_handle(self:get_prop_int(netvar.offset))
    end
    return self["get_prop_"..netvar.type](self, netvar.offset)
end, "entity_t.__get_prop")
---@param prop string
---@param value any
entity_t.__set_prop = errors.handle(function(self, prop, value)
    local netvar = initialize_netvar(prop)
    if not netvar then
        error("failed to init " .. prop .. " netvar")
    end
    if netvar.type == "table" then
        error("cannot set netvar table")
    end
    return self["set_prop_"..netvar.type](self, netvar.offset, value)
end, "entity_t.__set_prop")
local entity_mt
local initialize_entity_mt = function()
    local lp = entitylist.get_local_player()
    if not lp then return end
    entity_mt = getmetatable(lp)
    ---@param self entity_t
    entity_mt.__index = function (self, key)
        if key == 0 then return entitylist.get_client_entity(self:get_index()) end
        local result = entity_t[key]
        if result then return result end
        return entity_t.__get_prop(self, key)
    end
    ---@param self entity_t
    entity_mt.__newindex = function (self, key, value)
        if key == 0 then error("cannot set entity index") end
        local result = entity_t[key]
        if result then error("cannot set entity property") end
        return entity_t.__set_prop(self, key, value)
    end
end

if not entity_mt then
    initialize_entity_mt()
    if not entity_mt then
        cbs.add("frame_stage_notify", function (stage)
            if not entity_mt then initialize_entity_mt() end
        end)
    end
end
