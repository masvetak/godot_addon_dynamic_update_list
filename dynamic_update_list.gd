class_name DynamicUpdateList extends Control

enum SortOrder { ASCENDING, DESCENDIN }
enum SearchType { CONTAINS, BEGINS_WITH }

signal selected(data: Dictionary)

@export var max_items_per_page: int = 20
@export_range(1, 2) var columns: int = 1
@export var vertical_scroll_mode: ScrollContainer.ScrollMode = ScrollContainer.SCROLL_MODE_DISABLED
@export var item_scene_reource: Resource
@export var item_name_key: String = ""
@export var sort_enabled: bool = true
@export var sort_order: SortOrder = SortOrder.ASCENDING
@export var sort_key: String = ""
@export var search_enabled: bool = true
@export var search_type: SearchType = SearchType.CONTAINS
@export var search_key: String = ""

var _scroll: ScrollContainer = null
var _list: GridContainer = null

var _max_items_per_page: int = 0

var _list_items: Array = []
var _list_items_to_draw: Array = []
var _list_scroll_vertical_value: int = 0
var _list_size_y: int = 0

var _page_number: int = 1
var _page_number_max: int = 1
var _page_size_y: int = 0

# ------------------------------------------------------------------------------
# Build-in methods
# ------------------------------------------------------------------------------

func _ready() -> void:
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = vertical_scroll_mode
	_scroll.scroll_deadzone = 64
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	self.add_child(_scroll)
	
	_list = GridContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.set("theme_override_constants/h_separation", 16)
	_list.set("theme_override_constants/v_separation", 16)
	_scroll.add_child(_list)
	
	_max_items_per_page = max_items_per_page
	_list.columns = columns

func _process(_delta) -> void:
	if _list_scroll_vertical_value != _scroll.scroll_vertical:
		_list_scroll_vertical_value = _scroll.scroll_vertical
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
	match search_type:
		SearchType.CONTAINS:
			_filter_by_key_with_contains(text)
		SearchType.BEGINS_WITH:
			_filter_by_key_with_begins_with(text)

# ------------------------------------------------------------------------------
# Private methods
# ------------------------------------------------------------------------------

func _load_items(items: Array) -> void:
	_remove_items()
	_list_items_to_draw = items.duplicate()
	
	if sort_enabled: 
		match sort_order:
			SortOrder.ASCENDING:
				_list_items_to_draw.sort_custom(_sort_by_key_ascending)
			SortOrder.DESCENDIN:
				_list_items_to_draw.sort_custom(_sort_by_key_descending)
	
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
		var item_name = item_data.get(item_name_key)
		if item_data != null:
			list_item.name = str(item_name)
		list_item.data = item_data
		list_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list_item.selected.connect(_on_list_item_selected)
		
		_list.add_child(list_item)

func _sort_by_key_ascending(a, b) -> bool:
	if a[sort_key] < b[sort_key]:
		return true
	return false

func _sort_by_key_descending(a, b) -> bool:
	if a[sort_key] > b[sort_key]:
		return true
	return false

func _filter_by_key_with_contains(text: String) -> void:
	if not search_enabled: return
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

func _filter_by_key_with_begins_with(text: String) -> void:
	if not search_enabled: return
	var search_text_list: Array = text.strip_edges().split(" ")
	if text.is_empty():
		_load_items(_list_items)
	else:
		var filtered_list: Array = []
		for item in _list_items:
			var found_match: bool = true
			for search_text in search_text_list:
				var item_text: String = item[search_key].to_lower()
				var item_text_words: Array = item_text.split(' ')
				var found_match_in_text: bool = false
				for item_text_word in item_text_words:
					if item_text_word.begins_with(search_text.to_lower()):
						found_match_in_text = true
						continue
				if found_match_in_text: 
					found_match = true
				else:
					found_match = false
					break
			if found_match:
				filtered_list.append(item)
		_load_items(filtered_list)

func _on_list_item_selected(data: Dictionary) -> void:
	selected.emit(data)
