#!/usr/bin/env bash

if ! SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd); then
    echo "FAIL: failed to resolve script directory" >&2
    exit 1
fi

passed=0

fail() {
    echo "FAIL $*" >&2
    exit 1
}

# shellcheck source=.github/scripts/release-tag.sh
if ! . "${SCRIPT_DIR}/release-tag.sh"; then
    fail "failed to load release-tag.sh"
fi

assert_eq() {
    local expected=$1
    local actual=$2
    local message=$3
    if [ "$expected" != "$actual" ]; then
        fail "${message}: expected '${expected}', got '${actual}'"
    fi
    passed=$((passed + 1))
}

assert_file_contains() {
    local pattern=$1
    local file=$2
    local message=$3
    local grep_rc

    grep -q -- "$pattern" "$file"
    grep_rc=$?
    if [ "$grep_rc" -eq 0 ]; then
        passed=$((passed + 1))
        return 0
    fi
    if [ "$grep_rc" -eq 1 ]; then
        fail "$message"
    fi
    fail "failed to read ${file}"
}

assert_file_lacks() {
    local pattern=$1
    local file=$2
    local message=$3
    local grep_rc

    grep -q -- "$pattern" "$file"
    grep_rc=$?
    if [ "$grep_rc" -eq 1 ]; then
        passed=$((passed + 1))
        return 0
    fi
    if [ "$grep_rc" -eq 0 ]; then
        fail "$message"
    fi
    fail "failed to read ${file}"
}

assert_accepted() {
    local tag=$1
    local message=$2
    local actual

    if ! actual=$(release_tag_suffix "$tag"); then
        fail "${message}: '${tag}' was rejected"
    fi
    assert_eq "$tag" "$actual" "$message"
}

assert_rejected() {
    local tag=$1
    local message=$2
    local actual

    if actual=$(release_tag_suffix "$tag"); then
        fail "${message}: '${tag}' was accepted with suffix '${actual}'"
    fi
    assert_eq "" "$actual" "${message}: rejected tag must print nothing"
}

# The suffix is the full git tag. A stripped suffix would rename images that
# users already pin.
test_release_tag_suffix_is_the_full_tag() {
    assert_accepted "release-20260903" "date stamped release tag"
    assert_accepted "release-20260903-2" "release tag with a hotfix qualifier"
    assert_accepted "release-20260903.1" "release tag with a dotted qualifier"
    assert_accepted "release-20260903-RC1" "qualifier may carry upper case letters"
}

test_release_tag_rejects_other_shapes() {
    assert_rejected "Release-20260903" "capitalised prefix does not match any git tag"
    assert_rejected "20260903" "bare date"
    assert_rejected "release-" "prefix only"
    assert_rejected "" "empty input"
    assert_rejected "release-2026090" "seven digit date"
    assert_rejected "release-202609031" "nine digit date"
    assert_rejected "release-20260903 " "trailing whitespace"
    assert_rejected "release-20260903/x" "slash is not tag safe"
    assert_rejected "release-20260903-" "dangling qualifier separator"
    assert_rejected "v1.0.0" "semver style tag"
    assert_rejected "release-20260903-é" "non ASCII letters are rejected in every locale"
    assert_rejected "main" "branch name"
}

# The release event and workflow_dispatch must resolve the same suffix for
# the same tag. Both must call the shared helper.
test_workflow_uses_shared_helper() {
    local workflow_file="${SCRIPT_DIR}/../workflows/docker.yml"

    assert_file_contains "release-tag.sh" "$workflow_file" "docker.yml must source release-tag.sh"
    assert_file_contains "release_tag_suffix" "$workflow_file" "docker.yml must call release_tag_suffix"
    assert_file_lacks "Release-" "$workflow_file" "docker.yml must not keep the capitalised Release- prefix"
}

test_release_tag_suffix_is_the_full_tag
test_release_tag_rejects_other_shapes
test_workflow_uses_shared_helper

echo "pass=$passed failed=0"
