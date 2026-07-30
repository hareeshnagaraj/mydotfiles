SHELL := /bin/bash

.PHONY: install sync scan hook sync-install sync-uninstall githooks githooks-sweep-install

install:            ## symlink dotfiles into ~ (backs up existing)
	./scripts/install.sh

sync:               ## pull current configs off this box into the repo (scrubbed), stage them
	./scripts/sync.sh

scan:               ## hard secret-scan every tracked + dotfile (the commit gate)
	./scripts/scrub.sh scan $$(git ls-files) dotfiles/* dotfiles/config-tmux/* dotfiles/ghostty/config dotfiles/ghostty/themes/*

hook:               ## install the pre-commit secret-scan hook
	ln -sf ../../scripts/pre-commit .git/hooks/pre-commit && chmod +x scripts/pre-commit && echo "pre-commit hook installed"

sync-install:       ## load the weekly launchd agent that runs `make sync` (never pushes)
	./launchd/install.sh

sync-uninstall:     ## unload the weekly launchd agent
	./launchd/uninstall.sh

githooks:           ## install global git hooks (AI-attribution guard, warn mode)
	./githooks/install.sh

githooks-sweep-install: ## load the weekly attribution drift sweep (read-only)
	./launchd/install-attribution-sweep.sh
