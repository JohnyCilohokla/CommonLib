-- CommonLib
include("Scripts/CL/CL.lua")

-------------------------------------------------------------------------------
if CommonLib == nil then
	CommonLib = EternusEngine.ModScriptClass.Subclass("CommonLib")
end

-------------------------------------------------------------------------------
function CommonLib:Constructor( )
	CL.println("Initializing CommonLib")
	
	self.hitObj = nil
	self.m_connectorCallback = include("Scripts/Callbacks/ConnectorSystem.lua").new()
end

function CommonLib:PostLoad( )
	EternusEngine.CallbackManager:RegisterCallback("SurvivalPlacementInput:ProcessGhostObjectOverride",self.m_connectorCallback,"ProcessGhostObjectOverride")
	EternusEngine.CallbackManager:RegisterCallback("SurvivalPlacementLogic:ServerEvent_PlaceAt",self.m_connectorCallback,"ServerEvent_PlaceAt")
end

 -------------------------------------------------------------------------------
 -- Called once from C++ at engine initialization time
function CommonLib:Initialize()
	if Eternus.IsClient then
		include("Scripts/CL/UI/DebuggingBox.lua")
		CEGUI.SchemeManager:getSingleton():createFromFile("CL.scheme")

		Eternus.GameState:RegisterSlashCommand("CommonLib", self, "Info")
		Eternus.GameState:RegisterSlashCommand("JSONTest", self, "JSONTest")
		Eternus.GameState:RegisterSlashCommand("Args", self, "Args")
		Eternus.GameState:RegisterSlashCommand("LuaStrict", self, "LuaStrict")
		Eternus.GameState:RegisterSlashCommand("Heal", self, "Heal")
		Eternus.GameState:RegisterSlashCommand("ApplyBuff", self, "ApplyBuff")
		
		self.cl_debuggingBox = CL_DebuggingBox.new("SurvivalLayout.layout")
		self.cl_debuggingBox:SetSize(0.2, 0.2)
		self.cl_debuggingBox:SetPosition(0.8, 0.0, -10, 10)
		self.cl_debuggingBox:SetText("Here! I'm over here! Notice me!")
		
		self.m_inputContext = InputMappingContext.new("CommonLib")
		self.m_inputContext:NKRegisterNamedCommand("CL Toggle Placement Mode", self.m_connectorCallback, "TogglePlacementMode", KEY_ONCE)
	end
end

function CommonLib:ApplyBuff(args)
	if args[1] then --Have a name.
		local buffName = args[1]
		
		if EternusEngine.BuffManager.m_buffs[buffName] then
			local value = -1
			if args[2] then
				value = tonumber(args[2])
			end
			if value or value >= 0 then
				local duration = -1
				if args[3] then
					duration = tonumber(args[3])
				end
				if duration or duration >= 0 then
					local newBuff = EternusEngine.BuffManager:CreateBuff(buffName, {duration = duration, value = value, stacks = false})
					Eternus.GameState.player:ApplyBuff(newBuff)
					Eternus.CommandService:NKAddLocalText("Applying buff " .. buffName .. "!\n")
				else
					Eternus.CommandService:NKAddLocalText("Invalid duration!\n")
				end
			else
				Eternus.CommandService:NKAddLocalText("Invalid value!\n")
			end
		else
			Eternus.CommandService:NKAddLocalText("" .. buffName .. " doesn't exist!\n")
		end
	end
	Eternus.CommandService:NKAddLocalText("Syntax: /ApplyBuff [name] [value] [duration]\n")
	return true
end

-------------------------------------------------------------------------------
-- Enables Strict Lua warnings
function CommonLib:LuaStrict( args )
    EnableLuaDebugLibrary = 0
    require("Scripts.Libs.strict")
    -- todo: Create a hook so mods can ignore globals when actually needed
    -- Globals( "Ball" ) 
end

-------------------------------------------------------------------------------
-- Called from C++ when the current game enters 
function CommonLib:LocalPlayerReady(player)	
	CL.println("CommonLib:LocalPlayerReady")
	
	player.m_targetAcquiredSignal:Add(function(hitObj)
		if hitObj then
			self.hitObj = hitObj
		end
	end)
	
	player.m_targetLostSignal:Add(function()
		self.hitObj = nil
	end)
end

