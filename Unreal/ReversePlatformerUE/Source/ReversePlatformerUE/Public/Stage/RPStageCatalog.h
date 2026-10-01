#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "Stage/RPStageTypes.h"
#include "RPStageCatalog.generated.h"

UCLASS()
class REVERSEPLATFORMERUE_API URPStageCatalog : public UBlueprintFunctionLibrary
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Stage")
    static FRPStageSpec GetStageSpec(ERPStageId StageId);

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Stage")
    static TArray<FRPStageSpec> GetAllStageSpecs();

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Difficulty")
    static FRPDifficultyTuning GetDifficultyTuning(ERPDifficulty Difficulty);
};
