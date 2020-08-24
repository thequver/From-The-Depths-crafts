function sign(x)
return x < 0 and -1 or 1
end
-----


function NormalizeRange(x, Min, Max)
return (x - Min) / (Max - Min)
end
-----


function Lerp3(a, b, c, t)
local x = a + t * (b - a)
local y = b + t * (c - b)
return x + t * (y - x)
end
-----


--!!!blockname must be in ""
function FindBlockindex(I, type, blockname)
local x = -1
for i = 0, I:Component_GetCount(type) - 1 do
 if I:Component_GetBlockInfo(type,i).CustomName == blockname then
  x = i
  break
  end
 end
return x
end
-----


Frame = 0

--a - amount of triggering frames,  b - frames to wait to end the loop, values must be int
function PreciseTimer(I, a, b)
return Mathf.Repeat(Frame, a + b + 1) < a and 1 or 0
end
-----


function DeployLandingGear(I)
I:SetSpinBlockRotationAngle(8, -20)
I:SetSpinBlockRotationAngle(11, -5)
end
-----


function FoldLandingGear(I)
I:SetSpinBlockRotationAngle(8, 75)
I:SetSpinBlockRotationAngle(11, -85)

end
-----


function Stabilize(I, Delta, TargetControllerAdd, TargetControllerSubtract, Threshold, Multiplier, Addittion)
if I:GetAIMovementMode(0) == "Off" and I:GetInput(2, TargetControllerAdd) < 1 and I:GetInput(2, TargetControllerSubtract) < 1 and (Threshold < Delta or Delta < -Threshold) then
 I:RequestControl(2, Delta < 0 and TargetControllerAdd or TargetControllerSubtract, Mathf.Clamp(Mathf.Abs(Delta) * Multiplier + Addittion, 0, 0.99))
 end
end
-----


T1 = 0
ExecuteLoop = 0

CabinLampAID = -1
CabinLampBID = -1
EngineLightID = -1

function Update(I)
I:ClearLogs()
Frame = Frame < 1000000 and Frame + 1
 or 0


AltAboveWaves = I:GetConstructPosition().y
AltAboveTerrain = AltAboveWaves - I:GetTerrainAltitudeForLocalPosition(0,0,0)
AltAboveSeaOrTerrain = Mathf.Min(AltAboveWaves, AltAboveTerrain)

Drive = I:GetDrive(0)
ForwardsVelocity = I:GetForwardsVelocityMagnitude()
AngularVelocity = I:GetLocalAngularVelocity()

--Find ID's
if PreciseTimer(I, 1, 80) == 1 then
 CabinLampAID = FindBlockindex(I, 30, "CabinLightA")
 CabinLampBID = FindBlockindex(I, 30, "CabinLightB")
 EngineLightID = FindBlockindex(I, 30, "EngineLight")
 end


--Y
Stabilize(I, AngularVelocity.y, 1, 0, 0.005, 0.4, 0.3 * Mathf.Abs(AngularVelocity.y) * (230 / ForwardsVelocity))

--P
Stabilize(I, AngularVelocity.x, 5, 4, 0.005, 0.4, 0.3 * Mathf.Abs(AngularVelocity.x) * (230 / ForwardsVelocity))

--R
Stabilize(I, AngularVelocity.z, 2, 3, 0.005,  0.3, 0.1 * Mathf.Abs(AngularVelocity.z) * (230 / ForwardsVelocity))

--Gravity compensation (Pitch only)
if I:GetAIMovementMode(0) == 'Off' then
 I:RequestControl(2, 5, 0.0004 * ForwardsVelocity)
 end

--LG
if PreciseTimer(I, 1, 40) == 1 then
 if I:Component_GetFloatLogic(8, 0) == 1 then
   DeployLandingGear(I)
   else
   FoldLandingGear(I)
  end
 end


--AI
if I:GetAIMovementMode(0) ~= "Off" then
 if PreciseTimer(I, 1, 10) == 1 then
  I:RequestControl(2, 8, I:GetNumberOfTargets(0) ~= 0 and 0.5 or 0.05)

--LG
  if AltAboveTerrain > 40 then
   I:Component_SetFloatLogic(8, 0, 0)
   else
   I:Component_SetFloatLogic(8, 0, 1)
   end
  end


--Missile Avoidance
--Set priority missile
 LastMissileScore = 0
 PriorityMissile = I:GetMissileWarning(0, 0)

if I:GetNumberOfWarnings(0) ~= 0 then
 for i = 0, I:GetNumberOfWarnings(0), 1 do
  local MissileIndex = I:GetMissileWarning(0, i)
  if MissileIndex.Valid == true and MissileIndex.Range < 2000 then
   local CalcScore = (1 / MissileIndex.Range)
 * Mathf.Lerp(2, 1, NormalizeRange(Mathf.Abs(MissileIndex.Azimuth), 0 , 180)) * Mathf.Lerp(1, 2, NormalizeRange(Mathf.Clamp(MissileIndex.Velocity.magnitude, 0 , 230), 0, 230))
   if CalcScore > LastMissileScore then
    LastMissileScore = CalcScore
    PriorityMissile = MissileIndex
    end
   end
  end
 --I:LogToHud(LastMissileScore)
 end


--Actions
ControlStrength = 1
MaxAltitude = 400
MaxPitch = 45
if PriorityMissile.Valid == true then
--general/front
 if LastMissileScore > Mathf.Lerp(0.003, 0.005, NormalizeRange(Mathf.Abs(PriorityMissile.Azimuth), 0, 180)) then
  
