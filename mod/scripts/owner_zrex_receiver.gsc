// Passive BO7 receiver inventory. This standalone sidecar never spawns an actor.
// Reference: ProjectHiNAtyu/CoDs_GSC_Wiki_Library_IW8Plus (PC S6L 20261016), commit
// 55d02741d078eaeeaeeaffa433deef4a439608f8: agent_manager:19-27, mp_agent:54-75,148-159,
// zombie_utils:583-592, zombie_init:341-343, zombie_phobos_collision:87-113,
// zm_sat_scarab_br:598-612, ztron_enemy:167-173,515-524. Source evidence, not live validation.

#using scripts\common\callbacks;
#using scripts\common\utility;

autoexec owner_zrxscan_init()
{
    level callback::add( #"player_spawned", &owner_zrxscan_player_spawned );
}

function owner_zrxscan_player_spawned( params )
{
    if ( !isdefined( level.mapname ) || !( utility::iszm() || isstartstr( "" + level.mapname, "zm_" ) ) )
        return;
    map = "" + level.mapname;
    if ( isdefined( level.owner_zrxscan_map ) && level.owner_zrxscan_map == map )
        return;
    level.owner_zrxscan_map = map;
    level thread owner_zrxscan_measure( map );
}

function owner_zrxscan_measure( map )
{
    level endon( #"game_ended" );
    wait 1;
    if ( !isdefined( level.mapname ) || "" + level.mapname != map )
        return;

    // Clear only this diagnostic namespace. A partial run must never inherit
    // old "complete" fields from another map or an earlier visit to this one.
    nengine_store_clear( "owner_zrex_receiver" );
    nengine_store_set( "owner_zrex_receiver", "build", "passive2" );
    nengine_store_set( "owner_zrex_receiver", "map", map );
    nengine_store_set( "owner_zrex_receiver", "time_ms", gettime() );
    owner_zrxscan_checkpoint( map, "checking navigation and shared controller" );
    nengine_store_set( "owner_zrex_receiver", "nav_loaded", isnavmeshloaded() );
    nengine_store_set( "owner_zrex_receiver", "turn_ai", utility::issharedfuncdefined( #"zombie_utils", #"turn_ai" ) );

    owner_zrxscan_checkpoint( map, "checking existing map entities" );
    backs = getentarray( "phobos_back", "targetname" );
    count = isdefined( backs ) ? backs.size : 0;
    nengine_store_set( "owner_zrex_receiver", "back_count", count );
    if ( count == 1 && isdefined( backs[0] ) )
    {
        back = backs[0];
        nengine_store_set( "owner_zrex_receiver", "back_linked", isdefined( back getlinkedparent() ) );
        nengine_store_set( "owner_zrex_receiver", "back_flag", back utility::ent_flag( "attached_on_back" ) );
    }
    living = 0;
    phobos_count = 0;
    foreach ( ai in getaiarray() )
    {
        if ( !isdefined( ai ) || !isalive( ai ) )
            continue;
        living++;
        if ( isdefined( ai.subclass ) && ai.subclass == "zombie_phobos" )
            phobos_count++;
    }
    nengine_store_set( "owner_zrex_receiver", "living_ai", living );
    nengine_store_set( "owner_zrex_receiver", "living_phobos", phobos_count );

    nengine_store_set( "owner_zrex_receiver", "dark_base_present", owner_zrxscan_field( "super_dark_flare" ) );
    nengine_store_set( "owner_zrex_receiver", "dark_shadow_present", owner_zrxscan_field( "super_dark_flare_shadow_ball" ) );
    nengine_store_set( "owner_zrex_receiver", "dark_extension_present", owner_zrxscan_field( "super_dark_flare_13s" ) );
    // Stock can remap an actor via a map-owned function pointer. Never invoke an
    // opaque map handler just to inspect it. Missing literal names are inconclusive.
    nengine_store_set( "owner_zrex_receiver", "native_remapper_present", isdefined( level.var_1e2c07e345d293d1 ) );
    owner_zrxscan_checkpoint( map, "checking independent subclass bundle" );
    subclass = getscriptbundle( hashcat( %"hash_138dab78b1b28a0f", "zombie_phobos" ) );
    nengine_store_set( "owner_zrex_receiver", "direct_phobos_subclass",
        isdefined( subclass ) && isdefined( subclass.name ) && subclass.name == "zombie_phobos" );
    owner_zrxscan_type( map, "scarab", "actor_sat_spawner_zombie_phobos_zm" );
    owner_zrxscan_type( map, "subclass", "actor_zombie_phobos" );
    nengine_store_set( "owner_zrex_receiver", "scope", "direct names only; no remap, spawn, mesh, animation or FX test" );
    owner_zrxscan_checkpoint( map, "complete" );
    logstring( "OWNER_ZRXSCAN passive2 recorded " + map );
}

function owner_zrxscan_checkpoint( map, phase )
{
    nengine_store_set( "owner_zrex_receiver", "phase", phase );
    nengine_store_save( "owner_zrex_receiver", map );
}

function owner_zrxscan_field( ref )
{
    return isdefined( level.superglobals ) && isdefined( level.superglobals.staticsuperdata )
        && isdefined( level.superglobals.staticsuperdata[ref] );
}

function owner_zrxscan_label( value )
{
    if ( !isdefined( value ) )
        return "-";
    if ( isxhash( value ) )
        return "" + getxhashsourcename( value );
    return "" + value;
}

function owner_zrxscan_type( map, prefix, name )
{
    nengine_store_set( "owner_zrex_receiver", prefix + "_name", name );
    owner_zrxscan_checkpoint( map, prefix + ": checking name validity" );
    valid = isaitypenamevalid( name );
    nengine_store_set( "owner_zrex_receiver", prefix + "_type_valid", valid );
    if ( !valid )
        return;
    owner_zrxscan_checkpoint( map, prefix + ": checking AI bundle" );
    ai = getaitypescriptbundle( name );
    nengine_store_set( "owner_zrex_receiver", prefix + "_ai_bundle", isdefined( ai ) );
    if ( !isdefined( ai ) )
        return;
    owner_zrxscan_checkpoint( map, prefix + ": checking subclass and settings" );
    if ( isdefined( ai.subclass ) )
        subclass = getscriptbundle( hashcat( %"hash_138dab78b1b28a0f", ai.subclass ) );
    if ( isdefined( ai.zombieaisetting ) )
        settings = getscriptbundle( "zombieaisettings:" + ai.zombieaisetting );
    owner_zrxscan_checkpoint( map, prefix + ": checking behavior bundle" );
    if ( isdefined( settings ) && isdefined( settings.var_394d3c5e6fa40c50 ) )
        behavior = getscriptbundle( settings.var_394d3c5e6fa40c50 );
    if ( isdefined( subclass ) )
        subclass_name = subclass.name;
    settings_name = ai.zombieaisetting;
    if ( isdefined( behavior ) )
        leg = behavior.legscriptable;

    nengine_store_set( "owner_zrex_receiver", prefix + "_subclass_bundle", isdefined( subclass ) );
    nengine_store_set( "owner_zrex_receiver", prefix + "_subclass_name", owner_zrxscan_label( subclass_name ) );
    nengine_store_set( "owner_zrex_receiver", prefix + "_settings_name", owner_zrxscan_label( settings_name ) );
    nengine_store_set( "owner_zrex_receiver", prefix + "_settings_bundle", isdefined( settings ) );
    nengine_store_set( "owner_zrex_receiver", prefix + "_behavior_bundle", isdefined( behavior ) );
    nengine_store_set( "owner_zrex_receiver", prefix + "_leg_ref", owner_zrxscan_label( leg ) );
    owner_zrxscan_checkpoint( map, prefix + ": checking leg registration" );
    nengine_store_set( "owner_zrex_receiver", prefix + "_leg_registered", isdefined( leg ) && isscriptabledefined( leg ) );
}
