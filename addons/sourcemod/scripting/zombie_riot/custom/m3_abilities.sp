#pragma semicolon 1
#pragma newdecls required

static float ability_cooldown[MAXPLAYERS+1]={0.0, ...};
static float ability_cooldown_2[MAXPLAYERS+1]={0.0, ...};
static int Attack3AbilitySlotArray[MAXPLAYERS+1]={0, ...};
static float f_HealDelay[MAXENTITIES];
static float f_Duration[MAXENTITIES];
static int g_ProjectileModel;
static int g_ProjectileModelArmor;
static int g_BeamIndex_heal = -1;

static char gExplosive1;
static char gLaser1;


//#define ARROW_TRAIL_GRENADE "effects/arrowtrail_blu.vmt"

//int trail = Trail_Attach(entity, ARROW_TRAIL_GRENADE, 255, 0.3, 3.0, 3.0, 5);


#define SOUND_HEAL_BEAM			"items/medshot4.wav"
#define SOUND_ARMOR_BEAM			"physics/metal/metal_box_strain1.wav"

#define SOUND_DASH			"npc/roller/mine/rmine_explode_shock1.wav"

public void M3_Abilities_Precache()
{
	gLaser1 = PrecacheModel("materials/sprites/laser.vmt");
	gExplosive1 = PrecacheModel("materials/sprites/sprite_fire01.vmt");
//	PrecacheModel(ARROW_TRAIL_GRENADE);
//	PrecacheDecal(ARROW_TRAIL_GRENADE, true);
	static char model[PLATFORM_MAX_PATH];
	model = "models/healthvial.mdl";
	g_ProjectileModel = PrecacheModel(model);
	model = "models/Items/battery.mdl";
	g_ProjectileModelArmor = PrecacheModel(model);
	g_BeamIndex_heal = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheSound(SOUND_HEAL_BEAM);
	PrecacheSound(SOUND_ARMOR_BEAM);
	PrecacheSound(SOUND_DASH);
	PrecacheSound("mvm/mvm_tank_start.wav");
	
}
public void M3_ClearAll()
{
	Zero(ability_cooldown);
	Zero(ability_cooldown_2);
	Zero(Attack3AbilitySlotArray);
	Zero(f_HealDelay);
	Zero(f_Duration);
}

public void M3_Abilities(int client)
{
	switch(Attack3AbilitySlotArray[client])
	{
		case 1:
		{
			PlaceableTempomaryHealingGrenade(client);
		}
		case 2:
		{
			WeakDash(client);
		}
		case 3:
		{
			PlaceableTempomaryArmorGrenade(client);
		}
		case 4:
		{
			GearTesting(client);
		}
	}
}
public void WeakDash(int client)
{
	if(dieingstate[client] > 0)
	{
		if (ability_cooldown_2[client] < GetGameTime())
		{
			ability_cooldown_2[client] = GetGameTime() + 120.0;
			WeakDashLogic(client);
		}
		else
		{
			float Ability_CD = ability_cooldown_2[client] - GetGameTime();
			
			if(Ability_CD <= 0.0)
				Ability_CD = 0.0;
				
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);	
		}		
	}
	else
	{
		if (ability_cooldown[client] < GetGameTime())
		{
			ability_cooldown[client] = GetGameTime() + 60.0;
			CreateTimer(60.0, M3_Ability_Is_Back, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
			WeakDashLogic(client);
		}
		else
		{
			float Ability_CD = ability_cooldown[client] - GetGameTime();
			
			if(Ability_CD <= 0.0)
				Ability_CD = 0.0;
				
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);	
		}
	}
}

public void WeakDashLogic(int client)
{
	EmitSoundToAll(SOUND_DASH, client, _, 70, _, 1.0);
			
	static float EntLoc[3];
			
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", EntLoc);
			
	SpawnSmallExplosion(EntLoc);
			
	static float anglesB[3];
	GetClientEyeAngles(client, anglesB);
	static float velocity[3];
	GetAngleVectors(anglesB, velocity, NULL_VECTOR, NULL_VECTOR);
	float knockback = 750.0;
			
	ScaleVector(velocity, knockback);
	if ((GetEntityFlags(client) & FL_ONGROUND) != 0 || GetEntProp(client, Prop_Send, "m_nWaterLevel") >= 1)
		velocity[2] = fmax(velocity[2], 300.0);
	else
		velocity[2] += 150.0; // a little boost to alleviate arcing issues
			
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);		
}

