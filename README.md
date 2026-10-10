# Story Lab

这里集中管理游戏剧情的原文、Inky 试玩和 articy 故事板。所有完成的修改使用本地 Git commit 记录。

- `stories/fishing/`：从 fishing 现有游戏整理的《雾海传说》。从 `ink/fishing.ink` 开始试玩。
- `stories/wind-and-contract/`：《风与契约》商人船长原型。
- `articy-wind-contract/`：现有《风与契约》原生 articy 工程，因应用正在打开而暂保留路径。
- `tools/`：可重复生成、校验剧情的工具。

每个作品使用 `source/`（来源）、`design/`（结构与说明）、`ink/`（试玩）、`articy/`（原生工程和导入）分层。Inky 用 File → Open 打开 `.ink`。articy 用打开工程选择对应 `ProjectInfo.aph`。

Git 操作：修改前 `git status`；完成后先验证，再 `git add <文件>` 与 `git commit -m "描述实际变化"`。Git 是本地历史，当前没有配置远程备份。

## 网页故事目录

在仓库根目录运行 `python3 -m http.server 8765 --bind 127.0.0.1`，打开 http://127.0.0.1:8765/ 。首页选择故事，试玩页可随时返回目录。

`web/stories.js` 是作品登记表：新增作品时填写 ID、标题、人物、简介、编译后 Ink JSON 路径及头像映射。`web/player.js` 是共用 AVG 播放器，人物缺少头像时显示剪影，旁白使用整行文字。各作品原文、剧本和 articy 工程继续保存在 `stories/<作品>/`。

目前《风与契约》为原创序章，《雾海传说》为原游戏剧情审阅，任务按钮模拟玩法目标；后者暂时共用港口背景，不代表原游戏美术。
