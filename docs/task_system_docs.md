# Task System — How It Works (Level Designer's Guide)

Your friend built three files: `task_data.gd`, `task_objective.gd`,
`task_manager.gd`. This explains what each one is for and — most
importantly — **the one thing the system does NOT do for you**, which is
the part that usually trips people up.

---

## 1. The three pieces

Think of it like a spreadsheet:

| Piece | What it is | Analogy |
|---|---|---|
| `TaskObjective` | One measurable step — "kill 3 zombies", "reach the cabin" | A row in a checklist |
| `TaskData` | A task/chapter made of one or more objectives | The checklist itself |
| `TaskManager` | Tracks every task's state, fires signals when things change | The person checking things off and telling everyone |

A `TaskData` can have multiple `TaskObjective`s (e.g. "Clear the Camp" needs
both "kill 5 raiders" AND "destroy 2 barricades"). The task only completes
once **every** objective on it is done.

---

## 2. The most important thing to understand

**`TaskManager` does not watch your game world.** It has no idea what a
"zombie" or a "cabin" is. It doesn't automatically detect kills, pickups, or
the player walking somewhere.

All it does is hold numbers and states. **You, the level designer, are
responsible for calling a function on it at the exact moment something
progress-worthy happens in your level** — a zombie's death signal, a pickup's
`body_entered`, a dialogue ending, whatever. The system is deliberately
"dumb" so it works for literally any kind of objective.

This is exactly what `outskirt.gd` (your friend's example level) already
does — it listens for `zombie.died` and, *manually*, tells the task manager
to advance:

```gdscript
func _connect_enemies() -> void:
	for zombie: ZombieAxe in get_tree().get_nodes_in_group("enemies"):
		zombie.died.connect(_on_zombie_died)

func _on_zombie_died() -> void:
	_progress.advance("escape_forest", 0, 1)   # <- YOU decide when this fires
```

Every level you build needs its own version of this: find the gameplay
event that should count as progress, connect its signal (or call it
directly), and call `advance()`.

---

## 3. The objective `Type` field is just a label

`TaskObjective.Type` (`COLLECT`, `KILL`, `TALK`, `REACH`, `CUSTOM`) and
`target_id` **don't trigger anything automatically.** They exist purely so
*you* can read your own task list later and remember what an objective was
supposed to be about. The manager never reads `type` to decide behavior —
it only reads `current` vs `required`.

So `target_id = "zombie"` on a `KILL` objective is just documentation to
your future self — it's still on you to make sure the code that calls
`advance()` is actually attached to zombie deaths, and not something else.

A practical pattern per type — where you'd typically call `advance()` from:

| Type | Typical trigger point |
|---|---|
| `KILL` | The enemy's `died` signal (like the zombie example above) |
| `COLLECT` | A pickup's `body_entered` / `area_entered`, or an inventory-add function |
| `REACH` | An `Area2D` at the destination, connected to `body_entered` |
| `TALK` | Wherever your dialogue system fires "conversation ended" |
| `CUSTOM` | Anything else — a puzzle solved, a switch flipped, a timer survived |

---

## 4. Task lifecycle (the state machine)

```
INACTIVE  →  ACTIVE  →  COMPLETED
                    ╲→  FAILED
```

- A task starts **INACTIVE** the moment you `register()` it.
- It only starts counting progress once you `activate()` it. Activation
  fails silently (returns `false`) if any task listed in its
  `prerequisites` isn't `COMPLETED` yet — this is how you chain chapters:

```gdscript
ch2.prerequisites = ["escape_forest"]   # ch2 can't activate until ch1 is done
```

- Every `advance()` call checks if *all* objectives are now complete, and
  if so, **auto-completes the task and emits `task_completed`** — you don't
  need to call `complete()` yourself in the normal case. `complete()` and
  `fail()` exist for when *you* want to force an outcome (e.g. a mission
  timer running out should call `fail()` manually).

---

## 5. The signals — how your UI finds out

`TaskManager` never touches the HUD directly. It just shouts into the void
via signals, and your level script relays them to whatever UI you're using:

```gdscript
_progress.task_activated.connect(_on_task_activated)      # task just started
_progress.objective_advanced.connect(_on_objective_advanced)  # progress ticked up
_progress.task_completed.connect(_on_task_completed)       # task finished
```

In `outskirt.gd`, these three callbacks just forward the info to `HUD`
(`_hud.show_task(...)`, `_hud.update_objective(...)`, `_hud.hide_task()`).
If you build a level with a different HUD, or no HUD at all, you'd connect
these same three signals to whatever *your* level needs instead — a
notification popup, a quest log, an achievement toast, etc.

There's also `task_failed`, which nothing currently listens to — wire it up
if/when you build tasks that can fail.

---

## 6. Recipe: adding a new task to your level

This is the exact pattern `outskirt.gd` uses for its two chapters — copy it:

```gdscript
@onready var _progress: TaskManager = $TaskManager

func _ready() -> void:
    _define_tasks()
    _connect_triggers()          # whatever signals YOUR level needs
    _progress.activate("your_first_task_id")   # kick off the starting task


func _define_tasks() -> void:
    var task := TaskData.new()
    task.id = "your_task_id"
    task.title = "Human-Readable Title"
    task.description = "Shown in the task panel."

    var obj := TaskObjective.new()
    obj.type = TaskObjective.Type.KILL      # just a label, see section 3
    obj.description = "Defeat raiders"
    obj.target_id = "raider"                # also just a label
    obj.required = 5
    task.objectives.append(obj)

    # For a multi-objective task, just append more TaskObjective instances.

    _progress.register(task)


func _connect_triggers() -> void:
    # Wherever the real gameplay event happens, call advance():
    for raider in get_tree().get_nodes_in_group("raiders"):
        raider.died.connect(func(): _progress.advance("your_task_id", 0, 1))
```

To chain a second task after the first:

```gdscript
var task2 := TaskData.new()
task2.id = "second_task_id"
task2.prerequisites = ["your_task_id"]   # locked until the first completes
```

Note `_progress.activate("second_task_id")` still needs to be called
somewhere once its prerequisite is done — usually inside your
`_on_task_completed` callback, checking which task just finished:

```gdscript
func _on_task_completed(task_id: StringName) -> void:
    if task_id == "your_task_id":
        _progress.activate("second_task_id")
```

---

## 7. Quick reference — every function you'll actually call

| Function | When to use it |
|---|---|
| `register(task)` | Once per task, usually all in `_ready()` |
| `activate(id)` | When a task should start being tracked (start of level, after a cutscene, after a prerequisite completes) |
| `advance(id, objective_index, amount)` | Every time a gameplay event should count as progress |
| `set_objective(id, index, value)` | Rare — force an objective to an exact value instead of incrementing |
| `complete(id)` / `fail(id)` | Only for forcing an outcome outside normal objective progress |
| `get_task(id)` | Read a task's current data (e.g. to show its description in UI) |
| `is_active(id)` / `is_completed(id)` | Quick boolean checks — useful for gating things like locked doors |

Everything else (`all()`, `active()`, `completed()`) is for building things
like a full quest-log screen listing every task at once.
