/*
 * Copyright � 2018 RagnarokHGM (Creator/Developer) & Murrawhip (Developer)
 * Distributed under the GNU Affero General Public License, version 3.
 * Your changes must be made public.
 * For the full license text, see LICENSE.txt.
 */
mob/GM
	verb
		Delete(S as turf|obj|mob in view(17))
			set category = "Staff"
			if(isplayer(S))
				switch(alert("Deleting Player: [S]","Are you sure you want to delete [S]?","Yes","No"))
					if("No")
						return
			del S

obj/Shield
	icon='teleport2.dmi'
	icon_state = "shield"
	layer = 5
	density = 1

mob/Player/var/tmp
	prevname
	shieldamount