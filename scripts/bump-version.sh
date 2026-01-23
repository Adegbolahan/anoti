#!/bin/bash

# Bump plugin version
# Usage: ./scripts/bump-version.sh [major|minor|patch]

PLUGIN_JSON="project-scaffolder/.claude-plugin/plugin.json"
SETTINGS_JSON="project-scaffolder/resources/templates/.claude/settings.json"

if [ ! -f "$PLUGIN_JSON" ]; then
    echo "Error: $PLUGIN_JSON not found"
    exit 1
fi

# Get current version
CURRENT=$(grep -o '"version": "[^"]*"' "$PLUGIN_JSON" | cut -d'"' -f4)
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# Determine bump type
BUMP_TYPE=${1:-patch}

case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Usage: $0 [major|minor|patch]"
        echo "  major: Breaking changes (1.0.0 -> 2.0.0)"
        echo "  minor: New features (1.0.0 -> 1.1.0)"
        echo "  patch: Bug fixes (1.0.0 -> 1.0.1)"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Update plugin.json
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW_VERSION\"/" "$PLUGIN_JSON"

# Update scaffoldVersion in settings.json template if it exists
if [ -f "$SETTINGS_JSON" ]; then
    sed -i '' "s/\"scaffoldVersion\": \"[^\"]*\"/\"scaffoldVersion\": \"$NEW_VERSION\"/" "$SETTINGS_JSON"
fi

echo "Version bumped: $CURRENT -> $NEW_VERSION"
echo ""
echo "Updated files:"
echo "  - $PLUGIN_JSON"
[ -f "$SETTINGS_JSON" ] && echo "  - $SETTINGS_JSON"
echo ""
echo "Don't forget to commit the version change!"
