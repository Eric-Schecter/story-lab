# GitHub Pages 部署

远程仓库：<https://github.com/Eric-Schecter/story-lab>

首次发布前，在仓库 Settings → Pages → Build and deployment 中将 Source 设为 **GitHub Actions**。

将本地 `main` 推送到 `origin` 后，`Deploy GitHub Pages` 工作流会构建并部署网页。后续推送到 `main` 会更新网站，也可在 Actions 页面手动运行工作流。本项目默认不自动推送。

预期访问地址：<https://eric-schecter.github.io/story-lab/>。只有工作流部署成功后，才代表网站已上线。

本地检查构建：

```sh
npm ci --prefix web/flow
node tools/build_pages.mjs
```

部署目录为 `dist-pages/`，仅含目录、试玩、流程图及所需资源；不发布原始资料、设计文档或 articy 工程。部署路径默认 `/story-lab/`，可通过 `PAGES_BASE` 指定。根目录本地开发入口保持原样。

参考 audio-lab 的项目子路径与构建产物发布方式；本仓库使用 GitHub Actions 部署，无需在本地手动维护发布分支。
