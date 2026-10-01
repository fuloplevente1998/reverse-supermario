#include "World/RPCheckpointActor.h"

#include "Components/BoxComponent.h"
#include "Components/SceneComponent.h"
#include "GameFramework/Pawn.h"

ARPCheckpointActor::ARPCheckpointActor()
{
    PrimaryActorTick.bCanEverTick = false;

    SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    SetRootComponent(SceneRoot);

    Trigger = CreateDefaultSubobject<UBoxComponent>(TEXT("Trigger"));
    Trigger->SetupAttachment(SceneRoot);
    Trigger->SetBoxExtent(FVector(100.0f, 250.0f, 220.0f));
    Trigger->SetCollisionProfileName(TEXT("Trigger"));
}

void ARPCheckpointActor::BeginPlay()
{
    Super::BeginPlay();
    Trigger->OnComponentBeginOverlap.AddDynamic(this, &ARPCheckpointActor::HandleOverlap);
}

void ARPCheckpointActor::HandleOverlap(UPrimitiveComponent*, AActor* OtherActor,
    UPrimitiveComponent*, int32, bool, const FHitResult&)
{
    if (Cast<APawn>(OtherActor))
    {
        OnActivated.Broadcast(this);
    }
}
