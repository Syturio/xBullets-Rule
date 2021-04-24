//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

/*
		   ================
				xDescription ~
		   ================
		   
			This simple plugin is mainly for Surf Mod Servers wich have the 
			Rule that only allows players to shoot X bullets of AWP every 
			Xsecs./spot.	The main porpuse of that rule is to make players 
			move/surf more, and stay less time camping with AWP. 
			It forces AWP to have X ammo (3 by default), 
			once the player shoots the X bullets, 	he will have to 
			wait X seconds (15 by default) before he can shoot them again. 
			Also, the refresh time starts at the first bullet, 
			wich means your ammo still gets refreshed even if you 
			only used 1 bullet.

			
			
		   ================
				xCvars ~
		   ================
		   
		    • amx_time_xbullets - The amount of time player has to wait before he gets new ammo. (15 default)
			• amx_ammo_xbullets - The amount bullets player gets on AWP. (3 default)

			
		   
		   ================
				xChangelog  ~
		   ================

		    - Version: 1.0 (11 January 2015)
				* Public release.
		   
		    - Version: 1.1 (12 January 2015)
				* Optimization, improvements.
				
		    - Version: 2.0 (10 August 2015)
				* Fixed a bug, the plugin now works properly.
				* Removed unnecessary code and loops.
				
		    - Version: 2.1 (17 August 2015)
				* More optimizations.
				* Fixed a error that appear on console.
				* Added cvar to see servers using this plugin.
*/  

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>

#pragma tabsize 0

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

new const 	PLUGIN []		=	"xBullets_Rule",
					VERSION []	=	"2.1",
					AUTHOR []	=	"Syturio"

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

new Float:startTime[33]
new bool:wait_1[33], bool:wait_2[33]
new clip, ammo
new xTime, xAmmo
new Float:xCvar, Float:yTime

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(PLUGIN, VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	
	xTime = register_cvar("amx_time_xbullets", "15")
	xAmmo = register_cvar("amx_ammo_xbullets", "3")
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "onAwpPrimaryAttack")
	register_event( "CurWeapon", "Event_CurWeapon", "be", "1=1", "2=18" )
}

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

public Event_CurWeapon() // If player got AWP
	set_task(0.1, "ModifyAWP")

public onAwpPrimaryAttack(ent) // If player shoots with AWP
{
	new id = pev(ent, pev_owner)
	  
	if(!wait_2[id]) // Starts the 'xTime' on the first bullet.
	{
		set_task(1.0, "Countdown", id, _, _, "b")
		startTime[id] = get_gametime()
		wait_1[id] = true
		wait_2[id] = true
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

public ModifyAWP()
{
	new Players[32], playerCount, i
    get_players(Players, playerCount, "ach")
	
    for(i = 0; i < playerCount; i++)
    {
        new id = Players[i]
		
        if(!wait_1[id])
		{
            if(get_user_weapon(id, ammo, clip) == CSW_AWP)
			{
                if(ammo > get_pcvar_num(xAmmo))
                {
                    cs_set_weapon_ammo(find_ent_by_owner(-1, "weapon_awp", id), 3)
                    cs_set_user_bpammo(id, CSW_AWP, 0)
                }
            }
		}
	}
}

public Countdown(id)
{
	if(wait_1[id] && is_user_alive(id))
	{
		yTime = get_gametime() - startTime[id]
		xCvar = get_pcvar_float(xTime)
		
		if(yTime < xCvar)
		{
			cs_set_user_bpammo(id, CSW_AWP, 0)

			if(get_user_weapon(id, ammo, clip) == CSW_AWP && ammo == 0)
				client_print(id, print_center, "Next Ammo in [%d]", floatround(xCvar - get_gametime() + startTime[id])) // Countdown Message
			else
				client_print(id,print_center, " ") // To insta-hide the Countdown Message if player changes weapon.
		}
		else if(yTime - xCvar >= 0)
		{
			cs_add_player_ammo(id, CSW_AWP, 3)

			wait_1[id] = false
			wait_2[id] = false

			if(get_user_weapon(id) != CSW_AWP)
				client_print(id, print_center, "Your AWP Ammo is ready!")
			else
				client_print(id,print_center, " ") // To insta-hide the Countdown Message at 0 sec.
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

public client_disconnect(id)
	remove_task(id)

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

cs_add_player_ammo(id, iId, iAmmo, iMaxAmmo = 0)
{
    new szWeapon[32]

    if(get_weaponname(iId, szWeapon, charsmax(szWeapon)))
    {
        new iWeapon = find_ent_by_owner(-1, szWeapon,id)

        if(iWeapon > 0)
        {
            new iNewAmmo = iMaxAmmo > 0 ? min(cs_get_weapon_ammo(iWeapon) + iAmmo, iMaxAmmo) : cs_get_weapon_ammo(iWeapon) + iAmmo
            cs_set_weapon_ammo(iWeapon, iNewAmmo)
            return iNewAmmo
        }
    }

    return 0
}

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////