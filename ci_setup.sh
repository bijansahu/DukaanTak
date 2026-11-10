#!/usr/bin/env bash
# Prepare a complete Android platform project and wire Firebase for DukaanTak.
set -euo pipefail

# The supplied archive keeps Dart sources at its root for phone-friendly uploads.
mkdir -p lib
for f in ./*.dart; do
  [ -e "$f" ] || continue
  mv -f "$f" lib/
done

# Regenerate Android scaffolding so Gradle files are valid for the installed Flutter SDK.
# Firebase's registered Android application ID is com.duakaantak.customer.
rm -rf android
flutter create --platforms=android --org com.duakaantak --project-name customer .

# Install the exact Firebase Android client configuration.
if [ ! -f google-services.json ]; then
  echo "ERROR: google-services.json is missing from the project root." >&2
  exit 1
fi
mkdir -p android/app
cp -f google-services.json android/app/google-services.json

# Configure Google Services plugin for either Kotlin DSL or Groovy Gradle files.
python3 - <<'PYTHON'
from pathlib import Path
import re

def patch_settings(path, kotlin):
    p=Path(path)
    if not p.exists(): return
    s=p.read_text()
    plugin='com.google.gms.google-services'
    if plugin not in s:
        if kotlin:
            pattern=r'(^[ \t]*id\("com\.android\.application"\)\s+version[^\n]*\n)'
            replacement=r'\1    id("com.google.gms.google-services") version "4.4.2" apply false\n'
        else:
            pattern=r'(^[ \t]*id\s+"com\.android\.application"\s+version[^\n]*\n)'
            replacement=r'\1    id "com.google.gms.google-services" version "4.4.2" apply false\n'
        s,n=re.subn(pattern,replacement,s,count=1,flags=re.M)
        if not n:
            raise SystemExit(f'Could not add Google Services plugin declaration to {path}')
        p.write_text(s)

def patch_app(path, kotlin):
    p=Path(path)
    if not p.exists(): return
    s=p.read_text()
    plugin='com.google.gms.google-services'
    if plugin not in s:
        if kotlin:
            pattern=r'(^[ \t]*id\("com\.android\.application"\)[ \t]*\n)'
            replacement=r'\1    id("com.google.gms.google-services")\n'
        else:
            pattern=r'(^[ \t]*id\s+"com\.android\.application"[ \t]*\n)'
            replacement=r'\1    id "com.google.gms.google-services"\n'
        s,n=re.subn(pattern,replacement,s,count=1,flags=re.M)
        if not n:
            raise SystemExit(f'Could not apply Google Services plugin in {path}')
    # Firebase Android SDKs require minSdk 23 for current Firebase releases.
    s=s.replace('flutter.minSdkVersion', '23')
    p.write_text(s)

patch_settings('android/settings.gradle.kts', True)
patch_settings('android/settings.gradle', False)
patch_app('android/app/build.gradle.kts', True)
patch_app('android/app/build.gradle', False)
PYTHON

# Confirm generated Android application ID matches the Firebase registration.
grep -Rqs 'applicationId = "com.duakaantak.customer"\|applicationId "com.duakaantak.customer"' android/app || {
  echo "ERROR: Android applicationId does not match Firebase package name." >&2
  exit 1
}
flutter pub get

echo "DukaanTak Android + Firebase configuration prepared."
