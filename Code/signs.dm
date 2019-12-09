/*
 * Copyright � 2018 RagnarokHGM (Creator/Developer) & Murrawhip (Developer)
 * Distributed under the GNU Affero General Public License, version 3.
 * Your changes must be made public.
 * For the full license text, see LICENSE.txt.
 */
obj
	Signs
		mouse_over_pointer = MOUSE_HAND_POINTER
		icon='statues.dmi'
		icon_state="sign"
		density=1

		verb
			read_sign()
				set src in oview(10)
				set name="Read"
				if(desc)
					usr << desc
				else
					usr << "<span style=\"color:red;\"><b>[name]</b></span>"

		Click()
			..()
			if(src in oview(10))
				read_sign()


		Diagon_Bank
			desc = "\n<span style=\"color:red;\"><b>Gringott's Wizard's Bank.</span><font color=blue><br>Main Branch - Diagon Alley.</b>"


		Museum
			desc = "<b>This is the Wizard Chronicles Museum."


		sign2
			icon_state = "sign3"