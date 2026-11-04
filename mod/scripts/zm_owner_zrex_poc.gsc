// Original offline PoC. PC S6L 20261016 reference: ProjectHiNAtyu/CoDs_GSC_Wiki_Library_IW8Plus,
// commit 55d02741d078eaeeaeeaffa433deef4a439608f8. See zm_sat_scarab_br (598-632),
// agent_manager (19-27), mp_agent (54-75), zombie_utils (30-37,504-525), Ruby Bongo (179-195),
// field_upgrades_dark_flare (79-84), supers (2689-2808,4405-4446), teamrevive (capsuletracepassed).
// Current-client linking, donor residency, all attack paths, and clearance remain UNCONFIRMED.

#using scripts\common\utility;
#using scripts\common\callbacks;
#using scripts\common\values;
#using scripts\mp\supers;
#using scripts\mp\damage;
#using scripts\mp\zm\systems\agent_manager;
#using scripts\mp\zm\zm_utility;
#using scripts\common\ai\aitypes\shared\zombie\zombie_utils;
#using scripts\common\ai\aitypes\shared\zombie\zombie_boss_healthbar;

autoexec owner_zrex_init()
{
    owner_zrex_mark( "boot", "autoexec" );
    level callback::add( #"player_spawned", &owner_zrex_player_ready );
    owner_zrex_open_probe();
}

function owner_zrex_mark( file, phase )
{
    map = level.mapname ?? "pending";
    logstring( "OWNER_ZREX " + phase + " map=" + map );
    nengine_store_set( "owner_zrex_poc", "build", "move3" );
    nengine_store_set( "owner_zrex_poc", "map", map );
    nengine_store_set( "owner_zrex_poc", "time_ms", gettime() );
    nengine_store_set( "owner_zrex_poc", "phase", phase );
    nengine_store_save( "owner_zrex_poc", file );
}

function owner_zrex_player_ready( params )
{
    owner_zrex_open_probe();
}

function owner_zrex_open_probe()
{
    // A slow startup or freshly restored player gets a new bounded window.
    level.owner_zrex_probe_until = gettime() + 45000;
    if ( istrue( level.owner_zrex_probe_running ) )
        return;
    level.owner_zrex_probe_running = 1;
    level thread owner_zrex_register();
}

function owner_zrex_register()
{
    level endon( #"game_ended" );
    refs = [ "super_dark_flare", "super_dark_flare_shadow_ball", "super_dark_flare_13s" ];
    previous = "";
    while ( gettime() < level.owner_zrex_probe_until )
    {
        zm = utility::iszm() || ( isdefined( level.mapname ) && isstartstr( "" + level.mapname, "zm_" ) );
        has_table = isdefined( level.superglobals ) && isdefined( level.superglobals.staticsuperdata );
        present = 0;
        hooked = 0;
        equipped = 0;
        bit = 1;
        foreach ( ref in refs )
        {
            if ( zm && has_table )
            {
                data = level.superglobals.staticsuperdata[ ref ];
                if ( isdefined( data ) )
                {
                    present += bit;
                    if ( owner_zrex_bind( data ) )
                        hooked += bit;
                }
            }
            if ( zm && isdefined( level.players ) )
            {
                foreach ( p in level.players )
                {
                    if ( !isdefined( p ) || !isdefined( p.super ) || !isdefined( p.super.staticdata ) )
                        continue;
                    active = p.super.staticdata;
                    if ( active.ref == ref && owner_zrex_bind( active ) )
                    {
                        equipped |= bit;
                    }
                }
            }
            bit *= 2;
        }
        // Masks are base=1, Shadow Ball=2 and Extension=4. Never assume all variants exist.
        state = "zm=" + zm + " table=" + has_table + " present=" + present + " hooked=" + hooked + " equipped=" + equipped;
        if ( state != previous )
        {
            owner_zrex_mark( "registration", state );
            previous = state;
        }
        wait 0.25;
    }
    owner_zrex_mark( "registration", "probe finished " + previous );
    level.owner_zrex_probe_running = 0;
}

function owner_zrex_bind( data )
{
    if ( !isdefined( data.beginusefunc ) || !isdefined( data.endusefunc ) )
        return false;
    if ( data.beginusefunc != &owner_zrex_begin || data.endusefunc != &owner_zrex_end )
    {
        // Replace the pair atomically. Keep the native charge, weapon and augment bookkeeping.
        data.beginusefunc = &owner_zrex_begin;
        data.endusefunc = &owner_zrex_end;
    }
    return data.beginusefunc == &owner_zrex_begin && data.endusefunc == &owner_zrex_end;
}

function owner_zrex_block( reason )
{
    logstring( "OWNER_ZREX blocked: " + reason );
    owner_zrex_mark( "use", "blocked: " + reason );
    self iprintlnbold( reason );
    // supers_mp::beginsuperuse refunds when beginusefunc returns false.
    return false;
}

function owner_zrex_begin()
{
    owner_zrex_mark( "use", "Dark Flare begin" );
    if ( !isdefined( level.mapname ) || !( utility::iszm() || isstartstr( "" + level.mapname, "zm_" ) ) )
        return self owner_zrex_block( "The Z-Rex requires a Zombies match." );
    if ( !isalive( self ) || !isdefined( self.team ) )
        return self owner_zrex_block( "Spawn before calling the Z-Rex." );
    owner_id = self getentitynumber();
    if ( !isdefined( level.owner_zrex_reservations ) )
        level.owner_zrex_reservations = [];
    if ( isdefined( self.owner_zrex_ticket ) || isdefined( level.owner_zrex_reservations[owner_id] ) )
        return self owner_zrex_block( "Your Z-Rex is already active." );
    if ( owner_zrex_map_uses_boss( undefined ) )
        return self owner_zrex_block( "The map has reserved its Z-Rex encounter." );
    if ( !utility::issharedfuncdefined( #"zombie_utils", #"turn_ai" ) )
        return self owner_zrex_block( "The ally controller is unavailable." );

    type = owner_zrex_receiver_type();
    if ( !isdefined( type ) )
        return self owner_zrex_block( "This map has no verified Z-Rex asset set." );

    spot = self owner_zrex_find_spot();
    if ( !isdefined( spot ) )
        return self owner_zrex_block( "Find open ground for your Z-Rex." );

    if ( !istrue( level.owner_zrex_guards ) )
    {
        // Stock pattern: zm_maneki_neko:39-56; damage:585-595,14215-14224.
        damage::register_scripted_damage_override_func( &owner_zrex_player_damage );
        level callback::add( "on_zombie_phobos_spawn_empowered", &owner_zrex_puke_add );
        level callback::add( "on_zombie_phobos_spawn_roared", &owner_zrex_puke_add );
        level callback::add( "on_zombie_phobos_spawn_parasite", &owner_zrex_puke_add );
        level callback::add( "on_zombie_ai_damaged", &owner_zrex_hit );
        level.owner_zrex_guards = 1;
    }
    ticket = spawnstruct();
    ticket.owner = self;
    ticket.owner_id = owner_id;
    level.owner_zrex_sequence = ( level.owner_zrex_sequence ?? 0 ) + 1;
    ticket.key = "" + level.mapname + "_" + ticket.owner_id + "_" + gettime() + "_" + level.owner_zrex_sequence;
    self.owner_zrex_ticket = ticket;
    level.owner_zrex_reservations[owner_id] = ticket;
    ticket.factory_until = gettime() + 8000;
    level thread owner_zrex_factory_lease( ticket );
    level thread owner_zrex_factory( ticket, type, spot, ( 0, self.angles[1], 0 ), self.team );
    while ( !istrue( ticket.factory_returned ) && gettime() < ticket.factory_until )
        waitframe();
    if ( !istrue( ticket.factory_returned ) || istrue( ticket.factory_uncertain ) )
        return self owner_zrex_block( "Z-Rex creation timed out. This summon stays locked for safety." );
    actor = ticket.actor;
    if ( !isdefined( actor ) || istrue( ticket.closed ) )
        return self owner_zrex_block( "The Z-Rex could not spawn." );
    actor.b_ignore_cleanup = 1;
    actor.b_cleanup_no_respawn = 1;
    actor.ignore_enemy_count = 1;
    actor.no_powerups = 1;
    actor.puke_zombies_no_powerups = 1;
    // Spawn one ally. In zombie_phobos_roar:215-223,328-334 these are the per-actor
    // parasite switch and the replacement callback for ordinary roar spawns.
    actor.var_e46525bdff4f9d3b = 1;
    actor.var_4da43c6a7a1311e9 = &owner_zrex_no_roar_adds;
    // Level-owned cleanup survives an activation thread interrupted during the AI's startup.
    actor utility::callsharedfunc( #"zombie_utils", #"turn_ai", self );
    // Initialization and conversion may take game time. Measure settle AFTER the call returns.
    level thread owner_zrex_evidence( ticket, "converted", "turn helper returned" );
    ticket.settle_until = gettime() + 2500;
    failure = owner_zrex_wait_for_turn( ticket );
    if ( failure != "" )
    {
        owner_zrex_retire( ticket, failure );
        return self owner_zrex_block( "Z-Rex: " + failure );
    }
    // Player-nav placement and a free generic capsule are not proof a full-size Rex can walk.
    // No teleport. Require its own actual nav point plus a reachable exit; otherwise refund.
    if ( !owner_zrex_creature_clearance( ticket ) )
    {
        failure = ticket.reason ?? "no full-size creature path out of this spot";
        owner_zrex_retire( ticket, failure );
        return self owner_zrex_block( "Z-Rex: " + failure );
    }
    actor setthreatbiasgroup( "team_players" );
    actor setsafeguardent( self );
    actor setsafeguardrange( 512 );
    ticket.ready = 1;
    level notify( #"highvis_reload_outline", self.team, [actor] );
    level thread owner_zrex_evidence( ticket, "accepted", "live turned actor on owner team" );
    logstring( "OWNER_ZREX spawned owner=" + self getentitynumber() + " actor=" + actor getentitynumber() );
    self iprintlnbold( "Z-Rex ally active for four minutes." );
    self thread owner_zrex_finish_button( self supers_mp::getcurrentsuper() );
    return true;
}

function owner_zrex_factory_lease( ticket )
{
    // Timeout is evidence of an unresolved result, never evidence of an empty slot.
    level thread owner_zrex_evidence( ticket, "factory_start", "one reserved native factory call" );
    while ( !istrue( ticket.factory_returned ) && gettime() < ticket.factory_until )
        wait 0.25;
    if ( istrue( ticket.factory_returned ) ) return;
    ticket.factory_uncertain = 1;
    level thread owner_zrex_evidence( ticket, "factory_pending", "no return; slot remains locked for this match" );
}

function owner_zrex_factory( ticket, type, spot, angles, team )
{
    // A native script fault here cannot take the input callback or lease monitor with it.
    actor = agent_manager::spawn_agent( type, spot, angles, team );
    if ( !isdefined( actor ) )
    {
        ticket.factory_returned = 1;
        level thread owner_zrex_evidence( ticket, "factory_empty", "factory returned no handle" );
        owner = ticket.owner;
        if ( isdefined( owner ) && owner.owner_zrex_ticket == ticket ) owner.owner_zrex_ticket = undefined;
        if ( level.owner_zrex_reservations[ticket.owner_id] == ticket ) level.owner_zrex_reservations[ticket.owner_id] = undefined;
        return;
    }
    ticket.actor = actor;
    actor.owner_zrex_ticket = ticket;
    ticket.actor_id = actor getentitynumber();
    ticket.deadline = gettime() + 240000;
    level thread owner_zrex_hard_expiry( ticket );
    ticket.original_origin = actor.origin;
    ticket.setup_watchdog = gettime() + 15000;
    level thread owner_zrex_watch( ticket );
    level thread owner_zrex_wait_end( ticket );
    ticket.factory_returned = 1;
    if ( istrue( ticket.factory_uncertain ) || gettime() >= ticket.factory_until
        || !isdefined( ticket.owner ) || !isalive( ticket.owner ) || level.owner_zrex_reservations[ticket.owner_id] != ticket )
    {
        ticket.factory_uncertain = 1;
        owner_zrex_retire( ticket, "late or ownerless factory return" );
        return;
    }
    level thread owner_zrex_evidence( ticket, "created", type );
}

function owner_zrex_receiver_type()
{
    // Scarab boss-rush uses the first ref. DOA's ztron_enemy.gsc:167,522 passes the second
    // subclass through the same factory. A registered name alone is insufficient.
    foreach ( type in [ "sat_spawner_zombie_phobos_zm", "zombie_phobos" ] )
    {
        resolved = function_b3988325430ce242( type ) ?? type;
        if ( !isstartstr( resolved, "actor_" ) )
            resolved = "actor_" + resolved;
        if ( isdefined( level.var_1e2c07e345d293d1 ) )
            resolved = [[ level.var_1e2c07e345d293d1 ]]( resolved );
        if ( !isdefined( resolved ) || !isaitypenamevalid( resolved ) )
            continue;
        // Bind2 already produced a live actor from this exact pair in the owner’s match.
        if ( "" + level.mapname == "zm_sat_scarab" && type == "sat_spawner_zombie_phobos_zm" )
            return type;
        ai = getaitypescriptbundle( resolved );
        if ( !isdefined( ai ) || !isdefined( ai.subclass ) || !isdefined( ai.zombieaisetting ) )
            continue;
        sub = getscriptbundle( hashcat( %"hash_138dab78b1b28a0f", ai.subclass ) );
        if ( !isdefined( sub ) || !isdefined( sub.name ) )
            continue;
        name = isxhash( sub.name ) ? getxhashsourcename( sub.name ) : sub.name;
        if ( name != "zombie_phobos" && !( isxhash( sub.name ) && sub.name == %"zombie_phobos" ) )
            continue;
        settings = getscriptbundle( "zombieaisettings:" + ai.zombieaisetting );
        if ( !isdefined( settings ) || !isdefined( settings.var_394d3c5e6fa40c50 ) )
            continue;
        config = getscriptbundle( settings.var_394d3c5e6fa40c50 );
        if ( isdefined( config ) && isdefined( config.legscriptable ) && isscriptabledefined( config.legscriptable ) )
            return type;
    }
    return undefined;
}

function owner_zrex_map_uses_boss( ally )
{
    // Native collision:103-113 claims the first free map prop and installs an
    // unconditional death watcher. Never borrow an even currently unlinked quest prop.
    if ( getentarray( "phobos_back", #"targetname" ).size )
        return true;
    foreach ( ai in getaiarray() )
    {
        if ( ai != ally && isalive( ai ) && isdefined( ai.subclass ) && ai.subclass == "zombie_phobos"
            && !isdefined( ai.owner_zrex_ticket ) )
            return true;
    }
    return false;
}

function owner_zrex_disable_mount( actor )
{
    trigger = actor.phobos_trigger_origin;
    if ( isdefined( trigger ) && trigger.phobos_owner == actor )
        trigger setusableenabled( 0 );
}

function owner_zrex_wait_for_turn( ticket )
{
    failure = "conversion timed out";
    while ( gettime() < ticket.settle_until )
    {
        actor = ticket.actor;
        owner = ticket.owner;
        if ( istrue( ticket.closed ) ) return ticket.reason ?? "cleanup already started";
        if ( !isdefined( owner ) || !isalive( owner ) ) return "owner unavailable";
        if ( !isdefined( actor ) || !isalive( actor ) ) return "actor unavailable";
        if ( owner_zrex_map_uses_boss( actor ) ) return "authentic encounter reserved";
        owner_zrex_disable_mount( actor );
        if ( actor.team == owner.team && actor utility::ent_flag( "turned" ) )
        {
            // A stale attention target after native conversion is not proof of hostile allegiance.
            if ( isdefined( actor.enemy ) && isplayer( actor.enemy ) )
                actor clearenemy();
            return "";
        }
        failure = actor.team == owner.team ? "turned flag absent" : "owner team mismatch";
        waitframe();
    }
    return failure;
}

function owner_zrex_find_spot()
{
    if ( !isnavmeshloaded() )
        return undefined;
    // Conservative open-ground proxy, not a measurement of this asset's native bounds.
    for ( i = 0; i < 8; i++ )
    {
        direction = anglestoforward( ( 0, self.angles[1] + 45 * i, 0 ) );
        guess = self.origin + direction * 448;
        ground = getclosestpointonnavmesh( guess, self );
        if ( !isdefined( ground ) || distancesquared( ground, guess ) > 96 * 96 )
            continue;
        if ( !capsuletracepassed( ground + ( 0, 0, 4 ), 128, 320, undefined, 0, 0 ) )
            continue;
        if ( getaiarrayinradius( ground, 176 ).size )
            continue;
        occupied = 0;
        foreach ( player in level.players )
        {
            if ( isdefined( player ) && distancesquared( player.origin, ground ) < 192 * 192 )
                occupied = 1;
        }
        if ( !occupied )
            return ground;
    }
    return undefined;
}

function owner_zrex_end( fromdeath, attacker )
{
    return false;
}

function owner_zrex_no_roar_adds( phobos, points )
{
    return;
}

// Puke has a separate attack path. The stock callback carries the new zombie and
// zombie_phobos_puke:248-253 explicitly assigns its owner before notifying.
function owner_zrex_puke_add( params )
{
    child = params.zombie;
    if ( !isdefined( child ) )
        return;
    ticket = undefined;
    if ( isdefined( child.owner ) && isdefined( child.owner.owner_zrex_ticket ) && child.owner.owner_zrex_ticket.actor == child.owner )
        ticket = child.owner.owner_zrex_ticket;
    // Native roar:381-389 adds the exact child to the parent before the notification.
    if ( !isdefined( ticket ) )
        foreach ( p in level.players )
        {
            if ( !isdefined( p ) || !isdefined( p.owner_zrex_ticket ) || !isdefined( p.owner_zrex_ticket.actor ) )
                continue;
            parent = p.owner_zrex_ticket.actor;
            if ( isdefined( parent.phobos_spawned_zombies ) )
            {
                foreach ( owned in parent.phobos_spawned_zombies )
                    if ( owned == child )
                    {
                        ticket = p.owner_zrex_ticket;
                        break;
                    }
                if ( isdefined( ticket ) ) break;
            }
        }
    if ( !isdefined( ticket ) ) return; // no inferred attribution by team, position or appearance
    child.owner_zrex_ticket = ticket;
    child.ignore_enemy_count = 1;
    child.b_cleanup_no_respawn = 1;
    child.no_powerups = 1;
    if ( !isdefined( ticket.saw_child ) )
    {
        ticket.saw_child = 1;
        level thread owner_zrex_evidence( ticket, "owned_add", "removing attributed child " + child getentitynumber() );
    }
    level thread owner_zrex_remove_add( child, ticket );
}

function owner_zrex_remove_add( child, ticket )
{
    waitframe(); // allow the stock spawn callback to finish
    if ( isdefined( child ) && child.owner_zrex_ticket == ticket )
        child delete();
}

function owner_zrex_damage_source( ent )
{
    if ( !isdefined( ent ) )
        return false;
    if ( isdefined( ent.owner_zrex_ticket ) && !isplayer( ent ) )
        return true;
    return isdefined( ent.owner ) && !isplayer( ent.owner ) && isdefined( ent.owner.owner_zrex_ticket );
}

function owner_zrex_player_damage( inflictor, attacker, amount, flags, mod, weapon, point, dir, hitloc, offset )
{
    if ( isplayer( self ) && ( owner_zrex_damage_source( inflictor ) || owner_zrex_damage_source( attacker ) ) )
        return 0;
    return amount;
}

// One receipt per summon, restricted to a direct damage callback on an opposing AI.
function owner_zrex_hit( params )
{
    actor = params.eattacker;
    if ( !isdefined( actor ) || !isdefined( actor.owner_zrex_ticket ) || !isdefined( params.idamage ) || params.idamage <= 0 )
        return;
    ticket = actor.owner_zrex_ticket;
    if ( ticket.actor != actor || !isdefined( self.team ) || self.team == actor.team || isplayer( self ) )
        return;
    ticket.hit_target = self;
    ticket.hit_time = gettime();
    if ( isdefined( ticket.saw_hit ) ) return;
    ticket.saw_hit = 1;
    logstring( "OWNER_ZREX hostile damage callback actor=" + actor getentitynumber() + " target=" + self getentitynumber() + " damage=" + params.idamage );
    level thread owner_zrex_evidence( ticket, "hostile_hit", "target " + self getentitynumber() + " damage " + params.idamage );
}

function owner_zrex_evidence( ticket, stage, why )
{
    actor = ticket.actor;
    owner = ticket.owner;
    exists = isdefined( actor );
    live = exists && isalive( actor );
    enemy_id = -1;
    player_target = 0;
    displacement = -1;
    speed = -1;
    path_left = -1;
    owner_dist = -1;
    if ( live )
    {
        displacement = int( distance( actor.origin, ticket.original_origin ) );
        if ( istrue( ticket.ready ) && isstartstr( stage, "movement" ) )
        {
            speed = int( length( actor getvelocity() ) );
            path_left = int( actor pathdisttogoal() );
        }
        if ( isdefined( owner ) ) owner_dist = int( distance( actor.origin, owner.origin ) );
        if ( isdefined( actor.enemy ) )
        {
            enemy_id = actor.enemy getentitynumber();
            player_target = isplayer( actor.enemy );
        }
    }
    nengine_store_set( "owner_zrex_v3", "stage", stage );
    nengine_store_set( "owner_zrex_v3", "detail", why );
    nengine_store_set( "owner_zrex_v3", "time_ms", gettime() );
    nengine_store_set( "owner_zrex_v3", "owner_id", ticket.owner_id );
    nengine_store_set( "owner_zrex_v3", "actor_id", ticket.actor_id ?? -1 );
    nengine_store_set( "owner_zrex_v3", "handle_defined", exists );
    nengine_store_set( "owner_zrex_v3", "alive", live );
    nengine_store_set( "owner_zrex_v3", "same_team", live && isdefined( owner ) && actor.team == owner.team );
    nengine_store_set( "owner_zrex_v3", "turned", live && actor utility::ent_flag( "turned" ) );
    nengine_store_set( "owner_zrex_v3", "enemy_id", enemy_id );
    nengine_store_set( "owner_zrex_v3", "enemy_player", player_target );
    nengine_store_set( "owner_zrex_v3", "displacement", displacement );
    nengine_store_set( "owner_zrex_v3", "speed", speed );
    nengine_store_set( "owner_zrex_v3", "path_left", path_left );
    nengine_store_set( "owner_zrex_v3", "owner_distance", owner_dist );
    nengine_store_set( "owner_zrex_v3", "creature_nav_at_spawn", ticket.nav_at_spawn ?? -1 );
    nengine_store_set( "owner_zrex_v3", "creature_exit_found", ticket.walk_exit ?? -1 );
    nengine_store_save( "owner_zrex_v3", ticket.key + "_" + stage );
}

function owner_zrex_reachable( actor, position )
{
    point = getclosestpointonnavmesh( position, actor, 1, 1, 1 );
    if ( !isdefined( point ) || distancesquared( point, position ) > 192 * 192 )
        return undefined;
    if ( distancesquared( actor.origin, point ) < 96 * 96 )
        return point;
    path = actor findpath( actor.origin, point );
    // BO7 AI findpath returns an indexed list of positions. A nonempty partial
    // path ending at a wall does not certify a reachable creature goal.
    if ( isarray( path ) && path.size > 0 && distancesquared( path[path.size - 1], point ) <= 96 * 96 )
        return point;
    return undefined;
}

function owner_zrex_creature_clearance( ticket )
{
    for ( pass = 0; pass < 3; pass++ )
    {
        actor = ticket.actor;
        if ( istrue( ticket.closed ) || !isdefined( actor ) || !isalive( actor ) || !isdefined( ticket.owner ) )
            return false;
        actor_nav = getclosestpointonnavmesh( actor.origin, actor, 1, 1, 1 );
        ticket.nav_at_spawn = isdefined( actor_nav ) && distancesquared( actor.origin, actor_nav ) <= 96 * 96;
        ticket.walk_exit = 0;
        if ( ticket.nav_at_spawn )
            for ( j = 0; j < 4; j++ )
            {
                dir = anglestoforward( ( 0, actor.angles[1] + 90*j, 0 ) );
                exit_point = owner_zrex_reachable( actor, actor.origin + dir * 330 );
                if ( isdefined( exit_point ) && distancesquared( exit_point, actor.origin ) >= 192 * 192 )
                {
                    ticket.walk_exit = 1;
                    level thread owner_zrex_evidence( ticket, "creature_nav", "own nav origin and reachable exit" );
                    return true;
                }
            }
        if ( pass < 2 ) wait 0.2;
    }
    level thread owner_zrex_evidence( ticket, "creature_nav", "no verified full-size exit" );
    return false;
}

function owner_zrex_set_focus( ticket, target )
{
    actor = ticket.actor;
    if ( isdefined( target ) && ( !isdefined( ticket.focus ) || target != ticket.focus ) )
    {
        actor utility::callsharedfunc( #"zombie_utils", #"settarget", target, "owner_zrex_hostile", 8307 );
        ticket.focus = target;
    }
    else if ( !isdefined( target ) && istrue( ticket.had_focus ) )
    {
        actor utility::callsharedfunc( #"zombie_utils", #"settarget", undefined, "owner_zrex_hostile", 8307 );
        ticket.focus = undefined;
    }
    ticket.had_focus = isdefined( target );
}

function owner_zrex_contact( ticket, target )
{
    actor = ticket.actor;
    now = gettime();
    // A hostile under the belly can be inside our distance cutoff but outside the
    // native forward bite arc. Require measured lack of movement AND damage first.
    if ( !isdefined( ticket.contact_target ) || ticket.contact_target != target )
    {
        ticket.contact_target = target;
        ticket.contact_origin = actor.origin;
        ticket.contact_since = now;
        ticket.standoff_until = 0;
    }
    if ( ( isdefined( ticket.hit_target ) && ticket.hit_target == target && ticket.hit_time > ticket.contact_since )
        || distancesquared( ticket.contact_origin, actor.origin ) >= 64 * 64 )
    {
        ticket.contact_origin = actor.origin;
        ticket.contact_since = now;
    }
    if ( now < ticket.standoff_until ) return "holding reachable standoff goal";
    if ( now - ticket.contact_since < 3000 ) return "waiting for native melee";
    // Probe one location per steering tick, alternating sides, then behind and ahead.
    angles = [ 90, -90, 180, 0 ];
    index = ticket.standoff_index ?? 0;
    ticket.standoff_index = ( index + 1 ) % angles.size;
    dir = anglestoforward( ( 0, actor.angles[1] + angles[index], 0 ) );
    point = owner_zrex_reachable( actor, target.origin + dir * 310 );
    if ( !isdefined( point ) || distancesquared( point, actor.origin ) < 160 * 160 )
        return ""; // give a different hostile a turn in this same tick
    actor zombie_utils::update_bt_goal( point );
    ticket.standoff_until = now + 2500;
    if ( !isdefined( ticket.saw_standoff ) )
    {
        ticket.saw_standoff = 1;
        level thread owner_zrex_evidence( ticket, "standoff", "no displacement or damage; goal for target " + target getentitynumber() );
    }
    return "reachable close-contact standoff goal issued";
}

function owner_zrex_steer( ticket )
{
    actor = ticket.actor;
    owner = ticket.owner;
    if ( !utility::issharedfuncdefined( #"zombie_utils", #"settarget" ) )
        return "stock target-priority hook unavailable";
    // Native Phobos movement projects self.enemy onto its OWN nav layer. Give that
    // controller a reachable hostile/goal, never an owner as an enemy. Do not teleport.
    if ( isdefined( actor.enemy ) && isplayer( actor.enemy ) )
        actor clearenemy();
    distance_to_owner = distance( actor.origin, owner.origin );
    if ( distance_to_owner > 1100 ) ticket.following = 1;
    if ( distance_to_owner < 600 ) ticket.following = 0;
    if ( !istrue( ticket.following ) )
    {
        team = zm_utility::get_zombie_team();
        nearby = utility::get_array_of_closest( actor.origin, getaiarrayinradius( actor.origin, 1800, team ) );
        probes = 0;
        foreach ( target in nearby )
        {
            if ( !isalive( target ) || isplayer( target ) || target == actor || !isdefined( target.team )
                || target.team != team || target.team == owner.team || isdefined( target.owner_zrex_ticket ) )
                continue;
            if ( probes >= 3 ) break;
            probes++;
            delta = actor.origin - target.origin;
            near = length( delta ) <= 240;
            if ( near )
            {
                action = owner_zrex_contact( ticket, target );
                if ( action == "" ) continue;
                owner_zrex_set_focus( ticket, target );
                return action;
            }
            goal = owner_zrex_reachable( actor, target.origin + vectornormalize( delta ) * 160 );
            if ( !isdefined( goal ) ) continue;
            ticket.contact_target = undefined;
            owner_zrex_set_focus( ticket, target );
            actor zombie_utils::update_bt_goal( goal );
            return "reachable hostile goal issued";
        }
    }
    owner_zrex_set_focus( ticket, undefined );
    if ( distance_to_owner <= 400 )
        return "staying near owner; no reachable hostile";
    goal = owner_zrex_reachable( actor, owner.origin + vectornormalize( actor.origin - owner.origin ) * 240 );
    if ( !isdefined( goal ) ) return "no creature-nav path to owner";
    actor zombie_utils::update_bt_goal( goal );
    return "reachable owner-follow goal issued";
}

function owner_zrex_finish_button( original )
{
    self endon( #"disconnect" );
    wait 0.5;
    if ( isdefined( original ) && self supers_mp::getcurrentsuper() == original && self supers_mp::issuperinuse() )
        self supers_mp::superusefinished( 0, 0, 0, 1 );
}

function owner_zrex_watch( ticket )
{
    ticket endon( #"owner_zrex_done" );
    waitframe(); // allow the initiating thread to turn/register the actor before any retirement
    while ( true )
    {
        if ( istrue( ticket.closed ) ) return;
        if ( !isdefined( ticket.owner ) || !isalive( ticket.owner ) )
        {
            owner_zrex_retire( ticket, "owner left or died" );
            return;
        }
        actor = ticket.actor;
        if ( !isdefined( actor ) || !isalive( actor ) )
        {
            owner_zrex_retire( ticket, "actor died" );
            return;
        }
        if ( owner_zrex_map_uses_boss( actor ) )
        {
            owner_zrex_retire( ticket, "encounter reserved" );
            return;
        }
        owner_zrex_disable_mount( actor );
        if ( !istrue( ticket.ready ) )
        {
            if ( gettime() >= ticket.setup_watchdog )
            {
                owner_zrex_retire( ticket, "activation timed out" );
                return;
            }
            waitframe();
            continue;
        }
        if ( gettime() >= ticket.deadline )
        {
            owner_zrex_retire( ticket, "240 seconds elapsed" );
            return;
        }
        enemy = actor.enemy;
        if ( actor.team != ticket.owner.team || !actor utility::ent_flag( "turned" ) )
        {
            owner_zrex_retire( ticket, "lost turned state or owner team" );
            return;
        }
        if ( gettime() >= ( ticket.next_steer ?? 0 ) )
        {
            ticket.next_steer = gettime() + 1000;
            owner_zrex_hide_owned_bar( actor );
            action = owner_zrex_steer( ticket );
            elapsed = gettime() - ( ticket.deadline - 240000 );
            sample = elapsed < 3000 ? 0 : ( elapsed < 15000 ? 1 : ( elapsed < 60000 ? 2 : 3 ) );
            if ( !isdefined( ticket.last_sample ) || ticket.last_sample != sample )
            {
                ticket.last_sample = sample;
                level thread owner_zrex_evidence( ticket, "movement" + sample, action );
            }
        }
        if ( !isdefined( ticket.saw_enemy ) && isdefined( enemy ) && isdefined( enemy.team ) && enemy.team != actor.team )
        {
            ticket.saw_enemy = 1;
            logstring( "OWNER_ZREX acquired hostile #" + enemy getentitynumber() );
        }
        wait 0.25;
    }
}

function owner_zrex_wait_end( ticket )
{
    ticket endon( #"owner_zrex_done" );
    level waittill( #"game_ended" );
    owner_zrex_retire( ticket, "match ended" );
}

function owner_zrex_retire( ticket, reason )
{
    if ( istrue( ticket.closed ) )
        return;
    ticket.closed = 1;
    ticket.reason = reason;
    // This level-owned verifier runs separately. If an auxiliary cleanup call faults,
    // it can still inspect the exact handle; another summon cannot take this reservation.
    level thread owner_zrex_verify_retire( ticket );
    level thread owner_zrex_evidence( ticket, "retire_start", reason );
}

function owner_zrex_hard_expiry( ticket )
{
    ticket endon( #"owner_zrex_done" );
    while ( gettime() < ticket.deadline )
        wait min( 1, ( ticket.deadline - gettime() ) / 1000.0 );
    if ( !istrue( ticket.closed ) )
        owner_zrex_retire( ticket, "240-second absolute limit" );
    else if ( isdefined( ticket.actor ) )
    {
        // Covers a watchdog/cleanup worker that previously faulted. Touch only
        // the exact actor created by this still-reserved ticket.
        level thread owner_zrex_raw_delete( ticket, 99 );
    }
}

function owner_zrex_hide_owned_bar( actor )
{
    foreach ( p in level.players )
        if ( isdefined( p ) && isdefined( p.var_7fa280bb4c563541 ) && p.var_7fa280bb4c563541 == actor )
            p zombie_boss_healthbar::zombie_boss_healthbar_hide();
}

function owner_zrex_verify_retire( ticket )
{
    for ( attempt = 0; attempt < 3; attempt++ )
    {
        actor = ticket.actor;
        if ( !isdefined( actor ) ) break;
        if ( actor getentitynumber() != ticket.actor_id || actor.owner_zrex_ticket != ticket )
            break;
        // Schedule the fenced native removal FIRST. Best-effort cleanup workers
        // may fault individually but cannot prevent the raw worker from running.
        level thread owner_zrex_raw_delete( ticket, attempt );
        level thread owner_zrex_hide_owned_bar( actor );
        level thread owner_zrex_detach( actor );
        level thread owner_zrex_remove_callbacks( level, "zombie_toxic_gas_spawned", actor );
        level thread owner_zrex_dispose_parts( ticket );
        level thread owner_zrex_evidence( ticket, "retire_attempt" + attempt, "raw deletion scheduled" );
        wait 0.25;
    }
    if ( isdefined( ticket.actor ) )
    {
        level thread owner_zrex_evidence( ticket, "retire_pending", "handle still exists; owner remains reserved" );
        while ( isdefined( ticket.actor ) )
        {
            wait 5;
            if ( isdefined( ticket.actor ) )
                level thread owner_zrex_raw_delete( ticket, -1 );
        }
    }
    level thread owner_zrex_evidence( ticket, "retire_confirmed", ticket.reason );
    owner = ticket.owner;
    if ( isdefined( owner ) && owner.owner_zrex_ticket == ticket )
        owner.owner_zrex_ticket = undefined;
    if ( level.owner_zrex_reservations[ticket.owner_id] == ticket )
        level.owner_zrex_reservations[ticket.owner_id] = undefined;
    ticket notify( #"owner_zrex_done" );
}

function owner_zrex_raw_delete( ticket, attempt )
{
    // One frame lets the SEPARATE exact-owned cleanup workers release attachments.
    // No diagnostics, path calls or cleanups sit between the identity fence and delete.
    waitframe();
    actor = ticket.actor;
    if ( !isdefined( actor ) || actor getentitynumber() != ticket.actor_id || actor.owner_zrex_ticket != ticket )
        return;
    actor delete();
    if ( attempt >= 0 )
        level thread owner_zrex_evidence( ticket, "delete_returned" + attempt, "native delete returned" );
}

function owner_zrex_dispose_parts( ticket )
{
    actor = ticket.actor;
    if ( isdefined( actor ) && actor.owner_zrex_ticket == ticket && actor getentitynumber() == ticket.actor_id )
    {
        // Native disposal of a living agent is not a kill. Its spine helpers normally
        // wait for a death notify (utility:4711); release only this actor's private parts.
        if ( isdefined( actor.phobos_trigger_origin ) && actor.phobos_trigger_origin.phobos_owner == actor )
            actor.phobos_trigger_origin delete();
        if ( isdefined( actor.var_77d0126cc851fda8 ) )
        {
            foreach ( spine in actor.var_77d0126cc851fda8 )
                if ( isdefined( spine ) && spine.phobos_owner == actor )
                    spine delete();
        }
        if ( isdefined( actor.var_3f696ebfb0ffe19b ) )
        {
            foreach ( leg in actor.var_3f696ebfb0ffe19b )
                if ( isdefined( leg ) && ( !isdefined( leg.owner ) || leg.owner == actor ) )
                    leg freescriptable();
        }
    }
}

function owner_zrex_detach( actor )
{
    owner_zrex_disable_mount( actor );
    // Mirror collision:312-349 using common APIs. The mod is loaded on other
    // maps, so avoid hard-linking the Phobos-only private rider module there.
    restored_rider = 0;
    if ( isdefined( actor.var_b331e173161548c3 ) )
    {
        foreach ( rider in actor.var_b331e173161548c3 )
        {
            if ( !isdefined( rider ) || !isplayer( rider ) || !rider utility::ent_flag( "attached_to_back" ) )
                continue;
            parent = rider getlinkedparent();
            // An already unlinked rider can still need their native controls restored.
            if ( isdefined( parent ) && ( !isdefined( parent.phobos_owner ) || parent.phobos_owner != actor ) )
                continue;
            if ( isdefined( parent ) )
                rider unlink( 1 );
            rider.var_db1bfb1d736629c6 = gettime();
            rider utility::ent_flag_clear( "attached_to_back" );
            rider val::reset_all( "phobos_on_back" );
            owner_zrex_remove_callbacks( rider, #"player_laststand", actor );
            rider notifyonplayercommandremove( "phobos_melee_on_back", "+attack" );
            rider notify( #"removed_from_phobos_back" );
            restored_rider = 1;
        }
    }

    // Streaming can introduce this prop during setup. Match stock restoration
    // (collision:512-517) only when it is still the map object linked to THIS ally.
    back = actor.phobos_back;
    if ( !isdefined( back ) || !isdefined( back.original_origin ) ) return;
    foreach ( map_back in getentarray( "phobos_back", #"targetname" ) )
    {
        if ( map_back != back || back getlinkedparent() != actor ) continue;
        if ( restored_rider )
            back show();
        back unlink();
        back.origin = back.original_origin;
        back utility::ent_flag_clear( "attached_on_back" );
        break;
    }
}

function owner_zrex_remove_callbacks( host, event, actor )
{
    // callbacks:298-331 accepts the original [function, extra params] registration.
    // Spit:48-65 listens for gas from ALL sources. Never free its global gas list.
    if ( !isdefined( host.callbacks ) || !isdefined( host.callbacks[ event ] ) )
        return;
    foreach ( row in host.callbacks[ event ] )
    {
        if ( !isarray( row ) || row.size < 2 || !isfunction( row[0] ) || !isstruct( row[1] ) )
            continue;
        if ( isdefined( row[1].phobos ) && row[1].phobos == actor )
            host callback::remove( event, row[0], row[1] );
    }
}
