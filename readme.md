
# DSC 190 Autoware Source Installation
## with Eagleye, ROS2 Humble on 1/5th Car, with F1Tenth Trajectory Record/Replay

Our humble Autoware installation is currently located in `autoware190/autoware`. Using this [container registry](https://github.com/Triton-AI/autoware_docker/blob/master/run.sh).

This [diagram](https://app.diagrams.net/?lightbox=1#Uhttps%3A%2F%2Fautowarefoundation.github.io%2Fautoware-documentation%2Fpr-347%2Fdesign%2Fautoware-architecture%2Fnode-diagram%2Foverall-node-diagram-autoware-universe.drawio.svg#%7B%22pageId%22%3A%22T6t2FfeAp1iw48vGkmOz%22%7D) depicts the Autoware Stack.

## Prerequisites
- Ubuntu 22.04
- ROS2 Humble
- Git

## Docker Container Registry / Setup

Reference: [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

Refer to these [docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) for working with the container registry.
1. [Create an access key](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic) for your GitHub account.
2. Save your token on the Jetson: `export CR_PAT=YOUR_TOKEN`
3. Sign in using the [ghcr.io](http://ghcr.io/) registry service: `echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin`
4. Pull the TritonAI package using the command: `docker pull ghcr.io/triton-ai/autoware:humble`
5. Add the `run.sh` file to the Jetson and edit it to include a volume for Autoware and update the image name (last line). It’ll look something like this:

```sh
docker run \
    --runtime nvidia \
    --name test \
    -it \
    --rm \
    --privileged \
    --net=host \
    -e DISPLAY=$DISPLAY \
    -v /dev/bus/usb:/dev/bus/usb \
    --device-cgroup-rule='c 189:* rmw' \
    --volume='/dev/input:/dev/input' \
    --volume='/home/jetson/.Xauthority:/root/.Xauthority:rw' \
    --volume='/tmp/.X11-unix/:/tmp/.X11-unix' \
    --volume='/home/jetson/autoware190/:/root/autoware190/' \
    ghcr.io/triton-ai/autoware:humble
```
6. Run docker container: `sh run.sh`

## Development Environment Setup

1. Clone Autoware:
    ```sh
    git clone https://github.com/autowarefoundation/autoware.git
    ```
2. Install dependencies using setup script:
    ```sh
    cd autoware
    ./setup-dev-env.sh
    ```

## Autoware Workspace

1. Create `src` directory:
    ```sh
    cd autoware
    mkdir src
    ```
2. Import VCS dependencies from `autoware.repos` into new `src`:
    ```sh
    vcs import src < autoware.repos
    ```
3. Create a new repos file for additional missing dependencies using vim or a text editor of your choice:
    ```sh
    vim autoware190.repos
    ```

The latest file update will be at the bottom of this doc. The file structure should follow this:

```yaml
repositories:
  # autoware190
  autoware190/mrt_cmake_modules:
    type: git
    url: https://github.com/KIT-MRT/mrt_cmake_modules.git
    version: 1.0.9
```

4. Build workspace and handle errors:
    ```sh
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-w"
    ```

Include `--continue-on-error` and `--packages-select`/`--packages-up-to` if needed.

You’ll likely encounter various missing dependency errors. For each missing package, retrieve the package URI and version from [index.ros](https://index.ros.org/p/mrt_cmake_modules/github-KIT-MRT-mrt_cmake_modules/). Add the package to `autoware190.repos` with the correct URL and version retrieved from `index.ros`. Run `vcs import src < autoware190.repos` to install the additional repos. This will be an iterative process.

## GPS (PointOneNav)

GPS Installation: [PointOneNav Fusion Engine Client](https://github.com/PointOneNav/fusion-engine-client)

## Camera/IMU (DepthAI)

[Manual DepthAI Installation](https://docs.luxonis.com/software/depthai/manual-install/#Manual%20DepthAI%20installation-Installing%20dependencies-Ubuntu%2FDebian)

## F1Tenth Installation

1. Clone the F1Tenth branch into the Jetson (outside of the Autoware directory):
    ```sh
    git clone https://github.com/autowarefoundation/autoware.universe.git
    ```
2. Move the F1Tenth stack into `autoware/src`:
    ```sh
    mv f1tenth/autoware.universe/f1tenth/ autoware/src/universe/autoware.universe/
    ```
3. Install the required packages:
    ```sh
    colcon build --packages-up-to trajectory_follower_node
    colcon build --packages-up-to launch_autoware_f1tenth
    colcon build --packages-up-to f1tenth_stack
    colcon build --packages-select recordreplay_planner
    colcon build --packages-select recordreplay_planner_nodes
    ```

## Potential Pitfalls

### CMake Changes

Add this to the Eagleye util GNSS converter CMake file if you run into issues with ublox (or other packages):

```cmake
include_directories(
    Include
    ${ublox_msgs_INCLUDE_DIRS}
)
```

### Joystick Troubleshooting

Install `jstest-gtk` for troubleshooting joystick issues: [jstest-gtk](https://github.com/Grumbel/jstest-gtk)

```sh
ros2 launch joy_teleop example.launch.py 
```

### Linux Dependencies
Various Linux system packages may be missing after initializing the container. Reference ROS Humble Index when installing these packages.

Some system packages required for Autoware may be missing from ROS Humble entirely. Ignore Autoware packages reliant on these system packages.

By default, many packages will error out during the build process due to various `-werror` warning flags. You may need to suppress these `-werror` warnings.

## Launch Commands

### GPS

```sh
ros2 launch ntrip_client ntrip_client_launch.py host:=polaris.pointonenav.com port:=2101 mountpoint:=POLARIS username:=<username> password:=<password>
```

### Camera (and IMU)

```sh
ros2 launch depthai_ros_driver camera.launch.py
```

### Eagleye

```sh
ros2 launch eagleye_rt eagleye_rt.launch.xml
```

Note: eagleye_rt config will need to be updated with the right topics.
- imu: `/oak/imu/data`
- gps: `/nmea` or `/rtcm`

### Car

```sh
ros2 launch launch_autoware_f1tenth realcar_launch.py
```

### Record trajectory

```sh
ros2 action send_goal /planning/recordtrajectory autoware_auto_planning_msgs/action/RecordTrajectory "{record_path: "/tmp/path"}" --feedback
```

### Replay trajectory

```sh
ros2 action send_goal /planning/replaytrajectory autoware_auto_planning_msgs/action/ReplayTrajectory "{replay_path: "/tmp/path"}" --feedback
```

## AV4EV Simulation

Given how the simulation is tailored to UPenn AV4EV GoKart, the simulation is not in a great state to be integrated with our ART Stack. Still, we may want to investigate the use of [SodaSim](https://github.com/soda-auto/soda-sim)/Unreal Engine for future simulations. SodaSim provides a good foundation for vehicle simulation.

The AV4EV Sim can be downloaded [here](https://drive.google.com/file/d/1goxswioa2MntthHZ-5inmKRmKjOJss0m/view?usp=drive_link). The installation process is available [here](https://docs.google.com/document/d/1_H5eWenuQquDp7uDdd6iuoHd1Gemtf0hW57mue3JtLY/edit?usp=drive_link).

## autoware190.repos Example File

The `autoware190.repos` file should appear similar to [this file](https://drive.google.com/file/d/1gT6nYcsPcxmyS2z-svs-h3dhBJfApT7S/view?usp=sharing).

