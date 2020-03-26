FROM nvidia/cuda:9.0-devel-ubuntu16.04
# Based on default horovod image

# TensorFlow version is tightly coupled to CUDA and cuDNN so it should be selected carefully
ENV TENSORFLOW_VERSION=1.12.0
ENV CUDNN_VERSION=7.4.1.5-1+cuda9.0
ENV NCCL_VERSION=2.3.5-2+cuda9.0

# Python 2.7 or 3.5 is supported by Ubuntu Xenial out of the box
ARG python=3.5
ENV PYTHON_VERSION=${python}

RUN echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update && apt-get install -y --no-install-recommends --allow-downgrades --allow-change-held-packages \
        build-essential \
        cmake \
        git \
        curl \
        vim \
        wget \
        ca-certificates \
        libcudnn7=${CUDNN_VERSION} \
        libnccl2=${NCCL_VERSION} \
        libnccl-dev=${NCCL_VERSION} \
        libjpeg-dev \
        libpng-dev \
        net-tools \
        libsm6 \
        libxext6 \
        python$PYTHON_VERSION \
        python$PYTHON_VERSION-dev \
        # Infiniband/RDMA
        cpio \
        libmlx4-1 \
        libmlx5-1 \
        librdmacm1 \
        libibverbs1 \
        libmthca1 \
        libdapl2 \
		dapl2-utils \
        ibverbs-utils\
        ibutils


# install intel MPI
RUN cd /tmp && \
    wget -q 'http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/11595/l_mpi_2017.3.196.tgz' && \
    tar zxvf l_mpi_2017.3.196.tgz && \
    sed -i -e 's/^ACCEPT_EULA=decline/ACCEPT_EULA=accept/g' /tmp/l_mpi_2017.3.196/silent.cfg && \
    sed -i -e 's|^#ACTIVATION_LICENSE_FILE=|ACTIVATION_LICENSE_FILE=/tmp/l_mpi_2017.3.196/USE_SERVER.lic|g' \
    			/tmp/l_mpi_2017.3.196/silent.cfg && \
    sed -i -e 's/^ACTIVATION_TYPE=exist_lic/ACTIVATION_TYPE=license_server/g' /tmp/l_mpi_2017.3.196/silent.cfg && \
    cd /tmp/l_mpi_2017.3.196 && \
    ./install.sh -s silent.cfg && \
    cd .. && \
    rm -rf l_mpi_2017.3.196* && \
    echo "source /opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpivars.sh" >> ~/.bashrc

ENV PATH $PATH:/opt/intel/compilers_and_libraries/linux/mpi/bin64

RUN ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

# Install TensorFlow
RUN pip install tensorflow-gpu==${TENSORFLOW_VERSION} h5py


# Install Dependencies
RUN pip install --no-cache-dir h5py scipy jupyter ipykernel numpy toolz pandas \
 	scikit-learn pillow

# Install Horovod, temporarily using CUDA stubs
RUN ldconfig /usr/local/cuda-9.0/targets/x86_64-linux/lib/stubs && \
	/bin/bash -c "source /opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpivars.sh" && \
    HOROVOD_WITH_TENSORFLOW=1 pip install --no-cache-dir horovod==0.15.2 && \
    ldconfig


# Set default NCCL parameters
RUN echo NCCL_DEBUG=INFO >> /etc/nccl.conf && \
    echo NCCL_SOCKET_IFNAME=^docker0 >> /etc/nccl.conf

# Download benchmarks
RUN git clone https://github.com/tensorflow/benchmarks && \
	cd benchmarks && \
	git checkout 091ef1e4d8832e14d1f874e66bff78a2522d0947

WORKDIR "/benchmarks"
