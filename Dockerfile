# Base image
FROM osrf/ros:kinetic-desktop-full

MAINTAINER Finn Rietz <finn.rietz@uni-hamburg.de>

# some utils
RUN apt-get update
RUN apt-get install -y \
	vim \
	wget \
	xz-utils \
	module-init-tools \
	mesa-utils \
	binutils

# pepper ros packages
RUN apt-get install -y \
	ros-kinetic-pepper-robot \
	ros-kinetic-pepper-moveit-config
	

# install pepper meshes. We have to pipe this into 'yes' to agree to the license. otherwise docker build get's stuck on this step...
# we also have these debian environment params, otherwise the yes still gets stuck on the prompt in the mesh installation
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_FRONTEND teletype
RUN yes | apt-get install ros-kinetic-pepper-meshes

# get pepper naoqi python api (not required, but nice to have if one wants to quickly do API things in the container)
RUN wget https://community-static.aldebaran.com/resources/2.5.10/Python%20SDK/pynaoqi-python2.7-2.5.7.1-linux64.tar.gz
RUN tar -xf pynaoqi-python2.7-2.5.7.1-linux64.tar.gz
RUN rm pynaoqi-python2.7-2.5.7.1-linux64.tar.gz
RUN echo 'export PYTHONPATH=$PYTHONPATH:/pynaoqi-python2.7-2.5.7.1-linux64/lib/python2.7/site-packages/' >> /ros_entrypoint.sh

# get ira laser merge for pepper's three individual laser
RUN mkdir -p /catkin_ws/src
RUN cd /catkin_ws/src && \ 
	git clone https://github.com/iralabdisco/ira_laser_tools.git
	
# add launchfile for laser merger for pepper 
ADD ira_laser_merger_pepper_params.launch /catkin_ws/src/ira_laser_tools/launch

# build the catkin_ws inside the container
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash && cd /catkin_ws && catkin_make'


# add my main launch file
ADD pepper_main.launch /pepper.launch


RUN echo 'source /ros_entrypoint.sh' >>  /root/.bashrc
RUN echo 'source /catkin_ws/devel/setup.bash' >> /root/.bashrc
