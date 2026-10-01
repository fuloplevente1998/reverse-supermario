#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Stage/RPStageTypes.h"
#include "RPStageGenerator.generated.h"

class URPStageDefinition;
class URPStageSegmentDefinition;
class USceneComponent;

UCLASS(Blueprintable)
class REVERSEPLATFORMERUE_API ARPStageGenerator : public AActor
{
    GENERATED_BODY()

public:
    ARPStageGenerator();

    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Stage")
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage")
    ERPStageId StageId = ERPStageId::Courtyard;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage")
    ERPDifficulty Difficulty = ERPDifficulty::Normal;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage")
    int32 GenerationSeed = 1001;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage")
    float TargetLengthOverrideMeters = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage")
    TObjectPtr<URPStageDefinition> StageDefinition;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage")
    bool bGenerateOnBeginPlay = true;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage")
    bool bSpawnSegmentActors = true;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage|Streaming")
    bool bUseSegmentStreaming = true;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage|Streaming", meta=(ClampMin="50.0"))
    float StreamingAheadMeters = 240.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stage|Streaming", meta=(ClampMin="20.0"))
    float StreamingBehindMeters = 90.0f;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Stage")
    TArray<FRPGeneratedSegment> GeneratedSegments;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Stage")
    void GenerateStage();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Stage")
    void ClearGeneratedStage();

    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Stage")
    float GetGeneratedLengthMeters() const { return GeneratedLengthMeters; }

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Stage")
    void RefreshStreaming(bool bForce = false);

protected:
    ERPStageSegmentType ChooseBodySegmentType(FRandomStream& Random, const FRPStageSpec& Spec, int32 SegmentIndex) const;
    URPStageSegmentDefinition* ChooseDefinition(ERPStageSegmentType Type, FRandomStream& Random) const;
    void AddSegment(ERPStageSegmentType Type, float LengthMeters, int32 Seed, float StartMeter, FRandomStream& Random);
    void SpawnSegmentActor(int32 SegmentIndex);
    void DestroySegmentActor(int32 SegmentIndex);
    float ResolveTargetLength(FRandomStream& Random, const FRPStageSpec& Spec) const;
    bool DifficultyAllows(const URPStageSegmentDefinition* Definition) const;

    UPROPERTY(Transient)
    TArray<TObjectPtr<AActor>> SpawnedSegmentActors;

    UPROPERTY(Transient)
    TMap<int32, TObjectPtr<AActor>> LiveSegmentActors;

    float GeneratedLengthMeters = 0.0f;
    float LastStreamingCenterMeters = -100000.0f;
};
