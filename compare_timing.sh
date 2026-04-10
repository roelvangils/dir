#!/bin/zsh

echo "=== Original script timing ==="
time ./dir.sh > /dev/null 2>&1
echo ""

echo "=== Optimized script timing ==="
time ./dir_optimized.sh > /dev/null 2>&1
echo ""

echo "=== Running optimized script ==="
./dir_optimized.sh