FROM dustynv/ros:humble-desktop-pytorch-l4t-r35.4.1 as base
LABEL maintainer="Raymond Song <raymond.song98@gmail.com>"
SHELL ["/bin/bash", "-o", "pipefail", "-ic"]

ARG APT_FILE
ARG PIP_FILE
ARG PIP_GPU_FILE
ARG CUSTOM_INSTALL_FILE

COPY ${APT_FILE} /tmp/${APT_FILE}

RUN apt update && DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends \
        $(cat /tmp/${APT_FILE} | cut -d# -f1) && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/${APT_FILE}

## Add GitHub to known hosts for private repositories
RUN mkdir -p ~/.ssh \
  && ssh-keyscan github.com >> ~/.ssh/known_hosts \
  && ssh-keyscan gitlab.com >> ~/.ssh/known_hosts

RUN export C_INCLUDE_PATH=/usr/lib/openmpi/include

RUN python3 -m pip install --upgrade pip

COPY ${PIP_FILE} /tmp/${PIP_FILE}
RUN DEBIAN_FRONTEND=noninteractive pip3 install -U --no-cache --ignore-installed -r /tmp/${PIP_FILE} && \
    rm -rf /tmp/${PIP_FILE}

COPY ${PIP_GPU_FILE} /tmp/${PIP_GPU_FILE}
RUN DEBIAN_FRONTEND=noninteractive pip3 install -U --no-cache --ignore-installed -r /tmp/${PIP_GPU_FILE} && \
    rm -rf /tmp/${PIP_GPU_FILE}

RUN rm -rf /tmp

FROM base as base_custom

COPY ${CUSTOM_INSTALL_FILE} /tmp/${CUSTOM_INSTALL_FILE}
RUN --mount=type=ssh \
    DEBIAN_FRONTEND=noninteractive /bin/sh /tmp/${CUSTOM_INSTALL_FILE} && \
    rm -rf /tmp/${CUSTOM_INSTALL_FILE}

RUN mkdir /auto_tmp && chmod 1777 /tmp && apt-get update && cd /auto_tmp && \
    sudo apt update && apt install apt-transport-https -y && \
    git clone https://github.com/autowarefoundation/autoware.git && \
    cd autoware && apt-get install -y ccache git-lfs && \
    pip3 install pre-commit gdown clang-format==17.0.5 && \
    apt-get install -y golang && \
    git lfs install && \
    sudo geographiclib-get-geoids egm2008-1 && \
    sudo apt update && \
    sudo apt install -y \
	  python3-colcon-mixin \
	  python3-flake8-docstrings \
	  python3-pip \
	  python3-pytest-cov \
	  ros-dev-tools 

FROM base_custom as autoware_tai

RUN --mount=type=ssh \
    source /opt/ros/humble/install/setup.bash && \
    apt update && \
    rosdep update --include-eol-distros && \
    cd /auto_tmp/autoware && mkdir src && \
    vcs import src < autoware.repos && \
    DEBIAN_FRONTEND=noninteractive rosdep install -r -y --ignore-src --rosdistro humble --from-paths src --skip-keys libopencv-dev && \
    rm -rf /auto_tmp

ARG EXPORTS_SCRIPT
ARG EXPORTS_GPU_SCRIPT

COPY ${EXPORTS_SCRIPT} /auto_tmp/${EXPORTS_SCRIPT}
RUN  cd /auto_tmp && \
    ./${EXPORTS_SCRIPT} && \
    rm -rf /auto_tmp/

COPY cyclonedds.xml /etc/cyclone/cyclonedds.xml


CMD ["/bin/bash"]
