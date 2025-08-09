NVIDIA=$(echo "$NVIDIA" | tr '[:upper:]' '[:lower:]')
if [ "${NVIDIA:-true}" = "true" ]; then
  echo "Running with NVIDIA support"
  RENDERER="--nvidia"
else
  echo "Running without NVIDIA support"
  RENDERER="--devices /dev/dri"
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

rocker $RENDERER  --x11 \
  --name pyslam \
  --network host \
  --oyr-run-arg "--privileged -v $SCRIPT_DIR:/root/pyslam:rw" \
  pyslam:latest\
  ${@:-"bash"}