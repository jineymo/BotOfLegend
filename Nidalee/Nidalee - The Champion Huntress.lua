
require 'SourceLibk'

updater = SimpleUpdater("Nidalee - The Champion Huntress", VERSION, "raw.github.com" , "/kej1191/anonym/master/KOM/illaoi/illaoi%20-%20Warriors%20of%20the%20Rift.lua" , LIB_PATH .. "SourceLib_Fix.lua" , "/kej1191/anonym/master/KOM/illaoi/version.version" ):CheckUpdate()

function OnLoad()
	champ = Nidalee()
end

class 'Nidalee'
function Nidalee:__init()
	self.STS = SimpleTS(STS_NEARMOUSE)
	self.CBM = CallBackManager()
	
	self.Human = false
	self.huntMark = {first = false, second = false, third = false}
	self.enemyMinions = minionManager(MINION_ENEMY, 1000, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, 1000, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.AARange = myHero.range+myHero.boundingRadius
	self.ExtendedPounce	= 765
	
	self.hQ = {Range = 1500, Speed = 1285, Width = 45, Delay = 0.23, IsReady = false, Cooldown = 0}
	self.hW = {Range = 900, Speed = 1450, Delay = 0.5, Width = 80, IsReady = false, Cooldown = 0}
	self.hE = {Range = 600, IsReady = false, Cooldown = 0}
	self.cQ = {Range = myHero.range+myHero.boundingRadius, IsReady = false, Cooldown = 0}
	self.cW = {Range = 400, Speed = 0.5, Width = 95, Speed = 1500, IsReady = false, Cooldown = 0}
	self.cE = {Range = 375, IsReady = false, Cooldown = 0}
	
	self.Q = Spell(_Q, 0, SKILLSHOT_OTHER, 0)
	self.W = Spell(_W, 0, SKILLSHOT_OTHER, 0)
	self.E = Spell(_E, 0, SKILLSHOT_OTHER, 0)
	self.R = Spell(_R, 0, SKILLSHOT_OTHER, 0)
	
	--human Circle setting
	self.hQCircle = _Circle(myHero, self.hQ.Range, 1, {100, 255, 0, 0})
	self.hWCircle = _Circle(myHero, self.hW.Range, 1, {100, 255, 0, 0})
	self.hECircle = _Circle(myHero, self.hE.Range, 1, {100, 255, 0, 0})
	
	--Cougar Circle settings 
	self.cQCircle = _Circle(myHero, self.cQ.Range, 1, {100, 255, 0, 0})
	self.cWCircle = _Circle(myHero, self.cW.Range, 1, {100, 255, 0, 0})
	self.cECircle = _Circle(myHero, self.cE.Range, 1, {100, 255, 0, 0})
	
	self.Config = scriptConfig("Nidalee", "Nidalee")
		self.Config:addSubMenu(myHero.charName.." - OrbWalk settings", "OrbWalk")
		self.OBM = OrbWalkManager("Nidalee", self.Config.OrbWalk)
	
		self.Config:addSubMenu(myHero.charName.." - Combo settings", "Combo")
			self.Config.Combo:addParam("UsehQ", "Use human Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UsehW", "Use human W", SCRIPT_PARAM_LIST, 2, {"Always", "On Inmobile", "Disabled"})
			self.Config.Combo:addParam("UsecQ", "Use cougar Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UsecW", "Use cougar W", SCRIPT_PARAM_LIST, 2, {"Always", "if out of aa range", "disabled"})
			self.Config.Combo:addParam("UsecE", "Use cougar E", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		
		self.Config:addSubMenu(myHero.charName.." - Harass settings", "Harass")
			self.Config.Harass:addParam("UsehQ", "Use human Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("AutoR", "auto r when cougar", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
		
		self.Config:addSubMenu(myHero.charName.." - Skillshot settings", "SS")
			self.Config.SS:addSubMenu("Human Q", "Q")
			self.hQSpell = Spell(_Q, self.Config.SS.Q, SKILLSHOT_LINEAR, self.hQ.Range, self.hQ.Width, self.hQ.Delay, self.hQ.Speed, true)
			self.Config.SS:addSubMenu("Human W", "hW")
			self.hWSpell = Spell(_W, self.Config.SS.hW, SKILLSHOT_CIRCULAR, self.hW.Range, self.hW.Width, self.hW.Delay, self.hW.Speed, false)
			self.Config.SS:addSubMenu("Cougar W", "cW")
			self.cWSpell = Spell(_W, self.Config.SS.cW, SKILLSHOT_LINEAR, self.cW.Range, self.cW.Width, self.cW.Delay, self.cW.Speed, false)
		
		self.Config:addSubMenu(myHero.charName.." - Draw settings", "Draw")
			self.hQCircle:AddToMenu(self.Config.Draw, "Human Q circle setting", true, false, true)
			self.hWCircle:AddToMenu(self.Config.Draw, "Human W circle setting", true, false, true)
			self.hECircle:AddToMenu(self.Config.Draw, "Human E circle setting", true, false, true)
			self.cQCircle:AddToMenu(self.Config.Draw, "Cougar Q circle setting", true, false, true)
			self.cWCircle:AddToMenu(self.Config.Draw, "Cougar W circle setting", true, false, true)
			self.cECircle:AddToMenu(self.Config.Draw, "Cougar E circle setting", true, false, true)
			
	
	self.CBM:Tick(function() self:Tick() end)
	self.CBM:Draw(function() self:Draw() end)
	self.CBM:CreateObj(function(object) self:CreateObj(object) end)
	self.CBM:DeleteObj(function(object) self:DeleteObj(object) end)
	self.CBM:ProcessSpell(function(spell) self:UpdateCooldown(spell) end)
end

function Nidalee:Tick()
	-- target update
	if self.Human then
		self.target = self.STS:GetTarget(self.hQ.Range)
	else
		self.target = self.STS:GetTarget(500)
	end
	
	-- form detecter
	if self.Q:GetName() == "Takedown" or self.W:GetName() == "Pounce" or self.E:GetName() == "Swipe" then
		self.Human = false
	end
	if self.Q:GetName() == "JavelinToss" or self.W:GetName() == "Bushwhack" or self.E:GetName() == "PrimalSurge" then
		self.Human 	= true
	end
	
	-- Mode Tracker
	if self.OBM:IsComboMode() then
		self:Combo()
	end
	if self.OBM:IsHarassMode() then
		self:Harass()
	end
	if self.OBM:IsClearMode() then
		self:Clear()
	end
	
	-- buff hunt check
	if self.target and HasBuff(self.target, 'nidaleepassivehunted') and self.Human and (self.huntMark.first or self.huntMark.second or self.huntMark.third) and self.Config.Combo.UseR and GetDistance(self.target) < 600 then
		self.R:Cast()
	end
	if self.target then
		self.Point = (Vector(self.target) - Vector(myHero)):normalized() * self.cE.Range
	end
	
	-- Cooldown checker
	if (self.Human) then
		self.hQ.IsReady = self.Q:IsReady()
		self.hW.IsReady = self.W:IsReady()
		self.hE.IsReady = self.E:IsReady()
		self.cQ.IsReady = (self.Q:GetLevel() >= 1 and self.cQ.Cooldown - GetGameTimer() <=0 ) or false
		self.cW.IsReady = (self.W:GetLevel() >= 1 and self.cW.Cooldown - GetGameTimer() <=0 ) or false
		self.cE.IsReady = (self.E:GetLevel() >= 1 and self.cE.Cooldown - GetGameTimer() <=0 ) or false
	else
		self.hQ.IsReady = (self.Q:GetLevel() >= 1 and self.hQ.Cooldown - GetGameTimer() <=0 ) or false
		self.hW.IsReady = (self.W:GetLevel() >= 1 and self.hW.Cooldown - GetGameTimer() <=0 ) or false
		self.hE.IsReady = (self.E:GetLevel() >= 1 and self.hE.Cooldown - GetGameTimer() <=0 ) or false
		self.cQ.IsReady = self.Q:IsReady()
		self.cW.IsReady = self.W:IsReady()
		self.cE.IsReady = self.E:IsReady()
	end
end

function Nidalee:UpdateCooldown(spell)
	if self.Human then
		if (spell.name:lower() == "JavelinToss") then
			self.hQ.Cooldown = GetGameTimer() + GetSpellCooldown(6)
		elseif (spell.name:lower() == "Bushwhack") then
			self.hQ.Cooldown = GetGameTimer() + GetSpellCooldown(14 - (1 * myHero.level))
		elseif (spell.name:lower() == "PrimalSurge") then
			self.hQ.Cooldown = GetGameTimer() + GetSpellCooldown(12)
		end
	else
		if (spell.name:lower() == "Takedown") then
			self.cQ.Cooldown = GetGameTimer() + GetSpellCooldown(5)
		elseif (spell.name:lower() == "Pounce") then
			self.cQ.Cooldown = GetGameTimer() + GetSpellCooldown(5)
		elseif (spell.name:lower() == "Swipe") then
			self.cQ.Cooldown = GetGameTimer() + GetSpellCooldown(5)
		end
	end
end

function Nidalee:Draw()
	if self.Human then
		self.hQCircle:Draw()
		self.hWCircle:Draw()
		self.hECircle:Draw()
	else
		self.cQCircle:Draw()
		self.cWCircle:Draw()
		self.cECircle:Draw()
	end
end

function Nidalee:CreateObj(obj)
	if obj.name == "Nidalee_Base_Q_Tar.troy" then
		self.huntMark.first = true
	end
	if obj.name == "Nidalee_Base_Q_Buf.troy" then
		self.huntMark.second = true
	end
	if obj.name == "Nidalee_Base_P_Buf.troy" then
		self.huntMark.third = true
	end
end

function Nidalee:DeleteObj(obj)
	if obj.name == "Nidalee_Base_Q_Tar.troy" then
		self.huntMark.first = false
	end
	if obj.name == "Nidalee_Base_Q_Buf.troy" then
		self.huntMark.second = false
	end
	if obj.name == "Nidalee_Base_P_Buf.troy" then
		self.huntMark.third = false
	end
end

function Nidalee:Combo()
	if self.target ~= nil then
		if self.Human then
			-- Human mode
			if(self.Q:IsReady() and self.Config.Combo.UsehQ and GetDistance(self.target) < self.hQ.Range ) then
				self.hQSpell:Cast(self.target)
			end
			if(self.W:IsReady() and self.Config.Combo.UsehW < 3 and GetDistance(self.target) < self.hW.Range ) then
				if (self.Config.Combo.UsehW == 1) then
					self.hWSpell:Cast(self.target)
				elseif(self.Config.Combo.UsehW == 2) then
					self.hWSpell:CastIfImmobile(self.target)
				end
			end
			if(self.R:IsReady() and self.Config.Combo.UseR) then
				local first = false
				local swap = false
				if(self.Q:IsReady()) then
					first = true
				else
					first = true
				end
				if(first) then
					if (self.Config.Combo.UsecW and self.cW.IsReady) then
						if(self:InPounceRange(self.target)) then
							swap = true
						elseif (TargetHunted(self.target) and GetDistance(self.target) < self.ExtendedPounce) then
							swap = true
						end
					end
					if (self.Config.Combo.UsecQ and  self.cQ.IsReady and GetDistance(self.target) < self.cQ.Range) then
						swap = true
					elseif (self.Config.Combo.UsecE and self.cE.IsReady and GetDistance(self.target) <self.cE.Range ) then
						swap = true
					end
					if (swap) then
						self.R:IsReady()
						return
					end
				end
			end
		else
			-- Cougar mode
			if(self.Q:IsReady() and GetDistance(self.target) < self.cQ.Range ) then
				self.Q:Cast()
				self.OBM:ResetAA()
			end
			if(self.W:IsReady() and self.Config.Combo.UsecW <3) then
				if (self.Config.Combo.UsecW == 1) or ((self.Config.Combo.UsecW == 2) and (GetDistance(self.target) > self.AARange)) then
					if (self:InPounceRange(self.target)) then
						self.cWSpell:Cast(self.target)
					elseif(TargetHunted(self.target) and GetDistance(self.target)<self.ExtendedPounce) then
						self.cWSpell:Cast(self.target)
					end
				end
			end
			if (self.E:IsReady() and self.Config.Combo.UsecE and GetDistance(self.target) < self.cE.Range) then
				self.E:Cast(self.target.x, self.target.z)
			end
			if (self.R:IsReady() and self.Config.Combo.UseR) then
				if(self.hQ.IsReady and self.Config.Combo.UsehQ) then
					if (self.target.health <= self:CougarDamage(self.target) and GetDistance(self.target) < self.cW.Range) then
						return
					end
					if (self.hQSpell:WillHit(self.target)) then
						self.R:Cast()
						return
					end
				end
				if(not self.Q.IsReady() and not self.W.IsReady() and not self.E:IsReady() and not self.InPounceRange(self.target)) then
					self.R:Cast()
					return
				end
			end
		end
	end
end

function Nidalee:Harass()
	if self:IsManalow() then return end
	if self.Human then
		self.hQSpell:Cast(self.target)
	elseif not self.Human and self.Config.Harass.AutoR then
		self.R:Cast()
	end
end

function Nidalee:Clear()
	if self.Human then
		self.R:Cast()
	end
end

function TargetHunted(unit)
	return HasBuff(unit, 'nidaleepassivehunted')
	--return (UnitHasBuff(unit, "nidaleepassivehunted", true))
end

function Nidalee:IsManalow(mode)
	local mode = mode or "harass"
	if(mode == "combo") then
		return true
	elseif mode == "harass" then
		return ((myHero.mana / myHero.maxMana * 100) <= self.Config.Harass.ManaCheck)
	end
end

function Nidalee:InPounceRange(unit)
	return not (GetDistance(Vector(unit)) < (self.cW.Range - self.cW.Width)) -- and (GetDistance(unit) < (self.cW.Range + self.cW.Width))
end

function isFacing(source, target, lineLength)
	local sourceVector = Vector(source.visionPos.x, source.visionPos.z)
	local sourcePos = Vector(source.x, source.z)
	sourceVector = (sourceVector-sourcePos):normalized()
	sourceVector = sourcePos + (sourceVector*(GetDistance(target, source)))
	return GetDistanceSqr(target, {x = sourceVector.x, z = sourceVector.y}) <= (lineLength and lineLength^2 or 90000)
end

function GetSpellCooldown(cooldown)
	local cdr = myHero.cdr
	return (cooldown - (cooldown * cdr))
end
function Nidalee:CougarDamage(target)

	local damage = 0
	if (self.cQ.Cooldown < 1) then
		damage = damage + (getDmg("QM", target, myHero) or 0)
	end
	if (self.cQ.Cooldown < 1) then
		damage = damage + (getDmg("WM", target, myHero) or 0)
	end
	if (self.cQ.Cooldown < 1) then
		damage = damage + (getDmg("EM", target, myHero) or 0)
	end
	return damage
end