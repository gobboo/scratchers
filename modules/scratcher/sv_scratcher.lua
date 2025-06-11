print("registered sv_scratcher")
local utils = require 'modules.utils.sh_utils'
local maths = require 'modules.maths.sv_maths'
local config = require 'data.config'

math.randomseed(os.time())

local current_redeem_inventories = {}

local function generate_unique_serial()
	local charset = {}
	for c = 48, 57 do
		table.insert(charset, string.char(c))
	end

	for c = 65, 90 do
		table.insert(charset, string.char(c))
	end

	local serial = {}
	for i = 1, 11 do
		local idx = math.random(1, #charset)
		serial[i] = charset[idx]
	end

	return table.concat(serial)
end

local function on_ticket_scratched(serial)
	-- do a lookup on the players inventory for said item

	local items = exports.ox_inventory:GetInventoryItems(source)

	local found_scratcher = {}

	for _, item in pairs(items) do
		local current_serial = item.metadata.serial

		if serial == current_serial then
			found_scratcher = item
			break
		end
	end

	found_scratcher.metadata.scratched = true
	exports.ox_inventory:SetMetadata(source, found_scratcher.slot, found_scratcher.metadata)
end

local function on_scratcher_callback(event, item, inventory, slot, data)
	print(event)

	if event ~= 'usingItem' then return end

	-- check if our item is a scratcher, precaution
	local is_scratcher = item.name ==
			"scratcher" -- only warning is that if someone changes the item "name" in the config, this wont be true ever, so...

	if not is_scratcher then return end


	local slot = exports.ox_inventory:GetSlot(inventory.id, slot)

	-- this is the bread and butter right here, here we generate winnings, then we tell the client to open the UI with the winning data
	local payload = {
		serial = slot.metadata.serial,
		goldenStars = slot.metadata.winners,
		scratched = slot.metadata.scratched,
		tiers = config.tiers -- could always just fetch this on the client but server sends JUST to make sure
	}

	TriggerClientEvent("scratchers:client:ViewScratcher", inventory.id, payload)
end

local function on_scratcher_creation(item)
	local serial = generate_unique_serial()

	local metadata = item.metadata
	metadata.serial = serial

	-- generate winnings here, that way we tie it to the ticket metadata and thats our storage :)
	local stars = maths.sample_symbol_count()

	local golden_positions = maths.pick_positions(stars)

	metadata.winners = golden_positions
	metadata.scratched = false

	return metadata
end

local function on_ticket_redemption_request()
	local player_id = source

	local stash = exports.ox_inventory:CreateTemporaryStash({
		label = "Please give me your scratchers to redeem",
		slots = 8,
		maxWeight = 999,
	})

	current_redeem_inventories[stash] = true

	exports.ox_inventory:forceOpenInventory(player_id, 'stash', stash)
end

local function on_ticket_stash_closed(player_id, inventory_id)
	if not current_redeem_inventories[inventory_id] then return end

	-- search the inventory, get all items that ARENT valid, and give them back
	local invalid_items = {}
	local to_redeem = {}

	local contents = exports.ox_inventory:GetInventoryItems(inventory_id)

	for slot, item in pairs(contents) do
		if item.name ~= "scratcher" or not item.metadata.scratched then
			invalid_items[slot] = item -- add the item to invalid items, store slot so we can be specific of the item to return
		else
			to_redeem[slot] = item
		end
	end

	-- return the items to the player that are invalid
	for _, item in pairs(invalid_items) do
		exports.ox_inventory:AddItem(player_id, item, 1, item.metadata)
	end

	-- the rest of items left, we get the winnings and give cash
	for _, item in pairs(to_redeem) do
		local winning_tier = maths.evaluate_ticket(item.metadata.winners)
		
		if not winning_tier then return end

		exports.ox_inventory:AddItem(player_id, 'money', winning_tier.reward)
	end
	
	current_redeem_inventories[inventory_id] = nil
end

AddEventHandler('ox_inventory:closedInventory', on_ticket_stash_closed)
RegisterServerEvent("scratchers:server:ScratchTicket", on_ticket_scratched)
RegisterServerEvent("scratchers:server:RedeemTickets", on_ticket_redemption_request)

exports.ox_inventory:registerHook('createItem', on_scratcher_creation, {
	print = true,
	itemFilter = {
		scratcher = true
	},
})

exports('onScratcherCallback', on_scratcher_callback)
