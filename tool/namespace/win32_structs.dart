import 'dart:io';

import 'package:winmd/winmd.dart';

import '../metadata/projection/typeprinter.dart';
import '../metadata/utils.dart';
import 'exclusions.dart';

const structFileHeader = '''
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common structs used in the Win32 API.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: camel_case_extensions, camel_case_types
// ignore_for_file: directives_ordering, unnecessary_getters_setters
// ignore_for_file: unused_field, unused_import

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

''';

/// Return all the imports needed for a struct to be satisfied.
List<String> importsForStruct(TypeDef struct) {
  final importList = <String>[];

  for (final field in struct.fields) {
    if (field.typeIdentifier.name.startsWith('Windows.Win32')) {
      final typeName = field.typeIdentifier.name.split('.');
      importList.add(typeName[typeName.length - 2].toLowerCase());
    }
  }
  return importList;
}

void generateStructsFile(File file, List<TypeDef> typedefs) {
  final imports = <String>{};

  final writer = file.openSync(mode: FileMode.writeOnly);
  final buffer = StringBuffer();

  for (final struct in typedefs) {
    buffer.write(TypePrinter.printStruct(
        struct, nameWithoutEncoding(struct.name.split('.').last)));
    imports.addAll(importsForStruct(struct));
  }

  writer.writeStringSync(structFileHeader);
  for (final import in imports) {
    if (!excludedImports.contains(import)) {
      writer.writeStringSync(
          "import '${relativePathToSrcDirectory(file)}$import/structs.g.dart';\n");
    }
  }
  writer.writeStringSync(buffer.toString());
  writer.closeSync();
}
