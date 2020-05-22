extends TileMap

enum TILE_TYPE {EMPTY, PLAYER, OBSTACLE, COIN}

onready var line = $Line2D

var tile_size: Vector2 = get_cell_size()
var half_tile_size: Vector2 = tile_size / 2

var grid_size = Vector2(16,10)
var grid: Array = []


var astar_path : Array = Array()

export var obstacle_quantity: int
export var coin_quantity: int = 3


onready var Obstacle = preload("res://Scenes/Obstacle.tscn")
onready var Coin = preload("res://Scenes/Coin.tscn")
onready var Player = preload("res://Scenes/Player.tscn")

onready var label = get_parent().get_node("Label")

var start : Vector2 = Vector2()
var end : Vector2 = Vector2()
var pos_moedas: Array = [] #posições de 0 a 2
var moedas_pegas=0




func _ready():
	
	label.text = "MOEDAS RESTANTES: " + str(coin_quantity)
	#Cria matriz da grid
	for x in range(grid_size.x):
		grid.append([])
# warning-ignore:unused_variable
		for y in range(grid_size.y):
			grid[x].append(TILE_TYPE.EMPTY)
	randomize()
	#Cria obstaculos
	var positions: Array = []
	
# warning-ignore:unused_variable
	for n in range(obstacle_quantity):
		var grid_position = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
		if not grid_position in positions:
			positions.append(grid_position)
	
	for pos in positions:
		var new_obstacle = Obstacle.instance()
		new_obstacle.position = map_to_world(pos) + half_tile_size
		grid[pos.x][pos.y] = TILE_TYPE.OBSTACLE
		add_child(new_obstacle)

	
		
	
	
	
	#Cria player
	var player_pos: Vector2 = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
	while player_pos in positions:
		player_pos = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
		

	var new_player = Player.instance()
	new_player.connect("area_entered", self, "_on_Area2D_area_entered")
	new_player.position = map_to_world(player_pos) + half_tile_size
	grid[player_pos.x][player_pos.y] = TILE_TYPE.PLAYER
	start = player_pos
	add_child(new_player)

	pos_moedas.append(Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y)))
	pos_moedas.append(Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y)))
	pos_moedas.append(Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y)))
	positions = []
	
	#Cria moedas
	criamoeda(moedas_pegas)
	#array com todas as posições
	
	
	# VALOR DE RETORNO DO PATH (MENOR CAMINHO DO A*)
	# Usar mesma chamada de função "get_node("/root/Grid")._start_a_star()" para obter valores para próximas moedas
	#var path = get_node("/root/Grid")._start_a_star()
	var cell = get_cell(1,1)
	

func criamoeda(pegas):
	var positions: Array = []
	var grid_position = pos_moedas[pegas]
	positions.append(grid_position)
	for pos in positions:
		var moeda = Coin.instance()
		moeda.position = map_to_world(pos) + half_tile_size
		#end = pos se n for usar apagar depois
		grid[pos.x][pos.y] = TILE_TYPE.COIN
		if pegas > 0:
			start = pos_moedas[pegas-1]
		end = pos_moedas[pegas]
		var path = get_node("/root/Grid")._start_a_star()
		get_parent().call_deferred("add_child",moeda)
		moedas_pegas=moedas_pegas+1
		
			

func is_cell_vacant(pos, direction) -> bool:
	#retorna se uma posiço esta vazia 
	var grid_pos = world_to_map(pos) + direction
	if grid_pos.x < grid_size.x and grid_pos.x >= 0:
		if grid_pos.y < grid_size.y and grid_pos.y >= 0:
			return true if grid[grid_pos.x][grid_pos.y] == TILE_TYPE.EMPTY || grid[grid_pos.x][grid_pos.y] == TILE_TYPE.COIN else false
	return false

func update_child_position (child_node, direction) -> Vector2:
	#Move um no filho para uma nova posiço no grid
	#Retorna a nova posiço global do no filho
	var grid_pos = world_to_map(child_node.position)
	grid[grid_pos.x][grid_pos.y] = TILE_TYPE.EMPTY
	
	var new_grid_pos = grid_pos + direction
	grid[new_grid_pos.x][new_grid_pos.y] = TILE_TYPE.PLAYER
	
	var target_pos = map_to_world(new_grid_pos) + half_tile_size
	return target_pos

func remove_coin_from_grid(coin) -> void:
	var pos = world_to_map(coin.position)
	if (coin_quantity>1):
		criamoeda(moedas_pegas)
	#else:
		#
		#o else só roda quando acaba as moedas
		#Colocar aqui a chamada para fim do jogo
		#
		#
		#
	grid[pos.x][pos.y] = TILE_TYPE.EMPTY	
	coin_quantity -= 1
	label.text = "MOEDAS RESTANTES: " + str(coin_quantity)
	

func _on_Area2D_area_entered(area):
	remove_coin_from_grid(area)
	area.queue_free()
	
	

