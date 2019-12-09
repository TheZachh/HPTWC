/**
 * The event scheduler is used as an event loop, that you place events onto.
 * Events fire at their designated time, in the order they were scheduled. The
 * implementation of the scheduler is actually a little bit naive currently,
 * in that it doesn't use a time ordered heap. However it can comfortably handle
 * about 1 million scheduled events with no significant cost to performance.
 */
EventScheduler
	proc
		/**
		 * Cancels an event, if it's scheduled.
		 *
		 * @param E The event to cancel.
		 */
		cancel(var/Event/E)
			var/__Trigger/T = src.__trigger_mapping[E]
			if (T)
				src.__trigger_mapping.Remove(E)
				var/time = T.__scheduled_iterations > 0 ? 16777216 : T.__scheduled_time - src.__tick
				if (time > 0)
					var/list/A = src.__scheduled_events[num2text(time, 8)]
					if (A)
						A -= T


		/**
		 * Re-schedules an event on the scheduler, to fire in @{ticks} time. The
		 * scheduler operates on world.tick_lag intervals, so one tick is 1/10th
		 * of a second by default. If the event is currently scheduled, it is
		 * cancelled and re-scheduled.
		 *
		 * @param E 		The event to re-schedule.
		 * @param ticks 	The number of ticks in the future to schedule this for.
		 * @param priority	Optional argument, the priority of the event. By default,
		 *					the previously set priority is maintained.
		 */
		reschedule(var/Event/E, var/ticks as num, var/priority = -1)
			var/__Trigger/T = src.__trigger_mapping[E]
			if (T && priority < 0)
				priority = T.__priority
			cancel(E)
			schedule(E, ticks, priority)

		/**
		 * Schedules an event on the scheduler, to fire in @{ticks} time. The
		 * scheduler operates on world.tick_lag intervals, so one tick is 1/10th
		 * of a second by default.
		 *
		 * @param E 		The event to schedule.
		 * @param ticks 	The number of ticks in the future to schedule this for.
		 * @param priority	Optional argument, the priority of the event. Higher
		 *					numerical values mean a higher priority. Defaults to 0.
		 */
		schedule(var/Event/E, var/ticks as num, var/priority = 0)
			var/__Trigger/T = new(E, src.__tick, ticks, 0)
			if (T.__scheduled_iterations > 0)
				ticks = num2text(16777216, 8)
			else
				ticks = num2text(ticks, 8)
			var/list/A = src.__scheduled_events[ticks]
			if (A)
				A += T
			else
				src.__scheduled_events[ticks] = list(T)
			src.__trigger_mapping[E] = T

		/**
		 * Determines is the provided event is currently scheduled or not on this
		 * event scheduler.
		 *
		 * @param E The event to check is scheduled.
		 * @return TRUE if it is scheduled, FALSE if it is not scheduled.
		 */
		is_scheduled(var/Event/E)
			return !isnull(src.__trigger_mapping[E])

		/**
		 * Gets the number of ticks until the provided event fires.
		 *
		 * @param E The event to check the time to fire for.
		 * @return The number of ticks until it fires, or -1 if the event is not scheduled.
		 */
		time_to_fire(var/Event/E)
			var/__Trigger/T = src.__trigger_mapping[E]
			if (T)
				return ((T.__scheduled_iterations * 16777216) + T.__scheduled_time) - src.__tick
			return -1

		/**
		 * Sets the delay, in 1/10th seconds, that this scheduler will sleep for, between ticks.
		 * A delay of 0 will mean the scheduler sleeps for just long enough to allow other work to continue.
		 * With a delay of 0, you can get several ticks processing in one DM tick.
		 *
		 * @param delay The delay, in 1/10th seconds, that this scheduler will sleep for, between ticks.
		 */
		set_sleep_delay(var/delay as num)
			src.__sleep_delay = delay

		/**
		 * Starts the event loop. You can use this with stop() to be selective about
		 * when the event loop runs, or to turn off all scheduled events when you are
		 * shutting down or performing a sensitive operation.
		 */
		start()
			if (!src.__running)
				src.__running = 1
				spawn() src.__loop()

		/**
		 * Stops the event scheduler. You can use this with start() to be selective about
		 * when the event loop runs, or to turn off all scheduled events when you are
		 * shutting down or performing a sensitive operation.
		 */
		stop()
			src.__running = 0


	var
		__running 				= 0
		list/__trigger_mapping	= new()
		list/__scheduled_events = new()
		__tick					= 0
		__sleep_delay			= 1

	proc
		__shift_down_events()
			var/list/result = null
			for (var/T in src.__scheduled_events)
				var/A = src.__scheduled_events[T]
				src.__scheduled_events.Remove(T)
				var/index = text2num(T)
				if (--index)
					src.__scheduled_events[num2text(index, 8)] = A
				else
					for (var/__Trigger/Tr in A)
						if (Tr.__scheduled_iterations > 0)
							Tr.__scheduled_iterations--
							var/new_index = Tr.__scheduled_iterations ? 16777216 : Tr.__scheduled_time
							var/list/S = src.__scheduled_events[text2num(new_index)]
							if (S)
								S += Tr
							else
								src.__scheduled_events[text2num(new_index)] = list(Tr)
						else
							if (result)
								result += Tr
							else
								result = list(Tr)

					result = A
			return result

		__iteration()
			src.__tick++
			var/list/execute = src.__shift_down_events()
			if (execute)
				QuickSort(execute, /EventScheduler/proc/__sort_priorities)
				for (var/__Trigger/T in execute)
					T.__event.fire()
					src.__trigger_mapping.Remove(T.__event)
			if (src.__tick == 16777216)
				src.__tick = 0

		__loop()
			while (src.__running)
				sleep(src.__sleep_delay)
				src.__iteration()

		__sort_priorities(var/__Trigger/T1, var/__Trigger/T2)
			return T2.__priority - T1.__priority

__Trigger
	var
		Event/__event			= null
		__priority				= 0
		__scheduled_time		= 0
		__scheduled_iterations 	= 0

	New(var/Event/E, var/insert_time as num, var/ticks as num, var/priority = 0)
		src.__event			 		= E
		src.__scheduled_time 		= insert_time + ticks
		src.__priority		 		= priority
		var/scheduled_time 			= insert_time + ticks
		src.__scheduled_iterations	= round(scheduled_time / 16777216)
		// May not be entirely accurate, we lost accuracy when the user input a big number.
		src.__scheduled_time		= round(scheduled_time % 16777216, 1)
