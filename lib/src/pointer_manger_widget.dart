import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

part 'pointer_group_handler.dart';
part 'utils.dart';

class PointerMangerWidget extends StatefulWidget {
  final bool _onlyMe;

  final String? _groupTag;
  final bool useAbsorbController;
  final HitTestBehavior behavior;
  final bool replaceCurrentWithNext;
  final int? maxNumOfPointers;
  final Widget child;

  /// This means that this child will be inside a group of other children.
  ///
  /// And no two children in this [groupTag] will receive pointers at the same time.
  ///
  /// If [groupTag] is [null], then it will use the available
  /// closest-ancestor of [PointerGroupHandler].
  ///
  /// [maxNumOfPointers] is the maximum number of pointers allowed.
  ///
  /// if [replaceCurrentWithNext] is [true], then the new pointer that comes
  /// after the last-allowed-pointer will be used as the new last-allowed-pointer,
  /// otherwise this new pointer will be ignored.
  ///
  /// if [useAbsorbController] is [true], then [AbsorbPointer] will
  /// be used to prevent more pointer, otherwise [IgnorePointer] will be used.
  const PointerMangerWidget.withAll({
    Key? key,
    String? groupTag,
    this.useAbsorbController = true,
    this.behavior = HitTestBehavior.opaque,
    this.maxNumOfPointers,
    this.replaceCurrentWithNext = false,
    required this.child,
  })  : assert((maxNumOfPointers ?? 1) > 0),
        _onlyMe = false,
        _groupTag = groupTag,
        super(key: key);

  /// This pointer manger is for its child only.
  ///
  /// [maxNumOfPointers] is the maximum number of pointers allowed.
  ///
  /// if [replaceCurrentWithNext] is [true], then the new pointer that comes
  /// after the last-allowed-pointer will be used as the new last-allowed-pointer,
  /// otherwise this new pointer will be ignored.
  ///
  /// if [useAbsorbController] is [true], then [AbsorbPointer] will
  /// be used to prevent more pointer, otherwise [IgnorePointer] will be used.
  const PointerMangerWidget.thisOnly({
    Key? key,
    this.useAbsorbController = true,
    this.behavior = HitTestBehavior.opaque,
    this.maxNumOfPointers,
    this.replaceCurrentWithNext = false,
    required this.child,
  })  : assert((maxNumOfPointers ?? 1) > 0),
        _onlyMe = true,
        _groupTag = null,
        super(key: key);

  @override
  State<PointerMangerWidget> createState() => _PointerMangerWidgetState();
}

class _PointerMangerWidgetState extends State<PointerMangerWidget> {
  _PointerGroupHandlerState? _findGroupHandlerState() {
    BuildContext ctx = context;
    if (widget._groupTag == null) {
      return ctx.findAncestorStateOfType<_PointerGroupHandlerState>();
    } else {
      while (true) {
        final state =
            context.findAncestorStateOfType<_PointerGroupHandlerState>();
        if (state == null) {
          return null;
        }
        if (state._groupTag == widget._groupTag!) {
          return state;
        } else {
          ctx = state.context;
        }
      }
    }
  }

  _PointerGroupHandlerState? _handlerCache;
  _PointerGroupHandlerState get _handler {
    if (_handlerCache != null &&
        _handlerCache!.mounted &&
        _handlerCache!._groupTag == widget._groupTag) {
      return _handlerCache!;
    }

    if (!_onlyMe) {
      _handlerCache = _findGroupHandlerState();
      if (_handlerCache != null) {
        return _handlerCache!;
      } else {
        throw Exception(
            "No PointerHandler ancestor widget with this group tag available.");
      }
    } else {
      throw Exception("This is not defined as withAll.");
    }
  }

  late final _PointersManger _pointerManger;

  // last
  late bool _lastOnlyMe;
  late int? _lastMaxNumOfPointers;
  late bool _lastReplaceCurrentWithNext;

  // current
  bool get _onlyMe => widget._onlyMe;
  int? get _maxNumOfPointers => widget.maxNumOfPointers;
  bool get _replaceCurrentWithNext => widget.replaceCurrentWithNext;

