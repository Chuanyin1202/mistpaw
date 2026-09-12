extends RefCounted
## Stop near the loot and let the game's magnet finish pickup.
static func loot_movement(dx: float) -> int:
	return int(signf(dx)) if absf(dx) > 1.0 else 0
