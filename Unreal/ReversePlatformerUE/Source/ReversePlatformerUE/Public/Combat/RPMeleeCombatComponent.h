#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "RPMeleeCombatComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FRPMeleeHit, AActor*, HitActor);

UCLASS(ClassGroup=(ReversePlatformer), meta=(BlueprintSpawnableComponent))
class REVERSEPLATFORMERUE_API URPMeleeCombatComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    URPMeleeCombatComponent();

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat", meta=(ClampMin="0.0"))
    float Damage = 30.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat", meta=(ClampMin="20.0"))
    float Range = 190.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat", meta=(ClampMin="10.0"))
    float SweepRadius = 65.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat", meta=(ClampMin="0.05"))
    float Cooldown = 0.55f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat", meta=(ClampMin="0.0", ClampMax="1.0"))
    float BlockDamageMultiplier = 0.25f;

    UPROPERTY(BlueprintReadOnly, Category="Combat")
    bool bBlocking = false;

    UPROPERTY(BlueprintAssignable, Category="Combat")
    FRPMeleeHit OnMeleeHit;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Combat")
    bool TryAttack();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Combat")
    void SetBlocking(bool bNewBlocking);

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Combat")
    bool CanAttack() const;

private:
    double NextAttackTime = 0.0;
};
