import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _resolvedBaseUrl;
  static const String _cachedUrlKey = "resolved_backend_url";

  Future<String> get baseUrl async {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;

    // Try to load cached URL
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString(_cachedUrlKey);
    if (cachedUrl != null) {
      // Verify it is still active asynchronously (ping)
      _probeUrl(cachedUrl).then((isActive) {
        if (!isActive) {
          _resolvedBaseUrl = null;
          prefs.remove(_cachedUrlKey);
        }
      });
      _resolvedBaseUrl = cachedUrl;
      return cachedUrl;
    }

    // Resolve base URL dynamically (only cache a URL that actually responded)
    final resolved = await resolveBaseUrl();
    if (resolved != null) {
      _resolvedBaseUrl = resolved;
      await prefs.setString(_cachedUrlKey, resolved);
      return resolved;
    }

    // No backend found yet: fall back to localhost WITHOUT caching so we
    // keep re-discovering once the backend comes online.
    return 'http://127.0.0.1:8000';
  }

  Future<void> _invalidateCachedUrl() async {
    _resolvedBaseUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUrlKey);
  }

  Future<bool> _probeUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map && data['status'] == 'Running';
      }
    } catch (_) {}
    return false;
  }

  Future<String?> resolveBaseUrl() async {
    final Set<String> candidates = {
      // Configured host (physical phone on same Wi-Fi)
      'http://${AppConstants.backendHost}:8000',
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000',
      'http://192.168.56.1:8000',
    };

    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            final ip = address.address;
            final parts = ip.split('.');
            if (parts.length == 4) {
              final subnet = "${parts[0]}.${parts[1]}.${parts[2]}";
              // Common gateways/host IPs
              candidates.add("http://$subnet.1:8000");
              candidates.add("http://$subnet.2:8000");
              candidates.add("http://$subnet.100:8000");
              candidates.add("http://$subnet.101:8000");
              candidates.add("http://$ip:8000");
            }
          }
        }
      }
    } catch (_) {}

    final completer = Completer<String?>();
    bool finished = false;

    void onDone(String url) {
      if (!finished) {
        finished = true;
        completer.complete(url);
      }
    }

    final candidateList = candidates.toList();

    // Run probes concurrently
    final List<Future> futures = [];
    for (var url in candidateList) {
      futures.add(
        _probeUrl(url).then((success) {
          if (success) {
            onDone(url);
          }
        }),
      );
    }

    // Wait for all to finish, or if one succeeds
    Future.wait(futures).then((_) {
      if (!finished) {
        finished = true;
        completer.complete(null); // No candidate responded
      }
    });

    // Set a global timeout of 5 seconds for the discovery phase
    Future.delayed(const Duration(seconds: 5)).then((_) {
      if (!finished) {
        finished = true;
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Sends an HTTP request, retrying once against a freshly re-discovered
  /// backend when the cached URL turns out to be unreachable.
  Future<http.Response> _send(
    Map<String, String>? headers,
    Future<http.Response> Function(String base, Map<String, String> headers)
        send,
  ) async {
    final base = await baseUrl;
    final h = await _authHeaders(headers);
    try {
      return await send(base, h);
    } on SocketException {
      // Connection refused / network unreachable -> re-discover and retry once
      await _invalidateCachedUrl();
      final newBase = await baseUrl;
      return send(newBase, h);
    } on http.ClientException {
      await _invalidateCachedUrl();
      final newBase = await baseUrl;
      return send(newBase, h);
    }
  }

  Future<Map<String, String>> _authHeaders(Map<String, String>? headers) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final Map<String, String> finalHeaders = headers != null ? Map.from(headers) : {};
    if (token != null && token.isNotEmpty) {
      finalHeaders["Authorization"] = "Bearer $token";
    }
    if (!finalHeaders.containsKey("Content-Type")) {
      finalHeaders["Content-Type"] = "application/json";
    }
    return finalHeaders;
  }

  // Helper methods for HTTP verbs using the resolved baseUrl
  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    return _send(
      headers,
      (base, h) => http.get(Uri.parse("$base$path"), headers: h),
    );
  }

  Future<http.Response> post(String path, {Map<String, String>? headers, Object? body}) {
    return _send(
      headers,
      (base, h) => http.post(Uri.parse("$base$path"), headers: h, body: body),
    );
  }

  Future<http.Response> put(String path, {Map<String, String>? headers, Object? body}) {
    return _send(
      headers,
      (base, h) => http.put(Uri.parse("$base$path"), headers: h, body: body),
    );
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) {
    return _send(
      headers,
      (base, h) => http.delete(Uri.parse("$base$path"), headers: h),
    );
  }
}
