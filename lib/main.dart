import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:charts_flutter/flutter.dart' as charts;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '体重記録ソフト',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes:{
        '/':  (context) => FirstScreen(),
        '/list': (context) => SecondScreen(),
        '/graph': (context) => ThirdScreen(),
        '/graphSimple': (context) => ThirdScreen(),     
      }
    );
  }
}

class FirstScreen extends StatefulWidget{
  FirstScreen({Key key}) : super(key: key);

  @override
  _FirstScreenState createState() => new _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen>{
  int _selected = 0;

  final _date = TextEditingController();
  final _timing = TextEditingController();
  final _weight = TextEditingController();

  final TextStyle style0 = TextStyle(
    fontSize: 28.0,
    color: Colors.white
  );

  final TextStyle styleA = TextStyle(
    fontSize: 28.0,
    color: Colors.black87,
  );
  final TextStyle styleB = TextStyle(
    fontSize: 24.0,
    color: Colors.black87,
  );

  void initState(){
    _timing.text = "0";
    super.initState();

  }

  Widget _dateArea(BuildContext context){
    Future _selectDate() async {
      DateTime picked = await showDatePicker(
        context: context,
        initialDate: new DateTime.now(),
        firstDate: new DateTime(2018),
        lastDate: new DateTime(2030)
      );
      if(picked != null) setState(() => _date.text = picked.toString().substring(0,10));
    }
    return Row(
      mainAxisAlignment:MainAxisAlignment.start,
      mainAxisSize:MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('日付:', style:styleB),
          Expanded(
            child:
              TextField(
                controller:_date,
                style: styleA,
              ),
          ),
          new RaisedButton(
              onPressed: _selectDate,
              child: new Text('参照'),
          ),
        ],
    );  
 }

  Widget _timeArea(BuildContext context){

    void checkChanged(int value){
      setState(() {
        _selected = value;
        _timing.text = value.toString();
        print(_timing.text);
      });
    }

    return Row(
      mainAxisAlignment:MainAxisAlignment.start,
      mainAxisSize:MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('朝/晩:', style:styleB),
          Radio<int>(
            value: 0,
            groupValue: _selected,
            onChanged: (int value) => checkChanged(value),
          ),
          Text('朝', style:styleB),
          Radio<int>(
            value: 1,
            groupValue: _selected,
            onChanged: (int value) => checkChanged(value),
          ),
          Text('晩', style:styleB),
        ],
    );
  }

  Widget _weightArea(BuildContext context){
    return Row(
      mainAxisAlignment:MainAxisAlignment.start,
      mainAxisSize:MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('体重:', style:styleB),
          Expanded(
            child:
              TextField(
                keyboardType: TextInputType.number,
                controller:_weight,
                style: styleA,
              ),
          ),
        ],
    );
  }

  @override
  Widget build(BuildContext context){
    var childItem = <Widget>[
      _dateArea(context),
      _timeArea(context),
      _weightArea(context)
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('体重記録', style:style0),
      ),
       body : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: childItem,
       ),

    //下部のボタンエリア
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            title: Text('add'),
            icon: Icon(Icons.add_circle),
          ),
          BottomNavigationBarItem(
            title: Text('list'),
            icon: Icon(Icons.list),
          ),
          BottomNavigationBarItem(
            title: Text('graph'),
            icon: Icon(Icons.poll),
          )
        ],
      onTap: (int index){
        if( index == 1){
          Navigator.pushNamed(context, '/list');
        }else if( index == 2){
          Navigator.pushNamed(context, '/graphSimple');
          print("graphSimple");

        }
      },
    ),
    // 保存ボタン
    floatingActionButton: FloatingActionButton(
      child: Icon(Icons.save),
      onPressed: (){
        saveData();
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("saved!"),
            content: Text("insert data into database."),
          )
        );
      },
    ),
   );
  }

  void saveData() async {
    String data1 = _date.text;
    String data2 = _timing.text;
    String data3 = _weight.text;

    String del_query = 'DELETE FROM weight WHERE date="$data1" AND timing=$data2';
    String ins_query = 'INSERT INTO weight(date, timing, weight) VALUES("$data1", $data2, $data3)';

    String dbPath = await getDatabasesPath();
    String path = join(dbPath, "mydata.db");
    Database database = await openDatabase(path, version: 1, 
      onCreate: (Database newdb, int version) async {

        await newdb.execute(
          "CREATE TABLE IF NOT EXISTS weight (id INTEGER PRIMARY KEY, date TEXT, timing INTEGER, weight REAL)"
        );
      }
    );

    await database.transaction((txn) async{
      int del_num = await txn.rawDelete(del_query);
      int id = await txn.rawInsert(ins_query);
      print("del: $del_num, insert: $id");
    });

    setState( () {
      // 何もしない
    });
  }
}

//================= Second Screen ===========
//list表示
class SecondScreen extends StatefulWidget{
  SecondScreen({Key key}) : super(key: key);

