import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
class RoundsController extends GetxController{
  final rounds = [
    {
      "title": "Round 1",
      "matches": [
        {"court": "Court 1"},
        {"court": "Court 2"},
      ],
    },
    {
      "title": "Round 2",
      "matches": [
        {"court": "Court 1"},
        {"court": "Court 2"},
      ],
    },
    {
      "title": "Round 3",
      "matches": [
        {"court": "Court 1"},
        {"court": "Court 2"},
      ],
    },
  ].obs;
}