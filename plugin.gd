@tool extends EditorPlugin

# ------------------------------------------------------------------------------
# Build-in methods
# ------------------------------------------------------------------------------

func _enter_tree() -> void:
	self.add_custom_type("DynamicUpdateList", "Control", preload("dynamic_update_list.gd"), preload("icon.png"))

func _exit_tree() -> void:
	self.remove_custom_type("DynamicUpdateList")
