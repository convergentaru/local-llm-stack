#!/bin/bash
# =============================================================================
# Polybar launch script
# =============================================================================

# Kill existing polybar instances
killall -q polybar

# Wait for i3 to be ready
while ! pgrep -x i3 > /dev/null; do sleep 0.5; done

# Launch polybar
polybar main 2>&1 | tee -a /tmp/polybar.log &

echo "Polybar launched"
