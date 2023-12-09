/datum/computer_file/program/radar //generic parent that handles most of the process
	filename = "genericfinder"
	filedesc = "debug_finder"
	category = PROGRAM_CATEGORY_CREW
	ui_header = "borg_mon.gif" //DEBUG -- new icon before PR
<<<<<<< HEAD
	program_icon_state = "radarntos"
	requires_ntnet = TRUE
	available_on_ntnet = FALSE
	usage_flags = PROGRAM_LAPTOP | PROGRAM_TABLET
=======
	program_open_overlay = "radarntos"
	program_flags = PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_LAPTOP | PROGRAM_PDA
>>>>>>> edbc7c56226 (PDA update (Messenger works while dead, Microwave works, etc). (#80069))
	size = 5
	tgui_id = "NtosRadar"
	///List of trackable entities. Updated by the scan() proc.
	var/list/list/objects
	///Ref of the last trackable object selected by the user in the tgui window. Updated in the ui_act() proc.
	var/selected
	///Used to store when the next scan is available.
	COOLDOWN_DECLARE(next_scan)
	///Used to keep track of the last value program_icon_state was set to, to prevent constant unnecessary update_appearance() calls
	var/last_icon_state = ""
	///Used by the tgui interface, themed NT or Syndicate.
	var/arrowstyle = "ntosradarpointer.png"
	///Used by the tgui interface, themed for NT or Syndicate colors.
	var/pointercolor = "green"

/datum/computer_file/program/radar/on_start(mob/living/user)
	. = ..()
	if(!.)
		return
	if(COOLDOWN_FINISHED(src, next_scan))
		// start with a scan without a cooldown, but don't scan if we *are* on cooldown already.
		scan()
	START_PROCESSING(SSfastprocess, src)

/datum/computer_file/program/radar/kill_program(mob/user)
	objects = list()
	selected = null
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/datum/computer_file/program/radar/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/datum/computer_file/program/radar/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/radar_assets),
	)

/datum/computer_file/program/radar/ui_data(mob/user)
	var/list/data = list()
	data["selected"] = selected
	data["scanning"] = !COOLDOWN_FINISHED(src, next_scan)
	data["object"] = objects

	data["target"] = list()
	var/list/trackinfo = track()
	if(trackinfo)
		data["target"] = trackinfo
	return data

/datum/computer_file/program/radar/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)

	switch(action)
		if("selecttarget")
			var/selected_new_ref = params["ref"]
			if(selected_new_ref in trackable_object_refs())
				selected = selected_new_ref
			return TRUE

		if("scan")
			if(!COOLDOWN_FINISHED(src, next_scan))
				return TRUE // update anyways

			COOLDOWN_START(src, next_scan, 2 SECONDS)
			scan()
			return TRUE

/// Returns all ref()s that are being tracked currently
/datum/computer_file/program/radar/proc/trackable_object_refs()
	var/list/all_refs = list()
	for(var/list/object_list as anything in objects)
		all_refs += object_list["ref"]
	return all_refs

/**
 *Updates tracking information of the selected target.
 *
 *The track() proc updates the entire set of information about the location
 *of the target, including whether the Ntos window should use a pinpointer
 *crosshair over the up/down arrows, or none in favor of a rotating arrow
 *for far away targets. This information is returned in the form of a list.
 *
*/
/datum/computer_file/program/radar/proc/track()
	var/atom/movable/signal = find_atom()
	if(!trackable(signal))
		return

	var/turf/here_turf = (get_turf(computer))
	var/turf/target_turf = (get_turf(signal))
	var/userot = FALSE
	var/rot = 0
	var/pointer="crosshairs"
	var/locx = (target_turf.x - here_turf.x) + 24
	var/locy = (here_turf.y - target_turf.y) + 24

	if(get_dist_euclidian(here_turf, target_turf) > 24)
		userot = TRUE
		rot = round(get_angle(here_turf, target_turf))
	else
		if(target_turf.z > here_turf.z)
			pointer="caret-up"
		else if(target_turf.z < here_turf.z)
			pointer="caret-down"

	var/list/trackinfo = list(
		"locx" = locx,
		"locy" = locy,
		"userot" = userot,
		"rot" = rot,
		"arrowstyle" = arrowstyle,
		"color" = pointercolor,
		"pointer" = pointer,
		)
	return trackinfo

/**
 *
 *Checks the trackability of the selected target.
 *
 *If the target is on the computer's Z level, or both are on station Z
 *levels, and the target isn't untrackable, return TRUE.
 *Arguments:
 **arg1 is the atom being evaluated.
*/
/datum/computer_file/program/radar/proc/trackable(atom/movable/signal)
	if(!signal || !computer)
		return FALSE
	var/turf/here = get_turf(computer)
	var/turf/there = get_turf(signal)
	if(!here || !there)
		return FALSE //I was still getting a runtime even after the above check while scanning, so fuck it
	return (there.z == here.z) || (is_station_level(here.z) && is_station_level(there.z))

