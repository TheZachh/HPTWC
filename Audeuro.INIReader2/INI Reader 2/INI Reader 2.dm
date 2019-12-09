/**
	INI Reader 2 Documentation
		USAGE:
			Create a new /INI Datum with the file to read as the parameter to /INI/New()
			OR Create a new /INI Datum with no parameters to New() and call Read(filename) manually.

			Writing does not currently work, and so far it only has strings and numbers.

			To retrieve a section, use /INI/GetSection(section). /INI/GetSection(section) returns
			the /Configuration datum associated with the section. From there, you can use /Configuration/Value(key) to retrieve
			the number/string value associated with the given key. /Configuration/Value(key) returns null if the key is invalid
			or not present in the settings list.
*/
Configuration
	var
		title = ""
		list/settings = null
	New(name)
		title = name
	proc
		_Settings()
			return settings
		Value(key)
			if(!istext(key) || !length(key) || !settings || !(key in settings)) return null
			return settings[key]
		Set(key, val, not_num = 0)
			if(!istext(key) || !length(key)) return 0
			if(!settings) settings = new
			if(!not_num)
				settings[key] = text2num(val)
			else
				settings[key] = val
			return 1
		Unset(key)
			if(!istext(key) || !length(key) || !settings || !(key in settings)) return 0
			settings -= key
			if(!settings.len) settings = null
			return 1
		Name()
			return title
		Dump()
			world << "Configuration name: [title]"
			if(settings)
				world << "=== DATA ==="
				for(var/i in settings)
					if(!istype(settings[i], /list))
						world << "`[i]`: '[settings[i]]'"
					else
						world << "`[i]`: [_ListDump(settings[i])]"
				world << "=== END DATA ==="
			else
				world << "=== NO DATA AVAILABLE ==="
		_ListDump(list/L)
			if(!istype(L)) return 0
			. = "list("
			var/ind = 0
			for(var/i in L)
				if(ind++) . += ","
				if(isnum(i))
					. += "[i]"
				else if(istype(i, /list))
					. += _ListDump(i)
				else
					. += "\"[i]\""
			. += ")"

