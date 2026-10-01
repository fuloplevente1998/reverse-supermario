#include "Game/RPGameMode.h"

#include "Camera/RPCameraModeComponent.h"
#include "EngineUtils.h"
#include "Kismet/GameplayStatics.h"
#include "GameFramework/PlayerController.h"
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

    ARPPlayerCharacter* PlayerCharacter = Cast<ARPPlayerCharacter>(UGameplayStatics::GetPlayerCharacter(this, 0));
    if (!PlayerCharacter)
    {
        if (APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0))
        {
            FActorSpawnParameters PlayerSpawn;
            PlayerSpawn.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
            PlayerCharacter = GetWorld()->SpawnActor<ARPPlayerCharacter>(
                DefaultPawnClass ? DefaultPawnClass : ARPPlayerCharacter::StaticClass(),
                FVector(150.0f, 0.0f, 160.0f),
                FRotator::ZeroRotator,
                PlayerSpawn);
            if (PlayerCharacter)
            {
                PC->Possess(PlayerCharacter);
            }
        }
    }

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

    if (Session && PlayerCharacter && PlayerCharacter->CameraMode)
    {
        PlayerCharacter->CameraMode->SetCameraMode(Session->PreferredCameraMode);
    }
}
