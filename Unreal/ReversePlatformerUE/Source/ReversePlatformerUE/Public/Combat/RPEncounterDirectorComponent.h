#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Stage/RPStageTypes.h"
#include "RPEncounterDirectorComponent.generated.h"

UCLASS(ClassGroup=(ReversePlatformer), meta=(BlueprintSpawnableComponent))
class REVERSEPLATFORMERUE_API URPEncounterDirectorComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    URPEncounterDirectorComponent();

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Difficulty")
    ERPDifficulty Difficulty = ERPDifficulty::Normal;

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Encounter")
    int32 GetAdjustedEnemyCount(int32 BaselineCount) const;

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Encounter")
    float GetAdjustedEnemyDamage(float BaselineDamage) const;

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Encounter")
    bool RollElite(int32 Seed) const;
};
