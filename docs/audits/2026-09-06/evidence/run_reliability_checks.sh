#!/bin/sh
# Audit-only: compiles actual schedule/model sources; writes only temporary build artifacts.
set -eu
audit_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$audit_dir/../../../.." && pwd)
audit_build=$(mktemp -d "${TMPDIR:-/tmp}/bindaynz-reliability.XXXXXX")
trap 'rm -rf "$audit_build"' EXIT HUP INT TERM
swiftc -module-cache-path "$audit_build/modules" \
  "$repo_dir/BinDayNZ/Models/BinType.swift" \
  "$repo_dir/BinDayNZ/Models/Council.swift" \
  "$repo_dir/BinDayNZ/Models/CollectionSchedule.swift" \
  "$repo_dir/BinDayNZ/Models/CollectionZone.swift" \
  "$repo_dir/BinDayNZ/Models/UpcomingCollection.swift" \
  "$repo_dir/BinDayNZ/Services/ScheduleEngine.swift" \
  "$audit_dir/main.swift" -o "$audit_build/reliability-checks"
"$audit_build/reliability-checks" "$repo_dir/BinDayNZ/Resources/councils.json"
