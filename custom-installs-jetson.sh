#!/bin/sh
apt update

# install pcl
git clone --recurse-submodules -b pcl-1.12.1 https://github.com/PointCloudLibrary/pcl.git
cd pcl && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j2
sudo make -j2 install
cd ../..
rm -rf pcl

# Install Cmake
wget https://github.com/Kitware/CMake/archive/refs/tags/v3.22.1.zip
unzip v3.22.1.zip
cd CMake-3.22.1/
sudo ./bootstrap --prefix=/opt/cmake-install
sudo make
sudo make install
echo -e '\nexport PATH="/opt/cmake-install/bin:${PATH}"' >> ~/.bashrc
echo 'export CMAKE_PREFIX_PATH="/opt/cmake-install:${CMAKE_PREFIX_PATH}"' >> ~/.bashrc
source ~/.bashrc
cd /opt
rm -rf CMake-3.22.1
rm -rf v3.22.1.zip

# Install range-v3
# git clone git@github.com:raymondsong00/range-v3.git
# cd range-v3 && mkdir build && cd build
# cmake -DCMAKE_BUILD_TYPE=Release ..
#make -j4
# sudo make -j4 install
# cd ../..
# rm -rf range-v3

wget -qO- https://raw.githubusercontent.com/luxonis/depthai-ros/main/install_dependencies.sh | sudo bash

cd /tmp
git clone https://github.com/Livox-SDK/Livox-SDK2.git
cd ./Livox-SDK2/
mkdir build && cd build
cmake .. && make -j4
sudo make install
cd /tmp
rm -rf Livox-SDK2
