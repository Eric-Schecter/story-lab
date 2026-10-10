# 雾海传说

从本机 fishing 游戏版本 `333e97f6ee6605843e7b0d9f73eaac3e825cff5d` 整理。原游戏没有改动，原文快照及 SHA-256 存于 `source/`。

## 体验

用 Inky 打开 `ink/fishing.ink`，点击右侧选项逐步推进。六章主线、五份漂流瓶线索、两条支线和三个结局都保留。按钮上的“模拟完成”只跳过实际钓鱼、交易、航行和建设，方便审阅剧情。

想看隐藏结局：调查时读完五份碎片，并选择模拟补全图鉴，再返回主线。少一份碎片或未补全图鉴时，柔光选项锁定。

## articy 状态

`articy/fishing-import.xlsx` 根据 articy 自己导出的往返模板生成，包含44个流程/资料节点与5个人物实体。尚未成功通过应用内导入验证，不能视为原生工程。导入不包含流程连接和可执行脚本，连接关系保存在 `design/story-model.json`。

原作条件、任务ID和数据快照已保存。下一步是完成原生工程导入、排版与连线，再验证预览。不要重复导入未经处理的空ID表，以免产生重复节点。

## 可重复生成与检查

在仓库根目录运行 `python3 tools/build_fishing.py`，再使用 Inky 附带 inklecate 编译 `ink/fishing.ink`。运行 `python3 tools/check_fishing.py` 可验证三种结局及隐藏结局锁定边界。

`tools/build_articy_import.mjs <articy官方往返模板路径>` 用 bundled artifact-tool 生成导入候选文件。模板的项目标识属于当前风与契约工程，新建独立工程时应从目标工程重新导出模板。
