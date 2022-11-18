// import 'dart:html';
import 'dart:math';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('dictionary_set');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // final WordController _wordController = Get.put(WordController());
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {

    return GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => MyMainPage()), 
        GetPage(name: '/dictionary', page: () => Dictionary())
      ],
      title: 'Flutter Demo',
      theme: ThemeData(
        
        primarySwatch: Colors.red,
      ),
      home: const MyMainPage(),
    );
  }
}

enum DictionaryType { base, normal, hard }

class HiveDictionaryController extends GetxController{
  Rx<List<String>> dictionaryList = Rx<List<String>>([]);
  Rx<Map<String,dynamic>> currentDictionaryBase = Rx<Map<String,dynamic>>({});
  Rx<Map<String,dynamic>> currentDictionaryNormal = Rx<Map<String,dynamic>>({});
  Rx<Map<String,dynamic>> currentDictionaryHard = Rx<Map<String,dynamic>>({});
  late Box<dynamic> dictionaryListBox;
  late Box<dynamic> currentDictionaryBaseBox;
  late Box<dynamic> currentDictionaryNormalBox;
  late Box<dynamic> currentDictionaryHardBox;

  Rx<Map<String,dynamic>> currentSelectedDictionary = Rx<Map<String,dynamic>>({});
  Rx<String> currentSelectedItemKey = Rx<String>('');
  Rx<dynamic> currentSelectedItemValue = Rx<dynamic>('');
  List<int> randomHappends = [];
  int currentSelectedDictionaryLength = 0;
  DictionaryType currentSelectedDictionaryType = DictionaryType.base;
  var random = Random();
  List<String> currentSelectedDictionaryKeys = [];
  // List<String> currentSelectedDictionaryvalues = [];

  @override
  onInit(){
    openDictionaryList();
    // openDictionary();
    // update();
  }
  
  Future openDictionaryList() async{
    dictionaryListBox = await Hive.openBox('dictionary_list');
    dictionaryList.value = dictionaryListBox.values.toList().map((e) => e.toString()).toList();
    print('dictionary_list: openDictionaryList');
    print(dictionaryList.value);
    update();
  }
  
  Future openDictionary(String dictionaryName) async{
    currentDictionaryBaseBox = await Hive.openBox('${dictionaryName}_base');
    currentDictionaryNormalBox = await Hive.openBox('${dictionaryName}_normal');
    currentDictionaryHardBox = await Hive.openBox('${dictionaryName}_hard');

    currentDictionaryBase.value = {
      for (final key in currentDictionaryBaseBox.keys) 
        key: currentDictionaryBaseBox.get(key)
      };
    currentDictionaryNormal.value = {
      for (final key in currentDictionaryNormalBox.keys)
        key: currentDictionaryNormalBox.get(key)
    };
    currentDictionaryHard.value = {
      for (final key in currentDictionaryHardBox.keys)
        key: currentDictionaryHardBox.get(key)
    };
    setCurrentSelectedDictionary(DictionaryType.base);
  }

  setCurrentSelectedDictionary(DictionaryType dictionaryType){
    if (dictionaryType == DictionaryType.base){
      currentSelectedDictionary = currentDictionaryBase;
    }
    else if (dictionaryType == DictionaryType.normal){
      currentSelectedDictionary = currentDictionaryNormal;
    }
    else if (dictionaryType == DictionaryType.hard){
      currentSelectedDictionary = currentDictionaryHard;
    }
    currentSelectedDictionaryType = dictionaryType;
    updateCurrentSelectedDictionaryKeysAndLength();
  }

  setCurrentSelectedItem(String key, String value){
    currentSelectedItemKey.value = key;
    currentSelectedItemValue.value = value;
    print('key: {$key}, value: {$value}');
  }

  addDictionary(String dictionaryName){
    if (!dictionaryList.value.contains(dictionaryName)){
        dictionaryList.value.add(dictionaryName);
    }
    if (dictionaryListBox.get(dictionaryName) == null){
      dictionaryListBox.put(dictionaryName,dictionaryName);
    }
  }

  addDictionaryItem(DictionaryType dictionaryType, String key, String value){
    if (dictionaryType == DictionaryType.base){
      currentDictionaryBase.value[key] = value;
      currentDictionaryBaseBox.put(key, value);
    }
    else if (dictionaryType == DictionaryType.normal){
      currentDictionaryNormal.value[key] = value;
      currentDictionaryNormalBox.put(key, value);
    }
    else if (dictionaryType == DictionaryType.hard){
      currentDictionaryHard.value[key] = value;
      currentDictionaryHardBox.put(key, value);
    }
    updateCurrentSelectedDictionaryKeysAndLength();
  }

