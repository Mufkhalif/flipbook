import 'package:appbook/app/utils/log.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:internet_file/internet_file.dart';
import 'package:pdfx/pdfx.dart';

const filePdf = 'https://pibo.imgix.net/books/file/1671544548.pdf';

class HomeController extends GetxController {
  final count = 0.obs;

  final isLoading = false.obs;

  final pagesCount = 0.obs;
  final imagesCount = 0.obs;

  RxList<PdfPageImage> listImages = <PdfPageImage>[].obs;
  RxList<Uint8List> listBytes = <Uint8List>[].obs;

  @override
  void onInit() {
    super.onInit();

    _getPdfFile();
  }

  Future<void> _getPdfFile() async {
    isLoading.value = true;

    List<PdfPageImage> data = [];
    List<Uint8List> temp = [];

    final document = await PdfDocument.openData(InternetFile.get(filePdf));
    final pageCount = document.pagesCount;

    for (var i = 1; i < pageCount; i++) {
      final page = await document.getPage(i);

      final pageImage = await page.render(
        width: page.width,
        height: page.height,
      );

      temp.add(pageImage!.bytes);
      data.add(pageImage);

      await page.close();
    }

    listImages.value = data;
    listBytes.value = temp;
    isLoading.value = false;

    Log.colorGreen(listImages);
  }

  @override
  void onClose() {}
  void increment() => count.value++;
}
