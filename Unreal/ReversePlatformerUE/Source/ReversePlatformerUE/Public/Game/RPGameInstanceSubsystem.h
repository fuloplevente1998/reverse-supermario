#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "Stage/RPStageTypes.h"
#include "RPGameInstanceSubsystem.generated.h"

UCLASS()
class REVERSEPLATFORMERUE_API URPGameInstanceSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintReadWrite, Category="Reverse Platformer|Session")
    ERPStageId SelectedStage = ERPStageId::Courtyard;

    UPROPERTY(BlueprintReadWrite, Category="Reverse Platformer|Session")
    ERPDifficulty SelectedDifficulty = ERPDifficulty::Normal;

    UPROPERTY(BlueprintReadWrite, Category="Reverse Platformer|Session")
    int32 StageSeed = 1001;

    UPROPERTY(BlueprintReadWrite, Category="Reverse Platformer|Session")
    ERPCameraMode PreferredCameraMode = ERPCameraMode::SideView;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Session")
    void ConfigureRun(ERPStageId Stage, ERPDifficulty Difficulty, int32 Seed);
};
