#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] = {
	"zombie_riot/sawrunner/death.mp3",
};

static const char g_IdleAlertedSounds[][] = {
	"zombie_riot/sawrunner/passive.mp3",
};

static const char g_MeleeHitSounds[][] = {
	"zombie_riot/sawrunner/attack1.mp3",
};

static const char g_MeleeAttackSounds[][] = {
	"zombie_riot/sawrunner/attack1.mp3",
	"zombie_riot/sawrunner/attack2.mp3",
};

static const char g_MeleeMissSounds[][] = {
	"zombie_riot/sawrunner/attacksaw2.mp3",
};

static const char g_IdleChainsaw[][] = {
	"zombie_riot/sawrunner/chainsaw_loop.mp3",
};

static const char g_IdleMusic[][] = {
	"#zombie_riot/sawrunner/near_loop.mp3",
};

void SawRunner_OnMapStart_NPC()
{
	for (int i = 0; i < (sizeof(g_DeathSounds));	   i++) { PrecacheSound(g_DeathSounds[i]);	   }
	for (int i = 0; i < (sizeof(g_IdleAlertedSounds)); i++) { PrecacheSound(g_IdleAlertedSounds[i]); }
	for (int i = 0; i < (sizeof(g_MeleeHitSounds));	i++) { PrecacheSound(g_MeleeHitSounds[i]);	}
	for (int i = 0; i < (sizeof(g_MeleeAttackSounds));	i++) { PrecacheSound(g_MeleeAttackSounds[i]);	}
	for (int i = 0; i < (sizeof(g_MeleeMissSounds));   i++) { PrecacheSound(g_MeleeMissSounds[i]);   }
	for (int i = 0; i < (sizeof(g_IdleChainsaw));   i++) { PrecacheSound(g_IdleChainsaw[i]);   }
	for (int i = 0; i < (sizeof(g_IdleMusic));   i++) { PrecacheSound(g_IdleMusic[i]);   }
	PrecacheModel("models/zombie_riot/cof/sawrunner_2.mdl");
}

static int i_PlayIdleAlertSound[MAXENTITIES];
static int i_PlayMusicSound[MAXENTITIES];
static float fl_AlreadyStrippedMusic[MAXTF2PLAYERS];

static char[] GetSawRunnerHealth()
{
	int health = 90;
	
	health *= CountPlayersOnRed(); //yep its high! will need tos cale with waves expoentially.
	
	float temp_float_hp = float(health);
	
	if(CurrentRound+1 < 30)
	{
		health = RoundToCeil(Pow(((temp_float_hp + float(CurrentRound+1)) * float(CurrentRound+1)),1.20));
	}
	else if(CurrentRound+1 < 45)
	{
		health = RoundToCeil(Pow(((temp_float_hp + float(CurrentRound+1)) * float(CurrentRound+1)),1.25));
	}
	else
	{
		health = RoundToCeil(Pow(((temp_float_hp + float(CurrentRound+1)) * float(CurrentRound+1)),1.35)); //Yes its way higher but i reduced overall hp of him
	}
	
	health = health * 3 / 8;
	
	char buffer[16];
	IntToString(health, buffer, sizeof(buffer));
	return buffer;
}

