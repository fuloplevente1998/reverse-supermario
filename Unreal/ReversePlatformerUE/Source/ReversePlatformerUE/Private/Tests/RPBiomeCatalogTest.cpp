#if WITH_DEV_AUTOMATION_TESTS

#include "Misc/AutomationTest.h"
#include "Stage/RPBiomeCatalog.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FRPBiomeCatalogTest,
    "ReversePlatformer.Stage.Biomes",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FRPBiomeCatalogTest::RunTest(const FString&)
{
    for (uint8 Index = 1; Index <= 10; ++Index)
    {
        const ERPStageId StageId = static_cast<ERPStageId>(Index);
        const FRPBiomeRecipe Recipe = URPBiomeCatalog::GetBiomeRecipe(StageId);

        TestEqual(TEXT("Recipe returns requested stage"), static_cast<uint8>(Recipe.StageId), Index);
        TestTrue(TEXT("Every biome has architecture families"), Recipe.ArchitectureFamilies.Num() > 0);
        TestTrue(TEXT("Every biome has props"), Recipe.PropFamilies.Num() > 0);
        TestTrue(TEXT("Every biome has enemies"), Recipe.EnemyFamilies.Num() > 0);
        TestFalse(TEXT("Lighting preset must exist"), Recipe.LightingPreset.IsNone());
        TestFalse(TEXT("Atmosphere preset must exist"), Recipe.AtmospherePreset.IsNone());
    }

    return true;
}

#endif
