ESX = nil
local PlayerData = {}
local currentParty, dungeonData, Allmonsters = {}, {}, {}
local busy, onCountDown, playerState, isPicking, isDead = false, false, false, false, false
local Npc = nil
local dungeonTimer = 0
local Monsters = 0
local nearbyObject, nearbyID
local Token = nil
local script_name = GetCurrentResourceName()
local Spawning = false
PLAYER_GROUP = GetHashKey("PLAYER")
ZOMBIE_GROUP = GetHashKey("_ZOMBIE")
AddRelationshipGroup("_ZOMBIE")
local purgeday = false

Citizen.CreateThread(function()
    while ESX == nil do 
        Citizen.Wait(1)
        -- Init extended object.
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
	while ESX.GetPlayerData().job == nil do Citizen.Wait(100) end

    PlayerData = ESX.GetPlayerData()
    Citizen.Wait(500)
    TriggerServerEvent(script_name..':getDungeonStatus')
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

RegisterNetEvent(script_name..':setTK')
AddEventHandler(script_name..':setTK', function(tk, hasbusy)
	Token = tk
    busy = hasbusy
	local model = "DocZ"
    LoadModels(GetHashKey(model))
    Npc = CreatePed(4, model, Config.RegisterZone.x, Config.RegisterZone.y, Config.RegisterZone.z-1.0, 181.73, false, true)
    FreezeEntityPosition(Npc, true)
    SetEntityInvincible(Npc, true)
    SetBlockingOfNonTemporaryEvents(Npc, true)
    local blip = AddBlipForCoord(Config.RegisterZone.x, Config.RegisterZone.y, Config.RegisterZone.z)
	SetBlipHighDetail(blip, true)
	SetBlipSprite (blip, 310)
	SetBlipScale  (blip, 0.6)
	SetBlipColour (blip, 1)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('<font face="THSarabunNew">ดันเจี้ยน</font>')
	EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent(script_name..':setDungeonStatus')
AddEventHandler(script_name..':setDungeonStatus', function(hasbusy)
    busy = hasbusy
    if (not hasbusy) then 
        currentParty = {}
        dungeonTimer = 0
    end
end)

-- // Register Dungeon Thread //
Citizen.CreateThread(function()
    while true do 
        local threadSleep = true
		if not purgeday then
			local pedCoords = GetEntityCoords(PlayerPedId())
			if (GetDistanceBetweenCoords(pedCoords, Config.RegisterZone, true) < 2.0) and not isDead then
				if (busy) then
					DrawText3D(Config.RegisterZone, '~r~ดันเจี้ยนยังไม่ว่าง', 2.0)
				else
					DrawText3D(Config.RegisterZone, '[~b~E~s~] เข้าร่วมดันเจี้ยน', 2.0)
					if (IsControlJustReleased(0, 38)) then
						if PlayerData.job and (PlayerData.job.name == "ambulance" or PlayerData.job.name == "mechanic") then
							TriggerEvent('pNotify:SendNotification', {text = "ต้องออกเวรก่อน", type = "error", queue = "job"})
						elseif (PlayerData.job.name == "police" or PlayerData.job.name == "offpolice") then
							TriggerEvent('pNotify:SendNotification', {text = "ต้องพักร้อนก่อนนะ", type = "error", queue = "job"})
						else
							openRegisterUI()
						end
					end
				end 
				threadSleep = false
			end
			for k, v in pairs(Config.ExitGate) do
				if (GetDistanceBetweenCoords(pedCoords, v, true) < 3.0) and not isDead and not playerState then
					DrawText3D(v, '[E] ~r~ออกจากดันเจี้ยน', 2.0)
					if (IsControlJustReleased(0, 38)) then
						FreezeEntityPosition(PlayerPedId(), true)
						Citizen.Wait(500)
						SetEntityCoords(PlayerPedId(), Config.ExitZone.x, Config.ExitZone.y, Config.ExitZone.z, false)
						Citizen.Wait(2500)
						FreezeEntityPosition(PlayerPedId(), false)
					end
					threadSleep = false
				end
			end
		end
        if (threadSleep) then 
            Citizen.Wait(500)
        end
        Citizen.Wait(1)
    end
end)

function openRegisterUI()
    SetNuiFocus(true, true);
    SendNUIMessage({
        message = 'openRegisterUI',
		max = Config.MaxPlayer
    })
    SendNUIMessage({
        message = 'updatePlayer',
        team = currentParty,
    })
end

RegisterNetEvent(script_name..':updatePartyPlayer')
AddEventHandler(script_name..':updatePartyPlayer', function(_currentPlayer)
    currentParty = _currentPlayer
    Wait(300)
    SendNUIMessage({
        message = 'updatePlayer',
        team = currentParty,
    })
end)

RegisterNetEvent(script_name..':countDown')
AddEventHandler(script_name..':countDown', function(__countDownTimer)
    local countDownTimer = __countDownTimer
    onCountDown = true
    Citizen.CreateThread(function()
        while onCountDown do
            if (countDownTimer > 0) then
                countDownTimer = countDownTimer - 1
                SendNUIMessage({
                    message = 'updateCountDownTimer',
                    timer = countDownTimer,
                })
            else
                onCountDown = false
            end
            Citizen.Wait(1000)
        end
    end)
end)

RegisterNetEvent(script_name..':stopCountDown')
AddEventHandler(script_name..':stopCountDown', function()
    onCountDown = false
	SendNUIMessage({
		message = 'updateCountDownTimer',
		timer = 'รอผู้เล่นท่านอื่น',
	})
end)

RegisterNetEvent(script_name..':ForcedOut')
AddEventHandler(script_name..':ForcedOut', function(_score)
    TriggerEvent('mythic_progbar:client:cancel')
	isPicking = false
	if isDead then
		StopScreenEffect("DeathFailOut")
		local coords = GetEntityCoords(PlayerPedId())
		DoScreenFadeOut(800)
		while not IsScreenFadedOut() do
			Wait(50)
		end
		local formattedCoords = {
			x = ESX.Math.Round(coords.x, 1),
			y = ESX.Math.Round(coords.y, 1),
			z = ESX.Math.Round(coords.z, 1)
		}
		SetEntityCoordsNoOffset(PlayerPedId(), formattedCoords.x, formattedCoords.y, formattedCoords.z, false, false, false)
		NetworkResurrectLocalPlayer(formattedCoords.x, formattedCoords.y, formattedCoords.z, 0.0, true, false)
		SetPlayerInvincible(PlayerPedId(), false)
		TriggerEvent('esx:onPlayerSpawn')
		ClearPedBloodDamage(PlayerPedId())
		ESX.UI.Menu.CloseAll()
		StopScreenEffect("DeathFailOut")
		StopScreenEffect("")
		DoScreenFadeIn(800)
		SetEntityHealth(PlayerPedId(), 200)
	end
	FreezeEntityPosition(PlayerPedId(), true)
	Wait(500)
	playerState = false
	SetEntityCoords(PlayerPedId(), Config.ExitZone.x, Config.ExitZone.y, Config.ExitZone.z, false)
	if next(dungeonData) ~= nil then
		for k, v in pairs(dungeonData) do DeleteEntity(v.prop)  end
	end
	for key, ped in pairs(Allmonsters) do
		DeletePed(ped)
		table.remove(Allmonsters, key)
	end
	Wait(3000)
	Monsters = 0
	Allmonsters = {}
	dungeonData = {}
	FreezeEntityPosition(PlayerPedId(), false)
	SendNUIMessage({
        message = 'gameEnd',
    })
end)

RegisterNetEvent(script_name..':setDungeonStart')
AddEventHandler(script_name..':setDungeonStart', function(_dungeonData, _dungeonTimer)
    FreezeEntityPosition(PlayerPedId(), true)
    local coordsTarget = Config.SpawnPedCoords[GetRandomIntInRange(1, #Config.SpawnPedCoords)]
    dungeonData = _dungeonData
    dungeonTimer = _dungeonTimer
	SetEntityCoords(PlayerPedId(), coordsTarget.x, coordsTarget.y, coordsTarget.z, false)
    playerState = true
	-- TriggerEvent('esx_ambulancejob:Dungeonstate', playerState)
	SetNuiFocus(false, false)
    SendNUIMessage({
        message = 'closeUI',
    })
	for k,v in pairs(dungeonData) do
		ESX.Game.SpawnLocalObject(Config.Prop, v.coord, function(obj)
			PlaceObjectOnGroundProperly(obj)
			FreezeEntityPosition(obj, true)
			v.prop = obj
		end)
	end
    Wait(6000)
    FreezeEntityPosition(PlayerPedId(), false)
    SendNUIMessage({
        message = 'gameStart'
    })
    -- // Main Thread //
    Citizen.CreateThread(function()
        while playerState do
            Citizen.Wait(1)
            local pedCoords = GetEntityCoords(PlayerPedId())
			local near = false
			for k, v in pairs(dungeonData) do
				if GetDistanceBetweenCoords(pedCoords, v.coord, true) < 2 and not isPicking and not isDead then
					nearbyObject, nearbyID = v.prop, k
					near = true
					DrawText3D(v.coord, '[E] ~y~เปิดกล่อง', 1.5)
				end
			end
			
			if nearbyObject and near then
				if IsControlJustReleased(0, 38) and not isPicking and IsPedOnFoot(PlayerPedId()) then
					isPicking = true
					math.randomseed(GetGameTimer()+math.random(1111,9999)+math.random(1111,9999))
					TriggerEvent('esx_status:add', "stress", (math.random(3, 7) * 10))
					local Drt = (math.random(100, 120) * 100)
					local vip = ESX.HasItem('vip_card')
					if vip then
						Drt = Drt * 0.7
					end
					TriggerEvent('mythic_progbar:client:progress', {
						name = "unique_action_name",
						duration = Drt, 
						label = 'Searching..',
						useWhileDead = false,
						canCancel = true,
						controlDisables = {
							disableMovement = true,
							disableCarMovement = true,
							disableMouse = false,
							disableCombat = true,
						},		
						animation = {
							animDict = 'amb@prop_human_bum_bin@idle_b',
							anim = 'idle_d',
							flags = 1,
						},
					}, function(status)
						if not status and not isDead then
							if dungeonData[nearbyID] and dungeonData[nearbyID].prop == nearbyObject then
								TriggerServerEvent(script_name..':GetCrate', nearbyID, Token)
								isPicking = false
							else
								isPicking = false
							end
						else
							isPicking = false
						end
					end)
				end
			else
				Citizen.Wait(500)
			end
        end
    end)
	
	-- // Monsters Thread //
    Citizen.CreateThread(function()
        while playerState do
            Citizen.Wait(7500)
			if Monsters < Config.MaxMonsters then
				SpawnRandomMonsters()
			end
		end
    end)
	
	-- // Monsters Thread //
    Citizen.CreateThread(function()
        while playerState do
            Citizen.Wait(0)
			if Monsters > 0 then
				for key, ped in pairs(Allmonsters) do
					if (GetDistanceBetweenCoords(GetEntityCoords(ped), GetEntityCoords(PlayerPedId()), false) > 20.0) then
						DeletePed(ped)
						table.remove(Allmonsters, key)
						Monsters = Monsters - 1
					else
						if (IsEntityDead(ped)) then
							math.randomseed(GetGameTimer()+math.random(1111,9999)+math.random(1111,9999))
							DeletePed(ped)
							table.remove(Allmonsters, key)
							Monsters = Monsters - 1
							TriggerEvent('esx_status:add', "stress", (math.random(3, 7) * 10))
							local lucky = math.random(1,100)
							if lucky < 85 then
								TriggerServerEvent(script_name..':rootBody', Token)
							end
						else
							SetPedSuffersCriticalHits(ped, false)
							DrawText3D(GetEntityCoords(ped), "~w~"..(GetEntityHealth(ped) - 100).."/100~s~", 1.0)
						end
					end
				end
			end
		end
    end)
end)

RegisterNetEvent(script_name..':joinParty')
AddEventHandler(script_name..':joinParty', function()
	SendNUIMessage({
        message = 'UpjoinParty'
    })
end)

RegisterNetEvent(script_name..':removeCrate')
AddEventHandler(script_name..':removeCrate', function(CrateId)
	if dungeonData[CrateId] then
		DeleteEntity(dungeonData[CrateId].prop)
		dungeonData[CrateId] = nil
	end
end)

RegisterNetEvent(script_name..':setData')
AddEventHandler(script_name..':setData', function(_dungeonCrate, _dungeonTimer)
    score = _dungeonCrate
	dungeonTimer = _dungeonTimer
	local Allalive = false
	for index, ped in pairs(currentParty) do
		local health = 100
		local iPed = GetPlayerPed(GetPlayerFromServerId(ped.playerID))
		if iPed ~= PlayerPedId() then
			health = GetEntityHealth(iPed)
		else
			local found, amount = ESX.HasItem(Config.Key)
			ped.keys = amount
			health = GetEntityHealth(PlayerPedId())
		end
		if health < 100 then
			health = 0
		else
			Allalive = true
			health = (health - 100)
		end
		ped.health = health
	end
    SendNUIMessage({
        message = 'updateGameTimer',
		timer = dungeonTimer,
        score = score,
		team = currentParty
    })
	if not Allalive then
		TriggerServerEvent(script_name..':ForcedEnd', Token)
	end
end)

AddEventHandler('esx:onPlayerSpawn', function()
	isDead = false
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    isDead = true
	isPicking = false
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if isPicking == true then
			DisableControlAction(0, 29, true) -- B
			DisableControlAction(0, 73, true) -- X
			DisableControlAction(0, 323, true) -- X
			DisableControlAction(0, 246, true) -- Y
			DisableControlAction(0, 289, true) -- F2
			DisableControlAction(0, 74, true) -- H
			DisableControlAction(0, 22, true) -- SPACEBAR
			DisableControlAction(0, 30, true) -- disable left/right
			DisableControlAction(0, 31, true) -- disable forward/back
			DisableControlAction(0, 23, true) -- disable f
			DisableControlAction(0, 21, true) -- disable sprint
			DisableControlAction(0, 44, true) -- Cover
			DisableControlAction(0, 18, true) -- Enter
			DisableControlAction(0, 176, true) -- Enter
			DisableControlAction(0, 201, true) -- Enter
			DisableControlAction(0, 170, true) -- F3
			DisableControlAction(0, 166, true) -- F5
			DisableControlAction(0, 167, true) -- F6
			DisableControlAction(0, 56, true) -- F9
		else
			Citizen.Wait(300)
		end
	end
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        message = "closeUI",
    })
end)

RegisterNUICallback('joinTeam', function(data, cb)
    if (#currentParty < tonumber(Config.MaxPlayer)) then
		local found, amount = ESX.HasItem(Config.Ticket)
		if found then
        	TriggerServerEvent(script_name..':joinParty')
			cb({ok = false})
		else
			cb({ok = true, swal = 'เข้าร่วมล้มเหลว คุณไม่มีบัตรเข้าดันเจี้ยน !'})
		end
    else
        cb({ok = true, swal = 'เข้าร่วมล้มเหลว ทีมอาจเต็ม !'})
    end
end)

RegisterNUICallback('leaveTeam', function(data, cb)
    TriggerServerEvent(script_name..':leaveParty')
    Wait(300)
    cb({ok = true, swal = 'ออกทีมเรียบร้อย !'})
end)

local fontID = nil
Citizen.CreateThread(function()
    while fontID == nil do
        Citizen.Wait(5000)
        fontID = exports["base_font"]:GetFontId("srbn")
    end
end)

function DrawText3D(coords,textInput,sc)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local distance = GetDistanceBetweenCoords(px,py,pz, coords.x, coords.y, coords.z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    if sc then scale = scale * sc end
    SetTextScale(0.0 * scale, 0.35 * scale)
    SetTextFont(fontID)   ------แบบอักษร 1-7
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(coords.x, coords.y, coords.z+1.0, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

function GetRandomPosOffsetFromEntity(entity, maxDistance)
    local angle = math.random() * math.pi * 2
    local r = math.sqrt(math.random()) * maxDistance
    local x = r * math.cos(angle)
    local y = r * math.sin(angle)
    return GetOffsetFromEntityInWorldCoords(entity, x, y, 0.0)
end

function SpawnRandomMonsters()
	if playerState and not Spawning then
		Spawning = true
		local _weapon = "WEAPON_FLASHLIGHT"
		math.randomseed(GetGameTimer()+math.random(1111,9999)+math.random(1111,9999))
		local lucky = math.random(1,100)
		if lucky > 85 then
			_weapon = "WEAPON_MACHETE"
		elseif lucky > 50 then
			_weapon = "WEAPON_KNUCKLE"
		end
		local goodSpawnFound = false
		local spawnPos
		local tries = 5
		while not goodSpawnFound do
			goodSpawnFound = true
			spawnPos = GetRandomPosOffsetFromEntity(PlayerPedId(), 12.0)
			if not spawnPos then
				goodSpawnFound = false
				tries = tries - 1
			end
			if tries == 0 then
				spawnPos = nil
			end
		end
		if spawnPos then
			local found, newZ = GetGroundZFor_3dCoord(table.unpack(spawnPos))
			if not newZ then
				newZ = spawnPos.z - 1000.0
			end
			local choosenPed = GetHashKey(Config.MonsterModels[math.random(1, #Config.MonsterModels)])
			LoadModels(choosenPed)
			local currentPed = CreatePed(4, choosenPed, spawnPos.x, spawnPos.y, newZ, 0.0, false);
			NetworkRegisterEntityAsNetworked(currentPed);
			SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(currentPed), true)
			SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(currentPed), true);
        	NetworkSetNetworkIdDynamic(NetworkGetNetworkIdFromEntity(currentPed), false);
			-- SetModelAsNoLongerNeeded(choosenPed)
			local walk = 'move_lester_CaneUp'
			RequestAnimSet(walk)
			while not HasAnimSetLoaded(walk) do Citizen.Wait(1) end
			TaskSetBlockingOfNonTemporaryEvents(currentPed, true)
			SetPedMovementClipset(currentPed, walk, 1.0)
			TaskWanderStandard(currentPed, 10.0, 10)
			SetEntityMaxHealth(currentPed, 199)
			SetEntityHealth(currentPed, 199)
			SetCanAttackFriendly(currentPed, true, true)
			SetPedCanEvasiveDive(currentPed, false)
			SetPedCombatAbility(currentPed, 0)
			SetPedCombatRange(currentPed, 0)
			SetPedCombatMovement(currentPed, 3)
			SetPedAlertness(currentPed, 3)
			-- SetPedIsDrunk(currentPed, true)
			-- SetPedConfigFlag(currentPed, 2, 1)
			SetPedConfigFlag(currentPed, 100, 1)
			SetPedCanSwitchWeapon(currentPed, false)
			SetPedAccuracy(currentPed, 80)
			DisablePedPainAudio(currentPed, true)
			StopPedSpeaking(currentPed, true)
			SetPedCombatAttributes(currentPed, 46, 1)
			SetPedCanRagdollFromPlayerImpact(currentPed, false)
			GiveWeaponToPed(currentPed, GetHashKey(_weapon), 1, false, true)
			TaskCombatPed(currentPed, PlayerPedId(), 0, 16)
			SetPedRelationshipGroupHash(currentPed, ZOMBIE_GROUP)
			table.insert(Allmonsters, currentPed)
			Monsters = Monsters + 1
		end
		Spawning = false
    end
end

function LoadModels(model)
    if not IsModelValid(model) then
        return
    end
	if not HasModelLoaded(model) then
		RequestModel(model)
	end
	while not HasModelLoaded(model) do
		Citizen.Wait(7)
	end
end

function getStatusDungeon()
	return playerState
end

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		DeletePed(Npc)
		for k, v in pairs(dungeonData) do DeleteEntity(v.prop)  end
		for key, ped in pairs(Allmonsters) do DeletePed(ped) end
	end
end)