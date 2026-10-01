#include "Game/RPGameMode.h"

#include "Camera/RPCameraModeComponent.h"
#include "EngineUtils.h"
#include "Game/RPGameInstanceSubsystem.h"
#include "Player/RPPlayerCharacter.h"
#include "Stage/RPStageGenerator.h"

ARPGameMode::ARPGameMode()
{
    DefaultPawnClass = ARPPlayerCharacter::StaticClass();
}

void ARPGameMode::BeginPlay()
{
    Super::BeginPlay();

    URPGameInstanceSubsystem* Session = GetGameInstance()
        ? GetGameInstance()->GetSubsystem<URPGameInstanceSubsystem>()
        : nullptr;

    ARPStageGenerator* Generator = nullptr;
    for (TActorIterator<ARPStageGenerator> It(GetWorld()); It; ++It)
    {
        Generator = *It;
        break;
    }

    if (!Generator)
    {
        Generator = GetWorld()->SpawnActor<ARPStageGenerator>();
    }

    if (Generator && Session)
    {
        Generator->StageId = Session->SelectedStage;
        Generator->Difficulty = Session->SelectedDifficulty;
        Generator->GenerationSeed = Session->StageSeed;
        Generator->GenerateStage();
    }

    if (Session)
    {
        for (TActorIterator<ARPPlayerCharacter> It(GetWorld()); It; ++It)
        {
            if (It->CameraMode)
            {
                It->CameraMode->SetCameraMode(Session->PreferredCameraMode);
            }
            break;
        }
    }
}
