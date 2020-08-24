function sign(x)
  return x < 0 and -1 or 1
end
-----


--x - switching speed, 1 ~ 1sec, must be %2 = 0
function flipflop(I, x)
 return Mathf.Round(I:GetTime() * x) % 2 == 0 and 1 or 0
end
-----


--x - seconds before trigger
function timer(I, x)
 return Mathf.Round(I:GetTime() * 10) / 10 % x == 0 and 1 or 0
end
-----


function Lerp3(a, b, c, t)
local x, y, i

if 0 <= t and t < 0.5  then
 y = a
 i = b
 elseif 0.5 <= t and t <= 1  then
 y = b
 i = c
 end

x = y + t * (i - y)
return x
end
-----


function Lerp4(a, b, c, d, t)
local x, y, i

if 0 <= t and t < 0.25  then
 y = a
 i = b
 elseif 0.25 <= t and t < 0.5  then
 y = b
 i = c
 elseif 0.5 <= t and t <= 1  then
 y = c
 i = d
 end

x = y + t * (i - y)
return x
end
-----


function FindBlockindex(I, type, blockname)
--!!!blockname must be in ""
for i = 0, I:Component_GetCount(type) - 1 do
 if I:Component_GetBlockInfo(type,i).CustomName == blockname then
  x = i
  break
  end
 end
return x
end
-----


function Stabilize(I, Delta, TargetControllerAdd, TargetControllerSubtract, Threshold, Multiplier, Addittion)
if I:GetAIMovementMode(0) == 'Off' and I:GetInput(2, TargetControllerAdd) < 1 and I:GetInput(2, TargetControllerSubtract) < 1 and (Threshold < Delta or Delta < -Threshold) then
  I:RequestControl(2, Delta < 0 and TargetControllerAdd or TargetControllerSubtract, Mathf.Clamp(Mathf.Abs(Delta) * Multiplier + Addittion, 0, 0.99))
 end
end
-----


LGDeployed = 1

function DeployLandingGear(I)
 I:SetSpinBlockRotationAngle(12, -110)
 LGDeployed = 1
 end
-----


function FoldLandingGear(I)
 I:SetSpinBlockRotationAngle(12, 0)
 LGDeployed = 0
 end
-----


function Update(I)
I:ClearLogs()


AltAboveWaves = I:GetConstructPosition().y
AltAboveTerrain = AltAboveWaves - I:GetTerrainAltitudeForLocalPosition(0,0,0)
AltAboveSeaOrTerrain = Mathf.Min(AltAboveWaves, AltAboveTerrain)


--Find ID's
RedLampID = FindBlockindex(I, 30, "RedLamp")
WhiteLampID = FindBlockindex(I, 30, "WhiteLamp")
GreenLampID = FindBlockindex(I, 30, "GreenLamp")
CabinLampID = FindBlockindex(I, 30, "CabinLamp")
LGId = FindBlockindex(I, 8, "LG")
EngineId = FindBlockindex(I, 8, "Engine")

ForwardVelocity = I:GetForwardsVelocityMagnitude()
MainDrive = I:GetDrive(0)
MainDriveAbs = Mathf.Abs(MainDrive)
SteppedDrive = 0
if 0 <= MainDriveAbs and MainDriveAbs < 0.125 then
  SteppedDrive = 0
  elseif 0.125 <= MainDriveAbs and MainDriveAbs < 0.375 then
  SteppedDrive = 0.25
  elseif 0.375 <= MainDriveAbs and MainDriveAbs < 0.625 then
  SteppedDrive = 0.5
  elseif 0.625 <= MainDriveAbs and MainDriveAbs <= 1 then
  SteppedDrive = 1
  end
PitchFix = -MainDriveAbs * 0.3014
EngineStatus = I:Component_GetFloatLogic(8, EngineId)

--Stabilization
--Y
Stabilize(I, I:GetLocalAngularVelocity().y, 1, 0, 0.02, Mathf.Lerp(0.2, 0.2, MainDriveAbs), 0.1 * Mathf.Abs(I:GetLocalAngularVelocity().y) * (120 / ForwardVelocity))
--P
Stabilize(I, I:GetLocalAngularVelocity().x, 5, 4, 0.005, Mathf.Lerp(0.7, 0.2, MainDriveAbs), 0.2 * Mathf.Abs(I:GetLocalAngularVelocity().x) * (120 / ForwardVelocity))
--R
Stabilize(I, I:GetLocalAngularVelocity().z, 2, 3, 0.02, Mathf.Lerp(0.1, 0.05, MainDriveAbs), 0.1 * Mathf.Abs(I:GetLocalAngularVelocity().z) * (120 / ForwardVelocity))

--Gravity compensation (Pitch only)
if I:GetAIMovementMode(0) == 'Off' then
 I:RequestControl(2, 4, Mathf.Lerp(0, 0.03, MainDriveAbs))
 I:RequestControl(2, 5, Mathf.Lerp(0.3, 0, MainDriveAbs))
 end


--LG
if timer(I, 1.5) == 1 then
 if 
