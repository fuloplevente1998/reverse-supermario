#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "RPMobileQualitySubsystem.generated.h"

UENUM(BlueprintType)
enum class ERPMobileQuality : uint8
{
    Medium,
    High,
    Ultra
};

UCLASS()
class REVERSEPLATFORMERUE_API URPMobileQualitySubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintReadOnly, Category="Reverse Platformer|Mobile")
    ERPMobileQuality CurrentQuality = ERPMobileQuality::High;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Mobile")
    void ApplyQuality(ERPMobileQuality Quality);

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Mobile")
    float GetTargetFrameRate() const;
};
