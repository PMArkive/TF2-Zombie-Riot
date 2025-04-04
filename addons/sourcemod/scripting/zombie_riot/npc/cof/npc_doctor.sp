#pragma semicolon 1
#pragma newdecls required

static char g_HurtSounds[][] =
{
	"cof/purnell/hurt1.mp3",
	"cof/purnell/hurt2.mp3",
	"cof/purnell/hurt3.mp3",
	"cof/purnell/hurt4.mp3"
};

static char g_KillSounds[][] =
{
	"cof/purnell/kill1.mp3",
	"cof/purnell/kill2.mp3",
	"cof/purnell/kill3.mp3",
	"cof/purnell/kill4.mp3"
};

methodmap Doctor < CClotBody
{
	public void PlayHurtSound()
	{
		if(this.m_flNextHurtSound > GetGameTime(this.index))
			return;
		
		this.m_flNextHurtSound = GetGameTime(this.index) + 1.0;
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE);
	}
	public void PlayDeathSound()
	{
		EmitSoundToAll("cof/purnell/death.mp3");
		EmitSoundToAll("cof/purnell/death.mp3");
	}
	public void PlayIntroSound()
	{
		EmitSoundToAll("cof/purnell/intro.mp3");
		EmitSoundToAll("cof/purnell/intro.mp3");
	}
	public void PlayFriendlySound()
	{
		EmitSoundToAll("cof/purnell/converted.mp3");
		EmitSoundToAll("cof/purnell/converted.mp3");
	}
	public void PlayReloadSound()
	{
		EmitSoundToAll("cof/purnell/reload.mp3", this.index);
		EmitSoundToAll("cof/purnell/reload.mp3", this.index);
	}
	public void PlayShootSound()
	{
		EmitSoundToAll("cof/purnell/shoot.mp3", this.index);
	}
	public void PlayMeleeSound()
	{
		this.m_flNextHurtSound = GetGameTime(this.index) + 1.0;
		EmitSoundToAll("cof/purnell/shove.mp3", this.index, SNDCHAN_VOICE);
	}
	public void PlayHitSound()
	{
		EmitSoundToAll("cof/purnell/meleehit.mp3", this.index);
	}
	public void PlayKillSound()
	{
		this.m_flNextHurtSound = GetGameTime(this.index) + 2.0;
		EmitSoundToAll(g_KillSounds[GetRandomInt(0, sizeof(g_KillSounds) - 1)], this.index, SNDCHAN_VOICE);
	}
	public void PlayBuffSound(int entity)
	{
		EmitSoundToAll("cof/purnell/buff.mp3", entity);
	}
	
	public Doctor(int client, float vecPos[3], float vecAng[3], bool ally, const char[] data)
	{
		Doctor npc = view_as<Doctor>(CClotBody(vecPos, vecAng, "models/zombie_riot/cof/doctor_purnell.mdl", "1.15", data[0] == 'f' ? "200000" : "30000", ally, false, false, true));
		i_NpcInternalId[npc.index] = THEDOCTOR;
		
		npc.m_iState = -1;
		npc.SetActivity("ACT_SPAWN");
		
		if(ally)
		{
			npc.PlayFriendlySound();
		}
		else
		{
			npc.PlayIntroSound();
		}
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		
		SDKHook(npc.index, SDKHook_OnTakeDamagePost, Doctor_ClotDamagedPost);
		SDKHook(npc.index, SDKHook_Think, Doctor_ClotThink);
		
		npc.m_iInjuredLevel = 0;
		npc.m_bThisNpcIsABoss = true;
		npc.m_iTarget = -1;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_bDissapearOnDeath = false;
		npc.m_iInjuredLevel = 0;
		
		npc.m_flNextMeleeAttack = 0.0;
		npc.m_flAttackHappens = 0.0;
		
		npc.m_flNextRangedAttack = 0.0;
		npc.m_iAttacksTillReload = 5;
		npc.m_flReloadDelay = GetGameTime(npc.index) + 0.8;
		
		npc.m_flNextRangedSpecialAttack = 0.0;
		
		npc.m_bLostHalfHealth = view_as<bool>(data[0]);

		Citizen_MiniBossSpawn(npc.index);
		return npc;
	}
	
	public void SetActivity(const char[] animation)
	{
		int activity = this.LookupActivity(animation);
		if(activity > 0 && activity != this.m_iState)
		{
			this.m_iState = activity;
			//this.m_bisWalking = false;
			this.StartActivity(activity);
		}
	}
	property int m_iInjuredLevel
	{
		public get()		{ return this.m_iMedkitAnnoyance; }
		public set(int value) 	{ this.m_iMedkitAnnoyance = value; }
	}
}

