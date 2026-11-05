# Bunko

简体中文 | [English](README.en.md)

在 Android 手机上浏览 linovelib，将轻小说分卷连同插图下载为 EPUB，并使用任意 EPUB 阅读器阅读。

Bunko（文庫）得名于轻小说出版常用的小开本平装书。

## 功能

- **浏览**：在应用内访问网站 (www.bilinovel.net) 查找书籍，并屏蔽广告与跟踪域名。
- **下载**：在书籍页面勾选所需分卷，每卷保存为一个 EPUB，插图保留在正文原位置，段落顺序正确。开启“设置 → 合并分卷”后，所勾选的分卷将合并为一个 EPUB。
- 下载任务按顺序排队，切换至其他应用时仍会继续，并在通知栏显示进度。
- **书架**：按书籍分组列出书架文件夹中的 EPUB，点击书名可展开或收起。点击分卷即可选择阅读器打开。
- **设置**：可选择书架文件夹、浅色或深色主题（或跟随系统），界面语言可在中文与英文之间切换。

Bunko 仅用于下载。请使用阅读器阅读已保存的 EPUB；不建议在 Bunko 内的网站上阅读章节，因为网站检测到广告被屏蔽时可能会使页面无法滚动。

## 书架文件夹

下载的文件默认保存在 `Download/LightNovel`，应用无需存储权限。在“设置 → 书架文件夹 → 更改”中可通过 Android 文件夹选择器选择其他文件夹：新的下载将保存至该文件夹，书架会列出其中的所有 EPUB。

重新安装 Bunko 后，Android 会对其隐藏之前保存的文件。请在“设置 → 书架文件夹”中重新选择该文件夹，书架将从文件中读取并恢复所有分卷。

书籍内容与网站一致，为简体中文。

## 安装

从 [Releases](../../releases) 下载 APK，在手机上打开并允许安装。需要 Android 10 或更高版本。

下载速度经过有意限制。Bunko 遵循 bili_novel_packer 的请求频率限制，即每分钟约 15 次页面请求和 10 次图片请求，因此每卷需要数分钟。下载某一章的图片时，后续几章的文本会同时加载，以充分利用两项限制。

若 Bunko 在后台时下载停止，可能是手机的电池管理暂停了应用。荣耀、华为、小米等品牌即使应用显示通知也可能如此。请在手机的电池设置中允许 Bunko 后台运行，各品牌的设置方法可参阅 [dontkillmyapp.com](https://dontkillmyapp.com)。

## 从源码构建

需要 Flutter 3.44（Dart 3.12）及 Android SDK。

```bash
flutter pub get
flutter test
flutter build apk --release
```

提交前请另行运行 `flutter analyze` 和 `dart run tool/check_imports.dart`，后者用于检查各层仅引用其下层。

发布版本使用 `android/key.properties` 指定的密钥签名（格式见 `android/key.properties.example`）；缺少该文件时使用调试密钥。

界面文本位于 `lib/l10n/app_zh.arb`（中文）和 `lib/l10n/app_en.arb`（英文）。

## 致谢

本项目基于 Montaro2017 的 [bili_novel_packer](https://github.com/Montaro2017/bili_novel_packer)（MIT 许可证）构建，该项目负责读取网站内容、还原段落顺序并生成 EPUB。Archivo 字体采用 SIL Open Font License。详情请参阅 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。应用图标为本项目使用 AI 图像工具制作。

## 注意事项

- Bunko 与 linovelib、bilinovel 无任何关联。
- 小说版权归作者及出版方所有。Bunko 不包含任何书籍内容，仅将网站上可阅读的内容保存供个人阅读。请勿分享下载的文件。

## 许可证

MIT，详见 [LICENSE](LICENSE)。
