require("libs.ScriptConfig")
require("libs.Utils")
require("libs.TargetFind")
require("libs.Animations")
require("libs.Skillshot")

-- Config --
local config = ScriptConfig.new()
config:SetParameter("Chase", "D", config.TYPE_HOTKEY)
config:SetParameter("Stay", "S", config.TYPE_HOTKEY)
config:SetParameter("NoBall", "F", config.TYPE_HOTKEY)
config:Load()

local ChaseKey = config.Chase
local StayKey = config.Stay
local BallKey = config.NoBall

-- Globals --
local reg = false
local victim = nil
local sleep = 0
local attack = 0
local move = 0
local start = false
local reset = nil
local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor) 
local statusText = drawMgr:CreateText(-20*monitor,80*monitor,-1,"Targeting",F14) statusText.visible = false
local me = entityList:GetMyHero()

-- Load --
function Load()
    if PlayingGame() then
        if me.classId ~= CDOTA_Unit_Hero_StormSpirit then 
            script:Disable() 
        else
            reg = true
            victim = nil
            start = false
            sleep = 0
            reset = nil
            script:RegisterEvent(EVENT_TICK,Tick)
            script:UnregisterEvent(Load)
        end
    end
end

-- Main --
function Tick(tick)
    local attackRange = me.attackRange
    
    if victim and victim.visible then
        if not statusText.visible then
            statusText.visible = true
        end
    else
        statusText.visible = false
    end
    
    if (IsKeyDown(ChaseKey) or IsKeyDown(StayKey) or IsKeyDown(BallKey))and not client.chat then
        if Animations.CanMove(me) or not start or (victim and GetDistance2D(victim,me) > attackRange+450) then
            start = true
            local MouseOver = targetFind:GetLastMouseOver(1500)
            if MouseOver and (not victim or GetDistance2D(me,victim) > attackRange or not victim.alive) and SleepCheck("victim") then            
                victim = MouseOver
                statusText.entity = victim
                statusText.entityPosition = Vector(0,0,victim.healthbarOffset)
                Sleep(250,"victim")
            end
        end
        if not Animations.CanMove(me) and victim and GetDistance2D(me,victim) <= 1500 then
            if tick > attack and SleepCheck("casting") and victim.hero then
                local Q = me:GetAbility(1)
                local W = me:GetAbility(2)
                local R = me:GetAbility(4)
                local Sheep = me:FindItem("item_sheepstick")
                local Orchid = me:FindItem("item_orchid")
                local Shivas = me:FindItem("item_shivas_guard")
                local SoulRing = me:FindItem("item_soul_ring")                   
                local silenced = victim:IsSilenced() 
                local pull = victim:IsHexed() or victim:IsStunned()
                local linkens = victim:IsLinkensProtected()
                local distance = GetDistance2D(victim,me)                
                local Overload = me:DoesHaveModifier("modifier_storm_spirit_overload")                
                local balling = me:DoesHaveModifier("modifier_storm_spirit_ball_lightning")
                
                if W and W:CanBeCasted() and me:CanCast() and distance <= W.castRange+100 and not pull and not linkens and not Sheep:CanBeCasted() then
                    me:CastAbility(W,victim)
                    Sleep(W:FindCastPoint()*1000+me:GetTurnTime(victim)*1000,"casting")
                end

                if Q and Q:CanBeCasted() and me:CanCast() and distance <= attackRange+200 and not Overload then
                    me:CastAbility(Q)
                    Sleep(client.latency, "casting")
                end
                    
                if R and R:CanBeCasted() and me:CanCast() and distance > attackRange+100 and not balling and not R.abilityphase then
                    local CP = R:FindCastPoint()
                    local delay = CP*1000+client.latency+me:GetTurnTime(victim)*1000
                    local speed = R:GetSpecialData("ball_lightning_move_speed", R.level)
                    local xyz = SkillShot.SkillShotXYZ(me,victim,delay,speed)
                    if xyz then
                        me:CastAbility(R,xyz)
                        Sleep(delay, "casting")
                    end
                end
                
                if SoulRing and SoulRing:CanBeCasted() and distance < attackRange+200 then
                    me:CastAbility(SoulRing)
                    Sleep(client.latency, "casting")
                end
                if Sheep and Sheep:CanBeCasted() and not pull and not linkens then
                    me:CastAbility(Sheep, victim)
                    Sleep(me:GetTurnTime(victim)*1000, "casting")
                end
                if Orchid and Orchid:CanBeCasted() and not silenced then
                    me:CastAbility(Orchid, victim)
                    Sleep(me:GetTurnTime(victim)*1000, "casting")
                end
                if Shivas and Shivas:CanBeCasted() and distance < attackRange+200 then
                    me:CastAbility(Shivas)
                    Sleep(client.latency, "casting")
                end
                me:Attack(victim)
                attack = tick + 100
            end
        elseif tick > move and SleepCheck("casting") then
            if victim and victim.hero and not Animations.isAttacking(me) then
                local R = me:GetAbility(4)    
                local Overload = me:DoesHaveModifier("modifier_storm_spirit_overload")                
                local distance = GetDistance2D(victim,me)                
                
                if IsKeyDown(ChaseKey) and R and R:CanBeCasted() and me:CanCast() and distance < attackRange+200 and not Overload then
                    local CP = R:FindCastPoint()
                    local delay = CP*1000+client.latency+me:GetTurnTime(victim)*1000
                    local speed = R:GetSpecialData("ball_lightning_move_speed", R.level)
                    local xyz = SkillShot.SkillShotXYZ(me,victim,delay,speed)
                    if xyz then
                        me:CastAbility(R,xyz)
                        Sleep(delay, "casting")
                    end
                end
                
                if IsKeyDown(StayKey) and R and R:CanBeCasted() and me:CanCast() and distance < attackRange+200 and not Overload then
                    local mouse = client.mousePosition
                    local xyz = (mouse - me.position) * 400 / GetDistance2D(mouse,me) + me.position
                    me:CastAbility(R,xyz)
                    Sleep(R:FindCastPoint()*1000+me:GetTurnTime(victim)*1000, "casting")
                end
            end
            if victim then
                if victim.visible and (IsKeyDown(StayKey) or IsKeyDown(BallKey)) then
                    me:Move(client.mousePosition)
                elseif victim.visible and IsKeyDown(ChaseKey) then
                    local xyz = SkillShot.PredictedXYZ(victim,me:GetTurnTime(victim)*1000+client.latency+500)
                    me:Move(xyz)
                else
                    me:Follow(victim)
                end
            else
                me:Move(client.mousePosition)
            end
            move = tick + 100
            start = false
        end
    elseif victim then
        if not reset then
            reset = client.gameTime
        elseif (client.gameTime - reset) >= 3 then
            victim = nil
        end
        start = false
    end
end

-- Close --
function GameClose()
    collectgarbage("collect")
    if reg then
        reg = false
        statusText.visible = false
        victim = nil
        start = false
        reset = nil
        script:UnregisterEvent(Tick)
        script:RegisterEvent(EVENT_TICK,Load)
    end
end

script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Load)
