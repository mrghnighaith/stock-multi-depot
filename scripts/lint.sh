#!/bin/sh
# Lints every PHP file in app/public. Fails the build on the first syntax error.
set -e

echo "Linting PHP files..."
find app/public -name "*.php" -print0 | while IFS= read -r -d '' file; do
  php -l "$file"
done

echo "All PHP files passed lint."
