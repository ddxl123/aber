library aber;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef RefreshFunction = void Function();
typedef RemoveRefreshFunction = void Function(RefreshFunction);
typedef MarkRebuildFunction = void Function();

class Ab<V> {
  Ab(V initial) {
    value = initial;
  }

  /// 只获取值，不进行任何操作。
  late V value;

  /// 存储每个引用该对象的 [AbBuilder] 的 [_AbBuilderState.refresh]。
  final Set<RefreshFunction> _refreshFunctions = {};

  /// 当 [AbBuilder] 被 dispose 时，会调用这个函数移除曾经添加过的 [_AbBuilderState.refresh]。
  void _removeRefreshFunction(RefreshFunction refresh) => _refreshFunctions.remove(refresh);

  /// 当 [AbBuilder] 需要被当前对象监听时调用。
  ///
  /// 绑定函数的目的：
  ///
  /// 1. 绑定 [_refreshFunctions] :
  ///   将每个引用该对象的 [AbBuilder] 内的 [_AbBuilderState.refresh],
  ///   添加到 [_refreshFunctions]中, 供 [_update] 使用。
  ///
  /// 2. 绑定 [AbController._removeRefreshFunctions] :
  ///   将当前对象 (每个被.nb 标记的对象) 的 [_removeRefreshFunction]，
  ///   添加到 [AbController._removeRefreshFunctions] 中, 供 [_AbBuilderState._removeRefreshs] 使用。
  ///
  ///
  /// 里面都是 Set 类型，所以不会重复被添加。
  V get<C extends AbController>(Abw abw) {
    _refreshFunctions.add(abw._refresh);
    abw._removeRefreshFunctions.add(_removeRefreshFunction);
    return value;
  }

  /// 将当前对象标记为将要被重建。
  Ab<V> call<C extends AbController>(C controller) {
    controller._marksRebuildFunction.add(_refresh);
    return this;
  }

  /// 重建引用了当前对象的 [get] 的 [AbBuilder]。
  void _refresh() {
    for (var _refreshFunction in _refreshFunctions) {
      _refreshFunction();
    }
  }

  void refreshForce() => _refresh();

  /// 当 [value] 为 基本数据类型 时的快捷方案。
  ///
  /// 当 [isForce] 为 true，无论修改的值是否相等，都会强制重建。
  ///
  /// 只会尝试重建引用当前对象 [AbBuilder]。
  ///
  /// 也可以看 [refreshComplex], 复杂的修改推荐使用 [modify] 或 [modifyComplex] 方案。
  void refreshEasy(V Function(V oldValue) newValue, [bool isForce = false]) {
    if (V is num || V is String || V is bool) {
      if (kDebugMode) {
        print('Aber-Warning: Modifying values that are not basic data type, '
            'please use the refreshComplex or modify method.');
      }
    }
    final nv = newValue(value);
    if (value != nv || isForce) {
      value = nv;
      _refresh();
    }
  }

  /// 当 [diff] 返回值为 true 时，才会尝试重建。
  ///
  /// 当 [isForce] 为 true，无论修改的值是否相等，都会强制重建。
  ///
  /// 只会尝试重建引用当前对象 [AbBuilder]。
  ///
  /// 也可以看 [refreshEasy], 复杂的修改推荐使用 [modify] 或 [modifyComplex] 方案。
  void refreshComplex(bool Function(V obj) diff, [bool isForce = false]) {
    if (diff(value)) {
      _refresh();
    }
  }

  /// 当前对象将被释放时, 需要先执行 [broken]。
  ///
  /// 比如 [Ab] 对象被赋 null 值, 例如
  /// ```dart
  ///   Ab<int>? counts = 10.ab;
  ///   counts.broken(controller);
  ///   counts = null;
  /// ```
  ///
  /// 或是在 list/Map/Set 中被 remove/clear ，例如
  /// ```dart
  ///   List<Ab<int>> list = <Ab<int>>[Ab<int>(10)];
  ///   list.first.broken(controller);
  ///   list.remove(0);
  /// ```
  ///
  /// 否则可能会造成内存泄露，因为 [_removeRefreshFunction] 还残留在 [controller] 中。
  void broken<C extends AbController>(C controller) {
    controller._removeRefreshFunctions.remove(_removeRefreshFunction);
  }
}

