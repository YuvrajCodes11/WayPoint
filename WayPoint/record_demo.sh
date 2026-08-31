#!/bin/bash
# =====================================================================
# WayPoint Simulator Demo Recording Script
# RevenueCat Shipathon 2026
# =====================================================================

mkdir -p waypoint-landing

echo "=================================================="
echo "🎬 WayPoint Demo Recording Started"
echo "=================================================="
echo "Target Output: waypoint-landing/demo.mp4"
echo "Press Ctrl+C at any time to stop recording."
echo "=================================================="

# Boot iPhone 17 Simulator if not running
xcrun simctl boot 15E8D52F-4C42-4FE5-902F-1DE6F720A8D1 2>/dev/null
xcrun simctl launch 15E8D52F-4C42-4FE5-902F-1DE6F720A8D1 com.yuvraj.WayPoint 2>/dev/null

# Record video directly from simulator
xcrun simctl io booted recordVideo waypoint-landing/demo.mp4 --codec=h264
