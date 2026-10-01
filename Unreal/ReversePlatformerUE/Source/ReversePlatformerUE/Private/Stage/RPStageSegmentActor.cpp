#include "Stage/RPStageSegmentActor.h"

#include "Components/SceneComponent.h"
#include "Stage/RPModularEnvironmentComponent.h"

ARPStageSegmentActor::ARPStageSegmentActor()
{
    PrimaryActorTick.bCanEverTick = false;
    SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    SetRootComponent(SceneRoot);
    Environment = CreateDefaultSubobject<URPModularEnvironmentComponent>(TEXT("Environment"));
}

void ARPStageSegmentActor::OnConstruction(const FTransform& Transform)
{
    Super::OnConstruction(Transform);

    Environment->LengthMeters = LengthMeters;
    Environment->Palette = Palette;
    Environment->Seed = Seed;
}

void ARPStageSegmentActor::RebuildSegment()
{
    Environment->LengthMeters = LengthMeters;
    Environment->Palette = Palette;
    Environment->Seed = Seed;
    Environment->BuildEnvironment();
}
