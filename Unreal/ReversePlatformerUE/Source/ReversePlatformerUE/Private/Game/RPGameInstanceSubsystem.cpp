#include "Game/RPGameInstanceSubsystem.h"

void URPGameInstanceSubsystem::ConfigureRun(
    const ERPStageId Stage,
    const ERPDifficulty Difficulty,
    const int32 Seed)
{
    SelectedStage = Stage;
    SelectedDifficulty = Difficulty;
    StageSeed = Seed;
}
