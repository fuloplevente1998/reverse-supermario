#pragma once

#include "CoreMinimal.h"
#include "Stage/RPStageTypes.h"
#include "RPBiomeRecipe.generated.h"

USTRUCT(BlueprintType)
struct FRPBiomeRecipe
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    ERPStageId StageId = ERPStageId::Courtyard;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TArray<FName> ArchitectureFamilies;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TArray<FName> PropFamilies;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TArray<FName> VegetationFamilies;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TArray<FName> EnemyFamilies;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TArray<FName> HazardFamilies;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FName LightingPreset = TEXT("WarmDay");

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FName AtmospherePreset = TEXT("Clear");

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FName MusicPreset = NAME_None;
};
