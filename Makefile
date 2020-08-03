.PHONY: actions
.PHONY: actions-clean
actions-clean:
	rm -f ./.github/workflows/*.yml

.PHONY: actions
actions: actions-clean
	@ ./scripts/jsonnet.sh ./.github/workflows/workflows.jsonnet