#if WITH_DEV_AUTOMATION_TESTS

#include "Misc/AutomationTest.h"
#include "Stage/RPStageCatalog.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FRPStageCatalogTest,
    "ReversePlatformer.Stage.Catalog",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FRPStageCatalogTest::RunTest(const FString&)
{
    const TArray<FRPStageSpec> Stages = URPStageCatalog::GetAllStageSpecs();
    TestEqual(TEXT("Exactly ten stages"), Stages.Num(), 10);

    TSet<FString> UniqueNames;
    for (const FRPStageSpec& Stage : Stages)
    {
        TestTrue(TEXT("Minimum stage length is long-form"), Stage.MinLengthMeters >= 700.0f);
        TestTrue(TEXT("Length range is valid"), Stage.MaxLengthMeters >= Stage.MinLengthMeters);
        TestTrue(TEXT("Every stage has combat"), Stage.CombatCount >= 3);
        UniqueNames.Add(Stage.DisplayName.ToString());
    }

    TestEqual(TEXT("All stage names are unique"), UniqueNames.Num(), 10);

    const FRPDifficultyTuning Easy = URPStageCatalog::GetDifficultyTuning(ERPDifficulty::Easy);
    const FRPDifficultyTuning Normal = URPStageCatalog::GetDifficultyTuning(ERPDifficulty::Normal);
    const FRPDifficultyTuning Hard = URPStageCatalog::GetDifficultyTuning(ERPDifficulty::Hard);

    TestTrue(TEXT("Easy has fewer enemies"), Easy.EnemyCountMultiplier < Normal.EnemyCountMultiplier);
    TestTrue(TEXT("Hard has more enemies"), Hard.EnemyCountMultiplier > Normal.EnemyCountMultiplier);
    TestTrue(TEXT("Easy checkpoints are closer"), Easy.CheckpointIntervalMeters < Normal.CheckpointIntervalMeters);
    TestTrue(TEXT("Hard checkpoints are farther apart"), Hard.CheckpointIntervalMeters > Normal.CheckpointIntervalMeters);

    return true;
}

#endif
