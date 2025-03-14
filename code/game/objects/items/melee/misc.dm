/obj/item/melee
	item_flags = NEEDS_PERMIT

/obj/item/melee/chainofcommand
	name = "chain of command"
	desc = "A tool used by great men to placate the frothing masses."
	icon = 'icons/obj/weapons/whip.dmi'
	icon_state = "chain"
	item_state = "chain"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	force = 10
	throwforce = 7
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb = list("flogged", "whipped", "lashed", "disciplined")
	hitsound = 'sound/weapons/chainhit.ogg'
	materials = list(/datum/material/iron = 1000)

/obj/item/melee/chainofcommand/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] is strangling [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return (OXYLOSS)

/obj/item/melee/synthetic_arm_blade
	name = "synthetic arm blade"
	desc = "A grotesque blade that on closer inspection seems made of synthetic flesh, it still feels like it would hurt very badly as a weapon."
	icon = 'icons/obj/weapons/hand.dmi'
	icon_state = "arm_blade"
	item_state = "arm_blade"
	lefthand_file = 'icons/mob/inhands/antag/changeling_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/changeling_righthand.dmi'
	w_class = WEIGHT_CLASS_HUGE
	force = 20
	throwforce = 10
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	sharpness = SHARP_EDGED

/obj/item/melee/synthetic_arm_blade/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 60, 80) //very imprecise

/obj/item/melee/cutlass
	name = "cutlass"
	desc = "YAAAAAR! A fine weapon for a pirate, fit for slicing land-lubbers." //All pirate weapons must have pirate quips from now on it is non-negotiable
	icon = 'icons/obj/weapons/longsword.dmi'
	icon_state = "metalcutlass"
	item_state = "metalcutlass"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	force = 18
	throwforce = 10
	w_class = WEIGHT_CLASS_HUGE
	sharpness = SHARP_EDGED
	attack_verb = list("slashed", "cut")
	hitsound = 'sound/weapons/rapierhit.ogg'
	materials = list(/datum/material/iron = 1000)

/obj/item/melee/cutlass/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/cleave_attack)
	AddComponent(/datum/component/blocking, block_flags = 15, block_flags = WEAPON_BLOCK_FLAGS|PROJECTILE_ATTACK|REFLECTIVE_BLOCK)

/obj/item/melee/sabre
	name = "officer's sabre"
	desc = "An elegant weapon, its monomolecular edge is capable of cutting through flesh and bone with ease."
	icon = 'icons/obj/weapons/longsword.dmi'
	icon_state = "sabre"
	item_state = "sabre"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	flags_1 = CONDUCT_1
	obj_flags = UNIQUE_RENAME | UNIQUE_REDESC
	force = 15
	throwforce = 10
	wound_bonus = 10
	w_class = WEIGHT_CLASS_BULKY
	armour_penetration = 75
	sharpness = SHARP_EDGED
	attack_verb = list("slashed", "cut")
	hitsound = 'sound/weapons/rapierhit.ogg'
	materials = list(/datum/material/iron = 1000)

/obj/item/melee/sabre/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/cleave_attack) // YES
	AddComponent(/datum/component/butchering, 30, 95, 5) //fast and effective, but as a sword, it might damage the results.
	AddComponent(/datum/component/blocking, block_force = 20)

/obj/item/melee/sabre/on_exit_storage(datum/component/storage/concrete/S)
	var/obj/item/storage/belt/sabre/B = S.real_location()
	if(istype(B))
		playsound(B, 'sound/items/unsheath.ogg', 25, TRUE)

/obj/item/melee/sabre/on_enter_storage(datum/component/storage/concrete/S)
	var/obj/item/storage/belt/sabre/B = S.real_location()
	if(istype(B))
		playsound(B, 'sound/items/sheath.ogg', 25, TRUE)