INI
	var
		file = ""
		error = 0
		const
			STATE_HEADER = 1
			STATE_DATA = 2
			STATE_VALUE = 4
			STATE_STRING = 8
			STATE_LIST = 16

			CHAR_SCOLON = 0x3B		// ;
			CHAR_FSLASH = 0x2F		// /
			CHAR_LBRACK = 0x5B		// [
			CHAR_RBRACK = 0x5D		// ]
			CHAR_ASTERI = 0x2A		// *
			CHAR_UNDERS = 0x5F		// _
			CHAR_EQUALS = 0x3D		// =
			CHAR_QUOTES = 0x22		// "
			CHAR_PLUS	= 0x2B		// +
			CHAR_MINUS	= 0x2D		// -
			CHAR_LARGEE = 0x45		// E
			CHAR_SMALLE = 0x65		// e
			CHAR_PERIOD = 0x2E		// .
			CHAR_COMMA	= 0x2C		// ,
			CHAR_LESSTH = 0x3C		// <
			CHAR_GREATH = 0x3E		// >

			COMMENT_MONOL = 1
			COMMENT_MULTL = 2
		list/sections = null
	proc
		DumpSections()
			if(!sections)
				world << "No sections found."
				return
			for(var/Configuration/cfg in sections)
				cfg.Dump()
				world << ""

		GetSection(name)
			if(istext(name) && length(name) && sections)
				for(var/Configuration/cfg in sections)
					if(cfg.Name() == name) return cfg
			return null
		_AddSection(section)
			if(!istext(section) || !length(section)) return 0
			var/Configuration/cfg = new(section)
			if(!sections) sections = new
			sections += cfg
			return cfg
		_IsSpace(dec)
			return (dec == 0x20 || dec == 0x09)
		_SkipSpace(context, pos)
			var/char = text2ascii(context, pos)
			while(_IsSpace(char))
				pos ++
				char = text2ascii(context, pos)
			return pos
		_IsWhitespace(dec)
			return (_IsSpace(dec)|| _IsBreak(dec))
		_SkipWhitespace(context, pos)
			var/char = text2ascii(context, pos)
			while(_IsWhitespace(char))
				pos ++
				char = text2ascii(context, pos)
			return pos
		_IsBreak(dec)
			return (dec == 0x0A || dec == 0x0D)
		_IsAlpha(dec)
						//	a-z and A-Z
			return ((dec >= 0x41 && dec <= 0x5A) || (dec >= 0x61 && dec <= 0x7A))
		_IsExpChar(dec)
			return (dec == CHAR_SMALLE || dec == CHAR_LARGEE)
		_IsSign(dec)
			return (dec == CHAR_PLUS || dec == CHAR_MINUS)
		_IsScientific(context)
			return (findtext(context, ascii2text(CHAR_SMALLE)) || findtext(context, ascii2text(CHAR_LARGEE)))
		_IsValidNumeric(context, ch)
			if(_IsNumber(ch)) return 1
			if(_IsSign(ch) && (!length(context) || _IsExpChar(text2ascii(context, length(context))))) return 1
			var/scientific = _IsScientific(context)
			if(_IsExpChar(ch) && !scientific)
				if(length(context) > 1 || (length(context) == 1 && !_IsSign(text2ascii(context, 1)))) return 1
			if(ch == CHAR_PERIOD && length(context) && !scientific) return 1
			return 0
		_IsNumber(dec)
			return (dec >= 0x30 && dec <= 0x39)
		_IsIdentifierChar(dec, pos)
			return (_IsAlpha(dec) || (pos == 1 && dec == CHAR_UNDERS) || (pos != 1 && _IsNumber(dec)))
		_IsCommentStart(context, pos)
			var/size = length(context)
			var/ch = text2ascii(context, pos)
			if(ch == CHAR_SCOLON)
				return COMMENT_MONOL
			else if(ch == CHAR_FSLASH && (size - pos) >= 1)
				var/next = text2ascii(context, pos + 1)
				if(next == CHAR_FSLASH) return COMMENT_MONOL
				else if(next == CHAR_ASTERI) return COMMENT_MULTL
			return 0
		_IsInvalidArea(context, pos)
			var/ch = text2ascii(context, pos)
			return  (_IsWhitespace(ch) || _IsCommentStart(context, pos))
		_SkipToValidity(context, pos)
			var/size = length(context)
			while(pos <= size && _IsInvalidArea(context, pos))
				var/ch = text2ascii(context, pos)
				if(_IsWhitespace(ch)) pos = _SkipWhitespace(context, pos)
				else pos = _SkipComment(context, pos)
			return pos
		_CopyString(context, pos)
			if(text2ascii(context, pos) != CHAR_QUOTES) return 0
			var/endQuotes = findtext(context, ascii2text(CHAR_QUOTES), pos + 1)
			if(!endQuotes) return 0
			return copytext(context, pos + 1, endQuotes)

		_SkipComment(context, pos)
			var/size = length(context)
			var/type = _IsCommentStart(context, pos)
			if(type == COMMENT_MONOL)
				var/i = pos + 1
				var/ch = text2ascii(context, i)
				while(!_IsBreak(ch) && i <= size)
					i++
					ch = text2ascii(context, i)
				if(i <= size)
					i = _SkipWhitespace(context, i)
				return i
			else if(type == COMMENT_MULTL)
				var/end = findtext(context, "*/", pos + 1)
				if(!end)
					return size
				else
					var/i = end + 2
					while(i <= size && _IsBreak(text2ascii(context, i)))
						i++
					return i
			return pos
		_OutputList(list/L)
			if(!istype(L)) return 0
			. = "<"
			var/ind = 0
			for(var/i in L)
				if(ind++) . += ","
				if(isnum(i))
					. += "[i]"
				else if(istype(i, /list))
					. += _OutputList(i)
				else
					. += "\"[i]\""
			. += ">"
		_ParseList(context, list/lPos)
			var/size = length(context)
			var/char = 0
			var/list/ret = list()
			var/val = ""
			var/numVal = 0
			var/i = 0
			for(i = lPos[1]; i <= size; ++i)
				char = text2ascii(context, i)
				if(char == CHAR_COMMA)
					ret[++ret.len] = (numVal ? text2num(val) : val)
					numVal = 0
					val = ""
				else if(_IsSpace(char))
					if(!val)
						continue
					else
						// This is only acceptable if the next non-space character is a comma.
						while(i <= size && _IsSpace(char))
							char = text2ascii(context, ++i)
						if(char != CHAR_COMMA)
							error = "Malformed INI: Invalid spacing in list data."
							return 0
						i--
				else if(char == CHAR_QUOTES)
					var/str = _CopyString(context, i)
					if(!str)
						error = "Malformed INI: Reader terminated within a string."
						return 0
					else
						val = str
						i += length(str) + 1
				else if(char == CHAR_LESSTH)
					var/list/pPos = list(i + 1)
					val = _ParseList(context, pPos)
					i = pPos[1]
					if(!val) return 0
				else if(_IsValidNumeric(val, char))
					val += ascii2text(char)
					numVal = 1
				else if(char == CHAR_GREATH)
					break
				else
					error = "Malformed INI: Incorrect character found within list data [char] (length = [length(ret)])."
					return 0
			if(val)
				ret[++ret.len] = (numVal ? text2num(val) : val)
			lPos[1] = i
			return ret


	New(f = "")
		if(istext(f)) file = f
		if(file) Read()
	Read(f = "")
				// We are re-defining Read(), so any attempts using a /savefile should fail to read.
		if(istype(f, /savefile)) return 0

		if(istext(f) && f != "") file = f
		else if(!file || !istext(file)) return 0

		var
			contents = file2text(file)
			size = length(contents)
			read_state = 0
			char = 0
			header = ""
			key = ""
			val = ""
			Configuration/cur_section = null
		error = 0

		for(var/i = 1; i <= size; i++)
			char = text2ascii(contents, i)
			if(!read_state)
				if(_IsInvalidArea(contents, i))
					i = _SkipToValidity(contents, i)
					// The first character in an INI file should be a semicolon (comment) or a bracket.
				if(char == CHAR_LBRACK)
					read_state = STATE_HEADER
				else
									// Malformed INI
					error = "Malformed INI: Section header/name must be first."
					return 0
			else if(read_state == STATE_HEADER)
				if(char == CHAR_RBRACK)
									// Signifies the end of the header and the beginning of the data
					read_state = STATE_DATA
					cur_section = _AddSection(header)
					header = ""
				else if(_IsWhitespace(char))
									// Whitespace in a section header is only acceptable before or after the section name.
					if(length(header))
						var
							next = 0
							offset = 1
						for(1; (i + offset) <= size; ++offset)
							next = text2ascii(contents, i + offset)
							if(next != CHAR_RBRACK && !_IsWhitespace(next))
								error = "Malformed INI: Unacceptable whitespace in section header."
								return 0
							else if(next == CHAR_RBRACK)
								break
						i += (offset - 1)
					continue
				else if(_IsCommentStart(contents, i))
					error = "Malformed INI: Unacceptable comment in section header at [i]."
					return 0
				else if(_IsIdentifierChar(char, length(header) + 1))
					header += ascii2text(char)
				else
					error = "Malformed INI: Invalid header."
					return 0
			else if(read_state&STATE_DATA)
				if(!length(key))
					// Reading a new key/val pair
								// Skipping past all comments and whitespace
					if(_IsInvalidArea(contents, i))
						i = _SkipToValidity(contents, i)
						char = text2ascii(contents, i)
					if(!_IsIdentifierChar(char, 1))
						error = "Malformed INI: Non-identifier char in key/value pair."
						return 0
					else
						key += ascii2text(char)
						continue
				else
					if((read_state&STATE_VALUE) && _IsInvalidArea(contents, i))
						// Whitespace occurs at the end of a value, so we're good.
						read_state &= ~STATE_VALUE
						cur_section.Set(key, val, (read_state & STATE_STRING) || (read_state & STATE_LIST))
						read_state &= ~STATE_STRING
						key = ""
						val = ""
						i = _SkipToValidity(contents, i)
						if(text2ascii(contents, i) == CHAR_LBRACK)
							read_state = STATE_HEADER
							cur_section = null
						else
							i--
					else if(!(read_state&STATE_VALUE) && _IsSpace(char))
						i = _SkipSpace(contents, i)
						char = text2ascii(contents, i)
						if(char != CHAR_EQUALS)
							error = "Malformed INI: Invalid spacing in key/value pair (no assignment operator found)."
							return 0
						else
							read_state |= STATE_VALUE
						if(_IsSpace(text2ascii(contents, i + 1)))
							// Skip to the identifier
							i = _SkipSpace(contents, i + 1) - 1
					else
						if(read_state&STATE_VALUE)
							if(!length(val) && char == CHAR_QUOTES)
								var/str = _CopyString(contents, i)
								read_state |= STATE_STRING
								if(!str)
									error = "Malformed INI: Reader terminated within a string."
									return 0
								else
									val = str
									i += length(str) + 1
							else if(_IsValidNumeric(val, char))
								val += ascii2text(char)
							else if(char == CHAR_LESSTH)
								var/list/lPos = list(i + 1)
								val = _ParseList(contents, lPos)
								read_state |= STATE_LIST
								if(!val) return 0
								i = lPos[1]
							else
								error = "Malformed INI: Invalid value type (number or string supported)"
								return 0
						else
							key += ascii2text(char)
						continue
		if(length(key) && length(val))
			cur_section.Set(key, val, (read_state & STATE_STRING) || (read_state & STATE_LIST))
		return 1
	Write(f = "")
				// We are re-defining Write(), so any attempts using a /savefile should fail to write.
		if(!sections || istype(f, /savefile)) return 0

		if(istext(f) && f != "") file = f
		else if(!file || !istext(file)) return 0

		var/buf = ""
		var/sind = 0
		var/vind = 0

		for(var/Configuration/cfg in sections)
			var/list/settings = cfg._Settings()
			buf += "[sind++ ? "\n\n" : ""]\[[cfg.Name()]\]"
			for(var/i in settings)
				vind ++
				var/val = settings[i]
				if(isnum(val))
					buf += "\n[i] = [val]"
				else if(istype(val, /list))
					buf += "\n[i] = [_OutputList(val)]"
				else
					buf += "\n[i] = \"[val]\""

		buf += "\n; [sind] sections written with a total of [vind] values."
		if(fexists(file)) fdel(file)
		text2file(buf, file)
		return 1
