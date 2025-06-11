local config = require "data.config"

local maths = {}

-- fixed grid size
local ROWS, COLS = 5, 4

-- precompute flat list of all cell coords
local all_cells = {}
do
	for r = 1, ROWS do
		for c = 1, COLS do
			table.insert(all_cells, { r = r, c = c })
		end
	end
end

-- build cumulative distribution for star counts
local count_table = {}
do
  local cum = 0
  for k, p in pairs(config.starCountDist) do
    cum = cum + p
    table.insert(count_table, {
      k       = k,      -- star count
      cumProb = cum     -- probability
    })
  end
  table.sort(count_table, function(a,b) 
    return a.cumProb < b.cumProb 
  end)
end
-- sort tiers descending by min_cluster
local tiers = {}
do
	for _, t in pairs(config.tiers) do
		table.insert(tiers, {
			min_cluster = t.minCluster,
			reward      = t.reward
		})
	end

	-- sort me pls
	table.sort(tiers, function(a, b)
		return a.min_cluster > b.min_cluster
	end)
end

-- sample K from star count in config
function maths.sample_symbol_count()
  local x = math.random()

  for _, entry in ipairs(count_table) do
    if x <= entry.cumProb then
      return entry.k
    end
  end
  -- shouldn’t really happen if cumProb sums to 1
  return count_table[#count_table].k
end

-- pick K random positios
-- ideally could do possibilities here but used random for time being
function maths.pick_positions(k)
	local cells = {}

	for i, cell in ipairs(all_cells) do
		cells[i] = cell
	end

	for i = 1, k do
		local j = math.random(i, #cells)
		cells[i], cells[j] = cells[j], cells[i]
	end

	local out = {}

	for i = 1, k do
		out[i] = cells[i]
	end

	return out
end

-- find all 4‐way connected component sizes in golden_positions
-- golden_positions = array of {rows, ccolums}
function maths.find_connected_components(golden_positions)
	local star_set = {}
	for _, p in ipairs(golden_positions) do
		star_set[p.r .. "," .. p.c] = true
	end

	local visited = {}
	local sizes = {}
	local deltas = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

	for key in pairs(star_set) do
		if not visited[key] then
			local stack = { key }
			visited[key] = true
			local count = 0

			while #stack > 0 do
				local cell = table.remove(stack)
				count = count + 1

				local r, c = cell:match("([^,]+),([^,]+)")
				r, c = tonumber(r), tonumber(c)

				for _, d in ipairs(deltas) do
					local nr, nc = r + d[1], c + d[2]
					if nr >= 1 and nr <= ROWS and nc >= 1 and nc <= COLS then
						local nk = nr .. "," .. nc
						if star_set[nk] and not visited[nk] then
							visited[nk] = true
							table.insert(stack, nk)
						end
					end
				end
			end

			table.insert(sizes, count)
		end
	end

	return sizes
end

-- evaluate a set of golden_positions, returning { reward, size } or nil
function maths.evaluate_ticket(golden_positions)
	local comps = maths.find_connected_components(golden_positions)
	if #comps == 0 then
		return nil
	end

	for _, tier in ipairs(tiers) do
		for _, size in ipairs(comps) do
			if size >= tier.min_cluster then
				return { reward = tier.reward, size = size }
			end
		end
	end

	return nil
end

return maths