I:Component_GetFloatLogic(8, LGId) == 1 or EngineStatus == 0 then
   DeployLandingGear(I)
   I:Component_SetFloatLogic_1(30, CabinLampID, 2, 1) --R
   I:Component_SetFloatLogic_1(30, CabinLampID, 3, 0.7) --G
   I:Component_SetFloatLogic_1(30, CabinLampID, 4, 0.1) --B
   else
   FoldLandingGear(I)
   I:Component_SetFloatLogic_1(30, CabinLampID, 2, 0.4) --R
   I:Component_SetFloatLogic_1(30, CabinLampID, 3, 0.8) --G
   I:Component_SetFloatLogic_1(30, CabinLampID, 4, 1) --B
  end
end


--AI
if I:GetAIMovementMode(0) ~= "Off" then
 if timer(I, 1.5) == 1 then

  --Set priority enemy
  PriorityTargetIndex = 0

  if I:GetNumberOfTargets(0) ~= 0 then
   for i = 0, I:GetNumberOfTargets(0), 1 do
    if I:GetTargetInfo(0, i).Priority == 0 then
     PriorityTargetIndex = i
     break
     end
    end
 
   end


  if AltAboveSeaOrTerrain < 100 then   
   AIDrive = 0.25
   else
   AIDrive = I:GetNumberOfTargets(0) ~= 0 and (Mathf.Abs(I:GetTargetPositionInfo(0, PriorityTargetIndex).Azimuth) > 45 or I:GetTargetPositionInfo(0, PriorityTargetIndex).Range > 800) and 1 or 0.5
   end

  I:RequestControl(2, 8, AIDrive)
  --LG
  if AltAboveTerrain > 40 then
   I:Component_SetFloatLogic(8, LGId, 0)
   else
   I:Component_SetFloatLogic(8, LGId, 1)
   end

  end


 --Missile Avoidance

 --Set priority missile
 LastMissileScore = 0
 PriorityMissile = I:GetMissileWarning(0, 0)

 if I:GetNumberOfTargets(0) ~= 0 and flipflop(I, 2) == 1 then
  for i = 0, I:GetNumberOfWarnings(0), 1 do
   MissileIndex = I:GetMissileWarning(0, i)
   if MissileIndex.Valid == true then
    CalcScore = 1 / MissileIndex.Range
    if CalcScore > LastMissileScore then
     LastMissileScore = CalcScore
     PriorityMissile = MissileIndex
     end
    end
   end

  --I:LogToHud(LastMissileScore)
  end


 --Actions
  if PriorityMissile.Valid == true then

   --general
   if LastMissileScore > 0.005 then
    I:RequestControl(2, 8, 1)
    I:RequestControl(2, sign(PriorityMissile.Azimuth) < 0 and 1 or 0, 1)
    if AltAboveSeaOrTerrain > 110 then
     I:RequestControl(2, sign(PriorityMissile.Elevation) < 0 and 5 or 4, 1)
     end
    end

   --front
   if LastMissileScore > 0.003 and Mathf.Abs(PriorityMissile.Azimuth) < 45 then
    I:RequestControl(2, sign(PriorityMissile.Azimuth) < 0 and 1 or 0, 1)
    if AltAboveSeaOrTerrain > 110 then
     I:RequestControl(2, sign(PriorityMissile.Elevation) < 0 and 5 or 4, 1)
     end
    end

   --back
   if LastMissileScore > 0.005 and Mathf.Abs(PriorityMissile.Azimuth) > 135 then
    I:RequestControl(2, flipflop(I, 1), 1)
    if AltAboveSeaOrTerrain > 110 then
     I:RequestControl(2, flipflop(I, 1) < 0 and 5 or 4, 1)
      end
    end
   end

  end



