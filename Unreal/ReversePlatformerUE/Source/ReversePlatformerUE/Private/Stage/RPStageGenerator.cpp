#include "Stage/RPStageGenerator.h"

#include "Components/SceneComponent.h"
#include "Engine/World.h"
#include "GameFramework/Pawn.h"
#include "Kismet/GameplayStatics.h"
#include "Stage/RPStageCatalog.h"
#include "Stage/RPStageDefinition.h"
#include "Stage/RPStageSegmentDefinition.h"
#include "Stage/RPStageSegmentActor.h"

ARPStageGenerator::ARPStageGenerator()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = 0.25f;
    SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    SetRootComponent(SceneRoot);
}

void ARPStageGenerator::BeginPlay()
{
    Super::BeginPlay();

    if (bGenerateOnBeginPlay)
    {
        GenerateStage();
    }
}

void ARPStageGenerator::Tick(const float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (bUseSegmentStreaming && bSpawnSegmentActors && GeneratedSegments.Num() > 0)
    {
        RefreshStreaming(false);
    }
}

void ARPStageGenerator::ClearGeneratedStage()
{
    for (AActor* Actor : SpawnedSegmentActors)
    {
        if (IsValid(Actor))
        {
            Actor->Destroy();
        }
    }

    SpawnedSegmentActors.Reset();
    LiveSegmentActors.Reset();
    GeneratedSegments.Reset();
    GeneratedLengthMeters = 0.0f;
    LastStreamingCenterMeters = -100000.0f;
}

float ARPStageGenerator::ResolveTargetLength(FRandomStream& Random, const FRPStageSpec& Spec) const
{
    if (TargetLengthOverrideMeters > 0.0f)
    {
        return TargetLengthOverrideMeters;
    }

    if (StageDefinition && StageDefinition->TargetLengthMeters > 0.0f)
    {
        return StageDefinition->TargetLengthMeters;
    }

    return Random.FRandRange(Spec.MinLengthMeters, Spec.MaxLengthMeters);
}

bool ARPStageGenerator::DifficultyAllows(const URPStageSegmentDefinition* Definition) const
{
    if (!Definition)
    {
        return false;
    }

    const uint8 Current = static_cast<uint8>(Difficulty);
    return Current >= static_cast<uint8>(Definition->MinimumDifficulty)
        && Current <= static_cast<uint8>(Definition->MaximumDifficulty);
}

URPStageSegmentDefinition* ARPStageGenerator::ChooseDefinition(const ERPStageSegmentType Type, FRandomStream& Random) const
{
    if (!StageDefinition)
    {
        return nullptr;
    }

    TArray<URPStageSegmentDefinition*> Candidates;
    float TotalWeight = 0.0f;

    for (URPStageSegmentDefinition* Definition : StageDefinition->SegmentPool)
    {
        if (Definition && Definition->SegmentType == Type && DifficultyAllows(Definition))
        {
            Candidates.Add(Definition);
            TotalWeight += FMath::Max(0.01f, Definition->SelectionWeight);
        }
    }

    if (Candidates.IsEmpty())
    {
        return nullptr;
    }

    float Pick = Random.FRandRange(0.0f, TotalWeight);
    for (URPStageSegmentDefinition* Candidate : Candidates)
    {
        Pick -= FMath::Max(0.01f, Candidate->SelectionWeight);
        if (Pick <= 0.0f)
        {
            return Candidate;
        }
    }

    return Candidates.Last();
}

ERPStageSegmentType ARPStageGenerator::ChooseBodySegmentType(
    FRandomStream& Random,
    const FRPStageSpec& Spec,
    const int32 SegmentIndex) const
{
    // A readable authored rhythm comes before unrestricted randomness.
    if (SegmentIndex % 7 == 5) return ERPStageSegmentType::Vista;
    if (SegmentIndex % 6 == 3) return ERPStageSegmentType::Bridge;
    if (SegmentIndex % 5 == 4) return ERPStageSegmentType::Hazard;
    if (SegmentIndex % 4 == 2) return ERPStageSegmentType::CombatLarge;

    const float Roll = Random.FRand();
    if (Roll < 0.26f) return ERPStageSegmentType::CombatSmall;
    if (Roll < 0.40f && Spec.BridgeCount > 0) return ERPStageSegmentType::Bridge;
    if (Roll < 0.52f && Spec.HazardCount > 0) return ERPStageSegmentType::Hazard;
    if (Roll < 0.64f) return ERPStageSegmentType::Stairs;
    if (Roll < 0.74f) return ERPStageSegmentType::Tower;
    return ERPStageSegmentType::Traversal;
}

void ARPStageGenerator::AddSegment(
    const ERPStageSegmentType Type,
    const float LengthMeters,
    const int32 Seed,
    const float StartMeter,
    FRandomStream&)
{
    FRPGeneratedSegment& Segment = GeneratedSegments.AddDefaulted_GetRef();
    Segment.Type = Type;
    Segment.StartMeter = StartMeter;
    Segment.LengthMeters = LengthMeters;
    Segment.Seed = Seed;
}

