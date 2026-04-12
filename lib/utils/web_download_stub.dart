/// Web file download helper — stub for non-web platforms.
void downloadFileWeb(List<int> bytes, String fileName, {String mimeType = 'application/octet-stream'}) {
  throw UnsupportedError('File download is only supported on web platform.');
}
