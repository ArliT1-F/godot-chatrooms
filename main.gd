extends Node2D

@onready var ui_address: LineEdit = $HBoxContainer/Container_Left/UI_Address
@onready var ui_username: LineEdit = $HBoxContainer/Container_Left/UI_Username
@onready var ui_host: Button = $HBoxContainer/Container_Left/UI_Host
@onready var ui_join: Button = $HBoxContainer/Container_Left/UI_Join
@onready var ui_chat: TextEdit = $HBoxContainer/Container_Middle/UI_Chat
@onready var ui_send: Button = $HBoxContainer/Container_Middle/Message_Container/UI_Send
@onready var ui_message: LineEdit = $HBoxContainer/Container_Middle/Message_Container/UI_Message
@onready var ui_username_display: LineEdit = $HBoxContainer/Container_Left/ColorRect/VBoxContainer/UI_UsernameDisplay
@onready var status_indicator: ColorRect = $HBoxContainer/Container_Left/ColorRect/VBoxContainer/StatusContainer/StatusIndicator
@onready var status_label: Label = $HBoxContainer/Container_Left/ColorRect/VBoxContainer/StatusContainer/StatusLabel


var username : String
var message : String

enum ConnectionStatus {
	DISCONNECTED,
	CONNECTING,
	CONNECTED
}

var current_status = ConnectionStatus.DISCONNECTED

func _ready():
	ui_username.text = get_machine_username()
	ui_username_display.text = ui_username.text
	update_connection_status(ConnectionStatus.DISCONNECTED)
	
	# Connect to multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func get_machine_username():
	if OS.get_environment("USER") != "": return OS.get_environment("USER") # LINUX
	elif OS.get_environment("USERNAME") != "": return OS.get_environment("USERNAME") # WINDOWS
	else: return "client"

func _on_ui_host_pressed():
	update_connection_status(ConnectionStatus.CONNECTING)
	server_host(7777)

func _on_ui_join_pressed():
	update_connection_status(ConnectionStatus.CONNECTING)
	server_connect(ui_address.text, 7777)

func server_host(port):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error != OK:
		consolelog("[ERROR]: Failed to create server")
		update_connection_status(ConnectionStatus.DISCONNECTED)
		return
	get_tree().set_multiplayer(SceneMultiplayer.new(),self.get_path())
	multiplayer.multiplayer_peer = peer
	update_connection_status(ConnectionStatus.CONNECTED)
	joined()

func server_connect(address, port):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error != OK:
		consolelog("[ERROR]: Failed to create client")
		update_connection_status(ConnectionStatus.DISCONNECTED)
		return
	get_tree().set_multiplayer(SceneMultiplayer.new(),self.get_path())
	multiplayer.multiplayer_peer = peer
	
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

# Connection status management
func update_connection_status(status: ConnectionStatus):
	current_status = status
	match status:
		ConnectionStatus.DISCONNECTED:
			status_indicator.color = Color(0.8, 0.2, 0.2, 1) # Red
			status_label.text = "Disconnected"
		ConnectionStatus.CONNECTING:
			status_indicator.color = Color(0.9, 0.7, 0.2, 1) # Yellow
			status_label.text = "Connecting..."
		ConnectionStatus.CONNECTED:
			status_indicator.color = Color(0.2, 0.8, 0.2, 1) # Green
			status_label.text = "Connected"

# Multiplayer signal handlers
func _on_peer_connected(id):
	consolelog("[NETWORK]: Peer " + str(id) + " connected")
	ui_chat.text += "[System]: User " + str(id) + " joined the chat\n"
	ui_chat.scroll_vertical = ui_chat.get_line_count()

func _on_peer_disconnected(id):
	consolelog("[NETWORK]: Peer " + str(id) + " disconnected")
	ui_chat.text += "[System]: User " + str(id) + " left the chat\n"
	ui_chat.scroll_vertical = ui_chat.get_line_count()

func _on_connected_to_server():
	consolelog("[NETWORK]: Successfully connected to server")
	update_connection_status(ConnectionStatus.CONNECTED)
	joined()

func _on_connection_failed():
	consolelog("[ERROR]: Connection failed")
	ui_chat.text += "[System]: Failed to connect to server\n"
	ui_chat.scroll_vertical = ui_chat.get_line_count()
	update_connection_status(ConnectionStatus.DISCONNECTED)

func _on_server_disconnected():
	consolelog("[NETWORK]: Disconnected from server")
	ui_chat.text += "[System]: Disconnected from server\n"
	ui_chat.scroll_vertical = ui_chat.get_line_count()
	update_connection_status(ConnectionStatus.DISCONNECTED)