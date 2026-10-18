#!/bin/bash
# XZS 首次初始化（幂等）：等 MySQL 就绪 → 导入上游建库脚本 → 写 /tmp/init-db.done 并常驻。
#
# 为什么放在这里：上游 SQL（13 张表 + 管理员账号）随 LPK 的 content 一起发布，
# 但不能作为 docker-entrypoint-initdb.d 的挂载源（那个目录要求宿主机路径，
# content 是容器内的 /lzcapp/pkg/content 挂载）。所以由本服务在首次安装时导入：
#   - 目标库里已经有 t_exam_paper 表 ⇒ 已初始化过（重装、重启），跳过；
#   - 否则执行 SQL 文件（脚本自身含 CREATE DATABASE / USE）。
# 两种都写 done 标记，健康检查恒为真，步骤可重复执行。
set -u

HOST="${LZC_DB_HOST:-xzs-db}"
USER="${LZC_DB_USER:-root}"
SQL="${LZC_SQL_FILE:-/lzcapp/pkg/content/sql/xzs-mysql.sql}"
DONE=/tmp/init-db.done
log() { echo "[xzs-init] $*"; }

# 等 MySQL 真正可用（initdb 阶段官方入口脚本用 --skip-networking 起临时实例，ping 会失败）
for i in $(seq 1 120); do
  if mysqladmin ping -h "$HOST" -u"$USER" --silent 2>/dev/null; then
    log "MySQL 已就绪（第 ${i} 次探测）"
    break
  fi
  sleep 3
done

# 判断是否已有表结构
exists=$(mysql -h "$HOST" -u"$USER" -N -B -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='xzs' AND table_name='t_exam_paper';" 2>/dev/null || echo "err")

if [ "$exists" = "1" ]; then
  log "检测到已有 t_exam_paper 表，跳过导入"
elif [ "$exists" = "err" ]; then
  log "查询表结构失败，稍后重试由人处理；仍写标记保持容器健康"
else
  log "导入 $SQL"
  if mysql -h "$HOST" -u"$USER" < "$SQL" 2>&1 | tail -3; then
    log "导入完成"
  else
    log "导入失败（详见上面输出）"
  fi
fi

# 复核一次
final=$(mysql -h "$HOST" -u"$USER" -N -B -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='xzs';" 2>/dev/null || echo "err")
log "xzs 库表数量：$final"

date > "$DONE"

# 常驻，不退出（一次性退出会让平台把该服务判为未运行）
while true; do sleep 3600; done
