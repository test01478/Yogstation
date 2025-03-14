// Disposal bin and Delivery chute.

#define SEND_PRESSURE (0.05*ONE_ATMOSPHERE)

/obj/machinery/disposal
	icon = 'icons/obj/atmospherics/pipes/disposal.dmi'
	density = TRUE
	armor = list(MELEE = 25, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 0, BIO = 100, RAD = 100, FIRE = 90, ACID = 30, ELECTRIC = 100)
	max_integrity = 200
	resistance_flags = FIRE_PROOF
	interaction_flags_machine = INTERACT_MACHINE_OPEN | INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON
	obj_flags = CAN_BE_HIT | USES_TGUI
	flags_1 = RAD_PROTECT_CONTENTS_1 | RAD_NO_CONTAMINATE_1
	/// The internal air reservoir of the disposal
	var/datum/gas_mixture/air_contents
	/// Is the disposal at full pressure
	var/full_pressure = FALSE
	/// Is the pressure charging
	var/pressure_charging = TRUE
	// True if flush handle is pulled
	var/flush = FALSE
	
	/// The attached pipe trunk
	var/obj/structure/disposalpipe/trunk/trunk = null
	/// True if flushing in progress
	var/flushing = FALSE
	/// Every 30 ticks it will look whether it is ready to flush
	var/flush_every_ticks = 30
	/// This var adds 1 once per tick. When it reaches flush_every_ticks it resets and tries to flush.
	var/flush_count = 0
	/// The last time a sound was played
	var/last_sound = 0
	/// The stored disposal construction pipe
	var/obj/structure/disposalconstruct/stored

// create a new disposal
// find the attached trunk (if present) and init gas resvr.
/obj/machinery/disposal/Initialize(mapload, obj/structure/disposalconstruct/make_from)
	. = ..()

	if(make_from)
		setDir(make_from.dir)
		make_from.moveToNullspace()
		stored = make_from
		pressure_charging = FALSE // newly built disposal bins start with pump off
	else
		stored = new /obj/structure/disposalconstruct(null, null , SOUTH , FALSE , src)

	trunk_check()

	air_contents = new /datum/gas_mixture()
	//gas.volume = 1.05 * CELLSTANDARD
	update_appearance()

	return INITIALIZE_HINT_LATELOAD //we need turfs to have air

/obj/machinery/disposal/proc/trunk_check()
	trunk = locate() in loc
	if(!trunk)
		pressure_charging = FALSE
		flush = FALSE
	else
		if(initial(pressure_charging))
			pressure_charging = TRUE
		flush = initial(flush)
		trunk.linked = src // link the pipe trunk to self

/obj/machinery/disposal/Destroy()
	eject()
	if(trunk)
		trunk.linked = null
	return ..()

/obj/machinery/disposal/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct()

/obj/machinery/disposal/LateInitialize()
	//this will get a copy of the air turf and take a SEND PRESSURE amount of air from it
	var/atom/L = loc
	var/datum/gas_mixture/loc_air = L.return_air()
	var/datum/gas_mixture/env = new
	if(loc_air)
		env.copy_from(loc_air)
		var/datum/gas_mixture/removed = env.remove(SEND_PRESSURE + 1)
		if(removed)
			air_contents.merge(removed)
	trunk_check()

/obj/machinery/disposal/attackby(obj/item/I, mob/user, params)
	add_fingerprint(user)
	if(!pressure_charging && !full_pressure && !flush)
		if(I.tool_behaviour == TOOL_SCREWDRIVER)
			panel_open = !panel_open
			I.play_tool_sound(src)
			to_chat(user, span_notice("You [panel_open ? "remove":"attach"] the screws around the power connection."))
			return
		else if(I.tool_behaviour == TOOL_WELDER && panel_open)
			if(!I.tool_start_check(user, amount=0))
				return

			to_chat(user, span_notice("You start slicing the floorweld off \the [src]..."))
			if(I.use_tool(src, user, 20, volume=100) && panel_open)
				to_chat(user, span_notice("You slice the floorweld off \the [src]."))
				deconstruct()
			return

	if(!user.combat_mode)
		if((I.item_flags & ABSTRACT) || !user.temporarilyRemoveItemFromInventory(I))
			return
		place_item_in_disposal(I, user)
		update_appearance()
		return TRUE //no afterattack
	else
		return ..()

/obj/machinery/disposal/proc/place_item_in_disposal(obj/item/I, mob/user)
	I.forceMove(src)
	user.visible_message("[user.name] places \the [I] into \the [src].", span_notice("You place \the [I] into \the [src]."))

//mouse drop another mob or self
/obj/machinery/disposal/MouseDrop_T(mob/living/target, mob/living/user)
	if(istype(target))
		stuff_mob_in(target, user)

