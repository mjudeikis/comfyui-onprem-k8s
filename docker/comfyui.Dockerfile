#FROM nvidia/cuda:12.1.0-runtime-ubuntu20.04
FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu22.04
ENV TZ=Lithuania/Vilnius
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /home/workspace

# python
RUN apt-get update 
RUN apt-get install -y build-essential curl python3-pip vim htop tmux


# torch and xformers
RUN pip install torch==2.9.0 torchvision==0.24.0 torchaudio==2.9.0 --index-url https://download.pytorch.org/whl/cu126 

ARG COMFYUI_VERSION
ARG COMFYUI_MANAGER_VERSION

RUN apt install -y git
# clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git \
    && cd ComfyUI \
    && git checkout ${COMFYUI_VERSION}
RUN cd ComfyUI/custom_nodes \
    && git clone https://github.com/ltdrdata/ComfyUI-Manager.git \
    && cd ComfyUI-Manager \
    && git checkout ${COMFYUI_MANAGER_VERSION}

# install dependencies
RUN pip install -r ComfyUI/requirements.txt

# RUN
ENV PYTHON=python3
ENV COMFYUI_PATH=/home/workspace/ComfyUI
ENV PATH="$PATH:$COMFYUI_PATH"
WORKDIR $COMFYUI_PATH
CMD ["/bin/bash", "-c", "$PYTHON main.py --listen 0.0.0.0 --port 50000"]
