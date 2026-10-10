# GitHub Pages 部署

与 audio-lab 一样，使用 `gh-pages` 工具发布构建产物到远程 `gh-pages` 分支。

远程仓库：<https://github.com/Eric-Schecter/story-lab>

```sh
npm install
npm run deploy
```

`deploy` 会先构建网页，再推送 `dist-pages/` 到 `origin` 的 `gh-pages` 分支。它是明确的发布操作；普通提交和推送 `main` 不会自动更新网站。

首次发布后，在仓库 Settings → Pages → Build and deployment 中将 Source 设为 **Deploy from a branch**，Branch 选择 **gh-pages**，Folder 选择 **/ (root)** 并保存。此前选择过 GitHub Actions 的，也需要切换到分支发布。

网站地址：<https://eric-schecter.github.io/story-lab/>。分支上传成功与网站上线是两个步骤，以 GitHub Pages 部署成功为准。

仅检查构建可以运行 `npm run build`。发布内容仅含网页及所需资源，不含原始资料、设计文档或 articy 工程。部署路径默认 `/story-lab/`；本地开发入口保持原样。

网页现使用单页 Hash 路由：根地址为预加载入口，`#/home` 为目录，`#/play?story=…&chapter=…` 为试玩，`#/flow?story=…&chapter=…` 为流程图。可直接访问、刷新或使用浏览器前进后退。旧 `.html` 地址保留为跳转入口；无需服务器路由回退配置。
