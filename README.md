# Hoppin' Rad

A Jumping Flash style first-person platformer on [Petrichor64](https://github.com/Auxnon/petrichor64).
You're a robot frog. Robot bugs are everywhere. Find the four power cells, then
reach the exit pad on top of the spire.

```sh
chor ~/projects/hoppin-rad      # or ~/petrichor64/target/release/chor
```

## Controls

| | keyboard / mouse | gamepad |
|---|---|---|
| drive forward/back | W / S | left stick Y |
| turn (tank) | A / D | left stick X |
| strafe | Q / E | |
| aim | mouse | right stick |
| jump / double jump | Space | South |
| tongue | LMB (or J) | RB / RT |
| kick | RMB (or K) | West / LB |
| toggle airborne camera tilt | C | |
| restart | R | |

## How it plays

- **Jumping**: a jump, then a bigger second jump in the air. Landing on a
  bug's head scraps it and bounces you up, and your double jump comes back.
- **Camera tilt**: while you're in the air the view tips down so you can see
  where you'll land. It goes further the higher you are, but tops out at about
  24° (`DIP_MAX` in `scripts/player.lua`), well short of Jumping Flash's. Mouse
  look works the whole time. Press C to turn the tilt off.
- **Tongue**: it has a little aim assist. The crosshair turns pink when
  something is in reach. A bug you catch gets reeled in and held in front of
  you. Cells and hearts are collected.
- **Kick**: kick a held bug and it flies off like a missile. It blows up on
  whatever it hits, and nearby bugs go up in a chain reaction. With nothing
  held, the kick launches the bug in front of you instead.
- **Bugs**:
  - Grasshoppers kick when you're in front of them. Otherwise they crouch and
    leap to land on your head.
  - Beetles rev up, flashing, then charge.
  - Gnats circle until they spot you, then dive.

## Layout

`scripts/`:

- `main.lua` has the loop and input.
- `player.lua` handles movement, jumping and the camera.
- `tongue.lua` has the tongue and the kick.
- `enemy.lua` holds the bug AI.
- `world.lua` has the level boxes and collision.
- `models.lua` builds every mesh in code.
- `items.lua`, `fx.lua`, `hud.lua`, `sfx.lua`, `pal.lua` and `mesh.lua` cover
  the rest.

## Playtests

These run headless on a hidden Hyprland output and drive the game through
`TEST_HOOK`/`INPUT_FAKE`. The script prints the output dir, which holds
`game.log` and the screenshots.

```sh
playtests/run.sh playtests/soak.lua 65 20 50   # test, seconds, screenshot times
```

There are five tests:

- `smoke` checks driving, jumping and turning.
- `tongue_kick` runs the lick → hold → kick-into-a-beetle combo.
- `pose` freezes poses for screenshots: the airborne tilt, the tongue and the
  foot.
- `clear` covers cells, the exit and stage clear.
- `soak` runs a minute of random input with a restart partway through.
