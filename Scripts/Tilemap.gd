extends TileMap


# Variaveis globais
enum TILE_TYPE {EMPTY, PLAYER, OBSTACLE, COIN}
onready var line = $Line2D
onready var button = get_parent().get_parent().get_node("Button")
signal calculated
var tile_size: Vector2 = get_cell_size()
var half_tile_size: Vector2 = tile_size / 2
var grid_size = Vector2(16,10)
var grid: Array = []
var astar_path : Array = Array()
var open_set : Array = Array()
var closed_set : Array = Array()
export var obstacle_quantity: int
export var coin_quantity: int = 3
var NUM_COINS = coin_quantity
var realCoinQuantity = coin_quantity
onready var Astar = get_node("/root/Grid")
onready var Obstacle = preload("res://Scenes/Obstacle.tscn")
onready var Coin = preload("res://Scenes/Coin.tscn")
onready var Player = preload("res://Scenes/Player.tscn")
onready var IA = preload("res://Scenes/IA.tscn")
onready var End = preload("res://Scenes/End.tscn")
var end_scene
var obstacles_in_scene = []
var player_in_scene
var agent_in_scene
var coin_in_scene
var pos_IA_init
onready var label = get_parent().get_parent().get_node("Label")
var start : Vector2 = Vector2()
var end : Vector2 = Vector2()
var pos_moedas: Array = [] #posições de 0 a 2
var moedas_pegas = 0


# Função que é chamada quando o node é instanciado na cena
func _ready():
	label.text = "RESTANTES: " + str(coin_quantity)
	generate_grid_with_all_entities(false)
	var cell = get_cell(1,1)
	
	
# Função de criar moedas na grid
func criar_moeda():
	var positions: Array = []
	var grid_position = pos_moedas[moedas_pegas]
	positions.append(grid_position)
	for pos in positions:
		var moeda = Coin.instance()
		coin_in_scene = moeda
		moeda.position = map_to_world(pos) + half_tile_size
		grid[pos.x][pos.y] = TILE_TYPE.COIN
		if not is_instance_valid(agent_in_scene):
			if moedas_pegas > 0:
				start = pos_moedas[moedas_pegas-1]
			end = pos_moedas[moedas_pegas]
			var path = get_node("/root/Grid")._start_a_star()
		get_parent().call_deferred("add_child",moeda)
		moedas_pegas=moedas_pegas+1


# Verificação se a célula da grid é vazia
func is_cell_vacant(pos, direction) -> bool:
	var grid_pos = world_to_map(pos) + direction
	if grid_pos.x < grid_size.x and grid_pos.x >= 0:
		if grid_pos.y < grid_size.y and grid_pos.y >= 0:
			return true if grid[grid_pos.x][grid_pos.y] == TILE_TYPE.EMPTY || grid[grid_pos.x][grid_pos.y] == TILE_TYPE.COIN else false
	return false


# Função que move um no filho para uma nova posiço no grid
# Retorna a nova posiço global do no filho
func update_child_position (child_node, direction) -> Vector2:
	var grid_pos = world_to_map(child_node.position)
	grid[grid_pos.x][grid_pos.y] = TILE_TYPE.EMPTY

	var new_grid_pos = grid_pos + direction
	grid[new_grid_pos.x][new_grid_pos.y] = TILE_TYPE.PLAYER

	var target_pos = map_to_world(new_grid_pos) + half_tile_size

	return target_pos


# Função que remove as moedas da grid
func remove_coin_from_grid(coin) -> void:
	var pos = world_to_map(coin.position)
	if (coin_quantity>1):
		criar_moeda()
	else:
		end_scene = End.instance()
		if is_instance_valid(player_in_scene):
			player_in_scene.queue_free()
		if is_instance_valid(agent_in_scene):
			agent_in_scene.queue_free()
		button.disabled = true
		add_child(end_scene)

	grid[pos.x][pos.y] = TILE_TYPE.EMPTY	
	coin_quantity -= 1
	set_text(coin_quantity)

	label.text = "RESTANTES: " + str(coin_quantity)


func _on_Area2D_area_entered(area):
	remove_coin_from_grid(area)
	area.queue_free()


# Função de criação do jogador
func create_player(): 
	var player_pos: Vector2 = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
	pos_IA_init = player_pos
	var new_player = Player.instance()
	player_in_scene = new_player
	new_player.connect("area_entered", self, "_on_Area2D_area_entered")
	new_player.position = map_to_world(player_pos) + half_tile_size
	grid[player_pos.x][player_pos.y] = TILE_TYPE.PLAYER
	start = player_pos
	add_child(new_player)


# Função de criação dos obstáculos
func create_obstacles(positions):
	var aux = 0
	while aux != obstacle_quantity:
		var grid_position = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
		if grid[grid_position.x][grid_position.y] == TILE_TYPE.EMPTY:
			positions.append(grid_position)
			aux += 1

	for pos in positions:
		var new_obstacle = Obstacle.instance()
		new_obstacle.position = map_to_world(pos) + half_tile_size
		grid[pos.x][pos.y] = TILE_TYPE.OBSTACLE
		add_child(new_obstacle)
		obstacles_in_scene.append(new_obstacle)


# Função de criação das posições em que as moedas devem ser instanciadas
func create_coins_positions():
	pos_moedas = []
	var aux = 0
	while(aux != realCoinQuantity):
		var rand_pos = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
		if grid[rand_pos.x][rand_pos.y] == TILE_TYPE.EMPTY:
			pos_moedas.append(rand_pos)
			aux += 1


# Função que gera a grid vazia
func generate_empty_grid():
	var alternatecell = false
	
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			grid[x].append(TILE_TYPE.EMPTY)
			if alternatecell :
				set_cell(x,y,4)
			else:
				set_cell(x,y,5)
			alternatecell = not alternatecell
		alternatecell = not alternatecell


# Função de reinicio da grid (limpa as instancias)
func clear_grid():
	player_in_scene.queue_free()
	for obstacle in obstacles_in_scene:
		obstacle.queue_free()

	obstacles_in_scene = []
	coin_quantity = realCoinQuantity
	set_text(coin_quantity)
	if is_instance_valid(coin_in_scene): coin_in_scene.queue_free()
	moedas_pegas = 0

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			grid[x][y] = TILE_TYPE.EMPTY

	astar_path.clear()
	open_set.clear()
	closed_set.clear()
	line.clear_points()


# Função que gera as entidades da grid
func generate_grid_with_all_entities(restart):
	if restart:
		clear_grid()
	else: generate_empty_grid()
	var positions: Array = []
	create_player()
	randomize()
	create_obstacles(positions)
	randomize()
	create_coins_positions()
	randomize()
	criar_moeda()


# Função que atualiza o texto de hamburgueres restantes
func set_text(quantity):
	label.text = "RESTANTES: " + str(quantity)


# Função de instanciação do agente
func instance_ia():
	agent_in_scene = IA.instance()
	agent_in_scene.connect("area_entered", self, "_on_Area2D_area_entered")
	agent_in_scene.position = map_to_world(pos_IA_init) + half_tile_size
	grid[pos_IA_init.x][pos_IA_init.y] = TILE_TYPE.PLAYER
	add_child(agent_in_scene)

	connect("calculated", agent_in_scene, "play_solution")
	emit_signal("calculated")
	moedas_pegas = 0
	coin_quantity = NUM_COINS
	criar_moeda()
	show_path()


# Função que mostra o caminho ótimo
func show_path():
	line.clear_points()
	for i in astar_path.size():
		for m in astar_path[i].size():
			line.add_point(map_to_world(Vector2(astar_path[i][m])) + Vector2(32,32))