public void Doctor_ClotThink(int iNPC)
{
	Doctor npc = view_as<Doctor>(iNPC);
	
	SetVariantInt(npc.m_iInjuredLevel);
	AcceptEntityInput(npc.index, "SetBodyGroup");
	
	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.04;
	npc.Update();
	
	if(npc.m_flNextRangedSpecialAttack < gameTime)
	{
		if(npc.m_bLostHalfHealth)
		{
			npc.m_flNextRangedSpecialAttack = gameTime + 0.25;
		}
		else
		{
			npc.m_flNextRangedSpecialAttack = gameTime + 2.0;
		}
		
		int target = GetClosestAlly(npc.index, 40000.0);
		if(target)
		{
			CClotBody ally = view_as<CClotBody>(target);
			if(!ally.m_bLostHalfHealth)
			{
				ally.m_bLostHalfHealth = true;
				b_PernellBuff[target] = true;
				npc.PlayBuffSound(target);
				npc.AddGesture("ACT_SIGNAL");
			}
		}
	}
	
	if(npc.m_iTarget > 0 && !IsValidEnemy(npc.index, npc.m_iTarget))
	{
		if(npc.m_iTarget <= MaxClients)
			npc.PlayKillSound();
		
		npc.m_iTarget = 0;
		npc.m_flGetClosestTargetTime = 0.0;
	}
	
	if(npc.m_flGetClosestTargetTime < gameTime)
	{
		npc.m_flGetClosestTargetTime = gameTime + 0.5;
		npc.m_iTarget = GetClosestTarget(npc.index, true);
	}
	
	int behavior = -1;
	
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < gameTime)
		{
			npc.m_flAttackHappens = 0.0;
			npc.m_iAttacksTillReload++;
			
			if(IsValidEnemy(npc.index, npc.m_iTarget))
			{
				Handle swingTrace;
				npc.FaceTowards(WorldSpaceCenter(npc.m_iTarget), 15000.0);
				if(npc.DoSwingTrace(swingTrace, npc.m_iTarget, _, _, _, _, 1))
				{
					int target = TR_GetEntityIndex(swingTrace);	
					
					float vecHit[3];
					TR_GetEndPosition(vecHit, swingTrace);
					
					if(target > 0) 
					{
						if(target <= MaxClients)
							SDKHooks_TakeDamage(target, npc.index, npc.index, 150.0, DMG_CLUB, -1, _, vecHit);
						else
							SDKHooks_TakeDamage(target, npc.index, npc.index, 800.0, DMG_CLUB, -1, _, vecHit);	
							
						Custom_Knockback(npc.index, target, 500.0);
						npc.m_iAttacksTillReload++;
						npc.PlayHitSound();
					}
				}
				delete swingTrace;
			}
		}
		
		behavior = 0;
	}
	
	if(behavior == -1)
	{
		if(npc.m_iTarget > 0)	// We have a target
		{
			float vecPos[3]; vecPos = WorldSpaceCenter(npc.index);
			float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
			
			float distance = GetVectorDistance(vecTarget, vecPos, true);
			if(distance < 10000.0 && npc.m_flNextMeleeAttack < gameTime)	// Close at any time: Melee
			{
				npc.FaceTowards(vecTarget, 15000.0);
				
				npc.AddGesture("ACT_SHOVE");
				npc.PlayMeleeSound();
				
				npc.m_flAttackHappens = gameTime + 0.3;
				npc.m_flReloadDelay = gameTime + 0.6;
				npc.m_flNextMeleeAttack = gameTime + 1.0;
				
				behavior = 0;
			}
			else if(npc.m_flReloadDelay > gameTime)	// Reloading
			{
				behavior = 0;
			}
			else if(distance < 80000.0)	// In shooting range
			{
				if(npc.m_flNextRangedAttack < gameTime)	// Not in attack cooldown
				{
					if(npc.m_iAttacksTillReload > 0)	// Has ammo
					{
						int Enemy_I_See;
				
						Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);
						//Target close enough to hit
						if(IsValidEnemy(npc.index, npc.m_iTarget) && npc.m_iTarget == Enemy_I_See)
						{
							behavior = 0;
							npc.SetActivity("ACT_IDLE");
							
							npc.FaceTowards(vecTarget, 15000.0);
							
							npc.AddGesture("ACT_SHOOT");
							
							npc.m_flNextRangedAttack = gameTime + 1.0;
							npc.m_iAttacksTillReload--;
							
							vecTarget = PredictSubjectPositionForProjectiles(npc, npc.m_iTarget, 700.0);
							npc.FireRocket(vecTarget, 80.0, 700.0, "models/weapons/w_bullet.mdl", 2.0);
							
							npc.PlayShootSound();
						}
						else	// Something in the way, move closer
						{
							behavior = 1;
						}
					}
					else	// No ammo, retreat
					{
						behavior = 3;
					}
				}
				else	// In attack cooldown
				{
					behavior = 0;
					npc.SetActivity("ACT_IDLE");
				}
			}
			else if(npc.m_iAttacksTillReload < 0)	// Take the time to reload
			{
				//Only if low ammo, otherwise it can be abused.
				behavior = 4;
			}
			else	// Sprint Time
			{
				behavior = 2;
			}
		}
		else if(npc.m_flReloadDelay > gameTime)	// Reloading...
		{
			behavior = 0;
		}
		else if(npc.m_iAttacksTillReload < 5)	// Nobody here..?
		{
			behavior = 4;
		}
		else	// What do I do...
		{
			behavior = 0;
			npc.SetActivity("ACT_GMOD_TAUNT_DANCE");
		}
	}
	
	// Reload anyways if we can't run
	if(npc.m_flRangedSpecialDelay && behavior == 3 && npc.m_flRangedSpecialDelay > gameTime)
		behavior = 4;
	
	switch(behavior)
	{
		case 0:	// Stand
		{
			// Activity handled above
			npc.m_flSpeed = 0.0;
			
			if(npc.m_bPathing)
			{
				PF_StopPathing(npc.index);
				npc.m_bPathing = false;
			}
		}
		case 1:	// Move After the Player
		{
			npc.SetActivity("ACT_RUN");
			npc.m_flSpeed = 100.0;
			npc.m_flRangedSpecialDelay = 0.0;
			
			PF_SetGoalEntity(npc.index, npc.m_iTarget);
			if(!npc.m_bPathing)
				npc.StartPathing();
		}
		case 2:	// Sprint After the Player
		{
			npc.SetActivity("ACT_RUN");
			npc.m_flSpeed = 150.0;
			npc.m_flRangedSpecialDelay = 0.0;
			
			PF_SetGoalEntity(npc.index, npc.m_iTarget);
			if(!npc.m_bPathing)
				npc.StartPathing();
		}
		case 3:	// Retreat
		{
			npc.SetActivity("ACT_RUNHIDE");
			npc.m_flSpeed = 500.0;
			
			if(!npc.m_flRangedSpecialDelay)	// Reload anyways timer
				npc.m_flRangedSpecialDelay = gameTime + 4.0;
			
			float vBackoffPos[3]; vBackoffPos = BackoffFromOwnPositionAndAwayFromEnemy(npc, npc.m_iTarget);
			PF_SetGoalVector(npc.index, vBackoffPos);
			
			if(!npc.m_bPathing)
				npc.StartPathing();
		}
		case 4:	// Reload
		{
			npc.AddGesture("ACT_RELOAD");
			npc.m_flSpeed = 0.0;
			npc.m_flRangedSpecialDelay = 0.0;
			npc.m_flReloadDelay = gameTime + 4.25;
			npc.m_iAttacksTillReload = 5;
			
			if(npc.m_bPathing)
			{
				PF_StopPathing(npc.index);
				npc.m_bPathing = false;
			}
			
			npc.PlayReloadSound();
		}
	}
}

public void Doctor_ClotDamagedPost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if(damage > 0.0)
	{
		Doctor npc = view_as<Doctor>(victim);
		npc.m_iInjuredLevel = 4 - (GetEntProp(victim, Prop_Data, "m_iHealth") * 5 / GetEntProp(victim, Prop_Data, "m_iMaxHealth"));
		
		npc.PlayHurtSound();
	}
}

public void Doctor_NPCDeath(int entity)
{
	Doctor npc = view_as<Doctor>(entity);
	
	SDKUnhook(npc.index, SDKHook_OnTakeDamagePost, Doctor_ClotDamagedPost);
	SDKUnhook(npc.index, SDKHook_Think, Doctor_ClotThink);
	
	PF_StopPathing(npc.index);
	npc.m_bPathing = false;
	
	npc.PlayDeathSound();

	Citizen_MiniBossDeath(entity);
}
