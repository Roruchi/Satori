param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing.Common

$folders = @(
    "barren_expanse",
    "boreal_forest",
    "deep_stand",
    "glade",
    "great_reef",
    "lotus_pond",
    "mirror_archipelago",
    "mountain_peak",
    "obsidian_expanse",
    "peat_bog",
    "river",
    "waterfall",
    "wayfarer_torii",
    "bamboo_chime",
    "bridge_of_sighs",
    "echoing_cavern",
    "eternal_kagura_hall",
    "floating_pavilion",
    "iwakura_sanctum",
    "lotus_pagoda",
    "misogi_spring_shrine",
    "monks_rest",
    "star_gazing_deck",
    "sun_dial",
    "whale_bone_arch",
    "great_torii",
    "heavenwind_torii",
    "pagoda_of_the_five",
    "void_mirror",
    "meadow_dwelling",
    "scorched_hollow",
    "dew_bowl",
    "root_network",
    "wind_chime",
    "tiny_shrine",
    "steam_weave",
    "reed_nest",
    "reed_mat",
    "reed_flute",
    "dream_hammock",
    "hearth_stone",
    "stone_basin",
    "foundation_marker",
    "resonance_cairn",
    "rune_marker",
    "kiln_heart",
    "steam_bowl",
    "clay_anchor",
    "ember_bellows",
    "moonflame"
)

$preserveFrameFolders = @("house", "origin_shrine")

function Get-DisplayName {
    param([string]$Folder)
    return ((Get-Culture).TextInfo.ToTitleCase($Folder.Replace("_", " ")))
}

function Get-BrushColor {
    param([string]$Folder, [int]$Offset = 0)
    $hash = [Math]::Abs(($Folder + $Offset).GetHashCode())
    $r = 88 + (($hash -shr 0) -band 95)
    $g = 96 + (($hash -shr 8) -band 88)
    $b = 88 + (($hash -shr 16) -band 96)
    return [System.Drawing.Color]::FromArgb(235, $r, $g, $b)
}

function New-Pen {
    param([System.Drawing.Color]$Color, [float]$Width)
    $pen = [System.Drawing.Pen]::new($Color, $Width)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    return $pen
}

function Fill-Polygon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Brush]$Brush,
        [float[]]$Coords
    )
    $points = @()
    for ($i = 0; $i -lt $Coords.Length; $i += 2) {
        $points += [System.Drawing.PointF]::new($Coords[$i], $Coords[$i + 1])
    }
    $Graphics.FillPolygon($Brush, [System.Drawing.PointF[]]$points)
}

