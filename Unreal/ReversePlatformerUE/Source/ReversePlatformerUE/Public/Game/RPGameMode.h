#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "RPGameMode.generated.h"

UCLASS()
class REVERSEPLATFORMERUE_API ARPGameMode : public AGameModeBase
{
    GENERATED_BODY()

public:
    ARPGameMode();

    virtual void BeginPlay() override;
};
