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
#using scripts\mp\agents\agent_utils;
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
    nengine_store_set( "owner_zrex_poc", "build", "ally2" );
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

function owner_zrex_profile()
{
    kind = getdvar( "owner_ally_profile" );
    if ( kind == "" ) kind = "uber_klaus";
    if ( kind != "uber_klaus" && kind != "zrex" ) return undefined;
    profile = spawnstruct();
    profile.kind = kind;
    rex = kind == "zrex";
    profile.label = rex ? "Z-Rex" : "Uber Klaus";
    profile.subclass = rex ? "zombie_phobos" : "zombie_viper";
    // No other species, mini-core, HVT, or silent fallback is eligible.
    profile.types = rex ? [ "sat_spawner_zombie_phobos_zm", "zombie_phobos" ] : [ "sat_spawner_zombie_viper_zm" ];
    // Conservative placement proxies, not measured native collision bounds.
    profile.spawn_range = rex ? 448 : 192;
    profile.radius = rex ? 128 : 32;
    profile.height = rex ? 320 : 100;
    profile.ai_clearance = rex ? 176 : 64;
    profile.player_clearance = rex ? 192 : 96;
    profile.nav_snap = rex ? 192 : 64;
    profile.nav_close = rex ? 96 : 32;
    profile.exit_distance = rex ? 330 : 160;
    profile.exit_minimum = rex ? 192 : 80;
    profile.contact_range = rex ? 240 : 96;
    profile.target_gap = rex ? 160 : 48;
    profile.standoff = rex ? 310 : 128;
    profile.standoff_minimum = rex ? 160 : 64;
    profile.owner_stop = rex ? 400 : 160;
    profile.owner_gap = rex ? 240 : 96;
    return profile;
}

function owner_zrex_setup_failed( ticket, reason )
{
    if ( isdefined( ticket.actor ) ) owner_zrex_retire( ticket, reason );
    warning = istrue( ticket.released ) ? " No ally remains." : " Cleanup is pending; another summon stays locked until removal is confirmed.";
    if ( !istrue( ticket.factory_returned ) )
        warning = " The native creation result is still unknown; this summon stays reserved.";
    return self owner_zrex_block( ticket.profile.label + ": " + reason + "." + warning );
}

