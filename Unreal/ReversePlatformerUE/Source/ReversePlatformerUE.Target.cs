using UnrealBuildTool;

public class ReversePlatformerUETarget : TargetRules
{
    public ReversePlatformerUETarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("ReversePlatformerUE");
    }
}
