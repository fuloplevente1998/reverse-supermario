#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "RPModularEnvironmentComponent.generated.h"

class UHierarchicalInstancedStaticMeshComponent;
class URPEnvironmentPalette;
class UStaticMesh;

UCLASS(ClassGroup=(ReversePlatformer), meta=(BlueprintSpawnableComponent))
class REVERSEPLATFORMERUE_API URPModularEnvironmentComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    URPModularEnvironmentComponent();

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Environment")
    TObjectPtr<URPEnvironmentPalette> Palette;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Environment", meta=(ClampMin="5.0"))
    float LengthMeters = 40.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Environment", meta=(ClampMin="2.0"))
    float PlayableWidthMeters = 7.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Environment")
    int32 Seed = 1001;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Environment", meta=(ClampMin="0.0", ClampMax="2.0"))
    float DecorationDensity = 1.0f;

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Environment")
    void BuildEnvironment();

    UFUNCTION(BlueprintCallable, Category="Reverse Platformer|Environment")
    void ClearEnvironment();

protected:
    UHierarchicalInstancedStaticMeshComponent* GetOrCreateBucket(UStaticMesh* Mesh);
    UStaticMesh* PickMesh(const TArray<TSoftObjectPtr<UStaticMesh>>& Pool, FRandomStream& Random) const;
    float MeshLengthMeters(const UStaticMesh* Mesh, float FallbackMeters) const;
    void AddFloor(FRandomStream& Random);
    void AddWalls(FRandomStream& Random);
    void AddDecoration(FRandomStream& Random);

    UPROPERTY(Transient)
    TArray<TObjectPtr<UHierarchicalInstancedStaticMeshComponent>> Buckets;
};
