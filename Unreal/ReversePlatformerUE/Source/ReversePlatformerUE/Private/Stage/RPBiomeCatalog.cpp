#include "Stage/RPBiomeCatalog.h"
#include <initializer_list>

namespace
{
FRPBiomeRecipe Recipe(
    ERPStageId Id,
    std::initializer_list<const TCHAR*> Architecture,
    std::initializer_list<const TCHAR*> Props,
    std::initializer_list<const TCHAR*> Vegetation,
    std::initializer_list<const TCHAR*> Enemies,
    std::initializer_list<const TCHAR*> Hazards,
    const TCHAR* Lighting,
    const TCHAR* Atmosphere,
    const TCHAR* Music)
{
    FRPBiomeRecipe R;
    R.StageId = Id;
    for (const TCHAR* V : Architecture) R.ArchitectureFamilies.Add(FName(V));
    for (const TCHAR* V : Props) R.PropFamilies.Add(FName(V));
    for (const TCHAR* V : Vegetation) R.VegetationFamilies.Add(FName(V));
    for (const TCHAR* V : Enemies) R.EnemyFamilies.Add(FName(V));
    for (const TCHAR* V : Hazards) R.HazardFamilies.Add(FName(V));
    R.LightingPreset = FName(Lighting);
    R.AtmospherePreset = FName(Atmosphere);
    R.MusicPreset = FName(Music);
    return R;
}
}

