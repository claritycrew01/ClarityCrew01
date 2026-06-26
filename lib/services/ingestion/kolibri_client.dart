import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'import_models.dart';
import 'import_logger.dart';

class KolibriClient {
  final String baseUrl;
  final http.Client _client;
  final ImportLogger _log;
  final Duration _timeout;

  KolibriClient({
    this.baseUrl = 'https://contentworkshop.learningequality.org/api/public/v1',
    http.Client? client,
    required ImportLogger log,
    this._timeout = const Duration(seconds: 30),
  })  : _client = client ?? http.Client(),
        _log = log;

  Future<void> dispose() => _client.close();

  Future<List<KolibriContentNode>> search({
    required String query,
    String? kind,
    String language = 'en',
    int maxResults = 10,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _searchOnce(
            query: query,
            kind: kind,
            language: language,
            maxResults: maxResults);
      } on HttpException catch (e) {
        _log.warn('Kolibri API HTTP error (attempt $attempt/$maxRetries): $e');
      } on SocketException catch (e) {
        _log.warn('Kolibri network error (attempt $attempt/$maxRetries): $e');
      } on TimeoutException catch (e) {
        _log.warn('Kolibri timeout (attempt $attempt/$maxRetries): $e');
      } on FormatException catch (e) {
        _log.warn('Kolibri parse error (attempt $attempt/$maxRetries): $e');
      }

      if (attempt < maxRetries) {
        final delay = Duration(seconds: 2 * attempt);
        _log.info('Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }
    _log.error('Kolibri search failed after $maxRetries attempts: "$query"');
    return [];
  }

  Future<List<KolibriContentNode>> _searchOnce({
    required String query,
    String? kind,
    String language = 'en',
    int maxResults = 10,
  }) async {
    final params = <String, String>{
      'search': query,
      'language': language,
      'max_results': maxResults.toString(),
    };
    if (kind != null && kind.isNotEmpty) params['kind'] = kind;

    final uri = Uri.parse('$baseUrl/contentnode/').replace(queryParameters: params);
    _log.info('GET $uri');

    final response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw HttpException(
          'Kolibri returned ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];
    _log.info('Found ${results.length} Kolibri nodes for "$query"');

    return results
        .map((e) => KolibriContentNode.fromJson(e as Map<String, dynamic>))
        .where((n) => n.id.isNotEmpty)
        .toList();
  }

  Future<List<KolibriContentNode>> searchAllKinds({
    required String query,
    String language = 'en',
    int maxResultsPerKind = 5,
  }) async {
    final kinds = ['video', 'exercise', 'document', 'topic', 'html5'];
    final allResults = <KolibriContentNode>[];

    for (final kind in kinds) {
      final results = await search(
        query: query,
        kind: kind,
        language: language,
        maxResults: maxResultsPerKind,
      );
      allResults.addAll(results);
    }

    return allResults;
  }

  Future<String?> fetchThumbnailUrl(String nodeId) async {
    try {
      final uri = Uri.parse('$baseUrl/contentnode/$nodeId/');
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final node = KolibriContentNode.fromJson(body);
        return node.thumbnailUrl;
      }
    } catch (_) {}
    return null;
  }
}