I:RequestControl(2, 8, Mathf.Lerp(0.5, 1, NormalizeRange(Mathf.Abs(PriorityMissile.Azimuth), 0, 180)))
  I:RequestControl(2, sign(PriorityMissile.Azimuth) < 0 and 1 or 0, ControlStrength)
  I:RequestControl(2, sign(PriorityMissile.Elevation) < 0 and 5 or 4, AltAboveSeaOrTerrain > 150 and AltAboveSeaOrTerrain < MaxAltitude and Mathf.Abs(I:GetConstructPitch()) < MaxPitch and ControlStrength or 0)
  end

--back
 if LastMissileScore > 0.005 and Mathf.Abs(PriorityMissile.Azimuth) > 135 then
  I:RequestControl(2, PreciseTimer(I, 1, 20) == 1 and 1 or 0, ControlStrength * 0.3)
  I:RequestControl(2, PreciseTimer(I, 1, 20) == 1 and 5 or 4, AltAboveSeaOrTerrain > 150 and AltAboveSeaOrTerrain < MaxAltitude and Mathf.Abs(I:GetConstructPitch()) < MaxPitch and ControlStrength * 0.3 or 0)
  end

 end


--Set priority enemy
 PriorityTargetIndex = 0

if I:GetNumberOfTargets(0) ~= 0 and PreciseTimer(I, 1, 20) == 1 then
 for i = 0, I:GetNumberOfTargets(0), 1 do
  if I:GetTargetInfo(0, i).Priority == 0 then
   PriorityTargetIndex = i
   break
   end
  end
 end


--Check enemy
if I:GetTargetInfo(0, PriorityTargetIndex).Valid == true then
 PriortyTargetPos = I:GetTargetPositionInfo(0, PriorityTargetIndex)

 if PriortyTargetPos.Range < 600 and Vector3.Magnitude(PriortyTargetPos.Velocity) > ForwardsVelocity - 100 and Mathf.Abs(PriortyTargetPos.Azimuth) > 150 and Mathf.Abs(PriortyTargetPos.Elevation) > 140 and Vector3.Dot(Vector3.Normalize(PriortyTargetPos.Velocity), I:GetConstructForwardVector()) > 0.7 then
  --I:LogToHud("!!!Enemy Lock!!!")
  ExecuteLoop = 1
  end

--Loop maneuver
 if ExecuteLoop == 1 and T1 < 80 and AltAboveSeaOrTerrain > 150 and AltAboveSeaOrTerrain < MaxAltitude then
  T1 = T1 + 1
  I:TellAiThatWeAreTakingControl()
  --I:RequestControl(2, 8, 0.05)
  I:RequestControl(2,4,1)
  else
  T1 = 0
  ExecuteLoop = 0
  end

--Wobbling
 if ExecuteLoop == 0 and PriortyTargetPos.Range >= 600 and PriortyTargetPos.Range < 900 and Vector3.Magnitude(PriortyTargetPos.Velocity) > ForwardsVelocity - 100 and Mathf.Abs(PriortyTargetPos.Azimuth) > 150 and Mathf.Abs(PriortyTargetPos.Elevation) > 140 and Vector3.Dot(Vector3.Normalize(PriortyTargetPos.Velocity), I:GetConstructForwardVector()) > 0.5 then
  I:RequestControl(2, PreciseTimer(I, 1, 20) == 1 and 2 or 3, 1)
  I:RequestControl(2, PreciseTimer(I, 1, 10), 1)
  I:RequestControl(2, PreciseTimer(I, 1, 10) == 1 and 5 or 4, AltAboveSeaOrTerrain > 150 and AltAboveSeaOrTerrain < MaxAltitude and Mathf.Abs(I:GetConstructPitch()) < MaxPitch and 1 or 0)
  end


 end

 end

--Lights
I:Component_SetFloatLogic(30, EngineLightID, (
Drive > 0.01 and Lerp3(3, 6, 8, Drive) or 0) * (PreciseTimer(I, Mathf.Round(Mathf.Lerp(5, 2, Drive)), Mathf.Round(Mathf.Lerp(5, 3, Drive))) == 1 and 1 or Mathf.Lerp(1.05, 1.1, Drive)) * (I:GetFuelFraction() > 0.005 and 1 or 0))
I:Component_SetFloatLogic(30, CabinLampAID, I:GetNumberOfTargets(0) ~= 0 and 0 or 4)
I:Component_SetFloatLogic(30, CabinLampBID, I:GetNumberOfTargets(0) ~= 0 and 0 or 4)

I:Component_SetFloatLogic_1(30, EngineLightID, 2, Lerp3( 1, 0.7, 0.7, 
Drive)) --R
I:Component_SetFloatLogic_1(30, EngineLightID, 3, Lerp3( 0.6, 0.6, 0.6, 
Drive)) --G
I:Component_SetFloatLogic_1(30, EngineLightID, 4, Lerp3( 0.3, 1, 1, 
Drive)) --B

I:Component_SetFloatLogic_1(30, CabinLampAID, 2, 0.9) --R
I:Component_SetFloatLogic_1(30, CabinLampAID, 3, 0.8) --G
I:Component_SetFloatLogic_1(30, CabinLampAID, 4, 1) --B

I:Component_SetFloatLogic_1(30, CabinLampBID, 2, 0.85) --R
I:Component_SetFloatLogic_1(30, CabinLampBID, 3, 0.7) --G
I:Component_SetFloatLogic_1(30, CabinLampBID, 4, 1) --B
end
