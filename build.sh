DOCKER_BUILDKIT=1 docker build \
		--network=host \
		-f Dockerfile \
		--target autoware_tai \
		--build-arg APT_FILE=apt-packages-jetson \
		--build-arg PIP_FILE=pip3-packages-jetson \
		--build-arg PIP_GPU_FILE=pip3-packages-jetson-gpu \
		--build-arg EXPORTS_SCRIPT=exports-jetson.sh \
		--build-arg CUSTOM_INSTALL_FILE=custom-installs-jetson.sh \
		-t autoware_jp5 . 