methodmap SawRunner < CClotBody
{
	
	property int m_iPlayIdleAlertSound
	{
		public get()							{ return i_PlayIdleAlertSound[this.index]; }
		public set(int TempValueForProperty) 	{ i_PlayIdleAlertSound[this.index] = TempValueForProperty; }
	}
	property int m_iPlayMusicSound
	{
		public get()							{ return i_PlayMusicSound[this.index]; }
		public set(int TempValueForProperty) 	{ i_PlayMusicSound[this.index] = TempValueForProperty; }
	}
	
	public void PlayIdleSound() {
		if(this.m_flNextIdleSound > GetEngineTime())
			return;
		EmitSoundToAll(g_IdleChainsaw[GetRandomInt(0, sizeof(g_IdleChainsaw) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 100);
		this.m_flNextIdleSound = GetEngineTime() + 2.5;
		
		#if defined DEBUG_SOUND
		PrintToServer("CClot::PlayIdleSound()");
		#endif
	}
	
	public void PlayIdleAlertSound() {
		if(this.m_iPlayIdleAlertSound > GetTime())
			return;
		
		EmitSoundToAll(g_IdleAlertedSounds[GetRandomInt(0, sizeof(g_IdleAlertedSounds) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 100);
		this.m_iPlayIdleAlertSound = GetTime() + GetRandomInt(12, 17);
		
	}
	
	public void PlayMusicSound() {
		if(this.m_iPlayMusicSound > GetTime())
			return;
		
		EmitSoundToAll(g_IdleMusic[GetRandomInt(0, sizeof(g_IdleMusic) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 100);
		EmitSoundToAll(g_IdleMusic[GetRandomInt(0, sizeof(g_IdleMusic) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 100);
		this.m_iPlayMusicSound = GetTime() + 45;
		
	}
	
	public void PlayDeathSound() {
	
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 100);
		
	}
	
	public void PlayMeleeSound() {
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, _, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 100);
		
	}
	
	public void PlayMeleeHitSound() {
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, _, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 100);
		
	}

	public void PlayMeleeMissSound() {
		EmitSoundToAll(g_MeleeMissSounds[GetRandomInt(0, sizeof(g_MeleeMissSounds) - 1)], this.index, _, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 100);
		
	}
	
	
	public SawRunner(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		SawRunner npc = view_as<SawRunner>(CClotBody(vecPos, vecAng, "models/zombie_riot/cof/sawrunner_2.mdl", "1.5", GetSawRunnerHealth(), ally, false, true, true));
		
		i_NpcInternalId[npc.index] = SAWRUNNER;
		
		int iActivity = npc.LookupActivity("ACT_RUN");
		if(iActivity > 0) npc.StartActivity(iActivity);
		
		npc.m_iPlayMusicSound = 0;
		npc.m_flNextMeleeAttack = 0.0;
		npc.m_bisGiantWalkCycle = 1.5;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPSOUND_NORMAL;		
		
		SDKHook(npc.index, SDKHook_OnTakeDamage, SawRunner_ClotDamaged);
		SDKHook(npc.index, SDKHook_Think, SawRunner_ClotThink);
		
		npc.m_bDoSpawnGesture = true;
		
		for(int client_clear=1; client_clear<=MaxClients; client_clear++)
		{
			fl_AlreadyStrippedMusic[client_clear] = 0.0; //reset to 0
		}
		
		npc.m_flDoSpawnGesture = GetGameTime(npc.index) + 2.0;
		
		b_ThisNpcIsSawrunner[npc.index] = true;
		
		npc.m_iState = 0;
		npc.m_flSpeed = 200.0;
		npc.m_flNextRangedAttack = 0.0;
		npc.m_flNextRangedSpecialAttack = 0.0;
		npc.m_flNextMeleeAttack = 0.0;
		npc.m_flAttackHappenswillhappen = false;
		npc.m_fbRangedSpecialOn = false;
		
		npc.m_bDissapearOnDeath = true;
		
		npc.StartPathing();
		
		
		return npc;
	}
	
	
}

//TODO 
//Rewrite
public void SawRunner_ClotThink(int iNPC)
{
	SawRunner npc = view_as<SawRunner>(iNPC);
	
//	if(npc.m_flNextDelayTime > GetGameTime(npc.index))
	{
	//	return;
	}
	
//	npc.m_flNextDelayTime = GetGameTime(npc.index) + DEFAULT_UPDATE_DELAY_FLOAT;
	
	npc.Update();	
	
	if(npc.m_bDoSpawnGesture)
	{
		npc.AddGesture("ACT_SPAWN");
		npc.m_bDoSpawnGesture = false;
	}
	
	if(npc.m_flDoSpawnGesture > GetGameTime(npc.index))
	{
		npc.m_flSpeed = 0.0;
		return;
	}
	
	
	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_HURT", false);
		npc.m_blPlayHurtAnimation = false;
	}
	
	if(npc.m_flAttackHappens_bullshit >= GetGameTime(npc.index))
	{
		npc.m_flSpeed = 0.0;
	}
	else
	{
		npc.m_flSpeed = 450.0;
	}
	
	if(npc.m_flNextThinkTime > GetGameTime(npc.index))
	{
		return;
	}
	
			
	npc.m_flNextThinkTime = GetGameTime(npc.index) + 0.1;

	if(npc.m_flGetClosestTargetTime < GetGameTime(npc.index))
	{
		float targPos[3];
		float chargerPos[3];
		GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", chargerPos);
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				GetClientAbsOrigin(client, targPos);
				if (GetVectorDistance(chargerPos, targPos, true) <= 4000000) // 1500 range
				{
					if(fl_AlreadyStrippedMusic[client] < GetEngineTime())
					{
						Music_Stop_All(client); //This is actually more expensive then i thought.
					}
					SetMusicTimer(client, GetTime() + 5);
					fl_AlreadyStrippedMusic[client] = GetEngineTime() + 5.0;
				}
			}
		}
		npc.m_iTarget = GetClosestTarget(npc.index, true);
		npc.m_flGetClosestTargetTime = GetGameTime(npc.index) + 1.0;
	}
	
	int PrimaryThreatIndex = npc.m_iTarget;
	
	if(IsValidEnemy(npc.index, PrimaryThreatIndex))
	{
			float vecTarget[3]; vecTarget = WorldSpaceCenter(PrimaryThreatIndex);
			
		
			float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
			
			//Predict their pos.
			if(flDistanceToTarget < npc.GetLeadRadius()) {
				
				float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, PrimaryThreatIndex);
				
			/*	int color[4];
				color[0] = 255;
				color[1] = 255;
				color[2] = 0;
				color[3] = 255;
			
				int xd = PrecacheModel("materials/sprites/laserbeam.vmt");
			
				TE_SetupBeamPoints(vPredictedPos, vecTarget, xd, xd, 0, 0, 0.25, 0.5, 0.5, 5, 5.0, color, 30);
				TE_SendToAllInRange(vecTarget, RangeType_Visibility);*/
				
				PF_SetGoalVector(npc.index, vPredictedPos);
			}
			else 
			{
				PF_SetGoalEntity(npc.index, PrimaryThreatIndex);
			}
			
			//Target close enough to hit
			if((flDistanceToTarget < 12500 && npc.m_flReloadDelay < GetGameTime(npc.index)) || npc.m_flAttackHappenswillhappen)
			{
			//	npc.FaceTowards(vecTarget, 1000.0);
				
				if(npc.m_flNextMeleeAttack < GetGameTime(npc.index) || npc.m_flAttackHappenswillhappen)
				{
					if (!npc.m_flAttackHappenswillhappen)
					{
						npc.m_flNextRangedSpecialAttack = GetGameTime(npc.index) + 2.0;
						
						switch(GetRandomInt(1,3))
						{
							case 1:
							{
								npc.AddGesture("ACT_MELEE_1");
							}
							case 2:
							{
								npc.AddGesture("ACT_MELEE_2");
							}
							case 3:
							{
								npc.AddGesture("ACT_MELEE_3");
							}
						}
						npc.PlayMeleeSound();
						npc.m_flAttackHappens = GetGameTime(npc.index)+0.5;
						npc.m_flAttackHappens_bullshit = GetGameTime(npc.index)+0.64;
						npc.m_flAttackHappenswillhappen = true;
						npc.m_flNextMeleeAttack = GetGameTime(npc.index) + 1.5;
					}
						
					if (npc.m_flAttackHappens < GetGameTime(npc.index) && npc.m_flAttackHappens_bullshit >= GetGameTime(npc.index) && npc.m_flAttackHappenswillhappen)
					{
						Handle swingTrace;
						npc.FaceTowards(vecTarget, 20000.0);
						if (npc.DoSwingTrace(swingTrace, PrimaryThreatIndex, { 128.0, 128.0, 128.0 }, { -128.0, -128.0, -128.0 }, _, _, 1))
							{
								
								int target = TR_GetEntityIndex(swingTrace);	
								
								float vecHit[3];
								TR_GetEndPosition(vecHit, swingTrace);
								
								if(target > 0) 
								{
									if(target <= MaxClients)
									{
										if(i_HealthBeforeSuit[target] > 0)
										{
											SDKHooks_TakeDamage(target, npc.index, npc.index, 999999.9, DMG_DROWN); //Make him oneshot the enemy if they have the quantum armor
											Custom_Knockback(npc.index, target, 5000.0); //Kick them away.
										}
										else
										{
											float flMaxHealth = float(SDKCall_GetMaxHealth(target));
											
											flMaxHealth *= 0.75; //Because drown damage is 2x in anycase
											
											if(IsInvuln(target))	
											{
												flMaxHealth *= 0.5; //If under uber, give em more resistance so uber isnt completly useless
												Custom_Knockback(npc.index, target, 5000.0);
											}
											else
											{
												Custom_Knockback(npc.index, target, 1000.0); //Give them massive knockback so they can get away/dont make this boy stuck.
											}
											
											
											SDKHooks_TakeDamage(target, npc.index, npc.index, flMaxHealth + 50.0, DMG_DROWN); //adding 100 damage so they cant cheese this with healing and very low hp people
										}
									}
									else
									{
										SDKHooks_TakeDamage(target, npc.index, npc.index, 999999.0, DMG_CLUB, -1, _, vecHit);
									}
									
									// Hit particle
									
									
									// Hit sound
									npc.PlayMeleeHitSound();
								} 
							}
						delete swingTrace;
						npc.m_flAttackHappenswillhappen = false;
					}
					else if (npc.m_flAttackHappens_bullshit < GetGameTime(npc.index) && npc.m_flAttackHappenswillhappen)
					{
						npc.m_flAttackHappenswillhappen = false;
					}
				}
			}
			if (npc.m_flReloadDelay < GetGameTime(npc.index))
			{
				npc.StartPathing();
				
			}
	}
	else
	{
		PF_StopPathing(npc.index);
		npc.m_bPathing = false;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTarget = GetClosestTarget(npc.index);
	}
	npc.PlayIdleAlertSound();
	npc.PlayIdleSound();
	npc.PlayMusicSound();
}

public Action SawRunner_ClotDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Valid attackers only.
	if(attacker <= 0)
		return Plugin_Continue;
		
		
		
	SawRunner npc = view_as<SawRunner>(victim);
	
	if(npc.m_flDoSpawnGesture > GetGameTime(npc.index))
	{
		return Plugin_Handled;
	}
	
	if (npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	
	return Plugin_Changed;
}

public void SawRunner_NPCDeath(int entity)
{
	SawRunner npc = view_as<SawRunner>(entity);
	if(!npc.m_bGib)
	{
		npc.PlayDeathSound();	
	}
	
	SDKUnhook(npc.index, SDKHook_OnTakeDamage, SawRunner_ClotDamaged);
	SDKUnhook(npc.index, SDKHook_Think, SawRunner_ClotThink);
		
	Music_Stop_All_Sawrunner(entity);
					
	int entity_death = CreateEntityByName("prop_dynamic_override");
	if(IsValidEntity(entity_death))
	{
		float pos[3];
		float Angles[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", Angles);

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(entity_death, pos, Angles, NULL_VECTOR);
		
//		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		DispatchKeyValue(entity_death, "model", "models/zombie_riot/cof/sawrunner_2.mdl");

		DispatchSpawn(entity_death);
		
		SetEntPropFloat(entity_death, Prop_Send, "m_flModelScale", 1.5); 
		SetEntityCollisionGroup(entity_death, 2);
		SetVariantString("death");
		AcceptEntityInput(entity_death, "SetAnimation");
		
		pos[2] += 20.0;
		
		CreateTimer(2.0, Timer_RemoveEntitySawrunner, EntIndexToEntRef(entity_death), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.7, Timer_RemoveEntitySawrunner_Tantrum, EntIndexToEntRef(entity_death), TIMER_FLAG_NO_MAPCHANGE);

	}

	Citizen_MiniBossDeath(entity);
}

public Action Timer_RemoveEntitySawrunner(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEntity(entity) && entity>MaxClients)
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TE_Particle("env_sawblood", pos, NULL_VECTOR, NULL_VECTOR, entity, _, _, _, _, _, _, _, _, _, 0.0);
//		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		RemoveEntity(entity);
	}
	return Plugin_Handled;
}

