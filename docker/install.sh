#!/bin/sh -eu

# Installs the newest stable Kotlin compiler on top of the JDK this image
# already has. The compiler is a JVM program, so the distribution is the
# whole of it.

apk add --update bash
apk add --virtual=build-dependencies curl wget ca-certificates

# github redirects the releases/latest URL to the tag of the newest release,
# so the version is read from where it is redirected to. That asks nothing of
# the API, which rate limits by IP and would make a build depend on how busy
# the runner's neighbours had been.
#
# curl reports the redirect target itself, so no header has to be parsed.
# busybox grep, which is the grep here, has no long options anyway.
readonly LATEST_URL=$(curl --silent --output /dev/null \
  --write-out '%{redirect_url}' \
  https://github.com/JetBrains/kotlin/releases/latest)

# The tag carries a leading v that the version and the zip inside it do not.
readonly KOTLIN_TAG="${LATEST_URL##*/tag/}"
readonly KOTLIN_VERSION="${KOTLIN_TAG#v}"

if [ -z "${KOTLIN_VERSION}" ]; then
  echo 'ERROR: could not resolve the newest stable kotlin release' >&2
  exit 1
fi

readonly ZIP="kotlin-compiler-${KOTLIN_VERSION}.zip"
wget "https://github.com/JetBrains/kotlin/releases/download/${KOTLIN_TAG}/${ZIP}"
unzip "${ZIP}"
rm "${ZIP}"

# Read by check_version.sh and by the images built on this one, so that all of
# them state the version this image holds rather than repeating a number
# written down somewhere else.
echo "{\"kotlin\":\"${KOTLIN_VERSION}\"}" > /versions.json

apk del build-dependencies
rm -rf /tmp/* /var/cache/apk/*