  @override
  @mustCallSuper
  void initState() {
    super.initState();

    _updateDependantVars();

    _pointerManger = _PointersManger();
    if (!_onlyMe) {
      _registerWithAll();
    }
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant PointerMangerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool didAnyThingChanged = _onlyMe != oldWidget._onlyMe ||
        _maxNumOfPointers != oldWidget.maxNumOfPointers ||
        _replaceCurrentWithNext != oldWidget.replaceCurrentWithNext;

    if (didAnyThingChanged) {
      // TODO : handle different cases rather than canceling pointer directly.
      if (_onlyMe && !oldWidget._onlyMe) {
        _unRegisterWithAll();
      } else if (!_onlyMe && oldWidget._onlyMe) {
        _registerWithAll();
      }

      _pointerManger.cancelAll();
      _updateDependantVars();
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    if (!_onlyMe) {
      _unRegisterWithAll();
    }

    _pointerManger.dispose();
    super.dispose();
  }

  void _updateDependantVars() {
    _lastOnlyMe = _onlyMe;
    _lastMaxNumOfPointers = _maxNumOfPointers;
    _lastReplaceCurrentWithNext = _replaceCurrentWithNext;
  }

  void _registerWithAll() {
    _handler._registerNewChild(_pointerManger);

    // not accept pointers if there is already clicked one.
    _pointerManger.acceptPointers = !_handler._isPointerOnChild;
  }

  void _unRegisterWithAll() {
    // if this is the first clicked child, then notify _handler.
    if (_handler._firstClickedPointerManger == _pointerManger) {
      _handler._firstClickedPointerManger!.cancelAll();
    }

    _handler._unRegisterChild(_pointerManger);
  }

  void _handlePointerDownForThisOnly(PointerEvent d) {
    if (_pointerManger.havePointers) {
      _handleNewPointer(
        pointerId: d.pointer,
        pointerManger: _pointerManger,
        maxNumOfPointers: _lastMaxNumOfPointers,
        replaceCurrentWithNext: _lastReplaceCurrentWithNext,
      );
    } else {
      _pointerManger.addPointer(d.pointer);

      if (_lastReplaceCurrentWithNext) {
        _pointerManger.acceptPointers = true;
      } else {
        _pointerManger.acceptPointers = _lastMaxNumOfPointers == null
            ? true
            : _pointerManger.numOfRegisteredPointers < _lastMaxNumOfPointers!;
      }
    }
  }

  void _handlePointerUpOrCancelForThisOnly(PointerEvent d) {
    if (_pointerManger.havePointers) {
      if (!_pointerManger.containsPointer(d.pointer)) {
        return;
      }

      _pointerManger.removePointer(d.pointer);

      if (_lastMaxNumOfPointers == null ||
          _pointerManger.numOfRegisteredPointers < _lastMaxNumOfPointers!) {
        _pointerManger.acceptPointers = true;
      }
    }
  }

  void _handlePointerDownWithAll(PointerEvent d) {
    _handler._onPointerDown(
      pointerId: d.pointer,
      pointerManger: _pointerManger,
      maxNumOfPointers: _lastMaxNumOfPointers,
      replaceCurrentWithNext: _lastReplaceCurrentWithNext,
    );
  }

  void _handlePointerUpOrCancelWithAll(PointerEvent d) {
    _handler._onPointerUpOrCancel(
      pointerId: d.pointer,
      pointerManger: _pointerManger,
      maxNumOfPointers: _lastMaxNumOfPointers,
    );
  }

  Widget _buildPointerControllerWidget({
    required BuildContext context,
    required bool isAbsorbController,
    required bool acceptPointers,
    Widget? child,
  }) =>
      isAbsorbController
          ? AbsorbPointer(
              absorbing: !acceptPointers,
              child: child,
            )
          : IgnorePointer(
              ignoring: !acceptPointers,
              child: child,
            );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _pointerManger._ignoreNotifier,
      builder: (context, __, nonBuildChild) => _buildPointerControllerWidget(
        context: context,
        isAbsorbController: widget.useAbsorbController,
        acceptPointers: _pointerManger.acceptPointers,
        child: nonBuildChild,
      ),
      child: Listener(
        behavior: widget.behavior,
        onPointerDown: !_lastOnlyMe
            ? _handlePointerDownWithAll
            : _handlePointerDownForThisOnly,
        onPointerUp: !_lastOnlyMe
            ? _handlePointerUpOrCancelWithAll
            : _handlePointerUpOrCancelForThisOnly,
        onPointerCancel: !_lastOnlyMe
            ? _handlePointerUpOrCancelWithAll
            : _handlePointerUpOrCancelForThisOnly,
        child: widget.child,
      ),
    );
  }
}
