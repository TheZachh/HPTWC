/*
 * Copyright � 2018 RagnarokHGM (Creator/Developer) & Murrawhip (Developer)
 * Distributed under the GNU Affero General Public License, version 3.
 * Your changes must be made public.
 * For the full license text, see LICENSE.txt.
 */


WorldData/var/tmp/spellObjects = list()

mob/Player
	var/tmp
		spellBookOpen = FALSE
		list/spells
	verb
		spellBookClosed()
			set name= ".spellBookClosed"
			spellBookOpen = 0
			toggle_actionbar(0)

	proc

		saveSpells()
			if(!UsedKeys) return

			var/list/copied = UsedKeys.Copy()
			for(var/k in copied)
				if(istype(copied[k], /obj/spells))
					var/obj/spells/s = copied[k]

					if((s.path in verbs) || !s.path)
						copied[k] = s.name
					else
						copied -= k

			return copied

		loadSpells()
			if(!UsedKeys || !spells) return

			for(var/k in UsedKeys)
				var/o = UsedKeys[k]
				if(istext(o))
					UsedKeys[k] = spells[o]

		updateSpellbook()

			var/list/verbList = list("Meditate", "Take")

			if(!spells) spells = list()
			var/count = spells.len

			for(var/v in verbList)
				if(v in spells) continue
				count++

				var/obj/spells/o = worldData.spellObjects[v]
				if(!o)
					o = new (null, v, null)
					worldData.spellObjects[v] = o

				spells[v] = o

				src << output(o, "SpellBook.gridSpellbook:[count]")



			for(var/v in verbs)
				var/mob/Spells/verb/generic = v
				if(generic.name in spells)               continue
				if(!findtext("[v]", "/mob/Spells/verb")) continue
				count++

				var/obj/spells/o = worldData.spellObjects[generic.name]
				if(!o)
					o = new (null, generic.name, text2path("[v]"))
					worldData.spellObjects[generic.name] = o
				spells[generic.name] = o

				src << output(o, "SpellBook.gridSpellbook:[count]")

obj/spells
	icon = 'SpellbookIcons.dmi'

	var/path

	New(Loc, name, path)
		..()

		src.name   = name
		src.path   = path
		icon_state = name

		mouse_drag_pointer = src


	Click()
		var/mob/m = usr
		if(path && !(path in m.verbs))
			if(m:spells && (src in m:spells))
				m:spells -= src
				return
			if(m:UsedKeys)
				for(var/k in m:UsedKeys)
					var/obj/o = m:UsedKeys[k]
					if(o == src)
						m:removeKey(k)
						break
		switch(name)
			if("Glacius")
				m:Glacius()
			if("Inflamari")
				m:Inflamari()
			if("Waddiwasi")
				m:Waddiwasi()
			if("Flippendo")
				m:Flippendo()
			if("Incindia")
				m:Incindia()
			if("Incendio")
				m:Incendio()
			if("Tremorio")
				m:Tremorio()
			if("Aqua Eructo")
				m:Aqua_Eructo()
			if("Chaotica")
				m:Chaotica()
			if("Meditate")
				m.Meditate()
			if("Episkey")
				m:Episky()
			if("Sanguinis Iactus")
				m:Sanguinis_Iactus()

	MouseDrop(over_object,src_location,over_location,src_control,over_control,params)
		..()
		if(istype(over_object, /hudobj/actionbar/keys))
			var/hudobj/actionbar/keys/k = over_object
			k.SetKey(src)
