local config = require('data.config')

local function display_scratcher(payload)
	SetNuiFocus(true, true)

	SendNUIMessage({
		type = "Ticket:Open",
		data = payload
	})
end

-- define your scratch-off animation sequenc
local function on_scratcher_closed(item, cb)
	SetNuiFocus(false, false)

	if (item.scratched) then
		-- todo: tell server we scratched a ticket
		TriggerServerEvent("scratchers:server:ScratchTicket", item.serial)
	end

	cb(true)
end

local function register_redeeming_targets()
	for _, target in pairs(config.redeem_targets) do
		local height = math.abs(target.maxZ - target.minZ)
		local z = target.loc.z + math.abs(target.minZ - target.maxZ) / 2
		target.coords = vec3(target.loc.x, target.loc.y, z)
		target.size = vec3(target.width, target.length, height)
		target.rotation = target.heading

		target.options = {
			label = "Redeem Scratcher(s)",
			icon = "fa-solid fa-ticket",
			serverEvent = "scratchers:server:RedeemTickets"
		}

		exports.ox_target:addBoxZone(target)
	end
end

RegisterNetEvent("scratchers:client:ViewScratcher", display_scratcher)
RegisterNUICallback('ticketClosed', on_scratcher_closed)

AddEventHandler('onResourceStart', function(resourceName)
  if (GetCurrentResourceName() ~= resourceName) then
    return
  end

	register_redeeming_targets()
end)