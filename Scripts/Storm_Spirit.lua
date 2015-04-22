require("libs.ScriptConfig")
require("libs.Utils")
require("libs.TargetFind")
require("libs.Animations")
require("libs.Skillshot")

local config = ScriptConfig.new()
config:SetParameter("Hotkey", "S", config.TYPE_HOTKEY)
config:Load()

local play = false local myhero = nil local victim = nil local attack = 0 local move = 0
local rate = client.screenSize.x/1600 local rec = {}
rec[1] = drawMgr:CreateRect(70*rate,26*rate,270*rate,60*rate,0xFFFFFF30,drawMgr:GetTextureId("NyanUI/other/CM_status_1")) rec[1].visible = false
rec[2] = drawMgr:CreateText(175*rate,52*rate,0xFFFFFF90,"Target :",drawMgr:CreateFont("manabarsFont","Arial",18*rate,700)) rec[2].visible = false
rec[3] = drawMgr:CreateRect(220*rate,54*rate,16*rate,16*rate,0xFFFFFF30) rec[3].visible = false

function Main(tick)
	if not PlayingGame() then return end
	local me = entityList:GetMyHero()
	local ID = me.classId if ID ~= myhero then return end
 	
	local victim = FindTarget(me.team)
	local numb = 90*rate+30*0*rate+65*rate
	rec[1].w = numb
	rec[2].x = 30*rate + numb - 95*rate
	rec[3].x = 80*rate + numb - 50*rate
	rec[3].textureId = drawMgr:GetTextureId("NyanUI/miniheroes/"..victim.name:gsub("npc_dota_hero_",""))

	for z = 1,3 do
		rec[z].visible = true
	end
	
	local attackRange = me.attackRange	

	if IsKeyDown(config.Hotkey) and not client.chat then	
		if not Animations.CanMove(me) and victim and GetDistance2D(me,victim) <= 2000 then
			if tick > attack and SleepCheck("casting") then
				if victim.hero and not Animations.isAttacking(me) then
                    local W = me:GetAbility(2)
					local R = me:GetAbility(4)
					local Overload = me:DoesHaveModifier("modifier_storm_spirit_overload")
					local Sheep = me:FindItem("item_sheepstick")
					local Orchid = me:FindItem("item_orchid")
					local Shivas = me:FindItem("item_shivas_guard")
                    local SoulRing = me:FindItem("item_soul_ring")
					local distance = GetDistance2D(victim,me)
                    local pull = victim:IsHexed() or victim:IsStunned()
                    local silenced = victim:IsSilenced()
                    local hex = victim:IsHexed()
                    local stunned = victim:IsStunned()
                    local linkens = victim:IsLinkensProtected()
					local balling = me:DoesHaveModifier("modifier_storm_spirit_ball_lightning")
                    
					if R and R:CanBeCasted() and me:CanCast() and distance > attackRange and not balling then
						local CP = R:FindCastPoint()
						local delay = CP*1000+client.latency+me:GetTurnTime(victim)*1000
						local speed = R:GetSpecialData("ball_lightning_move_speed", R.level)
						local xyz = SkillShot.SkillShotXYZ(me,victim,delay,speed)
						if xyz then
							me:CastAbility(R,xyz)
							Sleep(CP*1000+me:GetTurnTime(victim)*1000, "casting")
						end
					end
                    if SoulRing and SoulRing:CanBeCasted() and distance < attackRange then
                        me:CastAbility(SoulRing)
                        Sleep(me:GetTurnTime(victim)*1000, "casting")
                    end
                    if Sheep and Sheep:CanBeCasted() and not pull and not W:CanBeCasted() and not linkens then
						me:CastAbility(Sheep, victim)
						Sleep(me:GetTurnTime(victim)*1000, "casting")
					end
					if Orchid and Orchid:CanBeCasted() and not silenced then
						me:CastAbility(Orchid, victim)
						Sleep(me:GetTurnTime(victim)*1000, "casting")
					end
					if Shivas and Shivas:CanBeCasted() and distance < attackRange then
						me:CastAbility(Shivas)
						Sleep(me:GetTurnTime(victim)*1000, "casting")
					end				
				end
				me:Attack(victim)
				attack = tick + 100
			end
		elseif tick > move and SleepCheck("casting") then
			if victim and victim.hero and not Animations.isAttacking(me) then
				local Q = me:GetAbility(1)
                local W = me:GetAbility(2)
                local R = me:GetAbility(4)
                local Sheep = me:FindItem("item_sheepstick")
				local Orchid = me:FindItem("item_orchid")
				local Overload = me:DoesHaveModifier("modifier_storm_spirit_overload")
				local Dagon = me:FindDagon()
				local distance = GetDistance2D(victim,me)
                local pull = victim:IsHexed() or victim:IsStunned()   
                local linkens = victim:IsLinkensProtected()
                local balling = me:DoesHaveModifier("modifier_storm_spirit_ball_lightning")
                					
				if Dagon and Dagon:CanBeCasted() and me:CanCast() then
					me:CastAbility(Dagon, victim)
					Sleep(me:GetTurnTime(victim)*1000, "casting")
				end
				if not Overload then
                    if W and W:CanBeCasted() and me:CanCast() and distance <= W.castRange+100 and not pull and not linkens then
							me:CastAbility(W,victim)
							Sleep(W:FindCastPoint()*1000+me:GetTurnTime(victim)*1000,"casting")
						end
					if Q and Q:CanBeCasted() and me:CanCast() and distance < attackRange then
						me:CastAbility(Q)
						Sleep(client.latency,"casting")
					end
                    if R and R:CanBeCasted() and me:CanCast() and distance < attackRange then
						local CP = R:FindCastPoint()
						local delay = CP*1000+client.latency+me:GetTurnTime(victim)*1000
						local speed = R:GetSpecialData("ball_lightning_move_speed", R.level)
						local xyz = SkillShot.SkillShotXYZ(me,victim,delay,speed)
						if xyz then
							me:CastAbility(R,xyz)
							Sleep(CP*1000+me:GetTurnTime(victim)*1000, "casting")
						end
					end    
				end					
			end
			if victim then
				if victim.visible then
					local xyz = SkillShot.PredictedXYZ(victim,me:GetTurnTime(victim)*1000+client.latency+500)
					me:Move(xyz)
				else
					me:Follow(victim)
				end
			end
			move = tick + 100
		end
	end 
end

function FindTarget(teams)
	local enemy = entityList:GetEntities(function (v) return v.type == LuaEntity.TYPE_HERO and v.team ~= teams and v.visible and v.alive and not v.illusion end)
	if #enemy == 0 then
		return entityList:GetEntities(function (v) return v.type == LuaEntity.TYPE_HERO and v.team ~= teams end)[1]
	elseif #enemy == 1 then
		return enemy[1]	
	else
		local mouse = client.mousePosition
		table.sort( enemy, function (a,b) return GetDistance2D(mouse,a) < GetDistance2D(mouse,b) end)
		return enemy[1]
	end
end

function Load()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if me.classId ~= CDOTA_Unit_Hero_StormSpirit then 
			script:Disable() 
		else
			play = true
			victim = nil
			start = false
			myhero = me.classId
			script:RegisterEvent(EVENT_FRAME, Main)
			script:UnregisterEvent(Load)
		end
	end	
end

function Close()
	myhero = nil
	victim = nil
	start = false
	if play then
		script:UnregisterEvent(Main)
		script:RegisterEvent(EVENT_TICK,Load)
		play = false
	end
end

script:RegisterEvent(EVENT_CLOSE,Close)
script:RegisterEvent(EVENT_TICK,Load)
