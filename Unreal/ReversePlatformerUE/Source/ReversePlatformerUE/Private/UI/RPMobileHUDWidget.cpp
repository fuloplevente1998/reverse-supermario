#include "UI/RPMobileHUDWidget.h"

#include "Kismet/GameplayStatics.h"
#include "Player/RPPlayerCharacter.h"

ARPPlayerCharacter* URPMobileHUDWidget::ResolvePlayer() const
{
    return Cast<ARPPlayerCharacter>(UGameplayStatics::GetPlayerCharacter(this, 0));
}

void URPMobileHUDWidget::SetMoveVector(const FVector2D Value)
{
    if (ARPPlayerCharacter* Player = ResolvePlayer())
    {
        Player->SetMobileMoveInput(Value);
    }
}

void URPMobileHUDWidget::JumpPressed()
{
    if (ARPPlayerCharacter* Player = ResolvePlayer()) Player->MobileJumpPressed();
}

void URPMobileHUDWidget::JumpReleased()
{
    if (ARPPlayerCharacter* Player = ResolvePlayer()) Player->MobileJumpReleased();
}

void URPMobileHUDWidget::AttackPressed()
{
    if (ARPPlayerCharacter* Player = ResolvePlayer()) Player->MobileAttack();
}

void URPMobileHUDWidget::BlockPressed()
{
    if (ARPPlayerCharacter* Player = ResolvePlayer()) Player->MobileBlockPressed();
}

void URPMobileHUDWidget::BlockReleased()
{
    if (ARPPlayerCharacter* Player = ResolvePlayer()) Player->MobileBlockReleased();
}

void URPMobileHUDWidget::ToggleViewPressed()
{
    if (ARPPlayerCharacter* Player = ResolvePlayer()) Player->ToggleView();
}
