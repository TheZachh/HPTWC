/**
 * This is a basic demo of event scheduling. In our example, we have a
 * little map of trees, which change with the seasons. We also have a
 * powerful Shaman, who can stop and start time itself, at will.
 */
turf
	grass
		icon = 'demo/basic/grass.dmi'

obj
	tree
		icon = 'demo/basic/tree.dmi'
		icon_state = "summer"

mob
	shaman
		icon = 'demo/basic/shaman.dmi'

		verb
			Freeze_Time()

			Unfreeze_Time()

world
	mob = /mob/shaman

var/season = "summer"

/**
 * In order to use event scheduling, you first need an event scheduler:
 */
var/EventScheduler/global_scheduler = new()

/**
 * This needs to be started on world startup, preferably nice and early:
 */
world
	New()
		global_scheduler.start()
		..()

/**
 * And to be nice and symmetrical, lets stop it when the world is shutdown.
 * We should probably stop it before the rest of the world shutdown though,
 * so we're not trying to make stuff happen after we've all but finished.
 */
world
	Del()
		global_scheduler.stop()
		..()

/**
 * To make things happen, you need events. You define these yourself. Here's
 * an example that will change the trees from summer leaves, to autumn leaves,
 * an vice versa.
 *
 * The library provides a simple timer event, which we'll extend:
 */
SeasonChangeEvent
	parent_type = /Event/Timer

	/**
	 * fire() is where all of our magic happens. we'll change the seasons here.
	 */
	fire()
		..() // Make sure we allow the /Event/Timer fire() to do it's thing.
		var/next_season = season == "summer" ? "autumn" : "summer"
		for (var/obj/tree/T in world)
			T.icon_state = next_season
		season = next_season

/**
 * And that's it! Kinda ... we just need to schedule an actual event.
 * /Event/Timer takes in two arguments, the scheduler you want to re-schedule
 * on, and how frequently you want the event to happen:
 */
world
	New()
		..()
		var/SeasonChangeEvent/season_changer = new(global_scheduler, 30) // Lets make it change every 3 seconds.
		global_scheduler.schedule(season_changer, 30) // First fires in 3 seconds time.

/**
 * Now, onto our powerful shaman. He can freeze and unfreeze time,
 * which can stop the very seasons themselves changing! His spells
 * to do that are now very easy:
 */
mob
	shaman
		Freeze_Time()
			global_scheduler.stop()
			world << "Mwahaha, I have frozen time!"

		Unfreeze_Time()
			global_scheduler.start()
			world << "Consider me gracious, for I have allowed time to continue ..."