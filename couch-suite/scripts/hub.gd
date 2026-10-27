extends Control

const GAME_FILE := "res://games.json"
var games: Array = []
var category_filter := "All"
var list_box: VBoxContainer

func _ready() -> void:
    var file := FileAccess.open(GAME_FILE, FileAccess.READ)
    if file == null:
        push_error("Could not open couch suite game catalog")
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Array:
        games = parsed
    _build_ui()
    _populate()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#07111f")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 14)
    root.offset_left = 34
    root.offset_top = 24
    root.offset_right = -34
    root.offset_bottom = -24
    add_child(root)
    var title := Label.new()
    title.text = "HEPHZIBAH BEHULAH  /  COUCH GAME BANK"
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("#65f0df"))
    root.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "100 GAME ROADMAP  ·  GODOT 4  ·  LOCAL PLAY"
    subtitle.add_theme_font_size_override("font_size", 13)
    subtitle.add_theme_color_override("font_color", Color("#a9bbcd"))
    root.add_child(subtitle)
    var filter_row := HBoxContainer.new()
    root.add_child(filter_row)
    var filter_label := Label.new()
    filter_label.text = "CATEGORY"
    filter_label.add_theme_color_override("font_color", Color("#a9bbcd"))
    filter_row.add_child(filter_label)
    var category_picker := OptionButton.new()
    category_picker.add_item("All categories")
    for cat in ["Racing","Football","Basketball","Racket Sports","Combat & Party","Platform","Puzzles","Shooters","Strategy","Party Games","Sports","Rhythm & Co-op"]:
        category_picker.add_item(cat)
    category_picker.item_selected.connect(_on_category_selected.bind(category_picker))
    filter_row.add_child(category_picker)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(scroll)
    list_box = VBoxContainer.new()
    list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(list_box)
    var footer := Label.new()
    footer.text = "Keyboard: arrows / Enter  ·  Gamepad: left stick / D-pad / A  ·  Only tested games launch"
    footer.add_theme_color_override("font_color", Color("#8299af"))
    root.add_child(footer)

func _on_category_selected(index: int, picker: OptionButton) -> void:
    _filter("All" if index == 0 else picker.get_item_text(index))

func _filter(category: String) -> void:
    category_filter = category
    _populate()

func _populate() -> void:
    if list_box == null:
        return
    for child in list_box.get_children():
        child.queue_free()
    var first: Button
    for game in games:
        if category_filter != "All" and game.get("category","") != category_filter:
            continue
        var row := HBoxContainer.new()
        list_box.add_child(row)
        var launch := Button.new()
        launch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        launch.text = "%02d  %s" % [int(game.id), str(game.title)]
        launch.disabled = not bool(game.get("launchable", false))
        if launch.disabled:
            launch.text += "   ·   LOCKED"
        else:
            first = launch
            launch.pressed.connect(_launch_game.bind(str(game.get("scene", ""))))
        row.add_child(launch)
        var category := Label.new()
        category.custom_minimum_size.x = 150
        category.text = str(game.category)
        category.add_theme_color_override("font_color", Color("#85a1b7"))
        row.add_child(category)
    if first:
        first.grab_focus()

func _launch_game(scene_path: String) -> void:
    if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
        push_error("The selected game is marked playable but its scene could not be found: %s" % scene_path)
        return
    get_tree().change_scene_to_file(scene_path)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() is Button:
        var focused := get_viewport().gui_get_focus_owner() as Button
        if not focused.disabled:
            focused.pressed.emit()
