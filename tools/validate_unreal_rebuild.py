#!/usr/bin/env python3
"""Static repository checks for the Unreal migration.

This does not replace UnrealBuildTool compilation. It catches repository-level
regressions that can be verified on a normal GitHub runner without an installed
Unreal Engine.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UE = ROOT / "Unreal" / "ReversePlatformerUE"

errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


required_files = [
    UE / "ReversePlatformerUE.uproject",
    UE / "Source/ReversePlatformerUE/ReversePlatformerUE.Build.cs",
    UE / "Source/ReversePlatformerUE/Public/Stage/RPStageTypes.h",
    UE / "Source/ReversePlatformerUE/Public/Stage/RPStageGenerator.h",
    UE / "Source/ReversePlatformerUE/Private/Stage/RPStageGenerator.cpp",
    UE / "Source/ReversePlatformerUE/Private/Stage/RPStageCatalog.cpp",
    UE / "Source/ReversePlatformerUE/Private/Stage/RPBiomeCatalog.cpp",
    UE / "Source/ReversePlatformerUE/Public/Camera/RPCameraModeComponent.h",
    UE / "Source/ReversePlatformerUE/Public/Player/RPPlayerCharacter.h",
    UE / "Config/DefaultEngine.ini",
    ROOT / "docs/CHANGE_TO_UNREAL_ENGINE_MOBILE.md",
]

for path in required_files:
    require(path.exists(), f"missing required file: {path.relative_to(ROOT)}")

uproject = json.loads((UE / "ReversePlatformerUE.uproject").read_text(encoding="utf-8"))
require(uproject.get("EngineAssociation") == "5.8", "Unreal target must stay on UE 5.8 for this migration branch")
require(any(m.get("Name") == "ReversePlatformerUE" for m in uproject.get("Modules", [])), "runtime module missing")

engine_ini = (UE / "Config/DefaultEngine.ini").read_text(encoding="utf-8")
require("TargetSDKVersion=35" in engine_ini, "Android target SDK must be 35")
require("bBuildForArm64=True" in engine_ini, "Android ARM64 build must be enabled")
require("bSupportsVulkan=True" in engine_ini, "Android Vulkan support must be enabled")

catalog = (UE / "Source/ReversePlatformerUE/Private/Stage/RPStageCatalog.cpp").read_text(encoding="utf-8")
stage_names = [
    "Várudvar",
    "A Királyi Kertek",
    "Sas-szirt",
    "Dermedt Bástya",
    "Vaskohó",
    "Szélmalom-völgy",
    "Az Elfeledett Katakombák",
    "Árnyékszurdok",
    "Feketeerdő Erődje",
    "A Korona Citadellája",
]
for stage in stage_names:
    require(stage in catalog, f"stage missing from built-in catalog: {stage}")

spec_header = (UE / "Source/ReversePlatformerUE/Public/Stage/RPStageTypes.h").read_text(encoding="utf-8")
require(spec_header.count("UMETA(DisplayName=") == 10, "stage enum must contain exactly ten stages")
require("SideView" in spec_header and "ThirdPerson" in spec_header, "both initial camera modes are required")
require("Easy" in spec_header and "Normal" in spec_header and "Hard" in spec_header, "three difficulty profiles are required")

generator = (UE / "Source/ReversePlatformerUE/Private/Stage/RPStageGenerator.cpp").read_text(encoding="utf-8")
require("FRandomStream" in generator, "stage generation must remain deterministic/seeded")
require("Checkpoint" in generator and "MiniBoss" in generator and "Finish" in generator, "core stage grammar is incomplete")

all_paths = "\n".join(str(p.relative_to(ROOT)) for p in ROOT.rglob("*") if p.is_file())
for index in range(1, 11):
    require(f"Level{index}Generator.cpp" not in all_paths, "do not split the generator into ten per-stage scripts")

doc = (ROOT / "docs/CHANGE_TO_UNREAL_ENGINE_MOBILE.md").read_text(encoding="utf-8")
for stage in stage_names:
    require(stage in doc, f"migration document lost stage definition: {stage}")

# Catch accidental generated build output.
for forbidden in ["Binaries", "Intermediate", "DerivedDataCache", "Saved"]:
    path = UE / forbidden
    require(not path.exists(), f"generated Unreal directory must not be committed: {path.relative_to(ROOT)}")

if errors:
    print("UNREAL_MIGRATION_VALIDATION_FAILED")
    for error in errors:
        print(" -", error)
    sys.exit(1)

print("UNREAL_MIGRATION_VALIDATION_OK")
print("10 stages, 3 difficulties, 2 camera modes, Android SDK 35, shared generator architecture")
