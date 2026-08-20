import 'dart:html' as html;
import 'dart:convert';
void downloadImage(List<int> bytes, String fileName) {
  final base64data = base64Encode(bytes);
  final a = html.AnchorElement(href: 'data:image/png;base64,$base64data');
  a.download = fileName;
  a.click();
  a.remove();
}
