#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "RPRespawnSubsystem.generated.h"

class ARPCheckpointActor;
class APawn;

UCLASS()
class REVERSEPLATFORMERUE_API URPRespawnSubsystem : public UWorldSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Checkpoint")
    void SetCheckpoint(ARPCheckpointActor* Checkpoint);

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Checkpoint")
    bool RespawnPawn(APawn* Pawn) const;

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Checkpoint")
    FVector GetRespawnLocation() const { return RespawnLocation; }

private:
    FVector RespawnLocation = FVector::ZeroVector;
    bool bHasCheckpoint = false;
};
