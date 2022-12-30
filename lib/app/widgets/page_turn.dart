// ignore_for_file: library_private_types_in_public_api

import 'package:appbook/app/utils/log.dart';
import 'package:appbook/app/widgets/page_turn_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:pdfx/pdfx.dart';

class PageTurn extends StatefulWidget {
  const PageTurn({
    Key? key,
    this.duration = const Duration(milliseconds: 450),
    this.cutoff = 0.6,
    required this.children,
    this.initialIndex = 0,
    this.listImages = const [],
    this.listBytes = const [],
    this.onTap,
  }) : super(key: key);

  final List<Widget> children;
  final Duration duration;
  final int initialIndex;
  final double cutoff;
  final List<PdfPageImage> listImages;
  final List<Uint8List> listBytes;
  final Function()? onTap;

  @override
  PageTurnState createState() => PageTurnState();
}

class PageTurnState extends State<PageTurn> with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];

  int pageNumber = 0;
  List<Widget> pages = [];

  bool? _isForward;
  bool _isLoading = true;

  @override
  void didUpdateWidget(PageTurn oldWidget) {
    if (oldWidget.children != widget.children) _setUp();

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  void _setUp() {
    setState(() => _isLoading = true);

    _controllers.clear();

    pages.clear();

    for (var bytes in widget.listBytes) {
      final controller = AnimationController(
        value: 1,
        duration: widget.duration,
        vsync: this,
      );

      _controllers.add(controller);

      final child = PageTurnImage(
        amount: controller,
        image: MemoryImage(bytes),
      );

      pages.add(child);
    }

    pages = pages.reversed.toList();
    pageNumber = widget.initialIndex;

    setState(() => _isLoading = false);
  }

  bool get _isLastPage => (pages.length - 1) == pageNumber;

  bool get _isFirstPage => pageNumber == 0;

  void _turnPage(DragUpdateDetails details, BoxConstraints dimens) {
    final ratio = details.delta.dx / dimens.maxWidth;

    if (_isForward == null) {
      if (details.delta.dx > 0) {
        _isForward = false;

        if (pageNumber == 0 && !_isForward!) return;
      } else {
        _isForward = true;
      }
    }

    if (_isForward! && pageNumber == pages.length - 1) {
      return;
    }

    if (_isForward! || pageNumber == 0) {
      _controllers[pageNumber].value += ratio;
    } else {
      _controllers[pageNumber - 1].value += ratio;
    }
  }

  Future<void> _onDragFinish() async {
    if (_isForward == null) return;

    if (_isForward!) {
      if (!_isLastPage &&
          _controllers[pageNumber].value <= (widget.cutoff + 0.15)) {
        nextPage();
      } else {
        await _controllers[pageNumber].forward();
      }
    } else {
      if (!_isFirstPage &&
          _controllers[pageNumber - 1].value >= widget.cutoff) {
        await previousPage();
      } else {
        if (_isFirstPage) {
          await _controllers[pageNumber].forward();
        } else {
          await _controllers[pageNumber - 1].reverse();
        }
      }
    }

    _isForward = null;
  }

  Future<void> nextPage() async {
    if (kDebugMode) print('Next Page..');

    await _controllers[pageNumber].reverse();

    if (mounted) setState(() => pageNumber++);
  }

  Future<void> previousPage() async {
    if (kDebugMode) print('Previous Page..');

    await _controllers[pageNumber - 1].forward();

    if (mounted) setState(() => pageNumber--);
  }

  Future<void> goToPage(int index) async {
    if (kDebugMode) print('Navigate Page ${index + 1}..');

    if (mounted) setState(() => pageNumber = index);

    for (var i = 0; i < _controllers.length; i++) {
      if (i == index) {
        _controllers[i].forward();
      } else if (i < index) {
        _controllers[i].reverse();
      } else {
        if (_controllers[i].status == AnimationStatus.reverse) {
          _controllers[i].value = 1;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (_, dimens) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragCancel: () => _isForward = null,
          onHorizontalDragUpdate: (details) => _turnPage(details, dimens),
          onHorizontalDragEnd: (details) => _onDragFinish(),
          child: _renderStack(),
        ),
      ),
    );
  }

  Widget _renderStack() {
    return Stack(
      children: [
        ...pages,
        if (_isLoading) _buildLoading(),
        _buttonController(),
        _pageNumber(),
      ],
    );
  }

  Widget _pageNumber() {
    return Positioned(
      top: 60,
      right: 20,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            "${pageNumber + 1}/ ${pages.length}",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Align(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: const Center(child: Text("Memuat gambar lain...")),
      ),
    );
  }

  Widget _buttonController() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(bottom: 40, top: 12),
        decoration: BoxDecoration(
          color: Colors.black,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (pageNumber != 0)
              IconButton(
                  onPressed: () => previousPage(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  )),
            if (pageNumber != 0) SizedBox(width: 24),
            if (pageNumber + 1 != pages.length)
              IconButton(
                  onPressed: () => nextPage(),
                  icon: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  )),
            Spacer(),
            IconButton(
                onPressed: () => _showBottomSheet(context),
                icon: Icon(
                  Icons.list,
                  color: Colors.white,
                )),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Color.fromRGBO(0, 0, 0, 0.001),
            child: GestureDetector(
              onTap: () {},
              child: DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.2,
                maxChildSize: 0.75,
                builder: (_, controller) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(25.0),
                        topRight: const Radius.circular(25.0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text("Page Chapter"),
                        Icon(
                          Icons.remove,
                          color: Colors.grey[600],
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: controller,
                            itemCount: 100,
                            itemBuilder: (_, index) {
                              return Card(
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text("Element at index($index)"),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
