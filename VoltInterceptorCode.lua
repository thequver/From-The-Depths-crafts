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



LGDeployed = 1

function DeployLandingGear(I)
I:SetSpinBlockRotationAngle(10, -110)
I:SetSpinBlockRotationAngle(13, 70)
I:SetSpinBlockRotationAngle(14, 25)
I:SetSpinBlockRotationAngle(16, -70)
I:SetSpinBlockRotationAngle(17, -25)

I:SetPistonExtension(11, 2.8)
I:SetPistonExtension(15, 1.3)
I:SetPistonExtension(18, 1.3)
LGDeployed = 1
end
-----

function FoldLandingGear(I)
I:SetSpinBlockRotationAngle(10, 0)
I:SetSpinBlockRotationAngle(13, 0)
I:SetSpinBlockRotationAngle(14, 0)
I:SetSpinBlockRotationAngle(16, 0)
I:SetSpinBlockRotationAngle(17, 0)

I:SetPistonExtension(11, 0)
I:SetPistonExtension(15, 0)
I:SetPistonExtension(18, 0)
LGDeployed = 0
end
-----


function Stabilize(I, Delta, TargetControllerAdd, TargetControllerSubtract, Threshold, Multiplier, Addittion)
if I:GetAIMovementMode(0) == 'Off' and I:GetInput(2, TargetControllerAdd) < 1 and I:GetInput(2, TargetControllerSubtract) < 1 and (Threshold < Delta or Delta < -Threshold) then
  I:RequestControl(2, Delta < 0 and TargetControllerAdd or TargetControllerSubtract, Mathf.Clamp(Mathf.Abs(Delta) * Multiplier + Addittion, 0, 0.99))
 end
end
-----



T1 = 0
ExecuteLoop = 0

function Update(I)
I:ClearLogs()

AltAboveWaves = I:GetConstructPosition().y
AltAboveTerrain = AltAboveWaves - I:GetTerrainAltitudeForLocalPosition(0,0,0)
AltAboveSeaOrTerrain = Mathf.Min(AltAboveWaves, AltAboveTerrain)



--Y
Stabilize(I, I:GetLocalAngularVelocity().y, 1, 0, 0.02, 0.2, 0.1 * Mathf.Abs(I:GetLocalAngularVelocity().y) * (220 / I:GetForwardsVelocityMagnitude()))
--P
Stabilize(I, I:GetLocalAngularVelocity().x, 5, 4, 0.005, 0.3, 0.3 * Mathf.Abs(I:GetLocalAngularVelocity().x) * (220 / I:GetForwardsVelocityMagnitude()))
--R
Stabilize(I, I:GetLocalAngularVelocity().z, 2, 3, 0.02,  0.1, 0.1 * Mathf.Abs(I:GetLocalAngularVelocity().z) * (220 / I:GetForwardsVelocityMagnitude()))

--Gravity compensation (Pitch only)
if I:GetAIMovementMode(0) == 'Off' then
I:RequestControl(2, 4, 0.0003 * I:GetForwardsVelocityMagnitude())
end

--LG
if timer(I, 1.5) == 1 then
 if I:Component_GetFloatLogic(8, 0) == 1 then
   DeployLandingGear(I)
   else
   FoldLandingGear(I)
  end
end


--Rotate tail
TailInputR = 0
TailInputP = 0

if I:GetInput(2, 2) > I:GetInput(2, 3) then
  TailInputR = -I:GetInput(2, 2) else TailInputR = I:GetInput(2, 3)
 end
if I:GetInput(2, 4) > I:GetInput(2, 5) then
  TailInputP = -I:GetInput(2, 4) else TailInputP = I:GetInput(2, 5)
 end

I:SetSpinBlockRotationAngle(19, TailInputP * -10 + TailInputR * 5)
I:SetSpinBlockRotationAngle(20, TailInputP * 10 + TailInputR * 5)



--AI
if I:GetAIMovementMode(0) ~= "Off" then
 if timer(I, 1.5) == 1 then
  I:RequestControl(2, 8, I:GetNumberOfTargets(0) ~= 0 and 0.5 or 0.1)
  end

----LG
if AltAboveTerrain > 40 then
 I:Component_SetFloatLogic(8, 0, 0)
else
 I:Component_SetFloatLogic(8, 0, 1)
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


--Set priority enemy
 PriorityTargetIndex = 0

if I:GetNumberOfTargets(0) ~= 0 and flipflop(I, 2) == 1 then
 for i = 0, I:GetNumberOfTargets(0), 1 do
  if I:GetTargetInfo(0, i).Priority == 0 then
   PriorityTargetIndex = i
   end
  end
 end


--Check enemy
if I:GetTargetInfo(0, PriorityTargetIndex).Valid == true then
 PriortyTargetPos = I:GetTargetPositionInfo(0, PriorityTargetIndex)

  if PriortyTargetPos.Range < 500 and Vector3.Magnitude(PriortyTargetPos.Velocity) > I:GetForwardsVelocityMagnitude() - 100 and Mathf.Abs(PriortyTargetPos.Azimuth) > 150 and Mathf.Abs(PriortyTargetPos.Elevation) > 140 and Vector3.Dot(Vector3.Normalize(PriortyTargetPos.Velocity), I:GetConstructForwardVector()) > 0.85 then
   --I:LogToHud("!!!Enemy Lock!!!")
   ExecuteLoop = 1
   end

--Loop maneuver
 if ExecuteLoop == 1 and T1 < 80 then
  T1 = T1 + 1
  I:TellAiThatWeAreTakingControl()
  --I:RequestControl(2, 8, 0.05)
  I:RequestControl(2,4,1)
  else
  T1 = 0
  ExecuteLoop = 0
  end


 end

 end
end
