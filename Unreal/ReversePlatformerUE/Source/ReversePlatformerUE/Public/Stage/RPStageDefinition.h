#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "Stage/RPStageTypes.h"
#include "RPStageDefinition.generated.h"

class URPEnvironmentPalette;
class URPStageSegmentDefinition;

UCLASS(BlueprintType)
class REVERSEPLATFORMERUE_API URPStageDefinition : public UPrimaryDataAsset
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Stage")
    ERPStageId StageId = ERPStageId::Courtyard;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Stage")
    float TargetLengthMeters = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Stage")
    TObjectPtr<URPEnvironmentPalette> EnvironmentPalette;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Stage")
    TArray<TObjectPtr<URPStageSegmentDefinition>> SegmentPool;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Stage")
    int32 DefaultSeed = 1001;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Stage")
    bool bAllowRuntimeVariation = true;
};
