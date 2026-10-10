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

目前《风与契约》为原创序章，《雾海传说》为原游戏剧情审阅，任务按钮模拟玩法目标；后者使用原游戏的水彩钓鱼场景作为封面与试玩背景。

## 故事流程图

目录中《风与契约》卡片可进入 `/web/flow/`，使用 React Flow + ELK.js 浏览完整流程、点击节点查看原文与变量、切换三条决策路线。图为审阅工具，不执行 Ink 条件，不影响试玩状态。

修改本故事 `.ink` 后运行 `python3 tools/build_wind_flow.py` 重新提取图数据（当前提取器针对本剧本所用的 knot、选项和直接跳转语法，不是通用 Ink 解析器）。画面标题、节点类型与路线结算为整理标注，源文件 SHA-256 和行号保存在 `web/flow/story.json`。

修改前端时在 `web/flow` 执行 `npm ci`、`npm run build`。依赖与许可证来自 npm 官方包，构建输出 `dist/` 提交到 Git，日常浏览无需安装 Node 或联网。Fishing 尚未接入此流程图入口。

## 统一预加载

目录、试玩与故事流程使用 `web/preloader/Preloader.jsx`。预加载入场仅在当前标签页首次访问时播放，完成后以 sessionStorage 记录；切换作品、返回目录、查看流程或刷新均跳过完整预加载；站内链接切换使用独立的 250ms 淡出、450ms 淡入，返回历史页面也会恢复。组件与样式改编自本机 `audio-lab/src/Preloader.tsx`、`src/preloader.css`，保留黑底标题、资源进度与淡出动效；audio-lab 未修改。这里不加载 audio-lab 的音频，按页面加载实际封面、背景、头像、Ink JSON 或流程数据。每个资源独立超时，失败后仍可进入页面；离开加载界面后恢复滚动和键盘交互。

使用已有 React 构建环境：`npm ci --prefix web/flow` 后运行 `npm run build:preloader --prefix web/flow`。产物保存在 `web/preloader/dist/`，静态页面以独立 React 挂载点接入，无需整体迁移。
