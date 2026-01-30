import 'dart:io';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'app.dart';
import 'engine.dart';

class DesktopScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 对于Flutter没有捕捉到的错误，弹出系统原生对话框
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      final statck = trimStackTrace(stackTrace);
      engine.error('$error\n$statck');
      alertNativeError(error, statck);
      return false;
    };

    // 对于Flutter捕捉到的错误，弹出Flutter绘制的自定义对话框
    FlutterError.onError = (details) {
      engine.error(details.toString());
      FlutterError.presentError(details);
      alertFlutterError(details);
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => engine),
        ],
        child: fluent.FluentTheme(
          data: fluent.FluentThemeData(),
          child: MaterialApp(
            scrollBehavior: DesktopScrollBehavior(),
            debugShowCheckedModeBanner: false,
            home: GameApp(key: mainKey),
            // 控件绘制时发生错误，用一个显示错误信息的控件替代
            builder: (context, widget) {
              ErrorWidget.builder = (FlutterErrorDetails details) {
                String stack = '';
                if (details.stack != null) {
                  stack = trimStackTrace(details.stack!);
                }
                final Object exception = details.exception;
                Widget error = ErrorWidget.withDetails(
                    message: '$exception\n$stack',
                    error: exception is FlutterError ? exception : null);
                if (widget is Scaffold || widget is Navigator) {
                  error = Scaffold(body: Center(child: error));
                }
                return error;
              };
              if (widget != null) return widget;
              throw ('error trying to create error widget!');
            },
          ),
        ),
      ),
    );
  }, alertNativeError);
}
