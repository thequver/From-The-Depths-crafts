function Stabilize(I, Delta, TargetControllerAdd, TargetControllerSubtract, Threshold, Multiplier, Addittion)
if I:GetAIMovementMode(0) == "Off" and I:GetInput(2, TargetControllerAdd) < 1 and I:GetInput(2, TargetControllerSubtract) < 1 and (Threshold < Delta or Delta < -Threshold) then
 I:RequestControl(2, Delta < 0 and TargetControllerAdd or TargetControllerSubtract, Mathf.Clamp(Mathf.Abs(Delta) * Multiplier + Addittion, 0, 0.99))
 end
end
-----

function Update(I)
I:ClearLogs()

--Y
Stabilize(I, AngularVelocity.y, 1, 0, 0.005, 0.4, 0.3 * Mathf.Abs(AngularVelocity.y) * (230 / ForwardsVelocity))
--P
Stabilize(I, AngularVelocity.x, 5, 4, 0.005, 0.4, 0.3 * Mathf.Abs(AngularVelocity.x) * (230 / ForwardsVelocity))
--R
Stabilize(I, AngularVelocity.z, 2, 3, 0.005,  0.3, 0.1 * Mathf.Abs(AngularVelocity.z) * (230 / ForwardsVelocity))

end