#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

release=$(curl -s https://api.github.com/repos/be5invis/Iosevka/releases/latest)

oldVersion=$(nix-instantiate --eval -E 'with import ../../../.. {}; lib.getVersion iosevka-bin' | tr -d '"')
version=$(echo "$release" | jq -r .tag_name | tr -d v)

if test "$oldVersion" = "$version"; then
    echo "New version same as old version, nothing to do." >&2
    exit 0
fi

sed -i "s/$oldVersion/$version/" bin.nix

{
    echo '# This file was autogenerated. DO NOT EDIT!'
    echo '{'
    for asset in $(echo "$release" | jq -r '.assets[].name | select(startswith("PkgTTC"))'); do
        printf '  %s = "%s";\n' \
            $(echo "$asset" | sed -r "s/^PkgTTC-(.*)-$version.zip$/\1/") \
            $(nix-prefetch-url "https://github.com/be5invis/Iosevka/releases/download/v$version/$asset")
    done
    echo '}'
} >variants.nix
