turf
	var/pathweight = 1
	ground
		icon = 'ground.dmi'
	sand
		pathweight = 4
		icon = 'sand.dmi'
	wall
		icon = 'wall.dmi'
		density = 1
	proc
		AdjacentTurfs()
			var/L[] = new()
			for(var/turf/t in oview(src,1))
				if(!t.density)
					L.Add(t)
			return L
		Distance(turf/t)
			if(get_dist(src,t) == 1)
				var/cost = (src.x - t.x) * (src.x - t.x) + (src.y - t.y) * (src.y - t.y)
				//Multiply the cost by the average of the pathweights of the
				//tile being entered and tile being left
				cost *= (pathweight+t.pathweight)/2
				return cost
			else
				return get_dist(src,t)

obj
	dest
		icon = 'dest.dmi'
mob
	icon = 'mob.dmi'
	verb
		astartest()
			Clear()
			var/turf/dest = locate(/obj/dest)
			dest = dest.loc
			var/path[] = AStar(loc,dest,/turf/proc/AdjacentTurfs,/turf/proc/Distance)
			for(var/turf/t in path)
				t.icon = 'blue.dmi'
		dijkstratest()
			Clear()
			var/path[] = Dijkstra(loc,/turf/proc/AdjacentTurfs,/turf/proc/Distance,/proc/Finished)
			for(var/turf/t in path)
				t.icon = 'blue.dmi'

		dijkstratestall()
			Clear()
			var/paths[] = Dijkstra(loc,/turf/proc/AdjacentTurfs,/turf/proc/Distance,/proc/FinishedAll, , 0)
			for(var/list/path in paths)
				for(var/turf/t in path)
					t.icon = 'blue.dmi'

		dijkstratestrange()
			Clear()
			var/path[] = DijkstraTurfInRange(loc,/turf/proc/AdjacentTurfs,/turf/proc/Distance,/proc/RangeFinished, P_INCLUDE_INTERIOR)
			for(var/turf/t in path)
				t.icon = 'blue.dmi'

		clear()
			Clear()


world
	turf = /turf/ground

proc
	Clear()
		for(var/turf/t as turf in world.contents)
			t.icon = initial(t.icon)

	//Done after running into the first destination object
	Finished(turf/t)
		return (locate(/obj/dest) in t) ? P_DIJKSTRA_FINISHED : P_DIJKSTRA_NOT_FOUND

	//Done after moving 5 units of range
	RangeFinished(turf/t,range)
		return range > 5

	//Find paths to all the destination objects
	FinishedAll(turf/t)
		return (locate(/obj/dest) in t) ? P_DIJKSTRA_ADD_PATH : P_DIJKSTRA_NOT_FOUND