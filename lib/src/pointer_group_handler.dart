part of 'pointer_manger_widget.dart';

/// Defines a group of its children which use [PointerMangerWidget.withAll] with this [groupTag].
class PointerGroupHandler extends StatefulWidget {
  final String groupTag;
  final Widget child;
  const PointerGroupHandler({
    Key? key,
    required this.groupTag,
    required this.child,
  }) : super(key: key);

  @override
  State<PointerGroupHandler> createState() => _PointerGroupHandlerState();
}

class _PointerGroupHandlerState extends State<PointerGroupHandler> {
  final List<_PointersManger> _childrenPointersManger = [];
  _PointersManger? _firstClickedPointerManger;

  String get _groupTag => widget.groupTag;

  bool get _isPointerOnChild => _firstClickedPointerManger != null
      && _firstClickedPointerManger!.havePointers;

  @override
  @mustCallSuper
  void didUpdateWidget(covariant PointerGroupHandler oldWidget) {
    super.didUpdateWidget(oldWidget);

    if(widget.groupTag != oldWidget.groupTag){
      _childrenPointersManger.clear();
      _firstClickedPointerManger?.cancelAll();
      _firstClickedPointerManger = null;
    }
  }


  void _registerNewChild(_PointersManger childPointerID){
    _childrenPointersManger.add(childPointerID);
  }

  void _unRegisterChild(_PointersManger childPointerID){
    _childrenPointersManger.remove(childPointerID);
  }

  /// loop over all [_childrenPointersManger](except [except]) and set ignoring state to [ignore].
  ///
  /// if [valueForExcept] is null, then do NOT change its state.
  void _setIgnoringStateForAll(bool ignore, [_PointersManger? except, bool? valueForExcept = false]){
    for (final pointersManger in _childrenPointersManger) {
      if(pointersManger == except){
        if(valueForExcept != null){
          pointersManger.acceptPointers = !valueForExcept;
        }
      } else {
        pointersManger.acceptPointers = !ignore;
      }
    }
  }

  /// for with-all.
  ///
  /// with-all: means that the first child clicked will be the only one accepting more clicks
  /// until all its pointers are UP.
  void _onPointerDown({
    required int pointerId,
    required _PointersManger pointerManger,
    required int? maxNumOfPointers,
    required bool replaceCurrentWithNext,
  }){
    if(_firstClickedPointerManger != null){
      // if there is an already-clicked-child.

      if(_firstClickedPointerManger != pointerManger){
        // a second click will be on the same first clicked child (because others have been absorbed).
        //  so if this happen drop and cancel it.
        _cancelPointer(pointerId);
        return;
      }

      _handleNewPointer(
        pointerId: pointerId,
        pointerManger: _firstClickedPointerManger!,
        maxNumOfPointers: maxNumOfPointers,
        replaceCurrentWithNext: replaceCurrentWithNext,
      );
    }else{
      // if there is NO clicked-child yet.

      // register this first-clicked-child.
      pointerManger.addPointer(pointerId);
      _firstClickedPointerManger = pointerManger;

      // here we ignore all registered children except this one.
      _setIgnoringStateForAll(true, pointerManger, null);

      if(replaceCurrentWithNext){
        // here we can just replace pointers indefinitely.
        pointerManger.acceptPointers = true;
      }else{
        // here we CANNOT replace, so we check if we are allowed to add more pointers or not
        pointerManger.acceptPointers = maxNumOfPointers == null
            ? true
            : pointerManger.numOfRegisteredPointers < maxNumOfPointers;
      }
    }
  }

  /// for with-all.
  ///
  /// with-all: means that the first child clicked will be the only one accepting more clicks
  /// until all its pointers are UP.
  void _onPointerUpOrCancel({
    required int pointerId,
    required _PointersManger pointerManger,
    required int? maxNumOfPointers,
  }){
    // drop if NO first child is clicked yet or this is NOT the first-clicked-child.
    if(_firstClickedPointerManger == null
        || _firstClickedPointerManger != pointerManger){return;}
    final firstClickedPointerManger = _firstClickedPointerManger!;

    if(firstClickedPointerManger.havePointers){
      // drop if the pointer does NOT exist.
      if(!firstClickedPointerManger.containsPointer(pointerId)){return;}

      firstClickedPointerManger.removePointer(pointerId);

      if(maxNumOfPointers == null
          || firstClickedPointerManger.numOfRegisteredPointers < maxNumOfPointers){
        // ensure there are available pointers slots(then continue to accept pointers).
        firstClickedPointerManger.acceptPointers = true;
      }
    }

    if(!firstClickedPointerManger.havePointers){
      _firstClickedPointerManger = null;

      _setIgnoringStateForAll(false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
