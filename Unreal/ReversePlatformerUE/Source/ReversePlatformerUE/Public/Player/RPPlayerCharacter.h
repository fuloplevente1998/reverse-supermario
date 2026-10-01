#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "RPPlayerCharacter.generated.h"

class UCameraComponent;
class USpringArmComponent;
class URPCameraModeComponent;
class URPHealthComponent;
class URPMeleeCombatComponent;

UCLASS()
class REVERSEPLATFORMERUE_API ARPPlayerCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    ARPPlayerCharacter();

    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<UCameraComponent> FollowCamera;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<URPCameraModeComponent> CameraMode;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Combat")
    TObjectPtr<URPHealthComponent> Health;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Combat")
    TObjectPtr<URPMeleeCombatComponent> MeleeCombat;

    UPROPERTY(BlueprintReadOnly, Category="Combat")
    bool bBlocking = false;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Input")
    void ToggleView();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile")
    void SetMobileMoveInput(FVector2D Value);

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile")
    void MobileJumpPressed();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile")
    void MobileJumpReleased();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile")
    void MobileAttack();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile")
    void MobileBlockPressed();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile")
    void MobileBlockReleased();

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

    UFUNCTION()
    void HandleDeath();

    FTransform InitialSpawnTransform;
    FVector2D MobileMoveInput = FVector2D::ZeroVector;
};
