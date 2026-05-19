# Breakout

A Breakout clone developed in Lua using LÖVE2D.

## Overview

This project expands the classic Breakout gameplay by introducing power-ups, progression systems, and special brick mechanics.

The main focus of the project was to practice:

- Collision systems
- Power-up management
- Difficulty and reward balancing
- Procedural level elements
- Multiple game objects and physics interactions
- Gameplay progression mechanics

## Features

### Power-Up System

Implemented multiple power-ups that can randomly spawn during gameplay.

Available power-ups include:

- **Multi-ball Power-Up**  
  Spawns 2 additional balls to help clear bricks faster.

- **Heart Power-Up**  
  Restores 1 life if the player has fewer than 3 hearts remaining.

- **Key Power-Up**  
  Grants a key used to unlock special locked bricks.

### Power-Up Spawn Logic

Power-ups can spawn when:

- A brick is destroyed
- A locked brick is hit

In the demo version, power-ups were temporarily configured to spawn on hit instead of destruction to better showcase the functionality.

## Dynamic Paddle Progression

The paddle grows as the player earns more points.

### Paddle Sizes

- Player starts with paddle size **2**
- Reaching score thresholds increases paddle size to:
  - Size 3
  - Size 4

### Life Loss Penalty

If the player loses a life:

- Paddle size resets from:
  - Size 3 → Size 2
  - Size 4 → Size 2
- If already at size 2, it shrinks to size 1

This creates a risk/reward progression system during gameplay.

## Locked Brick System

Special locked bricks can randomly appear in levels.

### Locked Brick Mechanics

- Locked bricks cannot be destroyed normally
- If the player has at least 1 key available:
  - The locked brick is unlocked
  - It transforms into a random regular brick

### Key Management

- Added a key counter to the top UI
- Keys are reset to 0 whenever the player loses a life

This encourages careful gameplay and resource management.

## Technologies

- Lua
- LÖVE2D
