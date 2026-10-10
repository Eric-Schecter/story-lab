# 雾海传说

从本机 fishing 游戏版本 `333e97f6ee6605843e7b0d9f73eaac3e825cff5d` 整理。原游戏没有改动，原文快照及 SHA-256 存于 `source/`。

## 体验

用 Inky 打开 `ink/fishing.ink`，点击右侧选项逐步推进。六章主线、五份漂流瓶线索、两条支线和三个结局都保留。按钮上的“模拟完成”只跳过实际钓鱼、交易、航行和建设，方便审阅剧情。

想看隐藏结局：调查时读完五份碎片，并选择模拟补全图鉴，再返回主线。少一份碎片或未补全图鉴时，柔光选项锁定。

## articy 状态

原生工程为 `articy/project/ProjectInfo.aph`（Fishing - Fog Sea），已在 articy 4.3.16 中成功导入并保存：44个剧情/资料节点、5个人物实体，导入报告无错误。

在左侧展开 `Flow → 雾海传说｜剧情总览` 可浏览六章主线、两条支线与矛盾审阅节点；`Entities` 保存人物卡。当前可浏览章节和原文，尚未添加流程连线、可执行条件及模拟器。连接关系另存于 `design/story-model.json`；互动试玩使用 Inky。

`articy/fishing-import-fixed.xlsx` 是本次验证成功的导入文件，项目标识匹配上述原生工程。不要再次导入：空ID行会新建重复节点。`fishing-import.xlsx` 为修复前的生成文件。

## 可重复生成与检查

在仓库根目录运行 `python3 tools/build_fishing.py`，再使用 Inky 附带 inklecate 编译 `ink/fishing.ink`。运行 `python3 tools/check_fishing.py` 可验证三种结局及隐藏结局锁定边界。

`tools/build_articy_import.mjs <articy官方往返模板路径>` 用 bundled artifact-tool 生成导入候选文件。随后运行 `python3 tools/fix_articy_headers.py stories/fishing/articy/fishing-import.xlsx stories/fishing/articy/project/ProjectInfo.aph`，修复空模板名并匹配目标工程标识。新建独立工程时应使用目标工程自身的往返模板。
