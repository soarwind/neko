#!/bin/bash
set -e

if [ ! -d "sing-box" ]; then
    echo "Downloading sing-box..."
    mkdir sing-box
    # arm64
    curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest \
     | grep "browser_download_url.*sing-box-.*-darwin-arm64.*tar.gz" \
     | cut -d '"' -f 4 \
     | xargs curl -L -o sing-box/sing-box-darwin-arm64.tar.gz

     # amd64
    curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest \
     | grep "browser_download_url.*sing-box-.*-darwin-amd64.*tar.gz" \
     | cut -d '"' -f 4 \
     | xargs curl -L -o sing-box/sing-box-darwin-amd64.tar.gz

    echo "Download complete."
fi

echo "Unzip core files"
cd sing-box
ls
mkdir -p arm64 amd64

if [ -f "sing-box-darwin-arm64.tar.gz" ]; then
    tar -xzf sing-box-darwin-arm64.tar.gz -C arm64
fi

if [ -f "sing-box-darwin-amd64.tar.gz" ]; then
    tar -xzf sing-box-darwin-amd64.tar.gz -C amd64
fi

echo "Create Universal core"
arm64_bin=$(find arm64 -name "sing-box" -type f | head -1)
amd64_bin=$(find amd64 -name "sing-box" -type f | head -1)

lipo -create -output sing-box "$amd64_bin" "$arm64_bin"
chmod +x sing-box

echo "Update sing-box core md5 to code"
sed -i '' "s/WOSHIZIDONGSHENGCHENGDEA/$(md5 -q sing-box)/g" ../ClashX/AppDelegate.swift
sed -n '20p' ../ClashX/AppDelegate.swift

echo "Gzip Universal core"
gzip -f sing-box
cp sing-box.gz ../ClashX/Resources/
cd ..

echo "delete old files"
rm -f ./ClashX/Resources/country.mmdb
rm -f ./ClashX/Resources/geosite.dat
rm -f ./ClashX/Resources/geoip.dat
rm -rf ./ClashX/Resources/dashboard
rm -f GeoLite2-Country.*
echo "install mmdb"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/raw/release/country.mmdb
gzip country.mmdb
mv country.mmdb.gz ./ClashX/Resources/country.mmdb.gz
echo "install geosite"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.dat
gzip geosite.dat
mv geosite.dat.gz ./ClashX/Resources/geosite.dat.gz
echo "install geoip"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip.dat
gzip geoip.dat
mv geoip.dat.gz ./ClashX/Resources/geoip.dat.gz


echo "install yacd dashboard"
cd ClashX/Resources
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
