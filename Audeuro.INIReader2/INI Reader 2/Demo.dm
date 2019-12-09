
	// This is possible
mob/verb/Dump()
	var/INI/Ini = new
	if(!Ini.Read("demo.ini"))
		world << Ini.error
	else
		Ini.DumpSections()

	// Or this is possible.
mob/verb/Function()
	var/INI/ini = new("demo.ini")
		// This is how you access data:
	var/Configuration/cfg = ini.GetSection("general")
	world << cfg.Value("test")
	world << cfg.Value("LOL")
	var/Configuration/nongen = ini.GetSection("nongeneral")
	var/str = nongen.Value("lol")
	world << str
	ini.Write("demo_out.ini")
	world << "Written to demo_out.ini"

	// Benchmark
mob/verb/Benchmark()
	for(var/i = 0; i < 1000; ++i)
		var/INI/Ini = new("demo.ini")
		sleep(1)
	world << "Done"