extension ModifyExt<O> on O {
  /// 对特别复杂的值进行修改的方案。
  ///
  /// 当 [oldValue] != [newValue] 时，会执行 [modify]。
  ///
  /// 只调用该函数并不能将 [AbBuilder] 进行重建，
  /// 只有在最后调用 [AbController.refreshModify] 时，才会尝试进行重建。
  ///
  /// 只会重建调用 [Ab.call] 过的 [Ab] 所对应的 [AbBuilder]。
  ///
  /// 也可以看 [modifyComplex], 简单的修改推荐使用 [Ab.refreshEasy] 或 [Ab.refreshComplex]。
  C modify<C extends AbController, V>(
    C controller,
    V Function(O obj) oldValue,
    V Function(O obj) newValue,
    void Function(O obj, V newValue) modify,
  ) {
    final oldValueGet = oldValue(this);
    final newValueGet = newValue(this);
    if (oldValueGet != newValueGet) {
      modify(this, newValueGet);
      controller._isRefresh = true;
    }
    return controller;
  }

  /// 当 [diff] 返回值为 true 时，才会尝试重建。
  ///
  /// 也可以看 [modify], 简单的修改推荐使用 [Ab.refreshEasy] 或 [Ab.refreshComplex]。
  C modifyComplex<C extends AbController>(C controller, bool Function(O obj) diff) {
    if (diff(this)) {
      controller._isRefresh = true;
    }
    return controller;
  }
}

extension AbExt<V> on V {
  Ab<V> get ab => Ab<V>(this);
}

abstract class AbController {
  /// 存储当前 Controller 对象中所有被 .ab 标记的对象所对应的 [Ab._removeRefreshFunction]。
  ///
  /// 在每个 .ab 属性第一次被引用时，才会把它添加到这里（并不是在初始化时被添加）。
  final Set<RemoveRefreshFunction> _removeRefreshFunctions = {};

  final Set<MarkRebuildFunction> _marksRebuildFunction = {};

  bool _isRefresh = false;

  /// [AbBuilder] 内部的 initState，只会在 [Aber._put] 时所在的 [AbBuilder] 中调用，且只会调用一次。
  void onInit() {}

  /// [AbBuilder] 内部的 dispose，只会在 [Aber._put] 时所在的 [AbBuilder] 中调用，且只会调用一次。
  void dispose() {}

  /// 使用 [modify] 或 [modifyComplex] 后调用该函数进行尝试重建。
  ///
  /// 可以多次连续多次使用 [modify] 或 [modifyComplex], 在最后使用该函数进行尝试重建。
  ///
  /// 当 [isForce] 为 true 时，无论修改的值是否相等，都会强制重建。
  void refreshModify({bool isForce = false}) {
    if (_isRefresh || isForce) {
      for (var element in _marksRebuildFunction) {
        element();
      }
    }
    _isRefresh = false;
    _marksRebuildFunction.clear();
  }
}

/// 将 [AbController]/[AbBuilder]/[Ab] 连接起来的重要类。
///
/// 引用的 [Ab] 被标记为 refresh 时, 所传入的 [Abw] 是哪个 [AbBuilder.builder] 产生的，就会使哪个 widget 被重建.
///
/// 例如:
/// ```dart
/// ...
/// return AbBuilder(
///   controller: Controller1(), // 第一次创建控制器
///   builder: (controller1, abw_1) {
///
///        return AbBuilder<Controller1>( // 因为已经创建过需要的控制器了，因此只需查找。
///          builder: (controller_1, abw_2) {
///
///               // 因为 count 所引用的是 abw_2, 因此当 count 被更新时，
///               // 将会自动重建 abw_2 所在的 AbBuilder, 而 abw_1 所在的 AbBuilder 不会被重建。
///               return Text(controller_1.count.get(abw_2).toString());
///        });
///
/// });
/// ...
/// ```
class Abw<C extends AbController> {
  Abw(this._refresh, this._removeRefreshFunctions);

  final RefreshFunction _refresh;
  final Set<RemoveRefreshFunction> _removeRefreshFunctions;
}

