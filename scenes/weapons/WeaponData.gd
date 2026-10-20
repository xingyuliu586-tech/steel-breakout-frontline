class_name WeaponData
extends Resource

var id := ""
var display_name := ""
var damage := 10
var fire_rate := 0.2
var magazine_size := 10
var ammo_in_magazine := 10
var reserve_ammo := 0
var reload_time := 1.0
var bullet_speed := 450.0
var spread := 0.0
var recoil := 0.0
var automatic := false
var pellets := 1
var projectile_type := "bullet"
var icon_region := Rect2()
var muzzle_flash_type := "muzzle"

static func from_dictionary(values: Dictionary) -> WeaponData:
	var data := WeaponData.new()
	data.id = str(values.get("id", ""))
	data.display_name = str(values.get("display_name", data.id))
	data.damage = int(values.get("damage", 10))
	data.fire_rate = float(values.get("fire_rate", 0.2))
	data.magazine_size = int(values.get("magazine_size", 10))
	data.ammo_in_magazine = int(values.get("ammo_in_magazine", data.magazine_size))
	data.reserve_ammo = int(values.get("reserve_ammo", 0))
	data.reload_time = float(values.get("reload_time", 1.0))
	data.bullet_speed = float(values.get("bullet_speed", 450.0))
	data.spread = float(values.get("spread", 0.0))
	data.recoil = float(values.get("recoil", 0.0))
	data.automatic = bool(values.get("automatic", false))
	data.pellets = int(values.get("pellets", 1))
	data.projectile_type = str(values.get("projectile_type", "bullet"))
	data.muzzle_flash_type = str(values.get("muzzle_flash_type", "muzzle"))
	return data
