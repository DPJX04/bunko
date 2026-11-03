import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/browse/page_title.dart';

void main() {
  test('keeps the part before the first underscore', () {
    expect(shortPageTitle('酒醉就旅行的今里小姐_结城弘作品_GA文库_哔哩轻小说'), '酒醉就旅行的今里小姐');
    expect(shortPageTitle('轻小说文库排行榜_哔哩轻小说'), '轻小说文库排行榜');
  });

  test('leaves a title without underscores as it is', () {
    expect(shortPageTitle('哔哩轻小说'), '哔哩轻小说');
  });

  test('a title starting with an underscore is kept whole', () {
    expect(shortPageTitle('_draft'), '_draft');
  });
}
