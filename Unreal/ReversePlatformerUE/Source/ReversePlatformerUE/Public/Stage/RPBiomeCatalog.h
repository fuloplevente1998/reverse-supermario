#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "Stage/RPBiomeRecipe.h"
#include "RPBiomeCatalog.generated.h"

UCLASS()
class REVERSEPLATFORMERUE_API URPBiomeCatalog : public UBlueprintFunctionLibrary
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintPure, Category="Reverse Platformer|Biome")
    static FRPBiomeRecipe GetBiomeRecipe(ERPStageId StageId);
};