/obj/item/melee/sabre/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is trying to cut off all [user.p_their()] limbs with [src]! it looks like [user.p_theyre()] trying to commit suicide!"))
	var/i = 0
	ADD_TRAIT(src, TRAIT_NODROP, SABRE_SUICIDE_TRAIT)
	if(iscarbon(user))
		var/mob/living/carbon/Cuser = user
		var/obj/item/bodypart/holding_bodypart = Cuser.get_holding_bodypart_of_item(src)
		var/list/limbs_to_dismember
		var/list/arms = list()
		var/list/legs = list()
		var/obj/item/bodypart/bodypart

		for(bodypart in Cuser.bodyparts)
			if(bodypart == holding_bodypart)
				continue
			if(bodypart.body_part & ARMS)
				arms += bodypart
			else if (bodypart.body_part & LEGS)
				legs += bodypart

		limbs_to_dismember = arms + legs
		if(holding_bodypart)
			limbs_to_dismember += holding_bodypart

		var/speedbase = abs((4 SECONDS) / limbs_to_dismember.len)
		for(bodypart in limbs_to_dismember)
			i++
			addtimer(CALLBACK(src, PROC_REF(suicide_dismember), user, bodypart), speedbase * i)
	addtimer(CALLBACK(src, PROC_REF(manual_suicide), user), (5 SECONDS) * i)
	return MANUAL_SUICIDE

/obj/item/melee/sabre/proc/suicide_dismember(mob/living/user, obj/item/bodypart/affecting)
	if(!QDELETED(affecting) && affecting.dismemberable && affecting.owner == user && !QDELETED(user))
		playsound(user, hitsound, 25, 1)
		affecting.dismember(BRUTE)
		user.adjustBruteLoss(20)

/obj/item/melee/sabre/proc/manual_suicide(mob/living/user, originally_nodropped)
	if(!QDELETED(user))
		user.adjustBruteLoss(200)
		user.death(FALSE)
	REMOVE_TRAIT(src, TRAIT_NODROP, SABRE_SUICIDE_TRAIT)

/obj/item/melee/beesword
	name = "The Stinger"
	desc = "Taken from a giant bee and folded over one thousand times in pure honey. Can sting through anything."
	icon = 'icons/obj/weapons/longsword.dmi'
	icon_state = "beesword"
	item_state = "stinger"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	force = 7
	throwforce = 10
	armour_penetration = 85
	attack_verb = list("slashed", "stung", "prickled", "poked")
	hitsound = 'sound/weapons/rapierhit.ogg'

/obj/item/melee/beesword/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/blocking, block_force = 10)

/obj/item/melee/beesword/afterattack(atom/target, mob/user, proximity = TRUE)
	. = ..()
	user.changeNext_move(CLICK_CD_RAPID)
	if(iscarbon(target))
		var/mob/living/carbon/H = target
		H.reagents.add_reagent(/datum/reagent/toxin/histamine, 4)

/obj/item/melee/beesword/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is stabbing [user.p_them()]self in the throat with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(get_turf(src), hitsound, 75, 1, -1)
	return TOXLOSS

/obj/item/melee/classic_baton
	name = "police baton"
	desc = "A wooden truncheon for beating criminal scum."
	icon = 'icons/obj/weapons/baton.dmi'
	icon_state = "baton"
	item_state = "classic_baton"
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	force = 12 //9 hit crit
	w_class = WEIGHT_CLASS_NORMAL

	var/cooldown_check = 0 // Used interally, you don't want to modify

	var/cooldown = 1 SECONDS // Default wait time until can stun again.
	var/knockdown_time_carbon = 1.5 SECONDS // Knockdown length for carbons.
	var/stun_time_silicon = 5 SECONDS // If enabled, how long do we stun silicons.
	var/stamina_damage = 60 // How much stamina damage we deal.
	var/block_threshold = 60 // Threshold at which armor blocks special effects.
	var/affect_silicon = FALSE // Does it stun silicons.
	var/on_sound // "On" sound, played when switching between able to stun or not.
	var/on_stun_sound = "sound/effects/woodhit.ogg" // Default path to sound for when we stun.
	var/stun_animation = FALSE // Do we animate the "hit" when stunning.
	var/on = TRUE // Are we on or off.

	var/on_icon_state // What is our sprite when turned on
	var/off_icon_state // What is our sprite when turned off
	var/on_item_state // What is our in-hand sprite when turned on
	var/force_on // Damage when on - not stunning
	var/force_off // Damage when off - not stunning
	var/weight_class_on // What is the new size class when turned on

	wound_bonus = 15

