extends StaticBody3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var voxelMeshInstance := $MeshInstance3D

	# Créer un CollisionShape3D pour le voxel
	var collisionShape := CollisionShape3D.new()

	# Générer une forme de collision convexe à partir du MeshInstance3D
	collisionShape.make_convex_from_brothers(voxelMeshInstance)

	# Attacher le CollisionShape3D à votre voxelMeshInstance
	voxelMeshInstance.add_child(collisionShape)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
