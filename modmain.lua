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

-- This is by far my best practice to override existing componentactions
-- since COMPONENT_ACTIONS is local variable and modded componentactions are stored in a different namespace.
local componentactionpoint = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS").POINT
local _blinkstaff = componentactionpoint.blinkstaff
componentactionpoint.blinkstaff = function(inst, doer, pos, actions, right, target) 
	if right then 
		if doer.HUD and doer.components.playercontroller and not doer.components.playercontroller:IsAOETargeting() then
			return
		end
		
		local aoetargeting = inst.components.aoetargeting
		if aoetargeting ~= nil and aoetargeting:IsEnabled() then
			local checker = {} -- instead of passing real actions, pass a fake table instead to check telepoof availability.
			_blinkstaff(inst, doer, pos, checker, right, target)
			if #checker > 0 then
				table.insert(actions, ACTIONS.CASTAOE) -- register CASTAOE instead; what actions inserted is how it interfaces.
			end
		end
	end
end

AddComponentPostInit("playercontroller", function(self, inst)
	local _DoAction = self.DoAction
	self.DoAction = function(self, buffaction, ...)
		if buffaction.action == ACTIONS.CASTAOE and (buffaction.invobject ~= nil and buffaction.invobject.prefab == "orangestaff") then
			-- Convert CASTAOE to BLINK right before it sends to the server.
			local invobject = buffaction.invobject
			local platform, pos_x, pos_z = buffaction.pos.walkable_platform, buffaction.pos.local_pt.x, buffaction.pos.local_pt.z
			local mouseover = TheInput:GetWorldEntityUnderMouse()
			local act = BufferedAction(GLOBAL.ThePlayer, nil, ACTIONS.BLINK, invobject, Vector3(pos_x, 0, pos_z))
			
			SendRPCToServer(RPC.RightClick, ACTIONS.BLINK.code, pos_x, pos_z, mouseover, nil, nil, nil, nil, nil, platform, platform ~= nil)
			if not self:CanLocomote() then return end
			-- TODO: Test this case
			buffaction = act
		end
		return _DoAction(self, buffaction, ...)
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
    -- inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    -- inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
end) 