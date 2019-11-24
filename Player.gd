extends KinematicBody

const GRAVITY = -47
var vel = Vector3()
const MAX_SPEED = 20
const WALK_SPEED = 10
const JUMP_SPEED = 18
const ACCEL = 4.5

var dir = Vector3()

const DEACCEL = 06
const MAX_SLOPE_ANGLE = 40

var camera
var rot_helper

var MOUSE_SENSITIVITY = 0.05

var grabbed_object = null
const OBJECT_THROW_FORCE = 10
const OBJECT_GRAB_DISTANCE = 4
const OBJECT_GRAB_RAY_DISTANCE = 4

func _ready():
    camera = $Rotation_Helper/Camera
    rot_helper = $Rotation_Helper

    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    process_input()
    process_movement(delta)

func process_input():
    # Walking
    dir = Vector3()
    var cam_xform = camera.get_global_transform()

    var input_movement_vector = Vector2()

    if Input.is_action_pressed("movement_forward"):
        input_movement_vector.y += 1
    if Input.is_action_pressed("movement_backward"):
        input_movement_vector.y -= 1
    if Input.is_action_pressed("movement_left"):
        input_movement_vector.x += 1
    if Input.is_action_pressed("movement_right"):
        input_movement_vector.x -= 1

    input_movement_vector = input_movement_vector.normalized()

    dir += -cam_xform.basis.z * input_movement_vector.y
    dir += -cam_xform.basis.x * input_movement_vector.x

    # Jumping
    if is_on_floor():
        if Input.is_action_just_pressed("movement_jump"):
            vel.y = JUMP_SPEED

    # Capturing/Freeing
    if Input.is_action_just_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    # Interact with Objects
    if Input.is_action_just_pressed("interact_object"):
        if grabbed_object == null:
            var state = get_world().direct_space_state

            var center_position = get_viewport().size / 2
            var ray_from = camera.project_ray_origin(center_position)
            var ray_to =  ray_from + camera.project_ray_normal(center_position) * OBJECT_GRAB_RAY_DISTANCE

            var ray_result = state.intersect_ray(ray_from, ray_to, [self, $Rotation_Helper])
            if ray_result != null:
                # Prevents crash on ray hitting nothing
                if "collider" in ray_result.keys():
                    if ray_result["collider"] is RigidBody:
                        grabbed_object = ray_result["collider"]
                        grabbed_object.mode = RigidBody.MODE_KINEMATIC
                        # grabbed_object.collision_layer = 0
                        # grabbed_object.collision_mask = 0
        else:
            grabbed_object.mode = RigidBody.MODE_RIGID
            grabbed_object.apply_impulse(Vector3(0, 0, 0), -camera.global_transform.basis.z.normalized() * OBJECT_THROW_FORCE)
            # grabbed_object.collision_layer = 1
            # grabbed_object.collision_mask = 1
            grabbed_object = null

    if grabbed_object != null:
        # TODO: Fix this shitty move function
        grabbed_object.global_transform.origin = camera.global_transform.origin + (-camera.global_transform.basis.z.normalized() * OBJECT_GRAB_DISTANCE)

func process_movement(delta):
    dir.y = 0
    dir = dir.normalized()

    vel.y += delta * GRAVITY

    var hvel = vel
    hvel.y = 0

    var target = dir
    if Input.is_action_pressed("movement_sprint"):
        target *= MAX_SPEED
    else:
        target *= WALK_SPEED

    var accel
    if dir.dot(hvel) > 0:
        accel = ACCEL
    else:
        accel = DEACCEL

    hvel = hvel.linear_interpolate(target, accel * delta)
    vel.x = hvel.x
    vel.z = hvel.z
    vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

func _input(event):
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rot_helper.rotate_x(-deg2rad(event.relative.y * MOUSE_SENSITIVITY))
        self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

        var camera_rot = rot_helper.rotation_degrees
        camera_rot.x = clamp(camera_rot.x, -70, 70)
        rot_helper.rotation_degrees = camera_rot
