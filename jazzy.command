#!/bin/sh
CWD="$(pwd)"
MY_SCRIPT_PATH=`dirname "${BASH_SOURCE[0]}"`
cd "${MY_SCRIPT_PATH}"
rm -drf docs
jazzy
cp img/*.* docs/img/
cp icon.png docs/icon.png
cp LGV.png docs/LGV.png
cd "${CWD}"
