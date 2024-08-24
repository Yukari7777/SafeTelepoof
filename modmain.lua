local ACTIONS = GLOBAL.ACTIONS
local STRINGS = GLOBAL.STRINGS
local SendRPCToServer = GLOBAL.SendRPCToServer
local RPC = GLOBAL.RPC
local BufferedAction = GLOBAL.BufferedAction
local Vector3 = GLOBAL.Vector3
local EntityScript = GLOBAL.EntityScript
local TheInput = GLOBAL.TheInput
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local Prefabs = GLOBAL.Prefabs
local UpvalueHacker = GLOBAL.require "tools/UpvalueHacker"

STRINGS.ACTIONS.CASTAOE.ORANGESTAFF = STRINGS.ACTIONS.BLINK.GENERIC
STRINGS.ACTIONS.CASTAOE.SOUL = STRINGS.ACTIONS.BLINK.SOUL
STRINGS.ACTIONS.CASTAOE.FREESOUL = STRINGS.ACTIONS.BLINK.FREESOUL

local mod_enabled = true
local mod_enabled_key = GetModConfigData("enabled_key")
local enabled_orangestaff = true or GetModConfigData("orangestaff")
local enabled_soulhop = true or GetModConfigData("soulhop")
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
				--	  -Forge used to strip all r.click actions even before starting aoe targeting,
				--	   so this early out was not needed until now.
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
		and buffaction.pos ~= nil 
		and buffaction.pos.local_pt ~= nil
		and ((enabled_orangestaff and buffaction.invobject ~= nil and buffaction.invobject.prefab == "orangestaff")
			or (enabled_soulhop and buffaction.invobject == nil and self.inst:HasTag("soulstealer"))) then
			-- Convert CASTAOE to BLINK right before it sends to the server.
			local invobject = buffaction.invobject
			local platform, pos_x, pos_z = buffaction.pos.walkable_platform, buffaction.pos.local_pt.x, buffaction.pos.local_pt.z
			local mouseover = TheInput:GetWorldEntityUnderMouse()
			
			if self.locomotor == nil then 
				SendRPCToServer(RPC.RightClick, ACTIONS.BLINK.code, pos_x, pos_z, mouseover, nil, nil, nil, nil, nil, platform, platform ~= nil)
			elseif self:CanLocomote() and not self:IsBusy() then 
				-- Lag compensation(movement prediction) is on
				local act = BufferedAction(GLOBAL.ThePlayer, mouseover, ACTIONS.BLINK, invobject, Vector3(pos_x, 0, pos_z))
				act.preview_cb = function() 
					SendRPCToServer(RPC.RightClick, ACTIONS.BLINK.code, pos_x, pos_z, mouseover, nil, nil, nil, nil, nil, platform, platform ~= nil)
				end
				self.locomotor:PreviewAction(act, true)
			end
		else 
			_DoAction(self, buffaction, ...)
		end
	end
end)

GLOBAL.PA = nil
GLOBAL.CA = nil
AddComponentPostInit("playeractionpicker", function(self, inst)
	-- local _GetRightClickActions = self.GetRightClickActions
	-- self.GetRightClickActions = function(self, ...)
	-- 	local _actions = _GetRightClickActions(self, ...)
	-- 	if _actions == nil or #_actions <= 0 or not mod_enabled then 
	-- 		return _actions 
	-- 	end
	-- 	local actions = {}
	-- 	for k, buffaction in pairs(_actions) do
	-- 		local eqiupitem = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	-- 		if (enabled_orangestaff and equipitem ~= nil and equipitem.prefab == "orangestaff")
	-- 		or (enabled_soulhop and equipitem == nil and self.inst:HasTag("soulstealer")) then
	-- 			buffaction.action = ACTIONS.CASTAOE
	-- 			-- table.insert(actions, ACTIONS.CASTAOE)
	-- 		end
	-- 		table.insert(actions, buffaction)
	-- 	end
		
	-- 	return actions
	-- end

	-- This fix is needed because of `FORGE_AOE_RCLICK` issue(I assume).
	-- Instant client crash would occur from DoGetMouseActions
	-- local x, y, z = position:Get() (playeractionpicker.lua line 456)
	-- isaoetargeting is true but GetAOETargetingPos returns nil.
	-- I think nil safety needs to be applied on that line by Klei.
	local _DoGetMouseActions = self.DoGetMouseActions
	self.DoGetMouseActions = function(self, position, target, ...) 
		if self.inst.components.playercontroller:IsAOETargeting() and self.inst.components.playercontroller:GetAOETargetingPos() == nil then return end
		return _DoGetMouseActions(self, position, target, ...)
	end

	-- local _SortActionList = self.SortActionList
	-- self.SortActionList = function(self, ...)
	-- 	local ret = _SortActionList(self, ...)
	-- 	for k, v in pairs(ret) do
	-- 		for k2, v2 in pairs(v) do
	-- 			print(k2, v2)
	-- 		end
	-- 		GLOBAL.PA = GLOBAL.CA
	-- 		GLOBAL.CA = v
	-- 		print("------------------------")
	-- 	end

	-- 	return ret
	-- end


	local _SortActionList = self.SortActionList
	self.SortActionList = function(self, actions, target, useitem, ...)
		-- if actions ~= nil and #actions > 0 then
		-- 	for k, v in pairs(actions[1]) do
		-- 		print(k, v)
		-- 	end
		-- end
		-- if actions ~= nil and #actions > 0 and mod_enabled then 
		-- 	local new_actions = {}
		-- 	for k, act in pairs(actions) do
		-- 		if act == ACTIONS.BLINK
		-- 		and ((enabled_orangestaff and useitem ~= nil and useitem.prefab == "orangestaff") 
		-- 			or (enabled_soulhop and useitem == nil and self.inst:HasTag("soulstealer"))) then
		-- 			new_actions[k] = ACTIONS.CASTAOE
		-- 			-- table.insert(new_actions, ACTIONS.CASTAOE)
		-- 		else
		-- 			new_actions[k] = act
		-- 			-- table.insert(new_actions, act)
		-- 		end
		-- 	end
		-- 	actions = new_actions
		-- end
		-- print("========================")
		-- if actions ~= nil and #actions > 0 then
		-- 	for k, v in pairs(actions[1]) do
		-- 		print(k, v)
		-- 	end
		-- end
		-- print((actions ~= nil and #actions > 0) and actions[1], target, target ~= nil and target:is_a(EntityScript), target ~= nil and target:is_a(Vector3))
		ret = _SortActionList(self, actions, target, useitem, ...)
		-- for i, v in ipairs(ret) do
		-- 	print(i, v)
		-- end
		return ret
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
end) 

AddPrefabPostInit("wortox", function(inst)
	local _GetPointSpecialActions = UpvalueHacker.GetUpvalue(Prefabs.wortox.fn, "common_postinit", "OnSetOwner", "GetPointSpecialActions")
	local GetPointSpecialActions = function(...)
		local ret = _GetPointSpecialActions(...)
		if ret ~= nil and #ret > 0 then
			ret = { ACTIONS.CASTAOE }
		end
		return ret
	end
	UpvalueHacker.SetUpvalue(Prefabs.wortox.fn, GetPointSpecialActions, "common_postinit", "OnSetOwner", "GetPointSpecialActions")
end)