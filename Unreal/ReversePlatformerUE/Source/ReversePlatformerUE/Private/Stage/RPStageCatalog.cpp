#include "Stage/RPStageCatalog.h"

namespace
{
FRPStageSpec MakeStage(
    ERPStageId Id,
    const TCHAR* Name,
    const TCHAR* Subtitle,
    const TCHAR* Goal,
    float MinLength,
    float MaxLength,
    FLinearColor Primary,
    FLinearColor Accent,
    int32 Vistas,
    int32 Combat,
    int32 Bridges,
    int32 Hazards)
{
    FRPStageSpec S;
    S.StageId = Id;
    S.DisplayName = FText::FromString(Name);
    S.Subtitle = FText::FromString(Subtitle);
    S.GoalText = FText::FromString(Goal);
    S.MinLengthMeters = MinLength;
    S.MaxLengthMeters = MaxLength;
    S.PrimaryColor = Primary;
    S.AccentColor = Accent;
    S.VistaCount = Vistas;
    S.CombatCount = Combat;
    S.BridgeCount = Bridges;
    S.HazardCount = Hazards;
    return S;
}
}

FRPStageSpec URPStageCatalog::GetStageSpec(const ERPStageId StageId)
{
    switch (StageId)
    {
        case ERPStageId::Courtyard:
            return MakeStage(StageId, TEXT("Várudvar"), TEXT("A Belső Kapu"), TEXT("Érd el a belső kaput"),
                700.f, 800.f, FLinearColor(0.78f,0.66f,0.49f), FLinearColor(0.52f,0.04f,0.07f), 3, 8, 2, 2);
        case ERPStageId::RoyalGardens:
            return MakeStage(StageId, TEXT("A Királyi Kertek"), TEXT("Az Elveszett Ösvény"), TEXT("Találd meg az ösvényt"),
                750.f, 850.f, FLinearColor(0.30f,0.58f,0.22f), FLinearColor(0.70f,0.05f,0.08f), 4, 8, 4, 2);
        case ERPStageId::EagleCliff:
            return MakeStage(StageId, TEXT("Sas-szirt"), TEXT("A Mélység Felett"), TEXT("Juss át a szakadékon"),
                800.f, 900.f, FLinearColor(0.42f,0.45f,0.43f), FLinearColor(0.68f,0.08f,0.08f), 5, 9, 5, 4);
        case ERPStageId::FrozenBastion:
            return MakeStage(StageId, TEXT("Dermedt Bástya"), TEXT("A Jégkapu"), TEXT("Nyisd meg a jégkaput"),
                800.f, 900.f, FLinearColor(0.55f,0.72f,0.88f), FLinearColor(0.06f,0.25f,0.70f), 4, 9, 3, 5);
        case ERPStageId::Forge:
            return MakeStage(StageId, TEXT("Vaskohó"), TEXT("A Tűz Negyede"), TEXT("Juss át a kohón"),
                850.f, 950.f, FLinearColor(0.16f,0.13f,0.11f), FLinearColor(1.00f,0.23f,0.02f), 3, 10, 3, 6);
        case ERPStageId::WindmillValley:
            return MakeStage(StageId, TEXT("Szélmalom-völgy"), TEXT("Az Ostrom Előtt"), TEXT("Haladj a falu felé"),
                850.f, 950.f, FLinearColor(0.68f,0.52f,0.25f), FLinearColor(0.62f,0.05f,0.07f), 5, 9, 4, 3);
        case ERPStageId::Catacombs:
            return MakeStage(StageId, TEXT("Az Elfeledett Katakombák"), TEXT("A Holtak Útja"), TEXT("Találd meg a kijáratot"),
                900.f, 1000.f, FLinearColor(0.12f,0.10f,0.09f), FLinearColor(0.72f,0.18f,0.04f), 3, 11, 3, 6);
        case ERPStageId::ShadowCanyon:
            return MakeStage(StageId, TEXT("Árnyékszurdok"), TEXT("A Törött Híd"), TEXT("Juss át a hídon"),
                900.f, 1050.f, FLinearColor(0.19f,0.22f,0.25f), FLinearColor(0.55f,0.05f,0.07f), 5, 11, 6, 5);
        case ERPStageId::BlackForest:
            return MakeStage(StageId, TEXT("Feketeerdő Erődje"), TEXT("Az Utolsó Őrség"), TEXT("Törd át az őrséget"),
                950.f, 1100.f, FLinearColor(0.07f,0.16f,0.11f), FLinearColor(0.48f,0.03f,0.04f), 4, 12, 4, 5);
        case ERPStageId::CrownCitadel:
        default:
            return MakeStage(ERPStageId::CrownCitadel, TEXT("A Korona Citadellája"), TEXT("A Végső Ostrom"), TEXT("Törj be a citadellába"),
                1100.f, 1300.f, FLinearColor(0.82f,0.72f,0.55f), FLinearColor(0.72f,0.05f,0.07f), 6, 14, 5, 6);
    }
}

TArray<FRPStageSpec> URPStageCatalog::GetAllStageSpecs()
{
    TArray<FRPStageSpec> Result;
    Result.Reserve(10);
    for (uint8 Index = 1; Index <= 10; ++Index)
    {
        Result.Add(GetStageSpec(static_cast<ERPStageId>(Index)));
    }
    return Result;
}

FRPDifficultyTuning URPStageCatalog::GetDifficultyTuning(const ERPDifficulty Difficulty)
{
    FRPDifficultyTuning Tuning;
    switch (Difficulty)
    {
        case ERPDifficulty::Easy:
            Tuning.EnemyCountMultiplier = 0.72f;
            Tuning.EnemyDamageMultiplier = 0.75f;
            Tuning.HazardSpeedMultiplier = 0.80f;
            Tuning.HealingMultiplier = 1.35f;
            Tuning.CheckpointIntervalMeters = 110.f;
            Tuning.EliteChance = 0.02f;
            break;
        case ERPDifficulty::Hard:
            Tuning.EnemyCountMultiplier = 1.35f;
            Tuning.EnemyDamageMultiplier = 1.25f;
            Tuning.HazardSpeedMultiplier = 1.20f;
            Tuning.HealingMultiplier = 0.65f;
            Tuning.CheckpointIntervalMeters = 180.f;
            Tuning.EliteChance = 0.20f;
            break;
        case ERPDifficulty::Normal:
        default:
            Tuning.EnemyCountMultiplier = 1.0f;
            Tuning.EnemyDamageMultiplier = 1.0f;
            Tuning.HazardSpeedMultiplier = 1.0f;
            Tuning.HealingMultiplier = 1.0f;
            Tuning.CheckpointIntervalMeters = 145.f;
            Tuning.EliteChance = 0.08f;
            break;
    }
    return Tuning;
}
