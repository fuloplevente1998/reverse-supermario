#include "World/RPHazardActor.h"

#include "Combat/RPHealthComponent.h"
#include "Components/BoxComponent.h"
#include "Components/SceneComponent.h"

ARPHazardActor::ARPHazardActor()
{
    PrimaryActorTick.bCanEverTick = false;

    SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    SetRootComponent(SceneRoot);

    DamageVolume = CreateDefaultSubobject<UBoxComponent>(TEXT("DamageVolume"));
    DamageVolume->SetupAttachment(SceneRoot);
    DamageVolume->SetCollisionProfileName(TEXT("Trigger"));
}

void ARPHazardActor::BeginPlay()
{
    Super::BeginPlay();
    DamageVolume->OnComponentBeginOverlap.AddDynamic(this, &ARPHazardActor::HandleOverlap);
}

void ARPHazardActor::HandleOverlap(UPrimitiveComponent*, AActor* OtherActor,
    UPrimitiveComponent*, int32, bool, const FHitResult&)
{
    if (!OtherActor)
    {
        return;
    }

    if (URPHealthComponent* Health = OtherActor->FindComponentByClass<URPHealthComponent>())
    {
        Health->ApplyDamage(bInstantKill ? Health->GetHealth() + Health->MaxHealth : Damage);
    }
}
