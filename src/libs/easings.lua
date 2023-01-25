return {
	["linear"] = function(x) return x end,
	["sine"] = { --1
		["in"] = function(x) return 1 - math.cos((x * math.pi) / 2) end,
		["out"] = function(x) return math.sin((x * math.pi) / 2) end,
		["inout"] = function(x) return -(math.cos(math.pi * x) - 1) / 2 end,
	},
	["quad"] = { --2
		["in"] = function(x) return x * 2 end,
		["out"] = function(x) return 1 - ((1 - x) ^ 2) end,
		["inout"] = function(x) return (x < 0.5) and (2 * x * x) or (1 - ((-2 * x + 2) ^ 2) / 2) end,
	},
	["cubic"] = { --3
		["in"] = function(x) return x ^ 3 end,
		["out"] = function(x) return 1 - ((1 - x) ^ 3) end,
		["inout"] = function(x) return (x < 0.5) and (4 * (x ^ 3)) or (1 - ((-2 * x + 2) ^ 3) / 2) end,
	},
	["quart"] = { --4 самые красивые
		["in"] = function(x) return x ^ 4 end,
		["out"] = function(x) return 1 - ((1 - x) ^ 4) end,
		["inout"] = function(x) return (x < 0.5) and (8 * (x ^ 4)) or (1 - ((-2 * x + 2) ^ 4) / 2) end,
	},
	["quint"] = { --5
		["in"] = function(x) return x ^ 5 end,
		["out"] = function(x) return 1 - ((1 - x) ^ 5) end,
		["inout"] = function(x) return (x < 0.5) and (16 * (x ^ 5)) or (1 - ((-2 * x + 2) ^ 5) / 2) end,
	}
}