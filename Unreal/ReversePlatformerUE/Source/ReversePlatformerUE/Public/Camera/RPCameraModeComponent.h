#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Stage/RPStageTypes.h"
#include "RPCameraModeComponent.generated.h"

class UCameraComponent;
class USpringArmComponent;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FRPCameraModeChanged, ERPCameraMode, NewMode);

UCLASS(ClassGroup=(ReversePlatformer), meta=(BlueprintSpawnableComponent))
class REVERSEPLATFORMERUE_API URPCameraModeComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    URPCameraModeComponent();

    virtual void BeginPlay() override;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Camera")
    ERPCameraMode InitialMode = ERPCameraMode::SideView;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Camera|Side View")
    float SideArmLength = 900.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Camera|Third Person")
    float ThirdPersonArmLength = 420.0f;

    UPROPERTY(BlueprintAssignable, Category="Camera")
    FRPCameraModeChanged OnCameraModeChanged;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Camera")
    void SetCameraMode(ERPCameraMode NewMode);

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Camera")
    void ToggleCameraMode();

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Camera")
    ERPCameraMode GetCameraMode() const { return CameraMode; }

private:
    UPROPERTY(Transient)
    TObjectPtr<USpringArmComponent> SpringArm;

    UPROPERTY(Transient)
    TObjectPtr<UCameraComponent> Camera;

    ERPCameraMode CameraMode = ERPCameraMode::SideView;
};
