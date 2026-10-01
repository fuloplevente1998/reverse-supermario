#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Stage/RPStageTypes.h"
#include "RPStageSegmentActor.generated.h"

class URPEnvironmentPalette;
class URPModularEnvironmentComponent;
class USceneComponent;

UCLASS(Blueprintable)
class REVERSEPLATFORMERUE_API ARPStageSegmentActor : public AActor
{
    GENERATED_BODY()

public:
    ARPStageSegmentActor();

    virtual void OnConstruction(const FTransform& Transform) override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    TObjectPtr<URPModularEnvironmentComponent> Environment;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Segment")
    ERPStageSegmentType SegmentType = ERPStageSegmentType::Traversal;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Segment")
    float LengthMeters = 40.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Segment")
    TObjectPtr<URPEnvironmentPalette> Palette;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Segment")
    int32 Seed = 1001;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Segment")
    virtual void RebuildSegment();
};
