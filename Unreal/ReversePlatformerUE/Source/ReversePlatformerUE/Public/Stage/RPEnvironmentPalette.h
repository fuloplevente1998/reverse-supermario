#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInterface.h"
#include "RPEnvironmentPalette.generated.h"

UCLASS(BlueprintType)
class REVERSEPLATFORMERUE_API URPEnvironmentPalette : public UPrimaryDataAsset
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Architecture")
    TArray<TSoftObjectPtr<UStaticMesh>> FloorModules;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Architecture")
    TArray<TSoftObjectPtr<UStaticMesh>> WallModules;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Architecture")
    TArray<TSoftObjectPtr<UStaticMesh>> Pillars;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Architecture")
    TArray<TSoftObjectPtr<UStaticMesh>> Arches;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Architecture")
    TArray<TSoftObjectPtr<UStaticMesh>> Bridges;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Decoration")
    TArray<TSoftObjectPtr<UStaticMesh>> Props;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Decoration")
    TArray<TSoftObjectPtr<UStaticMesh>> Vegetation;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Decoration")
    TArray<TSoftObjectPtr<UStaticMesh>> HeroVistaMeshes;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Materials")
    TSoftObjectPtr<UMaterialInterface> GroundMaterial;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Materials")
    TSoftObjectPtr<UMaterialInterface> AccentMaterial;
};
