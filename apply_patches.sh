#!/bin/bash
set -e

FLUTTER_ROOT="/Users/feiranyang/fvm/versions/3.47.2"
WORKSPACE="/Users/feiranyang/Developer/PiliPlus"

echo "Patching Flutter SDK"
cd $FLUTTER_ROOT
git reset --hard HEAD
PATCHES=(
    "lib/scripts/modal_barrier.patch"
    "lib/scripts/text_selection.patch"
    "lib/scripts/mouse_cursor.patch"
    "lib/scripts/image_anim.patch"
    "lib/scripts/layout_builder.patch"
    "lib/scripts/navigation_drawer.patch"
    "lib/scripts/popup_menu.patch"
    "lib/scripts/fab.patch"
    "lib/scripts/null_safety_for_selectable_region.patch"
    "lib/scripts/selectable_region.patch"
    "lib/scripts/editable_text.patch"
    "lib/scripts/text_field.patch"
    "lib/scripts/scroll_position.patch"
    "lib/scripts/scrollable.patch"
    "lib/scripts/scrollable_gesture.patch"
    "lib/scripts/draggable_scrollable_sheet.patch"
    "lib/scripts/scaffold.patch"
    "lib/scripts/text.patch"
    "lib/scripts/text_painter.patch"
    "lib/scripts/sliver.patch"
    "lib/scripts/refresh_indicator.patch"
    "lib/scripts/bottom_sheet_android.patch"
    "lib/scripts/scroll_view.patch"
    "lib/scripts/navigator.patch"
)

for patch in "${PATCHES[@]}"; do
    git apply "$WORKSPACE/$patch" || echo "Failed to apply $patch, continuing..."
done

echo "Removing pub cache for material_ui"
PUB_CACHE="$HOME/.pub-cache"
find "$PUB_CACHE/hosted/pub.dev" -name "material_ui-*" -exec rm -rf {} + || true

cd $WORKSPACE
/Users/feiranyang/fvm/bin/fvm flutter pub get

MATERIAL_UI_DIR=$(find "$PUB_CACHE/hosted/pub.dev" -maxdepth 1 -name "material_ui-*" | sort | tail -n 1)
echo "material_ui dir: $MATERIAL_UI_DIR"

if [ -n "$MATERIAL_UI_DIR" ]; then
    cd "$MATERIAL_UI_DIR"
    git init || true
    git add . || true
    MATERIAL_PATCHES=(
        "lib/scripts/material/modal_barrier_material.patch"
        "lib/scripts/material/navigation_drawer.patch"
        "lib/scripts/material/popup_menu.patch"
        "lib/scripts/material/fab.patch"
        "lib/scripts/material/text_field.patch"
        "lib/scripts/material/scaffold.patch"
        "lib/scripts/material/refresh_indicator.patch"
        "lib/scripts/material/tabs.patch"
        "lib/scripts/material/bottom_sheet_android.patch"
    )
    for patch in "${MATERIAL_PATCHES[@]}"; do
        git apply "$WORKSPACE/$patch" || echo "Failed to apply $patch, continuing..."
    done
fi

