#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "RPEnemyCharacter.generated.h"

class URPHealthComponent;
class URPEncounterDirectorComponent;
class URPMeleeCombatComponent;

UENUM(BlueprintType)
enum class ERPEnemyArchetype : uint8
{
    Guard,
    ShieldGuard,
    Archer,
    Scout,
    Brute,
    Elite,
    Boss
};

UCLASS()
class REVERSEPLATFORMERUE_API ARPEnemyCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    ARPEnemyCharacter();

    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Combat")
    TObjectPtr<URPHealthComponent> Health;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Combat")
    TObjectPtr<URPMeleeCombatComponent> MeleeCombat;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat")
    ERPEnemyArchetype Archetype = ERPEnemyArchetype::Guard;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat", meta=(ClampMin="0.0"))
    float BaseDamage = 12.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat", meta=(ClampMin="0.0"))
    float AttackRange = 180.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat", meta=(ClampMin="0.1"))
    float AttackCooldown = 1.0f;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Combat")
    float GetDifficultyAdjustedDamage() const;

    UFUNCTION(BlueprintImplementableEvent, Category="Reverse Platformer|Combat")
    void OnEnemyDeath();

protected:
    UFUNCTION()
    void HandleDeath();
};
