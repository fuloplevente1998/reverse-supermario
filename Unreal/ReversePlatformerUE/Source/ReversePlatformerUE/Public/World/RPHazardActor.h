#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "RPHazardActor.generated.h"

class UBoxComponent;
class USceneComponent;

UCLASS(Blueprintable)
class REVERSEPLATFORMERUE_API ARPHazardActor : public AActor
{
    GENERATED_BODY()

public:
    ARPHazardActor();

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    TObjectPtr<UBoxComponent> DamageVolume;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hazard", meta=(ClampMin="0.0"))
    float Damage = 20.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hazard")
    bool bInstantKill = false;

protected:
    virtual void BeginPlay() override;

    UFUNCTION()
    void HandleOverlap(UPrimitiveComponent* Overlapped, AActor* OtherActor,
        UPrimitiveComponent* OtherComp, int32 BodyIndex, bool bFromSweep, const FHitResult& Hit);
};
