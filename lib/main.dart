import 'dart:io';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/*
Explanation:

- The app has a single screen (`HomePage`) with a button to select folders and an `ImageSlideShow` widget that displays the images in the selected folders.
- When the user clicks the "Select Folders" button, a dialog (`FolderPickerDialog`) is shown that allows the user to navigate through the file system and select one or more folders. The `FolderPickerDialog` uses the `FolderPicker` package to display a folder picker interface.
- When the user selects one or more folders in the `FolderPickerDialog`, the selected image paths are retrieved using the `_getImagePaths` method and stored in the `_imagePaths` list.
- The `_getImagePaths` method recursively scans the folder for images with the `.jpg` or `.png` extension and returns their file paths.
- The `ImageSlideShow` widget is used to display the images in a slideshow format. The `imageUrls` property is set to the `_imagePaths` list, and the `interval`, `isAutoPlay`, and `isLoop` properties are set to control the slideshow behavior.
- The app is designed to support landscape mode only, and the `SystemChrome.setEnabledSystemUIOverlays` and `SystemChrome.setPreferredOrientations` methods are used to ensure that the app is displayed in landscape mode and with the system UI hidden during folder selection.
*/

Future<void> main() async {
  runApp(MyApp());

  WidgetsFlutterBinding.ensureInitialized();
// Must add this line.
  await windowManager.ensureInitialized();
// Use it only after calling `hiddenWindowAtLaunch`
  windowManager.waitUntilReadyToShow().then((_) async {
    // Hide window title bar
    //await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    //await windowManager.setFullScreen(true);
    //await windowManager.center();
    //wait windowManager.show();
    //await windowManager.setSkipTaskbar(false);
    await windowManager.setAsFrameless();
  });
}

class Folder {
  late Directory _directory;

  Folder(Directory directory) {
    _directory = directory;
  }

  int getNumberOfImages(){
    int counter = 0;
    List files = _directory.listSync(recursive: false);
    for (FileSystemEntity file in files) {
      if (file is File) {
        counter++;
      }
    }
    return counter;
  }

  //format: _percentages = [100,90,50,40,30] 5 entrys !!!
  int getPercentage(List<int> percentages){

    int fileLength = _directory.listSync(recursive: false).length;
    if (fileLength <= 20){
      return percentages[0];
    }
    else if (fileLength <= 50){
      return percentages[1];
    }
    else if (fileLength <= 100){
      return percentages[2];
    }
    else if (fileLength <= 200){
      return percentages[3];
    }
    else if (fileLength >= 300){
      return percentages[4];
    }
    else {
      return percentages[4];
    }
  }

  String toString2(){
    return directory.path;
  }

  String get path {
    return _directory.path;
  }

