#include "Combat/RPMeleeCombatComponent.h"

#include "Combat/RPHealthComponent.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"

URPMeleeCombatComponent::URPMeleeCombatComponent()
{
    PrimaryComponentTick.bCanEverTick = false;
}

bool URPMeleeCombatComponent::CanAttack() const
{
    const UWorld* World = GetWorld();
    return World && !bBlocking && World->GetTimeSeconds() >= NextAttackTime;
}

void URPMeleeCombatComponent::SetBlocking(const bool bNewBlocking)
{
    bBlocking = bNewBlocking;
}

bool URPMeleeCombatComponent::TryAttack()
{
    UWorld* World = GetWorld();
    AActor* Owner = GetOwner();
    if (!World || !Owner || !CanAttack())
    {
        return false;
    }

    NextAttackTime = World->GetTimeSeconds() + Cooldown;

    const FVector Start = Owner->GetActorLocation() + FVector(0.0f, 0.0f, 70.0f);
    const FVector End = Start + Owner->GetActorForwardVector() * Range;

    FCollisionQueryParams Params(SCENE_QUERY_STAT(RPMeleeAttack), false, Owner);
    TArray<FHitResult> Hits;
    const FCollisionShape Shape = FCollisionShape::MakeSphere(SweepRadius);

    const bool bHit = World->SweepMultiByChannel(
        Hits,
        Start,
        End,
        FQuat::Identity,
        ECC_Pawn,
        Shape,
        Params);

    if (!bHit)
    {
        return true;
    }

    TSet<AActor*> DamagedActors;
    for (const FHitResult& Hit : Hits)
    {
        AActor* HitActor = Hit.GetActor();
        if (!HitActor || DamagedActors.Contains(HitActor))
        {
            continue;
        }

        if (URPHealthComponent* Health = HitActor->FindComponentByClass<URPHealthComponent>())
        {
            float FinalDamage = Damage;
            if (const URPMeleeCombatComponent* Defender = HitActor->FindComponentByClass<URPMeleeCombatComponent>())
            {
                if (Defender->bBlocking)
                {
                    const FVector ToAttacker = (Owner->GetActorLocation() - HitActor->GetActorLocation()).GetSafeNormal2D();
                    const float Facing = FVector::DotProduct(HitActor->GetActorForwardVector().GetSafeNormal2D(), ToAttacker);
                    if (Facing > 0.15f)
                    {
                        FinalDamage *= Defender->BlockDamageMultiplier;
                    }
                }
            }

            Health->ApplyDamage(FinalDamage);
            DamagedActors.Add(HitActor);
            OnMeleeHit.Broadcast(HitActor);
        }
    }

    return true;
}
