# shellcheck shell=bash
# Step 6: deploy the dotfiles in home/ with the repo's own tool.

step_configs() {
	local tool=$REPO/bin/dotfiles
	local -a args=(deploy --yes)
	if [[ ! -x $tool ]]; then
		warn "$tool not found; skipping config deployment"
		return 0
	fi
	if [[ $DRY_RUN != 1 ]]; then
		run "$tool" "${args[@]}"
		return
	fi
	# The tool previews itself with --dry-run. Before the packages step has run
	# its own requirements may be missing, so a failed preview is not fatal.
	DRY_RUN=0 run "$tool" "${args[@]}" --dry-run ||
		warn "'dotfiles deploy --dry-run' failed; its requirements come from the packages step"
}