// Handles all the effects if a successful strike
/obj/item/melee/classic_baton/proc/stun(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if (H.check_shields(src, 0, "[user]'s [name]", MELEE_ATTACK, damage_type = STAMINA))
			playsound(target, 'sound/weapons/genhit.ogg', 50, 1)
			return
		var/datum/martial_art/M = H.check_block()
		if(M)
			M.handle_counter(target, user)
			return

	var/list/desc = get_hit_description(target, user)

	var/obj/item/bodypart/affecting = target.get_bodypart(user.zone_selected)
	var/armor_block = target.run_armor_check(affecting, MELEE)
	target.apply_damage(stamina_damage, STAMINA, user.zone_selected, armor_block)
	var/current_stamina_damage = target.getStaminaLoss()

	if(stun_animation)
		user.do_attack_animation(target)

	if(user)
		target.lastattacker = user.real_name
		target.lastattackerckey = user.ckey
		log_combat(user, target, "stunned")

	playsound(get_turf(src), on_stun_sound, 75, 1, -1)

	if(current_stamina_damage >= 100)
		desc = get_stun_description(target, user)
		target.Knockdown(knockdown_time_carbon)
		target.visible_message(desc["visible"], desc["local"])
		return

	if(armor_block >= block_threshold)
		target.visible_message(desc["visible"], desc["local"])
		playsound(target, 'sound/weapons/genhit.ogg', 50, 1)
		return

	// Special effects
	if(affecting?.stamina_dam >= 50 && (istype(affecting, /obj/item/bodypart/leg)))
		desc = get_stun_description(target, user)
		target.Knockdown(knockdown_time_carbon)

	else if(istype(affecting, /obj/item/bodypart/l_arm) && target.held_items[LEFT_HANDS])
		target.dropItemToGround(target.held_items[LEFT_HANDS])
	else if(istype(affecting, /obj/item/bodypart/r_arm) && target.held_items[RIGHT_HANDS])
		target.dropItemToGround(target.held_items[RIGHT_HANDS])
	target.visible_message(desc["visible"], desc["local"])

// Are we applying any special effects when we stun to silicon
/obj/item/melee/classic_baton/proc/stun_silicon(mob/living/silicon/target, mob/living/user)
	var/list/desc = get_silicon_stun_description(target, user)

	target.flash_act(affect_silicon = TRUE)
	target.Paralyze(stun_time_silicon)
	additional_effects_silicon(target, user)

	user.visible_message(desc["visible"], desc["local"])
	playsound(get_turf(src), on_stun_sound, 100, TRUE, -1)

	if (stun_animation)
		user.do_attack_animation(target)

// Description for trying to stun when still on cooldown.
/obj/item/melee/classic_baton/proc/get_wait_description()
	return

// Description for when turning their baton "on"
/obj/item/melee/classic_baton/proc/get_on_description()
	. = list()

	.["local_on"] = span_danger("You extend the baton.")
	.["local_off"] = span_danger("You collapse the baton.")

	return .

// Default message for hitting mob.
/obj/item/melee/classic_baton/proc/get_hit_description(mob/living/target, mob/living/user)
	. = list()

	.["visible"] =  span_danger("[user] struck [target] with [src]!")
	.["local"] = span_danger("[user] struck [target] with [src]!")

	return .

// Default message for stunning mob.
/obj/item/melee/classic_baton/proc/get_stun_description(mob/living/target, mob/living/user)
	. = list()

	.["visible"] =  span_danger("[user] has knocked down [target] with [src]!")
	.["local"] = span_danger("[user] has knocked down [target] with [src]!")

	return .

// Default message for stunning a silicon.
/obj/item/melee/classic_baton/proc/get_silicon_stun_description(mob/living/target, mob/living/user)
	. = list()

	.["visible"] = span_danger("[user] pulses [target]'s sensors with the baton!")
	.["local"] = span_danger("You pulse [target]'s sensors with the baton!")

	return .

// Are we applying any special effects when we stun to carbon
/obj/item/melee/classic_baton/proc/additional_effects_carbon(mob/living/target, mob/living/user)
	return

// Are we applying any special effects when we stun to silicon
/obj/item/melee/classic_baton/proc/additional_effects_silicon(mob/living/target, mob/living/user)
	return

/obj/item/melee/classic_baton/attack(mob/living/target, mob/living/user, params)
	var/list/modifiers = params2list(params)
	if(!on || (user.combat_mode && modifiers && modifiers[RIGHT_CLICK])) // right click to harm, so you can keep combat mode on to prevent walking through people
		return ..()
	if(!isliving(target))
		return ..()
	if(!synth_check(user, SYNTH_RESTRICTED_WEAPON))
		return TRUE
	if(HAS_TRAIT(user, TRAIT_NO_STUN_WEAPONS))
		to_chat(user, span_warning("You can't seem to remember how this works!"))
		return TRUE
	add_fingerprint(user)
	if((HAS_TRAIT(user, TRAIT_CLUMSY)) && prob(50))
		to_chat(user, "<span class ='danger'>You hit yourself over the head.</span>")
		user.Paralyze(knockdown_time_carbon * force)
		user.adjustStaminaLoss(stamina_damage)
		if(iscarbon(user))
			additional_effects_carbon(user) // user is the target here
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.apply_damage(2*force, BRUTE, BODY_ZONE_HEAD)
		else
			user.take_bodypart_damage(2*force)
		return TRUE

	if(iscyborg(target))
		if(affect_silicon)
			stun_silicon(target, user)
			return TRUE
		return ..()

	if(cooldown_check <= world.time)
		stun(target, user)
	else
		var/wait_desc = get_wait_description()
		if (wait_desc)
			to_chat(user, wait_desc)

/obj/item/melee/classic_baton/donkbat
	name = "toy baseball bat"
	desc = "A colorful foam baseball bat. The label on the handle reads Donksoft. Feels...heavy."
	icon = 'icons/obj/weapons/bat.dmi'
	icon_state = "baseball_bat_donk"
	item_state = "baseball_bat_donk"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	force = 6
	stamina_damage = 40


/obj/item/melee/classic_baton/telescopic
	name = "telescopic baton"
	desc = "A compact yet robust personal defense weapon. Can be concealed when folded."
	icon_state = "telebaton_0"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	item_state = null
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NONE
	force = 0
	on = FALSE
	on_sound = 'sound/weapons/batonextend.ogg'

	on_icon_state = "telebaton_1"
	off_icon_state = "telebaton_0"
	on_item_state = "nullrod"
	force_on = 10
	force_off = 0
	stamina_damage = 40
	block_threshold = 50
	weight_class_on = WEIGHT_CLASS_BULKY
	bare_wound_bonus = 5

/obj/item/melee/classic_baton/telescopic/suicide_act(mob/user)
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/brain/B = H.getorgan(/obj/item/organ/brain)

	user.visible_message(span_suicide("[user] stuffs [src] up [user.p_their()] nose and presses the 'extend' button! It looks like [user.p_theyre()] trying to clear [user.p_their()] mind."))
	if(!on)
		src.attack_self(user)
	else
		playsound(src, on_sound, 50, 1)
		add_fingerprint(user)
	sleep(0.3 SECONDS)
	if (!QDELETED(H))
		if(!QDELETED(B))
			H.internal_organs -= B
			qdel(B)
		new /obj/effect/gibspawner/generic(H.drop_location(), H)
		return (BRUTELOSS)

/obj/item/melee/classic_baton/telescopic/attack_self(mob/user)
	on = !on
	var/list/desc = get_on_description()

	if(on)
		to_chat(user, desc["local_on"])
		icon_state = on_icon_state
		item_state = on_item_state
		w_class = weight_class_on
		force = force_on
		stamina_damage = initial(stamina_damage)
		attack_verb = list("smacked", "struck", "cracked", "beaten")
	else
		to_chat(user, desc["local_off"])
		icon_state = off_icon_state
		item_state = null //no sprite for concealment even when in hand
		slot_flags = ITEM_SLOT_BELT
		w_class = WEIGHT_CLASS_SMALL
		force = force_off
		stamina_damage = 0
		attack_verb = list("hit", "poked")

	playsound(src.loc, on_sound, 50, 1)
	add_fingerprint(user)

/obj/item/melee/classic_baton/telescopic/contractor_baton
	name = "contractor baton"
	desc = "A compact, specialised baton assigned to Syndicate contractors. Applies light electrical shocks to targets."
	icon_state = "contractor_baton_0"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	item_state = null
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NONE
	force = 5
	cooldown = 2.5 SECONDS
	stamina_damage = 85
	affect_silicon = TRUE
	on_sound = 'sound/weapons/contractorbatonextend.ogg'
	on_stun_sound = 'sound/effects/contractorbatonhit.ogg'
	stun_animation = TRUE

	on_icon_state = "contractor_baton_1"
	off_icon_state = "contractor_baton_0"
	on_item_state = "contractor_baton"
	force_on = 16
	force_off = 5
	weight_class_on = WEIGHT_CLASS_NORMAL

/obj/item/melee/classic_baton/telescopic/contractor_baton/stun(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if (H.check_shields(src, 0, "[user]'s [name]", MELEE_ATTACK, damage_type = STAMINA))
			playsound(target, 'sound/weapons/genhit.ogg', 50, 1)
			return
		var/datum/martial_art/M = H.check_block()
		if(M)
			M.handle_counter(target, user)
			return

	var/list/desc = get_stun_description(target, user)

	if (stun_animation)
		user.do_attack_animation(target)

	playsound(get_turf(src), on_stun_sound, 75, 1, -1)
	target.Knockdown(knockdown_time_carbon)
	target.adjustStaminaLoss(stamina_damage)
	if(iscarbon(target))
		additional_effects_carbon(target, user)

	log_combat(user, target, "stunned", src)
	add_fingerprint(user)

	target.visible_message(desc["visible"], desc["local"])

	if(!iscarbon(user))
		target.LAssailant = null
	else
		target.LAssailant = WEAKREF(user)
	cooldown_check = world.time + cooldown

/obj/item/melee/classic_baton/telescopic/contractor_baton/get_wait_description()
	return span_danger("The baton is still charging!")

/obj/item/melee/classic_baton/telescopic/contractor_baton/additional_effects_carbon(mob/living/carbon/target, mob/living/user)
	target.set_jitter_if_lower(40 SECONDS)
	target.set_stutter_if_lower(40 SECONDS)
	if(HAS_TRAIT_FROM(target, TRAIT_INCAPACITATED, STAMINA))
		target.silent += 5

/obj/item/melee/classic_baton/secconbaton
	name = "billy club"
	desc = "A dark wooden club with the Space Queen's crest burned onto its bottom. Its wrist strap will help keep it in your hands and out of crooks'."
	icon_state = "secconbaton"
	item_state = "secconbaton"
	force = 10
	stamina_damage = 15
	var/tighten = FALSE
	actions_types = list(/datum/action/item_action/wrist_strap)

/obj/item/melee/classic_baton/secconbaton/ui_action_click(mob/user)
	tighten = !tighten
	if(tighten)
		user.balloon_alert(user, "Wrist strap tightened.")
		ADD_TRAIT(src, TRAIT_NODROP, WRIST_STRAP_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_NODROP, WRIST_STRAP_TRAIT)
		user.balloon_alert(user, "Wrist strap loosened.")

/datum/action/item_action/wrist_strap
	name = "Adjust Wrist Strap"

/obj/item/melee/supermatter_sword
	name = "supermatter sword"
	desc = "In a station full of bad ideas, this might just be the worst."
	icon = 'icons/obj/weapons/longsword.dmi'
	icon_state = "supermatter_sword"
	item_state = "supermatter_sword"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	slot_flags = null
	w_class = WEIGHT_CLASS_BULKY
	force = 0.001
	armour_penetration = 1000
	var/obj/machinery/power/supermatter_crystal/shard
	var/balanced = 1
	force_string = "INFINITE"

/obj/item/melee/supermatter_sword/Initialize(mapload)
	. = ..()
	shard = new /obj/machinery/power/supermatter_crystal(src)
	qdel(shard.countdown)
	shard.countdown = null
	START_PROCESSING(SSobj, src)
	visible_message(span_warning("[src] appears, balanced ever so perfectly on its hilt. This isn't ominous at all."))

/obj/item/melee/supermatter_sword/process()
	if(balanced || throwing || ismob(src.loc) || isnull(src.loc))
		return
	if(!isturf(src.loc))
		var/atom/target = src.loc
		forceMove(target.loc)
		consume_everything(target)
	else
		var/turf/T = get_turf(src)
		if(!isspaceturf(T))
			consume_turf(T)

/obj/item/melee/supermatter_sword/afterattack(target, mob/user, proximity_flag)
	. = ..()
	if(user && target == user)
		user.dropItemToGround(src)
	if(proximity_flag)
		consume_everything(target)

/obj/item/melee/supermatter_sword/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	..()
	if(ismob(hit_atom))
		var/mob/M = hit_atom
		if(src.loc == M)
			M.dropItemToGround(src)
	consume_everything(hit_atom)

/obj/item/melee/supermatter_sword/pickup(user)
	..()
	balanced = 0

/obj/item/melee/supermatter_sword/ex_act(severity, target)
	visible_message(span_danger("The blast wave smacks into [src] and rapidly flashes to ash."),\
	span_italics("You hear a loud crack as you are washed with a wave of heat."))
	consume_everything()

/obj/item/melee/supermatter_sword/acid_act()
	visible_message(span_danger("The acid smacks into [src] and rapidly flashes to ash."),\
	span_italics("You hear a loud crack as you are washed with a wave of heat."))
	consume_everything()

/obj/item/melee/supermatter_sword/bullet_act(obj/projectile/P)
	visible_message(span_danger("[P] smacks into [src] and rapidly flashes to ash."),\
	span_italics("You hear a loud crack as you are washed with a wave of heat."))
	consume_everything(P)
	return BULLET_ACT_HIT

/obj/item/melee/supermatter_sword/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] touches [src]'s blade. It looks like [user.p_theyre()] tired of waiting for the radiation to kill [user.p_them()]!"))
	user.dropItemToGround(src, TRUE)
	shard.Bumped(user)

/obj/item/melee/supermatter_sword/proc/consume_everything(target)
	if(isnull(target))
		shard.Consume()
	else if(!isturf(target))
		shard.Bumped(target)
	else
		consume_turf(target)

/obj/item/melee/supermatter_sword/proc/consume_turf(turf/T)
	var/oldtype = T.type
	var/turf/newT = T.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	if(newT.type == oldtype)
		return
	playsound(T, 'sound/effects/supermatter.ogg', 50, 1)
	T.visible_message(span_danger("[T] smacks into [src] and rapidly flashes to ash."),\
	span_italics("You hear a loud crack as you are washed with a wave of heat."))
	shard.Consume()

/obj/item/melee/supermatter_sword/add_blood_DNA(list/blood_dna)
	return FALSE

/obj/item/melee/singularity_sword
	name = "singularity sword"
	desc = "Spins so hard that it turns any struck foe into mincemeat instantaneously. Make sure not to stick around when you swing it at someone."
	icon = 'icons/obj/weapons/longsword.dmi'
	icon_state = "singularity_sword"
	item_state = "singularity_sword"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	slot_flags = null
	w_class = WEIGHT_CLASS_BULKY
	force = 0
	force_string = "INFINITE SPIN"
	resistance_flags = INDESTRUCTIBLE

/obj/item/melee/singularity_sword/afterattack(target, mob/user, proximity_flag)
	. = ..()
	if(proximity_flag)
		var/turf/T = get_turf(target)
		var/obj/singularity/gravitational/S = new(T)
		S.consume(target)
	else
		return FALSE

/obj/item/melee/singularity_sword/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/turf/T = get_turf(hit_atom)
	var/obj/singularity/gravitational/S = new(T)
	S.consume(hit_atom)

/// Simple whip that does additional damage(8 brute to be exact) to simple animals
/obj/item/melee/curator_whip
	name = "curator's whip"
	desc = "Somewhat eccentric and outdated, it still stings like hell to be hit by."
	icon = 'icons/obj/weapons/whip.dmi'
	icon_state = "whip"
	item_state = "chain"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	force = 12
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb = list("flogged", "whipped", "lashed", "disciplined")
	hitsound = 'sound/weapons/whip.ogg'

/obj/item/melee/curator_whip/afterattack(target, mob/user, proximity_flag)
	. = ..()
	if(isanimal(target) && proximity_flag)
		var/mob/living/simple_animal/A = target
		A.apply_damage(8, BRUTE)

/obj/item/melee/roastingstick
	name = "advanced roasting stick"
	desc = "A telescopic roasting stick with a miniature shield generator designed to ensure entry into various high-tech shielded cooking ovens and firepits."
	icon = 'icons/obj/weapons/baton.dmi'
	icon_state = "roastingstick_0"
	item_state = "null"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NONE
	force = 0
	attack_verb = list("hit", "poked")
	var/obj/item/reagent_containers/food/snacks/sausage/held_sausage
	var/static/list/ovens
	var/on = FALSE
	var/datum/beam/beam

/obj/item/melee/roastingstick/Initialize(mapload)
	. = ..()
	if (!ovens)
		ovens = typecacheof(list(/obj/singularity, /obj/machinery/power/supermatter_crystal, /obj/structure/bonfire, /obj/structure/destructible/clockwork/massive/ratvar, /obj/structure/destructible/clockwork/massive/celestial_gateway, /obj/mecha))

/obj/item/melee/roastingstick/attack_self(mob/user)
	on = !on
	if(on)
		extend(user)
	else
		if (held_sausage)
			to_chat(user, span_warning("You can't retract [src] while [held_sausage] is attached!"))
			return
		retract(user)

	playsound(src.loc, 'sound/weapons/batonextend.ogg', 50, 1)
	add_fingerprint(user)

/obj/item/melee/roastingstick/attackby(atom/target, mob/user)
	..()
	if (istype(target, /obj/item/reagent_containers/food/snacks/sausage))
		if (!on)
			to_chat(user, span_warning("You must extend [src] to attach anything to it!"))
			return
		if (held_sausage)
			to_chat(user, span_warning("[held_sausage] is already attached to [src]!"))
			return
		if (user.transferItemToLoc(target, src))
			held_sausage = target
		else
			to_chat(user, span_warning("[target] doesn't seem to want to get on [src]!"))
	update_appearance()

/obj/item/melee/roastingstick/attack_hand(mob/user)
	..()
	if (held_sausage)
		user.put_in_hands(held_sausage)
		held_sausage = null
	update_appearance()

/obj/item/melee/roastingstick/update_overlays()
	. = ..()
	if (held_sausage)
		var/mutable_appearance/sausage = mutable_appearance(icon, "roastingstick_sausage")
		. += sausage

/obj/item/melee/roastingstick/proc/extend(user)
	to_chat(user, "<span class ='warning'>You extend [src].</span>")
	icon_state = "roastingstick_1"
	item_state = "nullrod"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/melee/roastingstick/proc/retract(user)
	to_chat(user, "<span class ='notice'>You collapse [src].</span>")
	icon_state = "roastingstick_0"
	item_state = null
	w_class = WEIGHT_CLASS_SMALL

/obj/item/melee/roastingstick/handle_atom_del(atom/target)
	if (target == held_sausage)
		held_sausage = null
		update_appearance(UPDATE_ICON)

/obj/item/melee/roastingstick/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if (!on)
		return
	if (is_type_in_typecache(target, ovens))
		if (held_sausage && held_sausage.roasted)
			to_chat("Your [held_sausage] has already been cooked.")
			return
		if(ismecha(target))
			var/obj/mecha/overheating_mech = target
			if(overheating_mech.overheat < OVERHEAT_THRESHOLD)
				to_chat(user, span_warning("[overheating_mech] isn't hot enough!"))
				return
		if (istype(target, /obj/singularity) && get_dist(user, target) < 10)
			to_chat(user, "You send [held_sausage] towards [target].")
			playsound(src, 'sound/items/rped.ogg', 50, 1)
			beam = user.Beam(target, icon_state = "rped_upgrade", time = 10 SECONDS)
		else if (user.Adjacent(target))
			to_chat(user, "You extend [src] towards [target].")
			playsound(src.loc, 'sound/weapons/batonextend.ogg', 50, 1)
		else
			return
		if(do_after(user, 10 SECONDS, user))
			finish_roasting(user, target)
		else
			QDEL_NULL(beam)
			playsound(src, 'sound/weapons/batonextend.ogg', 50, 1)

/obj/item/melee/roastingstick/proc/finish_roasting(user, atom/target)
	to_chat(user, "You finish roasting [held_sausage]")
	playsound(src,'sound/items/welder2.ogg',50,1)
	held_sausage.add_atom_colour(rgb(103,63,24), FIXED_COLOUR_PRIORITY)
	held_sausage.name = "[target.name]-roasted [held_sausage.name]"
	held_sausage.desc = "[held_sausage.desc] It has been cooked to perfection on \a [target]."
	update_appearance(UPDATE_ICON)