void ARPStageGenerator::SpawnSegmentActor(const int32 SegmentIndex)
{
    if (!bSpawnSegmentActors || !GeneratedSegments.IsValidIndex(SegmentIndex) || LiveSegmentActors.Contains(SegmentIndex))
    {
        return;
    }

    const FRPGeneratedSegment& Segment = GeneratedSegments[SegmentIndex];
    FRandomStream SegmentRandom(Segment.Seed);
    URPStageSegmentDefinition* Definition = ChooseDefinition(Segment.Type, SegmentRandom);
    if (!Definition || !Definition->SegmentActorClass)
    {
        return;
    }

    FActorSpawnParameters Params;
    Params.Owner = this;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

    const FVector Location = GetActorLocation()
        + FVector((Segment.StartMeter + Segment.LengthMeters * 0.5f) * 100.0f, 0.0f, 0.0f);

    AActor* SegmentActor = GetWorld()->SpawnActor<AActor>(
        Definition->SegmentActorClass,
        Location,
        GetActorRotation(),
        Params);

    if (!SegmentActor)
    {
        return;
    }

    SegmentActor->Tags.Add(FName(TEXT("GeneratedStageSegment")));
    SegmentActor->Tags.Add(FName(*UEnum::GetValueAsString(Segment.Type)));

    if (ARPStageSegmentActor* ModularSegment = Cast<ARPStageSegmentActor>(SegmentActor))
    {
        ModularSegment->SegmentType = Segment.Type;
        ModularSegment->LengthMeters = Segment.LengthMeters;
        ModularSegment->Seed = Segment.Seed;
        if (StageDefinition)
        {
            ModularSegment->Palette = StageDefinition->EnvironmentPalette;
        }
        ModularSegment->RebuildSegment();
    }

    SpawnedSegmentActors.Add(SegmentActor);
    LiveSegmentActors.Add(SegmentIndex, SegmentActor);
}

void ARPStageGenerator::DestroySegmentActor(const int32 SegmentIndex)
{
    if (TObjectPtr<AActor>* Found = LiveSegmentActors.Find(SegmentIndex))
    {
        AActor* Actor = Found->Get();
        if (IsValid(Actor))
        {
            SpawnedSegmentActors.Remove(Actor);
            Actor->Destroy();
        }
        LiveSegmentActors.Remove(SegmentIndex);
    }
}

void ARPStageGenerator::RefreshStreaming(const bool bForce)
{
    float CenterMeters = 0.0f;
    if (const APawn* Player = UGameplayStatics::GetPlayerPawn(this, 0))
    {
        CenterMeters = (Player->GetActorLocation().X - GetActorLocation().X) / 100.0f;
    }

    if (!bForce && FMath::Abs(CenterMeters - LastStreamingCenterMeters) < 12.0f)
    {
        return;
    }
    LastStreamingCenterMeters = CenterMeters;

    const float MinVisible = bUseSegmentStreaming ? CenterMeters - StreamingBehindMeters : -BIG_NUMBER;
    const float MaxVisible = bUseSegmentStreaming ? CenterMeters + StreamingAheadMeters : BIG_NUMBER;

    for (int32 Index = 0; Index < GeneratedSegments.Num(); ++Index)
    {
        const FRPGeneratedSegment& Segment = GeneratedSegments[Index];
        const float SegmentEnd = Segment.StartMeter + Segment.LengthMeters;
        const bool bNeeded = SegmentEnd >= MinVisible && Segment.StartMeter <= MaxVisible;

        if (bNeeded)
        {
            SpawnSegmentActor(Index);
        }
        else
        {
            DestroySegmentActor(Index);
        }
    }
}