function Draw-StructureSprite {
    param(
        [string]$Folder,
        [string]$OutputPath
    )

    $bitmap = [System.Drawing.Bitmap]::new(128, 128, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $primary = Get-BrushColor $Folder 0
    $secondary = Get-BrushColor $Folder 1
    $accent = [System.Drawing.Color]::FromArgb(245, 235, 204, 124)
    $line = [System.Drawing.Color]::FromArgb(230, 44, 38, 34)
    $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(42, 26, 28, 38))
    $primaryBrush = [System.Drawing.SolidBrush]::new($primary)
    $secondaryBrush = [System.Drawing.SolidBrush]::new($secondary)
    $accentBrush = [System.Drawing.SolidBrush]::new($accent)
    $darkBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 54, 48, 42))
    $linePen = New-Pen $line 3.0
    $accentPen = New-Pen $accent 4.0

    $graphics.FillEllipse($shadowBrush, 30, 84, 68, 18)

    if ($Folder -match "torii") {
        $graphics.FillRectangle($primaryBrush, 33, 42, 62, 9)
        $graphics.FillRectangle($secondaryBrush, 38, 53, 10, 38)
        $graphics.FillRectangle($secondaryBrush, 80, 53, 10, 38)
        $graphics.FillRectangle($accentBrush, 28, 34, 72, 8)
        $graphics.FillEllipse($darkBrush, 59, 57, 10, 10)
    } elseif ($Folder -match "pagoda") {
        Fill-Polygon $graphics $primaryBrush @(42, 36, 86, 36, 76, 46, 52, 46)
        Fill-Polygon $graphics $secondaryBrush @(36, 56, 92, 56, 80, 67, 48, 67)
        Fill-Polygon $graphics $primaryBrush @(30, 78, 98, 78, 84, 91, 44, 91)
        $graphics.FillRectangle($darkBrush, 58, 45, 12, 36)
        $graphics.FillEllipse($accentBrush, 60, 24, 8, 8)
    } elseif ($Folder -match "bowl|basin|pond|pool|reef|river|waterfall|steam") {
        $graphics.FillEllipse($primaryBrush, 32, 50, 64, 38)
        $graphics.DrawEllipse($accentPen, 38, 56, 52, 20)
        $graphics.FillEllipse($secondaryBrush, 47, 60, 34, 14)
        $graphics.DrawLine($accentPen, 42, 45, 30, 31)
        $graphics.DrawLine($accentPen, 64, 43, 64, 25)
        $graphics.DrawLine($accentPen, 86, 45, 99, 31)
    } elseif ($Folder -match "chime|flute|bellows|cairn") {
        $graphics.DrawLine($linePen, 36, 36, 92, 36)
        $graphics.DrawLine($accentPen, 46, 38, 46, 84)
        $graphics.DrawLine($accentPen, 64, 38, 64, 92)
        $graphics.DrawLine($accentPen, 82, 38, 82, 82)
        $graphics.FillEllipse($primaryBrush, 39, 78, 14, 18)
        $graphics.FillEllipse($secondaryBrush, 57, 86, 14, 18)
        $graphics.FillEllipse($primaryBrush, 75, 76, 14, 18)
    } elseif ($Folder -match "root|forest|wood|hollow|dwelling|nest|hammock|stand|glade") {
        Fill-Polygon $graphics $primaryBrush @(31, 62, 64, 32, 97, 62, 87, 92, 41, 92)
        $graphics.FillEllipse($secondaryBrush, 42, 60, 44, 31)
        $graphics.FillEllipse($darkBrush, 56, 68, 16, 24)
        $graphics.DrawLine($accentPen, 28, 85, 49, 78)
        $graphics.DrawLine($accentPen, 100, 85, 79, 78)
    } elseif ($Folder -match "stone|mountain|cavern|iwakura|foundation|anchor|dial|mirror|void|obsidian") {
        Fill-Polygon $graphics $primaryBrush @(42, 84, 52, 42, 76, 34, 91, 86)
        Fill-Polygon $graphics $secondaryBrush @(29, 88, 45, 55, 64, 88)
        Fill-Polygon $graphics $secondaryBrush @(66, 88, 86, 50, 102, 88)
        $graphics.DrawEllipse($accentPen, 53, 53, 22, 22)
    } elseif ($Folder -match "kiln|ember|clay|hearth|flame|kagura|scorched|sun") {
        $graphics.FillEllipse($darkBrush, 35, 58, 58, 32)
        Fill-Polygon $graphics $primaryBrush @(44, 74, 62, 32, 82, 74)
        Fill-Polygon $graphics $secondaryBrush @(55, 73, 66, 48, 76, 73)
        $graphics.FillEllipse($accentBrush, 56, 76, 18, 10)
    } else {
        Fill-Polygon $graphics $primaryBrush @(36, 60, 64, 35, 92, 60, 84, 90, 44, 90)
        $graphics.FillEllipse($secondaryBrush, 47, 55, 34, 28)
        $graphics.FillEllipse($accentBrush, 59, 65, 10, 10)
    }

    $graphics.DrawEllipse($linePen, 40, 38, 48, 48)

    $outDir = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $linePen.Dispose()
    $accentPen.Dispose()
    $shadowBrush.Dispose()
    $primaryBrush.Dispose()
    $secondaryBrush.Dispose()
    $accentBrush.Dispose()
    $darkBrush.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

