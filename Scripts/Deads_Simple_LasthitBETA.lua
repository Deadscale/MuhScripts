require("libs.ScriptConfig")
require("libs.Utils")
require("libs.Animations")

-- Config --
local config = ScriptConfig.new()
config:SetParameter("Stop", "S", config.TYPE_HOTKEY)
config:SetParameter("Toggle", "X", config.TYPE_HOTKEY)
config:SetParameter("SleepTime", 100)
config:Load()

local StopKey = config.Stop
local toggleKey = config.Toggle
local SleepTime = config.SleepTime

-- Globals --
local reg = false
local active = true
local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor) 
local toggleText  = drawMgr:CreateText(10*monitor,560*monitor,-1,"(" .. string.char(toggleKey) .. ") Last Hit: On",F14) toggleText.visible = false


-- Load --
function Load()
    if PlayingGame() then
        local me = entityList:GetMyHero()
        if not me then
            script:Disable() 
        else
            reg = true
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
			toggleText.text = "(" .. string.char(toggleKey) .. ") Last Hit: On"
		else
			toggleText.text = "(" .. string.char(toggleKey) .. ") Last Hit: Off"
		end
	end
end

-- Hotkey Text --
local hotkeyText
if string.byte("A") <= toggleKey and toggleKey <= string.byte("Z") then
	hotkeyText = string.char(toggleKey)
else
	hotkeyText = ""..toggleKey
end

-- Main --
function Tick(tick)
    local me = entityList:GetMyHero()
    local aRange = me.attackRange
    local bonus = 0
    
    if me.classId == CDOTA_Unit_Hero_Sniper then
        local TakeAim = me:GetAbility(3)
        local aimrange = {100,200,300,400}
        
        if TakeAim and TakeAim.level > 0 then
            bonus = aimrange[TakeAim.level]
        end
    end
    if me.classId == CDOTA_Unit_Hero_TemplarAssassin then
        local PsyBlade = me:GetAbility(3)
        local PsyRange = {60,120,180,240}
        
        if PsyBlade and PsyBlade.level > 0 then
            bonus = PsyRange[PsyBlade.level]
        end
    end
    
    local attackRange = aRange + bonus
    
    if (active and not IsKeyDown(StopKey)) and not client.chat and SleepCheck("stop") then
        local damage = (me.dmgMin + me.dmgBonus)
        local megaplayer = entityList:GetMyPlayer()
        local qblade = me:FindItem("item_quelling_blade")
        
        if qblade then
            if aRange > 195 then
                damage = damage*1.15
            else
                damage = damage*1.40
            end
        end
        
        if megaplayer.orderId == Player.ORDER_ATTACKENTITY then
            target = megaplayer.target
            if target.creep and target.health > 0 and target.visible and GetDistance2D(me,target) <= attackRange+50 then 
                if Animations.isAttacking(me) and (target.health > (target:DamageTaken(damage,DAMAGE_PHYS,me))) then
                    megaplayer:HoldPosition()
                    Sleep(SleepTime, "stop")
                else
                    return true
                end
            end
        end
    end
end

-- Close --
function GameClose()
    collectgarbage("collect")
    if reg then
        reg = false
        active = false
        toggleText.visible = false
        script:UnregisterEvent(Tick)
        script:UnregisterEvent(Key)
        script:RegisterEvent(EVENT_TICK,Load)
    end
end

script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Load)
