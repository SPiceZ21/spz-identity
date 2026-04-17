-- client/main.lua

--- Set the player state for local identity sync
--- @param state string
local function SetPlayerState(state)
    -- This is a client-side mirror of the server-side player state
    -- spz-core calls this after spawning to set state to "FREEROAM"
    TriggerServerEvent("SPZ:identity:setPlayerState", state)
end

exports("SetPlayerState", SetPlayerState)
