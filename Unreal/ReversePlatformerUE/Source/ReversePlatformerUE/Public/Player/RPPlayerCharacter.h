#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "RPPlayerCharacter.generated.h"

class UCameraComponent;
class USpringArmComponent;
class URPCameraModeComponent;

UCLASS()
class REVERSEPLATFORMERUE_API ARPPlayerCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    ARPPlayerCharacter();

    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<UCameraComponent> FollowCamera;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<URPCameraModeComponent> CameraMode;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Input")
    void ToggleView();

    UFUNCTION(BlueprintImplementableEvent, Category="Reverse Platformer|Combat")
    void OnAttackRequested();

    UFUNCTION(BlueprintImplementableEvent, Category="Reverse Platformer|Combat")
    void OnBlockChanged(bool bBlocking);

protected:
    void MoveForward(float Value);
    void MoveRight(float Value);
    void Turn(float Value);
    void LookUp(float Value);
    void Attack();
    void StartBlock();
    void StopBlock();
};
