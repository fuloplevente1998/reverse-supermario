#include "Stage/RPStageGenerator.h"

#include "Components/SceneComponent.h"
#include "Engine/World.h"
#include "Stage/RPStageCatalog.h"
#include "Stage/RPStageDefinition.h"
#include "Stage/RPStageSegmentDefinition.h"
#include "Stage/RPStageSegmentActor.h"

ARPStageGenerator::ARPStageGenerator()
{
    PrimaryActorTick.bCanEverTick = false;
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
    GeneratedSegments.Reset();
    GeneratedLengthMeters = 0.0f;
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
    // Deterministic grammar: combat/traversal remain the backbone while biome
    // identity is expressed by authored segment definitions and environment assets.
    if (SegmentIndex % 7 == 5)
    {
        return ERPStageSegmentType::Vista;
    }
    if (SegmentIndex % 6 == 3)
    {
        return ERPStageSegmentType::Bridge;
    }
    if (SegmentIndex % 5 == 4)
    {
        return ERPStageSegmentType::Hazard;
    }
    if (SegmentIndex % 4 == 2)
    {
        return ERPStageSegmentType::CombatLarge;
    }

    const float Roll = Random.FRand();
    if (Roll < 0.26f)
    {
        return ERPStageSegmentType::CombatSmall;
    }
    if (Roll < 0.40f && Spec.BridgeCount > 0)
    {
        return ERPStageSegmentType::Bridge;
    }
    if (Roll < 0.52f && Spec.HazardCount > 0)
    {
        return ERPStageSegmentType::Hazard;
    }
    if (Roll < 0.64f)
    {
        return ERPStageSegmentType::Stairs;
    }
    if (Roll < 0.74f)
    {
        return ERPStageSegmentType::Tower;
    }
    return ERPStageSegmentType::Traversal;
}

void ARPStageGenerator::AddSegment(
    const ERPStageSegmentType Type,
    const float LengthMeters,
    const int32 Seed,
    const float StartMeter,
    FRandomStream& Random)
{
    FRPGeneratedSegment& Segment = GeneratedSegments.AddDefaulted_GetRef();
    Segment.Type = Type;
    Segment.StartMeter = StartMeter;
    Segment.LengthMeters = LengthMeters;
    Segment.Seed = Seed;

    if (!bSpawnSegmentActors)
    {
        return;
    }

    URPStageSegmentDefinition* Definition = ChooseDefinition(Type, Random);
    if (!Definition || !Definition->SegmentActorClass)
    {
        return;
    }

    FActorSpawnParameters Params;
    Params.Owner = this;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

    const FVector Location = GetActorLocation() + FVector((StartMeter + LengthMeters * 0.5f) * 100.0f, 0.0f, 0.0f);
    AActor* SegmentActor = GetWorld()->SpawnActor<AActor>(
        Definition->SegmentActorClass,
        Location,
        GetActorRotation(),
        Params);

    if (SegmentActor)
    {
        SegmentActor->Tags.Add(FName(TEXT("GeneratedStageSegment")));
        SegmentActor->Tags.Add(FName(*UEnum::GetValueAsString(Type)));

        if (ARPStageSegmentActor* ModularSegment = Cast<ARPStageSegmentActor>(SegmentActor))
        {
            ModularSegment->SegmentType = Type;
            ModularSegment->LengthMeters = LengthMeters;
            ModularSegment->Seed = Seed;
            if (StageDefinition)
            {
                ModularSegment->Palette = StageDefinition->EnvironmentPalette;
            }
            ModularSegment->RebuildSegment();
        }

        SpawnedSegmentActors.Add(SegmentActor);
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
    while (Cursor < TargetLength - ReservedEnding)
    {
        ERPStageSegmentType Type;
        if (Cursor >= NextCheckpoint)
        {
            Type = ERPStageSegmentType::Checkpoint;
            NextCheckpoint += Tuning.CheckpointIntervalMeters;
        }
        else
        {
            Type = ChooseBodySegmentType(Random, Spec, SegmentIndex);
        }

        URPStageSegmentDefinition* Definition = ChooseDefinition(Type, Random);
        const float BaseLength = Definition ? Definition->LengthMeters : Random.FRandRange(32.0f, 58.0f);
        const float Remaining = TargetLength - ReservedEnding - Cursor;
        const float Length = FMath::Clamp(BaseLength, 18.0f, FMath::Max(18.0f, Remaining));

        AddSegment(Type, Length, Random.RandHelper(MAX_int32), Cursor, Random);
        Cursor += Length;
        ++SegmentIndex;

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

    UE_LOG(LogTemp, Log, TEXT("Generated stage %d: %.1f m, %d segments, difficulty %d, seed %d"),
        static_cast<int32>(StageId),
        GeneratedLengthMeters,
        GeneratedSegments.Num(),
        static_cast<int32>(Difficulty),
        GenerationSeed);
}
