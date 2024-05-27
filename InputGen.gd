@tool
extends EditorPlugin

const debugMode = false
const staticVarName = "ProjectInputMap"
const scriptPath = "res://addons/InputGen/ProjectInputMap.gd"

func _enter_tree():
	project_settings_changed.connect(OnProjectChanged)
	#resource_saved.connect(OnResourceSaved)
	GenerateMap()
	RegisterMap()
	print("InputGen loaded")

func GenerateMap():
	printMessage("Generating custom input map...")
	#var actions = InputMap.get_actions()
	
	var projectFile = FileAccess.open("res://project.godot", FileAccess.READ)
	var projectText = projectFile.get_as_text()
	var lines = projectText.split("\n")
	
	var extraNames = []

	var sectionRegex = RegEx.create_from_string("^\\[(\\w+)\\]$")
	var parameterRegex = RegEx.create_from_string("^([\\w\\/]+)={$")
	var gettingNames = false
	for line in lines:
		var sectionRegexRes = sectionRegex.search(line)
		if sectionRegexRes != null:
			if sectionRegexRes.get_string(1) == "input":
				gettingNames = true
				continue
			elif gettingNames:
				break

		var paramRegexRes = parameterRegex.search(line)
		if paramRegexRes == null:
			continue

		extraNames.append(paramRegexRes.get_string(1))
		
	var outputText = []
	outputText.append("extends Node")

	var variableRegex = RegEx.create_from_string("^[^a-zA-Z_]+|[^a-zA-Z_0-9]+") #https://stackoverflow.com/a/5056104
	var format_string = "@export var input_%s = \"%s\""
	for inputName in extraNames:
		var variableName = variableRegex.sub(inputName, "_", true)
		outputText.append(format_string % [variableName, inputName])

	var file = FileAccess.open(scriptPath, FileAccess.WRITE)

	file.store_string("\r\n".join(outputText))
	printMessage("Complete")

func RegisterMap():
	add_autoload_singleton(staticVarName, scriptPath)

func printMessage(message):
	if debugMode:
		print(message)


func OnProjectChanged():
	GenerateMap()

func OnResourceSaved(resource: Resource):
	print(resource.resource_name)
	if resource.resource_name == "project.godot":
		GenerateMap()

func _exit_tree():
	if project_settings_changed.is_connected(OnProjectChanged):
		project_settings_changed.disconnect(OnProjectChanged)
		
		if resource_saved.is_connected(OnResourceSaved):
			resource_saved.disconnect(OnResourceSaved)
	
	#print("InputGen unloaded")
