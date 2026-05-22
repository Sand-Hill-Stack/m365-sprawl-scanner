#!/bin/bash
# Validate local Git configuration and commit anonymity.

echo "============================================="
echo "  SAND HILL STACK SECURITY GUARDRAIL SCANNER"
echo "============================================="

# 1. Check local Git Configuration
NAME=$(git config --local user.name 2>/dev/null)
EMAIL=$(git config --local user.email 2>/dev/null)

EXPECTED_NAME="Sand Hill Stack Operations"
EXPECTED_EMAIL="Sand-Hill-Stack@users.noreply.github.com"

VIOLATION=0

echo -n "Checking local Git user configuration... "
if [ "$NAME" != "$EXPECTED_NAME" ]; then
    echo "FAILED"
    echo "  [ERROR] user.name is '$NAME' but expected '$EXPECTED_NAME'"
    VIOLATION=1
else
    echo "PASSED"
fi

if [ "$EMAIL" != "$EXPECTED_EMAIL" ]; then
    echo "FAILED"
    echo "  [ERROR] user.email is '$EMAIL' but expected '$EXPECTED_EMAIL'"
    VIOLATION=1
else
    echo "PASSED"
fi

# 2. Check unpushed commits (origin/main..HEAD)
echo -n "Checking unpushed commits for personal identifiers... "
# Determine if origin/main exists
if git rev-parse --verify origin/main >/dev/null 2>&1; then
    UNPUSHED_COMMITS=$(git log origin/main..HEAD --pretty=format:"%H|%an|%ae" 2>/dev/null)
    if [ ! -z "$UNPUSHED_COMMITS" ]; then
        # Read line by line
        while IFS='|' read -r commit author_name author_email; do
            if [ "$author_name" != "$EXPECTED_NAME" ] || [ "$author_email" != "$EXPECTED_EMAIL" ]; then
                echo "FAILED"
                echo "  [ERROR] Unpushed commit $commit contains unmasked identity:"
                echo "          Author: $author_name <$author_email>"
                VIOLATION=1
                break
            fi
        done <<< "$UNPUSHED_COMMITS"
    fi
    if [ "$VIOLATION" -eq 0 ]; then
        echo "PASSED"
    fi
else
    echo "SKIPPED (origin/main not found)"
fi

# 3. Scan workspace files for personal leaks (excluding binaries and this script)
echo -n "Scanning file contents for private handles or personal email addresses... "
# Look for 'sanjaykrish' or 'sanjay' (case insensitive) followed by email patterns or real names,
# but ignore this file (validate-anonymity.sh) and images.
LEAK_COUNT=0

# Define patterns to search
PATTERNS=("sanjaykrish@gmail.com" "sanjaykrishnan" "sanjay@example.com")

for PATTERN in "${PATTERNS[@]}"; do
    # Search all text files in workspace, ignoring .git, binaries, and validate-anonymity.sh
    MATCHES=$(grep -rnFi "$PATTERN" --exclude-dir=".git" --exclude="validate-anonymity.sh" --exclude="*.png" --exclude="*.svg" .)
    if [ ! -z "$MATCHES" ]; then
        if [ "$LEAK_COUNT" -eq 0 ]; then
            echo "FAILED"
        fi
        echo "  [ERROR] Leaked personal identifier '$PATTERN' found in these files:"
        echo "$MATCHES"
        LEAK_COUNT=$((LEAK_COUNT+1))
        VIOLATION=1
    fi
done

if [ "$LEAK_COUNT" -eq 0 ]; then
    echo "PASSED"
fi

echo "============================================="
if [ "$VIOLATION" -eq 1 ]; then
    echo "  [SCAN RESULT] FAILED: Potential identity leak detected!"
    exit 1
else
    echo "  [SCAN RESULT] SUCCESS: All identity filters are active and clean."
    exit 0
fi
