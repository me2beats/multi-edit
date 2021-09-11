tool
extends EditorPlugin

const Utils = preload("utils.gd")
const Data = preload("data.tres")

var base: = get_editor_interface().get_base_control()
var inspector:EditorInspector = get_editor_interface().get_inspector()
var inspector_child:Control

var selection_color = Data.selection_color

func _enter_tree():
	yield(get_tree(), "idle_frame")
	inspector_child= inspector.get_child(0)
	
	var inspector_top_bar = inspector.get_parent().get_child(0)
	var clear_button:Button = Data.clear_button
	clear_button.init(self)
	inspector_top_bar.add_child(clear_button)
	inspector_top_bar.move_child(clear_button, 4)

#todo: optimize?
#move to utils?
func get_editor_spin_slider_at_mouse()->EditorSpinSlider:
	var empty:EditorSpinSlider

	var nodes = Utils.get_nodes(inspector_child)
	var mouse_pos = base.get_global_mouse_position()
	nodes.invert()
	
	for n in nodes:
		n = n as Control
		if not n: continue
		if n.get_global_rect().has_point(mouse_pos) and n is EditorSpinSlider:
			return n
	return empty





func on_slider_draw(spin_slider:EditorSpinSlider, canvas_item:RID):
	VisualServer.canvas_item_clear(canvas_item)
	VisualServer.canvas_item_add_rect(canvas_item, spin_slider.get_rect().grow(4), selection_color)


func on_slider_exit_tree(slider:EditorSpinSlider):
	unsetup_slider(slider)


func on_lineedit_focus_entered(edited_slider:EditorSpinSlider):
	Data.edited_slider = edited_slider
	
	for slider in Data.shared.keys():
		slider = slider as EditorSpinSlider
		if not is_instance_valid(slider): continue
		if slider == edited_slider: continue
		
		edited_slider.share(slider)

	
func on_lineedit_focus_exited(edited_slider:EditorSpinSlider):
	return



func _input(event):
	event = event as InputEventMouseButton
	if not (event and event.pressed): return
	if not (event.button_index == BUTTON_RIGHT or event.button_index == BUTTON_MIDDLE): return

	var mouse_pos = base.get_global_mouse_position()	

	if !inspector_child.get_global_rect().has_point(mouse_pos):return
	
	if event.button_index == BUTTON_MIDDLE:
		unsetup_all()
		return
	
	if Input.get_current_cursor_shape() == 1: return


	var spin_slider: = get_editor_spin_slider_at_mouse()
	if not spin_slider: return
	
	if not spin_slider.is_connected("draw", self, "on_slider_draw"):
		setup_slider(spin_slider)
	else:
		unsetup_slider(spin_slider)



func setup_slider(spin_slider:EditorSpinSlider):
	var lineedit:LineEdit = spin_slider.get_child(1)
	if not lineedit:
		push_warning("can't find SpinSlider LineEdit node")
		return
	

	lineedit.connect("focus_entered", self, "on_lineedit_focus_entered", [spin_slider])
	lineedit.connect("focus_exited", self, "on_lineedit_focus_exited", [spin_slider])


	var rid = VisualServer.canvas_item_create()
	VisualServer.canvas_item_set_parent(rid, spin_slider.get_parent().get_canvas_item())


	spin_slider.set_meta('canvas_item', rid)
	spin_slider.connect("draw", self, "on_slider_draw", [spin_slider, rid])

	spin_slider.connect("tree_exited", self, "on_slider_exit_tree", [spin_slider])

	
	Data.shared[spin_slider] = true
	
#	yield(get_tree(), "idle_frame")
	on_slider_draw(spin_slider, rid) # force draw



func unsetup_slider(spin_slider:EditorSpinSlider):

	spin_slider.disconnect("draw", self, "on_slider_draw")
	spin_slider.disconnect("tree_exited", self, "on_slider_exit_tree")

	spin_slider.unshare()

	var lineedit:LineEdit = spin_slider.get_child(1)
	if lineedit:
		lineedit.disconnect("focus_entered", self, "on_lineedit_focus_entered")
		lineedit.disconnect("focus_exited", self, "on_lineedit_focus_exited")

	var rid = spin_slider.get_meta('canvas_item')

	VisualServer.canvas_item_clear(rid)

	VisualServer.free_rid(rid)

	Data.shared.erase(spin_slider)

	if spin_slider == Data.edited_slider:
		Data.edited_slider = null


func unsetup_all():
	for slider in Data.shared.keys():
		if is_instance_valid(slider):
			unsetup_slider(slider)

	Data.shared.clear()
	Data.edited_slider = null


func _exit_tree():
	unsetup_all()

	var clear_button:Button = Data.clear_button
	clear_button.get_parent().remove_child(clear_button)
