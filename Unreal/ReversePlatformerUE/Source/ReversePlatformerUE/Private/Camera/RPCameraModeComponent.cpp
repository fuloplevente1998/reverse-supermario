#include "Camera/RPCameraModeComponent.h"

#include "Camera/CameraComponent.h"
#include "GameFramework/Character.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/SpringArmComponent.h"

URPCameraModeComponent::URPCameraModeComponent()
{
    PrimaryComponentTick.bCanEverTick = false;
}

void URPCameraModeComponent::BeginPlay()
{
    Super::BeginPlay();

    AActor* Owner = GetOwner();
    SpringArm = Owner ? Owner->FindComponentByClass<USpringArmComponent>() : nullptr;
    Camera = Owner ? Owner->FindComponentByClass<UCameraComponent>() : nullptr;

    SetCameraMode(InitialMode);
}

void URPCameraModeComponent::SetCameraMode(const ERPCameraMode NewMode)
{
    ACharacter* Character = Cast<ACharacter>(GetOwner());
    if (!Character || !SpringArm)
    {
        CameraMode = NewMode;
        return;
    }

    UCharacterMovementComponent* Movement = Character->GetCharacterMovement();
    CameraMode = NewMode;

    if (NewMode == ERPCameraMode::SideView)
    {
        SpringArm->TargetArmLength = SideArmLength;
        SpringArm->bUsePawnControlRotation = false;
        SpringArm->SetRelativeRotation(FRotator(-7.0f, -90.0f, 0.0f));
        SpringArm->bEnableCameraLag = true;
        SpringArm->CameraLagSpeed = 8.0f;

        Character->bUseControllerRotationYaw = false;
        Movement->bOrientRotationToMovement = true;
        Movement->SetPlaneConstraintNormal(FVector(0.0f, 1.0f, 0.0f));
        Movement->SetPlaneConstraintEnabled(true);
        Movement->bSnapToPlaneAtStart = true;
    }
    else
    {
        SpringArm->TargetArmLength = ThirdPersonArmLength;
        SpringArm->bUsePawnControlRotation = true;
        SpringArm->SetRelativeRotation(FRotator(-12.0f, 0.0f, 0.0f));
        SpringArm->bEnableCameraLag = true;
        SpringArm->CameraLagSpeed = 10.0f;

        Character->bUseControllerRotationYaw = false;
        Movement->bOrientRotationToMovement = true;
        Movement->SetPlaneConstraintEnabled(false);
    }

    OnCameraModeChanged.Broadcast(CameraMode);
}

void URPCameraModeComponent::ToggleCameraMode()
{
    SetCameraMode(CameraMode == ERPCameraMode::SideView
        ? ERPCameraMode::ThirdPerson
        : ERPCameraMode::SideView);
}
