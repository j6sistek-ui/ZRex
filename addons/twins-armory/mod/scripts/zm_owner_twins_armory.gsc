// Original local prototype. Current-client native linking and purchase behavior need a match test.
// Reference build: PC S6L 20261016, commit 55d02741d078eaeeaeeaffa433deef4a439608f8.
// See reference-notes.md. No normal Arsenal/ammo-mod definitions are replaced.
#using scripts\common\utility;
#using scripts\common\callbacks;
#using scripts\mp\currency;
#using scripts\mp\common\utility\lui_game_event_aggregator;
#using script_4519eff181e91bd3;

autoexec owner_twins_armory_init()
{
    level callback::add( #"player_spawned", &owner_twins_register );
    level thread owner_twins_register();
    level thread owner_twins_mark( "boot", "autoexec reached" );
}

function owner_twins_mark( stage, detail )
{
    // Local receipts expose actual server progress independently of menu logging.
    nengine_store_set( "owner_twins_runtime", "build", "native-card1" );
    nengine_store_set( "owner_twins_runtime", "map", level.mapname ?? "pending" );
    nengine_store_set( "owner_twins_runtime", "time_ms", gettime() );
    nengine_store_set( "owner_twins_runtime", "stage", stage );
    nengine_store_set( "owner_twins_runtime", "detail", detail );
    nengine_store_save( "owner_twins_runtime", stage );
}

function owner_twins_register( params )
{
    if ( !utility::iszm() || istrue( level.owner_twins_armory_registered ) )
        return;
    level.owner_twins_armory_registered = 1;
    lui_game_event_aggregator::registeronluieventcallback( &owner_twins_event, "owner_twins_armory_purchase" );
    level callback::add( "currency_sub", &owner_twins_currency_sub );
    level callback::add( "currency_add", &owner_twins_currency_add );
    logstring( "OWNER_TWINS purchase callback registered" );
    level thread owner_twins_mark( "listener", "native purchase callback registered" );
}

function owner_twins_event( channel, value )
{
    // Isolate failures/cancellation from the stock player's synchronous LUI listener.
    if ( channel == "owner_twins_armory_purchase" )
    {
        level thread owner_twins_mark( "request", "native purchase event received" );
        self thread owner_twins_purchase( channel, value );
    }
}

function owner_twins_price()
{
    return 500; // Local prototype price; keep the Lua quote identical.
}

function owner_twins_message( text )
{
    self iprintlnbold( text );
    logstring( "OWNER_TWINS " + text );
    level thread owner_twins_mark( "result", text );
}

function owner_twins_has_mask()
{
    return isdefined( self.mask_ee ) && isdefined( self.mask_ee.var_73e37bf886655ce7 ) &&
        self.mask_ee.var_73e37bf886655ce7.ref == "zmloot_scarab_twins_ee_mask";
}

function owner_twins_grant_complete()
{
    return self owner_twins_has_mask() && isdefined( self.mask_ee.var_536177437db76a1f ) &&
        self utility::ent_flag( "zmloot_scarab_twins_ee_mask_worn" );
}

function owner_twins_other_wearer( except )
{
    foreach ( player in level.players )
        if ( isdefined( player ) && player != except && player owner_twins_has_mask() )
            return player;
    return undefined;
}

function owner_twins_canuse( bundle, item, autouse, extra )
{
    // Keep the real quest reward pickup, but do not let it create a second
    // wearer whose removal would unhook the native singleton lightning callback.
    if ( isdefined( level.owner_twins_armory_ticket ) || isdefined( owner_twins_other_wearer( self ) ) )
        return false;
    original = level.owner_twins_original_canuse;
    if ( !isdefined( original ) )
        return false;
    return self [[ original ]]( bundle, item, autouse, extra );
}

function owner_twins_guard_pickups()
{
    if ( istrue( level.owner_twins_pickup_guard ) )
        return;
    original = utility::getsharedfunc( #"zmloot_scarab_twins_ee_mask", #"hash_2e22b6be73e28e05" );
    if ( !isdefined( original ) )
        return;
    level.owner_twins_original_canuse = original;
    utility::registersharedfunc( #"zmloot_scarab_twins_ee_mask", #"hash_2e22b6be73e28e05", &owner_twins_canuse );
    level.owner_twins_pickup_guard = 1;
}

function owner_twins_release( ticket )
{
    if ( isdefined( ticket.owner ) && ticket.owner.owner_twins_armory_ticket == ticket )
        ticket.owner.owner_twins_armory_ticket = undefined;
    if ( level.owner_twins_armory_ticket == ticket )
        level.owner_twins_armory_ticket = undefined;
}

function owner_twins_currency_sub( params )
{
    if ( !isdefined( self.owner_twins_armory_ticket ) || !isdefined( params ) || params.currencytype != #"salvage" )
        return;
    ticket = self.owner_twins_armory_ticket;
    if ( istrue( ticket.closed ) )
        return;
    if ( params.reason == "owner_twins_purchase" )
    {
        ticket.debit_event = params.amount;
        ticket.debit_recorded = 1;
    }
    else
        ticket.other_delta -= params.amount ?? 0;
}

function owner_twins_currency_add( params )
{
    if ( !isdefined( self.owner_twins_armory_ticket ) || !isdefined( params ) || params.currencytype != #"salvage" )
        return;
    ticket = self.owner_twins_armory_ticket;
    if ( !istrue( ticket.closed ) )
        ticket.other_delta += params.amount ?? 0;
}

function owner_twins_observed_debit( ticket )
{
    if ( !istrue( ticket.debit_started ) || !isdefined( ticket.owner ) || !isdefined( ticket.before_debit ) ||
        !isdefined( level.currency ) || !isdefined( level.currency[ #"salvage" ] ) )
        return 0;
    // A currency_sub event reports REQUESTED amount, not actual effect. Use the
    // observed balance, adjusted for other recorded native salvage mutations.
    current = ticket.owner currency::get_currency_amount( #"salvage" );
    amount = ticket.before_debit + ticket.other_delta - ticket.other_at_debit - current;
    if ( amount < 0 )
        amount = 0;
    if ( amount > ticket.price )
        amount = ticket.price;
    return amount;
}

function owner_twins_rollback_mask( ticket )
{
    player = ticket.owner;
    if ( !isdefined( player ) || !isdefined( player.mask_ee ) )
        return;
    current = player.mask_ee.var_73e37bf886655ce7;
    if ( isdefined( current ) && current.ref != "zmloot_scarab_twins_ee_mask" )
        return; // A different, later acquired mask is never removed.
    if ( isdefined( current ) || player.scarab_ee_mask_id == 2 )
    {
        player notify( #"mask_removed" );
        if ( isdefined( player.mask_ee.var_536177437db76a1f ) )
            player.mask_ee.var_536177437db76a1f delete();
        player.mask_ee.var_536177437db76a1f = undefined;
        player.mask_ee.var_73e37bf886655ce7 = undefined;
        player.scarab_ee_mask_id = ticket.prior_mask_id;
        player utility::ent_flag_clear( "zmloot_scarab_twins_ee_mask_worn" );
        other = owner_twins_other_wearer( player );
        if ( !isdefined( other ) )
            level utility::flag_clear( "zmloot_scarab_twins_ee_mask_worn" );
        else if ( isdefined( level.scarab_ee_masks.var_c72c979b2dbc4e94[ "zmloot_scarab_twins_ee_mask" ] ) )
        {
            // Quest pickups do not use our purchase lock. If a second wearer
            // appeared, re-establish its shared callback after our removal.
            ability = level.scarab_ee_masks.var_c72c979b2dbc4e94[ "zmloot_scarab_twins_ee_mask" ];
            other thread [[ ability ]]( other.mask_ee.var_73e37bf886655ce7, undefined, 0, undefined );
        }
    }
    // Never blanket-clear *_earned; native equip sets it and a real quest may
    // already have earned it. This normal native flag side effect is documented.
}

function owner_twins_finish_worker( ticket, success, reason )
{
    // Independent level-owned worker: NO ticket endons here. It can cancel the
    // caller/watchdogs first and still finish financial recovery and cleanup.
    ticket notify( #"owner_twins_purchase_cancel" );
    ticket notify( #"owner_twins_purchase_settled" );
    debit = owner_twins_observed_debit( ticket );
    player = ticket.owner;
    if ( !isdefined( success ) )
    {
        // Recovery also evaluates native state only after the locks are free
        // and the uncertain grant/debit caller has been cancelled.
        complete = isdefined( player ) && player owner_twins_grant_complete() &&
            !isdefined( owner_twins_other_wearer( player ) );
        success = complete && debit == ticket.price;
    }
    logstring( "OWNER_TWINS settled success=" + success + " debit=" + debit + " reason=" + reason );
    if ( !success )
    {
        if ( isdefined( player ) && debit > 0 )
            player currency::add_currency_amount( #"salvage", debit, "owner_twins_purchase_refund" );
        owner_twins_rollback_mask( ticket );
    }
}

function owner_twins_finish( ticket, success, reason )
{
    if ( istrue( ticket.closed ) )
        return;
    ticket.closed = 1;
    // Only plain GSC fields are touched before locks are released. Native credit,
    // cleanup and both cancellation signals run on the separate non-cancellable worker.
    owner_twins_release( ticket );
    level thread owner_twins_finish_worker( ticket, success, reason );
}

function owner_twins_recover( ticket, reason )
{
    owner_twins_finish( ticket, undefined, reason );
}

function owner_twins_watch_purchase( ticket )
{
    ticket endon( #"owner_twins_purchase_settled" );
    wait 3;
    owner_twins_recover( ticket, "native purchase did not finish" );
}

function owner_twins_watch_match_end( ticket )
{
    ticket endon( #"owner_twins_purchase_settled" );
    level waittill( #"game_ended" );
    owner_twins_recover( ticket, "match ended during purchase" );
}

function owner_twins_purchase( channel, value )
{
    if ( channel != "owner_twins_armory_purchase" || !isplayer( self ) || !isalive( self ) || istrue( self.inlaststand ) )
        return;
    if ( !utility::iszm() || "" + level.mapname != "zm_sat_scarab" )
        return self owner_twins_message( "Twins Mask requires Rex Infernus." );
    if ( isdefined( self.owner_twins_armory_ticket ) )
        return;
    if ( !isdefined( self.s_arsenal_machine ) || !isdefined( self.s_arsenal_machine.mdl_arsenal ) ||
        !isdefined( level.arsenal_menu ) || !level.arsenal_menu ZMArsenalMenu::is_open( self ) )
        return self owner_twins_message( "Open an Arsenal to buy the Twins Mask." );
    if ( distance2d( self.origin, self.s_arsenal_machine.mdl_arsenal.origin ) > 192 )
        return self owner_twins_message( "Move closer to the Arsenal." );
    if ( self owner_twins_has_mask() )
        return self owner_twins_message( "The Twins Mask is already equipped." );
    if ( isdefined( self.mask_ee ) && isdefined( self.mask_ee.var_73e37bf886655ce7 ) )
        return self owner_twins_message( "Remove your current mask before buying this one." );
    if ( !utility::issharedfuncdefined( #"zmloot_scarab_twins_ee_mask", #"hash_2e22b6be73e28e05" ) ||
        !utility::issharedfuncdefined( #"zmloot_scarab_twins_ee_mask", #"onuse" ) ||
        !isdefined( level.scarab_ee_masks ) ||
        !isdefined( level.scarab_ee_masks.var_c72c979b2dbc4e94[ "zmloot_scarab_twins_ee_mask" ] ) )
        return self owner_twins_message( "Twins Mask is unavailable in this mode." );
    if ( !isdefined( level.currency ) || !isdefined( level.currency[ #"salvage" ] ) )
        return self owner_twins_message( "Salvage purchases are unavailable in this mode." );
    bundle = getscriptbundle( %"hash_6ddbae43b1c907d8" );
    if ( !isdefined( bundle ) || bundle.ref != "zmloot_scarab_twins_ee_mask" || !isdefined( bundle.worldmodel ) )
        return self owner_twins_message( "Twins Mask is unavailable in this mode." );
    owner_twins_guard_pickups();
    item = spawnstruct();
    item.type = bundle.scriptable;
    item.count = 1;
    if ( !self utility::callsharedfunc( #"zmloot_scarab_twins_ee_mask", #"hash_2e22b6be73e28e05", bundle, item, 0, undefined ) )
        return self owner_twins_message( "The Twins Mask cannot be equipped right now." );
    price = owner_twins_price();
    if ( !self currency::can_afford( #"salvage", price ) )
        return self owner_twins_message( "Not enough salvage for the Twins Mask." );

    // Only this atomic claim follows potentially external prechecks. The native
    // lightning callback supports one wearer; include real quest-equipped wearers.
    if ( isdefined( level.owner_twins_armory_ticket ) || isdefined( owner_twins_other_wearer( self ) ) )
        return self owner_twins_message( "The Twins Mask is already in use." );
    ticket = spawnstruct();
    ticket.owner = self;
    ticket.price = price;
    ticket.other_delta = 0;
    ticket.prior_mask_id = self.scarab_ee_mask_id;
    self.owner_twins_armory_ticket = ticket;
    level.owner_twins_armory_ticket = ticket;
    level thread owner_twins_watch_purchase( ticket );
    level thread owner_twins_watch_match_end( ticket );
    ticket endon( #"owner_twins_purchase_cancel" );
    logstring( "OWNER_TWINS pending owner=" + self getentitynumber() + " price=" + price );

    // Grant first: an abort in the uncertain native mask handler spends nothing.
    self utility::callsharedfunc( #"zmloot_scarab_twins_ee_mask", #"onuse", bundle, item, 0, undefined );
    if ( !self owner_twins_grant_complete() || isdefined( owner_twins_other_wearer( self ) ) )
    {
        owner_twins_finish( ticket, false, "native grant postcondition failed" );
        return;
    }
    // Native handlers return without a scripted wait in the reference. The
    // independent watchdog also covers an interrupted debit after grant.
    ticket.before_debit = self currency::get_currency_amount( #"salvage" );
    if ( ticket.before_debit < price )
    {
        owner_twins_finish( ticket, false, "funds changed during grant" );
        return;
    }
    ticket.other_at_debit = ticket.other_delta;
    ticket.debit_started = 1;
    self currency::function_b5fe1e05c892a7f3( #"salvage", price, "owner_twins_purchase" );
    after = self currency::get_currency_amount( #"salvage" );
    observed = ticket.before_debit + ticket.other_delta - ticket.other_at_debit - after;
    if ( observed != price || !self owner_twins_grant_complete() )
    {
        owner_twins_finish( ticket, false, "grant/debit verification failed" );
        return;
    }
    self owner_twins_message( "Twins Mask equipped." );
    owner_twins_finish( ticket, true, "native mask and exact salvage debit verified" );
}
