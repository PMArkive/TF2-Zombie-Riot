#pragma semicolon 1
#pragma newdecls required


int Trip_NumMines[MAXPLAYERS+1] = {0, ...};
int Trip_Owner[MAXENTITIES+1] = {-1, ...};
float Trip_DMG[MAXPLAYERS+1] = {0.0, ...};
float Trip_BlastDMG[MAXPLAYERS+1] = {0.0, ...};
Handle Timer_Trip_Management[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

float f_TerroriserAntiSpamCd[MAXPLAYERS+1] = {0.0, ...};

#define SPRITE_SPRITE	"materials/sprites/laserbeam.vmt"

static int LaserSprite;


#define TRIP_MODEL			  "models/weapons/w_models/w_stickybomb_d.mdl"
#define TRIP_PLANTED		  "weapons/medi_shield_burn_01.wav"
#define TRIP_ARMED			  "weapons/medi_shield_burn_03.wav"
#define TRIP_ACTIVATED		  "weapons/neon_sign_hit_03.wav"
#define TERRORIZER_BLAST1	  "weapons/airstrike_small_explosion_01.wav"
#define TERRORIZER_BLAST2	  "weapons/airstrike_small_explosion_02.wav"
#define TERRORIZER_BLAST3	  "weapons/airstrike_small_explosion_03.wav"

#define Trip_BlastRadius 450.0

#define Terroriser_Implant_Radius 350.0

void Aresenal_Weapons_Map_Precache()
{
	PrecacheModel(TRIP_MODEL);
	PrecacheSound(TRIP_PLANTED);
	PrecacheSound(TRIP_ARMED);
	PrecacheSound(TRIP_ACTIVATED);
	
	PrecacheSound(TERRORIZER_BLAST1);
	PrecacheSound(TERRORIZER_BLAST2);
	PrecacheSound(TERRORIZER_BLAST3);
	LaserSprite = PrecacheModel(SPRITE_SPRITE, false);
}


public void Weapon_Arsenal_Trap(int client, int weapon, const char[] classname, bool &result)
{
	int traps = Trip_GetNumArmed(client);
	if(traps < 6)
	{
		int iTeam = GetClientTeam(client);
			   
		float spawnLoc[3];
		float eyePos[3];
		float eyeAng[3];
			   
		GetClientEyePosition(client, eyePos);
		GetClientEyeAngles(client, eyeAng);
			   
		Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
			   
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(spawnLoc, trace);
		} 
		CloseHandle(trace);
		if (GetVectorDistance(eyePos, spawnLoc, true) <= Pow(450.0, 2.0))
		{
			float Calculate_HP_Spikes = 75.0; 
		
			float Bonus_damage;
			
			float attack_speed;
		
			attack_speed = 1.0 / Attributes_FindOnPlayer(client, 343, true, 1.0); //Sentry attack speed bonus
				
			Bonus_damage = attack_speed * Attributes_FindOnPlayer(client, 287, true, 1.0);			//Sentry damage bonus
			
			if (EscapeMode)
			{
				Calculate_HP_Spikes *= 3.0;
			}
			
			if (Bonus_damage <= 1.0)
				Bonus_damage = 1.0;
				
			Calculate_HP_Spikes *= Bonus_damage;
		
			int TripMine = CreateEntityByName("tf_projectile_pipe_remote");
		  
			if (IsValidEntity(TripMine))
			{
				int color[4];
				color[0] = 255;
				color[1] = 255;
				color[2] = 0;
				color[3] = 255;
												
				if (TF2_GetClientTeam(client) == TFTeam_Blue)
				{
					color[2] = 255;
					color[0] = 0;
				}
				float amp = 0.2;
				float life = 0.1;
				float GunPos[3];
				float GunAng[3];
				GetAttachment(client, "effect_hand_R", GunPos, GunAng);
				TE_SetupBeamPoints(GunPos, spawnLoc, LaserSprite, 0, 0, 0, life, 2.0, 2.2, 1, amp, color, 0);
				TE_SendToAll();
				SetEntPropEnt(TripMine, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(TripMine, Prop_Send, "m_iTeamNum", TF2_GetClientTeam(client));
				SetEntProp(TripMine, Prop_Send, "m_bCritical", false); 	//No crits, causes particles which cause FPS DEATH!! Crits in tf2 cause immensive lag from what i know from ff2.
																	//Might also just be cosmetics, eitherways, dont use this, litterally no reason to!
				SetEntProp(TripMine, Prop_Send, "m_iType", 1);
				SetEntityModel(TripMine, TRIP_MODEL);
				DispatchKeyValue(TripMine, "StartDisabled", "false");
				DispatchSpawn(TripMine);
						
				SetEntityMoveType(TripMine, MOVETYPE_NONE);
				SetEntProp(TripMine, Prop_Data, "m_takedamage", 0);
				AcceptEntityInput(TripMine, "Enable");
		
				TeleportEntity(TripMine, spawnLoc, NULL_VECTOR, NULL_VECTOR);
				   
				SetVariantInt(iTeam);
				AcceptEntityInput(TripMine, "SetTeam");
				SetEntProp(TripMine, Prop_Send, "m_nSkin", iTeam -2);
					   
				EmitSoundToClient(client, TRIP_PLANTED, _, _, 70);
				Trip_NumMines[client] += -1;
					   
				Handle pack;
				CreateDataTimer(0.5, Trip_ArmMine, pack, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(pack, GetClientUserId(client));
				WritePackCell(pack, EntIndexToEntRef(TripMine));
				Trip_DMG[client] = Calculate_HP_Spikes;
				
				for (int i = 0; i < ZR_MAX_TRAPS; i++)
				{
					if (EntRefToEntIndex(i_ObjectsTraps[i]) <= 0)
					{
						i_ObjectsTraps[i] = EntIndexToEntRef(TripMine);
						i = ZR_MAX_TRAPS;
					}
				}
				Trip_BlastDMG[client] = Calculate_HP_Spikes * 0.45;
				int r = 0;
				int b = 0;
				if (TF2_GetClientTeam(client) == TFTeam_Red)
				{
					r = 255;
				}
				else
				{
					b = 255;
				}
				SetEntityCollisionGroup(TripMine, 1);
					
				spawnRing(TripMine, 0.0, 0.0, 0.0, 0.0, "materials/sprites/lgtning.vmt", r, 255, b, 255, 10, 0.4, 10.0, 1.0, 1, 160.0);
			}			
		}
		else
		{
			//ONLY give back ammo IF the Spike has full health.
			int Ammo_type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			//	ClientCommand(client, "playgamesound items/ammo_pickup.wav");
			//	ClientCommand(client, "playgamesound items/ammo_pickup.wav");
			SetAmmo(client, Ammo_type, GetAmmo(client, Ammo_type)+1); //Give ammo back that they just spend like an idiot
			for(int i; i<Ammo_MAX; i++)
			{
				CurrentAmmo[client][i] = GetAmmo(client, i);
			}	
			SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Too Far Away");
			return;
		}
	}
	else
	{
		//ONLY give back ammo IF the Spike has full health.
		int Ammo_type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		//	ClientCommand(client, "playgamesound items/ammo_pickup.wav");
		//	ClientCommand(client, "playgamesound items/ammo_pickup.wav");
		SetAmmo(client, Ammo_type, GetAmmo(client, Ammo_type)+1); //Give ammo back that they just spend like an idiot
		for(int i; i<Ammo_MAX; i++)
		{
			CurrentAmmo[client][i] = GetAmmo(client, i);
		}	
		SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Spike Limit Reached");
		return;
	}
}

public void Weapon_Arsenal_Trap_M2(int client, int weapon, const char[] classname, bool &result)
{
	int entity = GetClientPointVisible(client);
	if(entity > 0)
	{
		static char buffer[64];
		if(GetEntityClassname(entity, buffer, sizeof(buffer)))
		{
			if(Trip_Owner[entity] > 0 && !StrContains(buffer, "tf_projectile_pipe_remote"))
			{
				if(IsValidEntity(weapon))
				{
					int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if(owner == client)
					{
						Trip_Owner[entity] = -1;
						//ONLY give back ammo IF the Spike has full health.
						int Ammo_type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
						ClientCommand(client, "playgamesound items/ammo_pickup.wav");
						ClientCommand(client, "playgamesound items/ammo_pickup.wav");
						SetAmmo(client, Ammo_type, GetAmmo(client, Ammo_type)+1);
						for(int i; i<Ammo_MAX; i++)
						{
							CurrentAmmo[client][i] = GetAmmo(client, i);
						}	
						RemoveEntity(entity);
					}
				}
			}
		}
	}
}

/*
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (ScoreDown2 && !ScoreDown[client] && Trip_NumMines[client] >= 1)
	{
		int TripMine = CreateEntityByName("prop_physics_override");
		
		if (IsValidEntity(TripMine))
		{
			int iTeam = GetClientTeam(client);
			
			float spawnLoc[3];
			float eyePos[3];
			float eyeAng[3];
			
			GetClientEyePosition(client, eyePos);
			GetClientEyeAngles(client, eyeAng);
			
			Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
			
			if (TR_DidHit(trace))
			{
				TR_GetEndPosition(spawnLoc, trace);
			}
			
			CloseHandle(trace);
			
			SetEntityModel(TripMine, TRIP_MODEL);
			DispatchKeyValue(TripMine, "StartDisabled", "false");
			DispatchSpawn(TripMine);
			
			SetEntityMoveType(TripMine, MOVETYPE_NONE);
			SetEntProp(TripMine, Prop_Data, "m_takedamage", 0);
			AcceptEntityInput(TripMine, "Enable");

			TeleportEntity(TripMine, spawnLoc, NULL_VECTOR, NULL_VECTOR);
		
			SetVariantInt(iTeam);
			AcceptEntityInput(TripMine, "SetTeam");
			SetEntProp(TripMine, Prop_Send, "m_nSkin", iTeam -2);
			
			EmitSoundToClient(client, TRIP_PLANTED, _, SNDCHAN_WEAPON, 120);
			Trip_NumMines[client] += -1;
			
			Handle pack;
			CreateDataTimer(Trip_ArmTime[client], Trip_ArmMine, pack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(pack, GetClientUserId(client));
			WritePackCell(pack, EntIndexToEntRef(TripMine));
			
			int r = 0;
			int b = 0;
			if (TF2_GetClientTeam(client) == TFTeam_Red)
			{
				r = 255;
			}
			else
			{
				b = 255;
			}
			
			spawnRing(TripMine, 0.0, 0.0, 0.0, 0.0, "materials/sprites/lgtning.vmt", r, 255, b, 255, 10, 0.4, 10.0, 1.0, 1, 160.0);
		}
	}
	
	ScoreDown[client] = ScoreDown2;
}
*/


public Action Trip_ArmMine(Handle Trip_ArmMine_Handle, any pack)
{
	ResetPack(pack);
	int client = GetClientOfUserId(ReadPackCell(pack));
	int mine = EntRefToEntIndex(ReadPackCell(pack));
	
	if (IsValidMulti(client) && IsValidEntity(mine))
	{
		Trip_Owner[mine] = client;
		EmitSoundToAll(TRIP_ARMED, mine, SNDCHAN_WEAPON);
		
		int r = 0;
		int b = 0;
		if (TF2_GetClientTeam(client) == TFTeam_Red)
		{
			r = 255;
		}
		else
		{
			b = 255;
		}
		
		spawnRing(mine, 160.0, 0.0, 0.0, 0.0, "materials/sprites/lgtning.vmt", r, 255, b, 255, 10, 0.4, 10.0, 1.0, 1, 10.0);
	}
	return Plugin_Handled;
}

public void Trip_TrackPlanted(int client)
{
	if (!IsValidMulti(client))
		return;
		
	for(int entitycount; entitycount<i_MaxcountTraps; entitycount++)
	{
		int ent = EntRefToEntIndex(i_ObjectsTraps[entitycount]);
		if (IsValidEntity(ent))
		{
			if (Trip_Owner[ent] == client)
			{
				float EntLoc[3];
				GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", EntLoc);
				
				for(int entitycount_1; entitycount_1<i_MaxcountTraps; entitycount_1++)
				{
					int ent2 = EntRefToEntIndex(i_ObjectsTraps[entitycount_1]);
					if (IsValidEntity(ent2) && ent2 != ent)
					{
						if (Trip_Owner[ent2] == client)
						{
							float EntLoc2[3];
							GetEntPropVector(ent2, Prop_Data, "m_vecAbsOrigin", EntLoc2);
							//EntLoc2[2] += 20.0;
							//Add 20 to the height of both locations to prevent the model from blocking the line of sight check
							
							if (GetVectorDistance(EntLoc, EntLoc2, true) <= Pow(Trip_BlastRadius, 2.0)/* && HasLineOfSight(ent, ent2, true, EntLoc, EntLoc2)*/)
							{
								bool TriggerExplosion = false;
								
								Handle Trace = TR_TraceRayFilterEx(EntLoc, EntLoc2, ( MASK_SOLID | CONTENTS_SOLID ), RayType_EndPoint, Detect_BaseBoss, client);
								if (TR_DidHit(Trace))
								{
									int targ = TR_GetEntityIndex(Trace);
									char other_classname[32];
									GetEntityClassname(targ, other_classname, sizeof(other_classname));
									if ((StrContains(other_classname, "base_boss") != -1) && (GetEntProp(client, Prop_Send, "m_iTeamNum") != GetEntProp(targ, Prop_Send, "m_iTeamNum")))
									{
										SDKHooks_TakeDamage(targ, client, client, Trip_DMG[client], DMG_BLAST, -1);
										EmitSoundToAll(TRIP_ACTIVATED, targ, _, 70);
										TriggerExplosion = true;
									}
								}
										
								CloseHandle(Trace);
								
								if (TriggerExplosion)
								{
									SpawnSmallExplosion(EntLoc);
									SpawnSmallExplosion(EntLoc2);
									
									switch(GetRandomInt(1, 3))
									{
										case 1:
										{
											EmitSoundToAll(TERRORIZER_BLAST1, ent, _);
											EmitSoundToAll(TERRORIZER_BLAST1, ent2, _);
										}
										case 2:
										{
											EmitSoundToAll(TERRORIZER_BLAST2, ent, _);
											EmitSoundToAll(TERRORIZER_BLAST2, ent2, _);
										}
										case 3:
										{
											EmitSoundToAll(TERRORIZER_BLAST2, ent, _);
											EmitSoundToAll(TERRORIZER_BLAST3, ent2, _);
										}
									}
									
									Explode_Logic_Custom(Trip_BlastDMG[client], client, client, -1, EntLoc2,Trip_BlastRadius,_,_,false);
									Explode_Logic_Custom(Trip_BlastDMG[client], client, client, -1, EntLoc,Trip_BlastRadius,_,_,false);
									
									RemoveEntity(ent);
									RemoveEntity(ent2);
									Trip_Owner[ent2] = -1;
									Trip_Owner[ent] = -1;
								}
								
								int color[4];
								color[0] = 255;
								color[1] = 255;
								color[2] = 0;
								color[3] = 255;
									
								if (TF2_GetClientTeam(client) == TFTeam_Blue)
								{
									color[2] = 255;
									color[0] = 0;
								}
									
								int SPRITE_INT = PrecacheModel("materials/sprites/laserbeam.vmt", false);
									
								float amp = 0.2;
								float life = 0.1;
								
								if (TriggerExplosion)
								{
									amp = 12.0;
									life = 0.4;
								}
									
								TE_SetupBeamPoints(EntLoc, EntLoc2, SPRITE_INT, 0, 0, 0, life, 2.0, 2.2, 1, amp, color, 0);
								TE_SendToAll();
							}
						}
					}
				}
			}
		}
	}
}

public int Trip_GetNumArmed(int client)
{
	int Armed = 0;
	
	if (IsValidMulti(client))
	{
		for(int entitycount; entitycount<i_MaxcountTraps; entitycount++)
		{
			int ent = EntRefToEntIndex(i_ObjectsTraps[entitycount]);
			if (IsValidEntity(ent))
			{
				Armed += view_as<int>(Trip_Owner[ent] == client);
			}
		}
	}
	
	return Armed;
}

public bool Trip_PlayerCrossed(int client, int mask, any data) 
{ 	
	return client == data;
} 

public void Enable_Arsenal(int client, int weapon) // Enable management, handle weapons change but also delete the timer if the client have the max weapon
{
	if (Timer_Trip_Management[client] != INVALID_HANDLE)
		return;
		
	if(i_AresenalTrap[weapon] > 0)
	{	
		Timer_Trip_Management[client] = CreateTimer(0.1, Timer_Management_Trap, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		Kill_Timer_Trap(client);
	}
}

public Action Timer_Management_Trap(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			Trip_TrackPlanted(client);
		}
		else
			Kill_Timer_Trap(client);
	}
	else
		Kill_Timer_Trap(client);
		
	return Plugin_Continue;
}

public void Kill_Timer_Trap(int client)
{
	if (Timer_Trip_Management[client] != INVALID_HANDLE)
	{
		KillTimer(Timer_Trip_Management[client]);
		Timer_Trip_Management[client] = INVALID_HANDLE;
	}
}


public void Weapon_Arsenal_Terroriser_M1(int client, int weapon, const char[] classname, bool &result)
{
	f_ChargeTerroriserSniper[weapon] = GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage");
}

public void Weapon_Arsenal_Terroriser_M2(int client, int weapon, const char[] classname, bool &result)
{
	if (f_TerroriserAntiSpamCd[client] < GetGameTime())
	{
		f_TerroriserAntiSpamCd[client] = GetGameTime() + 0.25;
		
		for(int entitycount; entitycount<i_MaxcountNpc; entitycount++)
		{
			int npc = EntRefToEntIndex(i_ObjectsNpcs[entitycount]);
			if (IsValidEntity(npc))
			{
				if(i_HowManyBombsOnThisEntity[npc][client] > 0)
				{
					EmitSoundToAll(TRIP_ARMED, npc, _, 85);
					float damage = 50.0;
					Address address = TF2Attrib_GetByDefIndex(weapon, 2);
					if(address != Address_Null)
						damage *= RoundToCeil(TF2Attrib_GetValue(address));
						
					int r = 255;
					int g = 0;
					int b = 0;
					
					spawnRing(npc, 160.0, 0.0, 0.0, 0.0, "materials/sprites/lgtning.vmt", r, g, b, 255, 10, 0.4, 10.0, 1.0, 1, 10.0);
					
					Handle pack;
					CreateDataTimer(0.5, Terroriser_Explosion, pack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(pack, GetClientUserId(client));
					WritePackCell(pack, EntIndexToEntRef(npc));
					WritePackCell(pack, i_HowManyBombsOnThisEntity[npc][client]);
					WritePackCell(pack, damage);
					i_HowManyBombsOnThisEntity[npc][client] = 0;
				}
			}
		}
	}
}

int Terroriser_Bomb_Implant_Particle[MAXENTITIES+1] = {-1, ...};

public void Apply_Particle_Teroriser_Indicator(int entity)
{
	int particle_index;
	particle_index = EntRefToEntIndex(Terroriser_Bomb_Implant_Particle[entity]);
	if(!IsValidEntity(particle_index))
	{
		float flPos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", flPos);
					
		flPos[2] += 90.0 * GetEntPropFloat(entity, Prop_Data, "m_flModelScale");
		Terroriser_Bomb_Implant_Particle[entity] = EntIndexToEntRef(ParticleEffectAt_Parent(flPos, "powerup_icon_supernova_red",entity));
	}
}

public void CleanAllApplied_Aresenal(int entity)
{
	int particle_index;
	particle_index = EntRefToEntIndex(Terroriser_Bomb_Implant_Particle[entity]);
	if(IsValidEntity(particle_index))
	{
		RemoveEntity(particle_index);
	}
}

public Action Terroriser_Explosion(Handle Trip_ArmMine_Handle, any pack)
{
	ResetPack(pack);
	int client = GetClientOfUserId(ReadPackCell(pack));
	int npc = EntRefToEntIndex(ReadPackCell(pack));
	int bomb_amount = ReadPackCell(pack);
	float damage = ReadPackCell(pack);
	if (IsValidMulti(client) && IsValidEntity(npc) && !b_NpcHasDied[npc])
	{
		damage *= bomb_amount;
		float EntLoc2[3];
		
		EntLoc2 = WorldSpaceCenter(npc);
							
		SpawnSmallExplosion(EntLoc2);

		switch(GetRandomInt(1, 3))
		{
			case 1:
			{
				EmitSoundToAll(TERRORIZER_BLAST1, npc, _);
			}
			case 2:
			{
				EmitSoundToAll(TERRORIZER_BLAST2, npc, _);
			}
			case 3:
			{
				EmitSoundToAll(TERRORIZER_BLAST2, npc, _);
			}
		}
		CleanAllApplied_Aresenal(npc);
		
		Explode_Logic_Custom(damage, client, client, -1, EntLoc2, Terroriser_Implant_Radius,_,_,false);
		f_CooldownForHurtHud[client] = 0.0; //So it shows the damage delt by by secondary internal combustion too.
		SDKHooks_TakeDamage(npc, client, client, damage * 0.5, DMG_BLAST); //extra damage to the target that was hit cus yeah.
	}
	return Plugin_Handled;
}