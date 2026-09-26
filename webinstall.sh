#!/bin/sh
# DockRoot 一键部署脚本 (Alpine Linux)
# 用法: chmod +x install.sh && ./install.sh

set -e

# ========== 1. 检测 root 权限 ==========
if [ "$(id -u)" -ne 0 ]; then
    echo "[错误] 请使用 root 权限运行此脚本 (例如: sudo ./install.sh)"
    exit 1
fi
echo "[信息] root 权限检测通过，继续执行..."

# ========== 2. 准备环境 ==========
# Alpine 使用 BusyBox wget，确保有 ca-certificates 才能访问 https
if ! command -v wget >/dev/null 2>&1; then
    echo "[信息] 未检测到 wget，正在安装..."
    apk add --no-cache wget
fi
if ! command -v update-ca-certificates >/dev/null 2>&1; then
    echo "[信息] 安装 ca-certificates 以支持 HTTPS..."
    apk add --no-cache ca-certificates
fi

# ========== 3. 创建 /home/web 目录 ==========
mkdir -p /home/web
cd /home/web
echo "[信息] 已创建目录 /home/web"

# ========== 4. 下载 DockRoot 与 ruri ==========
DOCKROOT_URL="https://raw.githubusercontent.com/Jeinse/CCBMyFirstProject/main/DockRoot.amd64"
RURI_URL="https://raw.githubusercontent.com/Jeinse/CCBMyFirstProject/main/ruri.amd64"

echo "[信息] 正在下载 DockRoot..."
wget -O DockRoot "$DOCKROOT_URL" || { echo "[错误] DockRoot 下载失败"; exit 1; }

echo "[信息] 正在下载 ruri..."
wget -O ruri "$RURI_URL" || { echo "[错误] ruri 下载失败"; exit 1; }

# ========== 5. 赋予 777 权限 ==========
chmod 777 DockRoot ruri
echo "[信息] 已为 DockRoot 与 ruri 设置 777 权限"

# ========== 6. 拉取镜像 ==========
echo "[信息] 开始拉取 sqlite-wordpress 镜像..."
./DockRoot pull docker.io/soulteary/sqlite-wordpress:latest web

echo "[完成] 全部步骤执行完毕。"
