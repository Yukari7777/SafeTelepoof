local ACTIONS = GLOBAL.ACTIONS
local STRINGS = GLOBAL.STRINGS
local SendRPCToServer = GLOBAL.SendRPCToServer
local RPC = GLOBAL.RPC
local BufferedAction = GLOBAL.BufferedAction
local Vector3 = GLOBAL.Vector3
local EntityScript = GLOBAL.EntityScript
local TheInput = GLOBAL.TheInput
local UpvalueHacker = GLOBAL.require "tools/UpvalueHacker"

STRINGS.ACTIONS.CASTAOE.ORANGESTAFF = STRINGS.ACTIONS.BLINK.GENERIC

local mod_enabled = true
local mod_enabled_key = GetModConfigData("enabled_key")
TheInput:AddKeyDownHandler(GLOBAL[mod_enabled_key], function()
    if GLOBAL.ThePlayer ~= nil and GLOBAL.ThePlayer.components.talker ~= nil then 
		mod_enabled = not mod_enabled
		GLOBAL.ThePlayer.components.talker:Say("Safe Telepoof: "..(mod_enabled and "on" or "off"))
	end
end)

-- This is by far my best practice to override existing componentactions
-- since COMPONENT_ACTIONS is local variable and modded componentactions are stored in a different namespace.
local componentaction_point = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS").POINT
local _blinkstaff = componentaction_point.blinkstaff
componentaction_point.blinkstaff = function(inst, doer, pos, actions, right, target)
	if mod_enabled then
		if right then 
			if doer.HUD and doer.components.playercontroller and not doer.components.playercontroller:IsAOETargeting() then
				--@V2C: #FORGE_AOE_RCLICK *searchable*
				--      -Forge used to strip all r.click actions even before starting aoe targeting,
				--       so this early out was not needed until now.
				return 
			end
			
			local aoetargeting = inst.components.aoetargeting
			local mouseover = TheInput:GetWorldEntityUnderMouse()
			if aoetargeting ~= nil and aoetargeting:IsEnabled() 
			and (mouseover == nil or mouseover:HasTag("walkableplatform")) then -- This one has to be added it is not allowed to telepoof on object but CASTAOE has high priority enough to target it.
				local checker = {} -- instead of passing real actions, pass a fake table instead to check telepoof availability.
				_blinkstaff(inst, doer, pos, checker, right, target)
				if #checker > 0 then
					table.insert(actions, ACTIONS.CASTAOE) -- register CASTAOE instead; what actions inserted is how it interfaces.
				end
			end
		end
	else 
		_blinkstaff(inst, doer, pos, actions, right, target)
	end
end

AddComponentPostInit("playercontroller", function(self, inst)
	local _DoAction = self.DoAction
	self.DoAction = function(self, buffaction, ...)
		if buffaction.action == ACTIONS.CASTAOE 
		and (buffaction.invobject ~= nil and buffaction.invobject.prefab == "orangestaff") 
		and buffaction.pos ~= nil 
		and buffaction.pos.local_pt ~= nil then
			-- Convert CASTAOE to BLINK right before it sends to the server.
			local invobject = buffaction.invobject
			local platform, pos_x, pos_z = buffaction.pos.walkable_platform, buffaction.pos.local_pt.x, buffaction.pos.local_pt.z
			local mouseover = TheInput:GetWorldEntityUnderMouse()
			
			if self.locomotor == nil then 
				SendRPCToServer(RPC.RightClick, ACTIONS.BLINK.code, pos_x, pos_z, mouseover, nil, nil, nil, nil, nil, platform, platform ~= nil)
			elseif self:CanLocomote() and not self:IsBusy() then 
				-- Lag compensation(movement prediction) is on
				self.locomotor:Stop()
				self.inst:DoTaskInTime(0, function() 
					--Delay one frame if we just sent movement prediction so that
					--this RPC arrives a frame after the movement prediction 	
					local act = BufferedAction(GLOBAL.ThePlayer, mouseover, ACTIONS.BLINK, invobject, Vector3(pos_x, 0, pos_z))
					act.preview_cb = function() 
						SendRPCToServer(RPC.RightClick, ACTIONS.BLINK.code, pos_x, pos_z, mouseover, nil, nil, nil, nil, nil, platform, platform ~= nil)
					end
					self.locomotor:PreviewAction(act, true)
				end)
			end
		else 
			_DoAction(self, buffaction, ...)
		end
	end
end)

AddPrefabPostInit("orangestaff", function(inst)
	-- TODO: Controller suppport?
	-- if inst.components.reticule ~= nil then
	-- 	inst.components.reticule.targetfn = nil
	-- end

	inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAllowRiding(true)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticule"
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting:SetEnabled(false)
end) 