FRPBiomeRecipe URPBiomeCatalog::GetBiomeRecipe(const ERPStageId StageId)
{
    switch (StageId)
    {
        case ERPStageId::Courtyard:
            return Recipe(StageId,
                {TEXT("PaleLimestone"),TEXT("CastleGate"),TEXT("RoundTower"),TEXT("Fountain")},
                {TEXT("RedGoldBanner"),TEXT("Braziers"),TEXT("Crates"),TEXT("Barrels"),TEXT("LionStatue")},
                {TEXT("Cypress"),TEXT("Ivy"),TEXT("WhiteFlowers")},
                {TEXT("BlueGuard"),TEXT("ShieldGuard"),TEXT("Archer")},
                {TEXT("Spikes"),TEXT("Gaps")},
                TEXT("WarmDay"),TEXT("ClearBlue"),TEXT("Courtyard"));
        case ERPStageId::RoyalGardens:
            return Recipe(StageId,
                {TEXT("GardenWall"),TEXT("StoneBridge"),TEXT("Gazebo"),TEXT("Fountain")},
                {TEXT("Statue"),TEXT("Urn"),TEXT("RoseArch"),TEXT("RoyalBanner")},
                {TEXT("Hedge"),TEXT("Rose"),TEXT("Cypress"),TEXT("WaterLily")},
                {TEXT("BlueGuard"),TEXT("ShieldGuard"),TEXT("Archer")},
                {TEXT("Water"),TEXT("HedgeMaze"),TEXT("Gaps")},
                TEXT("GoldenGarden"),TEXT("ClearBlue"),TEXT("RoyalGardens"));
        case ERPStageId::EagleCliff:
            return Recipe(StageId,
                {TEXT("CliffFortress"),TEXT("SuspensionBridge"),TEXT("WatchTower"),TEXT("Crane")},
                {TEXT("Rope"),TEXT("Chain"),TEXT("Crate"),TEXT("RedGoldBanner")},
                {TEXT("MountainPine"),TEXT("Ivy")},
                {TEXT("BlueGuard"),TEXT("Archer"),TEXT("CliffElite")},
                {TEXT("Abyss"),TEXT("FallingRock"),TEXT("BrokenBridge")},
                TEXT("HighAltitudeSun"),TEXT("CloudSea"),TEXT("EagleCliff"));
        case ERPStageId::FrozenBastion:
            return Recipe(StageId,
                {TEXT("FrozenStone"),TEXT("IceBridge"),TEXT("IceGate"),TEXT("FrozenTower")},
                {TEXT("BlueBanner"),TEXT("Brazier"),TEXT("IceCrystal")},
                {TEXT("SnowPine"),TEXT("FrozenShrub")},
                {TEXT("IceGuard"),TEXT("IceShield"),TEXT("IceArcher")},
                {TEXT("SlipIce"),TEXT("IceSpike"),TEXT("BreakableIce")},
                TEXT("ColdDay"),TEXT("Snow"),TEXT("FrozenBastion"));
        case ERPStageId::Forge:
            return Recipe(StageId,
                {TEXT("IronPlatform"),TEXT("ForgeWall"),TEXT("Furnace"),TEXT("IndustrialGate")},
                {TEXT("Chain"),TEXT("Crucible"),TEXT("Anvil"),TEXT("Lift"),TEXT("Gear")},
                {},
                {TEXT("ForgeGuard"),TEXT("HammerBrute"),TEXT("FireArcher")},
                {TEXT("MoltenMetal"),TEXT("Crusher"),TEXT("MovingLift"),TEXT("FireJet")},
                TEXT("ForgeFire"),TEXT("Smoke"),TEXT("Forge"));
        case ERPStageId::WindmillValley:
            return Recipe(StageId,
                {TEXT("TimberHouse"),TEXT("StoneBridge"),TEXT("Windmill"),TEXT("VillageGate")},
                {TEXT("Cart"),TEXT("Fence"),TEXT("Barrel"),TEXT("Crate"),TEXT("FarmStand")},
                {TEXT("Wheat"),TEXT("Sunflower"),TEXT("FruitTree"),TEXT("Cypress")},
                {TEXT("BlueGuard"),TEXT("Pikeman"),TEXT("Archer")},
                {TEXT("Barricade"),TEXT("CartCrash"),TEXT("BurningField")},
                TEXT("LateSummer"),TEXT("SiegeSmoke"),TEXT("WindmillValley"));
        case ERPStageId::Catacombs:
            return Recipe(StageId,
                {TEXT("CryptStone"),TEXT("TombArch"),TEXT("BoneBridge"),TEXT("CatacombHall")},
                {TEXT("Candle"),TEXT("SkullPile"),TEXT("Cage"),TEXT("Chain"),TEXT("TombStatue")},
                {TEXT("Root"),TEXT("Moss")},
                {TEXT("SkeletonSword"),TEXT("SkeletonShield"),TEXT("SkeletonArcher")},
                {TEXT("SpikePit"),TEXT("FallingCage"),TEXT("CollapsedFloor")},
                TEXT("CandleDark"),TEXT("DustFog"),TEXT("Catacombs"));
        case ERPStageId::ShadowCanyon:
            return Recipe(StageId,
                {TEXT("DarkCliff"),TEXT("BrokenBridge"),TEXT("RuinedFort"),TEXT("WatchTower")},
                {TEXT("Chain"),TEXT("Cage"),TEXT("RedBanner"),TEXT("Brazier")},
                {TEXT("Pine"),TEXT("Ivy")},
                {TEXT("DarkGuard"),TEXT("DarkShield"),TEXT("DarkArcher")},
                {TEXT("Abyss"),TEXT("BridgeCollapse"),TEXT("SwingingCage")},
                TEXT("StormDusk"),TEXT("DeepFog"),TEXT("ShadowCanyon"));
        case ERPStageId::BlackForest:
            return Recipe(StageId,
                {TEXT("MossStone"),TEXT("ForestFort"),TEXT("WoodWatchTower"),TEXT("Palisade")},
                {TEXT("BlackRedBanner"),TEXT("Brazier"),TEXT("Crate"),TEXT("Barrel")},
                {TEXT("DensePine"),TEXT("Fern"),TEXT("Moss"),TEXT("Ivy")},
                {TEXT("BlackGuard"),TEXT("BlackShield"),TEXT("BlackArcher"),TEXT("ForestElite")},
                {TEXT("StakePit"),TEXT("Ambush"),TEXT("FallingTree")},
                TEXT("ForestDusk"),TEXT("GroundFog"),TEXT("BlackForest"));
        case ERPStageId::CrownCitadel:
        default:
            return Recipe(ERPStageId::CrownCitadel,
                {TEXT("MonumentalLimestone"),TEXT("GrandBridge"),TEXT("CitadelGate"),TEXT("GiantTower"),TEXT("SiegeWall")},
                {TEXT("GiantStatue"),TEXT("RedGoldBanner"),TEXT("Trebuchet"),TEXT("Brazier"),TEXT("SiegeScaffold")},
                {TEXT("Cypress"),TEXT("Ivy"),TEXT("WhiteFlowers")},
                {TEXT("RoyalGuard"),TEXT("RoyalShield"),TEXT("RoyalArcher"),TEXT("RoyalElite")},
                {TEXT("SiegeFire"),TEXT("FallingStone"),TEXT("BridgeGap"),TEXT("Ballista")},
                TEXT("EpicDay"),TEXT("BattleSmoke"),TEXT("CrownCitadel"));
    }
}