/**
 *
 *Runs a scan of all the trackable atoms.
 *
 *Checks each entry in the GLOB of the specific trackable atoms against
 *the track() proc, and fill the objects list with lists containing the
 *atoms' names and REFs. The objects list is handed to the tgui screen
 *for displaying to, and being selected by, the user. A two second
 *sleep is used to delay the scan, both for thematical reasons as well
 *as to limit the load players may place on the server using these
 *somewhat costly loops.
*/
/datum/computer_file/program/radar/proc/scan()
	return

/**
 *
 *Finds the atom in the appropriate list that the `selected` var indicates
 *
 *The `selected` var holds a REF, which is a string. A mob REF may be
 *something like "mob_209". In order to find the actual atom, we need
 *to search the appropriate list for the REF string. This is dependant
 *on the program (Lifeline uses GLOB.human_list, while Fission360 uses
 *GLOB.poi_list), but the result will be the same; evaluate the string and
 *return an atom reference.
*/
/datum/computer_file/program/radar/proc/find_atom()
	return

//We use SSfastprocess for the program icon state because it runs faster than process_tick() does.
/datum/computer_file/program/radar/process()
	if(computer.active_program != src)
		STOP_PROCESSING(SSfastprocess, src) //We're not the active program, it's time to stop.
		return
	if(!selected)
		return

	var/atom/movable/signal = find_atom()
	if(!trackable(signal))
		program_icon_state = "[initial(program_icon_state)]lost"
		if(last_icon_state != program_icon_state)
			computer.update_appearance()
			last_icon_state = program_icon_state
		return

	var/here_turf = get_turf(computer)
	var/target_turf = get_turf(signal)
	var/trackdistance = get_dist_euclidian(here_turf, target_turf)
	switch(trackdistance)
		if(0)
			program_icon_state = "[initial(program_icon_state)]direct"
		if(1 to 12)
			program_icon_state = "[initial(program_icon_state)]close"
		if(13 to 24)
			program_icon_state = "[initial(program_icon_state)]medium"
		if(25 to INFINITY)
			program_icon_state = "[initial(program_icon_state)]far"

	if(last_icon_state != program_icon_state)
		computer.update_appearance()
		last_icon_state = program_icon_state
	computer.setDir(get_dir(here_turf, target_turf))

//We can use process_tick to restart fast processing, since the computer will be running this constantly either way.
/datum/computer_file/program/radar/process_tick(seconds_per_tick)
	if(computer.active_program == src)
		START_PROCESSING(SSfastprocess, src)

///////////////////
//Suit Sensor App//
///////////////////

///A program that tracks crew members via suit sensors
/datum/computer_file/program/radar/lifeline
	filename = "lifeline"
	filedesc = "Lifeline"
	extended_desc = "This program allows for tracking of crew members via their suit sensors."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	download_access = list(ACCESS_MEDICAL)
	program_icon = "heartbeat"

/datum/computer_file/program/radar/lifeline/find_atom()
	return locate(selected) in GLOB.human_list

/datum/computer_file/program/radar/lifeline/scan()
	objects = list()
	for(var/i in GLOB.human_list)
		var/mob/living/carbon/human/humanoid = i
		if(!trackable(humanoid))
			continue
		var/crewmember_name = "Unknown"
		if(humanoid.wear_id)
			var/obj/item/card/id/ID = humanoid.wear_id.GetID()
			if(ID?.registered_name)
				crewmember_name = ID.registered_name
		var/list/crewinfo = list(
			ref = REF(humanoid),
			name = crewmember_name,
			)
		objects += list(crewinfo)

/datum/computer_file/program/radar/lifeline/trackable(mob/living/carbon/human/humanoid)
	if(!humanoid || !istype(humanoid))
		return FALSE
	if(..())
		if (istype(humanoid.w_uniform, /obj/item/clothing/under))
			var/obj/item/clothing/under/uniform = humanoid.w_uniform
			if(uniform.has_sensor && uniform.sensor_mode >= SENSOR_COORDS) // Suit sensors must be on maximum
				return TRUE
	return FALSE

///Tracks all janitor equipment
/datum/computer_file/program/radar/custodial_locator
	filename = "custodiallocator"
	filedesc = "Custodial Locator"
	extended_desc = "This program allows for tracking of custodial equipment."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	download_access = list(ACCESS_JANITOR)
	program_icon = "broom"
	size = 2
	detomatix_resistance = DETOMATIX_RESIST_MINOR

