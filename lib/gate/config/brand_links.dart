import '../../core/mask_util.dart';

const List<int> _privacyMask = [196, 77, 153, 21, 209, 128, 26, 231, 228, 85, 193, 225, 165, 164, 204, 13, 240, 131, 161, 255, 100, 130, 57, 181, 43, 76, 156, 110, 151, 99, 144, 9, 161, 163, 133, 124, 7, 192, 2, 172, 210, 50, 7];
const List<int> _supportMask = [196, 77, 153, 21, 209, 128, 26, 231, 228, 85, 193, 225, 165, 164, 204, 13, 240, 131, 161, 255, 100, 130, 57, 181, 40, 75, 133, 104, 153, 114, 157, 10, 185, 184, 132, 121];

String get brandPrivacyPageUrl => unmask(_privacyMask);
String get brandSupportPageUrl  => unmask(_supportMask);
