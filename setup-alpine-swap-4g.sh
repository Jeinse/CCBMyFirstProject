#!/bin/sh
# Alpine Linux: create a persistent 4 GiB swapfile safely.
set -eu
SWAP=/swapfile

[ "$(id -u)" -eq 0 ] || { echo '请用 root 运行。' >&2; exit 1; }
[ -f /etc/init.d/swap ] || { echo '找不到 Alpine OpenRC swap 服务。' >&2; exit 1; }

if awk -v p="$SWAP" 'NR>1 && $1==p {x=1} END {exit !x}' /proc/swaps; then
    echo '现有 /swapfile 已启用，不重复创建。'
elif [ -e "$SWAP" ] || [ -L "$SWAP" ]; then
    echo '发现已有 /swapfile，为避免覆盖，停止操作。' >&2
    exit 1
else
    FS=$(awk '$2=="/" {print $3; exit}' /proc/mounts)
    case "$FS" in
        ext4|xfs) ;;
        *) echo "根文件系统是 ${FS:-未知}，脚本只支持 ext4/xfs。" >&2; exit 1 ;;
    esac

    FREE=$(df -Pk / | awk 'NR==2 {print $4}')
    case "$FREE" in
        ''|*[!0-9]*) echo '无法检测根分区空闲空间。' >&2; exit 1 ;;
    esac
    [ "$FREE" -ge 5242880 ] || {
        echo '根分区空闲不足 5 GiB，停止操作。' >&2; exit 1;
    }

    echo '正在创建 4 GiB Swap 文件……'
    umask 077
    ACTIVE=0
    trap '[ "$ACTIVE" -eq 1 ] || rm -f "$SWAP"' EXIT
    dd if=/dev/zero of="$SWAP" bs=1M count=4096
    chmod 600 "$SWAP"
    mkswap "$SWAP"
    swapon "$SWAP"
    ACTIVE=1
    trap - EXIT
fi

if ! awk -v p="$SWAP" '$1==p && $3=="swap" {x=1} END {exit !x}' /etc/fstab; then
    printf '%s\n' "$SWAP none swap defaults 0 0" >> /etc/fstab
fi
rc-update add swap boot
printf '\n配置完成，当前内存与 Swap：\n'
free -h
cat /proc/swaps
