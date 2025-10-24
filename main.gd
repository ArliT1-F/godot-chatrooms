extends Node2D

@onready var ui_address: LineEdit = $HBoxContainer/Container_Left/UI_Address
@onready var ui_username: LineEdit = $HBoxContainer/Container_Left/UI_Username
@onready var ui_host: Button = $HBoxContainer/Container_Left/UI_Host
@onready var ui_join: Button = $HBoxContainer/Container_Left/UI_Join
@onready var ui_chat: TextEdit = $HBoxContainer/Container_Middle/UI_Chat
@onready var ui_send: Button = $HBoxContainer/Container_Middle/Message_Container/UI_Send
@onready var ui_message: LineEdit = $HBoxContainer/Container_Middle/Message_Container/UI_Message
@onready var ui_username_display: LineEdit = $HBoxContainer/Container_Left/ColorRect/VBoxContainer/UI_UsernameDisplay


var username : String
var message : String

func _ready():
	ui_username.text = get_machine_username()
	ui_username_display.text = ui_username.text

func get_machine_username():
	if OS.get_environment("USER") != "": return OS.get_environment("USER") # LINUX
	elif OS.get_environment("USERNAME") != "": return OS.get_environment("USERNAME") # WINDOWS
	else: return "client"

func _on_ui_host_pressed():
	server_host(7777)

func _on_ui_join_pressed():
	server_connect(ui_address.text, 7777)

func server_host(port):
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	get_tree().set_multiplayer(SceneMultiplayer.new(),self.get_path())
	multiplayer.multiplayer_peer = peer
	joined()

func server_connect(address, port):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	get_tree().set_multiplayer(SceneMultiplayer.new(),self.get_path())
	multiplayer.multiplayer_peer = peer
	joined()
	
func _on_ui_send_pressed():
	message_handler(ui_message.text)
	ui_message.text = ""
	
@rpc ("any_peer","call_local")
func message_rpc(username,data):
	ui_chat.text += str(username, ": ", data, "\n")
	ui_chat.scroll_vertical = ui_chat.get_line_count() #scroll to bottom
	
func joined():
	debughide()
	username = ui_username.text
	ui_username_display.text = username

func _on_ui_message_text_submitted(new_text: String):
	message_handler(ui_message.text)
	ui_message.text = ""

func message_handler(content):
	if content == "": return # Dont send empty messages.
	if content.begins_with("/"): return command_handler(content.trim_prefix("/"))
	rpc("message_rpc", username, content)
	
func command_handler(command):
	consolelog("[CONSOLE]: "+command)
	if command == "debughide": return debughide()
	if command == "debugshow": return debugshow()
	

func consolelog(content):
	print("["+Time.get_datetime_string_from_system()+"] "+content)

func debughide():
	consolelog("[DEBUG]: Debug hidden")
	ui_host.hide()
	ui_join.hide()
	ui_username.hide()
	ui_address.hide()
	
func debugshow():
	consolelog("[DEBUG]: Debug shown")
	ui_host.show()
	ui_join.show()
	ui_username.show()
	ui_address.show()
