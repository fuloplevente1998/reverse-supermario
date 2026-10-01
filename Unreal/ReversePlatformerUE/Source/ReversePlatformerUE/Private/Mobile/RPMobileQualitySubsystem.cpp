#include "Mobile/RPMobileQualitySubsystem.h"

#include "Engine/Engine.h"

namespace
{
void ExecSetting(UWorld* World, const TCHAR* Command)
{
    if (GEngine && World)
    {
        GEngine->Exec(World, Command);
    }
}
}

void URPMobileQualitySubsystem::ApplyQuality(const ERPMobileQuality Quality)
{
    CurrentQuality = Quality;
    UWorld* World = GetWorld();

    switch (Quality)
    {
        case ERPMobileQuality::Medium:
            ExecSetting(World, TEXT("r.ScreenPercentage 75"));
            ExecSetting(World, TEXT("sg.ViewDistanceQuality 1"));
            ExecSetting(World, TEXT("sg.ShadowQuality 1"));
            ExecSetting(World, TEXT("sg.PostProcessQuality 0"));
            ExecSetting(World, TEXT("sg.EffectsQuality 1"));
            ExecSetting(World, TEXT("sg.TextureQuality 1"));
            ExecSetting(World, TEXT("sg.FoliageQuality 1"));
            break;

        case ERPMobileQuality::Ultra:
            ExecSetting(World, TEXT("r.ScreenPercentage 100"));
            ExecSetting(World, TEXT("sg.ViewDistanceQuality 3"));
            ExecSetting(World, TEXT("sg.ShadowQuality 3"));
            ExecSetting(World, TEXT("sg.PostProcessQuality 2"));
            ExecSetting(World, TEXT("sg.EffectsQuality 3"));
            ExecSetting(World, TEXT("sg.TextureQuality 3"));
            ExecSetting(World, TEXT("sg.FoliageQuality 3"));
            break;

        case ERPMobileQuality::High:
        default:
            ExecSetting(World, TEXT("r.ScreenPercentage 90"));
            ExecSetting(World, TEXT("sg.ViewDistanceQuality 2"));
            ExecSetting(World, TEXT("sg.ShadowQuality 2"));
            ExecSetting(World, TEXT("sg.PostProcessQuality 1"));
            ExecSetting(World, TEXT("sg.EffectsQuality 2"));
            ExecSetting(World, TEXT("sg.TextureQuality 2"));
            ExecSetting(World, TEXT("sg.FoliageQuality 2"));
            break;
    }
}

float URPMobileQualitySubsystem::GetTargetFrameRate() const
{
    return CurrentQuality == ERPMobileQuality::Ultra ? 60.0f : 45.0f;
}
