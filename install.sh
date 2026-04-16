#!/bin/bash
set -e
cd antop-cli
swift build -c release
sudo cp .build/release/antop-cli /usr/local/bin/antop
echo "Installed antop; try? sudo antop"