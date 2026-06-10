#!/usr/bin/env bash
# Build & push the three custom tool images to Docker Hub.
#
# Credentials are read from the environment — NEVER hardcode a token in this
# file or commit it. Provide:
#   DOCKERHUB_USERNAME   your Docker Hub user (default: ebareke)
#   DOCKERHUB_TOKEN      a Docker Hub access token (export it, don't paste here)
#
# Usage:
#   export DOCKERHUB_USERNAME=ebareke
#   export DOCKERHUB_TOKEN=<your-token>
#   ./containers/build_and_push.sh                 # build + push all
#   PUSH=false ./containers/build_and_push.sh       # build only
#   ./containers/build_and_push.sh rattle           # one image
#
# Optionally pin upstream refs for reproducibility:
#   RATTLE_REF=<sha> TAILFINDR_REF=<tag> NANORMS_REF=<sha> ./containers/build_and_push.sh
set -euo pipefail

USER_NS="${DOCKERHUB_USERNAME:-ebareke}"
PUSH="${PUSH:-true}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# image -> tag and build-arg name
declare -A TAG=( [rattle]=1.0 [tailfindr]=1.4 [nanorms]=2.0 )
declare -A ARG=( [rattle]=RATTLE_REF [tailfindr]=TAILFINDR_REF [nanorms]=NANORMS_REF )

targets=("${@:-}")
[ -z "${targets[*]}" ] && targets=(rattle tailfindr nanorms)

if [ "$PUSH" = "true" ]; then
    : "${DOCKERHUB_TOKEN:?Set DOCKERHUB_TOKEN in the environment (do not hardcode)}"
    echo "$DOCKERHUB_TOKEN" | docker login -u "$USER_NS" --password-stdin
fi

for tool in "${targets[@]}"; do
    tag="${TAG[$tool]}"
    argname="${ARG[$tool]}"
    argval="${!argname:-}"
    build_arg=()
    [ -n "$argval" ] && build_arg=(--build-arg "${argname}=${argval}")

    echo ">> building ${USER_NS}/${tool}:${tag}"
    docker build "${build_arg[@]}" -t "${USER_NS}/${tool}:${tag}" "${HERE}/${tool}"

    if [ "$PUSH" = "true" ]; then
        echo ">> pushing ${USER_NS}/${tool}:${tag}"
        docker push "${USER_NS}/${tool}:${tag}"
    fi
done

echo "Done."
