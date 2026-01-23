#!/bin/bash
set -e

if [ ! -d "sing-box" ]; then
    echo "Downloading sing-box..."
    mkdir sing-box
    api_url="https://api.github.com/repos/SagerNet/sing-box/releases/latest"
    auth_header=()
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        auth_header=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    fi

    release_json=$(curl -fsSL "${auth_header[@]}" "$api_url")

    arm64_url=$(printf "%s" "$release_json" | grep -oE 'https://[^"]*sing-box-[^"]*-darwin-arm64[^"]*\.tar\.gz' | grep -v legacy | head -1)
    amd64_url=$(printf "%s" "$release_json" | grep -oE 'https://[^"]*sing-box-[^"]*-darwin-amd64[^"]*\.tar\.gz' | grep -v legacy | head -1)
    if [ -z "$arm64_url" ]; then
        arm64_url=$(printf "%s" "$release_json" | grep -oE 'https://[^"]*sing-box-[^"]*-darwin-arm64[^"]*\.tar\.gz' | head -1)
    fi
    if [ -z "$amd64_url" ]; then
        amd64_url=$(printf "%s" "$release_json" | grep -oE 'https://[^"]*sing-box-[^"]*-darwin-amd64[^"]*\.tar\.gz' | head -1)
    fi
    if [ -z "$arm64_url" ] || [ -z "$amd64_url" ]; then
        echo "Failed to resolve sing-box download URLs." >&2
        exit 1
    fi

    curl -fsSL --retry 3 --retry-connrefused "${auth_header[@]}" -o sing-box/sing-box-darwin-arm64.tar.gz "$arm64_url"
    curl -fsSL --retry 3 --retry-connrefused "${auth_header[@]}" -o sing-box/sing-box-darwin-amd64.tar.gz "$amd64_url"

    echo "Download complete."
fi

echo "Unzip core files"
cd sing-box
ls
mkdir -p arm64 amd64

arm64_tgz=$(ls -1 sing-box-*-darwin-arm64*.tar.gz sing-box-darwin-arm64.tar.gz 2>/dev/null | head -1 || true)
amd64_tgz=$(ls -1 sing-box-*-darwin-amd64*.tar.gz sing-box-darwin-amd64.tar.gz 2>/dev/null | head -1 || true)

arm64_bin=""
amd64_bin=""

if [ -n "$arm64_tgz" ]; then
    arm64_path_in_tar=$(tar -tf "$arm64_tgz" | grep -E '(^|/)(sing-box)$' | head -1 || true)
    if [ -z "$arm64_path_in_tar" ]; then
        echo "arm64 tarball does not contain sing-box binary." >&2
        tar -tf "$arm64_tgz" | head -50 >&2
        exit 1
    fi
    tar -xzf "$arm64_tgz" -C arm64 "$arm64_path_in_tar"
    arm64_bin="arm64/${arm64_path_in_tar#./}"
fi

if [ -n "$amd64_tgz" ]; then
    amd64_path_in_tar=$(tar -tf "$amd64_tgz" | grep -E '(^|/)(sing-box)$' | head -1 || true)
    if [ -z "$amd64_path_in_tar" ]; then
        echo "amd64 tarball does not contain sing-box binary." >&2
        tar -tf "$amd64_tgz" | head -50 >&2
        exit 1
    fi
    tar -xzf "$amd64_tgz" -C amd64 "$amd64_path_in_tar"
    amd64_bin="amd64/${amd64_path_in_tar#./}"
fi

echo "Create Universal core"
lipo_inputs_ok=true
if [ -z "$arm64_bin" ]; then
    echo "arm64 sing-box binary not found in tarball." >&2
    lipo_inputs_ok=false
fi
if [ -z "$amd64_bin" ]; then
    echo "amd64 sing-box binary not found in tarball." >&2
    lipo_inputs_ok=false
fi
if [ "$lipo_inputs_ok" != "true" ]; then
    exit 1
fi

lipo -create -output sing-box "$amd64_bin" "$arm64_bin"
chmod +x sing-box

echo "Detect core version"
core_version=$(./sing-box version 2>/dev/null | head -1 | sed -E 's/.*version[[:space:]]+([0-9A-Za-z.+-]+)/\1/')
if [ -n "$core_version" ]; then
    if /usr/libexec/PlistBuddy -c "Set coreVersion $core_version" ../Neko/Info.plist 2>/dev/null; then
        :
    else
        /usr/libexec/PlistBuddy -c "Add coreVersion string $core_version" ../Neko/Info.plist
    fi
    /usr/libexec/PlistBuddy -c 'Print coreVersion' ../Neko/Info.plist
else
    echo "Failed to detect sing-box core version." >&2
    exit 1
fi

echo "Update sing-box core md5 to code"
sed -i '' "s/WOSHIZIDONGSHENGCHENGDEA/$(md5 -q sing-box)/g" ../Neko/AppDelegate.swift
sed -n '20p' ../Neko/AppDelegate.swift

echo "Gzip Universal core"
gzip -f sing-box
cp sing-box.gz ../Neko/Resources/
cd ..

echo "Ensure ProxyConfigHelper meta exists"
meta_path="./Neko/Resources/com.metacubex.Neko.ProxyConfigHelper.meta.gz"
if [ ! -f "$meta_path" ]; then
    echo "Building ProxyConfigHelper for meta..."
    xcodebuild -project Neko.xcodeproj -scheme "com.metacubex.Neko.ProxyConfigHelper" -configuration Release -derivedDataPath build/ProxyConfigHelper build
    helper_bin=$(find build/ProxyConfigHelper/Build/Products/Release -name "com.metacubex.Neko.ProxyConfigHelper" -type f | head -1)
    if [ -z "$helper_bin" ]; then
        echo "ProxyConfigHelper binary not found after build." >&2
        exit 1
    fi
    gzip -c "$helper_bin" > "$meta_path"
fi

echo "delete old files"
rm -f ./Neko/Resources/country.mmdb
rm -f ./Neko/Resources/geosite.dat
rm -f ./Neko/Resources/geoip.dat
rm -rf ./Neko/Resources/dashboard
rm -f GeoLite2-Country.*
echo "install mmdb"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/raw/release/country.mmdb
gzip country.mmdb
mv country.mmdb.gz ./Neko/Resources/country.mmdb.gz
echo "install geosite"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.dat
gzip geosite.dat
mv geosite.dat.gz ./Neko/Resources/geosite.dat.gz
echo "install geoip"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip.dat
gzip geoip.dat
mv geoip.dat.gz ./Neko/Resources/geoip.dat.gz


echo "install yacd dashboard"
cd Neko/Resources
git clone -b gh-pages https://github.com/MetaCubeX/Yacd-meta.git dashboard/yacd
cd dashboard/yacd
rm -rf *.webmanifest *.js CNAME .git
cd ../../

echo "install XD dashboard"
git clone -b gh-pages https://github.com/metacubex/metacubexd.git dashboard/xd
cd dashboard/xd
rm -rf *.webmanifest CNAME .git
cd ../../

echo "install zashboard"
git clone -b gh-pages https://github.com/Zephyruso/zashboard.git dashboard/zashboard
cd dashboard/zashboard
rm -rf *.webmanifest CNAME .git
