#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "RPCheckpointActor.generated.h"

class UBoxComponent;
class USceneComponent;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FRPCheckpointActivated, ARPCheckpointActor*, Checkpoint);

UCLASS()
class REVERSEPLATFORMERUE_API ARPCheckpointActor : public AActor
{
    GENERATED_BODY()

public:
    ARPCheckpointActor();

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    TObjectPtr<UBoxComponent> Trigger;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Checkpoint")
    FVector RespawnOffset = FVector(0.0f, 0.0f, 120.0f);

    UPROPERTY(BlueprintAssignable, Category="Checkpoint")
    FRPCheckpointActivated OnActivated;

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Checkpoint")
    FVector GetRespawnLocation() const { return GetActorLocation() + RespawnOffset; }

protected:
    virtual void BeginPlay() override;

    UFUNCTION()
    void HandleOverlap(UPrimitiveComponent* Overlapped, AActor* OtherActor,
        UPrimitiveComponent* OtherComp, int32 BodyIndex, bool bFromSweep, const FHitResult& Hit);
};
