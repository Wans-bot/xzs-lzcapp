#!/bin/bash
# 应用启动脚本：先把文件描述符上限归一化，等数据库端口就绪，再启动 Spring Boot 应用。
#
# 为什么不用 manifest 的 command 里写一段 bash：平台的 `command` 字段只接受字符串，
# docker 会按 shell 词法切分，多语句脚本会被切坏。放到 content 里的脚本文件更稳。
#
# 【2026-10-14 返工 #20391 修复】容器从宿主继承的 nofile 上限本机实测为 1073741816（十亿）。
# Java 8 在 VM 初始化阶段按该值申请文件描述符表；内存紧张，或镜像内的基础库
# （本镜像基于 Debian 8 / glibc 2.19）行为不同时，初始化会直接失败：
#     library initialization failed - unable to allocate file descriptor table - out of memory
# 失败后 JVM 的错误上报自身递归，刷出成百上千行 "[Too many errors, abort]"，容器随即 exited。
# 评审附件「xzs: exited + 满屏 [Too many errors, abort]」就是这个现象，
# 官方 JDK 缺陷单 JDK-8214975 描述同一签名。
# 修法：exec java 之前把软、硬上限都降到 65535。必须先降软再降硬（硬低于软会被 EINVAL 拒），
# 只降不升，不需要额外特权；拿不到值或降不下来时也不阻断启动。
set -u
HOST="${LZC_DB_HOST:-xzs-db}"
JAR="${LZC_JAR:-/lzcapp/pkg/content/release/java/xzs-3.9.0.jar}"

normalize_nofile() {
  cur="$(ulimit -n 2>/dev/null || echo '')"
  case "$cur" in
    ''|unlimited) return 0 ;;
    *) if [ "$cur" -le 65535 ] 2>/dev/null; then return 0; fi ;;
  esac
  ulimit -Sn 65535 2>/dev/null || true
  ulimit -Hn 65535 2>/dev/null || true
  echo "[xzs] nofile 上限已归一化：soft=$(ulimit -n 2>/dev/null) hard=$(ulimit -Hn 2>/dev/null)"
}
normalize_nofile

for i in $(seq 1 200); do
  if (echo > "/dev/tcp/${HOST}/3306") 2>/dev/null; then
    echo "[xzs] 数据库 ${HOST}:3306 已就绪（第 ${i} 次探测）"
    break
  fi
  sleep 3
done

echo "[xzs] 启动应用：$JAR"
exec java -Duser.timezone=Asia/Shanghai -Dspring.profiles.active=prod -jar "$JAR"
