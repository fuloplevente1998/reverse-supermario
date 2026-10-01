#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "Stage/RPStageTypes.h"
#include "RPStageSegmentDefinition.generated.h"

UCLASS(BlueprintType)
class REVERSEPLATFORMERUE_API URPStageSegmentDefinition : public UPrimaryDataAsset
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Segment")
    ERPStageSegmentType SegmentType = ERPStageSegmentType::Traversal;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Segment", meta=(ClampMin="5.0"))
    float LengthMeters = 40.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Segment", meta=(ClampMin="0.01"))
    float SelectionWeight = 1.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Segment")
    ERPDifficulty MinimumDifficulty = ERPDifficulty::Easy;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Segment")
    ERPDifficulty MaximumDifficulty = ERPDifficulty::Hard;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Segment")
    TSubclassOf<AActor> SegmentActorClass;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Segment")
    bool bAllowMirroring = true;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Segment")
    bool bHeroComposition = false;
};
