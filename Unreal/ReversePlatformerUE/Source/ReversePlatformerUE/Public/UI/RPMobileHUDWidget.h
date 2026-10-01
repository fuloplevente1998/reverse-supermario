#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "RPMobileHUDWidget.generated.h"

class ARPPlayerCharacter;

UCLASS(Abstract, Blueprintable)
class REVERSEPLATFORMERUE_API URPMobileHUDWidget : public UUserWidget
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile HUD")
    void SetMoveVector(FVector2D Value);

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile HUD")
    void JumpPressed();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile HUD")
    void JumpReleased();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile HUD")
    void AttackPressed();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile HUD")
    void BlockPressed();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile HUD")
    void BlockReleased();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile HUD")
    void ToggleViewPressed();

protected:
    ARPPlayerCharacter* ResolvePlayer() const;
};