  String get name {
    String wordToFind = 'Scouts Herbesthal';
    int idx = _directory.path.indexOf(wordToFind);
    String directoryName = _directory.path.substring(idx+wordToFind.length + 1);
    directoryName = directoryName.replaceAll(r'\', ' - ');
    return directoryName;
  }

  Directory get directory {
    return _directory;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slideshow Advanced - J.A',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _imagePaths = [];
  List<Widget> _widgetImageList = [];
  late Directory _currentDirectory;
  List<Folder> _selectedDirectories = [];
  late SharedPreferences prefs;
  int _autoplayInterval = 3000;
  String _currentTitle = "";
  List<String> _titleList = [];
  List<int> _percentages = [100,90,50,40,30]; // <= 20; <= 50; <= 100 <= 200 >= 300
  final myController = TextEditingController();
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    initPref();

  }

  void initPref() async {
    prefs = await SharedPreferences.getInstance();

    List<String> selectedDirectoriesNames = prefs.getStringList('directories') ?? [];

    for (String directoryName in selectedDirectoriesNames){
      _selectedDirectories.add(Folder(Directory(directoryName)));
    }

    addImagePathsAdvanced(_selectedDirectories);
  }

  Future<void> addImagePathsAdvanced(List<Folder> folders) async {

    for(Folder folder in folders){
      List<String> allImagePaths = [];
      List<FileSystemEntity> entities = await folder.directory.list(recursive: false).toList();
      for (FileSystemEntity entity in entities) {
        if (entity is File) {
          String path = entity.path.toLowerCase();
          if (path.endsWith('.jpg') || path.endsWith('.png') || path.endsWith('.jpeg')) {
              allImagePaths.add(path);
          }
        }
      }
        int numberOfGeneratedImages = folder.getNumberOfImages() * folder.getPercentage(_percentages) ~/ 100;
        numberOfGeneratedImages = numberOfGeneratedImages > allImagePaths.length ? allImagePaths.length : numberOfGeneratedImages;
        List<String> randomGeneratedListOfPaths = allImagePaths.sample(numberOfGeneratedImages);
        for(String rgPath in randomGeneratedListOfPaths){
          _imagePaths.add(rgPath);
          _widgetImageList.add(Image.file(File(rgPath)));
          _titleList.add(folder.name);
        }

    }
    setState(() {
    });
  }

  void refreshImagePathsAdvanced() async {

    setState(() {
      _titleList = [];
      _imagePaths = [];
      _widgetImageList = [];
    });

    for(Folder folder in _selectedDirectories){
      List<String> allImagePaths = [];
      List<FileSystemEntity> entities = await folder.directory.list(recursive: false).toList();
      for (FileSystemEntity entity in entities) {
        if (entity is File) {
          String path = entity.path.toLowerCase();
          if (path.endsWith('.jpg') || path.endsWith('.png') || path.endsWith('.jpeg')) {
            allImagePaths.add(path);
          }
        }
      }
      int numberOfGeneratedImages = folder.getNumberOfImages() * folder.getPercentage(_percentages) ~/ 100;
      numberOfGeneratedImages = numberOfGeneratedImages > allImagePaths.length ? allImagePaths.length : numberOfGeneratedImages;
      List<String> randomGeneratedListOfPaths = allImagePaths.sample(numberOfGeneratedImages);
      for(String rgPath in randomGeneratedListOfPaths){
        _imagePaths.add(rgPath);
        _widgetImageList.add(Image.file(File(rgPath)));
        _titleList.add(folder.name);
      }

    }
    setState(() {
    });
  }


  Future<void> _selectDirectory(Directory directory) async {
    setState(() {
      _currentDirectory = directory;
    });
  }

  Future<void> _toggleDirectorySelection(Directory directory) async {
    setState(() {
      if (_selectedDirectories.contains(directory)) {
        _selectedDirectories.remove(directory);
      } else {
        _selectedDirectories.add(Folder(directory));
      }
    });
  }

  Future<void> chooseDirectory() async {

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      print("selected Directory: " + selectedDirectory);
      print("directory empty: " + selectedDirectory.isEmpty.toString());
      setState(() {
        List<Folder> folders = getSubDirectories(selectedDirectory);
        addSubDirectories(folders);
        addImagePathsAdvanced(folders);
      });
    }
  }

  // if no subfolder return current directory
  List<Folder> getSubDirectories(String directoryName) {
    List<Folder> folderList = [];
    List fileAndFolders = Directory(directoryName).listSync(recursive: true);
    for (var i in fileAndFolders){
      if (i is Directory){
        folderList.add(Folder(i));
      }
    }

    if(folderList.isEmpty){
      return [Folder(Directory(directoryName))];
    }
    else{
      return folderList;
    }
  }

  void addSubDirectories(List<Folder> folders) {

    setState(() {
      _selectedDirectories = _selectedDirectories + folders;
      prefs.setStringList('directories', listToString(_selectedDirectories));
    });
  }

  List<String> listToString(List<Folder> list){
    List<String> listString = [];
    for (Folder f in list){
      listString.add(f.toString2());
    }
    return listString;
  }

  void pauseUnpauseSlideShow() {
    setState(() {
      _autoplayInterval = _autoplayInterval == 0 ? 3000 : 0;
    });
  }

  int totalNumberOfImages() {
    return _imagePaths.length;
  }

  String totalHoursOfSlideshow() {
    double hours = ((_imagePaths.length * _autoplayInterval/1000) / 60) / 60;
    if (hours < 1){
      return (hours*60).toString() + " minutes";
    }
    else{
      return (hours).toString() + " hours";
    }
  }

  Future<void> removeDirectory(Folder folder) async {

    _selectedDirectories.remove(folder);
    _titleList.remove(folder.path);

    List<FileSystemEntity> entities = await folder.directory.list(recursive: false).toList();
    for (FileSystemEntity entity in entities) {
      if (entity is File) {
        String path = entity.path;
        if (path.endsWith('.jpg') || path.endsWith('.png') || path.endsWith('.jpeg')) {
          setState(() {
            if (_imagePaths.contains(path)){
              _imagePaths.remove(path);
              _widgetImageList.remove(Image.file(File(path)));
            }
          });
        }
      }
    }

    prefs.setStringList('directories', listToString(_selectedDirectories));
  }

  Future<void> removeAllDirectories() async {

    setState(() {

    _selectedDirectories = [];
    _titleList = [];
    _imagePaths = [];
    _widgetImageList = [];
    _currentTitle = "";

    prefs.setStringList('directories', listToString(_selectedDirectories));

    });
  }

