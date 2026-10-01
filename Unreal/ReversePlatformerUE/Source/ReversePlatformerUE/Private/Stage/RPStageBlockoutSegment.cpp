#include "Stage/RPStageBlockoutSegment.h"

#include "Components/HierarchicalInstancedStaticMeshComponent.h"
#include "UObject/ConstructorHelpers.h"

ARPStageBlockoutSegment::ARPStageBlockoutSegment()
{
    BlockoutInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("BlockoutInstances"));
    BlockoutInstances->SetupAttachment(SceneRoot);
    BlockoutInstances->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeMesh.Succeeded())
    {
        BlockoutInstances->SetStaticMesh(CubeMesh.Object);
    }
}

void ARPStageBlockoutSegment::AddBox(
    const FVector LocationMeters,
    const FVector SizeMeters,
    const FRotator Rotation)
{
    const FTransform Transform(
        Rotation,
        LocationMeters * 100.0f,
        SizeMeters);
    BlockoutInstances->AddInstance(Transform);
}

void ARPStageBlockoutSegment::BuildFloor(const float WidthMeters)
{
    AddBox(FVector::ZeroVector, FVector(LengthMeters, WidthMeters, 0.5f));
}

void ARPStageBlockoutSegment::BuildGap()
{
    const float SideLength = LengthMeters * 0.38f;
    const float Offset = LengthMeters * 0.31f;
    AddBox(FVector(-Offset, 0.0f, 0.0f), FVector(SideLength, 7.0f, 0.5f));
    AddBox(FVector( Offset, 0.0f, 0.0f), FVector(SideLength, 7.0f, 0.5f));
}

void ARPStageBlockoutSegment::BuildStairs()
{
    BuildFloor();
    constexpr int32 Steps = 6;
    const float StepLength = LengthMeters / static_cast<float>(Steps);
    for (int32 Index = 0; Index < Steps; ++Index)
    {
        const float X = -LengthMeters * 0.5f + StepLength * (Index + 0.5f);
        const float Height = 0.35f * Index;
        AddBox(FVector(X, 0.0f, Height), FVector(StepLength * 0.92f, 5.0f, 0.35f + Height));
    }
}

void ARPStageBlockoutSegment::BuildCombatCover(const bool bLarge)
{
    BuildFloor();
    const int32 Count = bLarge ? 5 : 3;
    for (int32 Index = 0; Index < Count; ++Index)
    {
        const float Alpha = static_cast<float>(Index + 1) / static_cast<float>(Count + 1);
        const float X = FMath::Lerp(-LengthMeters * 0.40f, LengthMeters * 0.40f, Alpha);
        const float Y = (Index % 2 == 0 ? -1.0f : 1.0f) * 1.7f;
        AddBox(FVector(X, Y, 0.65f), FVector(1.4f, 1.2f, 1.3f));
    }
}

void ARPStageBlockoutSegment::BuildGate()
{
    BuildFloor();
    const float X = LengthMeters * 0.15f;
    AddBox(FVector(X, -2.4f, 2.5f), FVector(1.2f, 1.0f, 5.0f));
    AddBox(FVector(X,  2.4f, 2.5f), FVector(1.2f, 1.0f, 5.0f));
    AddBox(FVector(X, 0.0f, 5.0f), FVector(1.2f, 5.8f, 1.0f));
}

void ARPStageBlockoutSegment::BuildTower()
{
    BuildFloor();
    const float X = LengthMeters * 0.10f;
    AddBox(FVector(X, 3.7f, 3.0f), FVector(5.0f, 2.0f, 6.0f));
    AddBox(FVector(X, 3.7f, 6.4f), FVector(5.6f, 2.4f, 0.8f));
}

void ARPStageBlockoutSegment::RebuildSegment()
{
    Super::RebuildSegment();

    BlockoutInstances->ClearInstances();

    switch (SegmentType)
    {
        case ERPStageSegmentType::Gap:
            BuildGap();
            break;
        case ERPStageSegmentType::Bridge:
            BuildFloor(3.6f);
            break;
        case ERPStageSegmentType::Stairs:
            BuildStairs();
            break;
        case ERPStageSegmentType::CombatSmall:
        case ERPStageSegmentType::ArcherAmbush:
            BuildCombatCover(false);
            break;
        case ERPStageSegmentType::CombatLarge:
        case ERPStageSegmentType::MiniBoss:
            BuildCombatCover(true);
            break;
        case ERPStageSegmentType::Gate:
        case ERPStageSegmentType::Finish:
            BuildGate();
            break;
        case ERPStageSegmentType::Tower:
            BuildTower();
            break;
        case ERPStageSegmentType::Hazard:
            BuildFloor();
            AddBox(FVector(0.0f, 0.0f, 0.8f), FVector(2.0f, 4.5f, 1.6f));
            break;
        case ERPStageSegmentType::Checkpoint:
            BuildFloor();
            AddBox(FVector(0.0f, -3.4f, 1.8f), FVector(0.5f, 0.5f, 3.6f));
            break;
        default:
            BuildFloor();
            break;
    }
}
