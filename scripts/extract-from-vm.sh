#!/usr/bin/env bash
# Copy a directory tree out of a VirtualBox Windows VM disk, read-only, without root and
# without starting the VM. Needs VirtualBox (vboximg-mount) and ntfs-3g (ntfsls, ntfscat).
# Shut the VM down first. Only the first NTFS partition (vol0) is read.
#
# Usage: VMDK=/path/to/disk.vmdk extract-from-vm.sh <ntfs-path> <dest-dir>
#   e.g. VMDK=~/"VirtualBox VMs/xp/xp.vmdk" scripts/extract-from-vm.sh /KnittStyler ~/KnittStyler
#        bundle/knittstyler --import ~/KnittStyler
set -euo pipefail
VMDK="${VMDK:-$HOME/VirtualBox VMs/knitter/knitter-disk001.vmdk}"
[ -f "$VMDK" ] || { echo "VM disk not found: $VMDK (set VMDK=...)" >&2; exit 1; }
SRC="$1"; DEST="$2"
MNT="$(mktemp -d)"
vboximg-mount --image "$VMDK" "$MNT" >/dev/null
trap 'fusermount -u "$MNT"; rmdir "$MNT"' EXIT
VOL="$MNT/vol0"
for _ in 1 2 3 4 5; do [ -e "$VOL" ] && break; sleep 1; done

copy_dir() {  # $1 = ntfs dir, $2 = local dir
  mkdir -p "$2"
  # ntfsls -l: size month day time year name ; dirs have size 0 and are listed with -F as name/
  ntfsls -f "$VOL" -F -p "$1" | while IFS= read -r name; do
    case "$name" in ./|../|.|..) continue ;; esac
    if [[ "$name" == */ ]]; then
      copy_dir "$1/${name%/}" "$2/${name%/}"
    else
      name="${name%[*@|=]}"
      ntfscat -f "$VOL" "$1/$name" > "$2/$name"
    fi
  done
}
copy_dir "$SRC" "$DEST"
