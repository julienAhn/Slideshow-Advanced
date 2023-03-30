import 'dart:io';
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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slideshow Advanced (Made by Julien Ahn)',
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
  List<Directory> _selectedDirectories = [];
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    initPref();

  }

  void initPref() async {
    prefs = await SharedPreferences.getInstance();

    List<String> selectedDirectoriesNames = prefs.getStringList('directories') ?? [];
    for (String directoryName in selectedDirectoriesNames){
      print("awfaf: " + directoryName);
      _selectedDirectories.add(Directory(directoryName));
      addImagePaths(directoryName);
    }
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

  Future<void> addImagePaths(String folderPath) async {
    print(folderPath);
    List<String> imagePaths = [];
    Directory folder = Directory(folderPath);
    List<FileSystemEntity> entities = await folder.list().toList();
    for (FileSystemEntity entity in entities) {
      if (entity is File) {
        String path = entity.path;
        if (path.endsWith('.jpg') || path.endsWith('.png') || path.endsWith('.jpeg')) {
          setState(() {
            _imagePaths.add(path);
            _widgetImageList.add(Image.file(File(path)));
          });
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
        _selectedDirectories.add(directory);
      }
    });
  }

  Future<void> _navigateUp() async {
    String parentPath = _currentDirectory.parent.path;
    Directory parentDirectory = Directory(parentPath);
    await _selectDirectory(parentDirectory);
  }

  Future<void> chooseDirectory() async {
    /*
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'mp4', 'jpeg'],
    );
    */

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      print("selected Directory: " + selectedDirectory);
      print("directory empty: " + selectedDirectory.isEmpty.toString());
      setState(() {
        addDirectory(selectedDirectory);
        addImagePaths(selectedDirectory);
      });
    }
  }

  void addDirectory(String directoryName) {

    Directory folder = Directory(directoryName);
    setState(() {
      _selectedDirectories.add(folder);
      prefs.setStringList('directories', listToString(_selectedDirectories));
    });
  }

  List<String> listToString(List list){
    List<String> listString = [];
    for (Directory i in list){
      listString.add(i.path);
    }
    return listString;
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
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _selectedDirectories.length,
                      itemBuilder: (BuildContext context, int index) {
                        Directory entity = _selectedDirectories[index];
                        return ListTile(
                          leading: entity is Directory
                              ? Icon(Icons.folder)
                              : Icon(Icons.insert_drive_file),
                          title: Text(entity.path.split('/').last),
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
                              await _selectDirectory(entity);
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
                        child: Text('Select'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Slideshow'),
        actions: [
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
                autoPlayInterval: 3000,
                isLoop: true,
                indicatorRadius: 0,
                indicatorBackgroundColor: Colors.black
              ),
            ),
          ],
        ),
      ),
    );
  }
}