function Write-SpriteFrames {
    param([string]$Folder, [string]$StructureDir)
    $path = Join-Path $StructureDir "sprite_frames.tres"
    $content = @"
[gd_resource type="SpriteFrames" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://assets/structures/$Folder/frames/idle/down/frame_0000.png" id="1"]

[resource]
animations = [{
"frames": [{
"duration": 1.0,
"texture": ExtResource("1")
}],
"loop": true,
"name": &"idle_down",
"speed": 1.0
}]
"@
    [System.IO.File]::WriteAllText($path, $content.Replace("`r`n", "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Get-SourcePathHash {
    param([string]$SourcePath)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($SourcePath)
        return (($md5.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
    } finally {
        $md5.Dispose()
    }
}

function Write-PngImport {
    param([string]$Folder, [string]$FramePath)
    $sourcePath = "res://assets/structures/$Folder/frames/idle/down/frame_0000.png"
    $hash = Get-SourcePathHash $sourcePath
    $uid = "uid://satori$($hash.Substring(0, 10))"
    $content = @"
[remap]

importer="texture"
type="CompressedTexture2D"
uid="$uid"
path="res://.godot/imported/frame_0000.png-$hash.ctex"
metadata={
"vram_texture": false
}

[deps]

source_file="$sourcePath"
dest_files=["res://.godot/imported/frame_0000.png-$hash.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"@
    [System.IO.File]::WriteAllText("$FramePath.import", $content.Replace("`r`n", "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Write-SpriteSheetJson {
    param([string]$Folder, [string]$StructureDir)
    $data = [ordered]@{
        entity_id = $Folder
        frame_width = 128
        frame_height = 128
        directions = @("down")
        layout = "static-generated"
        source = "tools/build_structure_static_sprites.ps1"
        animations = @(
            [ordered]@{
                name = "idle_down"
                frames = 1
                fps = 1.0
                loop = $true
            }
        )
    }
    $json = ($data | ConvertTo-Json -Depth 6)
    [System.IO.File]::WriteAllText((Join-Path $StructureDir "sprite_sheet.json"), $json + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Write-GenerationBrief {
    param([string]$Folder, [string]$StructureDir)
    $data = [ordered]@{
        entity_id = $Folder
        display_name = Get-DisplayName $Folder
        asset_role = "completed structure sprite"
        generator = "tools/build_structure_static_sprites.ps1"
        style = "transparent top-down symbolic structure sprite matching Satori structure asset scale"
    }
    $json = ($data | ConvertTo-Json -Depth 4)
    [System.IO.File]::WriteAllText((Join-Path $StructureDir "generation_brief.json"), $json + "`n", [System.Text.UTF8Encoding]::new($false))
}

$structuresRoot = Join-Path $ProjectRoot "assets/structures"
$built = 0

foreach ($folder in $folders) {
    $structureDir = Join-Path $structuresRoot $folder
    $framePath = Join-Path $structureDir "frames/idle/down/frame_0000.png"
    New-Item -ItemType Directory -Force -Path $structureDir | Out-Null
    if (-not (Test-Path $framePath)) {
        Draw-StructureSprite $folder $framePath
        $built += 1
    }
    if (-not (Test-Path "$framePath.import")) {
        Write-PngImport $folder $framePath
    }
    if (-not (Test-Path (Join-Path $structureDir "sprite_frames.tres"))) {
        Write-SpriteFrames $folder $structureDir
    }
    if (-not (Test-Path (Join-Path $structureDir "sprite_sheet.json"))) {
        Write-SpriteSheetJson $folder $structureDir
    }
    if (-not (Test-Path (Join-Path $structureDir "generation_brief.json"))) {
        Write-GenerationBrief $folder $structureDir
    }
}

foreach ($folder in $preserveFrameFolders) {
    $structureDir = Join-Path $structuresRoot $folder
    if (Test-Path $structureDir) {
        if (-not (Test-Path (Join-Path $structureDir "sprite_sheet.json"))) {
            Write-SpriteSheetJson $folder $structureDir
        }
        if (-not (Test-Path (Join-Path $structureDir "generation_brief.json"))) {
            Write-GenerationBrief $folder $structureDir
        }
    }
}

Write-Host "Built $built missing structure frame(s)."
