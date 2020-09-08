typedef LogWriterCallback = void Function(String text, {bool isError});

void logger(String value, {bool isError = false}) {
  print(value);
}
