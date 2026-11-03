# Bunko

[简体中文](README.md) | English

Browse linovelib on your Android phone and download light novel volumes as
EPUB, with the illustrations in place, to read in any EPUB reader.

Bunko (文庫) is named after the small paperback format light novels are
published in.

## What it does

- **Browse** the site (www.bilinovel.net) inside the app to find books, with
  its ad and tracker hosts blocked.
- **Download** from a book page: tick the volumes you want, and each one is
  saved as an EPUB with its illustrations inline and its paragraphs in the
  right order. Settings → Merge volumes saves the ticked volumes as one EPUB
  instead.
- Downloads wait in a queue and keep going when you switch apps, with a
  notification showing the progress.
- **Library** lists the EPUBs in the library folder by book; tap a book to
  fold or open it. Tap a volume to open it in the EPUB reader you pick.
- **Settings** picks the library folder, a light or dark theme (or follows
  the phone), and switches the app between Chinese and English.

Bunko is made for downloading. Read the saved EPUBs in your reader app:
reading chapters on the site inside Bunko is not recommended, because the
site can stop the page scrolling when it notices its ads are blocked.

## The library folder

Downloads are saved to `Download/LightNovel` by default, and the app asks for
no storage permission. Settings → Library folder → CHANGE opens Android's
folder picker to choose another folder: new downloads are saved there, and
Library lists every EPUB inside it.

After reinstalling Bunko, Android hides the files saved before from it. Pick
the folder again in Settings → Library folder, and Library reads every volume
back from the files.

The books are in simplified Chinese, as on the site.

## Install

Download the APK from [Releases](../../releases), open it on the phone and
allow the install. It needs Android 10 or newer.

Downloads are slow on purpose. Bunko keeps to about 15 page and 10 image
requests a minute, the limits bili_novel_packer uses, so a volume takes a few
minutes. While one chapter's pictures download, the text of the next few
chapters loads, so the two limits overlap.

If downloads stop while Bunko is not on screen, your phone's battery manager
may be pausing it. Honor, Huawei, Xiaomi and some other brands do this even
to apps showing a notification. Allow Bunko to run in the background in the
phone's battery settings; [dontkillmyapp.com](https://dontkillmyapp.com) has
the steps for each brand.

## Build from source

You need Flutter 3.44 (Dart 3.12) and the Android SDK.

```bash
flutter pub get
flutter test
flutter build apk --release
```

Before a commit, also run `flutter analyze` and
`dart run tool/check_imports.dart`, which checks that each layer imports only
the layers below it.

Release builds are signed with the key that `android/key.properties` names
(see `android/key.properties.example`); without that file they use the debug
key.

The app's words are in `lib/l10n/app_zh.arb` (Chinese) and
`lib/l10n/app_en.arb` (English).

## Credits

Built on [bili_novel_packer](https://github.com/Montaro2017/bili_novel_packer)
by Montaro2017 (MIT licence), which reads the site, restores the paragraph
order and builds each EPUB. The Archivo font is under the SIL Open Font
License. [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) has the details.
The app icon was made for Bunko with an AI image tool.

## Please note

- Bunko is not affiliated with linovelib or bilinovel.
- The novels belong to their authors and publishers. Bunko contains no book
  content: it saves what you can already read on the site, for your own
  reading. Please don't share the files you download.

## Licence

MIT. See [LICENSE](LICENSE).
