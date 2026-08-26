extends Node

class_name PoissonDiskSampler

func generatePoints(radius: float, region: Rect2, k: int = 30) -> Array[Vector2]:
	var cellSize: float = radius / sqrt(2.0)
	
	var grid : Array[int] = []
	var cols: int = ceil(region.size.x / cellSize)
	var rows: int = ceil(region.size.y / cellSize)
	grid.resize(cols * rows)
	grid.fill(-1)
	print(grid.size())
	
	var finalPoints : Array[Vector2] = []
	var activePoints : Array[Vector2] = []
	
	activePoints.append(region.position + region.size/2.0)
	
	while activePoints.size() > 0:
		var randomIndex : int = randi_range(0, activePoints.size() - 1)
		var spawnCenter : Vector2 = activePoints[randomIndex]
		var valid : bool = false
		
		for i in range(k):
			var angle : float = randf() * PI * 2.0
			var dist : float = randf_range(radius, 2.0 * radius)
			var dir : Vector2 = Vector2(sin(angle), cos(angle))
			var candidate = spawnCenter + dir * dist
			
			if isValid(candidate, region, cellSize, cols, rows, finalPoints, grid, radius):
				finalPoints.append(candidate)
				activePoints.append(candidate)
				var cCol = int((candidate.x - region.position.x)/cellSize)
				var cRow = int((candidate.y - region.position.y)/cellSize)
				grid[cCol + cRow * cols] = finalPoints.size() - 1
				valid = true
				break
			
		if !valid:
			activePoints.remove_at(randomIndex)
	
	return finalPoints

func isValid(candidate : Vector2, region: Rect2, cellSize: float, cols: int, rows: int, finalPoints: Array[Vector2], grid: Array[int], radius : float) -> bool:
	if region.has_point(candidate):
		var cellX: int = int((candidate.x - region.position.x)/ cellSize)
		var cellY: int = int((candidate.y - region.position.y)/ cellSize)
		var searchStartX : int = max(0, cellX - 2)
		var searchStartY : int = max(0, cellY - 2)
		var searchEndX : int = min(cols-1, cellX + 2)
		var searchEndY : int = min(rows-1, cellY + 2)
		
		for x in range(searchStartX, searchEndX + 1):
			for y in range(searchStartY, searchEndY + 1):
				var index : int = grid[x + y * cols]
				if index != -1:
					var dist : float = candidate.distance_to(finalPoints[index])
					if dist < radius:
						return false
		return true
					
	return false
