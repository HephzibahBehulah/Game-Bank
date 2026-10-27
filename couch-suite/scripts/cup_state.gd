extends Node

const SAVE_PATH := "user://kart_grand_prix_progress.json"
var cup_points: Array[int] = [0,0,0,0,0,0,0,0]
var cup_race := 0
var difficulty := 1
var track_seed := 0
var cups_completed := 0
var player_cup_wins := 0
var best_cup_points := 0

func _ready() -> void:
    load_progress()

func start_cup(selected_difficulty: int, seed: int) -> void:
    cup_points = [0,0,0,0,0,0,0,0]
    cup_race = 0
    difficulty = clampi(selected_difficulty, 0, 2)
    track_seed = seed

func track_for_race() -> int:
    return (track_seed + cup_race * 2) % 8

func record_race(points: Array[int]) -> void:
    for i in range(mini(cup_points.size(), points.size())):
        cup_points[i] += points[i]
    cup_race += 1

func cup_winner() -> int:
    var best := 0
    for i in range(1, cup_points.size()):
        if cup_points[i] > cup_points[best]:
            best = i
    return best

func cup_standings() -> Array[int]:
    var order: Array[int] = []
    for racer_id in range(cup_points.size()):
        order.append(racer_id)
    order.sort_custom(func(a: int, b: int) -> bool:
        if cup_points[a] == cup_points[b]:
            return a < b
        return cup_points[a] > cup_points[b])
    return order

func complete_cup() -> void:
    cups_completed += 1
    var total := 0
    for points in cup_points:
        total += points
    best_cup_points = maxi(best_cup_points, total)
    if cup_winner() < 2:
        player_cup_wins += 1
    save_progress()

func save_progress() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("Could not save Kart Grand Prix career progress: %s" % error_string(FileAccess.get_open_error()))
        return
    file.store_string(JSON.stringify({
        "version": 1,
        "cups_completed": cups_completed,
        "player_cup_wins": player_cup_wins,
        "best_cup_points": best_cup_points,
        "difficulty": difficulty,
        "track_seed": track_seed
    }, "\t"))

func load_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_warning("Could not load Kart Grand Prix career progress: %s" % error_string(FileAccess.get_open_error()))
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary or int(parsed.get("version", 0)) != 1:
        push_warning("Kart Grand Prix progress file is invalid; starting a fresh career record.")
        return
    cups_completed = maxi(0, int(parsed.get("cups_completed", 0)))
    player_cup_wins = maxi(0, int(parsed.get("player_cup_wins", 0)))
    best_cup_points = maxi(0, int(parsed.get("best_cup_points", 0)))
    difficulty = clampi(int(parsed.get("difficulty", 1)), 0, 2)
    track_seed = maxi(0, int(parsed.get("track_seed", 0)))
