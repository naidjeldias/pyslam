FROM nvcr.io/nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04 AS base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    # Basic Utilities 
    && apt-get install -y --no-install-recommends \
        curl wget ca-certificates software-properties-common \
    # Additional development tools
    && apt-get install -y --no-install-recommends \
        cmake build-essential git pkg-config libatlas-base-dev \
        libboost-all-dev gfortran \
    # pyslam stuff 
    && apt-get install -y --no-install-recommends \
        rsync python3-sdl2 python3-tk libhdf5-dev \
        libprotobuf-dev libeigen3-dev libopencv-dev libsuitesparse-dev libglew-dev \
    # viz
    && apt-get install -y --no-install-recommends \
        libqt5core5a libqt5dbus5 libqt5gui5 \
    # pyenv stuff
    && apt-get install -y --no-install-recommends \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
        libsqlite3-dev libffi-dev liblzma-dev tk-dev \
    && rm -rf /var/lib/apt/lists/*

# Update python version
# Python 
RUN  add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.11 python3.11-venv python3.11-dev \
        python3.11-distutils python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2\
    && ln -s /usr/bin/python3 /usr/bin/python 

FROM base AS final

ENV DEBIAN_FRONTEND=noninteractive
ENV PYENV_ROOT=/root/.pyenv
ENV PATH=$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH


# install pyenv and pyenv-virtualenv
RUN git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT \
 && git clone https://github.com/pyenv/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv \
 && mkdir -p $PYENV_ROOT/versions $PYENV_ROOT/cache

# create a virtualenv from the system Python and make it the global pyenv version
# You can override the venv name at build time with --build-arg PYENV_VENV_NAME=myenv
ARG PYENV_VENV_NAME=env-system
RUN export PYENV_ROOT=$PYENV_ROOT && export PATH=$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH && \
    eval "$(pyenv init -)" && eval "$(pyenv virtualenv-init -)" && \
    # create virtualenv from system python if it doesn't exist
    if ! pyenv versions --bare | grep -qx "$PYENV_VENV_NAME"; then \
      pyenv virtualenv system "$PYENV_VENV_NAME"; \
    fi && \
    pyenv global "$PYENV_VENV_NAME" && \
    python --version && pip --version

COPY . /pyslam
# the following to inform we are inside docker at build time 
RUN touch /.dockerenv 

WORKDIR /pyslam
RUN pip install -r requirements.txt
RUN cd cpp && ./build.sh && cd ..
RUN cd scripts && ./install_thirdparty.sh && cd ..

# Add entrypoint (will init pyenv & activate venv at runtime)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]