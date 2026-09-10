#!/usr/bin/env bash
set -euo pipefail

if [[ $(/usr/bin/uname -s) != Darwin ]]; then
  echo "error: the default-browser check requires macOS" >&2
  exit 1
fi

bundle_id=$(
  /usr/bin/osascript -l JavaScript <<'JXA'
ObjC.import('AppKit')
const url = $.NSURL.URLWithString('https://example.com')
const appURL = $.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL(url)
const bundle = $.NSBundle.bundleWithURL(appURL)
ObjC.unwrap(bundle.bundleIdentifier)
JXA
)

if [[ $bundle_id != com.brave.Browser ]]; then
  echo "error: the effective HTTPS handler is '$bundle_id', not 'com.brave.Browser'" >&2
  echo "Open Brave, choose 'Set Brave as default browser', and approve the macOS prompt." >&2
  exit 1
fi

echo "Brave is the effective default browser."
