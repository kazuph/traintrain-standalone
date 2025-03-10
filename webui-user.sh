#!/bin/bash

# Set default variables
PYTHON=""
GIT=""
VENV_DIR=""

# Default commandline arguments
DEFAULT_ARGS=""

# Use passed arguments if any, otherwise use defaults
if [ $# -gt 0 ]; then
    COMMANDLINE_ARGS="$@"
else
    COMMANDLINE_ARGS="$DEFAULT_ARGS"
fi

# Additional arguments you might want to use
#  --models-dir
#  --lora-dir

# Call the main script with arguments
bash webui.sh $COMMANDLINE_ARGS
