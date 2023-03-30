import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';

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
      title: 'Slideshow',
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

  Future<List<String>> _getImagePaths(String folderPath) async {
    List<String> imagePaths = [];
    Directory folder = Directory(folderPath);
    List<FileSystemEntity> entities = await folder.list().toList();
    for (FileSystemEntity entity in entities) {
      if (entity is File) {
        String path = entity.path;
        if (path.endsWith('.jpg') || path.endsWith('.png')) {
          imagePaths.add(path);
          _widgetImageList.add(Image.file(File(path)));
        }
      }
    }
    return imagePaths;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slideshow'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _selectFolders,
              child: Text('Select Folders'),
            ),
            SizedBox(height: 20),
            _imagePaths.isEmpty
                ? Text('No Images Selected')
                : Expanded(
              child: ImageSlideshow(
                children: _widgetImageList,
                autoPlayInterval: 3000,
                isLoop: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FolderPickerDialog extends StatefulWidget {
  @override
  _FolderPickerDialogState createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  late Directory _rootDirectory;
  late Directory _currentDirectory;
  late List<Directory> _selectedDirectories;

  @override
  void initState() {
    super.initState();
    _rootDirectory = Directory('/');
    _currentDirectory = _rootDirectory;
    _selectedDirectories = [];
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

  Future<List<Directory>> _selectFolders() async {
    //await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    //await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft,]);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Folders'),
          content: Container(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _currentDirectory.listSync().length,
                    itemBuilder: (BuildContext context, int index) {
                      FileSystemEntity entity = _currentDirectory.listSync()[index];
                      return ListTile(
                        leading: entity is Directory
                            ? Icon(Icons.folder)
                            : Icon(Icons.insert_drive_file),
                        title: Text(entity.path.split('/').last),
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
                    IconButton(
                      icon: Icon(Icons.arrow_upward),
                      onPressed: _currentDirectory.path == _rootDirectory.path
                          ? null
                          : _navigateUp,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_selectedDirectories);
                      },
                      child: Text('Select'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return _selectedDirectories;
  }

  @override
  Widget build(BuildContext context) {
        return AlertDialog(
          title: Text('Select Folders'),
          content: Container(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _currentDirectory.listSync().length,
                    itemBuilder: (BuildContext context, int index) {
                      FileSystemEntity entity = _currentDirectory.listSync()[index];
                      return ListTile(
                        leading: entity is Directory
                            ? Icon(Icons.folder)
                            : Icon(Icons.insert_drive_file),
                        title: Text(entity.path.split('/').last),
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
                    IconButton(
                      icon: Icon(Icons.arrow_upward),
                      onPressed: _currentDirectory.path == _rootDirectory.path
                          ? null
                          : _navigateUp,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_selectedDirectories);
                      },
                      child: Text('Select'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }
}
