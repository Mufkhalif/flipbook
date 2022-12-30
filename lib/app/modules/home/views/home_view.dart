import 'package:appbook/app/widgets/page_turn.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';

import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  final controller = Get.put(HomeController());
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(color: Colors.white),
          child: PageTurn(
            listBytes: controller.listBytes,
            children: controller.listImages
                .map((element) => ContentPage(data: element))
                .toList(),
          ),
        );
      }),
    );
  }
}

class ContentPage extends StatelessWidget {
  const ContentPage({
    Key? key,
    required this.data,
    this.onTap,
  }) : super(key: key);

  final PdfPageImage data;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.memory(
        data.bytes,
        gaplessPlayback: true,
      ),
    );
  }
}
