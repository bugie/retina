#!/bin/bash
set -e

# Arguments
TAG=$1
USER=$2
PASSWORD=$3

# Configure these for your registry
export IMAGE_REGISTRY="docker-k8s-infrastructure-public-release.dr-uw2.adobeitc.com"                    # or docker.io, your-registry.com, etc.                                # your desired tag
export IMAGE_NAMESPACE="microsoft/retina"
export AGENT_TARGETS="init agent"
export CONTAINER_BUILDER="docker"
export RETINA_INIT_IMAGE="retina-init"
export RETINA_IMAGE="retina-agent"
export APP_INSIGHTS_ID=""

# Get repo root (equivalent to Makefile's: git rev-parse --show-toplevel)
REPO_ROOT=$(git rev-parse --show-toplevel)

# Ensure buildx is set up
make buildx

# Build and push for both platforms
for PLATFORM in linux/amd64 linux/arm64; do
    echo "Building for $PLATFORM"
    
    # Convert linux/amd64 to linux-amd64 for the tag
    PLATFORM_TAG=$(echo "$PLATFORM" | tr '/' '-')
    RETINA_PLATFORM_TAG="${TAG}-${PLATFORM_TAG}"
    
    for target in $AGENT_TARGETS; do
        echo "Building for $target"
        
        if [ "$target" = "init" ]; then
            image_name=$RETINA_INIT_IMAGE
        else
            image_name=$RETINA_IMAGE
        fi
        
        # Include namespace in IMAGE path
        full_image_path="$IMAGE_NAMESPACE/$image_name"
        
        make container-$CONTAINER_BUILDER \
            PLATFORM=$PLATFORM \
            DOCKERFILE=controller/Dockerfile \
            REGISTRY=$IMAGE_REGISTRY \
            IMAGE=$full_image_path \
            VERSION=$TAG \
            TAG=$RETINA_PLATFORM_TAG \
            APP_INSIGHTS_ID=$APP_INSIGHTS_ID \
            CONTEXT_DIR=$REPO_ROOT \
            TARGET=$target \
            BUILDX_ACTION=--push
    done
done

# Create multi-arch manifests
echo "Creating multi-arch manifests..."
for component in agent init; do
    echo "Creating manifest for retina-$component..."
    docker buildx imagetools create \
        -t $IMAGE_REGISTRY/$IMAGE_NAMESPACE/retina-$component:$TAG \
        $IMAGE_REGISTRY/$IMAGE_NAMESPACE/retina-$component:$TAG-linux-amd64 \
        $IMAGE_REGISTRY/$IMAGE_NAMESPACE/retina-$component:$TAG-linux-arm64
done

echo "Done! Multi-arch images available at:"
echo "  - $IMAGE_REGISTRY/$IMAGE_NAMESPACE/retina-agent:$TAG"
echo "  - $IMAGE_REGISTRY/$IMAGE_NAMESPACE/retina-init:$TAG"