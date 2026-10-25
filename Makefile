IMAGE_NAME := config-manager:test

.PHONY: all build-image install clean

all: install

build-image:
	@if [ -z "$$(docker images -q $(IMAGE_NAME))" ]; then \
		echo "Image $(IMAGE_NAME) not found. Building..."; \
		docker build -t $(IMAGE_NAME) .; \
	else \
		echo "Image $(IMAGE_NAME) already exists. Skipping build."; \
	fi

install: build-image
	@echo "Running './config-manager.sh install' inside $(IMAGE_NAME)..."
	docker run --rm -v $(shell pwd):/app -w /app $(IMAGE_NAME) sudo CONFIG_MANAGER_DIR=/app ./config-manager.sh install -ignore desktop

clean:
	docker image rm $(IMAGE_NAME) 2>/dev/null || true
