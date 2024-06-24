#!/bin/sh
CWD="$(pwd)"
MY_SCRIPT_PATH=`dirname "${BASH_SOURCE[0]}"`
cd "${MY_SCRIPT_PATH}"

echo "Creating Docs for the Virtual Meeting Finder App\n"
rm -drf docs/*

jazzy  --readme ./README.md \
       --github_url https://github.com/LittleGreenViper/VirtualMeetingFinder \
       --title "Virtual Meeting Finder Doumentation" \
       --min_acl private \
       --theme fullwidth
cp ./icon.png docs/
