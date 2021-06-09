#!/usr/bin/env bash

set -e

INSTALL_PATH=$1
REPO=634750802/release.sh

if [[ -z "$INSTALL_PATH" ]]; then
  echo "INSTALL_PATH required"
  exit 1
fi

if ! type gh ; then
  echo "require gh(GitHub CLI) installed"
fi

cd "$INSTALL_PATH"

LATEST_RELEASE=$(gh release list -R "$REPO" | grep Latest | awk '{ print $3 }')
echo "latest release was: $LATEST_RELEASE"

ASSET_NAME=$(gh release view -R "$REPO" "$LATEST_RELEASE" | grep -oE "release\.sh\..+\.zip")

if [[ -f "$ASSET_NAME" ]]; then
  echo "use cached $(pwd)/$ASSET_NAME"
  unzip -o "$ASSET_NAME"
else
  echo "download $ASSET_NAME to $INSTALL_PATH"
  gh release download -R "$REPO" "$LATEST_RELEASE" -p "$ASSET_NAME"
  unzip -o "$ASSET_NAME"
fi
