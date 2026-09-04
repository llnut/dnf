#!/usr/bin/env bash

# Resolve the image tag suffix for a release git tag.
#
# Release tags follow the form release-YYYYMMDD. A qualifier may follow the
# date, for example release-20260903-2. The suffix is the full tag. Every
# published release used image tags of the form <os>-...-release-YYYYMMDD.
# Stripping the prefix would rename images that users already pin.
#
# The release event and workflow_dispatch both call this function. A
# dispatched rebuild of an existing tag then produces the same image tags.
#
# The function prints the suffix and returns 0 for a valid tag. It prints
# nothing and returns 1 for any other input.
release_tag_suffix() {
    local tag="$1"
    # Use the C locale so the letter ranges in the pattern only match ASCII.
    local LC_ALL=C
    local pattern='^release-[0-9]{8}([._-][A-Za-z0-9._-]+)?$'

    if [[ ! "$tag" =~ $pattern ]]; then
        return 1
    fi
    printf '%s' "$tag"
}
