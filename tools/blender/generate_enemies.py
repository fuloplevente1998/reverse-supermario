"""Create five original mobile-ready defenders for the villain-led castle assault.

Run after generate_art.py:
  blender -b --python tools/blender/generate_enemies.py -- --output assets/models --source build/blender

Every GLB has EnemyRig, Chest, LegLeft, LegRight and WeaponPivot.
The simple mesh pivots support current Godot motion without requiring a
full skeleton; refined skeletal animation can replace these later.
"""
import argparse
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import generate_art as a


KINDS = ("guard", "scout", "brute", "archer", "captain")


def build(kind, out, source):
    a.clear_scene()
    palettes = {
        "guard":   ((0.42, 0.53, 0.66), (0.66, 0.73, 0.78), (0.15, 0.28, 0.53)),
        "scout":   ((0.17, 0.37, 0.26), (0.46, 0.64, 0.38), (0.08, 0.20, 0.12)),
        "brute":   ((0.40, 0.32, 0.22), (0.70, 0.50, 0.25), (0.27, 0.16, 0.12)),
        "archer":  ((0.30, 0.32, 0.43), (0.58, 0.58, 0.65), (0.16, 0.18, 0.29)),
        "captain": ((0.55, 0.18, 0.15), (0.84, 0.66, 0.29), (0.18, 0.10, 0.16)),
    }
    primary, bright, dark_rgb = palettes[kind]
    armor = a.material(kind + " painted steel", primary, metal=0.5, roughness=0.43)
    trim = a.material(kind + " bright metal", bright, metal=0.74, roughness=0.31)
    dark = a.material(kind + " padded leather", dark_rgb, roughness=0.83)
    gold = a.material("royal gilding", (0.82, 0.57, 0.21), metal=0.74, roughness=0.34)
    eye = a.material("dark visor", (0.075, 0.11, 0.15), metal=0.38, roughness=0.30)
    root = a.empty("EnemyRig")
    broad = 1.24 if kind in ("brute", "captain") else (0.76 if kind == "scout" else 1.0)
    height = 0.95 if kind == "scout" else (1.12 if kind == "captain" else 1.0)
    # Strong silhouettes at mobile viewing distance, without costly textures.
    a.cube("Chest", (0, -0.01, 0.18), (0.77 * broad, 0.49, 0.75 * height),
           armor, root, 0.11)
    a.cube("Breastplate", (0, -0.275, 0.27), (0.60 * broad, 0.075, 0.42 * height),
           trim, root, 0.045)
    a.cube("Waist", (0, 0, -0.24), (0.66 * broad, 0.43, 0.18), dark, root, 0.03)
    a.sphere("Helm", (0, 0, 0.96 * height),
             (0.34 * broad, 0.36, 0.38), armor, root, 14, 8)
    a.cube("Visor", (0, -0.34, 1.02 * height),
           (0.49 * broad, 0.09, 0.13), eye, root, 0.025)
    for side, pivot_name in ((-1, "LegLeft"), (1, "LegRight")):
        a.sphere("Shoulder", (side * 0.47 * broad, 0, 0.40), 
                 (0.23 * broad, 0.25, 0.20), trim, root, 12, 6)
        a.cube("Arm", (side * 0.50 * broad, 0, 0.06),
               (0.22, 0.29, 0.47), armor, root, 0.04)
        a.cube("Gauntlet", (side * 0.52 * broad, -0.08, -0.20),
               (0.25, 0.3, 0.21), dark, root, 0.025)
        leg = a.empty(pivot_name, (side * 0.23 * broad, 0, -0.32), root)
        a.cube("Thigh", (0, 0, -0.12), (0.26 * broad, 0.32, 0.37),
               dark, leg, 0.045)
        a.cube("Greave", (0, -0.04, -0.41), (0.30 * broad, 0.35, 0.31),
               armor, leg, 0.04)
        a.cube("Boot", (0, -0.13, -0.58), (0.31 * broad, 0.48, 0.17),
               dark, leg, 0.04)

    weapon = a.empty("WeaponPivot", (0.56 * broad, -0.16, 0.08), root)
    if kind == "guard":
        a.cube("Sword", (0, -0.75, 0), (0.10, 1.16, 0.10), trim, weapon, 0.018)
        a.cube("Crossguard", (0, -0.17, 0), (0.48, 0.12, 0.13), gold, weapon, 0.018)
        a.cube("TowerShield", (-0.70, -0.27, 0.15),
               (0.50, 0.19, 0.72), armor, root, 0.04)
        a.cube("ShieldCross", (-0.70, -0.38, 0.15),
               (0.08, 0.025, 0.54), trim, root, 0.006)
        a.cube("ShieldCrossbar", (-0.70, -0.40, 0.15),
               (0.33, 0.02, 0.07), trim, root, 0.006)
        a.cone("GuardHelmSpike", (0, 0, 1.40), 0.14, 0.32, trim, root)

    elif kind == "scout":
        for side in (-1, 1):
            a.cube("ScoutKnife", (side * 0.20, -0.50, 0), 
                   (0.075, 0.67, 0.065), trim, weapon, 0.012)
            a.cube("ScoutKnifeGrip", (side * 0.20, -0.09, 0),
                   (0.13, 0.25, 0.09), dark, weapon, 0.015)
        for side in (-1, 1):
            a.cone("ScoutHoodPoint", (side * 0.22, 0.10, 1.29),
                   0.17, 0.43, dark, root)
        a.cube("ScoutSash", (0, -0.32, 0.22), (0.38, 0.028, 0.14),
               trim, root, 0.012)

    elif kind == "brute":
        a.cube("WarHammerHandle", (0, -0.78, 0.01),
               (0.15, 1.40, 0.14), dark, weapon, 0.015)
        a.cube("WarHammerHead", (0, -1.35, 0),
               (0.70, 0.45, 0.36), trim, weapon, 0.050)
        for side in (-1, 1):
            a.cone("BruteShoulderSpike", (side * 0.66 * broad, 0, 0.72),
                   0.16, 0.46, trim, root)
        a.cube("BruteJawGuard", (0, -0.34, 0.81),
               (0.49, 0.13, 0.24), trim, root, 0.03)

    elif kind == "archer":
        # Readable three-part bow, bowstring and arrow, parented to weapon pivot.
        a.cube("BowGrip", (0, -0.42, 0), (0.11, 0.19, 0.12), dark, weapon, 0.015)
        for z in (-1, 1):
            limb = a.cube("BowLimb", (0, -0.44, z * 0.39),
                          (0.07, 0.09, 0.68), trim, weapon, 0.015)
            limb.rotation_euler[1] = z * 0.30
        a.cube("BowString", (0, -0.67, 0),
               (0.015, 0.015, 1.65), gold, weapon, 0)
        a.cube("LoadedArrow", (0, -0.88, 0.07),
               (0.035, 1.05, 0.035), trim, weapon, 0)
        for dx in (-0.21, 0.21):
            a.cone("ArcherHood", (dx, 0.05, 1.30),
                   0.16, 0.31, dark, root)
        a.cube("Quiver", (-0.55, 0.25, 0.15),
               (0.21, 0.24, 0.70), dark, root, 0.035)

    elif kind == "captain":
        a.cube("CaptainGreatsword", (0, -1.05, 0),
               (0.18, 1.75, 0.13), trim, weapon, 0.03)
        a.cube("CaptainCrossguard", (0, -0.25, 0),
               (0.83, 0.17, 0.18), gold, weapon, 0.025)
        a.cube("CaptainShield", (-0.84, -0.27, 0.20),
               (0.73, 0.18, 0.93), armor, root, 0.085)
        for dx in (-0.30, 0, 0.30):
            a.cone("CaptainCrown", (dx, 0, 1.50),
                   0.12, 0.45, gold, root)
        # Low-poly royal cape, visible from behind.
        a.cube("RoyalCape", (0, 0.34, -0.24),
               (1.08, 0.055, 1.24),
               a.material("captain red cape", (0.55, 0.025, 0.07),
                          roughness=0.88), root, 0.018)
        a.cube("RoyalCapeTrim", (0, 0.39, -0.80),
               (1.12, 0.035, 0.10), gold, root, 0.015)
    a.save_asset("enemy_" + kind, out, source)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="assets/models")
    parser.add_argument("--source", default="build/blender")
    args = parser.parse_args(argv)
    output = Path(args.output).resolve()
    source = Path(args.source).resolve()
    output.mkdir(parents=True, exist_ok=True)
    source.mkdir(parents=True, exist_ok=True)
    (source / ".gdignore").touch()
    for kind in KINDS:
        build(kind, output, source)
    print("PASS: five original defenders generated for Android", flush=True)


if __name__ == "__main__":
    main()
