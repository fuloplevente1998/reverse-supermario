using UnrealBuildTool;

public class ReversePlatformerUEEditorTarget : TargetRules
{
    public ReversePlatformerUEEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("ReversePlatformerUE");
    }
}
