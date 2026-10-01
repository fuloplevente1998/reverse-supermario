#include "Combat/RPEnemyCharacter.h"

#include "Combat/RPEncounterDirectorComponent.h"
#include "Combat/RPHealthComponent.h"
#include "GameFramework/CharacterMovementComponent.h"

ARPEnemyCharacter::ARPEnemyCharacter()
{
    PrimaryActorTick.bCanEverTick = true;

    Health = CreateDefaultSubobject<URPHealthComponent>(TEXT("Health"));
    GetCharacterMovement()->MaxWalkSpeed = 320.0f;
}

void ARPEnemyCharacter::BeginPlay()
{
    Super::BeginPlay();
    Health->OnDeath.AddDynamic(this, &ARPEnemyCharacter::HandleDeath);
}

float ARPEnemyCharacter::GetDifficultyAdjustedDamage() const
{
    if (const AActor* OwnerActor = GetOwner())
    {
        if (const URPEncounterDirectorComponent* Director = OwnerActor->FindComponentByClass<URPEncounterDirectorComponent>())
        {
            return Director->GetAdjustedEnemyDamage(BaseDamage);
        }
    }

    return BaseDamage;
}

void ARPEnemyCharacter::HandleDeath()
{
    OnEnemyDeath();
    SetActorEnableCollision(false);
    GetCharacterMovement()->DisableMovement();
    SetLifeSpan(2.0f);
}