  deleteDictionaryItem(DictionaryType dictionaryType, String key){
    if (dictionaryType == DictionaryType.base){
      currentDictionaryBase.value.remove(key);
      currentDictionaryBaseBox.delete(key);
      
      currentDictionaryNormal.value.remove(key);
      currentDictionaryNormalBox.delete(key);

      currentDictionaryHard.value.remove(key);
      currentDictionaryHardBox.delete(key);
    }
    else if (dictionaryType == DictionaryType.normal){
      currentDictionaryNormal.value.remove(key);
      currentDictionaryNormalBox.delete(key);
    }
    else if (dictionaryType == DictionaryType.hard){
      currentDictionaryHard.value.remove(key);
      currentDictionaryHardBox.delete(key);
    }
    updateCurrentSelectedDictionaryKeysAndLength();
  }

  updateCurrentSelectedDictionaryKeysAndLength(){
    currentSelectedDictionaryLength = currentSelectedDictionary.value.length;
    currentSelectedDictionaryKeys = currentSelectedDictionary.value.keys.toList();
    randomHappends = [];
    update();
  }

  nextItem(){
    while (true){
      if (randomHappends.length >= currentSelectedDictionaryLength){
        randomHappends = [];
      }
      if (currentSelectedDictionaryLength <=0) return;

      int randomInt = random.nextInt(currentSelectedDictionaryLength);
      if (!randomHappends.contains(randomInt)){
        randomHappends.add(randomInt);
        String newKey = currentSelectedDictionaryKeys[randomInt];
        dynamic newValue = currentSelectedDictionary.value[newKey];
        if (!(newValue is String)){
          return;
        }
        setCurrentSelectedItem(newKey, newValue);
        update();
        break;
      }
    }
  }
}


class MyMainPage extends StatelessWidget {
  const MyMainPage({super.key});

  @override
  Widget build(BuildContext context){
    Get.put(HiveDictionaryController());
    // final _hiveDictionaryController = Get.put(HiveDictionaryController());
    // final dictionaryNames = <Widget>[];
    // _hiveDictionaryController.dictionaryList.value.forEach((element) => dictionaryNames.add(ListTile(title:TextButton(child:Text(element), onPressed: () => {_hiveDictionaryController.openDictionary(element), Get.offNamed('/dictionary')}))));

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          MaterialButton(onPressed: () => Get.offNamed('/dictionary'), child: const Text("dictionary"), color: Colors.white)
        ],
      ),
      body: GetX<HiveDictionaryController>(
        builder: (controller){
          final dictionaryNames = <Widget>[];
          controller.dictionaryList.value.forEach((element) => dictionaryNames.add(ListTile(title:TextButton(child:Text(element), onPressed: (){controller.openDictionary(element); Get.offNamed('/dictionary');}))));
          return ListView(children: dictionaryNames,);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(CreateDictionary()),
        tooltip: 'add dictionary',
        child: const Icon(Icons.add)),
    );
  }
}

class CreateDictionary extends StatelessWidget {
  final textController = TextEditingController();
  final _hiveDictionaryController = Get.put(HiveDictionaryController());
  
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          TextField(
            controller: textController,
            decoration: InputDecoration(
              border:OutlineInputBorder(),
              labelText: 'Create New Dictinonary'
            ),
          )
          ,
          ElevatedButton(
            onPressed: (){
              _hiveDictionaryController.addDictionary(textController.text);
              Get.offNamed('/');
            }, 
            child: Text('create'))
        ]),
    );

  }
}



class Dictionary extends StatelessWidget {
  const Dictionary({super.key});

