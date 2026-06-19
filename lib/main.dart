import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebPage(),
    );
  }
}

class WebPage extends StatefulWidget {
  const WebPage({super.key});

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  static const MethodChannel _channel = MethodChannel('deeplink.channel');

  InAppWebViewController? _webViewController;
  bool _deepLinkHandled = false;

  @override
  void initState() {
    super.initState();
    _handleDeepLinkOnce();
  }

  Future<void> _handleDeepLinkOnce() async {
    try {
      final String? launchUrl = await _channel.invokeMethod<String>(
        'getInitialUrl',
      );

      if (launchUrl != null &&
          launchUrl.startsWith('https://rroyalcasina.com/software/')) {
        // Wait until WebView exists
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_webViewController != null && !_deepLinkHandled) {
            _deepLinkHandled = true;
            _webViewController!.loadUrl(
              urlRequest: URLRequest(url: WebUri(launchUrl)),
            );
          }
        });
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_webViewController != null &&
            await _webViewController!.canGoBack()) {
          _webViewController!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: InAppWebView(
            onLoadStart: (controller, url) {
              print("LOAD START: $url");
            },

            onLoadStop: (controller, url) async {
              print("LOAD STOP: $url");
            },

            onReceivedError: (controller, request, error) {
              print("ERROR: ${error.description}");
            },

            onReceivedHttpError: (controller, request, response) {
              print("HTTP ERROR: ${response.statusCode}");
            },

            onConsoleMessage: (controller, consoleMessage) {
              print("CONSOLE: ${consoleMessage.message}");
            },
            initialUrlRequest: URLRequest(
              url: WebUri('https://rroyalcasina.com/software/'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri.toString().startsWith(
                'https://rroyalcasina.com/software/',
              )) {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
          ),
        ),
      ),
    );
  }
}
