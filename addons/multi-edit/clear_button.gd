tool
extends Button

var plugin:EditorPlugin

func init(plugin:EditorPlugin):
	self.plugin = plugin

func _pressed():
	plugin.unsetup_all()
