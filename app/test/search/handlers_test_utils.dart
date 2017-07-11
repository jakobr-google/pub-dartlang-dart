// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;

import 'package:pub_dartlang_org/search/handlers.dart';

Future<shelf.Response> issueGet(String path) async {
  final uri = 'https://search-dot-dartlang-pub.appspot.com$path';
  final request = new shelf.Request('GET', Uri.parse(uri));
  return searchServiceHandler(request);
}

Future<shelf.Response> issuePost(String path) async {
  final uri = 'https://search-dot-dartlang-pub.appspot.com$path';
  final request = new shelf.Request('POST', Uri.parse(uri));
  return searchServiceHandler(request);
}