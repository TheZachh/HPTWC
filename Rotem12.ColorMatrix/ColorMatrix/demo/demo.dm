#define DEBUG

world
	fps = 30

turf
	grass
		icon       = '1.dmi'
		icon_state = "grass"



mob
	icon       = '1.dmi'
	icon_state = "person"

	verb
		Pick_Color(newColor as color)

			var/ColorMatrix/c = new(newColor)

			animate(client, color = c.matrix, time = 10)

		Pick_ColorSatContBright(s as num, c as num, b as num)

			var/ColorMatrix/cm = new(s, c, b)

			animate(client, color = cm.matrix, time = 10)

		Pick_ColorPreset(newColor in list("Invert", "BGR", "Greyscale", "Sepia", "Black & White", "Polaroid", "GRB", "RBG", "BRG", "GBR", "Normal"))

			if(newColor == "Normal")
				animate(client, color = null, time = 10)

			else
				var/ColorMatrix/c = new(newColor)
				animate(client, color = c.matrix, time = 10)