void ARPStageGenerator::GenerateStage()
{
    ClearGeneratedStage();

    FRandomStream Random(GenerationSeed);
    const FRPStageSpec Spec = URPStageCatalog::GetStageSpec(StageId);
    const FRPDifficultyTuning Tuning = URPStageCatalog::GetDifficultyTuning(Difficulty);
    const float TargetLength = ResolveTargetLength(Random, Spec);

    float Cursor = 0.0f;
    int32 SegmentIndex = 0;
    float NextCheckpoint = Tuning.CheckpointIntervalMeters;

    const float StartLength = 40.0f;
    AddSegment(ERPStageSegmentType::Start, StartLength, Random.RandHelper(MAX_int32), Cursor, Random);
    Cursor += StartLength;

    const float ReservedEnding = 105.0f;
    const float BodyMeters = FMath::Max(200.0f, TargetLength - StartLength - ReservedEnding);
    const int32 DesiredBodySegments = FMath::Clamp(FMath::RoundToInt(BodyMeters / 38.0f), 10, 34);

    // Build a deterministic authored-looking segment bag from each stage spec.
    // This is what makes the ten stages share one generator without feeling
    // like the same level with a different texture.
    TArray<ERPStageSegmentType> BodyPlan;
    BodyPlan.Reserve(DesiredBodySegments);

    const int32 CombatTarget = FMath::Clamp(Spec.CombatCount, 3, DesiredBodySegments / 2);
    for (int32 Index = 0; Index < CombatTarget; ++Index)
    {
        const bool bLarge = Difficulty == ERPDifficulty::Hard
            ? (Index % 2 == 0)
            : (Difficulty == ERPDifficulty::Easy ? (Index % 4 == 3) : (Index % 3 == 2));
        BodyPlan.Add(bLarge ? ERPStageSegmentType::CombatLarge : ERPStageSegmentType::CombatSmall);
    }

    for (int32 Index = 0; Index < FMath::Min(Spec.VistaCount, 6); ++Index)
    {
        BodyPlan.Add(ERPStageSegmentType::Vista);
    }
    for (int32 Index = 0; Index < FMath::Min(Spec.BridgeCount, 6); ++Index)
    {
        BodyPlan.Add(ERPStageSegmentType::Bridge);
    }
    for (int32 Index = 0; Index < FMath::Min(Spec.HazardCount, 6); ++Index)
    {
        BodyPlan.Add(ERPStageSegmentType::Hazard);
    }

    BodyPlan.Add(ERPStageSegmentType::Tower);
    BodyPlan.Add(ERPStageSegmentType::Stairs);

    while (BodyPlan.Num() < DesiredBodySegments)
    {
        BodyPlan.Add((BodyPlan.Num() % 4 == 0)
            ? ERPStageSegmentType::ArcherAmbush
            : ERPStageSegmentType::Traversal);
    }

    // Trim lower-priority overflow while preserving the stage's combat/vista identity.
    while (BodyPlan.Num() > DesiredBodySegments)
    {
        int32 RemoveIndex = BodyPlan.FindLastByPredicate([](const ERPStageSegmentType Type)
        {
            return Type == ERPStageSegmentType::Traversal
                || Type == ERPStageSegmentType::Stairs
                || Type == ERPStageSegmentType::Tower;
        });
        if (RemoveIndex == INDEX_NONE)
        {
            RemoveIndex = BodyPlan.Num() - 1;
        }
        BodyPlan.RemoveAt(RemoveIndex);
    }

    // Fisher-Yates with FRandomStream keeps the same seed reproducible.
    for (int32 Index = BodyPlan.Num() - 1; Index > 0; --Index)
    {
        const int32 SwapIndex = Random.RandRange(0, Index);
        BodyPlan.Swap(Index, SwapIndex);
    }

    while (Cursor < TargetLength - ReservedEnding)
    {
        ERPStageSegmentType Type;
        if (Cursor >= NextCheckpoint)
        {
            Type = ERPStageSegmentType::Checkpoint;
            NextCheckpoint += Tuning.CheckpointIntervalMeters;
        }
        else if (BodyPlan.IsValidIndex(SegmentIndex))
        {
            Type = BodyPlan[SegmentIndex++];
        }
        else
        {
            Type = ChooseBodySegmentType(Random, Spec, SegmentIndex++);
        }

        FRandomStream PreviewRandom(Random.RandHelper(MAX_int32));
        URPStageSegmentDefinition* Definition = ChooseDefinition(Type, PreviewRandom);
        const float BaseLength = Definition ? Definition->LengthMeters : Random.FRandRange(30.0f, 48.0f);
        const float Remaining = TargetLength - ReservedEnding - Cursor;
        const float Length = FMath::Clamp(BaseLength, 18.0f, FMath::Max(18.0f, Remaining));
        const int32 SegmentSeed = Random.RandHelper(MAX_int32);

        AddSegment(Type, Length, SegmentSeed, Cursor, Random);
        Cursor += Length;

        if (Remaining <= 20.0f)
        {
            break;
        }
    }

    const float MiniBossLength = 60.0f;
    AddSegment(ERPStageSegmentType::MiniBoss, MiniBossLength, Random.RandHelper(MAX_int32), Cursor, Random);
    Cursor += MiniBossLength;

    const float FinishLength = FMath::Max(45.0f, TargetLength - Cursor);
    AddSegment(ERPStageSegmentType::Finish, FinishLength, Random.RandHelper(MAX_int32), Cursor, Random);
    Cursor += FinishLength;

    GeneratedLengthMeters = Cursor;
    RefreshStreaming(true);

    UE_LOG(LogTemp, Log, TEXT("Generated stage %d: %.1f m, %d segments, difficulty %d, seed %d"),
        static_cast<int32>(StageId),
        GeneratedLengthMeters,
        GeneratedSegments.Num(),
        static_cast<int32>(Difficulty),
        GenerationSeed);
}
