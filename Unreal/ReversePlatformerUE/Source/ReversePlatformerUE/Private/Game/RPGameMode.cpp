#include "Game/RPGameMode.h"

#include "Player/RPPlayerCharacter.h"

ARPGameMode::ARPGameMode()
{
    DefaultPawnClass = ARPPlayerCharacter::StaticClass();
}
