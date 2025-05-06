local isHovering = false

RegisterCommand('hover', function()
  	local ped = cache.ped
	local vehicle = GetVehiclePedIsIn(ped, true)

	if GetVehicleClass(vehicle) == 15 then
		isHovering = not isHovering
		if isHovering then
			Citizen.CreateThread(function()
				lib.notify({title = 'Automatické nadvznášení bylo zapnuto!', type = 'success', duration = 3500})
				while GetVehiclePedIsIn(ped,true) == vehicle and isHovering and GetHeliMainRotorHealth(vehicle) > 0 and GetHeliTailRotorHealth(vehicle) > 0 and GetVehicleEngineHealth(vehicle) > 300 do Citizen.Wait(0)
					local currentvelocity = GetEntityVelocity(vehicle)
					SetEntityVelocity(vehicle, currentvelocity.x, currentvelocity.y, 0.0)
				end
				lib.notify({title = 'Automatické nadvznášení bylo vypnuto!', type = 'error', duration = 3500})
				isHovering = false
			end)
		else
			
				end
	end
end)