public Action Timer_RemoveEntitySawrunner_Tantrum(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEntity(entity) && entity>MaxClients)
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		makeexplosion(-1, -1, pos, "", 150, 300);
	}
	return Plugin_Handled;
}

void Music_Stop_All_Sawrunner(int entity)
{
	StopSound(entity, SNDCHAN_AUTO, "#zombie_riot/sawrunner/near_loop.mp3");
	StopSound(entity, SNDCHAN_AUTO, "#zombie_riot/sawrunner/near_loop.mp3");
	StopSound(entity, SNDCHAN_AUTO, "#zombie_riot/sawrunner/near_loop.mp3");
	StopSound(entity, SNDCHAN_AUTO, "#zombie_riot/sawrunner/near_loop.mp3");
	StopSound(entity, SNDCHAN_AUTO, "#zombie_riot/sawrunner/near_loop.mp3");
	StopSound(entity, SNDCHAN_AUTO, "#zombie_riot/sawrunner/near_loop.mp3");
	StopSound(entity, SNDCHAN_AUTO, "#zombie_riot/sawrunner/near_loop.mp3");
	StopSound(entity, SNDCHAN_AUTO, "#zombie_riot/sawrunner/near_loop.mp3");
	StopSound(entity, SNDCHAN_AUTO, "#zombie_riot/sawrunner/near_loop.mp3");
}