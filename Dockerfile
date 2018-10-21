# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

#https://hub.docker.com/r/nvidia/cuda/tags/
#https://hub.docker.com/r/nvidia/cuda/
#FROM nvidia/cuda:9.0-base-ubuntu16.04
FROM nvidia/cuda:9.2-cudnn7-runtime-ubuntu16.04

LABEL maintainer="Jupyter Scipybase"

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    build-essential \
   # cuda-command-line-tools-9-0 \
   # cuda-cublas-9-0 \
   # cuda-cufft-9-0 \
   # cuda-curand-9-0 \
   # cuda-cusolver-9-0 \
   # cuda-cusparse-9-0 \
    curl \
   # libcudnn7=7.1.4.18-1+cuda9.0 \
    libfreetype6-dev \
    libhdf5-serial-dev \
    libpng12-dev \
    libzmq3-dev \
    iputils-ping \
    net-tools \
    dh-autoreconf \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    libncurses5-dev \
    vim \
    git \
    jed \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    netcat \
    pandoc \
    python-dev \
    unzip \
    nano \
    openssh-server \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.18.0/tini && \
    echo "12d20136605531b09a2c2dac02ccee85e1b874eb322ef6baf7561cd93f93c855 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home

USER root

RUN mkdir -p $CONDA_DIR && \ 
# Setup work directory for backward-compatibility
    mkdir /home/work 

# Install conda and check the md5 sum provided on the download site
ENV MINICONDA_VERSION 4.5.4
RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "a946ea1d0c4a642ddf0c3a26a18bb16d *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda install --quiet --yes conda="${MINICONDA_VERSION%.*}.*" && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy && \
    rm -rf /home/.cache/yarn 

# Install Jupyter Notebook and Hub
#RUN conda install --quiet --yes \
RUN conda install --yes \
    'notebook=5.6.*' \
    'jupyterhub=0.9.*' \
    'jupyterlab=0.34.*' && \
    conda clean -tipsy && \
    jupyter labextension install @jupyterlab/hub-extension@^0.11.0 && \
    npm cache clean --force && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/.cache/yarn 

USER root

#EXPOSE 8888
WORKDIR $HOME/work

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
#CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
RUN wget -P /usr/local/bin/  https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start.sh && \
    wget -P /usr/local/bin/  https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start-notebook.sh && \
    wget -P /usr/local/bin/  https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start-singleuser.sh && \
    wget -P /etc/jupyter/    https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/jupyter_notebook_config.py


#RUN wget -P /usr/local/bin/ https://raw.githubusercontent.com/Winowang/jupyter_images/master/run_jupyter.sh && \
#    wget -P /etc/jupyter/ https://raw.githubusercontent.com/Winowang/jupyter_images/master/jupyter_notebook_config.py 
 
#COPY start.sh /usr/local/bin/
#COPY start-notebook.sh /usr/local/bin/
#COPY start-singleuser.sh /usr/local/bin/
#COPY jupyter_notebook_config.py /etc/jupyter/


# ffmpeg for matplotlib anim
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    apt-get install -y --no-install-recommends libssl-dev && \
    #apt-get install -y --no-install-recommends libssl1.0-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#RUN conda install --quiet --yes \
RUN conda install --yes \
    'conda-forge::blas=*=openblas' \
    'ipywidgets=7.2*' \
   # 'pandas=0.23*' \
   # 'numexpr=2.6*' \
   # 'matplotlib=2.2*' \
    'scipy=1.1*' \
   # 'seaborn=0.8*' \
   # 'sympy=1.1*' \
   # 'cython=0.28*' \
   # 'patsy=0.5*' \
   # 'statsmodels=0.9*' \
   # 'dill=0.2*' \
    'numba=0.38*' &&\
   # 'bokeh=0.12*' \
   # 'sqlalchemy=1.2*' \
   # 'hdf5=1.10*' \
   # 'h5py=2.7*' \
   # 'xlrd'  && \
   # conda remove --quiet --yes --force qt pyqt && \
    conda clean -tipsy && \
    # Activate ipywidgets extension in the environment that runs the notebook server
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    # Also activate ipywidgets extension for JupyterLab
    jupyter labextension install @jupyter-widgets/jupyterlab-manager@^0.37.0 && \
    #jupyter labextension install jupyterlab_bokeh@^0.6.0 && \
    jupyter labextension install jupyterlab_bokeh@0.6.2 && \

    
    npm cache clean --force && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/.cache/yarn && \
    rm -rf /home/.node-gyp 


# Install shellinabox
#RUN  git clone https://github.com/shellinabox/shellinabox.git \
#     cd shellinabox \
#     autoreconf -i \
#     ./configure && make
     
# Install facets which does not have a pip or conda package at the moment
#RUN cd /tmp && \
#    git clone https://github.com/PAIR-code/facets.git && \
#    cd facets && \
#    jupyter nbextension install facets-dist/ --sys-prefix && \
#    cd && \
#    rm -rf /tmp/facets 

# Import matplotlib the first time to build the font cache.
#ENV XDG_CACHE_HOME /home/.cache/
#RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" 

CMD ["sudo /etc/init.d/ssh start"]