  @override
  Widget build(BuildContext context){
    // final _hiveDictionaryController = Get.put(HiveDictionaryController());
    // final tiles = <Widget>[];

    // _hiveDictionaryController.currentDictionaryBase.value.forEach((key, value) {
    //   if (key != 'dictionary_name'){
    //     tiles.add(ListTile(title:TextButton(child:Text(key), onPressed: () {
    //       String string2;
    //       if (value is String){
    //         string2 = value;
    //       }
    //       else{
    //         string2 = "from Dictionary.build: not String Class error";
    //       }
    //       _hiveDictionaryController.setCurrentSelectedItem(key, string2);
    //       Get.to(()=> DictionaryItem());

    //     },)));
      // }
    // });
    final _hiveDictionaryController = Get.put(HiveDictionaryController());
    String dictionaryTypeString ='base';
    print(_hiveDictionaryController.currentSelectedDictionaryKeys);

    
    return Scaffold(
      appBar: AppBar(
        title: GetBuilder<HiveDictionaryController>(
          builder: ((controller){
            if (_hiveDictionaryController.currentSelectedDictionaryType == DictionaryType.base) dictionaryTypeString = 'base';
            else if (_hiveDictionaryController.currentSelectedDictionaryType == DictionaryType.normal) dictionaryTypeString = 'normal';
            else if (_hiveDictionaryController.currentSelectedDictionaryType == DictionaryType.hard) dictionaryTypeString = 'hard';
            print(_hiveDictionaryController.currentSelectedDictionaryType);
            return Text('dictionary-$dictionaryTypeString');
          }),
        ),
        actions: <Widget>[
          MaterialButton(onPressed: () => Get.offNamed('/'), child: const Text("home"), color: Colors.white)
        ],
      ),
      body: GetBuilder<HiveDictionaryController>(
        builder: (controller){
          final tiles = <Widget>[];

          controller.currentSelectedDictionaryKeys.forEach((e) => {tiles.add(ListTile(
                                                                title: TextButton(
                                                                  child:Text(e), 
                                                                  onPressed: (){
                                                                    String newValue;
                                                                    final value = controller.currentSelectedDictionary.value[e];
                                                                    if (!(value is String)){
                                                                      newValue = "from Dictionary.build: the value is not String Class.";
                                                                    }
                                                                    else{
                                                                      newValue = value;
                                                                    }
                                                                    controller.setCurrentSelectedItem(e, newValue);
                                                                    Get.to(()=>DictionaryItem());

                                                                  },)))});
          return Column(
            children:[
              // Text('select dictionary type'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                ElevatedButton(onPressed: () => controller.setCurrentSelectedDictionary(DictionaryType.base), child: Text('base')),
                ElevatedButton(onPressed: () => controller.setCurrentSelectedDictionary(DictionaryType.normal), child: Text('normal')),
                ElevatedButton(onPressed: () => controller.setCurrentSelectedDictionary(DictionaryType.hard), child: Text('hard')),
              ],),
              Expanded(child:ListView(children: tiles,)),
            ]
          );  
        },),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(CreateDictionaryItem()),
        tooltip: 'add item',
        child: const Icon(Icons.add)
      )
    );
  }
}

class CreateDictionaryItem extends StatelessWidget{
  final textController1 = TextEditingController();
  final textController2 = TextEditingController();
  final _hiveDictionaryController = Get.put(HiveDictionaryController());

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller:  textController1,
            decoration:  InputDecoration(
              border:  OutlineInputBorder(),
              labelText: 'new word'
            )
          ),
          TextField(
            controller:  textController2,
            decoration:  InputDecoration(
              border:  OutlineInputBorder(),
              labelText: 'meaning'
            ),
          ),
          ElevatedButton(
            onPressed: (){
              if (textController1.text.trim().isEmpty){
                return;
              }
              if (textController2.text.trim().isEmpty){
                return;
              }
              _hiveDictionaryController.addDictionaryItem(DictionaryType.base, textController1.text, textController2.text);
              if (_hiveDictionaryController.currentSelectedDictionaryType == DictionaryType.normal){
                _hiveDictionaryController.addDictionaryItem(DictionaryType.normal, textController1.text, textController2.text);
              }
              else if (_hiveDictionaryController.currentSelectedDictionaryType == DictionaryType.hard){
                _hiveDictionaryController.addDictionaryItem(DictionaryType.hard, textController1.text, textController2.text);
              }
              Get.offNamed('/dictionary');
            }, 
            child: const Text('create')
          )
        ],
      ),
    );
  }
}


class DictionaryItem extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    // return GetBuilder<HiveDictionaryController>(builder: (controller) { 
    return GetX<HiveDictionaryController>(builder: (controller) { 
      var string1 = controller.currentSelectedItemKey.value;
      var string2 = controller.currentSelectedItemValue.value;
      print('from DictionaryItem : $string1, $string2');
      return Scaffold(
        appBar: AppBar(actions: <Widget>[
          // MaterialButton(onPressed: () => Get.offNamed('/dictionary'), child: const Text('dictionary'), color: Colors.white)
        ]),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:[
                        TextButton(onPressed: (){controller.addDictionaryItem(DictionaryType.normal, string1, string2); }, child: Text('add to normal')),
                        TextButton(onPressed: (){controller.addDictionaryItem(DictionaryType.hard, string1, string2); }, child: Text('add to hard')),
                        TextButton(onPressed: (){controller.deleteDictionaryItem(controller.currentSelectedDictionaryType, string1); Get.offNamed('/dictionary');}, child: Text('delete')),
                      ]
                    ), 
                    Center(child:Text(string1)), 
                    Text(string2), 
                    TextButton(onPressed: controller.nextItem, child: Text('next'))],)
      );});
  }
}