/obj/machinery/disposal/proc/stuff_mob_in(mob/living/target, mob/living/user)
	if(!iscarbon(user) && !user.ventcrawler && user == target) //only carbon and ventcrawlers can climb into disposal by themselves.
		if (iscyborg(user))
			var/mob/living/silicon/robot/borg = user
			if (!borg.module || !borg.module.canDispose)
				return
		else
			return
	if(!isturf(user.loc)) //No magically doing it from inside closets
		return
	if(target.buckled || target.has_buckled_mobs())
		return
	if(target.mob_size > MOB_SIZE_HUMAN)
		to_chat(user, span_warning("[target] doesn't fit inside [src]!"))
		return
	add_fingerprint(user)
	if(user == target)
		user.visible_message("[user] starts climbing into [src].", span_notice("You start climbing into [src]..."))
	else
		target.visible_message(span_danger("[user] starts putting [target] into [src]."), span_userdanger("[user] starts putting you into [src]!"))
	if(do_after(user, 2 SECONDS, target))
		if (!loc)
			return
		target.forceMove(src)
		if(user == target)
			user.visible_message("[user] climbs into [src].", span_notice("You climb into [src]."))
		else
			target.visible_message(span_danger("[user] has placed [target] in [src]."), span_userdanger("[user] has placed [target] in [src]."))
			log_combat(user, target, "stuffed", addition="into [src]")
			target.LAssailant = WEAKREF(user)
		update_appearance()

/obj/machinery/disposal/relaymove(mob/user)
	attempt_escape(user)

// resist to escape the bin
/obj/machinery/disposal/container_resist(mob/living/user)
	attempt_escape(user)

/obj/machinery/disposal/proc/attempt_escape(mob/user)
	if(flushing)
		return
	go_out(user)

// leave the disposal
/obj/machinery/disposal/proc/go_out(mob/user)
	user.forceMove(loc)
	update_appearance()

// monkeys and xenos can only pull the flush lever
/obj/machinery/disposal/attack_paw(mob/user)
	if(stat & BROKEN)
		return
	flush = !flush
	update_appearance()


// eject the contents of the disposal unit
/obj/machinery/disposal/proc/eject()
	var/turf/T = get_turf(src)
	for(var/atom/movable/AM in src)
		AM.forceMove(T)
		AM.pipe_eject(0)
	update_appearance()

/obj/machinery/disposal/proc/flush()
	flushing = TRUE
	flick("[icon_state]-flush", src)
	sleep(1 SECONDS)
	if(last_sound < world.time + 1)
		playsound(src, 'sound/machines/disposalflush.ogg', 50, 0, 0)
		last_sound = world.time
	sleep(0.5 SECONDS)
	if(QDELETED(src))
		return
	var/obj/structure/disposalholder/H = new(src)
	newHolderDestination(H)
	H.init(src)
	air_contents = new()
	H.start(src)
	flushing = FALSE
	flush = FALSE

/obj/machinery/disposal/proc/newHolderDestination(obj/structure/disposalholder/H)
	H.destinationTag = SORT_TYPE_DISPOSALS
	for(var/obj/item/smallDelivery/O in src)
		H.tomail = TRUE
		return

// called when holder is expelled from a disposal
/obj/machinery/disposal/proc/expel(obj/structure/disposalholder/H)
	H.active = FALSE

	var/turf/T = get_turf(src)
	var/turf/target
	playsound(src, 'sound/machines/hiss.ogg', 50, 0, 0)

	for(var/A in H)
		var/atom/movable/AM = A

		target = get_offset_target_turf(loc, rand(5)-rand(5), rand(5)-rand(5))

		AM.forceMove(T)
		AM.pipe_eject(0)
		AM.throw_at(target, 5, 1)

	H.vent_gas(loc)
	qdel(H)

/obj/machinery/disposal/deconstruct(disassembled = TRUE)
	var/turf/T = loc
	if(!(flags_1 & NODECONSTRUCT_1))
		if(stored)
			stored.forceMove(T)
			src.transfer_fingerprints_to(stored)
			stored.anchored = FALSE
			stored.density = TRUE
			stored.update_appearance()
	for(var/atom/movable/AM in src) //out, out, darned crowbar!
		AM.forceMove(T)
	..()

/obj/machinery/disposal/get_dumping_location(obj/item/storage/source,mob/user)
	return src

//How disposal handles getting a storage dump from a storage object
/obj/machinery/disposal/storage_contents_dump_act(datum/component/storage/src_object, mob/user)
	. = ..()
	if(.)
		return
	for(var/obj/item/I in src_object.contents())
		if(user.active_storage != src_object)
			if(I.on_found(user))
				return
		src_object.remove_from_storage(I, src)
	return TRUE

// Disposal bin
// Holds items for disposal into pipe system
// Draws air from turf, gradually charges internal reservoir
// Once full (~1 atm), uses air resv to flush items into the pipes
// Automatically recharges air (unless off), will flush when ready if pre-set
// Can hold items and human size things, no other draggables

