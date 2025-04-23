extends Control
@export var target_file_name : String

var base_dir_string : String
var mod_dir_string : String

var base_dir : DirAccess
var mod_dir : DirAccess

func _ready():
	get_node("VBoxContainer/BaseDir/FileDialogBase").set_current_dir(OS.get_executable_path())
	get_node("VBoxContainer/ModDir/FileDialogMod").set_current_dir(OS.get_executable_path())

func _on_base_dir_pressed() -> void:
	var dialog : FileDialog = get_node("VBoxContainer/BaseDir/FileDialogBase")
	dialog.show()


func _on_mod_dir_pressed() -> void:
	var dialog : FileDialog = get_node("VBoxContainer/ModDir/FileDialogMod")
	dialog.show()

func _on_file_dialog_base_dir_selected(dir : String) -> void:
	var button : Button = get_node("VBoxContainer/BaseDir")
	button.set_text("Base Directory: " + dir)
	base_dir_string = dir
	check_same()

func _on_file_dialog_mod_dir_selected(dir : String) -> void:
	var button : Button = get_node("VBoxContainer/ModDir")
	button.set_text("Modification Directory: " + dir)
	mod_dir_string = dir
	check_same()

func check_same() -> void:
	if (base_dir_string.get_file() == target_file_name && mod_dir_string.get_file() == "Merv's Modifications"):
		$VBoxContainer/Confirm.disabled = false
	else:
		print_debug("bye")
		$VBoxContainer/Confirm.disabled = true


func _on_confirm_pressed() -> void:
	$VBoxContainer/BaseDir.disabled = true
	$VBoxContainer/ModDir.disabled = true
	$VBoxContainer/Confirm.disabled = true
	#base_dir = DirAccess.open(base_dir_string)
	#mod_dir = DirAccess.open(mod_dir_string)
	if (base_dir_string.get_file() == target_file_name && mod_dir_string.get_file() == "Merv's Modifications"):
		print_debug("success")
		$VBoxContainer/Confirm.text = "Duplicating Base File"
		var dup_dir_string = duplicate_dir(base_dir_string, "Mervs Modifications")
		#$Timer.start()
		#await  $Timer.timeout
		#$VBoxContainer/Confirm.text = "Getting Base File Paths"
		#var base_file_paths : Array[String] = get_all_file_paths(dup_dir_string)
		$Timer.start()
		await  $Timer.timeout
		$VBoxContainer/Confirm.text = "Getting Modification File Paths"
		var mod_file_paths : Array[String] = get_all_file_paths(mod_dir_string)
		$Timer.start()
		await  $Timer.timeout
		$VBoxContainer/Confirm.text = "Patching"
		for each in mod_file_paths:
			var file : FileAccess = FileAccess.open(each,FileAccess.READ)
			var json : Dictionary = JSON.parse_string(file.get_as_text())
			for key in json.keys():
				if key != "file":
					match (json[key]["type"]):
						"replace":
							var replacer : FileAccess = FileAccess.open(dup_dir_string.path_join(json["file"]),FileAccess.READ_WRITE)
							var swapper : String = replacer.get_as_text()
							var before = swapper.get_slice(json[key]["linebefore"],0)
							print_debug(before)
							var after = swapper.get_slice(json[key]["lineafter"],1)
							print_debug("after: " + after)
							replacer.resize(0)
							replacer.store_string(before + json[key]["code"] + after)
							replacer.close()
			file.close()
			$Timer.start()
		await  $Timer.timeout
		$VBoxContainer/Confirm.text = "Done"
		$VBoxContainer/BaseDir.disabled = false
		$VBoxContainer/ModDir.disabled = false
		$VBoxContainer/Confirm.disabled = false
	else:
		$VBoxContainer/BaseDir.disabled = false
		$VBoxContainer/ModDir.disabled = false
		$VBoxContainer/Confirm.disabled = false


