#!/bin/bash
# List TODO/FIXME/HACK comments across the codebase
grep -rn --include="*.swift" --include="*.ts" -E "TODO|FIXME|HACK|XXX" . | grep -v ".build/" | grep -v "node_modules/"