-------------------------------------------------------------------------------
-- Called from C++ when the current game enters 
function CommonLib:Enter()	
	NKWarn("CommonLib>> Enter")
	if Eternus.IsClient then
		self.cl_debuggingBox:Show()
		
		Eternus.InputSystem:NKPushInputContext(self.m_inputContext)
	end
end

-------------------------------------------------------------------------------
-- Called from C++ when the game leaves it current mode
function CommonLib:Leave()
	NKWarn("CommonLib>> Enter")
	if Eternus.IsClient then
		self.cl_debuggingBox:Hide()
		
		Eternus.InputSystem:NKRemoveInputContext(self.m_inputContext)
	end
end


-------------------------------------------------------------------------------
-- Called from C++ every update tick
function CommonLib:Process(dt)
	if Eternus.IsClient then
		if self.hitObj then
			local out = self.hitObj:NKGetDisplayName()
			
			
			if (self.hitObj.GetMaxStackCount and self.hitObj:GetMaxStackCount() > 1) then
				out = out .. ("\n" .. self.hitObj:GetStackCount() .." / " .. self.hitObj:GetMaxStackCount())
			end
			
			local traceEquipable = self.hitObj:NKGetEquipable()
			if (traceEquipable ~= nil) then
				out = out .. ("\n{" .. traceEquipable:NKGetCurrentDurability() .." / " .. traceEquipable:NKGetMaxDurability() .. "}")
			end
			
			if (self.hitObj.GetDebuggingText ~= nil) then
				out = out .. ("\n" .. self.hitObj:GetDebuggingText() .."")
			end
			if (self.hitObj.NKGetName ~= nil) then
				out = out .. ("\n(" .. self.hitObj:NKGetName() ..")")
			end
			self.cl_debuggingBox:SetText(out)
		else
			self.cl_debuggingBox:SetText("No object selected")
			self.hitObj = nil
		end
	end
	
	--[[local location = vec3.new(49880.0, 155.0, 50015.0);
	
	RDU.NKDisplayLine(location + vec3.new(0.0, 0.0, 0.0), location + vec3.new(0.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(0.0, 4.0, 0.0), location + vec3.new(4.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 4.0, 0.0), location + vec3.new(4.0, 0.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 0.0, 0.0), location + vec3.new(0.0, 0.0, 0.0), RDU.eRED)
	
	location = vec3.new(49884.0, 155.0, 50018.0);
	
	RDU.NKDisplayLine(location + vec3.new(0.0, 0.0, 0.0), location + vec3.new(0.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(0.0, 4.0, 0.0), location + vec3.new(4.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 4.0, 0.0), location + vec3.new(4.0, 0.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 0.0, 0.0), location + vec3.new(0.0, 0.0, 0.0), RDU.eRED)
	]]
end

function CommonLib:Info(args)
	CL.println("CommonLib:Info")
end

function CommonLib:JSONTest(args)

	if args[1] then --Have a name.
		local fileName = args[1]
		local data = JSON.parseFile(fileName)
		NKWarn("data: " .. EternusEngine.Debugging.Inspect(data) .. "\n")
	end

	--[[CL.println("CommonLib:JSONTest")
	local tbl = {
	  animals = { "dog", "cat", "aardvark" },
	  instruments = { "violin", "trombone", "theremin" },
	  bugs = CL.json.null,
	  trees = nil
	}
	local str = CL.jsonEncode(tbl);
	local tbl2 = CL.jsonDecode(str);
	NKWarn("tbl: " .. EternusEngine.Debugging.Inspect(tbl) .. "\n")
	NKWarn("str: " .. str .. "\n")
	NKWarn("tbl2: " .. EternusEngine.Debugging.Inspect(tbl2) .. "\n")]]
end

function CommonLib:Heal(args)
	local player = Eternus.GameState:GetPlayerInstance()
	player.m_health = player.m_maxHealth
	player.m_stamina = player.m_maxStamina
	player.m_energy = player.m_maxEnergy
end

function CommonLib:Args(args)
	local out = ""
	table.foreach(args, function(k,v) out = out .. "" .. k .. "=" .. v .. ", " end)
	CL.println("CommonLib:Info")
	self.cl_debuggingBox:SetText(out)
end

EntityFramework:RegisterModScript(CommonLib)