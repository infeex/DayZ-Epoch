/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

// Public variable names for client and server (CLIENT one need to be blacklisted in BE filter publicvariable)
#define PVCLIENT CLTFACO4567
#define PVCLIENTADMIN CLTFACOADMIN4567
#define PVSERVER SRVFACO3224
#define FNC(name) name##RANDOM
#define VAR(name) name##RANDOM
#define Stringify(macro) #macro
/*
// id of the first item spawned on Chernarus. Buildings are static item, so their id must be lower than that.
#define FIRSTSPAWNEDITEMID 1055368

// forbidden weapons
#define WEAPBLACKLIST [ "A10", "AK_107_GL_kobra", "AK_107_GL_pso", "AK_107_kobra", "AK_107_pso", "AK_47_S", "AK_74_GL", "AK_74_GL_kobra", "AKS_74", "AKS_74_GOSHAWK", "AKS_74_NSPU", "AKS_74_pso", "AKS_74_UN_kobra", "AKS_GOLD", "BAF_AS50_TWS", "BAF_ied_v1", "BAF_ied_v2", "BAF_ied_v3", "BAF_ied_v4", "BAF_L110A1_Aim", "BAF_L7A2_GPMG", "BAF_L85A2_RIS_ACOG", "BAF_L85A2_RIS_CWS", "BAF_L85A2_UGL_ACOG", "BAF_L85A2_UGL_Holo", "BAF_L85A2_UGL_SUSAT", "BAF_L86A2_ACOG", "BAF_LRR_scoped", "BAF_LRR_scoped_W", "G36_C_SD_eotech", "IR_Strobe_Marker", "IRStrobe", "ItemRadio", "ksvk", "Laserbatteries", "Laserdesignator", "m107", "M136", "m16a4", "M16A4_ACG_GL", "M16A4_GL", "M24_des_EP1", "M240", "m240_scoped_EP1", "M249", "M249_EP1", "M249_m145_EP1", "M32_EP1", "M4A1_HWS_GL_SD_Camo", "M4A1_RCO_GL", "M4A3_RCO_GL_EP1", "M4SPR", "M60A4_EP1", "m8_carbineGL", "MetisLauncher", "MG36", "Mk_48", "Mk_48_DES_EP1", "Pecheneg", "PK", "PMC_AS50_scoped", "PMC_ied_v1_muzzle", "PMC_ied_v2_muzzle", "PMC_ied_v3_muzzle", "PMC_ied_v4_muzzle", "revolver_gold_EP1", "RPG7V", "Sa61_EP1", "Saiga12K", "SCAR_H_CQC_CCO", "SCAR_H_LNG_Sniper", "SCAR_H_LNG_Sniper_SD", "SCAR_H_STD_EGLM_Spect", "SCAR_L_CQC", "SCAR_L_CQC_EGLM_Holo", "UZI_SD_EP1", "VSS_vintorez", "PMC_AS50_TWS", "ItemMap_Debug", "EvMoney", "ksvk", "PMC_AS50_TWS_Large", "BAF_AS50_scoped_Large", "EvMap" ]

#define SPAWNABLEOBJECT ["Land_Fire_DZ", "TentStorage","UH60Wreck_DZ","UH1Wreck_DZ","Mi8Wreck_DZ", "ParachuteWest", "Land_Fire_barrel" , "Hedgehog_DZ", "Sandbag1_DZ", "TrapBear", "Wire_cat1", "StashSmall", "StashMedium"]

// forbidden magazines (used server side only)
#define MAGSBLACKLIST  [ "TimeBomb", "Mine", "MineE", "HandGrenade_Stone", "R_SMAW_HEAA", "R_SMAW_HEDP" ]

// these weapons are limited to LIMITGREYLIST item per cargo (used server side only)
#define MAGSGREYLIST  [ "PipeBomb", "HandGrenade", "HandGrenade_West", "HandGrenade_East" ]
#define LIMITGREYLIST 5
// limit for legit ammo!! (cheater can dup them)
#define LIMITWHITELIST 15
*/
// true: kick/kill player if cheat detected, false otherwise
#define KICKCHEATER true