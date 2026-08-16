## Task List

*Tag legend: **[MVP]** = required for minimum playable game · **[Stretch]** = only if time allows · `(owner: ?)` = fill in per person*

### 🧠 Core Systems
- [ ] **[MVP]** Combat system (shoot + melee, damage calc) `(owner: ?)`
- [ ] **[MVP]** Ammo system (count, reload, empty state) `(owner: ?)`
- [ ] **[MVP]** Boss system (base health/phases, trigger arena) `(owner: ?)`
- [ ] **[MVP]** Game state manager (current stage, player stats across scenes, win/lose) `(owner: ?)`
- [ ] **[Stretch]** Quest/objective tracking system `(owner: ?)`
- [ ] **[Stretch]** Resource/inventory system (beyond ammo — crafting, upgrades) `(owner: ?)`

### 🖥️ UI
- [ ] **[MVP]** Main menu scene
- [ ] **[MVP]** HUD (health, ammo)
- [ ] **[MVP]** Game over screen
- [ ] **[MVP]** Restart flow
- [ ] **[MVP]** Scene transitions
- [ ] **[Stretch]** Pause menu
- [ ] **[Stretch]** Settings (audio/controls)

### 🧩 Puzzle
- [ ] **[Stretch]** Wire/cable-connect puzzle (⚠️ new scope — confirm this replaces or fits inside one moment, not a repeated system, given timeline)

### 🧍 Entities — Player
- [ ] **[MVP]** Player movement
- [ ] **[MVP]** Basic shooting
- [ ] **[MVP]** Ammo and reloading (links to Ammo System above)
- [ ] **[MVP]** Animation states (idle/walk/shoot/melee/hit/death)
- [ ] **[Stretch]** Melee system (if not folded into MVP combat)

### 👾 Entities — Enemy
- [ ] **[MVP]** Enemy basics (movement, collision, health)
- [ ] **[MVP]** Simple AI (chase within range)
- [ ] **[MVP]** Boss attack pattern(s) — at least 1 for MVP stage
- [ ] **[Stretch]** Enemy patrol state
- [ ] **[Stretch]** Second enemy type / ranged enemy

### 📦 Entities — Props
- [ ] **[MVP]** General prop code (base interactable class)
- [ ] **[MVP]** Interactive props (ammo pickup, health pickup)
- [ ] **[Stretch]** Doors / environmental interactables

### 🎨 Art / Story
- [ ] **[MVP]** Pixel art spec doc (canvas size, palette) — do this FIRST, before any sprite work
- [ ] **[MVP]** Player sprite (idle/walk/shoot/melee frames)
- [ ] **[MVP]** Enemy sprite(s)
- [ ] **[MVP]** Boss sprite
- [ ] **[MVP]** Story beats written per stage (what's shown/said, intro + ending text)
- [ ] **[Stretch]** Environmental storytelling (notes, logs, visual details)

### 🗺️ Level Design (Areas)
- [ ] **[MVP]** Outskirt
- [ ] **[Stretch]** Downtown
- [ ] **[Stretch]** Home

### 🔊 Audio
- [ ] **[MVP]** Ambient music track wired to MVP stage
- [ ] **[MVP]** Core SFX hooked up (shoot, hit, damage, pickup)
- [ ] **[Stretch]** Per-stage music variation
- [ ] **[Stretch]** Chiptune flashback moment (per Audio Direction)

### ✨ Polish
- [ ] **[Stretch]** Hit flash / screen shake
- [ ] **[Stretch]** Particle effects (death, impact)

### 🧪 Playtesting & Ship
- [ ] **[MVP]** Continuous playtesting (recurring — not a one-time task, everyone participates)
- [ ] **[MVP]** Build/export tested and playable, done a few days before deadline `(owner: ?)`