#pragma semicolon 1
#pragma newdecls required

static const char g_IdleSound[][] = {
	"vo/taunts/scout_taunts19.mp3",
	"vo/taunts/scout_taunts20.mp3",
	"vo/taunts/scout_taunts21.mp3",
	"vo/taunts/scout_taunts22.mp3",
};

static const char g_HurtSound[][] = {
	"vo/scout_painsharp01.mp3",
	"vo/scout_painsharp02.mp3",
	"vo/scout_painsharp03.mp3",
	"vo/scout_painsharp04.mp3",
	"vo/scout_painsharp05.mp3",
	"vo/scout_painsharp06.mp3",
	"vo/scout_painsharp07.mp3",
	"vo/scout_painsharp08.mp3",
};


public void StartChicken_OnMapStart_NPC()
{
	for (int i = 0; i < (sizeof(g_IdleSound));	i++) { PrecacheSound(g_IdleSound[i]);	}
	for (int i = 0; i < (sizeof(g_HurtSound));	i++) { PrecacheSound(g_HurtSound[i]);	}
	PrecacheModel("models/player/scout.mdl");
}

methodmap StartChicken < CClotBody
{
	public void PlayIdleSound()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;

		EmitSoundToAll(g_IdleSound[GetRandomInt(0, sizeof(g_IdleSound) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, GetRandomInt(125, 135), NORMAL_ZOMBIE_VOLUME);

		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(24.0, 48.0);
	}
	
	public void PlayHurtSound() {
		
		EmitSoundToAll(g_HurtSound[GetRandomInt(0, sizeof(g_HurtSound) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, GetRandomInt(125, 135), NORMAL_ZOMBIE_VOLUME);
		
	}
	
	
	public StartChicken(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		StartChicken npc = view_as<StartChicken>(CClotBody(vecPos, vecAng, "models/player/scout.mdl", "0.5", "300", ally, false,_,_,_,{8.0,8.0,36.0}));
		
		i_NpcInternalId[npc.index] = START_CHICKEN;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");
		
		int iActivity = npc.LookupActivity("ACT_MP_STAND_MELEE");
		if(iActivity > 0) npc.StartActivity(iActivity);

		npc.m_flNextMeleeAttack = 0.0;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		
		//IDLE
		npc.m_flSpeed = 120.0;

		npc.m_bisWalking = false;

		SDKHook(npc.index, SDKHook_OnTakeDamage, StartChicken_OnTakeDamage);
		SDKHook(npc.index, SDKHook_Think, StartChicken_ClotThink);
		
		int skin = GetRandomInt(0, 1);
		SetEntProp(npc.index, Prop_Send, "m_nSkin", skin);

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/player/items/scout/sf14_nugget_noggin/sf14_nugget_noggin.mdl");
		SetVariantString("1.0");
		AcceptEntityInput(npc.m_iWearable1, "SetModelScale");

		SetEntProp(npc.m_iWearable1, Prop_Send, "m_nSkin", skin);

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/scout/sf14_fowl_fists/sf14_fowl_fists.mdl");
		SetVariantString("1.0");
		AcceptEntityInput(npc.m_iWearable2, "SetModelScale");

		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", skin);

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/scout/sf14_talon_trotters/sf14_talon_trotters.mdl");
		SetVariantString("1.0");
		AcceptEntityInput(npc.m_iWearable3, "SetModelScale");

		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", skin);
		
		npc.StartPathing();
		
		return npc;
	}
	
}

//TODO 
//Rewrite
static float f3_PositionArrival[MAXENTITIES][3];
public void StartChicken_ClotThink(int iNPC)
{
	StartChicken npc = view_as<StartChicken>(iNPC);
	
	if(npc.m_flNextDelayTime > GetGameTime(npc.index))
	{
		return;
	}
	
	npc.m_flNextDelayTime = GetGameTime(npc.index) + DEFAULT_UPDATE_DELAY_FLOAT;
	
	npc.Update();
	
	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
		npc.m_flNextMeleeAttack = 0.0; //Run!!
	}
	npc.PlayIdleSound();
	
	if(npc.m_flNextThinkTime > GetGameTime(npc.index))
	{
		return;
	}

	npc.m_flNextThinkTime = GetGameTime(npc.index) + 0.1;

	if(!npc.m_bisWalking) //Dont move, or path. so that he doesnt rotate randomly, also happens when they stop follwing.
	{
		npc.m_flSpeed = 0.0;

		if(npc.m_bPathing)
		{
			PF_StopPathing(npc.index);
			npc.m_bPathing = false;	
		}
	}
	else
	{
		npc.m_flSpeed = 120.0;

		if(!npc.m_bPathing)
			npc.StartPathing();
	}

	float vecTarget[3];
	GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", vecTarget);

	float fl_DistanceToOriginalSpawn = GetVectorDistance(vecTarget, f3_PositionArrival[npc.index], true);
	if(fl_DistanceToOriginalSpawn < Pow(80.0, 2.0)) //We are too far away from our home! return!
	{
		npc.m_bisWalking = false;
		npc.SetActivity("ACT_MP_STAND_MELEE");
	}
	
		
	//Roam while idle
		
	//Is it time to pick a new place to go?
	if(npc.m_flNextMeleeAttack < GetGameTime(npc.index))
	{
		//Pick a random goal area
		CNavArea RandomArea = PickRandomArea();	
			
		if(RandomArea == NULL_AREA) 
			return;
			
		float vecGoal[3]; RandomArea.GetCenter(vecGoal);
		
		//if(!PF_IsPathToVectorPossible(iNPC, vecGoal))
		//	return;
			
		f3_PositionArrival[iNPC][0] = vecGoal[0];
		f3_PositionArrival[iNPC][1] = vecGoal[1];
		f3_PositionArrival[iNPC][2] = vecGoal[2];

		npc.m_bisWalking = true;

		npc.SetActivity("ACT_MP_RUN_MELEE");

		PF_SetGoalVector(iNPC, vecGoal);
		PF_StartPathing(iNPC);
			
		//Timeout
		npc.m_flNextMeleeAttack = GetGameTime(npc.index) + GetRandomFloat(10.0, 20.0);
	}
}

public Action StartChicken_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Valid attackers only.
	if(attacker <= 0)
		return Plugin_Continue;

	StartChicken npc = view_as<StartChicken>(victim);
	
	if (npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
//	
	return Plugin_Changed;
}

public void StartChicken_NPCDeath(int entity)
{
//	StartChicken npc = view_as<StartChicken>(entity);

	SDKUnhook(entity, SDKHook_OnTakeDamage, StartChicken_OnTakeDamage);
	SDKUnhook(entity, SDKHook_Think, StartChicken_ClotThink);
}


