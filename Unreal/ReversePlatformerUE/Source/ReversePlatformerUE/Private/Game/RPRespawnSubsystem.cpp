#include "Game/RPRespawnSubsystem.h"

#include "GameFramework/Pawn.h"
#include "World/RPCheckpointActor.h"

void URPRespawnSubsystem::SetCheckpoint(ARPCheckpointActor* Checkpoint)
{
    if (Checkpoint)
    {
        RespawnLocation = Checkpoint->GetRespawnLocation();
        bHasCheckpoint = true;
    }
}

bool URPRespawnSubsystem::RespawnPawn(APawn* Pawn) const
{
    if (!Pawn || !bHasCheckpoint)
    {
        return false;
    }

    Pawn->SetActorLocation(RespawnLocation, false, nullptr, ETeleportType::TeleportPhysics);
    return true;
}
