// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get tabBrowse => '浏览';

  @override
  String get tabDownloads => '下载';

  @override
  String get tabLibrary => '书架';

  @override
  String queueCount(int count) {
    return '下载队列中有 $count 卷';
  }

  @override
  String get browseHome => '网站首页';

  @override
  String get browseBack => '返回';

  @override
  String get downloadVolumesTooltip => '下载分卷';

  @override
  String get download => '下载';

  @override
  String get retry => '重试';

  @override
  String get open => '打开';

  @override
  String get view => '查看';

  @override
  String get browseBooks => '浏览书籍';

  @override
  String get errorPageDidNotLoad => '页面加载失败，请点击“重试”。';

  @override
  String get errorNoInternet => '无网络连接。请检查 Wi‑Fi 后点击“重试”。';

  @override
  String get errorTooSlow => '网站响应超时，请点击“重试”。';

  @override
  String get errorBlocked => '请求被网站拦截。请先在“浏览”中打开该书页面，再点击“重试”。';

  @override
  String get errorTooManyRequests => '请求过于频繁，请稍候一分钟后点击“重试”。';

  @override
  String get errorNotFound => '网站上未找到该页面。';

  @override
  String get errorPageChanged => '网站页面结构已变更，应用可能需要更新。';

  @override
  String get errorCouldNotSave => '无法保存文件，请检查手机存储空间。';

  @override
  String get errorFileMissing => '该文件已不在 Download/LightNovel 中，请重新下载此卷。';

  @override
  String get errorNoReader => '未找到可打开 EPUB 文件的应用，请安装阅读器（如 eBoox）。';

  @override
  String get errorCancelled => '已取消。';

  @override
  String get errorSomethingWentWrong => '发生错误，请点击“重试”。';

  @override
  String get clear => '清除';

  @override
  String get clearTooltip => '移除已保存的项目，文件将保留。';

  @override
  String get downloadsEmptyTitle => '暂无下载任务';

  @override
  String get downloadsEmptyMessage => '在“浏览”中打开书籍并点击“下载”。分卷将在此按顺序排队，逐卷下载。';

  @override
  String downloadVolumes(int count) {
    return '下载 $count 卷';
  }

  @override
  String downloadMerged(int count) {
    return '下载 $count 卷并合并为一个 EPUB';
  }

  @override
  String get thisBook => '本书';

  @override
  String siteId(String bookId) {
    return 'LINOVELIB #$bookId';
  }

  @override
  String authorAndSiteId(String author, String bookId) {
    return '$author · LINOVELIB #$bookId';
  }

  @override
  String get readingContents => '正在读取目录…';

  @override
  String get selectAll => '全选';

  @override
  String chapterCount(int count) {
    return '$count 章';
  }

  @override
  String get markInDownloads => ' · 已在下载队列中';

  @override
  String get markSaved => ' · 已保存';

  @override
  String cancelTitle(String title) {
    return '取消下载“$title”？';
  }

  @override
  String get cancelRunning => '下载将在下一章开始前停止，不会保存任何内容。';

  @override
  String get cancelWaiting => '该卷将从下载队列中移除。';

  @override
  String get cancelDownload => '取消下载';

  @override
  String get keep => '继续下载';

  @override
  String get cancelDownloadTooltip => '取消下载';

  @override
  String get statusWaiting => '等待中';

  @override
  String get statusSaved => '已保存';

  @override
  String get statusFailed => '失败';

  @override
  String get savedToFolder => '已保存到 Download/LightNovel';

  @override
  String volumesAdded(int count) {
    return '已添加 $count 卷';
  }

  @override
  String volumesAddedMerged(int count) {
    return '已添加 $count 卷，将合并为一个 EPUB';
  }

  @override
  String savedVolume(String title) {
    return '已保存 $title';
  }

  @override
  String get settings => '设置';

  @override
  String get libraryEmptyTitle => '暂无已下载的分卷';

  @override
  String get libraryEmptyMessage =>
      '下载的分卷将保存至 Download/LightNovel，并在此按书籍分组显示，可使用阅读器打开。重新安装应用后，请在“设置 → 书架文件夹”中重新选择该文件夹以恢复分卷。';

  @override
  String volumeCount(int count) {
    return '$count 卷';
  }

  @override
  String get opensInReader => '在阅读器中打开';

  @override
  String get showVolumes => '展开分卷';

  @override
  String get hideVolumes => '收起分卷';

  @override
  String savedOn(String date) {
    return '保存于 $date';
  }

  @override
  String dayMonth(String day, String month) {
    return '$month月$day日';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get mergeVolumes => '合并分卷';

  @override
  String get mergeVolumesDetail => '同时勾选的分卷将合并为一个 EPUB，每卷在目录中单独成节。';

  @override
  String get theme => '主题';

  @override
  String get themeDetail => '“系统”将跟随手机的深色模式设置。';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get language => '语言';

  @override
  String get languageDetail => '仅更改应用界面语言，书名和网站内容不受影响。';

  @override
  String get about => '关于';

  @override
  String get aboutDetail => '项目依赖与开源许可证信息。';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutWhat => '浏览 linovelib，将分卷连同插图下载为 EPUB，并使用阅读器阅读。';

  @override
  String get aboutDownloadOnly =>
      'Bunko 仅用于下载。请使用阅读器阅读已保存的分卷；不建议在 Bunko 内的网站上阅读章节，网站检测到广告被屏蔽时可能会使页面无法滚动。';

  @override
  String get aboutBuiltOn =>
      '基于 Montaro2017 的 bili_novel_packer（MIT 许可证）构建。该项目负责读取网站内容、还原段落顺序并生成 EPUB。';

  @override
  String get aboutPersonal => '下载内容仅供个人阅读，请勿分享。';

  @override
  String get openSourceLicences => '开源许可证';

  @override
  String noticeDownloading(String title) {
    return '正在下载 $title';
  }

  @override
  String noticeMoreWaiting(int percent, int count) {
    return '$percent% · 另有 $count 卷等待中';
  }

  @override
  String volumeNumber(String number) {
    return '第$number卷';
  }

  @override
  String get libraryFolder => '书架文件夹';

  @override
  String get libraryFolderDetail =>
      '下载的文件保存在此文件夹，书架会列出其中的 EPUB。重新安装 Bunko 后，请重新选择此文件夹以恢复已保存的分卷。';

  @override
  String get changeFolder => '更改';

  @override
  String get useDefaultFolder => '恢复默认';
}