func duplicate_dir(path : String, name : String) -> String:
	var dirs : Array[String]
	var temp_file_paths : Array[String]
	var current_dir : DirAccess = DirAccess.open(path)
	dirs.append(current_dir.get_current_dir(true))
	while (!dirs.is_empty()):
		for each in current_dir.get_files():
			temp_file_paths.append(current_dir.get_current_dir(true).path_join(each))
		for each in current_dir.get_directories():
			dirs.append(current_dir.get_current_dir(true).path_join(each))
		dirs.remove_at(0)
		if (!dirs.is_empty()):
			current_dir.change_dir(dirs[0])
	var duplicate_path : Array
	for x in temp_file_paths.size():
		duplicate_path.append(temp_file_paths[x].replace("ComplementaryReimagined_r5.4 + EuphoriaPatches_1.5.2",name))
	for y in temp_file_paths.size():
		current_dir.make_dir_recursive_absolute(duplicate_path[y].get_base_dir())
		current_dir.copy_absolute(temp_file_paths[y],duplicate_path[y])
	return path.get_base_dir().path_join(name)

func get_all_file_paths(path : String) -> Array[String]:
	var dirs : Array[String]
	var temp_file_paths : Array[String]
	var current_dir : DirAccess = DirAccess.open(path)
	dirs.append(current_dir.get_current_dir(true))
	#print_debug(dirs)
	while (!dirs.is_empty()):
		for each in current_dir.get_files():
			temp_file_paths.append(current_dir.get_current_dir(true).path_join(each))
		for each in current_dir.get_directories():
			dirs.append(current_dir.get_current_dir(true).path_join(each))
		#print_debug(dirs)
		dirs.remove_at(0)
		if (!dirs.is_empty()):
			current_dir.change_dir(dirs[0])
	return temp_file_paths

func _on_license_toggled(toggled_on):
	if (toggled_on):
		$SplitContainer/RichTextLabel.clear()
		$SplitContainer2.hide()
		$SplitContainer.show()
		$SplitContainer/RichTextLabel.add_text("List of third-party licenses")
		$SplitContainer/RichTextLabel.newline()
		$SplitContainer/RichTextLabel.newline()
		for each in Engine.get_copyright_info():
			$SplitContainer/RichTextLabel.push_color(Color.RED)
			$SplitContainer/RichTextLabel.push_italics()
			$SplitContainer/RichTextLabel.push_bold()
			$SplitContainer/RichTextLabel.add_text("Next Entry: ")
			$SplitContainer/RichTextLabel.pop()
			$SplitContainer/RichTextLabel.pop()
			$SplitContainer/RichTextLabel.pop()
			$SplitContainer/RichTextLabel.newline()
			$SplitContainer/RichTextLabel.add_text("Name: " + each["name"])
			$SplitContainer/RichTextLabel.newline()
			var files = each["parts"][0]
			$SplitContainer/RichTextLabel.add_text("Files: ")
			for file in files["files"]:
				$SplitContainer/RichTextLabel.add_text(file + ", ")
			$SplitContainer/RichTextLabel.newline()
			$SplitContainer/RichTextLabel.add_text("Copyright: ")
			for copyright in files["copyright"]:
				$SplitContainer/RichTextLabel.add_text(copyright + ", ")
			$SplitContainer/RichTextLabel.newline()
			$SplitContainer/RichTextLabel.add_text("License/s: ")
			var license_name : String
			for license in files["license"]:
				$SplitContainer/RichTextLabel.add_text(license)
				license_name += license
			$SplitContainer/RichTextLabel.newline()
			for name in Engine.get_license_info().keys():
				if license_name.contains(name):
					$SplitContainer/RichTextLabel.add_text(name + " Text: ")
					$SplitContainer/RichTextLabel.newline()
					$SplitContainer/RichTextLabel.add_text(Engine.get_license_info()[name])
					$SplitContainer/RichTextLabel.newline()
			$SplitContainer/RichTextLabel.newline()
			$SplitContainer/RichTextLabel.newline()
	else:
		$SplitContainer/RichTextLabel.clear()
		$SplitContainer.hide()


func _on_license_2_toggled(toggled_on):
	if (toggled_on):
		$SplitContainer.hide()
		$SplitContainer2.show()
	else:
		$SplitContainer2.hide()
