#include "Stage/RPModularEnvironmentComponent.h"

#include "Components/HierarchicalInstancedStaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/Actor.h"
#include "Stage/RPEnvironmentPalette.h"

URPModularEnvironmentComponent::URPModularEnvironmentComponent()
{
    PrimaryComponentTick.bCanEverTick = false;
}

void URPModularEnvironmentComponent::ClearEnvironment()
{
    for (UHierarchicalInstancedStaticMeshComponent* Bucket : Buckets)
    {
        if (IsValid(Bucket))
        {
            Bucket->ClearInstances();
            Bucket->DestroyComponent();
        }
    }
    Buckets.Reset();
}

UHierarchicalInstancedStaticMeshComponent* URPModularEnvironmentComponent::GetOrCreateBucket(UStaticMesh* Mesh)
{
    if (!Mesh || !GetOwner())
    {
        return nullptr;
    }

    for (UHierarchicalInstancedStaticMeshComponent* Existing : Buckets)
    {
        if (Existing && Existing->GetStaticMesh() == Mesh)
        {
            return Existing;
        }
    }

    UHierarchicalInstancedStaticMeshComponent* Bucket =
        NewObject<UHierarchicalInstancedStaticMeshComponent>(GetOwner());
    Bucket->SetStaticMesh(Mesh);
    Bucket->SetMobility(EComponentMobility::Static);
    Bucket->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
    Bucket->SetGenerateOverlapEvents(false);
    Bucket->NumCustomDataFloats = 1;
    Bucket->RegisterComponent();
    Bucket->AttachToComponent(GetOwner()->GetRootComponent(), FAttachmentTransformRules::KeepRelativeTransform);
    Buckets.Add(Bucket);
    return Bucket;
}

UStaticMesh* URPModularEnvironmentComponent::PickMesh(
    const TArray<TSoftObjectPtr<UStaticMesh>>& Pool,
    FRandomStream& Random) const
{
    if (Pool.IsEmpty())
    {
        return nullptr;
    }

    const int32 Start = Random.RandRange(0, Pool.Num() - 1);
    for (int32 Offset = 0; Offset < Pool.Num(); ++Offset)
    {
        const int32 Index = (Start + Offset) % Pool.Num();
        if (!Pool[Index].IsNull())
        {
            if (UStaticMesh* Mesh = Pool[Index].LoadSynchronous())
            {
                return Mesh;
            }
        }
    }

    return nullptr;
}

float URPModularEnvironmentComponent::MeshLengthMeters(const UStaticMesh* Mesh, const float FallbackMeters) const
{
    if (!Mesh)
    {
        return FallbackMeters;
    }

    const float LengthCm = Mesh->GetBounds().BoxExtent.X * 2.0f;
    return LengthCm > 20.0f ? LengthCm / 100.0f : FallbackMeters;
}

void URPModularEnvironmentComponent::AddFloor(FRandomStream& Random)
{
    float Cursor = 0.0f;
    while (Cursor < LengthMeters)
    {
        UStaticMesh* Mesh = PickMesh(Palette->FloorModules, Random);
        if (!Mesh)
        {
            return;
        }

        const float ModuleLength = FMath::Clamp(MeshLengthMeters(Mesh, 4.0f), 1.0f, 15.0f);
        UHierarchicalInstancedStaticMeshComponent* Bucket = GetOrCreateBucket(Mesh);
        if (!Bucket)
        {
            return;
        }

        const FVector Location((Cursor + ModuleLength * 0.5f) * 100.0f, 0.0f, 0.0f);
        FTransform Transform(FRotator::ZeroRotator, Location, FVector::OneVector);
        const int32 Instance = Bucket->AddInstance(Transform);
        Bucket->SetCustomDataValue(Instance, 0, Random.FRand(), false);

        Cursor += ModuleLength;
    }
}

void URPModularEnvironmentComponent::AddWalls(FRandomStream& Random)
{
    if (Palette->WallModules.IsEmpty())
    {
        return;
    }

    for (const float Side : {-1.0f, 1.0f})
    {
        float Cursor = 0.0f;
        while (Cursor < LengthMeters)
        {
            UStaticMesh* Mesh = PickMesh(Palette->WallModules, Random);
            if (!Mesh)
            {
                break;
            }

            const float ModuleLength = FMath::Clamp(MeshLengthMeters(Mesh, 5.0f), 1.0f, 20.0f);
            UHierarchicalInstancedStaticMeshComponent* Bucket = GetOrCreateBucket(Mesh);
            const FVector Location(
                (Cursor + ModuleLength * 0.5f) * 100.0f,
                Side * PlayableWidthMeters * 50.0f,
                0.0f);
            const FRotator Rotation(0.0f, Side < 0.0f ? 180.0f : 0.0f, 0.0f);
            if (Bucket)
            {
                Bucket->AddInstance(FTransform(Rotation, Location, FVector::OneVector));
            }
            Cursor += ModuleLength;
        }
    }
}

void URPModularEnvironmentComponent::AddDecoration(FRandomStream& Random)
{
    const int32 PropCount = FMath::RoundToInt(LengthMeters * 0.16f * DecorationDensity);
    const int32 VegetationCount = FMath::RoundToInt(LengthMeters * 0.24f * DecorationDensity);

    auto ScatterPool = [this, &Random](const TArray<TSoftObjectPtr<UStaticMesh>>& Pool, int32 Count, float SideOffsetMeters)
    {
        for (int32 Index = 0; Index < Count; ++Index)
        {
            UStaticMesh* Mesh = PickMesh(Pool, Random);
            UHierarchicalInstancedStaticMeshComponent* Bucket = GetOrCreateBucket(Mesh);
            if (!Bucket)
            {
                continue;
            }

            const float X = Random.FRandRange(0.0f, LengthMeters) * 100.0f;
            const float Side = Random.FRand() < 0.5f ? -1.0f : 1.0f;
            const float Y = Side * Random.FRandRange(
                PlayableWidthMeters * 0.55f,
                PlayableWidthMeters * 0.5f + SideOffsetMeters) * 100.0f;
            const float Yaw = Random.FRandRange(-180.0f, 180.0f);
            const float Scale = Random.FRandRange(0.88f, 1.14f);
            Bucket->AddInstance(FTransform(FRotator(0.0f, Yaw, 0.0f), FVector(X,Y,0.0f), FVector(Scale)));
        }
    };

    ScatterPool(Palette->Props, PropCount, 3.0f);
    ScatterPool(Palette->Vegetation, VegetationCount, 5.0f);
}

void URPModularEnvironmentComponent::BuildEnvironment()
{
    ClearEnvironment();

    if (!Palette || !GetOwner() || !GetOwner()->GetRootComponent())
    {
        UE_LOG(LogTemp, Warning, TEXT("Modular environment has no palette or valid owner root."));
        return;
    }

    FRandomStream Random(Seed);
    AddFloor(Random);
    AddWalls(Random);
    AddDecoration(Random);

    UE_LOG(LogTemp, Log, TEXT("Built modular environment: %.1f m, %d HISM buckets, seed %d"),
        LengthMeters, Buckets.Num(), Seed);
}
