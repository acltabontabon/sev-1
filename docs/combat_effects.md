# Earthquake and shockwave refinement (11 October 2026)

Implemented presentation refinement for the existing playable moves; damage,
hit windows, cooldowns, and camera-tremor timing are unchanged.

- Earthquakes use a selected [Kenney CC0 smoke texture](../assets/effects/kenney_smoke/README.md).
  Lit gray puffs grow, rotate, drift out along the floor, and fade. Debris uses
  rough, non-emissive stone chunks. The echo ring, cracks, and light pulse are
  quieter than the previous white/glowing presentation.
- All existing `ElementFx.shockwave()` calls also emit a subtle screen refraction
  pulse, adapted from [mrsir8433's CC0 shader](https://godotshaders.com/shader/distortion/).
  Each pulse tracks its world origin through the current camera, scales with its
  projected radius, and ignores origins behind or outside the view. This is a
  screen-space ring, so it is circular rather than the floor ring's perspective ellipse.
- One viewport-owned pass handles at most four pulses. Total displacement is
  bounded; no screen pass runs while idle. A `BackBufferCopy` at canvas layer 0
  preserves the battle grade at -1, while the HUD and story layers draw above it.
- Distortion scales with the existing Camera shake preference; zero turns it off.
  The world rings, dust, and debris remain visible. Emitter reset/exit cancels
  pulses immediately, including the delayed earthquake echo. No new autoload,
  plugin, or runtime dependency is needed.

## Quick review and retry

From the repository root:

```sh
sh tools/godot.sh --path . --script tests/effect_preview.gd
```

The preview uses the actual office, environment, and current engineer at 1920×1080,
Forward+, SSAO, glow, and MSAA 2×. Press **1** for earthquake, **2** for a floor
shockwave, **3** for an upright shockwave, **0** to clear immediately, and **Esc**
to close. Press the effect keys repeatedly to inspect overlapping pulses. In the
normal game, existing enemy ground slams and player skill rings use the new effects.

Acceptance checkpoint: impacts should feel heavy while the engineer, nearby
threats, and floor hazards remain readable. Check whether smoke feels too faint
or dense, whether distortion is comfortable, and whether repeated skill use is
distracting. Human acceptance and Windows runtime testing remain open.

## Verification

```sh
python3 tools/validate.py
sh tools/godot.sh --headless --fixed-fps 60 --path . --script tests/effect_tests.gd
sh tools/godot.sh --path . --script tests/effect_render_tests.gd
sh tools/godot.sh --path . --script tests/effect_preview.gd -- --capture
sh tools/godot.sh --path . --script tests/effect_preview.gd -- --benchmark
```

The focused headless suite covers camera movement, resizing, zero shake, origins
behind the camera, bounded overlaps, immediate reset, and idle cleanup. The
graphical suite isolates refraction from the world ring and checks visible pixel
changes, preservation of the battle grade and HUD, restoration on reset, and
viewport/source teardown ordering. Preview captures are written to ignored
`builds/effect_*.png`; they are review output rather than source assets.

The benchmark is a small office fixture with a quake every 30 frames, not a full
combat performance guarantee. It reports median and 95th-percentile wall-clock
frame intervals across 240 frames, after the scene warms up.

Verified on 11 October 2026 with Godot 4.7.2: full `tools/validate.py` passed;
all eight focused lifecycle checks and four rendered pixel checks passed. Office
captures were visually reviewed, including the dust after the impact flash fades.
On an Apple M2 Pro using Metal/Forward+ at 1920×1080 with SSAO, glow, and MSAA 2×,
the repeated-quake preview measured **9.15 ms median / 10.42 ms p95** across 240
frames. This does not establish performance in a full combat encounter.

## Soft sword and magic effects (11 October 2026)

Implemented by creator request using three selected, unmodified textures from the
[Kenney Particle Pack, CC0](../assets/effects/kenney_particles/README.md).
Sword trails, wind crescents, lightning, cracks and fissure ribbons use the soft
trace with linear mipmap filtering and clamped UVs. The UVs exclude the texture's
empty side margins so the trail remains visible. Sword samples fade with elapsed
time, including after emission stops, and clear immediately on reset. Motes and
flames use the soft glow; shockwaves use the soft ring. Spell-circle marks have
feathered boundaries, quieter brightness and smooth entrance/exit fades.
Combat damage, reach, hit windows, cooldowns and movement are unchanged.

In the same office preview above, press **4** for a sword ribbon and **5** for a
combined magic example; **0** clears both. `--capture` also writes
`builds/effect_sword.png` and `builds/effect_magic.png`. The ribbon preview uses the
actual trail component with a staged swing; ordinary combat remains the final
checkpoint for animation alignment and readability.

The graphical regression `tests/soft_effect_render_tests.gd` checks rendered edge
shades, dimming after emission, expiration and immediate reset, plus visibility
and full fade-out of spell circles and textured shockwaves. Review the moving
three-hit combo and special moves in normal play: judge whether the trails are
visible enough, whether spell edges feel soft, and whether nearby enemies remain
readable. Human acceptance and Windows runtime verification remain open.

Verified on 11 October 2026: full `python3 tools/validate.py` passed; eight soft-effect
render checks, four existing distortion pixel checks and eight focused lifecycle
checks passed. Office captures were inspected using Godot 4.7.2 on Apple M2 Pro,
Metal/Forward+, 1920×1080, SSAO, glow and MSAA 2×. The `--soft-benchmark` office fixture repeated magic and sword effects every
30 frames across 240 measured frames after warmup: **11.00 ms median / 13.63 ms
p95** at those settings. This is a small effect fixture, not a full-combat
performance guarantee.
