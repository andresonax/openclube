import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Center(
        child: LoadingAnimationWidget.flickr(
          leftDotColor: const Color.fromARGB(255, 21, 79, 179),
          rightDotColor: Colors.orange,
          size: 70, 
        ),
      ),
    );
  }
}
