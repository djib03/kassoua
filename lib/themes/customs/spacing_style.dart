import 'package:flutter/widgets.dart';
import 'package:dm_shop/constants/size.dart';

class DMSpacingStyle {
  static const EdgeInsetsGeometry paddingWithAppBarHeight = EdgeInsets.only(
    top: DMSizes.appBarHeight,
    left: DMSizes.defaultSpace,
    bottom: DMSizes.defaultSpace,
    right: DMSizes.defaultSpace,
  );
}
