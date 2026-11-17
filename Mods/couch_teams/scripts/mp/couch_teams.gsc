// Couch teams for BO2 local play (Plutonium T6 multiplayer).
//
// Built for 8-player couch sessions where every player runs their own game copy
// and joins one LAN private match (see BO2 Split Launcher). Runs on the host only.
//
// What it does in team modes (TDM, Domination, S&D and so on):
//   - Puts each player on a fixed team based on their player number, so the players
//     sharing a TV are on the same side and nobody gains by looking at the other TV.
//   - Optionally stops players from switching teams from the in-game menu.
//   - Tells each player which team they are on when they first spawn.
// Free-for-all modes and bots are left alone.
//
// Dvars (set with +set on the host's command line, or in the console before the match):
//   couch_teams        "auto" (default), "tv", "alternate" or "off"
//                        tv        = players 1 to couch_tv_size on one team, the rest on the other
//                        alternate = players 1, 3, 5, 7 against 2, 4, 6, 8
//                        auto      = tv when couch_order lists more than couch_tv_size players,
//                                    otherwise alternate
//   couch_tv_size      players per TV, default 4
//   couch_lock         "1" (default) blocks team changes from the menu, "0" allows them
//   couch_order        player names in player order, separated by commas, no spaces after
//                      the commas, for example: Alice,Bob,Carl,Dana,Ed,Fay,Gus,Hal
//                      The launcher fills this in. Players not in the list are numbered
//                      after it, in the order they connect.

#include maps\mp\_utility;

init()
{
    if ( getdvar( "couch_teams" ) == "" )
        setdvar( "couch_teams", "auto" );

    if ( getdvar( "couch_tv_size" ) == "" )
        setdvar( "couch_tv_size", "4" );

    if ( getdvar( "couch_lock" ) == "" )
        setdvar( "couch_lock", "1" );

    level thread couch_install_hooks();
    level thread couch_on_player_connect();
}

couch_install_hooks()
{
    // Let the gametype finish setting up its own callbacks first.
    waittillframeend;

    if ( isdefined( level.couch_hooked ) )
        return;

    level.couch_hooked = 1;
    level.couch_orig_autoassign = level.autoassign;
    level.couch_orig_teammenu = level.teammenu;
    level.autoassign = ::couch_autoassign;
    level.teammenu = ::couch_teammenu;
}

couch_enabled()
{
    if ( !level.teambased )
        return 0;

    if ( getdvar( "couch_teams" ) == "off" )
        return 0;

    if ( self is_bot() )
        return 0;

    if ( !isdefined( level.teams["allies"] ) || !isdefined( level.teams["axis"] ) )
        return 0;

    return 1;
}

couch_order_names()
{
    order = getdvar( "couch_order" );

    if ( order == "" )
        return [];

    return strtok( order, "," );
}

couch_slot_taken( slot )
{
    players = level.players;

    for ( i = 0; i < players.size; i++ )
    {
        other = players[i];

        if ( ( other != self ) && isdefined( other.pers["couch_slot"] ) && ( other.pers["couch_slot"] == slot ) )
            return 1;
    }

    return 0;
}

couch_get_slot()
{
    if ( isdefined( self.pers["couch_slot"] ) )
        return self.pers["couch_slot"];

    names = couch_order_names();
    slot = -1;
    myname = tolower( self.name );

    for ( i = 0; i < names.size; i++ )
    {
        if ( ( slot < 0 ) && ( tolower( names[i] ) == myname ) )
            slot = i;
    }

    if ( slot < 0 )
    {
        // Not in the list: take the lowest free number after the listed players.
        slot = names.size;

        while ( self couch_slot_taken( slot ) )
            slot = slot + 1;
    }

    self.pers["couch_slot"] = slot;
    return slot;
}

couch_mode()
{
    mode = getdvar( "couch_teams" );

    if ( mode == "tv" || mode == "alternate" )
        return mode;

    // auto
    names = couch_order_names();

    if ( names.size > couch_tv_size() )
        return "tv";

    return "alternate";
}

couch_tv_size()
{
    size = getdvarint( "couch_tv_size" );

    if ( size < 1 )
        size = 4;

    return size;
}

couch_team_for_slot( slot )
{
    if ( couch_mode() == "tv" )
    {
        if ( slot < couch_tv_size() )
            return "allies";

        return "axis";
    }

    if ( ( slot % 2 ) == 0 )
        return "allies";

    return "axis";
}

couch_autoassign( comingfrommenu )
{
    if ( !self couch_enabled() )
    {
        self [[ level.couch_orig_autoassign ]]( comingfrommenu );
        return;
    }

    // Choosing "auto-assign" from the menu while unlocked keeps the game's own behaviour.
    if ( comingfrommenu && ( getdvar( "couch_lock" ) == "0" ) )
    {
        self [[ level.couch_orig_autoassign ]]( comingfrommenu );
        return;
    }

    team = couch_team_for_slot( self couch_get_slot() );
    self [[ level.couch_orig_teammenu ]]( team );
}

couch_teammenu( team )
{
    if ( self couch_enabled() && ( getdvar( "couch_lock" ) != "0" ) && isdefined( level.teams[team] ) )
    {
        assigned = couch_team_for_slot( self couch_get_slot() );

        if ( team != assigned )
        {
            self iprintln( "Teams are locked for couch play" );
            team = assigned;
        }
    }

    self [[ level.couch_orig_teammenu ]]( team );
}

couch_on_player_connect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread couch_announce_team();
    }
}

couch_announce_team()
{
    self endon( "disconnect" );

    if ( isdefined( self.pers["couch_announced"] ) )
        return;

    self waittill( "spawned_player" );

    if ( !self couch_enabled() )
        return;

    self.pers["couch_announced"] = 1;
    slot = self couch_get_slot();

    if ( couch_mode() == "tv" )
    {
        tv = int( slot / couch_tv_size() ) + 1;
        self iprintlnbold( "Player " + ( slot + 1 ) + ": you're on TV " + tv + "'s team" );
    }
    else
    {
        teamnum = ( slot % 2 ) + 1;
        self iprintlnbold( "Player " + ( slot + 1 ) + ": you're on team " + teamnum );
    }
}
