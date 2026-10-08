/// Results of an ordered file-system listing.
library;

import 'dart:io';

/// Directories & files of a directory, in display order.
class OrderResult {
  const OrderResult({
    this.directories = const <Directory>[],
    this.files = const <File>[],
  });

  final List<Directory> directories;
  final List<File> files;

  @override
  String toString() => 'OrderResult(${directories.length} directories, '
      '${files.length} files)';
}
