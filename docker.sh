#!/bin/bash

VERSION=$1
TAGS=$2
VARIANT=$3
VERSION_TAG_ONLY=$4

function tag_and_push() {
  docker tag samschmit/tomcat-hardened samschmit/tomcat-hardened:"$1"
  docker push samschmit/tomcat-hardened:"$1"
}

# Create list of tags to process
read -ra TAGLIST <<< "${TAGS//,/ -}" # replace "," with " -" and put into array
TAGLIST[0]="-${TAGLIST[0]}"
if [ "$VERSION_TAG_ONLY" ]; then
  TAGLIST+=("") # append empty tag for version only tags
fi

MAJOR_MINOR=$(echo "$VERSION" | cut -d "." -f 1-2)
MAJOR=$(echo "$VERSION" | cut -d "." -f 1)

# Prepare docker file
cd "$MAJOR_MINOR" || exit
sed "s/#BASE#/$VERSION${TAGLIST[0]}/g" "Dockerfile.$VARIANT" > Dockerfile

# Build docker image
docker build -t samschmit/tomcat-hardened .

# Login
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Tag and push
for tag in "${TAGLIST[@]}"; do
  tag_and_push "$VERSION$tag"
  tag_and_push "$MAJOR_MINOR$tag"
  tag_and_push "$MAJOR$tag"
done
