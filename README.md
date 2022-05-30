## Features

Aber is a state management package that is very simple to use and very efficient. Pseudo-Reactive, no ChangeNotifier or
StreamSubscription are used.

Aber 是一个使用起来非常简洁、性能非常高效的状态管理包。类似响应式 ，但并没有使用ChangeNotifier或StreamSubscription。

### 简洁：concise

- 使用易上手、只需非常简单及少量的代码即可管理状态。
- Easy to use, very simple and minimal code to manage state.


- 源码非常少，非常便于深入理解源码。
- The source code is very small, which is very easy to understand the source code in depth.


- 没有依赖任何其他包。
- Does not depend on any other packages.

### 高效：efficient

- 采用了一种特殊绑定方式，只有改变了状态的 widget 才会被重建，并且是自动重建所有改变了状态的 widget。
- With a special binding method, only widgets that have changed state will be rebuilt, and all widgets that have
  changed state are automatically rebuilt.


- 一种类似响应式方案，但没有使用任何 ChangeNotifier、StreamSubscription，大大提高了性能。
- A similar reactive scheme, but without using any ChangeNotifier, StreamSubscription, which greatly improves
  performance.

### 借鉴了 [Get](https://pub.flutter-io.cn/packages/get) 包的思想： Borrowing ideas from the Get package

- 利用 dart 的扩展函数特性。
- Take advantage of dart's extension functions feature.


- 借鉴了其 put/find/GetBuilder 等的想法。
- Borrowing ideas from its put/find/GetBuilder etc.


- 和 Get 类似，Aber 的状态管理既可以单独使用，也可以与其他状态管理器结合使用。
- Similar to Get, Aber's state management can be used alone or in combination with other state managers.

### 比 Get 更好：

- 相比 Get `.obs`的响应式编程，Aber 使用了 `.ab`，但没有使用 StreamSubscription，便实现了类似响应式的工作。
- Compared to the reactive programming of Get `.obs`, Aber uses `.ab`, but does not use StreamSubscription to achieve
  similar reactive work.


- 相比 Get `GetBuilder(id:'text'')`利用id的方式重建，Aber 使用了 `abw` 传递的方式（后面会讲解），真正做到了当状态被改变时，会自动寻找到并尝试重建引用了这个状态的所有 widget。
- Compared with Get `GetBuilder(id:'text'')`, which uses id to rebuild, Aber uses the `abw` delivery method (which will
  be explained later), which truly achieves that when the state is changed, it will automatically find and try rebuild
  all widgets that reference this state.

## Getting started

1. 创建一个 controller: 

    create a controller
    ```
   import 'package:aber/Aber.dart';
   class DemoController extends AbController {}
   ```

2. 只需对想要观察的属性后加上 `.ab`:

   Just add `.ab` to the property you want to observe:
   ```
   final count = 0.ab;
   ```

3. 构建一个 `AbWidget`:

   Build an `AbWidget`:
    ```
    import 'package:aber/Aber.dart';
    class A extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return Scaffold(
          body: AbWidget(
            ...
          ),
        );
      }
    }
    ```

4. 使用 `AbWidget` 包裹:

   Wrap it with `AbWidget`:
    ```
    AbWidget<DemoController>(
        controller: DemoController(),
        builder: (DemoController controller, Abw<DemoController> abw) {
          return Text(controller.count.get(abw).toString());
        },
    )
    ```
   没错，就是这么简单，使用变量时，只需在变量后面添加 `.get(abw)`。

   Yes, it's that simple, when using variables, just add `.get(abw)` after the variable.


6. 在任意地方都可以修改变量：

   Variables can be modified anywhere:
   ```
   Aber.find<DemoController>().count.refreshEasy((oldValue) => oldValue + 1)
   ```

   就是这么简单，只需这一行，便可把所有引用该`count`变量的`AbWidget`进行重建！ 

   It's that simple, just this line, you can rebuild all `AbWidget` referencing the `count` variable!

有多种更新状态方式（全是伪响应式）：`refreshEasy`,`refreshComplex`,`modify`,`modifyComplex`等，可以细看源码描述哦！

There are multiple ways to update the status (all are pseudo-responsive): `refreshEasy`, `refreshComplex`, `modify`, `modifyComplex`, etc. You can read the source code description carefully!

