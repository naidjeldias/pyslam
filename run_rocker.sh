DATA_PATH=$1

if [ -z "$DATA_PATH" ]; then
  echo "Usage: run_rocker.sh <data_path>"
  exit 1
else
  echo "Data path: $DATA_PATH"
fi

# Shift the first argument (data path) so it's not passed as a command
shift


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
  --oyr-run-arg "--privileged \
                -v $SCRIPT_DIR/main_vo.py:/root/pyslam/main_vo.py:rw \
                -v $SCRIPT_DIR/pyslam:/root/pyslam/pyslam:rw \
                -v $SCRIPT_DIR/thirdparty/superpoint:/root/pyslam/thirdparty/superpoint:rw \
                -v $SCRIPT_DIR/thirdparty/Deep-corner-tracker:/root/pyslam/thirdparty/Deep-corner-tracker:rw \
                -v $SCRIPT_DIR/config.yaml:/root/pyslam/config.yaml:rw \
                -v $SCRIPT_DIR/config_libs.yaml:/root/pyslam/config_libs.yaml:rw \
                -v ${DATA_PATH}:/root/data:rw" \
  pyslam:latest\
  ${@:-"bash"}