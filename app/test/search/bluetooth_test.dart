// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';

import 'package:pub_dartlang_org/search/index_simple.dart';
import 'package:pub_dartlang_org/search/text_utils.dart';
import 'package:pub_dartlang_org/shared/search_service.dart';

void main() {
  group('bluetooth', () {
    SimplePackageIndex index;

    setUpAll(() async {
      index = new SimplePackageIndex();
      await index.addPackage(new PackageDocument(
        package: 'flutter_blue',
        version: '0.2.3',
        description: compactDescription('Bluetooth plugin for Flutter.'),
      ));
      await index.addPackage(new PackageDocument(
        package: 'smooth_scroll',
        version: '0.0.3',
        description: compactDescription(
            'A Dart library for smooth scroll effect on a web page.'),
      ));
      await index.merge();
    });

    test('bluetooth', () async {
      final PackageSearchResult result = await index.search(
          new SearchQuery.parse(query: 'bluetooth', order: SearchOrder.text));
      expect(JSON.decode(JSON.encode(result)), {
        'indexUpdated': isNotNull,
        'totalCount': 1,
        'packages': [
          {
            'package': 'flutter_blue',
            'score': closeTo(0.916, 0.001),
          },
        ],
      });
    });
  });
}
