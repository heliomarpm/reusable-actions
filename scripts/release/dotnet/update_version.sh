#!/usr/bin/env bash
VERSION=$1

find . -name "*.csproj" -exec sed -i "s/<Version>.*<\/Version>/<Version>$VERSION<\/Version>/" {} \;
