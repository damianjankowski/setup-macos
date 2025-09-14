SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help
help:  ## Show help
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?##"} \
	/^##@/ {print "\n" substr($$0, 5)} \
	/^[a-zA-Z0-9_-]+:.*?##/ {printf "  %-15s - %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: run
run:  ## Run setup script
	@chmod +x setup.sh
	@./setup.sh