function sign(x)
  return x < 0 and -1 or 1
end
-----


function flipflop(I, x) --x - switching speed, 1 ~ 1sec, must be %2 = 0
if Mathf.Round(I:GetTime() * x) % 2 == 0 or Mathf.Round(I:GetTime() * x) % 2 == nil then
 return 0
 else
 return 1
end
end
-----


function FindBlockindex(I, type, blockname)
--type - component type, blockname - custom name, must be in ''
 --!!DON'T FORGET!!
for i = 0, I:Component_GetCount(type) - 1 do
 if I:Component_GetBlockInfo(type,i).CustomName == blockname then
 x = i
 break
 end
end
return x
end
-----


LGDeployed = 1

function DeployLandingGear(I)
I:SetSpinBlockRotationAngle(21, -22)
I:SetSpinBlockRotationAngle(22, 22)
I:SetSpinBlockRotationAngle(25, 22)
I:SetSpinBlockRotationAngle(26, -22)
I:SetSpinBlockRotationAngle(28, 120)

I:SetPistonExtension(23, 3)
I:SetPistonExtension(27, 3)
I:SetPistonExtension(29, 2)
LGDeployed = 1
end
-----

function FoldLandingGear(I)
I:SetSpinBlockRotationAngle(21, 0)
I:SetSpinBlockRotationAngle(22, 90)
I:SetSpinBlockRotationAngle(25, 0)
I:SetSpinBlockRotationAngle(26, -90)
I:SetSpinBlockRotationAngle(28, 0)

I:SetPistonExtension(23, 0)
I:SetPistonExtension(27, 0)
I:SetPistonExtension(29, 0)
LGDeployed = 0
end
-----


Yaw = 0
Yaw2 = 0

function YawStabilize(I)

if flipflop(I, 100) == 1 then
  Yaw = I:GetConstructYaw()
  DeltaYaw = I:GetConstructYaw() - Yaw2
  else
  Yaw2 = I:GetConstructYaw()
  DeltaYaw = I:GetConstructYaw() - Yaw
 end

if DeltaYaw < -0.02 or 0.02 < DeltaYaw  then
  I:RequestControl(2,0,sign(DeltaYaw))
 end

end
-----


function LightStrobbling(I, x)
-- x = true/false - on/off strobbling

--find proper id
id = FindBlockindex(I, 30, 'CabL')

if x == true then
 I:Component_SetFloatLogic_1(30, id, 2, 1) --R
 I:Component_SetFloatLogic_1(30, id, 3, 0) --G
 I:Component_SetFloatLogic_1(30, id, 4, 0) --B

 if flipflop(I, 4) == 0 then
  I:Component_SetFloatLogic_1(30, id, 0, 0)
  else
  I:Component_SetFloatLogic_1(30, id, 0, 5)
 end

 else
 I:Component_SetFloatLogic_1(30, id, 0, 2)

 I:Component_SetFloatLogic_1(30, id, 2, 0) --R
 I:Component_SetFloatLogic_1(30, id, 3, 1) --G
 I:Component_SetFloatLogic_1(30, id, 4, 1) --B
end
end
-----


function TextStrobbling(I, blockname, x, EndCondition)
--blockname - custom name, must be in '', x = true/false - on/off strobbling, EndCondition = true/false - enable or disable text after exec

--find proper id
blockindex = FindBlockindex(I, 33, blockname)

if x == true then
 if flipflop(I, 4) == 0 then
  I:Component_SetBoolLogic(33, blockindex, false)
  else
  I:Component_SetBoolLogic(33, blockindex, true)
 end
else
 I:Component_SetBoolLogic(33, blockindex, EndCondition)
end
end
-----


function PitchRulerUpdate(I)
id = FindBlockindex(I, 33, 'PitchRuler')

P = I:GetConstructPitch() * -0.07
PR = Mathf.Min(-0.6, Mathf.Max(-2.2, Mathf.LerpUnclamped(-1.4, -2.6, P)))

I:Component_SetFloatLogic_1(33, id, 4, PR - 0.466)

end
-----


function RollRulerUpdate(I)
id = FindBlockindex(I, 33, 'RollRuler')
if I:GetConstructRoll() > 90 then
 R = I:GetConstructRoll() - 360
 else
 R = I:GetConstructRoll()
end

I:Component_SetFloatLogic_1(33, id, 7, Mathf.Clamp(-R, -90, 90))
end
-----


function Update(I)
I:ClearLogs()

AltAboveWaves = I:GetConstructPosition().y
AltAboveTerrain = AltAboveWaves - I:GetTerrainAltitudeForLocalPosition(0,0,0)
AltAboveSeaOrTerrain = Mathf.Min(AltAboveWaves, AltAboveTerrain)

--Rulers
if AltAboveWaves < 1100 then
 I:Component_SetBoolLogic(33, FindBlockindex(I, 33, 'SpaceHUD'), false)
 I:Component_SetBoolLogic(33, FindBlockindex(I, 33, 'PitchRuler'), true)
 I:Component_SetBoolLogic(33, FindBlockindex(I, 33, 'RollRuler'), true)
 PitchRulerUpdate(I)
 RollRulerUpdate(I)
 else
 I:Component_SetBoolLogic(33, FindBlockindex(I, 33, 'PitchRuler'), false)
 I:Component_SetBoolLogic(33, FindBlockindex(I, 33, 'RollRuler'), false)
 I:Component_SetBoolLogic(33, FindBlockindex(I, 33, 'SpaceHUD'), true)
end

--AI mode
if I:GetAIMovementMode(0) == 'Off' then
TextStrobbling(I, 'AI', false, false)
else
TextStrobbling(I, 'AI', true, false)
end

--Proximity alert
if I:GetVelocityMagnitude() > 25 and AltAboveTerrain < 30 then
LightStrobbling(I, true)
TextStrobbling(I, 'Proximity', true, false)
else
LightStrobbling(I, false)
TextStrobbling(I, 'Proximity', false, false)
end

--Deploy/fold landing Gear
if I:GetVelocityMagnitude() > 30 or AltAboveTerrain > 50 then
 if LGDeployed == 1 then
   FoldLandingGear(I)
  end
  else
 if LGDeployed == 0 then
   DeployLandingGear(I)
  end
 end

--Add Yaw stabilization
if I:GetAIMovementMode(0) == 'Off' and I:Component_GetFloatLogic_1(2, 0, 0) == 0.5 then
 YawStabilize(I)
end
end