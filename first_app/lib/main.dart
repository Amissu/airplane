import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart'; // 导入DateFormat类
import 'package:geolocator/geolocator.dart'; // 导入Geolocator包


Future<void> main() async {
  sqflite_ffi.sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await openDatabase('my_database.db');

  // 创建 users 数据表
  await db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT,
      password TEXT
    )
  ''');

  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _saveUsername(String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<String?> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      // 获取数据库实例
      final db = await openDatabase('my_database.db');

      // 查询用户信息
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      // 验证用户名和密码
      if (result.isNotEmpty) {
        _saveUsername(username);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('提示'),
              content: Text('账号密码错误，请重新输入'),
              actions: <Widget>[
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }


  void _goToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('欢迎来到纸飞机交友APP，清先进行登录'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: '用户名'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _login,
                child: Text('登录'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _goToRegistration,
                child: Text('注册'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();


  void _register() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      // 获取数据库实例
      final db = await openDatabase('my_database.db');

      // 查询用户信息
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (result.isNotEmpty) {
        // 用户名已存在，提示注册失败
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('注册失败'),
            content: Text('该用户名已经被注册，请选择其他用户名。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
        );
        return;
      }

      // 添加新用户
      await db.insert(
        'users',
        {'username': username, 'password': password},
      );

      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('注册'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: '用户名'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _register,
                child: Text('注册'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
// 定义一个变量来存储用户名
  String? _username;

  // 定义一个方法来从本地缓存读取用户名
  Future<String?> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
  @override
  void initState() {
    super.initState();
    _getUsername().then((value) {
      setState(() {
        _username = value;
      });
    });
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          PaperPlanePage(),
          ChangeNotifierProvider(
            create: (context) => TodoModel(),
            child: ChatPage(),
          ),
          ChatListPage(),
          MePage(),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.grey,
        child: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              icon: Icon(Icons.near_me),
              text: '附近',
            ),
            Tab(
              icon: Icon(Icons.drag_handle),
              text: '发布',
            ),
            Tab(
              icon: Icon(Icons.chat_bubble),
              text: '聊天',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: '我的',
            ),
          ],
        ),
      ),
    );
  }
}



class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late Database db;
  List<Map<String, dynamic>> replies = [];

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  void initDatabase() async {
    // 获取数据库路径
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = '${documentsDirectory.path}/todo3.db';

    // 打开数据库
    db = await openDatabase(path);

    // 查询回复表
    replies = await db.query('replies');

    // 更新状态
    setState(() {});
  }

  void showChatDialog(int index) {
    // 获取当前回复的信息
    String replyUsername = replies[index]['replyUsername'];
    String taskUsername = replies[index]['taskUsername'];
    String replyContent = replies[index]['replyContent'];
    String taskContent = replies[index]['taskContent'];
    int id = replies[index]['id'];

    // 弹出对话框
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('与$replyUsername聊天'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('纸飞机内容：$taskContent'),
              Text('回复内容：$replyContent'),
              TextField(
                decoration: InputDecoration(hintText: '输入你的回复'),
                onSubmitted: (value) async {
                  // 插入新的回复到数据库
                  await db.insert('replies', {
                    'replyUsername': replyUsername,
                    'taskUsername': taskUsername,
                    'replyTime': DateTime.now().toString(),
                    'replyContent': value,
                    'taskContent': taskContent,
                    'id': id,
                  });

                  // 关闭对话框
                  Navigator.pop(context);

                  // 刷新页面
                  initDatabase();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('聊天列表'),
      ),
      body: ListView.builder(
        itemCount: replies.length,
        itemBuilder: (context, index) {
          // 获取当前回复的信息
          String replyUsername = replies[index]['replyUsername'];
          String taskUsername = replies[index]['taskUsername'];
          String replyTime = replies[index]['replyTime'];
          String replyContent = replies[index]['replyContent'];
          String taskContent = replies[index]['taskContent'];
          int id = replies[index]['id'];

          // 过滤掉和当前纸飞机id不同的回复
          List<Map<String, dynamic>> filteredReplies =
          replies.where((r) => r['id'] == id).toList();

          // 返回一个列表项，显示最新的回复
          return ListTile(
            leading: CircleAvatar(
              child: Text(replyUsername[0]),
            ),
            title: Text('$replyUsername 回复了 $taskUsername 的纸飞机'),
            subtitle: Text("点击查看回复"), // 使用last方法获取最后一个元素
            trailing: Text(replyTime),
            onTap: () {
              // 点击列表项时，显示聊天对话框，展示所有相关的回复
              showChatDialog(index);
            },
          );
        },
      ),
    );
  }
}


class PaperPlanePage extends StatefulWidget {
  const PaperPlanePage({Key? key}) : super(key: key);

  @override
  _PaperPlanePageState createState() => _PaperPlanePageState();
}

class _PaperPlanePageState extends State<PaperPlanePage> {
  final TodoModel _todoModel = TodoModel(); // 数据库模型
  List<Task> _taskList = []; // 纸飞机列表
  Position? _currentPosition; // 当前位置
  bool _isLoading = false; // 加载状态

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 获取当前位置
    _getPaperPlanes(); // 获取纸飞机列表
  }

  // 获取当前位置
  void _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 获取纸飞机列表
  void _getPaperPlanes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<Task> taskList = await _todoModel.taskList;

      setState(() {
        _taskList = taskList;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 计算两点之间的距离（单位：米）
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // 地球半径（单位：米）
    double radLat1 = lat1 * pi / 180.0;
    double radLat2 = lat2 * pi / 180.0;
    double a = radLat1 - radLat2;
    double b = lon1 * pi / 180.0 - lon2 * pi / 180.0;
    double s =
        2 * asin(sqrt(pow(sin(a / 2), 2) + cos(radLat1) * cos(radLat2) * pow(sin(b / 2), 2)));
    s = s * R;
    return s.roundToDouble();
  }

  // 显示纸飞机详情对话框
  void _showPaperPlaneDialog(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? ''; // 获取当前用户名
    String replyContent = ''; // 回复内容
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('纸飞机详情'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('发布者：${task.username}'),
                Text('发布时间：${task.createdAt}'),
                Text('内容：${task.title}'),
                Text('距离：${_calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, task.latitude, task.longitude)}米'),
                TextField(
                  decoration: InputDecoration(hintText: '回复内容'),
                  onChanged: (value) {
                    replyContent = value; // 获取输入内容
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 关闭对话框
                },
                child: Text('关闭'),
              ),
              TextButton(
                onPressed: () async {
                  if (replyContent.isNotEmpty) {
                    // 如果回复内容不为空
                    await _todoModel.addReply(username, task.username, DateTime.now().toString(), replyContent, task.title, task.id); // 添加回复到数据库
                    await _todoModel.updateTask(task); // 删除纸飞机
                    _getPaperPlanes(); // 重新获取纸飞机列表
                    Navigator.pop(context); // 关闭对话框
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('回复成功，可以在对话列表找到历史记录'),
                      duration: Duration(seconds: 2),
                    ));
                  }
                },
                child: Text('回复'),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('纸飞机展示页面'),
        actions: [
          IconButton(
            onPressed: () {
              _getCurrentLocation(); // 刷新当前位置
              _getPaperPlanes(); // 刷新纸飞机列表
            },
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: _taskList.length,
        itemBuilder: (context, index) {
          Task task = _taskList[index];
          return Stack(
            children: [
              Center(
                child: IconButton(
                  iconSize: 40,
                  icon: Icon(CupertinoIcons.paperplane),
                  onPressed: () {
                    _showPaperPlaneDialog(task); // 显示纸飞机详情对话框
                  },
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  child: Text(
                    '${task.title.substring(0, min(10, task.title.length))}... (${_calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, task.latitude, task.longitude)}米)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('我的纸飞机')),
      body: Consumer<TodoModel>(
        builder: (context, todoModel, child) {
          return ListView.builder(
            itemCount: todoModel.taskList1.length,
            itemBuilder: (context, index) {
              final task = todoModel.taskList1[index];
              return ListTile(
                title: Text(task.title),
                subtitle: Text(task.createdAt), // 显示创建时间
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      child: Icon(
                        task.isCompleted ? Icons.comment : Icons.comment_bank,
                        color: task.isCompleted ? Colors.red : Colors.grey,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        todoModel.deleteTask(task);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final title = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              final TextEditingController textController = TextEditingController();
              return AlertDialog(
                title: Text("扔一个纸飞机"),
                content: TextField(
                  controller: textController,
                  autofocus: true,
                  onSubmitted: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("取消"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(textController.text);
                    },
                    child: Text("扔出"),
                  ),
                ],
              );
            },
          );

          if (title != null) {
            // 获取用户名
            final prefs = await SharedPreferences.getInstance();
            final username = prefs.getString('username') ?? '';
            // 获取经纬度
            final position = await Geolocator.getCurrentPosition();
            final latitude = position.latitude;
            final longitude = position.longitude;
            // 获取创建时间
            final createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
            Provider.of<TodoModel>(context, listen: false).addTask(title, username, latitude, longitude, createdAt); // 传递参数
          }
        },
        tooltip: '扔一个纸飞机',
        child: Icon(Icons.add),
      ),
    );
  }
}

class Task {
  final int id;
  final String title;
  bool isCompleted;
  final String username; // 增加用户名属性
  final double latitude; // 增加纬度属性
  final double longitude; // 增加经度属性
  final String createdAt; // 增加创建时间属性

  Task({required this.id, required this.title, this.isCompleted = false, required this.username, required this.latitude, required this.longitude, required this.createdAt}); // 初始化属性

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'isCompleted': isCompleted ? 1 : 0, 'username': username, 'latitude': latitude, 'longitude': longitude, 'createdAt': createdAt}; // 转换为键值对
  }
}

class TodoModel extends ChangeNotifier {
  Database? _database;
  List<Task> _taskList = [];
  List<Task> _taskList1 = [];
  List<Task> get taskList => _taskList;
  List<Task> get taskList1 => _taskList1;
  TodoModel() {
    _initDatabase();
  }

  Future<void> addReply(String replyUsername, String taskUsername, String replyTime, String replyContent, String taskContent,int id) async {
    if (_database == null) return;

    await _database!.insert('replies', {
      'replyUsername': replyUsername,
      'taskUsername': taskUsername,
      'replyTime': replyTime,
      'replyContent': replyContent,
      'taskContent': taskContent,
      'id': id
    });
  }



  Future<void> updateTaskCompletion(Task task, bool isCompleted) async {
    if (_database == null) return;

    await _database!.update(
      'tasks',
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [task.id],
    );
    _loadTasks();
  }


  Future<void> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = '${documentsDirectory.path}/todo3.db';
    databaseFactory = sqflite_ffi.databaseFactoryFfi; // 设置 databaseFactory
    _database = await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE IF NOT EXISTS tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, isCompleted INTEGER, username TEXT, latitude REAL, longitude REAL, createdAt TEXT)", // 增加四个列
        );
      },
      onOpen: (db){
        return db.execute (
            'CREATE TABLE IF NOT EXISTS replies (replyUsername TEXT, taskUsername TEXT, replyTime TEXT, replyContent TEXT, taskContent TEXT, paperPlaneId TEXT, id INTEGER, dialogId INTEGER PRIMARY KEY AUTOINCREMENT)');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute("ALTER TABLE tasks ADD COLUMN isCompleted INTEGER");
        }
        if (oldVersion < 3) {
          db.execute("ALTER TABLE tasks ADD COLUMN username TEXT"); // 升级数据库
          db.execute("ALTER TABLE tasks ADD COLUMN latitude REAL");
          db.execute("ALTER TABLE tasks ADD COLUMN longitude REAL");
          db.execute("ALTER TABLE tasks ADD COLUMN createdAt TEXT");
        }
      },
      version: 3,
    );
    _loadTasks();
  }


  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username=await prefs.getString('username');
    if (_database == null) return;
    final List<Map<String, dynamic>> maps1 = await _database!.query('tasks', where: 'username = ?', whereArgs: [username]);
    _taskList1 = List.generate(maps1.length, (i) {
      return Task(
        id: maps1[i]['id'],
        title: maps1[i]['title'],
        isCompleted: maps1[i]['isCompleted'] == 1,
        username: maps1[i]['username'], // 赋值属性
        latitude: maps1[i]['latitude'],
        longitude: maps1[i]['longitude'],
        createdAt: maps1[i]['createdAt'],
      );
    });
    final List<Map<String, dynamic>> maps = await _database!.query('tasks' ,  where: 'isCompleted = 0 and username != ?', whereArgs: [username]);
    _taskList = List.generate(maps.length, (i) {
      return Task(
        id: maps[i]['id'],
        title: maps[i]['title'],
        isCompleted: maps[i]['isCompleted'] == 1,
        username: maps[i]['username'], // 赋值属性
        latitude: maps[i]['latitude'],
        longitude: maps[i]['longitude'],
        createdAt: maps[i]['createdAt'],
      );
    });

    notifyListeners();
  }



  Future<void> addTask(String title, String username, double latitude, double longitude, String createdAt) async { // 增加参数
    if (_database == null) return;
    final lastId = await _database!.rawQuery('SELECT id FROM tasks ORDER BY id DESC LIMIT 1'); // 获取最后一条数据的id
    final newId = lastId.isEmpty ? 1 : (lastId[0]['id'] as int) + 1;
    final task = Task(title: title, username: username, latitude: latitude, longitude: longitude, createdAt: createdAt, id: newId); // 传递参数
    await _database!.insert('tasks', task.toMap()); // 插入数据
    _loadTasks();
  }


  Future<void> deleteTask(Task task) async {
    if (_database == null) return;

    await _database!.delete('tasks', where: 'id = ?', whereArgs: [task.id]);
    _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    if (_database == null) return;

    await _database!.update('tasks',{'isCompleted': 1}, where: 'id = ?', whereArgs: [task.id]);
    _loadTasks();
  }
}

class ContactPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('通讯录'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text('张'),
            ),
            title: Text('小张'),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(
              child: Text('王'),
            ),
            title: Text('小王'),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(
              child: Text('红'),
            ),
            title: Text('小红'),
          ),
        ],
      ),
    );
  }
}

class DiscoverPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: null,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('发现'),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.group),
              title: Text('朋友圈'),
            ),
            Divider(),
            Divider(),
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('视频号'),
            ),
            ListTile(
              leading: Icon(Icons.circle),
              title: Text('直播'),
            ),
            Divider(),
            Divider(),
            ListTile(
              leading: Icon(Icons.scanner),
              title: Text('扫一扫'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.handshake),
              title: Text('摇一摇'),
            ),
            Divider(),
            Divider(),
            ListTile(
              leading: Icon(Icons.sunny),
              title: Text('看一看'),
            ),
            ListTile(
              leading: Icon(Icons.flood),
              title: Text('搜一搜'),
            ),
            Divider(),
            Divider(),
            ListTile(
              leading: Icon(Icons.location_city),
              title: Text('附近'),
            ),
            Divider(),
            Divider(),
            ListTile(
              leading: Icon(Icons.shop),
              title: Text('购物'),
            ),
            ListTile(
              leading: Icon(Icons.games),
              title: Text('游戏'),
            ),
            Divider(),
            Divider(),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('小程序'),
            ),
          ],
        )
    );
  }
}

class MePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        ListTile(
          leading: CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text('用户：123'),
          trailing: Icon(Icons.fullscreen),
        ),
        Divider(),
        ListTile(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('欢迎来到纸飞机交友APP'),
              ],
            )
        ),

        Divider(),
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('登出'),
          ),
        ),
      ],
    );
  }
}