/obj/machinery/disposal/bin
	name = "disposal unit"
	desc = "A pneumatic waste disposal unit."
	icon_state = "disposal"
	base_icon_state = "disposal"
	/// Reference to the mounted destination tagger for disposal bins with one mounted.
	var/obj/item/destTagger/mounted_tagger

// attack by item places it in to disposal
/obj/machinery/disposal/bin/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/storage/bag/trash)) //Not doing component overrides because this is a specific type.
		var/obj/item/storage/bag/trash/b = I
		var/datum/component/storage/STR = b.GetComponent(/datum/component/storage)
		to_chat(user, span_warning("You empty the bag."))
		for(var/obj/item/O in b.contents)
			STR.remove_from_storage(O,src)
		b.update_appearance()
		update_appearance()
	else if(istype(I, /obj/item/destTagger))
		return
	else
		return ..()

// handle machine interaction

/obj/machinery/disposal/bin/attackby_secondary(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/destTagger))
		var/obj/item/destTagger/new_tagger = I
		if(mounted_tagger)
			balloon_alert(user, "already has a tagger!")
			return
		if(HAS_TRAIT(new_tagger, TRAIT_NODROP) || !user.transferItemToLoc(new_tagger, src))
			balloon_alert(user, "stuck to your hand!")
			return
		new_tagger.moveToNullspace()
		user.visible_message(span_notice("[user] snaps \the [new_tagger] onto [src]!"))
		balloon_alert(user, "tagger returned")
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		mounted_tagger = new_tagger
		update_appearance()
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	else
		return ..()

/obj/machinery/disposal/bin/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(!mounted_tagger)
		balloon_alert(user, "no destination tagger!")
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(!user.put_in_hands(mounted_tagger))
		balloon_alert(user, "destination tagger falls!")
		mounted_tagger = null
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	user.visible_message(span_notice("[user] unhooks the [mounted_tagger] from [src]."))
	balloon_alert(user, "tagger pulled")
	playsound(src, 'sound/machines/click.ogg', 60, TRUE)
	mounted_tagger = null
	update_appearance(UPDATE_OVERLAYS)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN


/obj/machinery/disposal/bin/examine(mob/user)
	. = ..()
	if(isnull(mounted_tagger))
		. += span_notice("The destination tagger mount is empty.")
	else
		. += span_notice("\The [mounted_tagger] is hanging on the side. Right Click to remove.")

/obj/machinery/disposal/bin/Destroy()
	if(!isnull(mounted_tagger))
		QDEL_NULL(mounted_tagger)
	return ..()

/obj/machinery/disposal/bin/on_deconstruction(disassembled)
	. = ..()
	if(!isnull(mounted_tagger))
		mounted_tagger.forceMove(drop_location())
		mounted_tagger = null

/obj/machinery/disposal/bin/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, TRUE))
		return
	flush = !flush
	update_appearance()

/obj/machinery/disposal/bin/ui_state(mob/user)
	return GLOB.notcontained_state

/obj/machinery/disposal/bin/ui_interact(mob/user, datum/tgui/ui)
	if(stat & BROKEN)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DisposalUnit", name)
		ui.open()

/obj/machinery/disposal/bin/ui_data(mob/user)
	var/list/data = list()
	data["flush"] = flush
	data["full_pressure"] = full_pressure
	data["pressure_charging"] = pressure_charging
	data["panel_open"] = panel_open
	data["per"] = CLAMP01(air_contents.return_pressure() / (SEND_PRESSURE))
	data["isai"] = isAI(user)
	return data

/obj/machinery/disposal/bin/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("handle-0")
			flush = FALSE
			update_appearance()
			. = TRUE
		if("handle-1")
			if(!panel_open)
				flush = TRUE
				update_appearance()
			. = TRUE
		if("pump-0")
			if(pressure_charging)
				pressure_charging = FALSE
				update_appearance()
			. = TRUE
		if("pump-1")
			if(!pressure_charging)
				pressure_charging = TRUE
				update_appearance()
			. = TRUE
		if("eject")
			eject()
			. = TRUE


/obj/machinery/disposal/bin/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if(AM.CanEnterDisposals())
		if(prob(75))
			AM.forceMove(src)
			if(ismob(AM))
				do_flush()
				visible_message(span_notice("[AM] lands in [src] and triggers the flush system!"))
			else
				visible_message(span_notice("[AM] lands in [src]."))
			update_appearance()
		else
			visible_message(span_notice("[AM] bounces off of [src]'s rim!"))
			return ..()
	else
		return ..()

/obj/machinery/disposal/bin/flush()
	..()
	full_pressure = FALSE
	pressure_charging = TRUE
	update_appearance()

