import 'dart:io';

import 'package:winmd/winmd.dart';

import '../metadata/projection/typeprinter.dart';
import '../metadata/utils.dart';
import 'exclusions.dart';
import 'win32_functions.dart';

const callbacksFileHeader = '''
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// Native callback functions that can get called by the Win32 API

// -----------------------------------------------------------------------------
// Linter exceptions
// -----------------------------------------------------------------------------
// ignore_for_file: camel_case_types
// ignore_for_file: camel_case_extensions
//
// Why? The linter defaults to throw a warning for types not named as camel
// case. We deliberately break this convention to match the Win32 underlying
// types.
//
//
// ignore_for_file: unused_field
//
// Why? The linter complains about unused fields (e.g. a class that contains
// underscore-prefixed members that are not used in the library. In this class,
// we use this feature to ensure that sizeOf<STRUCT_NAME> returns a size at
// least as large as the underlying native struct. See, for example,
// ENUMLOGFONTEX.
//
//
// ignore_for_file: unnecessary_getters_setters
//
// Why? In structs like VARIANT, we're using getters and setters to project the
// same underlying data property to various union types. The trivial overhead is
// outweighed by readability.
//
//
// ignore_for_file: unused_import
//
// Why? We speculatively include some imports that we might generate a
// requirement for.
// -----------------------------------------------------------------------------

import 'dart:ffi';

import 'package:ffi/ffi.dart';
''';

final imports = <String>{};

void generateCallbacksFile(File file, List<TypeDef> callbacks) {
  final writer = file.openSync(mode: FileMode.writeOnly);
  final buffer = StringBuffer();

  for (final callback in callbacks) {
    buffer.write(
        TypePrinter.printCallback(callback, callback.name.split('.').last));

    final invokeMethod = callback.findMethod('Invoke');
    if (invokeMethod != null) {
      imports.addAll(importsForFunction(invokeMethod));
    }
  }

  writer.writeStringSync(callbacksFileHeader);
  writer.writeStringSync(
      "import '${relativePathToSrcDirectory(file)}guid.dart';\n");
  for (final import in imports) {
    if (!excludedImports.contains(import)) {
      writer.writeStringSync(
          "import '${relativePathToSrcDirectory(file)}$import';\n");
    }
  }
  writer.writeStringSync(buffer.toString());
  writer.closeSync();
}
