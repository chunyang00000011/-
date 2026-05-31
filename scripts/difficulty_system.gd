extends Node
class_name HomewardDifficultySystem

## 纯函数难度系统：输入飞行距离，输出各系统的难度参数。
## 其他系统向它查询，自身不持有运行时状态。

const FOOD_INTERVAL_BASE: float = 1.1
const FOOD_INTERVAL_MIN: float = 1.0

const TREE_CHANCE_BASE: float = 0.25
const TREE_CHANCE_MAX: float = 0.40

const PREDATOR_CHANCE_BASE: float = 0.0
const PREDATOR_CHANCE_MAX: float = 0.45

const RAIN_DURATION_BASE: float = 10.0
const RAIN_DURATION_MAX: float = 28.0

const NIGHT_PERIOD_BASE: float = 120.0
const NIGHT_PERIOD_MIN: float = 80.0

const SCROLL_MULT_PER_1000: float = 0.08
const SCROLL_MULT_MAX: float = 1.6


func params_for_distance(distance_m: float) -> Dictionary:
	var steps_1000: float = maxf(0.0, distance_m) / 1000.0
	var steps_2000: float = maxf(0.0, distance_m) / 2000.0

	var food_interval: float = FOOD_INTERVAL_BASE * pow(0.95, steps_1000)
	food_interval = maxf(FOOD_INTERVAL_MIN, food_interval)

	var tree_chance: float = TREE_CHANCE_BASE + 0.03 * steps_1000
	tree_chance = minf(TREE_CHANCE_MAX, tree_chance)

	var predator_chance: float = PREDATOR_CHANCE_BASE + 0.04 * steps_1000
	predator_chance = minf(PREDATOR_CHANCE_MAX, predator_chance)

	var rain_duration: float = RAIN_DURATION_BASE + 1.0 * steps_1000
	rain_duration = minf(RAIN_DURATION_MAX, rain_duration)

	var night_period: float = NIGHT_PERIOD_BASE - 10.0 * steps_2000
	night_period = maxf(NIGHT_PERIOD_MIN, night_period)

	var scroll_multiplier: float = 1.0 + SCROLL_MULT_PER_1000 * steps_1000
	scroll_multiplier = minf(SCROLL_MULT_MAX, scroll_multiplier)

	return {
		"food_interval": food_interval,
		"tree_chance": tree_chance,
		"predator_chance": predator_chance,
		"rain_duration": rain_duration,
		"night_period": night_period,
		"scroll_multiplier": scroll_multiplier,
	}
