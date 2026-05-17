-- client/character_creation.lua

local isCharacterCreationOpen = false

RegisterNetEvent("SPZ:openCharacterCreation", function(data)
    if isCharacterCreationOpen then return end
    isCharacterCreationOpen = true
    
    -- Try to hide any other UI
    TriggerEvent("spz-ui:hide")
    
    -- Ensure loading screen is cleared if triggered from server connection
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(500)
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "showCharacterCreation",
        suggestedName = data and data.suggested or ""
    })
end)

RegisterNUICallback("submitCharacterCreation", function(data, cb)
    local username = data.username
    local gender = data.gender

    -- Server event was already defined in spz-identity/server/main.lua
    TriggerServerEvent("SPZ:characterCreated", gender, username)
    cb("ok")
end)

RegisterNetEvent("SPZ:characterCreateCompleted", function(success, message)
    if success then
        isCharacterCreationOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = "hideCharacterCreation"
        })
        -- The server will then emit SPZ:characterReady and SPZ:playerReady to spz-spawn
    else
        SendNUIMessage({
            type = "characterCreationError",
            message = message or "An unknown error occurred."
        })
    end
end)
