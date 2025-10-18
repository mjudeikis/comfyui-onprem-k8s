MODEL_PATH ?= $(HOME)/models

COMFYUI_VERSION ?= v0.3.14
COMFYUI_MANAGER_VERSION ?= 3.23

IMAGE_REGISTRY ?= ghcr.io
IMAGE_REPO ?= mjudeikis/comfyui-onprem-k8s


# Cluster
cluster:
	@[ -d "$(MODEL_PATH)" ] || { echo "Please set MODEL_PATH"; exit 1; }
	# Create kind cluster with GPU support and bind mount for models
	kind create cluster --name comfyui --config - <<EOF
	kind: Cluster
	apiVersion: kind.x-k8s.io/v1alpha4
	nodes:
	- role: control-plane
	  extraMounts:
	  - hostPath: $(MODEL_PATH)
	    containerPath: /models
	  extraPortMappings:
	  - containerPort: 30000
	    hostPort: 30000
	    protocol: TCP
	EOF
	# Install NVIDIA GPU operator for GPU support in kind
	kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.4/nvidia-device-plugin.yml || true

cluster-removal:
	kind delete cluster --name comfyui


# Docker - Plain ComfyUI
docker-build:
	docker build -t $(IMAGE_REGISTRY)/$(IMAGE_REPO):comfyui-$(COMFYUI_VERSION) \
		--build-arg COMFYUI_VERSION=$(COMFYUI_VERSION) \
		--build-arg COMFYUI_MANAGER_VERSION=$(COMFYUI_MANAGER_VERSION) \
		-f docker/comfyui.Dockerfile .

docker-push:
	docker push $(IMAGE_REGISTRY)/$(IMAGE_REPO):comfyui-$(COMFYUI_VERSION)

docker-run:
	docker run -it --gpus all -p 50000:50000 \
		-v $(HOME)/models:/home/workspace/ComfyUI/models \
		$(IMAGE_REGISTRY)/$(IMAGE_REPO):comfyui-$(COMFYUI_VERSION)


# Docker - Jupyter ComfyUI
docker-build-jupyter:
	docker build -t $(IMAGE_REGISTRY)/$(IMAGE_REPO):comfyui-jupyter-$(COMFYUI_VERSION) \
		--build-arg BASE_IMAGE=$(IMAGE_REGISTRY)/$(IMAGE_REPO):comfyui-$(COMFYUI_VERSION) \
		-f docker/comfyui-jupyter.Dockerfile .

docker-push-jupyter:
	docker push $(IMAGE_REGISTRY)/$(IMAGE_REPO):comfyui-jupyter-$(COMFYUI_VERSION)

docker-run-jupyter:
	docker run -it --gpus all -p 8888:8888 \
		-v $(HOME)/models:/home/workspace/ComfyUI/models \
		$(IMAGE_REGISTRY)/$(IMAGE_REPO):comfyui-jupyter-$(COMFYUI_VERSION)


# Utils
tunnel:
	@echo "kind doesn't require tunneling - services are accessible via localhost"
	@echo "Use port-forward for specific services: kubectl port-forward svc/<service-name> <local-port>:<service-port>"
