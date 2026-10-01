#pragma once

#include "CoreMinimal.h"
#include "Stage/RPStageSegmentActor.h"
#include "RPStageBlockoutSegment.generated.h"

class UHierarchicalInstancedStaticMeshComponent;
class UStaticMesh;

UCLASS()
class REVERSEPLATFORMERUE_API ARPStageBlockoutSegment : public ARPStageSegmentActor
{
    GENERATED_BODY()

public:
    ARPStageBlockoutSegment();

    virtual void RebuildSegment() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Blockout")
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> BlockoutInstances;

protected:
    void AddBox(FVector LocationMeters, FVector SizeMeters, FRotator Rotation = FRotator::ZeroRotator);
    void BuildFloor(float WidthMeters = 7.0f);
    void BuildGap();
    void BuildStairs();
    void BuildCombatCover(bool bLarge);
    void BuildGate();
    void BuildTower();
};