  @override
  _SecondScreenState createState() => new _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen>{
  List<Widget> _items = <Widget>[];

  @override
  void initState(){
    super.initState();
    getItems();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('List'),
      ),
      body: ListView(
        children: _items,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            title: Text('add'),
            icon: Icon(Icons.add_circle),
          ),
          BottomNavigationBarItem(
            title: Text('list'),
            icon: Icon(Icons.list),
          ),
          BottomNavigationBarItem(
            title: Text('graph'),
            icon: Icon(Icons.poll),
          ),
        ],
        onTap: (int index) {
          if( index == 0 ){
            Navigator.pushNamed(context, '/');
          }else if( index == 2){
            Navigator.pushNamed(context, '/graph');
          }
        },
      ),
    );
  }

  void getItems() async {
    List<Widget> list = <Widget>[];
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, "mydata.db");

    Database database = await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async{
        await db.execute(
          "CREATE TABLE IF NOT EXISTS weight(id INTEGER PRIMARY KEY, date TEXT, timing INTEGER,  weight REAL)" );
      }
    );

    List<Map> result = await database.rawQuery('SELECT * FROM weight ORDER BY date DESC, timing, id');

    String currentDate = '';
    String currentMorning= '';
    String currentNight = '';

    for ( Map item in result ){
      String thisDate = item['date'];
      int timing = item['timing'];

      if(currentDate == '' || currentDate == thisDate){
        // 初回
        currentDate = thisDate;

        //体重データ
        if(timing == 0){
          currentMorning ="朝 :" + item['weight'].toString() + "Kg";
        }else{
          //夜
          currentNight ="夜 :" + item['weight'].toString() + "Kg";
        }
      }else{
        //日が変わった
        list.add(
          ListTile(
            title: Text('日付: ' + currentDate),
            subtitle: Text(currentMorning + ' / ' + currentNight),
          )
        );

        //日付更新
        currentDate = thisDate;
        currentMorning = '';
        currentNight = '';

        //体重データ
        if(timing == 0){
          currentMorning ="朝 :" + item['weight'].toString() + "Kg";
        }else{
          //夜
          currentNight ="夜 :" + item['weight'].toString() + "Kg";
        }
      }
    }
    // ループの最後の1回分を書き込む
        list.add(
          ListTile(
            title: Text('日付: ' + currentDate),
            subtitle: Text('      ' + currentMorning + ' / ' + currentNight),
          )
        );

    setState( () {
      _items = list;
    });
  }
}

//================= Third Screen ===========
//graph表示
class ThirdScreen extends StatefulWidget{
  ThirdScreen({Key key}) : super(key: key);

  @override
  _ThirdScreenState createState() => new _ThirdScreenState();
}

class _ThirdScreenState extends State<ThirdScreen>{
  List<MyRow> _items = <MyRow>[];
  List<charts.Series> _seriesList;

  @override
  void initState(){
    super.initState();
    getItems();
  }

  @override
  Widget build(BuildContext context){
    _seriesList = _loadData();
    return Scaffold(
      appBar: AppBar(
        title: Text('Graph'),
      ),
      body: new Center(
        child: new Container(
          child: CustomMeasureTickCount(this._seriesList),
        )
       ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            title: Text('add'),
            icon: Icon(Icons.add_circle),
          ),
          BottomNavigationBarItem(
            title: Text('list'),
            icon: Icon(Icons.list),
          ),
          BottomNavigationBarItem(
            title: Text('graph'),
            icon: Icon(Icons.poll),
          ),
        ],
        onTap: (int index) {
          if( index == 0 ){
            Navigator.pushNamed(context, '/');
          }else if( index == 1){
            Navigator.pushNamed(context, '/list');
          }
        },
      ),
    );
  }

  /// Create one series with sample hard coded data.
  List<charts.Series<MyRow, DateTime>> _loadData() {
    return [
      new charts.Series<MyRow, DateTime>(
        id: 'Cost',
        domainFn: (MyRow row, _) => row.timeStamp,
        measureFn: (MyRow row, _) => row.cost,
        data: _items,
      )
    ];
  }
  void getItems() async {

    String dbPath = await getDatabasesPath();
    String path = join(dbPath, "mydata.db");
    Database database = await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async{
        await db.execute(
          "CREATE TABLE IF NOT EXISTS weight(id INTEGER PRIMARY KEY, date TEXT, timing INTEGER,  weight REAL)" );
      }
    );

    List<Map> result = await database.rawQuery('SELECT * FROM weight ORDER BY date DESC, timing, id');
    for ( Map item in result ){
      // 日付
      String date = item['date'];
      List   dateSplit = date.split('-');
      int year = int.parse(dateSplit[0]);
      int month = int.parse(dateSplit[1]);
      int day = int.parse(dateSplit[2]);

      // 時刻 0(朝)は6時、1(夜)は23時にします。
      int timing = item['timing'];
      int hour = 6;
      if(timing == 1){
        hour = 23;
      }

      // 体重
      double weight = item['weight'];
  
      _items.add(new MyRow(new DateTime(year, month, day, hour), weight));
    }

    setState( () {
      _items = _items;
    });
  }
}

class CustomMeasureTickCount extends StatelessWidget {
  List<MyRow> _items = <MyRow>[];

  final List<charts.Series> seriesList;
  final bool animate;

  CustomMeasureTickCount(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
        seriesList,
        animate: animate,
        /// Customize the measure axis to have 2 ticks,
        primaryMeasureAxis: new charts.NumericAxisSpec(
            tickProviderSpec:
                new charts.BasicNumericTickProviderSpec(desiredTickCount: 2)));
  }
}

/// Sample time series data type.
class MyRow {
  final DateTime timeStamp;
  final double cost;
  MyRow(this.timeStamp, this.cost);
}

//================= 削除予定 ================
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
