SHELL := /bin/bash

.DEFAULT_GOAL := help

# General
# -----------------------------------------------------------------------------
##@ General

.PHONY: help
help:  ## Show this help message
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?##"} \
	/^##@/ {print "\n" substr($$0, 5)} \
	/^[a-zA-Z0-9_-]+:.*?##/ {printf "  make %-20s - %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: run
run:  ## Run script
	chmod +x setup.sh
	./setup.sh