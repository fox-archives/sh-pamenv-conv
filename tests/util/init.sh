# shellcheck shell=bash

set -ETeo pipefail

eval "$(basalt-package-init)"; basalt.package-init
basalt.package-load

load './util/test_util.sh'

setup() {
	unset TOML
	cd "$BATS_TEST_TMPDIR"
}

teardown() {
	cd "$BATS_SUITE_TMPDIR"
}
