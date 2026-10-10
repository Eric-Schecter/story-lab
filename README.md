# Story Lab

这里集中管理游戏剧情的原文、Inky 试玩和 articy 故事板。所有完成的修改使用本地 Git commit 记录。

- `stories/fishing/`：从 fishing 现有游戏整理的《雾海传说》。从 `ink/fishing.ink` 开始试玩。
- `stories/wind-and-contract/`：《风与契约》商人船长原型。
- `articy-wind-contract/`：现有《风与契约》原生 articy 工程，因应用正在打开而暂保留路径。
- `tools/`：可重复生成、校验剧情的工具。

每个作品使用 `source/`（来源）、`design/`（结构与说明）、`ink/`（试玩）、`articy/`（原生工程和导入）分层。Inky 用 File → Open 打开 `.ink`。articy 用打开工程选择对应 `ProjectInfo.aph`。

Git 操作：修改前 `git status`；完成后先验证，再 `git add <文件>` 与 `git commit -m "描述实际变化"`。Git 是本地历史，当前没有配置远程备份。
