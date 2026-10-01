#include "Combat/RPEncounterDirectorComponent.h"

#include "Stage/RPStageCatalog.h"

URPEncounterDirectorComponent::URPEncounterDirectorComponent()
{
    PrimaryComponentTick.bCanEverTick = false;
}

int32 URPEncounterDirectorComponent::GetAdjustedEnemyCount(const int32 BaselineCount) const
{
    const FRPDifficultyTuning Tuning = URPStageCatalog::GetDifficultyTuning(Difficulty);
    return FMath::Max(1, FMath::RoundToInt(static_cast<float>(BaselineCount) * Tuning.EnemyCountMultiplier));
}

float URPEncounterDirectorComponent::GetAdjustedEnemyDamage(const float BaselineDamage) const
{
    return BaselineDamage * URPStageCatalog::GetDifficultyTuning(Difficulty).EnemyDamageMultiplier;
}

bool URPEncounterDirectorComponent::RollElite(const int32 Seed) const
{
    FRandomStream Random(Seed);
    return Random.FRand() < URPStageCatalog::GetDifficultyTuning(Difficulty).EliteChance;
}