function owner_zrex_begin()
{
    owner_zrex_mark( "use", "Dark Flare begin" );
    profile = owner_zrex_profile();
    if ( !isdefined( profile ) )
        return self owner_zrex_block( "Unknown ally profile. Use uber_klaus or zrex." );
    if ( !isdefined( level.mapname ) || !( utility::iszm() || isstartstr( "" + level.mapname, "zm_" ) ) )
        return self owner_zrex_block( "Ally Summon requires a Zombies match." );
    if ( !isalive( self ) || !isdefined( self.team ) )
        return self owner_zrex_block( "Spawn before calling your ally." );
    owner_id = self getentitynumber();
    if ( !isdefined( level.owner_zrex_reservations ) )
        level.owner_zrex_reservations = [];
    if ( isdefined( self.owner_zrex_ticket ) )
        return self owner_zrex_block( "Your ally is already active or awaiting cleanup." );
    foreach ( held in level.owner_zrex_reservations )
        if ( isdefined( held ) && isdefined( held.owner ) && held.owner == self )
            return self owner_zrex_block( "Your ally is already active or awaiting cleanup." );
    if ( profile.kind == "zrex" && owner_zrex_map_uses_boss( undefined ) )
        return self owner_zrex_block( "The map has reserved its Z-Rex encounter." );
    if ( !utility::issharedfuncdefined( #"zombie_utils", #"turn_ai" ) )
        return self owner_zrex_block( "The ally controller is unavailable." );

    type = owner_zrex_receiver_type( profile );
    if ( !isdefined( type ) )
        return self owner_zrex_block( "This map has no candidate " + profile.label + " asset chain." );

    spot = self owner_zrex_find_spot( profile );
    if ( !isdefined( spot ) )
        return self owner_zrex_block( "Find open ground for your " + profile.label + "." );

    if ( !istrue( level.owner_zrex_guards ) )
    {
        // Stock pattern: zm_maneki_neko:39-56; damage:585-595,14215-14224.
        damage::register_scripted_damage_override_func( &owner_zrex_player_damage );
        level callback::add( "on_zombie_ai_damaged", &owner_zrex_hit );
        level.owner_zrex_guards = 1;
    }
    if ( profile.kind == "zrex" && !istrue( level.owner_zrex_phobos_guards ) )
    {
        level callback::add( "on_zombie_phobos_spawn_empowered", &owner_zrex_puke_add );
        level callback::add( "on_zombie_phobos_spawn_roared", &owner_zrex_puke_add );
        level callback::add( "on_zombie_phobos_spawn_parasite", &owner_zrex_puke_add );
        level.owner_zrex_phobos_guards = 1;
    }
    // Bound the short receipt prefix rather than relying on native 32-byte truncation.
    if ( ( level.owner_zrex_sequence ?? 0 ) >= 999999 )
        return self owner_zrex_block( "Ally summon receipt limit reached for this match." );
    ticket = spawnstruct();
    ticket.profile = profile;
    ticket.owner = self;
    ticket.owner_id = owner_id; // diagnostic only; never an ownership or reservation key
    level.owner_zrex_sequence = ( level.owner_zrex_sequence ?? 0 ) + 1;
    ticket.key = "a" + level.owner_zrex_sequence + "_" + gettime();
    self.owner_zrex_ticket = ticket;
    level.owner_zrex_reservations[ticket.key] = ticket;
    ticket.factory_until = gettime() + 8000;
    ticket.factory_status = "waiting for native creation";
    level thread owner_zrex_factory_lease( ticket );
    level thread owner_zrex_factory( ticket, type, spot, ( 0, self.angles[1], 0 ), self.team );
    while ( !istrue( ticket.factory_returned ) && gettime() < ticket.factory_until )
        waitframe();
    if ( !istrue( ticket.factory_returned ) )
        return self owner_zrex_setup_failed( ticket, "native creation did not return before its deadline" );
    actor = ticket.actor;
    if ( !isdefined( actor ) || istrue( ticket.closed ) )
        return self owner_zrex_setup_failed( ticket, ticket.reason ?? "native factory returned no actor" );
    actor.b_ignore_cleanup = 1;
    actor.b_cleanup_no_respawn = 1;
    actor.ignore_enemy_count = 1;
    actor.no_powerups = 1;
    if ( profile.kind == "zrex" )
    {
        actor.puke_zombies_no_powerups = 1;
        // Per-actor Phobos parasite switch and ordinary roar replacement callback.
        actor.var_e46525bdff4f9d3b = 1;
        actor.var_4da43c6a7a1311e9 = &owner_zrex_no_roar_adds;
    }
    else
    {
        failure = owner_zrex_wait_for_klaus( ticket );
        if ( failure != "" )
        {
            return self owner_zrex_setup_failed( ticket, failure );
        }
    }
    // Level-owned cleanup survives an activation thread interrupted during the AI's startup.
    actor utility::callsharedfunc( #"zombie_utils", #"turn_ai", self );
    // Initialization and conversion may take game time. Measure settle AFTER the call returns.
    level thread owner_zrex_evidence( ticket, "converted", "turn helper returned" );
    ticket.settle_until = gettime() + 2500;
    failure = owner_zrex_wait_for_turn( ticket );
    if ( failure != "" )
    {
        return self owner_zrex_setup_failed( ticket, failure );
    }
    failure = owner_zrex_wait_for_parts( ticket );
    if ( failure != "" )
    {
        return self owner_zrex_setup_failed( ticket, failure );
    }
    // Player-nav placement and a free generic capsule are not proof a full-size Rex can walk.
    // No teleport. Require its own actual nav point plus a reachable exit; otherwise refund.
    if ( !owner_zrex_creature_clearance( ticket ) )
    {
        failure = ticket.reason ?? "no creature path out of this spot";
        return self owner_zrex_setup_failed( ticket, failure );
    }
    actor setthreatbiasgroup( "team_players" );
    actor setsafeguardent( self );
    actor setsafeguardrange( 512 );
    ticket.ready = 1;
    level notify( #"highvis_reload_outline", self.team, [actor] );
    level thread owner_zrex_evidence( ticket, "accepted", "live turned actor on owner team" );
    logstring( "OWNER_ZREX spawned owner=" + self getentitynumber() + " actor=" + actor getentitynumber() );
    self iprintlnbold( profile.label + " ally active for four minutes." );
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
    ticket.factory_status = "native creation did not return before its deadline";
    level thread owner_zrex_evidence( ticket, "factory_pending", "no return; slot remains locked for this match" );
}

function owner_zrex_factory( ticket, type, spot, angles, team )
{
    // A native script fault here cannot take the input callback or lease monitor with it.
    actor = agent_manager::spawn_agent( type, spot, angles, team );
    if ( !isdefined( actor ) )
    {
        ticket.factory_returned = 1;
        ticket.factory_status = "native factory returned no actor";
        ticket.reason = ticket.factory_status;
        owner_zrex_release( ticket );
        level thread owner_zrex_evidence( ticket, "factory_empty", "factory returned no handle" );
        return;
    }
    // Native Viper death snapshots this flag before its delayed mini-core spawn.
    // Set it before any yielding startup/watch/turn work, only on our returned actor.
    if ( ticket.profile.kind == "uber_klaus" ) actor.var_c3746c711044489d = 1;
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
    // Record each predicate so a rejected live handle is never reported as an
    // unexplained timeout. The owner number is deliberately not involved here.
    ticket.factory_in_time = gettime() < ticket.factory_until;
    ticket.factory_owner_exists = isdefined( ticket.owner );
    ticket.factory_owner_alive = ticket.factory_owner_exists && isalive( ticket.owner );
    ticket.factory_owner_marker = ticket.factory_owner_exists && ticket.owner.owner_zrex_ticket == ticket;
    ticket.factory_registry_match = level.owner_zrex_reservations[ticket.key] == ticket;
    failure = "";
    if ( istrue( ticket.factory_uncertain ) ) failure = "native creation returned after its lease expired";
    else if ( !ticket.factory_in_time ) failure = "native creation returned after its deadline";
    else if ( !ticket.factory_owner_exists ) failure = "summoner disconnected during creation";
    else if ( !ticket.factory_owner_alive ) failure = "summoner died during creation";
    else if ( !ticket.factory_owner_marker ) failure = "summoner reservation changed during creation";
    else if ( !ticket.factory_registry_match ) failure = "shared reservation changed during creation";
    ticket.factory_status = failure == "" ? "returned with matching owner and reservation" : failure;
    if ( failure != "" )
    {
        owner_zrex_retire( ticket, failure );
        return;
    }
    level thread owner_zrex_evidence( ticket, "created", type );
}

function owner_zrex_receiver_type( profile )
{
    // Scarab boss-rush uses the first ref. DOA's ztron_enemy.gsc:167,522 passes the second
    // subclass through the same factory. A registered name alone is insufficient.
    foreach ( type in profile.types )
    {
        resolved = function_b3988325430ce242( type ) ?? type;
        if ( !isstartstr( resolved, "actor_" ) )
            resolved = "actor_" + resolved;
        if ( isdefined( level.var_1e2c07e345d293d1 ) )
            resolved = [[ level.var_1e2c07e345d293d1 ]]( resolved );
        if ( !isdefined( resolved ) || !isaitypenamevalid( resolved ) )
            continue;
        // Bind2 already produced a live actor from this exact pair in the owner’s match.
        if ( profile.kind == "zrex" && "" + level.mapname == "zm_sat_scarab" && type == "sat_spawner_zombie_phobos_zm" )
            return type;
        ai = getaitypescriptbundle( resolved );
        if ( !isdefined( ai ) || !isdefined( ai.subclass ) || !isdefined( ai.zombieaisetting ) )
            continue;
        sub = getscriptbundle( hashcat( %"hash_138dab78b1b28a0f", ai.subclass ) );
        if ( !isdefined( sub ) || !isdefined( sub.name ) )
            continue;
        // Production builds cannot link the developer-only source-name resolver.
        expected_hash = profile.kind == "zrex" ? %"zombie_phobos" : %"zombie_viper";
        expected_script_hash = profile.kind == "zrex" ? #"zombie_phobos" : #"zombie_viper";
        if ( sub.name != profile.subclass && sub.name != expected_hash && sub.name != expected_script_hash )
            continue;
        settings = getscriptbundle( "zombieaisettings:" + ai.zombieaisetting );
        if ( !isdefined( settings ) || !isdefined( settings.var_394d3c5e6fa40c50 ) )
            continue;
        config = getscriptbundle( settings.var_394d3c5e6fa40c50 );
        // A leg reference is metadata, not proof of live scriptable registration.
        // Verify two native leg instances on our returned actor before accepting it.
        if ( isdefined( config ) && ( profile.kind == "uber_klaus" || isdefined( config.legscriptable ) ) )
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
    if ( !isdefined( actor.owner_zrex_ticket ) || actor.owner_zrex_ticket.profile.kind != "zrex" ) return;
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
        if ( ticket.profile.kind == "zrex" && owner_zrex_map_uses_boss( actor ) ) return "authentic encounter reserved";
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

// Native collision worker creates these exact two instances after its spine waits.
// Installed Scarab CRC 990e4908 / worker 5ca180ef matches reference lines 65-90.
function owner_zrex_wait_for_parts( ticket )
{
    if ( ticket.profile.kind != "zrex" ) return "";
    while ( gettime() < ticket.setup_watchdog )
    {
        if ( istrue( ticket.closed ) ) return ticket.reason ?? "cleanup already started";
        actor = ticket.actor;
        if ( !isdefined( ticket.owner ) || !isalive( ticket.owner ) ) return "owner unavailable";
        if ( !isdefined( actor ) || !isalive( actor ) ) return "actor unavailable";
        if ( actor getentitynumber() != ticket.actor_id || actor.owner_zrex_ticket != ticket )
            return "actor ownership changed";
        legs = actor.var_3f696ebfb0ffe19b;
        if ( isarray( legs ) && legs.size == 2 && isdefined( legs[0] ) && isdefined( legs[1] ) )
        {
            ticket.native_legs_ready = 1;
            level thread owner_zrex_evidence( ticket, "native_parts", "two exact-actor native leg instances" );
            return "";
        }
        waitframe();
    }
    return "native Z-Rex legs did not initialize";
}

function owner_zrex_wait_for_klaus( ticket )
{
    // Viper:92-107 marks native init before the async scriptable reveal; markers alone
    // are insufficient. Reveal:136-164 sets base_on, waits 1.2s, then clears its state.
    first_ready = undefined;
    while ( gettime() < ticket.setup_watchdog )
    {
        actor = ticket.actor;
        if ( istrue( ticket.closed ) ) return ticket.reason ?? "cleanup already started";
        if ( !isdefined( ticket.owner ) || !isalive( ticket.owner ) ) return "owner unavailable";
        if ( !isdefined( actor ) || !isalive( actor ) ) return "actor unavailable";
        if ( actor getentitynumber() != ticket.actor_id || actor.owner_zrex_ticket != ticket )
            return "actor ownership changed";
        actor.var_c3746c711044489d = 1;
        if ( istrue( actor.var_5a9c952260ab1cf ) && istrue( actor.var_a13bed1ac47e1b2c )
            && utility::flag( "scriptables_ready" ) && actor isscriptable()
            && actor getscriptablehaspart( "brainrot" ) && actor getscriptablehaspart( "base" )
            && actor getscriptablehaspart( "spawn_reveal" ) )
        {
            if ( !isdefined( first_ready ) ) first_ready = gettime();
            if ( gettime() - first_ready >= 1300 && actor getscriptablepartstate( "base" ) == "base_on"
                && actor getscriptablepartstate( "spawn_reveal" ) == "off"
                && !( actor getaiblackboarddynamic( "in_spawn_reveal" ) > 0 ) )
            {
                ticket.native_init_ready = 1;
                level thread owner_zrex_evidence( ticket, "native_ready", "Viper init and scriptable reveal complete" );
                return "";
            }
        }
        waitframe();
    }
    return "native Uber Klaus initialization did not finish";
}

function owner_zrex_find_spot( profile )
{
    if ( !isnavmeshloaded() )
        return undefined;
    // Conservative open-ground proxy, not a measurement of this asset's native bounds.
    for ( i = 0; i < 8; i++ )
    {
        direction = anglestoforward( ( 0, self.angles[1] + 45 * i, 0 ) );
        guess = self.origin + direction * profile.spawn_range;
        ground = getclosestpointonnavmesh( guess, self );
        if ( !isdefined( ground ) || distancesquared( ground, guess ) > 96 * 96 )
            continue;
        if ( !capsuletracepassed( ground + ( 0, 0, 4 ), profile.radius, profile.height, undefined, 0, 0 ) )
            continue;
        if ( getaiarrayinradius( ground, profile.ai_clearance ).size )
            continue;
        occupied = 0;
        foreach ( player in level.players )
        {
            if ( isdefined( player ) && distancesquared( player.origin, ground ) < profile.player_clearance * profile.player_clearance )
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
    if ( !isdefined( ticket ) || ticket.profile.kind != "zrex" ) return; // no inferred attribution by team, position or appearance
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
        child agent_utils::despawnagent();
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
    // Native saves truncate filenames at 32 bytes. A <=19-byte per-summon key plus
    // a bounded numeric stage is unique within this match and never loses its suffix.
    ticket.evidence_sequence = ( ticket.evidence_sequence ?? 0 ) + 1;
    if ( ticket.evidence_sequence > 999999 ) return;
    file = ticket.key + "_" + ticket.evidence_sequence;
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
    nengine_store_set( "owner_zrex_v3", "build", "ally2" );
    nengine_store_set( "owner_zrex_v3", "kind", ticket.profile.kind );
    nengine_store_set( "owner_zrex_v3", "map", level.mapname ?? "pending" );
    nengine_store_set( "owner_zrex_v3", "summon", ticket.key );
    nengine_store_set( "owner_zrex_v3", "stage_index", ticket.evidence_sequence );
    nengine_store_set( "owner_zrex_v3", "deadline", ticket.deadline ?? -1 );
    nengine_store_set( "owner_zrex_v3", "detail", why );
    nengine_store_set( "owner_zrex_v3", "time_ms", gettime() );
    nengine_store_set( "owner_zrex_v3", "owner_id", isint( ticket.owner_id ) ? ticket.owner_id : -1 );
    nengine_store_set( "owner_zrex_v3", "owner_id_defined", isdefined( ticket.owner_id ) );
    nengine_store_set( "owner_zrex_v3", "owner_id_type", isint( ticket.owner_id ) ? "int" : ( isdefined( ticket.owner_id ) ? "other" : "undefined" ) );
    nengine_store_set( "owner_zrex_v3", "factory_status", ticket.factory_status ?? "pending" );
    nengine_store_set( "owner_zrex_v3", "factory_until", ticket.factory_until ?? -1 );
    nengine_store_set( "owner_zrex_v3", "factory_returned", istrue( ticket.factory_returned ) );
    nengine_store_set( "owner_zrex_v3", "factory_uncertain", istrue( ticket.factory_uncertain ) );
    nengine_store_set( "owner_zrex_v3", "factory_in_time", ticket.factory_in_time ?? -1 );
    nengine_store_set( "owner_zrex_v3", "factory_owner_exists", ticket.factory_owner_exists ?? -1 );
    nengine_store_set( "owner_zrex_v3", "factory_owner_alive", ticket.factory_owner_alive ?? -1 );
    nengine_store_set( "owner_zrex_v3", "factory_owner_marker", ticket.factory_owner_marker ?? -1 );
    nengine_store_set( "owner_zrex_v3", "factory_registry_match", ticket.factory_registry_match ?? -1 );
    nengine_store_set( "owner_zrex_v3", "released", istrue( ticket.released ) );
    fresh_slot = isint( ticket.actor_id ) ? getentbynum( ticket.actor_id ) : undefined;
    nengine_store_set( "owner_zrex_v3", "fresh_slot_defined", isdefined( fresh_slot ) );
    nengine_store_set( "owner_zrex_v3", "fresh_slot_matches", isdefined( fresh_slot ) && fresh_slot == actor );
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
    nengine_store_set( "owner_zrex_v3", "native_legs_ready", ticket.native_legs_ready ?? 0 );
    nengine_store_set( "owner_zrex_v3", "native_init_ready", ticket.native_init_ready ?? 0 );
    nengine_store_set( "owner_zrex_v3", "creature_nav_at_spawn", ticket.nav_at_spawn ?? -1 );
    nengine_store_set( "owner_zrex_v3", "creature_exit_found", ticket.walk_exit ?? -1 );
    nengine_store_save( "owner_zrex_v3", file );
}

function owner_zrex_reachable( actor, position )
{
    profile = actor.owner_zrex_ticket.profile;
    point = getclosestpointonnavmesh( position, actor, 1, 1, 1 );
    if ( !isdefined( point ) || distancesquared( point, position ) > profile.nav_snap * profile.nav_snap )
        return undefined;
    if ( distancesquared( actor.origin, point ) < profile.nav_close * profile.nav_close )
        return point;
    path = actor findpath( actor.origin, point );
    // BO7 AI findpath returns an indexed list of positions. A nonempty partial
    // path ending at a wall does not certify a reachable creature goal.
    if ( isarray( path ) && path.size > 0 && distancesquared( path[path.size - 1], point ) <= profile.nav_close * profile.nav_close )
        return point;
    return undefined;
}

function owner_zrex_creature_clearance( ticket )
{
    profile = ticket.profile;
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
                exit_point = owner_zrex_reachable( actor, actor.origin + dir * profile.exit_distance );
                if ( isdefined( exit_point ) && distancesquared( exit_point, actor.origin ) >= profile.exit_minimum * profile.exit_minimum )
                {
                    ticket.walk_exit = 1;
                    level thread owner_zrex_evidence( ticket, "creature_nav", "own nav origin and reachable exit" );
                    return true;
                }
            }
        if ( pass < 2 ) wait 0.2;
    }
    level thread owner_zrex_evidence( ticket, "creature_nav", "no verified creature exit" );
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
    point = owner_zrex_reachable( actor, target.origin + dir * ticket.profile.standoff );
    if ( !isdefined( point ) || distancesquared( point, actor.origin ) < ticket.profile.standoff_minimum * ticket.profile.standoff_minimum )
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
            near = length( delta ) <= ticket.profile.contact_range;
            if ( near )
            {
                action = owner_zrex_contact( ticket, target );
                if ( action == "" ) continue;
                owner_zrex_set_focus( ticket, target );
                return action;
            }
            goal = owner_zrex_reachable( actor, target.origin + vectornormalize( delta ) * ticket.profile.target_gap );
            if ( !isdefined( goal ) ) continue;
            ticket.contact_target = undefined;
            owner_zrex_set_focus( ticket, target );
            actor zombie_utils::update_bt_goal( goal );
            return "reachable hostile goal issued";
        }
    }
    owner_zrex_set_focus( ticket, undefined );
    if ( distance_to_owner <= ticket.profile.owner_stop )
        return "staying near owner; no reachable hostile";
    goal = owner_zrex_reachable( actor, owner.origin + vectornormalize( actor.origin - owner.origin ) * ticket.profile.owner_gap );
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
        if ( ticket.profile.kind == "zrex" && owner_zrex_map_uses_boss( actor ) )
        {
            owner_zrex_retire( ticket, "encounter reserved" );
            return;
        }
        owner_zrex_disable_mount( actor );
        if ( ticket.profile.kind == "uber_klaus" ) actor.var_c3746c711044489d = 1;
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
    if ( ticket.profile.kind == "uber_klaus" && isdefined( ticket.actor ) && ticket.actor.owner_zrex_ticket == ticket )
        ticket.actor.var_c3746c711044489d = 1;
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
        level thread owner_zrex_native_despawn( ticket, 99 );
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
        if ( owner_zrex_removed( ticket ) ) break;
        actor = ticket.actor;
        if ( !isdefined( actor ) ) break;
        if ( actor getentitynumber() != ticket.actor_id || actor.owner_zrex_ticket != ticket )
            break;
        // Schedule the fenced native agent removal FIRST. Best-effort cleanup workers
        // may fault individually but cannot prevent the despawn worker from running.
        level thread owner_zrex_native_despawn( ticket, attempt );
        level thread owner_zrex_hide_owned_bar( actor );
        if ( ticket.profile.kind == "zrex" )
        {
            level thread owner_zrex_detach( actor );
            level thread owner_zrex_remove_callbacks( level, "zombie_toxic_gas_spawned", actor );
            level thread owner_zrex_dispose_parts( ticket );
        }
        else
            level thread owner_zrex_klaus_parts( ticket );
        level thread owner_zrex_evidence( ticket, "retire_attempt" + attempt, "native agent despawn scheduled" );
        wait 0.25;
    }
    if ( !owner_zrex_removed( ticket ) )
    {
        level thread owner_zrex_evidence( ticket, "retire_pending", "handle still exists; owner remains reserved" );
        while ( !owner_zrex_removed( ticket ) )
        {
            wait 5;
            if ( !owner_zrex_removed( ticket ) )
                level thread owner_zrex_native_despawn( ticket, -1 );
        }
    }
    if ( !owner_zrex_release( ticket ) ) return;
    ticket notify( #"owner_zrex_done" );
    level thread owner_zrex_evidence( ticket, "retire_confirmed", ticket.reason );
}

function owner_zrex_removed( ticket )
{
    // Never interpret an outstanding factory call's empty ticket as a free slot.
    if ( !istrue( ticket.factory_returned ) ) return false;
    if ( !isdefined( ticket.actor ) ) return true;
    if ( !isint( ticket.actor_id ) ) return false;
    // A stale script reference need not keep the owner locked if the actual entity
    // slot is absent. A different occupied slot is NOT evidence of safe removal.
    return !isdefined( getentbynum( ticket.actor_id ) );
}

function owner_zrex_release( ticket )
{
    // A known-empty native return, invalidated handle or empty native slot is proof.
    // A deadline, hidden/dead model, or return from despawnagent alone is not.
    if ( !owner_zrex_removed( ticket ) ) return false;
    owner = ticket.owner;
    if ( isdefined( owner ) && owner.owner_zrex_ticket == ticket )
        owner.owner_zrex_ticket = undefined;
    if ( level.owner_zrex_reservations[ticket.key] == ticket )
        level.owner_zrex_reservations[ticket.key] = undefined;
    ticket.released = 1;
    return true;
}

function owner_zrex_native_despawn( ticket, attempt )
{
    // One frame lets the SEPARATE exact-owned cleanup workers release attachments.
    // Stock DOA/Portal Summon use despawnagent for AI. Generic delete returned while
    // our live agent kept fighting; only the verifier can release its reservation.
    waitframe();
    if ( owner_zrex_removed( ticket ) ) return;
    actor = ticket.actor;
    if ( !isdefined( actor ) || actor getentitynumber() != ticket.actor_id || actor.owner_zrex_ticket != ticket )
        return;
    fresh = getentbynum( ticket.actor_id );
    if ( !isdefined( fresh ) || fresh != actor || fresh.owner_zrex_ticket != ticket )
    {
        if ( !istrue( ticket.reported_slot_mismatch ) )
        {
            ticket.reported_slot_mismatch = 1;
            level thread owner_zrex_evidence( ticket, "retire_identity", "native slot does not match the owned actor; no despawn issued" );
        }
        return;
    }
    if ( ticket.profile.kind == "uber_klaus" ) actor.var_c3746c711044489d = 1;
    actor agent_utils::despawnagent();
    if ( attempt >= 0 )
        level thread owner_zrex_evidence( ticket, "despawn_returned" + attempt, "native agent despawn helper returned" );
}

function owner_zrex_dispose_parts( ticket )
{
    if ( ticket.profile.kind != "zrex" ) return;
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
    if ( !isdefined( actor.owner_zrex_ticket ) || actor.owner_zrex_ticket.profile.kind != "zrex" ) return;
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

function owner_zrex_klaus_parts( ticket )
{
    actor = ticket.actor;
    if ( ticket.profile.kind != "uber_klaus" || !isdefined( actor )
        || actor.owner_zrex_ticket != ticket || actor getentitynumber() != ticket.actor_id ) return;
    actor.var_c3746c711044489d = 1;
    // Native Viper shield is an actor-owned scriptable part, not a shared map entity.
    // Native despawn is already scheduled independently if this best-effort reset faults.
    actor.tesla_coil_shield_enabled = 0;
    if ( istrue( ticket.native_init_ready ) && actor isscriptable() && actor getscriptablehaspart( "tesla_coil_shield" ) )
        actor utility::function_32b24db3127bff40( "tesla_coil_shield", "off" );
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
