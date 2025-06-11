local config = {}

-- Key = how many stars
-- Value = possibility of having said amount of stars
config.starCountDist = {
	[2] = 0.60,
	[3] = 0.30,
	[4] = 0.15,
	[5] = 0.05,
}

config.tiers = {
	{ minCluster = 3, reward = 100 },
	{ minCluster = 4, reward = 500 },
	{ minCluster = 5, reward = 1000 }
}

config.redeem_targets = {
	{ loc = vec3(1134.9, -982.34, 46.41), length = 0.5, width = 0.5, heading = 96.0, minZ = 46.4, maxZ = 46.8, distance = 1.5 }
}

return config