/datum/computer_file/program/radar/custodial_locator/find_atom()
	return locate(selected) in GLOB.janitor_devices

/datum/computer_file/program/radar/custodial_locator/scan()
	objects = list()
	for(var/obj/custodial_tools as anything in GLOB.janitor_devices)
		if(!trackable(custodial_tools))
			continue
		var/tool_name = custodial_tools.name

		if(istype(custodial_tools, /obj/item/mop))
			var/obj/item/mop/wet_mop = custodial_tools
			tool_name = "[wet_mop.reagents.total_volume ? "Wet" : "Dry"] [wet_mop.name]"

		if(istype(custodial_tools, /obj/structure/mop_bucket/janitorialcart))
			var/obj/structure/mop_bucket/janitorialcart/janicart = custodial_tools
			tool_name = "[janicart.name] - Water level: [janicart.reagents.total_volume] / [janicart.reagents.maximum_volume]"

		if(istype(custodial_tools, /mob/living/basic/bot/cleanbot))
			var/mob/living/basic/bot/cleanbot/cleanbots = custodial_tools
			tool_name = "[cleanbots.name] - [cleanbots.bot_mode_flags & BOT_MODE_ON ? "Online" : "Offline"]"

		var/list/tool_information = list(
			ref = REF(custodial_tools),
			name = tool_name,
		)
		objects += list(tool_information)

////////////////////////
//Nuke Disk Finder App//
////////////////////////

///A program that tracks nukes and nuclear accessories
/datum/computer_file/program/radar/fission360
	filename = "fission360"
	filedesc = "Fission360"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "radarsyndicate"
	extended_desc = "This program allows for tracking of nuclear authorization disks and warheads."
	program_flags = PROGRAM_ON_SYNDINET_STORE
	tgui_id = "NtosRadarSyndicate"
	program_icon = "bomb"
	arrowstyle = "ntosradarpointerS.png"
	pointercolor = "red"

/datum/computer_file/program/radar/fission360/on_start(mob/living/user)
	. = ..()
	if(!.)
		return

	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_DEVICE_ARMED, PROC_REF(on_nuke_armed))

/datum/computer_file/program/radar/fission360/kill_program(mob/user)
	UnregisterSignal(SSdcs, COMSIG_GLOB_NUKE_DEVICE_ARMED)
	return ..()

/datum/computer_file/program/radar/fission360/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_NUKE_DEVICE_ARMED)
	return ..()

/datum/computer_file/program/radar/fission360/find_atom()
	return SSpoints_of_interest.get_poi_atom_by_ref(selected)

/datum/computer_file/program/radar/fission360/scan()
	objects = list()

	// All the nukes
	for(var/obj/machinery/nuclearbomb/nuke as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/nuclearbomb))
		var/list/nuke_info = list(
			ref = REF(nuke),
			name = nuke.name,
			)
		objects += list(nuke_info)

	// Dat fukken disk
	var/obj/item/disk/nuclear/disk = locate() in SSpoints_of_interest.real_nuclear_disks
	var/list/disk_info = list(
		ref = REF(disk),
		name = "Nuke Auth. Disk",
		)
	objects += list(disk_info)

	// The infiltrator
	var/obj/docking_port/mobile/infiltrator = SSshuttle.getShuttle("syndicate")
	var/list/ship_info = list(
		ref = REF(infiltrator),
		name = "Infiltrator",
		)
	objects += list(ship_info)

///Shows how long until the nuke detonates, if one is active.
/datum/computer_file/program/radar/fission360/on_examine(obj/item/modular_computer/source, mob/user)
	var/list/examine_list = list()

	for(var/obj/machinery/nuclearbomb/bomb as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/nuclearbomb))
		if(bomb.timing)
			examine_list += span_danger("Extreme danger. Arming signal detected. Time remaining: [bomb.get_time_left()].")
	return examine_list

/*
 * Signal proc for [COMSIG_GLOB_NUKE_DEVICE_ARMED].
 * Warns anyone nearby or holding the computer that a nuke was armed.
 */
/datum/computer_file/program/radar/fission360/proc/on_nuke_armed(datum/source, obj/machinery/nuclearbomb/bomb)
	SIGNAL_HANDLER

	if(!computer)
		return

	playsound(computer, 'sound/items/nuke_toy_lowpower.ogg', 50, FALSE)
	if(isliving(computer.loc))
		to_chat(computer.loc, span_userdanger("Your [computer.name] vibrates and lets out an ominous alarm. Uh oh."))
	else
		computer.audible_message(
			span_danger("[computer] vibrates and lets out an ominous alarm. Uh oh."),
			span_notice("[computer] begins to vibrate rapidly. Wonder what that means..."),
		)