public void PlaceableTempomaryArmorGrenade(int client)
{
	if (ability_cooldown[client] < GetGameTime())
	{
		ability_cooldown[client] = GetGameTime() + 100.0;
		CreateTimer(100.0, M3_Ability_Is_Back, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
		
		int entity = CreateEntityByName("tf_projectile_pipe");
		if(IsValidEntity(entity))
		{
			static float pos[3], ang[3], vel_2[3];
			GetClientEyeAngles(client, ang);
			GetClientEyePosition(client, pos);	
		
			ang[0] -= 8.0;
			
			float speed = 1500.0;
			
			vel_2[0] = Cosine(DegToRad(ang[0]))*Cosine(DegToRad(ang[1]))*speed;
			vel_2[1] = Cosine(DegToRad(ang[0]))*Sine(DegToRad(ang[1]))*speed;
			vel_2[2] = Sine(DegToRad(ang[0]))*speed;
			vel_2[2] *= -1;
			
			int team = GetClientTeam(client);
				
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntProp(entity, Prop_Send, "m_iTeamNum", team, 1);
			SetEntProp(entity, Prop_Send, "m_nSkin", (team-2));
			SetEntPropFloat(entity, Prop_Send, "m_flDamage", 0.0); 
			SetEntPropEnt(entity, Prop_Send, "m_hThrower", client);
			SetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher", 0);
			for(int i; i<4; i++)
			{
				SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", g_ProjectileModelArmor, _, i);
			}
			
			SetVariantInt(team);
			AcceptEntityInput(entity, "TeamNum", -1, -1, 0);
			SetVariantInt(team);
			AcceptEntityInput(entity, "SetTeam", -1, -1, 0); 
			
			SetEntPropEnt(entity, Prop_Send, "m_hLauncher", EntRefToEntIndex(i_StickyAccessoryLogicItem[client]));
			//Make them barely bounce at all.
			DispatchSpawn(entity);
			TeleportEntity(entity, pos, ang, vel_2);
			
			IsCustomTfGrenadeProjectile(entity, 9999999.0);
			CClotBody npc = view_as<CClotBody>(entity);
			npc.m_bThisEntityIgnored = true;
			
			f_HealDelay[entity] = GetGameTime() + 1.0;
			f_Duration[entity] = GetGameTime() + 10.0;
			
			SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
			 
			DataPack pack;
			CreateDataTimer(0.1, Timer_Detect_Player_Near_Armor_Grenade, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			pack.WriteCell(EntIndexToEntRef(entity));
	//		pack.WriteCell(Healing_Amount);	
			pack.WriteCell(GetClientUserId(client));
		}
	}
	else
	{
		float Ability_CD = ability_cooldown[client] - GetGameTime();
		
		if(Ability_CD <= 0.0)
			Ability_CD = 0.0;
			
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);	
	}
}


public Action Timer_Detect_Player_Near_Armor_Grenade(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
//	float Healing_Amount = pack.ReadCell();
	int client = GetClientOfUserId(pack.ReadCell());
	if(IsValidEntity(entity) && entity>MaxClients)
	{
		if(IsValidClient(client))
		{
			float powerup_pos[3];
			float client_pos[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", powerup_pos);
			if(f_HealDelay[entity] < GetGameTime())
			{
				f_HealDelay[entity] = GetGameTime() + 1.0;
				int color[4];
				
				color[0] = 255;
				color[1] = 255;
				color[2] = 0;
				color[3] = 255;
		
				TE_SetupBeamRingPoint(powerup_pos, 10.0, 500.0, g_BeamIndex_heal, -1, 0, 5, 0.5, 5.0, 1.0, color, 0, 0);
	   			TE_SendToAll();
	   			for (int target = 1; target <= MaxClients; target++)
				{
					if (IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target) == view_as<int>(TFTeam_Red) && TeutonType[target] == 0)
					{
						GetClientAbsOrigin(target, client_pos);
						if (GetVectorDistance(powerup_pos, client_pos, true) <= 90000)
						{
							EmitSoundToClient(target, SOUND_ARMOR_BEAM, target, _, 90, _, 1.0);
							EmitSoundToClient(target, SOUND_ARMOR_BEAM, target, _, 90, _, 1.0);
							EmitSoundToClient(target, SOUND_ARMOR_BEAM, target, _, 90, _, 1.0);
							int Armor_Max = 300;
							int Extra = 0;
						
							Extra = Armor_Level[target];
								
							Armor_Max = MaxArmorCalculation(Extra, target, 1.0);
								
							
								
							if(Armor_Charge[target] < Armor_Max)
							{
								if(Extra == 50)
									Armor_Charge[target] += 75 / 5;
									
								else if(Extra == 100)
									Armor_Charge[target] += 100 / 5;
									
								else if(Extra == 150)
									Armor_Charge[target] += 200 / 5;
									
								else if(Extra == 200)
									Armor_Charge[target] += 350 / 5;
									
								else
									Armor_Charge[target] += 25 / 5;
											
								if(Armor_Charge[target] >= Armor_Max)
								{
									Armor_Charge[target] = Armor_Max;
								}
							}
						}
					}
				}
   			}
   			if(f_Duration[entity] < GetGameTime())
   			{
   				RemoveEntity(entity);
   				return Plugin_Stop;	
   			}
   			return Plugin_Continue;
		}
		else
		{
			return Plugin_Stop;	
		}
	}
	else
	{
		return Plugin_Stop;	
	}
}



public void PlaceableTempomaryHealingGrenade(int client)
{
	if (ability_cooldown[client] < GetGameTime())
	{
		ability_cooldown[client] = GetGameTime() + 140.0;
		
		CreateTimer(140.0, M3_Ability_Is_Back, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
		
		int entity = CreateEntityByName("tf_projectile_pipe");
		if(IsValidEntity(entity))
		{
			static float pos[3], ang[3], vel_2[3];
			GetClientEyeAngles(client, ang);
			GetClientEyePosition(client, pos);	
		
			ang[0] -= 8.0;
			
			float speed = 1500.0;
			
			vel_2[0] = Cosine(DegToRad(ang[0]))*Cosine(DegToRad(ang[1]))*speed;
			vel_2[1] = Cosine(DegToRad(ang[0]))*Sine(DegToRad(ang[1]))*speed;
			vel_2[2] = Sine(DegToRad(ang[0]))*speed;
			vel_2[2] *= -1;
			
			int team = GetClientTeam(client);
				
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntProp(entity, Prop_Send, "m_iTeamNum", team, 1);
			SetEntProp(entity, Prop_Send, "m_nSkin", (team-2));
			SetEntPropFloat(entity, Prop_Send, "m_flDamage", 0.0); 
			SetEntPropEnt(entity, Prop_Send, "m_hThrower", client);
			SetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher", 0);
			for(int i; i<4; i++)
			{
				SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", g_ProjectileModel, _, i);
			}
			
			SetVariantInt(team);
			AcceptEntityInput(entity, "TeamNum", -1, -1, 0);
			SetVariantInt(team);	
			AcceptEntityInput(entity, "SetTeam", -1, -1, 0); 
			
			SetEntPropEnt(entity, Prop_Send, "m_hLauncher", EntRefToEntIndex(i_StickyAccessoryLogicItem[client]));
			//Make them barely bounce at all.
			DispatchSpawn(entity);
			TeleportEntity(entity, pos, ang, vel_2);
			
			IsCustomTfGrenadeProjectile(entity, 9999999.0);
			CClotBody npc = view_as<CClotBody>(entity);
			npc.m_bThisEntityIgnored = true;
			
			float Healing_Amount = 10.0;
			
			Healing_Amount *= Attributes_FindOnPlayer(client, 8, true, 1.0, true);
			
			f_HealDelay[entity] = GetGameTime() + 1.0;
			f_Duration[entity] = GetGameTime() + 10.0;
			
			SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
			 
			DataPack pack;
			CreateDataTimer(0.1, Timer_Detect_Player_Near_Healing_Grenade, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			pack.WriteCell(EntIndexToEntRef(entity));
			pack.WriteCell(Healing_Amount);	
			pack.WriteCell(GetClientUserId(client));
		}
	}
	else
	{
		float Ability_CD = ability_cooldown[client] - GetGameTime();
		
		if(Ability_CD <= 0.0)
			Ability_CD = 0.0;
			
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);	
	}
}


public Action Timer_Detect_Player_Near_Healing_Grenade(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	float Healing_Amount = pack.ReadCell();
	int client = GetClientOfUserId(pack.ReadCell());
	if(IsValidEntity(entity) && entity>MaxClients)
	{
		if(IsValidClient(client))
		{
			float powerup_pos[3];
			float client_pos[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", powerup_pos);
			if(f_HealDelay[entity] < GetGameTime())
			{
				f_HealDelay[entity] = GetGameTime() + 1.0;
				int color[4];
				
				color[0] = 0;
				color[1] = 255;
				color[2] = 0;
				color[3] = 255;
		
				TE_SetupBeamRingPoint(powerup_pos, 10.0, 500.0, g_BeamIndex_heal, -1, 0, 5, 0.5, 5.0, 1.0, color, 0, 0);
	   			TE_SendToAll();
	   			for (int target = 1; target <= MaxClients; target++)
				{
					if (IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target) == view_as<int>(TFTeam_Red) && TeutonType[target] == 0)
					{
						GetClientAbsOrigin(target, client_pos);
						if (GetVectorDistance(powerup_pos, client_pos, true) <= 90000)
						{
							if(dieingstate[target] > 0)
							{
								EmitSoundToClient(target, SOUND_HEAL_BEAM, target, _, 90, _, 1.0);
								if(i_CurrentEquippedPerk[client] == 1)
								{
									SetEntityHealth(target,  GetClientHealth(target) + 12);
									dieingstate[target] -= 20;
								}
								else
								{
									SetEntityHealth(target,  GetClientHealth(target) + 6);
									dieingstate[target] -= 10;
								}
								if(dieingstate[target] < 1)
								{
									dieingstate[target] = 1;
								}
							}
							else
							{
								if(f_TimeUntillNormalHeal[target] < GetGameTime())
								{
									Healing_Amount *= 0.25;
								}
								if(Healing_Amount < 10.0)
								{
									Healing_Amount = 10.0;
								}
								EmitSoundToClient(target, SOUND_HEAL_BEAM, target, _, 90, _, 1.0);
								StartHealingTimer(target, 0.1, RoundToCeil(Healing_Amount * 0.1), 10);
								
								Healing_done_in_total[client] += RoundToCeil(Healing_Amount);		
							}
						}
					}
				}
				for(int entitycount_again; entitycount_again<i_MaxcountNpc_Allied; entitycount_again++)
				{
					int baseboss_index_allied = EntRefToEntIndex(i_ObjectsNpcs_Allied[entitycount_again]);
					if (IsValidEntity(baseboss_index_allied))
					{
						if(!b_ThisEntityIgnored[baseboss_index_allied])
						{
							GetEntPropVector(baseboss_index_allied, Prop_Data, "m_vecAbsOrigin", client_pos);
							if (GetVectorDistance(powerup_pos, client_pos, true) <= 90000)
							{
								if(f_TimeUntillNormalHeal[baseboss_index_allied] < GetGameTime())
								{
									Healing_Amount *= 0.25;
								}
								if(Healing_Amount < 10.0)
								{
									Healing_Amount = 10.0;
								}
							
								StartHealingTimer(baseboss_index_allied, 0.1, RoundToCeil(Healing_Amount * 0.1), 10);
							}
						}
					}
				}
   			}
   			if(f_Duration[entity] < GetGameTime())
   			{
   				RemoveEntity(entity);
   				return Plugin_Stop;	
   			}
   			return Plugin_Continue;
		}
		else
		{
			return Plugin_Stop;	
		}
	}
	else
	{
		return Plugin_Stop;	
	}
}


public Action M3_Ability_Is_Back(Handle cut_timer, int ref)
{
	int client = EntRefToEntIndex(ref);
	
	if (IsValidClient(client))
	{
		ClientCommand(client, "playgamesound items/gunpickup2.wav");
		SetHudTextParams(-1.0, 0.45, 3.01, 34, 139, 34, 255);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "M3 Ability Is Back");
	}
	return Plugin_Handled;
}

public void GearTesting(int client)
{
	if(dieingstate[client] > 0)
	{
		if (ability_cooldown_2[client] < GetGameTime())
		{
	//		PrintToChatAll("User is dead");
		}
		else
		{
			float Ability_CD = ability_cooldown_2[client] - GetGameTime();
			
			if(Ability_CD <= 0.0)
				Ability_CD = 0.0;
				
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);	
		}		
	}
	else
	{
		if (ability_cooldown[client] < GetGameTime())
		{
			ability_cooldown[client] = GetGameTime() + 500.0;


			CreateTimer(500.0, M3_Ability_Is_Back, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);

			SetEntityMoveType(client, MOVETYPE_NONE);

			i_ClientHasCustomGearEquipped[client] = true;
			
			CreateTimer(3.0, QuantumActivate, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
		//	ClientCommand(client, "playgamesound mvm/mvm_tank_start.wav");

			EmitSoundToAll("mvm/mvm_tank_start.wav", client, SNDCHAN_STATIC, 70, _, 0.9);

			float startPosition[3];
			float position[3];
			GetClientAbsOrigin(client, startPosition);

			TE_SetupExplosion(startPosition, gExplosive1, 10.0, 1, 0, 0, 0);
			TE_SendToAll();
			position[0] = startPosition[0];
			position[1] = startPosition[1];
			position[2] += startPosition[2] + 500.0;
			startPosition[2] += -500;
			TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 3.0, 30.0, 30.0, 0, 0.9, {255, 255, 255, 255}, 3);
			TE_SendToAll();
			TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.8, 50.0, 50.0, 0, 0.9, {200, 255, 200, 255}, 3);
			TE_SendToAll();
			TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.5, 80.0, 80.0, 0, 0.9, {180, 255, 180, 255}, 3);
			TE_SendToAll();
			TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.4, 100.0, 100.0, 0, 0.8, {120, 255, 120, 255}, 3);
			TE_SendToAll();
		}
		else
		{
			float Ability_CD = ability_cooldown[client] - GetGameTime();
			
			if(Ability_CD <= 0.0)
				Ability_CD = 0.0;
				
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			SetHudTextParams(-1.0, 0.90, 3.01, 34, 139, 34, 255);
			SetGlobalTransTarget(client);
			ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);
		}
	}
}

