#include "Combat/RPHealthComponent.h"

URPHealthComponent::URPHealthComponent()
{
    PrimaryComponentTick.bCanEverTick = false;
}

void URPHealthComponent::BeginPlay()
{
    Super::BeginPlay();
    ResetHealth();
}

float URPHealthComponent::ApplyDamage(const float Amount)
{
    if (Amount <= 0.0f || IsDead())
    {
        return Health;
    }

    Health = FMath::Clamp(Health - Amount, 0.0f, MaxHealth);
    OnHealthChanged.Broadcast(Health, MaxHealth);

    if (IsDead())
    {
        OnDeath.Broadcast();
    }

    return Health;
}

float URPHealthComponent::Heal(const float Amount)
{
    if (Amount <= 0.0f || IsDead())
    {
        return Health;
    }

    Health = FMath::Clamp(Health + Amount, 0.0f, MaxHealth);
    OnHealthChanged.Broadcast(Health, MaxHealth);
    return Health;
}

void URPHealthComponent::ResetHealth()
{
    Health = MaxHealth;
    OnHealthChanged.Broadcast(Health, MaxHealth);
}
