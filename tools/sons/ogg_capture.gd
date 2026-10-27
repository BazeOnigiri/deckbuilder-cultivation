extends SceneTree
## Decode les .ogg choisis dans sources.json (cle "ogg") (Python ne lit pas le Vorbis) : les joue un par un pendant un
## enregistrement --write-movie, et note dans capture.json l'image de depart et la duree de chacun.
## Puis split_capture.py decoupe le .wav enregistre en un .wav par son.
## godot --path . -s tools/sons/ogg_capture.gd --write-movie <dossier>/f.png --fixed-fps 30 --resolution 64x64

const FPS := 30
## Silence entre deux sons, en images : le decoupage cherche le debut du son apres le depart note.
const GAP_FRAMES := 9

var _queue: Array[String] = []
var _plan: Array = []
var _player := AudioStreamPlayer.new()
var _frame := 0
var _next_frame := 5


func _initialize() -> void:
	var root_dir := ProjectSettings.globalize_path("res://tools/sons/sources")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/sons/sources.json"))
	var wanted: Dictionary = manifest["ogg"]
	for source: String in wanted:
		_collect(root_dir.path_join(source), wanted[source])
	root.add_child(_player)
	print("sons a decoder : ", _queue.size())


func _collect(dir_path: String, names: Array) -> void:
	for file: String in DirAccess.get_files_at(dir_path):
		if file.ends_with(".ogg") and names.has(file.get_basename()):
			_queue.append(dir_path.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir_path):
		_collect(dir_path.path_join(sub), names)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < _next_frame:
		return false
	if _queue.is_empty():
		var out := FileAccess.open("res://tools/sons/sources/capture.json", FileAccess.WRITE)
		print("plan ecrit : ", _plan.size(), " erreur ", FileAccess.get_open_error())
		out.store_string(JSON.stringify({"fps": FPS, "mix_rate": AudioServer.get_mix_rate(), "sons": _plan}, "\t"))
		return true
	var path: String = _queue.pop_front()
	var stream := AudioStreamOggVorbis.load_from_file(path)
	_player.stream = stream
	_player.play()
	_plan.append({"path": path, "frame": _frame, "length": stream.get_length()})
	_next_frame = _frame + ceili(stream.get_length() * FPS) + GAP_FRAMES
	return false