public Action QuantumActivate(Handle cut_timer, int ref)
{
	int client = EntRefToEntIndex(ref);
	float startPosition[3];
	GetClientAbsOrigin(client, startPosition);

	if(IsValidClient(client))
	{
		if(TeutonType[client] == TEUTON_NONE && dieingstate[client] == 0 && IsPlayerAlive(client))
		{
			i_HealthBeforeSuit[client] = GetClientHealth(client);

			i_ClientHasCustomGearEquipped[client] = true;
			

			Store_GiveAll(client, 50, true);
			ViewChange_PlayerModel(client);
			
			float HealthMulti = float(CashSpentTotal[client]);
			HealthMulti = Pow(HealthMulti, 1.2);
			HealthMulti *= 0.025;

			SetEntityHealth(client, RoundToCeil(HealthMulti));

			SetEntityMoveType(client, MOVETYPE_WALK);

			Store_GiveSpecificItem(client, "Quantum Repeater");
			Store_GiveSpecificItem(client, "Quantum Nanosaber");
			
			SetAmmo(client, 1, 9999);
			SetAmmo(client, 2, 9999);
		
			startPosition[2] += 25.0;
			makeexplosion(client, client, startPosition, "", 0, 0);

			CreateTimer(30.0, QuantumDeactivate, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_WALK);

			i_ClientHasCustomGearEquipped[client] = false;
		}
	}
	return Plugin_Handled;
}