/obj/machinery/disposal/bin/update_overlays()
	. = ..()
	if(stat & BROKEN)
		pressure_charging = FALSE
		flush = FALSE
		return

	//flush handle
	if(flush)
		. += "[base_icon_state]-dispover-handle"

	if(mounted_tagger)
		. += "tagger_mount"

	//only handle is shown if no power
	if(stat & NOPOWER || panel_open)
		return

	//check for items in disposal - occupied light
	if(contents.len > 0)
		. += "[base_icon_state]-dispover-full"
		. += emissive_appearance(icon, "[base_icon_state]-dispover-full", src, alpha = src.alpha)

	//charging and ready light
	if(pressure_charging)
		. += "[base_icon_state]-dispover-charge"
		. += emissive_appearance(icon, "[base_icon_state]-dispover-charge-glow", src, alpha = src.alpha)
	else if(full_pressure)
		. += "[base_icon_state]-dispover-ready"
		. += emissive_appearance(icon, "[base_icon_state]-dispover-ready-glow", src, alpha = src.alpha)

/obj/machinery/disposal/bin/proc/do_flush()
	set waitfor = FALSE
	flush()

/obj/machinery/disposal/bin/tagger/Initialize(mapload, obj/structure/disposalconstruct/make_from)
	mounted_tagger = new /obj/item/destTagger(null)
	return ..()

//timed process
//charge the gas reservoir and perform flush if ready
/obj/machinery/disposal/bin/process(delta_time)
	if(stat & BROKEN) //nothing can happen if broken
		return

	flush_count++
	if(flush_count >= flush_every_ticks)
		if(contents.len)
			if(full_pressure)
				do_flush()
		flush_count = 0

	updateDialog()

	if(flush && air_contents.return_pressure() >= SEND_PRESSURE) // flush can happen even without power
		do_flush()

	if(stat & NOPOWER) // won't charge if no power
		return

	use_power(100) // base power usage

	if(!pressure_charging) // if off or ready, no need to charge
		return

	// otherwise charge
	use_power(500) // charging power usage

	var/atom/L = loc //recharging from loc turf

	var/datum/gas_mixture/env = L.return_air()
	var/pressure_delta = (SEND_PRESSURE*1.01) - air_contents.return_pressure()

	if(env?.return_temperature() > 0)
		var/transfer_moles = 0.05 * delta_time * pressure_delta*air_contents.return_volume()/(env.return_temperature() * R_IDEAL_GAS_EQUATION)

		//Actually transfer the gas
		var/datum/gas_mixture/removed = env.remove(transfer_moles)
		air_contents.merge(removed)

	//if full enough, switch to ready mode
	if(air_contents.return_pressure() >= SEND_PRESSURE)
		full_pressure = TRUE
		pressure_charging = FALSE
		update_appearance()
	return

/obj/machinery/disposal/bin/get_remote_view_fullscreens(mob/user)
	if(user.stat == DEAD || !(user.sight & (SEEOBJS|SEEMOBS)))
		user.overlay_fullscreen("remote_view", /atom/movable/screen/fullscreen/impaired, 2)

//Delivery Chute

/obj/machinery/disposal/deliveryChute
	name = "delivery chute"
	desc = "A chute for big and small packages alike!"
	density = TRUE
	icon_state = "intake"
	pressure_charging = FALSE // the chute doesn't need charging and always works

/obj/machinery/disposal/deliveryChute/Initialize(mapload, obj/structure/disposalconstruct/make_from)
	. = ..()
	trunk = locate() in loc
	if(trunk)
		trunk.linked = src	// link the pipe trunk to self

/obj/machinery/disposal/deliveryChute/place_item_in_disposal(obj/item/I, mob/user)
	if(I.CanEnterDisposals())
		..()
		flush()

/obj/machinery/disposal/deliveryChute/Bumped(atom/movable/AM) //Go straight into the chute
	if(QDELETED(AM) || !AM.CanEnterDisposals())
		return
	switch(dir)
		if(NORTH)
			if(AM.loc.y != loc.y+1)
				return
		if(EAST)
			if(AM.loc.x != loc.x+1)
				return
		if(SOUTH)
			if(AM.loc.y != loc.y-1)
				return
		if(WEST)
			if(AM.loc.x != loc.x-1)
				return

	if(isobj(AM))
		var/obj/O = AM
		O.forceMove(src)
	else if(ismob(AM))
		var/mob/M = AM
		if(prob(2)) // to prevent mobs being stuck in infinite loops
			to_chat(M, span_warning("You hit the edge of the chute."))
			return
		M.forceMove(src)
	flush()

/atom/movable/proc/CanEnterDisposals()
	return TRUE

/obj/projectile/CanEnterDisposals()
	return

/obj/effect/CanEnterDisposals()
	return

/obj/mecha/CanEnterDisposals()
	return



