Script.Load("lua/DigestMixin.lua")

Script.kMaxUseableRange = 6.5
local kDigestDuration = 1.5

function Sentry:GetDigestDuration()
    return kDigestDuration
end

function Sentry:GetUseMaxRange()
    return self.kMaxUseableRange
end
function Sentry:GetCanDigest(player)
    return player == self:GetOwner() and player:isa("Marine") and (not HasMixin(self, "Live") or self:GetIsAlive())
end

function Sentry:GetCanConsumeOverride()
    return false
end

local oldOnCreate = Sentry.OnCreate
function Sentry:OnCreate()
    oldOnCreate(self)
    InitMixin(self, DigestMixin)
end

-- CQ: Predates Mixins, somewhat hackish
function Sentry:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = useSuccessTable.useSuccess and self:GetCanDigest(player)
end

function Sentry:GetCanBeUsedConstructed()
    return true
end

if not Server then
    function Sentry:GetOwner()
        return self.ownerId ~= nil and Shared.GetEntity(self.ownerId)
    end
end

local sentry_onpudate = Sentry.OnUpdate
function Sentry:OnUpdate(deltaTime)

    self.attachedToBattery = true
    self.lastBatteryCheckTime = Shared.GetTime()
    
    sentry_onpudate(self, deltaTime)

end

function Sentry:OnUpdateAnimationInput(modelMixin)

    PROFILE("Sentry:OnUpdateAnimationInput")    
    modelMixin:SetAnimationInput("attack", self.attacking)
    modelMixin:SetAnimationInput("powered", true)
    
end


function Sentry:GetUnitNameOverride(viewer)
    
    local unitName = GetDisplayName(self)
    
    if not GetAreEnemies(self, viewer) and self.ownerId then
        local ownerName
        for _, playerInfo in ientitylist(Shared.GetEntitiesWithClassname("PlayerInfoEntity")) do
            if playerInfo.playerId == self.ownerId then
                ownerName = playerInfo.playerName
                break
            end
        end
        if ownerName then
            
            local lastLetter = ownerName:sub(-1)
            if lastLetter == "s" or lastLetter == "S" then
                return string.format( "%s' Sentry", ownerName )
            else
                return string.format( "%s's Sentry", ownerName )
            end
        end
    
    end
    
    return unitName

end

local oldOnDestroy = Sentry.OnDestroy
function Sentry:OnDestroy()
    if Server then
        --local team = self:GetTeam()
        --if team then
        --    team:UpdateClientOwnedStructures(self:GetId())
        --end
        local player = self:GetOwner()
        if player then
            if (self.consumed) then
                player:AddResources(1)
            else
                player:AddResources(1)
            end
        end
    end
    
    oldOnDestroy(self)
end

local networkVars =
{
    ownerId = "entityid"
}

Shared.LinkClassToMap("Sentry", Sentry.kMapName, networkVars, true)
Class_Reload("Sentry")