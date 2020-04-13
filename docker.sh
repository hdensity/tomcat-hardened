#!/bin/bash

VERSION=$1
TAG=$2
JAVA_BASE=$3
TAGS=$4
VARIANT=$5
VERSION_ONLY_TAG=$6

function tag_and_push() {
  docker tag samschmit/tomcat-hardened samschmit/tomcat-hardened:"$1"
  docker push samschmit/tomcat-hardened:"$1"
}

# Create list of tags to process
read -ra TAGLIST <<< "${TAGS//,/ }" # replace "," with " " and put into array

MAJOR_MINOR=$(echo "$VERSION" | cut -d "." -f 1-2)
MAJOR=$(echo "$VERSION" | cut -d "." -f 1)

# Prepare docker file
sed "s/#TOMCAT_BASE#/$VERSION-$TAG/g" "Dockerfile.$VARIANT" > Dockerfile
sed -i "s/#JAVA_BASE#/$JAVA_BASE/g" Dockerfile

# Build docker image
docker build --build-arg VERSION="$MAJOR_MINOR" -t samschmit/tomcat-hardened .

# Login
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Tag and push
for tag in "${TAGLIST[@]}"; do
  tag_and_push "$VERSION-$tag"
  tag_and_push "$MAJOR_MINOR-$tag"
  tag_and_push "$MAJOR-$tag"

  # versionless tag for v8.5
  if [[ $MAJOR_MINOR == "8.5" && -n $tag ]]; then
    tag_and_push "$tag"
  fi
done

if [[ "$VERSION_ONLY_TAG" == "true" ]]; then
  tag_and_push "$VERSION"
  tag_and_push "$MAJOR_MINOR"
  tag_and_push "$MAJOR"
fi
