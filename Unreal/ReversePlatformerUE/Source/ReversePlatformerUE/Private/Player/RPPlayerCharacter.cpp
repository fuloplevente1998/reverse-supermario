#include "Player/RPPlayerCharacter.h"

#include "Camera/CameraComponent.h"
#include "Components/InputComponent.h"
#include "Camera/RPCameraModeComponent.h"
#include "Combat/RPHealthComponent.h"
#include "Combat/RPMeleeCombatComponent.h"
#include "Game/RPRespawnSubsystem.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/SpringArmComponent.h"

ARPPlayerCharacter::ARPPlayerCharacter()
{
    PrimaryActorTick.bCanEverTick = true;

    GetCharacterMovement()->MaxWalkSpeed = 520.0f;
    GetCharacterMovement()->JumpZVelocity = 720.0f;
    GetCharacterMovement()->AirControl = 0.45f;
    GetCharacterMovement()->GravityScale = 1.8f;

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength = 900.0f;
    CameraBoom->bDoCollisionTest = true;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;

    CameraMode = CreateDefaultSubobject<URPCameraModeComponent>(TEXT("CameraMode"));
    Health = CreateDefaultSubobject<URPHealthComponent>(TEXT("Health"));
    MeleeCombat = CreateDefaultSubobject<URPMeleeCombatComponent>(TEXT("MeleeCombat"));
}

void ARPPlayerCharacter::BeginPlay()
{
    Super::BeginPlay();
    InitialSpawnTransform = GetActorTransform();
    Health->OnDeath.AddDynamic(this, &ARPPlayerCharacter::HandleDeath);
}

void ARPPlayerCharacter::Tick(const float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (!MobileMoveInput.IsNearlyZero())
    {
        MoveForward(MobileMoveInput.Y);
        MoveRight(MobileMoveInput.X);
    }
}

void ARPPlayerCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &ARPPlayerCharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &ARPPlayerCharacter::MoveRight);
    PlayerInputComponent->BindAxis(TEXT("Turn"), this, &ARPPlayerCharacter::Turn);
    PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &ARPPlayerCharacter::LookUp);

    PlayerInputComponent->BindAction(TEXT("Jump"), IE_Pressed, this, &ACharacter::Jump);
    PlayerInputComponent->BindAction(TEXT("Jump"), IE_Released, this, &ACharacter::StopJumping);
    PlayerInputComponent->BindAction(TEXT("Attack"), IE_Pressed, this, &ARPPlayerCharacter::Attack);
    PlayerInputComponent->BindAction(TEXT("Block"), IE_Pressed, this, &ARPPlayerCharacter::StartBlock);
    PlayerInputComponent->BindAction(TEXT("Block"), IE_Released, this, &ARPPlayerCharacter::StopBlock);
    PlayerInputComponent->BindAction(TEXT("ToggleView"), IE_Pressed, this, &ARPPlayerCharacter::ToggleView);
}

void ARPPlayerCharacter::MoveForward(const float Value)
{
    if (FMath::IsNearlyZero(Value))
    {
        return;
    }

    if (CameraMode && CameraMode->GetCameraMode() == ERPCameraMode::SideView)
    {
        AddMovementInput(FVector::ForwardVector, Value);
        return;
    }

    const AController* C = GetController();
    const FRotator Rotation = C ? C->GetControlRotation() : FRotator::ZeroRotator;
    const FVector Direction = FRotationMatrix(FRotator(0.0f, Rotation.Yaw, 0.0f)).GetUnitAxis(EAxis::X);
    AddMovementInput(Direction, Value);
}

void ARPPlayerCharacter::MoveRight(const float Value)
{
    if (FMath::IsNearlyZero(Value) || (CameraMode && CameraMode->GetCameraMode() == ERPCameraMode::SideView))
    {
        return;
    }

    const AController* C = GetController();
    const FRotator Rotation = C ? C->GetControlRotation() : FRotator::ZeroRotator;
    const FVector Direction = FRotationMatrix(FRotator(0.0f, Rotation.Yaw, 0.0f)).GetUnitAxis(EAxis::Y);
    AddMovementInput(Direction, Value);
}

void ARPPlayerCharacter::Turn(const float Value)
{
    if (!CameraMode || CameraMode->GetCameraMode() == ERPCameraMode::ThirdPerson)
    {
        AddControllerYawInput(Value);
    }
}

void ARPPlayerCharacter::LookUp(const float Value)
{
    if (!CameraMode || CameraMode->GetCameraMode() == ERPCameraMode::ThirdPerson)
    {
        AddControllerPitchInput(Value);
    }
}

void ARPPlayerCharacter::Attack()
{
    if (MeleeCombat && MeleeCombat->TryAttack())
    {
        OnAttackRequested();
    }
}

void ARPPlayerCharacter::StartBlock()
{
    bBlocking = true;
    if (MeleeCombat) MeleeCombat->SetBlocking(true);
    OnBlockChanged(true);
}

void ARPPlayerCharacter::StopBlock()
{
    bBlocking = false;
    if (MeleeCombat) MeleeCombat->SetBlocking(false);
    OnBlockChanged(false);
}

void ARPPlayerCharacter::HandleDeath()
{
    bBlocking = false;
    if (MeleeCombat) MeleeCombat->SetBlocking(false);

    bool bRespawned = false;
    if (UWorld* World = GetWorld())
    {
        if (URPRespawnSubsystem* Respawn = World->GetSubsystem<URPRespawnSubsystem>())
        {
            bRespawned = Respawn->RespawnPawn(this);
        }
    }

    if (!bRespawned)
    {
        SetActorTransform(InitialSpawnTransform, false, nullptr, ETeleportType::TeleportPhysics);
    }

    GetCharacterMovement()->StopMovementImmediately();
    Health->ResetHealth();
}

void ARPPlayerCharacter::ToggleView()
{
    if (CameraMode)
    {
        CameraMode->ToggleCameraMode();
    }
}

void ARPPlayerCharacter::SetMobileMoveInput(const FVector2D Value)
{
    MobileMoveInput = Value.GetClampedToMaxSize(1.0f);
}

void ARPPlayerCharacter::MobileJumpPressed()
{
    Jump();
}

void ARPPlayerCharacter::MobileJumpReleased()
{
    StopJumping();
}

void ARPPlayerCharacter::MobileAttack()
{
    Attack();
}

void ARPPlayerCharacter::MobileBlockPressed()
{
    StartBlock();
}

void ARPPlayerCharacter::MobileBlockReleased()
{
    StopBlock();
}