public Action QuantumDeactivate(Handle cut_timer, int ref)
{
	int client = EntRefToEntIndex(ref);
	if(IsValidClient(client) && i_HealthBeforeSuit[client] > 0)
	{
		i_ClientHasCustomGearEquipped[client] = false;
		int health = i_HealthBeforeSuit[client];

		i_HealthBeforeSuit[client] = 0;
	//	SetEntityMoveType(client, MOVETYPE_WALK);

		Store_RemoveSpecificItem(client, "Quantum Repeater");
		Store_RemoveSpecificItem(client, "Quantum Nanosaber");
		//Remove both just in case.
		
		TF2_RegeneratePlayer(client);
	
		ViewChange_PlayerModel(client);
		Store_ApplyAttribs(client);
		Store_GiveAll(client, health);

		CurrentClass[client] = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"));
		ViewChange_DeleteHands(client);
		ViewChange_UpdateHands(client, CurrentClass[client]);
	}
	return Plugin_Handled;
}


public float GetAbilityCooldownM3(int client)
{
	return ability_cooldown[client] - GetGameTime();
}


public void SetAbilitySlotCount(int client, int value)
{
	Attack3AbilitySlotArray[client] = value;
}

public int GetAbilitySlotCount(int client)
{
	return Attack3AbilitySlotArray[client];
}
