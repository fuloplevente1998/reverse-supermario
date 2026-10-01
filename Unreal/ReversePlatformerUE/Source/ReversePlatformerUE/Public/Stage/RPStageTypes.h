#pragma once

#include "CoreMinimal.h"
#include "RPStageTypes.generated.h"

UENUM(BlueprintType)
enum class ERPStageId : uint8
{
    Courtyard = 1 UMETA(DisplayName="1. Várudvar"),
    RoyalGardens = 2 UMETA(DisplayName="2. A Királyi Kertek"),
    EagleCliff = 3 UMETA(DisplayName="3. Sas-szirt"),
    FrozenBastion = 4 UMETA(DisplayName="4. Dermedt Bástya"),
    Forge = 5 UMETA(DisplayName="5. Vaskohó"),
    WindmillValley = 6 UMETA(DisplayName="6. Szélmalom-völgy"),
    Catacombs = 7 UMETA(DisplayName="7. Az Elfeledett Katakombák"),
    ShadowCanyon = 8 UMETA(DisplayName="8. Árnyékszurdok"),
    BlackForest = 9 UMETA(DisplayName="9. Feketeerdő Erődje"),
    CrownCitadel = 10 UMETA(DisplayName="10. A Korona Citadellája")
};

UENUM(BlueprintType)
enum class ERPDifficulty : uint8
{
    Easy,
    Normal,
    Hard
};

UENUM(BlueprintType)
enum class ERPCameraMode : uint8
{
    SideView,
    ThirdPerson
};

UENUM(BlueprintType)
enum class ERPStageSegmentType : uint8
{
    Start,
    Traversal,
    CombatSmall,
    CombatLarge,
    Bridge,
    Gap,
    Stairs,
    Hazard,
    ArcherAmbush,
    Vista,
    Checkpoint,
    Tower,
    Gate,
    MiniBoss,
    Finish
};

USTRUCT(BlueprintType)
struct FRPDifficultyTuning
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float EnemyCountMultiplier = 1.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float EnemyDamageMultiplier = 1.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float HazardSpeedMultiplier = 1.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float HealingMultiplier = 1.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float CheckpointIntervalMeters = 150.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float EliteChance = 0.08f;
};

USTRUCT(BlueprintType)
struct FRPStageSpec
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    ERPStageId StageId = ERPStageId::Courtyard;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FText DisplayName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FText Subtitle;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FText GoalText;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float MinLengthMeters = 700.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float MaxLengthMeters = 800.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FLinearColor PrimaryColor = FLinearColor::White;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FLinearColor AccentColor = FLinearColor::Red;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    int32 VistaCount = 3;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    int32 CombatCount = 8;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    int32 BridgeCount = 2;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    int32 HazardCount = 2;
};

USTRUCT(BlueprintType)
struct FRPGeneratedSegment
{
    GENERATED_BODY()

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    ERPStageSegmentType Type = ERPStageSegmentType::Traversal;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    float StartMeter = 0.0f;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    float LengthMeters = 40.0f;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    int32 Seed = 0;
};