--Engine
if EngineStatus == 1 then

 --Axis
 AxisAngle = Mathf.Lerp(0, 90, Mathf.Max(SteppedDrive * sign(MainDrive), 0)) + Mathf.Lerp(0, -90, -Mathf.Min(SteppedDrive * sign(MainDrive), 0))

 --Drive = 0 Axis controllers
 AYawControllerL = I:GetInput(2, 0) * 20
 AYawControllerR = I:GetInput(2, 1) * 20
 APitchController = (I:GetInput(2, 4) - I:GetInput(2, 5)) * 40
 ARollController = 0

 --Drive = 0.5 Axis controllers
 AYawControllerL0_5 = I:GetInput(2, 0) * 10
 AYawControllerR0_5 = I:GetInput(2, 1) * 10
 APitchController0_5 = (I:GetInput(2, 4) - I:GetInput(2, 5)) * 20
 ARollController0_5 = 0

 --Drive = 1 Axis controllers
 AYawControllerL1 = I:GetInput(2, 3) * 3
 AYawControllerR1 = I:GetInput(2, 2) * 3
 APitchController1 = 0
 ARollController1 = 0

 --Lerp
 AYL = Lerp3(AYawControllerL, AYawControllerL0_5, AYawControllerL1, SteppedDrive)
 AYR = Lerp3(AYawControllerR, AYawControllerR0_5, AYawControllerR1, SteppedDrive)
 AP = Lerp3(APitchController, APitchController0_5, APitchController1, SteppedDrive)
 AR = Lerp3(ARollController, ARollController0_5, ARollController1, SteppedDrive)

 I:SetSpinBlockRotationAngle(39, AYL - AP + AR +AxisAngle)
 I:SetSpinBlockRotationAngle(38, -AYR + AP + AR -AxisAngle)



 --Rotors L40, L41, R42, R43
 SpinRate = Mathf.Lerp(Mathf.Lerp(27, 10, I:Component_GetFloatLogic(8, LGId)), 30, SteppedDrive)
 I:SetSpinBlockPowerDrive(40, SteppedDrive * 10)
 I:SetSpinBlockPowerDrive(41, SteppedDrive * 10)
 I:SetSpinBlockPowerDrive(42, SteppedDrive * 10)
 I:SetSpinBlockPowerDrive(43, SteppedDrive * 10)


 --Drive = 0 Rotor controllers
 RYawController = (I:GetInput(2, 0) - I:GetInput(2, 1)) * 2.5
 RPitchController = (I:GetInput(2, 4) - I:GetInput(2, 5) + PitchFix) * 5
 RRollController = (I:GetInput(2, 2) - I:GetInput(2, 3)) * 2

 --Drive = 0.25 Rotor controllers
 RYawController0_25 = (I:GetInput(2, 0) - I:GetInput(2, 1)) * 7
 RPitchController0_25 = (I:GetInput(2, 4) - I:GetInput(2, 5) + PitchFix) * 5
 RRollController0_25 = (I:GetInput(2, 2) - I:GetInput(2, 3)) * 1

 --Drive = 0.5 Rotor controllers
 RYawController0_5 = (I:GetInput(2, 0) - I:GetInput(2, 1)) * -7
 RPitchController0_5 = (I:GetInput(2, 4) - I:GetInput(2, 5) + PitchFix) * 5
 RRollController0_5 = (I:GetInput(2, 2) - I:GetInput(2, 3)) * 1

 --Drive = 1 Rotor controllers
 RYawController1 = (I:GetInput(2, 0) - I:GetInput(2, 1)) * 10
 RPitchController1 = 0
 RRollController1 = 0

 --Lerp
 RY = Lerp4(RYawController, RYawController0_25, RYawController0_5, RYawController1, SteppedDrive)
 RP = Lerp4(RPitchController, RPitchController0_25, RPitchController0_5, RPitchController1, SteppedDrive)
 RR = Lerp4(RRollController, RRollController0_25, RRollController0_5, RRollController1, SteppedDrive)


 I:SetSpinBlockContinuousSpeed(40, SpinRate -RY +RP - RR)
 I:SetSpinBlockContinuousSpeed(41, -SpinRate +RY -RP + RR)
 I:SetSpinBlockContinuousSpeed(42, -SpinRate -RY -RP - RR)
 I:SetSpinBlockContinuousSpeed(43, SpinRate +RY +RP + RR)


 --Lights fix
 if timer(I, 3)
 == 1 then
  I:Component_SetFloatLogic(30, WhiteLampID, 10)
  I:Component_SetFloatLogic(30, RedLampID, 2)
  I:Component_SetFloatLogic(30, GreenLampID, 2)
  I:Component_SetFloatLogic(30, CabinLampID, 0.6)

  I:Component_SetFloatLogic_1(30, RedLampID, 2, 1) --R
  I:Component_SetFloatLogic_1(30, RedLampID, 3, 0.15) --G
  I:Component_SetFloatLogic_1(30, RedLampID, 4, 0.15) --B

  I:Component_SetFloatLogic_1(30, GreenLampID, 2, 0.15) --R
  I:Component_SetFloatLogic_1(30, GreenLampID, 3, 1) --G
  I:Component_SetFloatLogic_1(30, GreenLampID, 4, 0.15) --B

  I:Component_SetFloatLogic_1(30, WhiteLampID, 2, 0.9) --R
  I:Component_SetFloatLogic_1(30, WhiteLampID, 3, 0.85) --G
  I:Component_SetFloatLogic_1(30, WhiteLampID, 4, 1) --B
  else
  I:Component_SetFloatLogic(30, WhiteLampID, 0)
  end


 else
 if timer(I, 1.5)
 == 1 then
  --Reset rotation
  I:SetSpinBlockRotationAngle(38, 0)
  I:SetSpinBlockRotationAngle(39, 0)

  I:SetSpinBlockContinuousSpeed(40, 0)
  I:SetSpinBlockContinuousSpeed(41, 0)
  I:SetSpinBlockContinuousSpeed(42, 0)
  I:SetSpinBlockContinuousSpeed(43, 0)

  --Disable lights
  I:Component_SetFloatLogic(30, WhiteLampID, 0)
  I:Component_SetFloatLogic(30, RedLampID, 0)
  I:Component_SetFloatLogic(30, GreenLampID, 0)
  I:Component_SetFloatLogic(30, CabinLampID, 0)
  end
 end


end