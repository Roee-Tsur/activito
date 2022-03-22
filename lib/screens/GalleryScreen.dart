import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryScreen extends StatelessWidget {
  List<String> photoUrls;
  int firstPage;

  GalleryScreen({required this.photoUrls, required this.firstPage});

  @override
  Widget build(BuildContext context) {
    PageController controller = PageController(initialPage: firstPage);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Container(
          child: PhotoViewGallery.builder(
        pageController: controller,
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(photoUrls[index]),
              initialScale: PhotoViewComputedScale.contained * 0.8,
              minScale: PhotoViewComputedScale.contained * 0.7,
              maxScale: PhotoViewComputedScale.contained * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: photoUrls[index]));
        },
        itemCount: photoUrls.length,
        loadingBuilder: (context, event) => Center(
          child: Container(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded /
                      event.expectedTotalBytes!.toInt(),
            ),
          ),
        ),
      )),
    );
  }
}
