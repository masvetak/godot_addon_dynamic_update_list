class_name DynamicUpdateList extends ScrollContainer

signal selected(data: Dictionary)

@export var max_items_per_page: int = 20
@export var columns: int = 1
@export var item_scene_reource: Resource
@export var item_name_key: String = ""
@export var sort_enabled: bool = true
@export var sort_key: String = ""
@export var search_enabled: bool = true
@export var search_key: String = ""

var _max_items_per_page: int = 0

var _list_items: Array = []
var _list_items_to_draw: Array = []
var _list_scroll_vertical_value: int = 0
var _list_size_y: int = 0

var _page_number: int = 1
var _page_number_max: int = 1
var _page_size_y: int = 0

@onready var _list: GridContainer = %List

# ------------------------------------------------------------------------------
# Build-in methods
# ------------------------------------------------------------------------------

func _ready() -> void:
	_max_items_per_page = max_items_per_page
	_list.columns = columns

func _process(_delta) -> void:
	if _list_scroll_vertical_value != self.scroll_vertical:
		_list_scroll_vertical_value = self.scroll_vertical
		if _page_number == _page_number_max: return
		if _list_scroll_vertical_value > int(float(_list_size_y) - float(_page_size_y)):
			if _page_size_y == 0 and _list.get_child_count() > 0:
				var list_item_size = _list.get_child(0).get("custom_minimum_size")
				var list_item_sepration = _list.get("theme_override_constants/v_separation")
				_page_size_y = ((list_item_size.y + list_item_sepration) * _max_items_per_page - list_item_sepration) / columns
			_page_number = _page_number + 1
			_list_size_y = _page_size_y * _page_number
			_draw_items()

# ------------------------------------------------------------------------------
# Public methods
# ------------------------------------------------------------------------------

func load_items(items: Array) -> void:
	_list_items = items
	_load_items(_list_items)

func remove_items() -> void:
	_list_items.clear()
	_remove_items()

func filter_items(text: String) -> void:
	_filter_by_key(text)

# ------------------------------------------------------------------------------
# Private methods
# ------------------------------------------------------------------------------

func _load_items(items: Array) -> void:
	_remove_items()
	_list_items_to_draw = items.duplicate()
	
	if sort_enabled: _list_items_to_draw.sort_custom(_sort_by_key)
	
	_list_scroll_vertical_value = 0
	_list_size_y = 0
	
	_page_size_y = 0
	_page_number = 1
	_page_number_max = ceil(ceil(float(_list_items_to_draw.size()) / float(_max_items_per_page)))
	
	_draw_items()

func _remove_items() -> void:
	for item in _list.get_children():
		_list.remove_child(item)
		item.queue_free()

func _draw_items() -> void:
	if _list == null: return
	
	var from_idx: int = _page_number * _max_items_per_page - _max_items_per_page
	var to_idx: int = _page_number * _max_items_per_page
	if to_idx > _list_items_to_draw.size(): to_idx = _list_items_to_draw.size()
	
	for idx in range(from_idx, to_idx):
		var item_data = _list_items_to_draw[idx]
		var list_item = item_scene_reource.instantiate()
		list_item.name = str(item_data[item_name_key])
		list_item.data = item_data
		list_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list_item.selected.connect(_on_list_item_selected)
		
		_list.add_child(list_item)

func _sort_by_key(a, b) -> bool:
	if a[sort_key] < b[sort_key]:
		return true
	return false

func _filter_by_key(text: String) -> void:
	var search_text_list: Array = text.strip_edges().split(" ")
	if text.is_empty():
		_load_items(_list_items)
	else:
		var filtered_list: Array = []
		for item in _list_items:
			var found_match: bool = true
			for search_text in search_text_list:
				if not item[search_key].to_lower().contains(search_text.to_lower()):
					found_match = false
					continue
			if found_match:
				filtered_list.append(item)
		_load_items(filtered_list)

func _on_list_item_selected(data: Dictionary) -> void:
	selected.emit(data)