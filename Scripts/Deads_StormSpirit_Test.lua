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
config:SetParameter("Distance", "E", config.TYPE_HOTKEY)
config:SetParameter("Toggle", "X", config.TYPE_HOTKEY)
config:SetParameter("StayDistance", 400)
config:SetParameter("JumpDistance", 650)
config:Load()

local ChaseKey = config.Chase
local StayKey = config.Stay
local BallKey = config.NoBall
local DistanceKey = config.Distance
local StayDistance = config.StayDistance
local JumpDistance = config.JumpDistance
local toggleKey = config.Toggle

-- Globals --
local reg = false
local victim = nil
local sleep = 0
local attack = 0
local move = 0
local start = false
local reset = nil
local active = false
local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor) 
local statusText = drawMgr:CreateText(-20*monitor,80*monitor,-1,"Targeting",F14) statusText.visible = false
local toggleText  = drawMgr:CreateText(10*monitor,560*monitor,-1,"(" .. string.char(toggleKey) .. ") Hex + Silence",F14) toggleText.visible = false


-- Load --
function Load()
    if PlayingGame() then  
    local me = entityList:GetMyHero()
        if me.classId ~= CDOTA_Unit_Hero_StormSpirit then 
            script:Disable() 
        else
            reg = true
            victim = nil
            start = false
            sleep = 0
            reset = nil
            toggleText.visible = true
            script:RegisterEvent(EVENT_KEY,Key)
            script:RegisterEvent(EVENT_TICK,Tick)
            script:UnregisterEvent(Load)
        end
    end
end

-- Key --
function Key(msg,code)
	if not PlayingGame() or client.chat then return end	
	if IsKeyDown(toggleKey) and SleepCheck("toggle") then
		active = not active
        Sleep(200, "toggle")
		if active then
			toggleText.text = "(" .. string.char(toggleKey) .. ") Hex > Silence"
		else
			toggleText.text = "(" .. string.char(toggleKey) .. ") Hex + Silence"
		end
	end
end


-- Main --
function Tick(tick)
    local me = entityList:GetMyHero()
    local attackRange = 480
    
    if victim and victim.visible then
        if not statusText.visible then
            statusText.visible = true
        end
    else
        statusText.visible = false
    end
    
    if (IsKeyDown(ChaseKey) or IsKeyDown(StayKey) or IsKeyDown(BallKey) or IsKeyDown(DistanceKey))and not client.chat then
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
                local disabled = victim:IsHexed() or victim:IsStunned() or victim:IsSilenced()
                local linkens = victim:IsLinkensProtected() or victim:IsMagicImmune()
                local distance = GetDistance2D(victim,me)                
                local Overload = me:DoesHaveModifier("modifier_storm_spirit_overload")                
                local balling = me:DoesHaveModifier("modifier_storm_spirit_ball_lightning")
                
                if W and W:CanBeCasted() and me:CanCast() and distance <= W.castRange+100 and not pull and not linkens and not (Sheep and Sheep:CanBeCasted()) then
                    me:CastAbility(W,victim)
                    Sleep(W:FindCastPoint()*1000+me:GetTurnTime(victim)*1000,"casting")
                end

                if Q and Q:CanBeCasted() and me:CanCast() and distance <= attackRange+200 and not Overload then
                    me:CastAbility(Q)
                end
                    
                if R and R:CanBeCasted() and me:CanCast() and distance > attackRange+200 and not balling then
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
                end
                
                if Shivas and Shivas:CanBeCasted() and distance < attackRange+200 then
                    me:CastAbility(Shivas)
                end
                
                if (Sheep and not Orchid) and Sheep:CanBeCasted() and not pull then
                    me:CastAbility(Sheep, victim)
                    Sleep(me:GetTurnTime(victim)*1000, "casting")
                end
                
                if (Orchid and not Sheep) and Orchid:CanBeCasted() and not silenced then
                    me:CastAbility(Orchid, victim)
                    Sleep(me:GetTurnTime(victim)*1000, "casting")
                end
                
                if (Orchid and Sheep) and active then
                    if Sheep:CanBeCasted() and not disabled and not linkens then
                        me:CastAbility(Sheep, victim)
                        Sleep(me:GetTurnTime(victim)*1000, "casting")
                    end
                    if (Orchid:CanBeCasted() and not Sheep:CanBeCasted()) and not disabled then
                        me:CastAbility(Orchid, victim)
                        Sleep(me:GetTurnTime(victim)*1000, "casting")
                    end
                end
                
                if (Orchid and Sheep) and not active then
                    if Sheep:CanBeCasted() and not pull and not linkens then
                        me:CastAbility(Sheep, victim)
                        Sleep(me:GetTurnTime(victim)*1000, "casting")
                    end
                    if Orchid:CanBeCasted() and not silenced then
                        me:CastAbility(Orchid, victim)
                        Sleep(me:GetTurnTime(victim)*1000, "casting")
                    end
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
                    local xyz = (mouse - me.position) * StayDistance / GetDistance2D(mouse,me) + me.position
                    if GetDistance2D(me,victim) ~= 0 then
                        me:CastAbility(R,xyz)
                        Sleep(R:FindCastPoint()*1000+me:GetTurnTime(victim)*1000, "casting")
                    end
                end
                if IsKeyDown(DistanceKey) and R and R:CanBeCasted() and me:CanCast() and distance < attackRange+200 and not Overload then
                    local position = (victim.position - me.position) * (GetDistance2D(me,victim) - (attackRange-JumpDistance)) / GetDistance2D(me,victim) + me.position
                    if GetDistance2D(me,victim) ~= 0 then
                        me:CastAbility(R,position)
                        Sleep(R:FindCastPoint()*1000+me:GetTurnTime(victim)*1000, "casting")
                    end
                end
            end
            if victim then
                if victim.visible and (IsKeyDown(StayKey) or IsKeyDown(BallKey)) then
                    me:Move(client.mousePosition)
                elseif victim.visible and IsKeyDown(ChaseKey) then
                    local xyz = SkillShot.PredictedXYZ(victim,me:GetTurnTime(victim)*1000+client.latency+500)
                    me:Move(xyz)
                elseif victim.visible and IsKeyDown(DistanceKey) then
                    me:Attack(victim)
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
        toggleText.visible = false
        active = false
        victim = nil
        start = false
        reset = nil
        script:UnregisterEvent(Key)
        script:UnregisterEvent(Tick)
        script:RegisterEvent(EVENT_TICK,Load)
    end
end

script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Load)
