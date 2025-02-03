-- tldr see this: https://abcnotation.com/wiki/abc:standard:v2.1#kkey
-- and https://www.merriammusic.com/school-of-music/piano-lessons/music-key-signatures/ at section "Key Signature Chart"

local key_signatures_keys = {
	["7#"] = {"C#", "A#M", "G#MIX", "D#DOR", "E#PHR", "F#LYD", "B#LOC"},
	["6#"] = {"F#", "D#M", "C#MIX", "G#DOR", "A#PHR", "BLYD",  "E#LOC"},
	["5#"] = {"B",  "G#M", "F#MIX", "C#DOR", "D#PHR", "ELYD",  "A#LOC"},
	["4#"] = {"E",  "C#M", "BMIX",  "F#DOR", "G#PHR", "ALYD",  "D#LOC"},
	["3#"] = {"A",  "F#M", "EMIX",  "BDOR",  "C#PHR", "DLYD",  "G#LOC"},
	["2#"] = {"D",  "BM",  "AMIX",  "EDOR",  "F#PHR", "GLYD",  "C#LOC"},
	["1#"] = {"G",  "EM",  "DMIX",  "ADOR",  "BPHR",  "CLYD",  "F#LOC"},
	["0" ] = {"C",  "AM",  "GMIX",  "DDOR",  "EPHR",  "FLYD",  "BLOC" },
	["1b"] = {"F",  "DM",  "CMIX",  "GDOR",  "APHR",  "BBLYD", "ELOC" },
	["2b"] = {"BB", "GM",  "FMIX",  "CDOR",  "DPHR",  "EBLYD", "ALOC" },
	["3b"] = {"EB", "CM",  "BBMIX", "FDOR",  "GPHR",  "ABLYD", "DLOC" },
	["4b"] = {"AB", "FM",  "EBMIX", "BBDOR", "CPHR",  "DBLYD", "GLOC" },
	["5b"] = {"DB", "BBM", "ABMIX", "EBDOR", "FPHR",  "GBLYD", "CLOC" },
	["6b"] = {"GB", "EBM", "DBMIX", "ABDOR", "BBPHR", "CBLYD", "FLOC" },
	["7b"] = {"CB", "ABM", "GBMIX", "DBDOR", "EBPHR", "FBLYD", "BBLOC"} 
}

local key_signatures = {
	["7#"] = { F = "^", C = "^", G = "^", D = "^", A = "^", E = "^", D = "^" },
	["6#"] = { F = "^", C = "^", G = "^", D = "^", A = "^", E = "^" },
	["5#"] = { F = "^", C = "^", G = "^", D = "^", A = "^" },
	["4#"] = { F = "^", C = "^", G = "^", D = "^" },
	["3#"] = { F = "^", C = "^", G = "^" },
	["2#"] = { F = "^", C = "^" },
	["1#"] = { F = "^" },
	["0"]  = {},
	["1b"] = { B = "_" },
	["2b"] = { B = "_", E = "_" },
	["3b"] = { B = "_", E = "_", A = "_" },
	["4b"] = { B = "_", E = "_", A = "_", D = "_" },
	["5b"] = { B = "_", E = "_", A = "_", D = "_", G = "_" },
	["6b"] = { B = "_", E = "_", A = "_", D = "_", G = "_", C = "_" },
	["7b"] = { B = "_", E = "_", A = "_", D = "_", G = "_", C = "_", F = "_" }
}

return key_signatures, key_signatures_keys