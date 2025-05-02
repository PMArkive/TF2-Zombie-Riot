#pragma semicolon 1
#pragma newdecls required

#define MAX_COSMIC_BEAM_USES 3

#define COSMIC_BEAM_ARMTIME 2.5		//how long until the thrown ball initiates stage 1 of the beam.

#define COSMIC_BEAM_PHASE_ONE_TIME	3.0		//how long after the ball triggers the actual beam appears and starts to deal damage
#define COSMIC_BEAM_DURATION		10.0	//simply how long it exists for.

int i_LasersUsedThisWave;
static float fl_cosmic_beam_charge[MAXTF2PLAYERS];
static int i_BallModel;

static float fl_BeamActive[MAXTF2PLAYERS];

void CosmicBeam_OnMapStart()
{
	Zero(fl_cosmic_beam_charge);
	Zero(fl_BeamActive);

	i_BallModel = PrecacheModel("models/workshop/weapons/c_models/c_quadball/w_quadball_grenade.mdl" , true);
}

void CosmicBeam_OnWaveEnd()
{
	i_LasersUsedThisWave = 0;
}


bool 	IsCosmicBeamMaxxed() 				{return CosmicBeamsUsed() > MAX_COSMIC_BEAM_USES; 		}
int 	CosmicBeamsUsed() 					{return i_LasersUsedThisWave;							}
float 	CosmicBeamChargeAmount(int client) 	{return fl_cosmic_beam_charge[client];					}
float 	CosmicBeamActiveTime(int client)	{return fl_BeamActive[client];							}

void GiveCosmicOnDamage(int client, int victim, float damage, int damagetype)
{
	if(GetAbilitySlotCount(client) != M3_COSMIC_BEAM)
		return;
		
	//if its melee dmg, block it.
	if(damagetype & DMG_CLUB)
		return; 

	int MinCashMaxGain = CurrentCash;
	if(MinCashMaxGain <= 1000)
		MinCashMaxGain = 1000;

	MinCashMaxGain -= 250;

	if(MinCashMaxGain >= 200000)
	{
		MinCashMaxGain = 200000;
	}
	
	float DamageForMaxCharge = (Pow(2.0 * MinCashMaxGain, 1.2) + MinCashMaxGain * 3.0);
	
	if(b_thisNpcIsARaid[victim])
		DamageForMaxCharge *= 0.85;

	if(Rogue_Mode())// Rogue op
		DamageForMaxCharge *= 1.5;

	fl_cosmic_beam_charge[client] += (damage / DamageForMaxCharge);
	if(fl_cosmic_beam_charge[client] >= 1.0)
		fl_cosmic_beam_charge[client] = 1.0;
	//Has to be atleast 3k.
}


void Initiate_Cosmic_Beam(int client)
{
	if(IsCosmicBeamMaxxed())
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		CPrintToChatAll("Beam Uses maxxed: %i", i_LasersUsedThisWave);
		//return;
	}
	float GameTime = GetGameTime();
	if(fl_m3_ability_cooldown[client] > GameTime)
	{
		float Ability_CD = fl_m3_ability_cooldown[client] - GameTime;
			
		if(Ability_CD <= 0.0)
			Ability_CD = 0.0;
			
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);

		//return;
	}

	//if(fl_cosmic_beam_charge[client] < 0.0)
	//{
	//	ClientCommand(client, "playgamesound items/medshotno1.wav");
	//	return;
	//}

	CPrintToChatAll("Client had %f charge", fl_cosmic_beam_charge[client]);

	

	int ball = i_Create_Ball(client);

	if(!IsValidEntity(ball))
		return;

	fl_m3_ability_cooldown[client] = GameTime + 10.0;
	i_LasersUsedThisWave++;

	fl_cosmic_beam_charge[client] = 0.0;

	float ArmTime = COSMIC_BEAM_ARMTIME;

	fl_BeamActive[client] = GameTime + ArmTime + COSMIC_BEAM_PHASE_ONE_TIME + COSMIC_BEAM_DURATION;

	DataPack pack;
	CreateDataTimer(ArmTime, TimerOffset_CosmicBeamSpawn, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	pack.WriteCell(EntIndexToEntRef(ball));
	pack.WriteCell(EntIndexToEntRef(client));
}
static Action TimerOffset_CosmicBeamSpawn(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	int client = EntRefToEntIndex(pack.ReadCell());
	
	if(!IsValidClient(client))
	{
		if(IsValidEntity(entity))
		{
			RemoveEntity(entity);
		}
		return Plugin_Stop;
	}
	if(!IsValidEntity(entity))
	{
		return Plugin_Stop;
	}

	float Origin[3], SkyLoc[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", Origin);

	Ruina_Laser_Logic Laser;
	Laser.DoForwardTrace_Custom({-90.0, 0.0, 0.0}, Origin);
	SkyLoc = Laser.End_Point;

	//should show me where it lands and such
	//but not tested yet... (4:24 hours lol)

	float time = 10.0;
	int color[4]; color = {255, 255, 255, 255};

	TE_SetupBeamPoints(Origin, SkyLoc, g_Ruina_BEAM_Combine_Black, 0, 0, 0, time, 30.0, 30.0, 0, 1.0, color, 3);
	TE_SendToAll();


	RemoveEntity(entity);

	return Plugin_Handled;
}


static int i_Create_Ball(int client)
{
	int entity;

	if(b_StickyExtraGrenades[client])
		entity = CreateEntityByName("tf_projectile_pipe_remote");
	else
		entity = CreateEntityByName("tf_projectile_pipe");

	if(!IsValidEntity(entity))
		return -1;

	SetEntitySpike(entity, 3);
	b_StickyIsSticking[entity] = true; //Make them not stick to npcs.
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
	if(b_StickyExtraGrenades[client])
		SetEntProp(entity, Prop_Send, "m_iType", 1);
		
	for(int i; i<4; i++)
	{
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", i_BallModel, _, i);
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
	
	SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);

	return entity;
}