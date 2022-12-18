#!/usr/bin/env bash

TEMP_DIR="/tmp/tencent-docs-bin/auto-update"
SRCINFO_DIR="~/Documents/Coding/ArchLinux/AUR/tencent-docs-bin/aur-repo/.SRCINFO"

# 删除并新建目录
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
cd $TEMP_DIR

# 在腾讯文档官网下载最新的安装包
wget https://down.qq.com/qqweb/linux_docs/LinuxTencentDocsAmd64.deb
wget https://down.qq.com/qqweb/linux_docs/LinuxTencentDocsArm64.deb

# 解包，读取版本
amd64_info=`ar p LinuxTencentDocsAmd64.deb control.tar.gz | tar xzOf - ./control`
arm64_info=`ar p LinuxTencentDocsArm64.deb control.tar.gz | tar xzOf - ./control`

amd64_version=`echo "$amd64_info" | grep Version | awk '{print $2}'`
arm64_version=`echo "$arm64_info" | grep Version | awk '{print $2}'`

echo "amd64 version: $amd64_version"
echo "arm64 version: $arm64_version"

# 计算安装包的 sha256
amd64_sha256=`cat LinuxTencentDocsAmd64.deb | openssl sha256 | awk '{print $2}'`
arm64_sha256=`cat LinuxTencentDocsArm64.deb | openssl sha256 | awk '{print $2}'`

echo "amd64_sha256: $amd64_sha256"
echo "arm64_sha256: $arm64_sha256"

# 输出辅助升级版本的文本
# 检查版本号有无发生改变
aur_amd64_pkgver=`cat $SRCINFO_DIR | grep pkgver | awk '{print $3}'`
aur_arm64_pkgver=`cat $SRCINFO_DIR | grep pkgver | awk '{print $3}'`

# 检查 sha256 有无发生改变
aur_amd64_sha256=`cat $SRCINFO_DIR | grep sha256sums_x86_64  | awk '{print $3}'`
aur_arm64_sha256=`cat $SRCINFO_DIR | grep sha256sums_aarch64 | awk '{print $3}'`

echo "-------------------"

# 准备安装包，方便上传到 GitHub
function prepare_package() {
    mkdir ~/Downloads/tencent-docs-bin-$amd64_version/
    mv LinuxTencentDocsAmd64.deb ~/Downloads/tencent-docs-bin-$amd64_version/LinuxTencentDocsAmd64.deb
    mv LinuxTencentDocsArm64.deb ~/Downloads/tencent-docs-bin-$amd64_version/LinuxTencentDocsArm64.deb
    echo "已准备新版本安装包到 ~/Downloads/tencent-docs-bin-$amd64_version/ 目录，请手动进行 AUR 的升级处理"
    dolphin ~/Downloads/tencent-docs-bin-$amd64_version/
}

# 如果新包的 amd64 和 arm64 包版本不一致，不执行对比
if [[ "$amd64_version" != "$arm64_version" ]]; then
echo "新包的 amd64 和 arm64 包版本不一致 $amd64_version != $arm64_version ，放弃检查，请稍候重试"
exit
fi

# 如果版本号和 sha256 都发生改变了
if [[ 
    "$aur_amd64_pkgver" != "$amd64_version" && 
    "$aur_arm64_pkgver" != "$arm64_version" &&
    "$aur_amd64_sha256" != "$amd64_sha256"  &&
    "$aur_arm64_sha256" != "$arm64_sha256"
]]; then
echo "有版本更新"
echo "版本号: $aur_amd64_pkgver -> $amd64_version"
echo "sha256:"
echo "- amd64: $aur_amd64_sha256 -> $amd64_sha256"
echo "- arm64: $aur_arm64_sha256 -> $arm64_sha256"
prepare_package
exit
fi

# 如果版本号没变，但sha256 变了
if [[ 
    "$aur_amd64_pkgver" == "$amd64_version" && 
    "$aur_arm64_pkgver" == "$arm64_version" &&
    "$aur_amd64_sha256" != "$amd64_sha256"  &&
    "$aur_arm64_sha256" != "$arm64_sha256"
]]; then
echo "上游偷偷换包了，需要更新 sha256"
echo "sha256:"
echo "- amd64: $aur_amd64_sha256 -> $amd64_sha256"
echo "- arm64: $aur_arm64_sha256 -> $arm64_sha256"
prepare_package
exit
fi 

# 如果版本号变了，sha256 却没变
if [[ 
    "$aur_amd64_pkgver" != "$amd64_version" && 
    "$aur_arm64_pkgver" != "$arm64_version" &&
    "$aur_amd64_sha256" == "$amd64_sha256"  &&
    "$aur_arm64_sha256" == "$arm64_sha256"
]]; then
echo "马萨卡！新的版本修复了版本号过低的 BUG"
echo "依旧需要发布一个新版本，但 sha256 无需改变"
echo "版本号: $aur_amd64_pkgver -> $amd64_version"
prepare_package
exit
fi

# 如果版本号和 sha256 都没变
if [[ 
    "$aur_amd64_pkgver" == "$amd64_version" && 
    "$aur_arm64_pkgver" == "$arm64_version" &&
    "$aur_amd64_sha256" == "$amd64_sha256"  &&
    "$aur_arm64_sha256" == "$arm64_sha256"
]]; then
echo "版本号和 sha256 都没有发生改变，无需升级版本"
fi