  void chooseDirectories() async {

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
            title: Text('Selected Folders'),
            content: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TOTAL images: " + totalNumberOfImages().toString()),
                  Text("TOTAL hours of slideshow: " + totalHoursOfSlideshow()),
                  SizedBox(height: 30),
                  // List<int> _percentages = [100,90,50,40,30]; // <= 20; <= 50; <= 100 <= 200 >= 300
                  FormBuilder(
                      key: _formKey ,
                      child:
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FormBuilderTextField(
                              name: "1",
                              initialValue: _percentages[0].toString(),
                              decoration: new InputDecoration(labelText: "<= 20 | default 100%",),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], // Only numbers can be entered
                            ),
                            SizedBox(height: 1),
                            FormBuilderTextField(
                              name: "2",
                              initialValue: _percentages[1].toString(),
                              decoration: new InputDecoration(labelText: "<= 50 | default 90%",),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], // Only numbers can be entered
                            ),
                            SizedBox(height: 1),
                            FormBuilderTextField(
                              name: "3",
                              initialValue: _percentages[2].toString(),
                              decoration: new InputDecoration(labelText: "<= 100 | default 50%",),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], // Only numbers can be entered
                            ),
                            SizedBox(height: 1),FormBuilderTextField(
                              name: "4",
                              initialValue: _percentages[3].toString(),
                              decoration: new InputDecoration(labelText: "<= 200 | default 40%",),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], // Only numbers can be entered
                            ),
                            SizedBox(height: 1),FormBuilderTextField(
                              name: "5",
                              initialValue: _percentages[4].toString(),
                              decoration: new InputDecoration(labelText: ">= 300 | default 30%",),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], // Only numbers can be entered
                            ),
                            SizedBox(height: 1),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                _formKey.currentState?.save();
                                if (_formKey.currentState!.validate()) {
                                  final formData = _formKey.currentState?.value;
                                  setState(() {
                                  _percentages[0] = int.parse(formData!["1"]);
                                  _percentages[1] = int.parse(formData["2"]);
                                  _percentages[2] = int.parse(formData["3"]);
                                  _percentages[3] = int.parse(formData["4"]);
                                  _percentages[4] = int.parse(formData["5"]);
                                  });
                                }
                              },
                              child: const Text('Submit'),
                            ),
                          ])),
                  SizedBox(height: 30),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _selectedDirectories.length,
                      itemBuilder: (BuildContext context, int index) {
                        Folder entity = _selectedDirectories[index];
                        return ListTile(
                          leading: entity is Folder
                              ? Icon(Icons.folder)
                              : Icon(Icons.insert_drive_file),
                          title: Text(entity.path.split('/').last),
                          subtitle: Text(entity.getNumberOfImages().toString() + " Images" + " | Percentage = " + entity.getPercentage(_percentages).toString() + "% | TOTAL = " + (entity.getNumberOfImages() * entity.getPercentage(_percentages) ~/ 100).toString()),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: (){
                                setState(() {
                                  removeDirectory(entity);
                                });
                              }),
                          onTap: () async {
                            /*
                            if (entity is Directory) {
                              await _selectDirectory(entity.directory);
                            } else {
                              await _toggleDirectorySelection(_currentDirectory);
                            }
                            */
                          },
                          selected: _selectedDirectories.contains(entity),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            chooseDirectory();
                          });
                        },
                        child: Text('Add'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: (){},
                        onLongPress: () {
                          setState(() {
                            removeAllDirectories();
                          });
                        },
                        child: Text('Remove all'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ));
        });
  }

  @override
  Widget build(BuildContext context) {
    //print("_selectedDirectories " + _selectedDirectories.toString());
    //print("_imagePaths " + _imagePaths.toString());
    //print("_autoplayInterval" + _autoplayInterval.toString());
    //print("_currentTitle" + _currentTitle);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: Row(
            children: const [
              Image(image: AssetImage('assets/personal_logo2.png')),
              Image(image: AssetImage('assets/logo_einheit2.jpg'))
            ]),
        leadingWidth: 200,
        title: Text(_currentTitle),
        actions: [
          IconButton(
            onPressed: refreshImagePathsAdvanced,
            icon: const Icon(Icons.refresh),
          ),
          /*
          IconButton(
            onPressed: (){
              setState(() {
                pauseUnpauseSlideShow();
              });
            },
            icon: _autoplayInterval != 0 ? const Icon(Icons.stop_rounded) : const Icon(Icons.play_arrow_rounded),
          ),
          */
          IconButton(
            onPressed: chooseDirectories,
            icon: const Icon(Icons.folder),
          ),

        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imagePaths.isEmpty
                ? Text('No Images Selected')
                : Expanded(
              child: ImageSlideshow(
                children: _widgetImageList,
                autoPlayInterval: _autoplayInterval,
                isLoop: true,
                indicatorRadius: 0,
                indicatorBackgroundColor: Colors.black,
                onPageChanged: (int i){
                  setState(() {
                    _currentTitle = _titleList[i];
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

