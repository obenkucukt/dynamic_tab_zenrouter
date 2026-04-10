// ============================================================================
// SEO Mixin
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta_seo/meta_seo.dart';
import 'package:zenrouter/zenrouter.dart';

mixin RouteSeo on RouteUnique {
  String get title;
  IconData? get icon => null;
  // String get description;
  // String get keywords;
  // // Optional meta tags with defaults
  // String get author => 'Dai Duong';
  // String? get ogImage => null; // URL to social media preview image
  // String get ogType => 'website';
  // TwitterCard? get twitterCard => TwitterCard.summaryLargeImage;
  // String? get twitterSite => null; // e.g., '@yourusername'
  // String? get canonicalUrl => null; // Canonical URL for this page
  // String get language => 'en';
  // String? get robots => null; // e.g., 'index, follow'

  final meta = MetaSEO();

  @override
  void onUpdate(covariant RouteTarget newRoute) {
    super.onUpdate(newRoute);
    buildSeo();
  }

  @override
  Widget build(covariant Coordinator<RouteUnique> coordinator, BuildContext context) {
    buildSeo();
    return const SizedBox.shrink();
  }

  void buildSeo() {
    // Add MetaSEO just into Web platform condition
    if (kIsWeb) {
      // Basic meta tags
      // meta.author(author: author);
      // meta.description(description: description);
      // meta.keywords(keywords: keywords);
      // Open Graph meta tags (for Facebook, LinkedIn, etc.)
      _setWebTitle(title);
      // meta.ogTitle(ogTitle: title);
      // meta.ogDescription(ogDescription: description);
      // if (ogImage != null) {
      //   meta.ogImage(ogImage: ogImage!);
      // }
      // // Twitter Card meta tags
      // if (twitterCard != null) {
      //   meta.twitterCard(twitterCard: twitterCard!);
      // }
      // meta.twitterTitle(twitterTitle: title);
      // meta.twitterDescription(twitterDescription: description);
      // if (ogImage != null) {
      //   meta.twitterImage(twitterImage: ogImage!);
      // }
      // if (twitterSite != null) {
      //   // Note: You may need to add this manually if MetaSEO doesn't support it
      //   // or use meta.config() for custom tags
      // }
      // // Additional SEO tags
      // if (robots != null) {
      //   // Use meta.config() for custom tags
      //   meta.robots(robotsName: RobotsName.robots, content: robots!);
      // }
    }
  }

  void _setWebTitle(String title) {
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(label: '$title — Chrome Tabs Demo', primaryColor: 0xFF2196F3),
    );
  }
}
