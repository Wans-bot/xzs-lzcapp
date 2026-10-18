# 学之思考试系统（XZS）打包说明与许可

本包由社区移植，应用本体为上游官方发行版，未修改上游源码。

| 项 | 值 |
| --- | --- |
| 上游项目 | https://github.com/mindskip/xzs-mysql |
| 上游版本 | 3.9.0（固定 commit `457ed2f1d69c`，2026-10-11） |
| 许可证 | AGPL-3.0（全文见同目录 `LICENSE`，上游 `LICENSE` 原样复制） |
| 应用镜像 | `registry.cn-hangzhou.aliyuncs.com/mindskip/java:1.8.0` 的中转副本（上游 compose 指定的 Java 运行环境） |
| 数据库镜像 | `mysql:8.0.33` 的中转副本（上游 compose 用同版本 MySQL） |
| 应用产物 | 上游 `release/java/xzs-3.9.0.jar`（40528745 B，git blob `ac089e3b…`），随本包 `content/release/java/` 发布，未做任何修改 |
| 建库脚本 | 上游 `sql/xzs-mysql.sql`（12727 B，git blob `d2aaaf24…`），随本包 `content/sql/` 发布 |
| 图标来源 | 上游 `source/vue/xzs-admin/src/assets/logo.png`（260×213，git blob `fdd86b9b…`）。上游仓库没有正方形图标，本包只做「画布补白边成正方形 + 双线性等比放大到 512×512」，不改动、不重绘图形 |

对应源码：AGPL-3.0，源码可从上面的上游项目地址获取，固定 commit `457ed2f1d69c` 即本包所用版本。

本包新增的内容仅为平台适配脚本：

- `init-db.sh`：首次安装时把上游建库脚本导入 MySQL（幂等，已有表结构则跳过）。
- `lazycat-injects/xzs-autologin.js`：管理端登录页免密登录与「切换账号」控件。
- `lazycat-injects/lzc-file-chooser-inject.js`：平台官方的网盘文件选择器注入（与其它已上架应用同一份脚本）。
