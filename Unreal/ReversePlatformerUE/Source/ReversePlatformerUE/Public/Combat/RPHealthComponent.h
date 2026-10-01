#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "RPHealthComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FRPHealthChanged, float, CurrentHealth, float, MaxHealth);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FRPDeathEvent);

UCLASS(ClassGroup=(ReversePlatformer), meta=(BlueprintSpawnableComponent))
class REVERSEPLATFORMERUE_API URPHealthComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    URPHealthComponent();

    virtual void BeginPlay() override;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Health", meta=(ClampMin="1.0"))
    float MaxHealth = 100.0f;

    UPROPERTY(BlueprintAssignable, Category="Health")
    FRPHealthChanged OnHealthChanged;

    UPROPERTY(BlueprintAssignable, Category="Health")
    FRPDeathEvent OnDeath;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Health")
    float ApplyDamage(float Amount);

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Health")
    float Heal(float Amount);

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Health")
    void ResetHealth();

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Health")
    float GetHealth() const { return Health; }

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Health")
    float GetHealthNormalized() const { return MaxHealth > 0.0f ? Health / MaxHealth : 0.0f; }

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Health")
    bool IsDead() const { return Health <= 0.0f; }

private:
    float Health = 100.0f;
};