///
/// ```dart
/// class Controller extends AbController {
///   final Ab<int> count = 0.ab;
/// }
/// ```
///
/// 创建控制器并使用
/// ```dart
/// class XXX extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return AbBuilder<Controller>(
///         controller: Controller(),
///         tag: tag,
///         builder: (Controller controller, Abw<Controller> abw){
///             return Text(controller.count.get(abw).toString);
///           }
///       );
///   }
/// }
/// ```
///
/// 如果控制器已被创建过，则直接这样做：
/// ```dart
/// class XXX extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return AbBuilder<Controller>(
///         builder: (Controller controller, Abw<Controller> abw){
///             return Text(controller.count.get(abw).toString);
///           }
///       );
///   }
/// }
/// ```
///
/// 如果要使用多个 controller，则可以使用嵌套的方式:
/// ```dart
/// class XXX extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return AbBuilder(
///         controller OneController(),
///         builder: (OneController one, Abw<OneController> oneAbw){
///             return AbBuilder(
///               controller TwoController(),
///               builder: (TwoController two, Abw<TwoController> twoAbw){
///                   return Column(
///                       children: [
///                           Text(one.count.get(oneAbw).toString),
///                           Text(two.count.get(twoAbw).toString),
///                         ]
///                     );
///                 }
///             );
///           }
///       );
///   }
/// }
/// ```
///
/// [controller] 禁止使用 [Aber.find], 只能用构造函数进行创建，例如： controller: Aber.find<Controller>(tag: 'tag')
///
/// 主要目的是为了保证当前 widget 与当前 controller 的生命周期相对应（比如 initState/dispose）：
///   - 如果在父 [AbBuilder] 中创建了 [controller]，子 [AbBuilder] find 了这个父 [controller],
///   - 那么子 [AbBuilder] 被销毁时，不会将这个父 [controller] 销毁，
///   - 只有在父 [AbBuilder] 被销毁时，才会将这个父 [controller] 销毁。
///   - 也就是说，controller 在 AWidget 中被创建，只有当该 AWidget 被销毁时，它才会被自动销毁。
///
class AbBuilder<C extends AbController> extends StatefulWidget {
  const AbBuilder({
    Key? key,
    this.controller,
    this.tag,
    required this.builder,
  }) : super(key: key);
  final C? controller;
  final String? tag;
  final Widget Function(C controller, Abw<C> abw) builder;

  @override
  State<AbBuilder<C>> createState() => _AbBuilderState<C>();
}

class _AbBuilderState<C extends AbController> extends State<AbBuilder<C>> {
  C? _controller;

  late final Abw<C> _abw;

  /// 当前 Widget 所接收的 controller 是否为 put 产生的。
  bool _isPutter = false;

  @override
  void initState() {
    super.initState();
    _controller = Aber.findOrNull<C>(tag: widget.tag);
    if (_controller == null) {
      if (widget.controller == null) throw 'The ${C.toString() + '.' + (widget.tag ?? '')} object not found.';
      _controller = Aber._put<C>(widget.controller!, tag: widget.tag);
      _isPutter = true;
      // 如果被 find 成功，会导致再次调用 onInit，因此只能放在这里，让它只会调用一次。
      _controller!.onInit();
    }
    if (_controller != null) {
      _abw = Abw<C>(refresh, _controller!._removeRefreshFunctions);
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller!, _abw);

  @override
  void dispose() {
    _removeRefreshs();

    if (_isPutter) {
      _controller!.dispose();
      Aber._removeController<C>(widget.tag);
      _controller = null;
    }

    super.dispose();
  }

  /// 当前 Widget 被移除时，需要同时将所添加过的 [refresh] 函数对象移除掉。
  void _removeRefreshs() {
    for (var element in _controller!._removeRefreshFunctions) {
      element(refresh);
    }
  }
}

class Aber {
  const Aber._();

  /// [_setKey] - [AbController]
  static final Map<String, AbController> _controllers = {};

  /// 当被 put 的 [AbBuilder] 被销毁时，会将其对应的 [AbController] 移除。（在 [AbBuilder] 的 dispose 中调用）
  static void _removeController<C extends AbController>(String? tag) => _controllers.remove(_setKey(tag: tag));

  /// 设置 key。
  ///
  /// 格式：'HomeControllerName.tagName', 中间加个 '.' 是为了防止下面情况，
  ///   - 2个控制器及其 tag 名称分别为 `HomeCont.roller` `Home.Controller`, 如果没有 '.' 的存在，它们将是同一个 key。
  static String _setKey<C extends AbController>({String? tag}) => C.toString() + '.' + (tag ?? '');

  static C _put<C extends AbController>(C controller, {String? tag}) {
    final String key = _setKey<C>(tag: tag);
    if (_controllers.containsKey(key)) throw 'Repeat to add: $key.';
    _controllers.addAll({key: controller});
    return controller;
  }

  /// 查找需要的 [AbController]。
  static C? findOrNull<C extends AbController>({String? tag}) {
    final String key = _setKey<C>(tag: tag);
    final c = _controllers[key];
    return (c is C?) ? c : (throw 'Serious error! The type of controller found does not match! Need-${C.toString()},Found-${c.toString()}');
  }

  /// 查找需要的 [AbController]。
  ///
  /// 没找到会抛出异常。
  static C find<C extends AbController>({String? tag}) =>
      findOrNull(tag: tag) ?? (throw 'Not found: ${_setKey(tag: tag)}. You need to create a controller with the constructor first.');
}
