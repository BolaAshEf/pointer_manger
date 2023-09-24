part of 'pointer_manger_widget.dart';

void _cancelPointer(int id) => GestureBinding.instance.cancelPointer(id);

/// handles the new coming pointer.
///
/// it registers the pointer if needed.
void _handleNewPointer({
  required int pointerId,
  required _PointersManger pointerManger,
  required int? maxNumOfPointers,
  required bool replaceCurrentWithNext,
}) {
  bool mustRegisterPointer = true;

  if (maxNumOfPointers != null) {
    if (pointerManger.numOfRegisteredPointers + 1 > maxNumOfPointers) {
      pointerManger.acceptPointers = false;

      if (replaceCurrentWithNext) {
        final willBeReplacedPointer = pointerManger.lastPointerId;
        pointerManger.lastPointerId = pointerId;
        _cancelPointer(willBeReplacedPointer);
      } else {
        _cancelPointer(pointerId);
      }

      mustRegisterPointer = false;
    } else if (pointerManger.numOfRegisteredPointers + 1 == maxNumOfPointers) {
      pointerManger.acceptPointers = false;
    } else if (pointerManger.numOfRegisteredPointers + 1 < maxNumOfPointers) {
      pointerManger.acceptPointers = true;
    }
  }

  if (mustRegisterPointer) {
    pointerManger.addPointer(pointerId);
  }
}

class _PointersManger {
  final _ignoreNotifier = ValueNotifier(false);
  final List<int> _pointersIDs = [];

  int get numOfRegisteredPointers => _pointersIDs.length;
  bool get havePointers => _pointersIDs.isNotEmpty;

  int get lastPointerId => _pointersIDs[numOfRegisteredPointers - 1];
  set lastPointerId(int value) =>
      _pointersIDs[numOfRegisteredPointers - 1] = value;

  bool get acceptPointers => !_ignoreNotifier.value;
  set acceptPointers(bool value) => _ignoreNotifier.value = !value;

  addPointer(int id) => _pointersIDs.add(id);
  removePointer(int id) => _pointersIDs.remove(id);
  containsPointer(int id) => _pointersIDs.contains(id);

  void cancelAll() {
    for (final id in _pointersIDs) {
      _cancelPointer(id);
    }
  }

  dispose() => _ignoreNotifier.dispose();
}
