IMAGE_NAME := config-manager:test
BINARY_NAME := config-manager

.PHONY: all build-image build-go install clean

all: install

build-image:
	@if [ -z "$$(docker images -q $(IMAGE_NAME))" ]; then \
		echo "Image $(IMAGE_NAME) not found. Building..."; \
		docker build -t $(IMAGE_NAME) .; \
	else \
		echo "Image $(IMAGE_NAME) already exists. Skipping build."; \
	fi

build-go:
	@echo "Building Go binary for Linux..."
	GOOS=linux GOARCH=amd64 go build -o $(BINARY_NAME) .

install: build-image build-go
	@echo "Running './$(BINARY_NAME) install' inside $(IMAGE_NAME)..."
	docker run --rm -v $(shell pwd):/app -w /app $(IMAGE_NAME) sudo ./$(BINARY_NAME) install

clean:
	docker image rm $(IMAGE_NAME) 2>/dev/null || true
	rm -f $(BINARY_NAME)
