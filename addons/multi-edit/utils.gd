#=========== Node utils ==================
static func get_nodes(node:Node)->Array:
	var nodes = []
	var stack = [node]
	while stack:
		var n = stack.pop_back()
		nodes.push_back(n)
		stack.append_array(n.get_children())
	return nodes
