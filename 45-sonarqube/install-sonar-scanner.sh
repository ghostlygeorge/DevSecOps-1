#!/usr/bin/env bash
export SONAR_VERSION="4.7.0.2747"
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-linux.zip -O /opt/sonar-scanner.zip
unzip -o /opt/sonar-scanner.zip -d /opt/
chmod +x /opt/sonar-scanner-${SONAR_VERSION}-linux/bin/sonar-scanner
echo "export PATH=/opt/sonar-scanner-${SONAR_VERSION}-linux/bin/:\$PATH   # run this in your shell"
