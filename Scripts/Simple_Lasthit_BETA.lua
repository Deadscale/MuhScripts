require("libs.ScriptConfig")
require("libs.Utils")
require("libs.Animations")

-- Config --
local config = ScriptConfig.new()
config:SetParameter("Stop", "S", config.TYPE_HOTKEY)
config:SetParameter("Toggle", "X", config.TYPE_HOTKEY)
config:SetParameter("NoSpam", true)
config:Load()

local StopKey = config.Stop
local toggleKey = config.Toggle
local NoSpam = config.NoSpam

-- Globals --
local reg = false
local active = true
local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor) 
local toggleText  = drawMgr:CreateText(10*monitor,630*monitor,-1,"(" .. string.char(toggleKey) .. ") Last Hit: On",F14) toggleText.visible = false


-- Load --
function Load()
    if PlayingGame() then
        reg = true
        toggleText.visible = true
        script:RegisterEvent(EVENT_KEY,Key)
        script:RegisterEvent(EVENT_TICK,Tick)
        script:UnregisterEvent(Load)
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
    if not me then return end
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
    
    if (active and not IsKeyDown(StopKey)) and not client.chat then
        local damage = me.dmgMin + me.dmgBonus
        local megaplayer = entityList:GetMyPlayer()
        local qblade = me:FindItem("item_quelling_blade")
        
        if qblade then
           if attackRange > 195 then
                damage = me.dmgMin*1.15 + me.dmgBonus
            else
                damage = me.dmgMin*1.40 + me.dmgBonus
            end
        end
            
        if megaplayer.orderId == Player.ORDER_ATTACKENTITY and (megaplayer.target.classId == CDOTA_BaseNPC_Creep_Lane or megaplayer.target.classId == CDOTA_BaseNPC_Creep_Siege) and megaplayer.target.alive == true and megaplayer.target.visible == true and SleepCheck("stop") then
        target = megaplayer.target     
            if me.classId == CDOTA_Unit_Hero_AntiMage then
                local Manabreak = me:GetAbility(1)
                local Manaburn = {28,40,52,64}
                    
                if Manabreak and Manabreak.level > 0 and megaplayer.target.maxMana > 0 and megaplayer.target.mana > 0 and megaplayer.target.team ~= me.team then
                    damage = damage + Manaburn[Manabreak.level]*0.60
                end
            end          
            if me.classId == CDOTA_Unit_Hero_Viper then
                local Nethertoxin = me:GetAbility(2)
                local Toxindamage = {2.5,5,7.5,10}  
                
                if Nethertoxin and Nethertoxin.level > 0 and megaplayer.target.team ~= me.team then
                    local HPcent = (megaplayer.target.health / megaplayer.target.maxHealth)*100
                    local Netherdamage = nil
                    if HPcent > 80 and HPcent <= 100 then
                        Netherdamage = Toxindamage[Nethertoxin.level]*0.5
                    elseif HPcent > 60 and HPcent <= 80 then
                        Netherdamage = Toxindamage[Nethertoxin.level]
                    elseif HPcent > 40 and HPcent <= 60 then
                        Netherdamage = Toxindamage[Nethertoxin.level]*2
                    elseif HPcent > 20 and HPcent <= 40 then
                        Netherdamage = Toxindamage[Nethertoxin.level]*4
                    elseif HPcent > 0 and HPcent <= 20 then
                        Netherdamage = Toxindamage[Nethertoxin.level]*8
                    end
                    if Netherdamage then
                        damage = damage + Netherdamage
                    end
                end
            end           
            if me.classId == CDOTA_Unit_Hero_Ursa then
                local Furyswipes = me:GetAbility(3)
                local Furybuff = megaplayer.target:FindModifier("modifier_ursa_fury_swipes_damage_increase")
                local Furydamage = {15,20,25,30}
                
                if Furyswipes and Furyswipes.level > 0 and megaplayer.target.team ~= me.team then
                    if Furybuff then
                        damage = damage + Furydamage[Furyswipes.level]*Furybuff.stacks
                    else
                        damage = damage + Furydamage[Furyswipes.level]
                    end
                end
            end
            if me.classId == CDOTA_Unit_Hero_BountyHunter then
                local Jinada = me:GetAbility(2)
                local Jinadadamage = {1.5,1.75,2,2.25}
                
                if Jinada and Jinada.level > 0 and Jinada.cd == 0 and megaplayer.target.team ~= me.team then
                    damage = damage*(Jinadadamage[Jinada.level])
                end
            end            
            if me.classId == CDOTA_Unit_Hero_Weaver then
                local Gem = me:GetAbility(3)
                
                if Gem and Gem.level > 0 and Gem.cd == 0 then
                    damage = damage*1.8
                end
            end            
            if me.classId == CDOTA_Unit_Hero_Kunkka then
                local Tidebringer = me:GetAbility(2)
                local Tdamage = {15,30,45,60}
                
                if Tidebringer and Tidebringer.level > 0 and Tidebringer.cd == 0 then
                    damage = damage+(Tdamage[Tidebringer.level])
                end
            end        
            if target.classId == CDOTA_BaseNPC_Creep_Siege then
                damage = damage*0.5
            end
            if target.team == me.team and qblade then
                damage = me.dmgMin + me.dmgBonus
            end
            
            if NoSpam == true then                
                if Animations.isAttacking(me) and (target.health > (target:DamageTaken(damage,DAMAGE_PHYS,me))) then
                    megaplayer:HoldPosition()
                    print(damage)
                end
                me:Attack(target)
                Sleep(25, "stop")
            else
                target = nil
            end
            if NoSpam == false then
                if Animations.isAttacking(me) and (megaplayer.target.health > (megaplayer.target:DamageTaken(damage,DAMAGE_PHYS,me))) then
                    megaplayer:HoldPosition()
                    Sleep(25, "stop")
                else
                    return
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
        active = true
        toggleText.visible = false
        script:UnregisterEvent(Tick)
        script:UnregisterEvent(Key)
        script:RegisterEvent(EVENT_TICK,Load)
    end
end

script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Load)
