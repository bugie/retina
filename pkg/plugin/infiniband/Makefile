REPO_ROOT = $(shell git rev-parse --show-toplevel)
MOCKGEN = go tool go.uber.org/mock/mockgen

.PHONY: generate

generate: ## Generate mock clients
	$(MOCKGEN) -source=$(REPO_ROOT)/pkg/plugin/infiniband/types_linux.go -copyright_file=$(REPO_ROOT)/pkg/lib/ignore_headers.txt -package=infiniband > infiniband_mock_generated.go
