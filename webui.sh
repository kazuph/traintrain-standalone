#!/bin/bash

# Set defaults if not defined
if [ -z "$PYTHON" ]; then
    PYTHON="python3"
fi

if [ -n "$GIT" ]; then
    export GIT_PYTHON_GIT_EXECUTABLE="$GIT"
fi

if [ -z "$VENV_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    VENV_DIR="$SCRIPT_DIR/venv"
fi

SD_WEBUI_RESTART="tmp/restart"
ERROR_REPORTING=FALSE

mkdir -p tmp 2>/dev/null

# Check Python
$PYTHON -c "" >tmp/stdout.txt 2>tmp/stderr.txt
if [ $? -eq 0 ]; then
    # Check pip
    $PYTHON -mpip --help >tmp/stdout.txt 2>tmp/stderr.txt
    if [ $? -ne 0 ]; then
        if [ -n "$PIP_INSTALLER_LOCATION" ]; then
            $PYTHON "$PIP_INSTALLER_LOCATION" >tmp/stdout.txt 2>tmp/stderr.txt
            if [ $? -ne 0 ]; then
                echo "Couldn't install pip"
                cat tmp/stdout.txt
                cat tmp/stderr.txt
                exit 1
            fi
        else
            echo "Couldn't launch pip"
            cat tmp/stdout.txt
            cat tmp/stderr.txt
            exit 1
        fi
    fi
else
    echo "Couldn't launch python"
    cat tmp/stdout.txt
    cat tmp/stderr.txt
    exit 1
fi

# Setup virtual environment
if [ "$VENV_DIR" != "-" ] && [ "$SKIP_VENV" != "1" ]; then
    if [ -f "$VENV_DIR/bin/python" ]; then
        # Activate existing venv
        PYTHON="$VENV_DIR/bin/python"
        source "$VENV_DIR/bin/activate"
        echo "venv $PYTHON"
    else
        # Create new venv
        PYTHON_FULLNAME=$($PYTHON -c "import sys; print(sys.executable)")
        echo "Creating venv in directory $VENV_DIR using python $PYTHON_FULLNAME"
        "$PYTHON_FULLNAME" -m venv "$VENV_DIR" >tmp/stdout.txt 2>tmp/stderr.txt

        if [ $? -eq 0 ]; then
            # Upgrade pip in the venv
            "$VENV_DIR/bin/python" -m pip install --upgrade pip
            if [ $? -ne 0 ]; then
                echo "Warning: Failed to upgrade PIP version"
            fi

            # Activate the venv
            PYTHON="$VENV_DIR/bin/python"
            source "$VENV_DIR/bin/activate"
            echo "venv $PYTHON"
        else
            echo "Unable to create venv in directory \"$VENV_DIR\""
            cat tmp/stdout.txt
            cat tmp/stderr.txt
            exit 1
        fi
    fi
fi

# Launch options
if [ "$ACCELERATE" = "True" ]; then
    ACCELERATE_PATH="$VENV_DIR/bin/accelerate"
    if [ -f "$ACCELERATE_PATH" ]; then
        echo "Accelerating"
        "$ACCELERATE_PATH" launch --num_cpu_threads_per_process=6 launch.py "$@"
    else
        $PYTHON launch.py "$@"
    fi
else
    $PYTHON launch.py "$@"
fi

# Restart if requested
if [ -f "$SD_WEBUI_RESTART" ]; then
    echo "Restarting..."
    source "$0" "$@"
fi
