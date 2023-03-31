import 'dart:io';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
Explanation:

- The app has a single screen (`HomePage`) with a button to select folders and an `ImageSlideShow` widget that displays the images in the selected folders.
- When the user clicks the "Select Folders" button, a dialog (`FolderPickerDialog`) is shown that allows the user to navigate through the file system and select one or more folders. The `FolderPickerDialog` uses the `FolderPicker` package to display a folder picker interface.
- When the user selects one or more folders in the `FolderPickerDialog`, the selected image paths are retrieved using the `_getImagePaths` method and stored in the `_imagePaths` list.
- The `_getImagePaths` method recursively scans the folder for images with the `.jpg` or `.png` extension and returns their file paths.
- The `ImageSlideShow` widget is used to display the images in a slideshow format. The `imageUrls` property is set to the `_imagePaths` list, and the `interval`, `isAutoPlay`, and `isLoop` properties are set to control the slideshow behavior.
- The app is designed to support landscape mode only, and the `SystemChrome.setEnabledSystemUIOverlays` and `SystemChrome.setPreferredOrientations` methods are used to ensure that the app is displayed in landscape mode and with the system UI hidden during folder selection.
*/

void main() {
  runApp(MyApp());
}

class Folder {
  late Directory _directory;
  late int _percentage;

  Folder(Directory directory) {
    _directory = directory;
    _percentage = calculatePercentage(directory);
  }

  int getNumberOfImages(){
    List file = _directory.listSync(recursive: true);
    return file.length;
  }

  int calculatePercentage(Directory directory){
    int fileLength = directory.listSync(recursive: true).length;
    if (fileLength < 20){
      return 100;
    }
    else if (fileLength < 50){
      return 80;
    }
    else if (fileLength < 80){
      return 70;
    }
    else if (fileLength < 100){
      return 50;
    }
    else if (fileLength < 200){
      return 80;
    }
    else {
      return 80;
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

  int get percentage {
    return _percentage;
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

  /*
  Future<void> _selectFolders() async {
    final List<Directory>? selectedDirectories = await showDialog<List<Directory>>(
      context: context,
      builder: (BuildContext context) {
        return FolderPickerDialog();
      },
    );
    if (selectedDirectories != null) {
      List<String> allPaths = [];
      for (Directory dir in selectedDirectories) {
        allPaths.addAll(await _getImagePaths(dir.path));
      }
      setState(() {
        _imagePaths = allPaths;
      });
    }
  }
  */

  Future<void> addImagePathsAdvanced(List<Folder> folders) async {
    List<String> allImagePaths = [];
    for(Folder folder in folders){
      List<FileSystemEntity> entities = await folder.directory.list(recursive: true).toList();
      for (FileSystemEntity entity in entities) {
        if (entity is File) {
          String path = entity.path;
          if (path.endsWith('.jpg') || path.endsWith('.png') || path.endsWith('.jpeg')) {
            setState(() {
              allImagePaths.add(path);
              _imagePaths.add(path);
              _widgetImageList.add(Image.file(File(path)));
              _titleList.add(folder.name);
            });
          }
        }
      }
    }
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

  Future<void> _navigateUp() async {
    String parentPath = _currentDirectory.parent.path;
    Directory parentDirectory = Directory(parentPath);
    await _selectDirectory(parentDirectory);
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

  void chooseDirectories() async {

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
            title: Text('Selected Folders'),
            content: Container(
              width: double.maxFinite,
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TOTAL images: " + totalNumberOfImages().toString()),
                  Text("TOTAL hours of slideshow: " + totalHoursOfSlideshow()),
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
                          subtitle: Text(entity.getNumberOfImages().toString() + " Images" + " | Percentage = " + entity.percentage.toString() + "% | TOTAL = " + (entity.getNumberOfImages() * entity.percentage ~/ 100).toString()),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: (){
                                setState(() {
                                  _selectedDirectories.remove(entity);
                                  _imagePaths.remove(entity.path);
                                  prefs.setStringList('directories', listToString(_selectedDirectories));
                                });
                              }),
                          onTap: () async {
                            if (entity is Directory) {
                              await _selectDirectory(entity.directory);
                            } else {
                              await _toggleDirectorySelection(_currentDirectory);
                            }
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
    print("_autoplayInterval" + _autoplayInterval.toString());
    print("_currentTitle" + _currentTitle);
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
            onPressed: pauseUnpauseSlideShow,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: pauseUnpauseSlideShow,
            icon: _autoplayInterval != 0 ? const Icon(Icons.stop_rounded) : const Icon(Icons.play_arrow_rounded),
          ),
          IconButton(
            onPressed: chooseDirectories,
            icon: const Icon(Icons.add),
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

