// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_dartlang_org.server_common;

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:gcloud/service_scope.dart';
import 'package:gcloud/storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../shared/configuration.dart';
import '../shared/package_memcache.dart';
import '../shared/service_utils.dart';

import 'backend.dart';
import 'oauth2_service.dart';
import 'search_service.dart';
import 'upload_signer_service.dart';

final TemplateLocation = Platform.script.resolve('../views').toFilePath();

const List<String> SCOPES = const [
  'https://www.googleapis.com/auth/cloud-platform',
  'https://www.googleapis.com/auth/datastore',
  'https://www.googleapis.com/auth/devstorage.full_control',
  'https://www.googleapis.com/auth/userinfo.email',
];

final Logger logger = new Logger('pub');

void initOAuth2Service() {
  // The oauth2 service is used for getting an email address from an oauth2
  // access token (which the pub client sends).
  final client = new http.Client();
  registerOAuth2Service(new OAuth2Service(client));
  registerScopeExitCallback(client.close);
}

void initStorage(String projectId, authClient) {
  registerStorageService(new Storage(authClient, projectId));
}

Future initSearchService() async {
  final searchService = await searchServiceViaApiKeyFromDb();
  registerSearchService(searchService);
  registerScopeExitCallback(searchService.httpClient.close);
}

void initBackend({UIPackageCache cache}) {
  registerBackend(new Backend(dbService, tarballStorage, cache: cache));
}

/// Looks at [request] and if the 'Authorization' header was set tries to get
/// the user email address and registers it.
Future registerLoggedInUserIfPossible(shelf.Request request) async {
  final authorization = request.headers['authorization'];
  if (authorization != null) {
    final parts = authorization.split(' ');
    if (parts.length == 2 && parts.first.trim().toLowerCase() == 'bearer') {
      final accessToken = parts.last.trim();

      final email = await oauth2Service.lookup(accessToken);
      if (email != null) {
        registerLoggedInUser(email);
      }
    }
  }
}

Future<String> obtainServiceAccountEmail() async {
  final http.Response response = await http.get(
      'http://metadata/computeMetadata/'
      'v1/instance/service-accounts/default/email',
      headers: const {'Metadata-Flavor': 'Google'});
  return response.body.trim();
}

Future withProdServices(Future fun()) {
  return withAppEngineServices(() {
    if (!envConfig.hasGcloudKey) {
      throw 'Missing GCLOUD_* environments for package:appengine';
    }
    return withCorrectDatastore(() {
      registerUploadSigner(
          new ServiceAccountBasedUploadSigner(activeConfiguration.credentials));
      initBackend();
      return fun();
    });
  });
}