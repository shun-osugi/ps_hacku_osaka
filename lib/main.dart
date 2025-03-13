import 'package:flutter/material.dart';

// import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'ui_chat.dart';
import 'ui_result.dart';
import 'colors.dart';
import 'subject_categories.dart';
import 'api_service.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
      routes: {
        '/home': (context) => MyHomePage(),
        '/chat': (context) => ChatPage(),
        '/result': (context) => ResultPage(text: '対象のテキスト',),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String str = ""; //入力する文字列
  FilePickerResult? file;
  String filename = ""; //写真の名前

  @override
  Widget build(BuildContext context) {
    file = null;
    return Scaffold(
      backgroundColor: AppColors.mainColor,
        body: SingleChildScrollView(
          child: Stack(
              children: [
                // アバター表示
                Center(
                  child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.4,),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: Container(
                        child: ModelViewer(
                          src: 'assets/avatar0.glb',
                          alt: 'A 3D model of AI avatar',
                          cameraOrbit: "0deg 90deg 0deg",
                          ar: false,
                          autoRotate: false,
                          disableZoom: true,
                          disableTap: true,
                          cameraControls: false,
                          interactionPrompt: null,
                          interactionPromptThreshold: 0,
                          autoPlay: true,
                          animationName: 'wait',
                        ),
                      ),
                    ),
                  ],
                  ),
                ),

                // メインUI
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.05,),

                        Image.asset('assets/logo.png', height: MediaQuery.of(context).size.height * 0.4), // ロゴ画像

                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),

                        // STARTボタン
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.subColor, AppColors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: AppColors.white, width: 5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.subColor.withOpacity(0.7),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              showSendDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                            ),
                            child: Text(
                              'START',
                              style: TextStyle(
                                color: AppColors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 20,
                                    color: AppColors.black,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                                fontSize: MediaQuery.of(context).size.width * 0.15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),),

                        SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                        //DifficultyDropdown(), // 難易度選択

                        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                      ],
                    ),
                  ),
                ),
                const HelpButton(), // ヘルプを表示するボタン
              ]
          )
        )
    );
  }
}

// ヘルプを表示するボタン
class HelpButton extends StatelessWidget {
  const HelpButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 40, right: 20),
        child: IconButton(
          icon: Icon(Icons.help_outline, size: 50, color: AppColors.white),
          onPressed: () {
            _showHelpDialog(context);
          },
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return HelpDialog();
      },
    );
  }
}

class HelpDialog extends StatefulWidget {
  @override
  _HelpDialogState createState() => _HelpDialogState();
}

class _HelpDialogState extends State<HelpDialog> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  // ヘルプ内容
  final List<String> helpPages = [
    "まずは、画面下のSTARTボタンを押して、問題の送信方法を選ぼう！\n送信方法は、音声入力、画像入力(画像ファイルからor写真を撮影)、テキスト入力から選べます。\n音声や画像を送信した場合は、自動でテキストに変換されます。",
    "問題の送信方法を選んだら、問題文の編集をしよう！\nテキスト入力の場合はここで入力、音声や画像で入力した場合は、問題文を修正できます。",
    "問題文を決定したら、ラベルの編集をしよう！\n自動でいくつかのラベルが選択されます。問題にあったラベルを編集・追加してください。\n最大4つのラベルを選択することができます。",
    "ラベルを決定したら、AIとのチャットを開始！\nAIの質問に答えながら、問題を解いていこう！\n問題が解けたら、電球マークのボタンでチャットが終了できます。",
    "チャットを終えると、AIからのフィードバックと類題が表示されるよ！\nフィードバックを参考にして、類題から次の問題を始めてみよう！",
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("使い方", style: TextStyle(color: AppColors.black, fontSize: 22, fontWeight: FontWeight.bold)),

            SizedBox(height: 16),

            Container(
              height: 150,
              child: PageView.builder(
                controller: _pageController,
                itemCount: helpPages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: Text(helpPages[index], textAlign: TextAlign.left, style: TextStyle(color: AppColors.black, fontSize: 14)),
                  );
                },
              ),
            ),

            SizedBox(height: 16),

            // インジケーター（現在のページを示すドット）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(helpPages.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? AppColors.subColor : AppColors.black,
                  ),
                );
              }),
            ),

            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () {
                    _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                      : null,
                  child: Text("← 戻る", style: TextStyle(fontSize: 18)),
                ),
                TextButton(
                  onPressed: _currentPage < helpPages.length - 1
                      ? () {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                      : () {
                    Navigator.pop(context); // 最後のページならダイアログを閉じる
                  },
                  child: Text(_currentPage < helpPages.length - 1 ? "次へ →" : "閉じる", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// カメラを起動するボタン
class CameraButton extends StatelessWidget {
  final Function(String) onImagePicked;
  const CameraButton({Key? key, required this.onImagePicked}) : super(key: key);

  Future<void> file_to_text(File putfile) async {
    final inputImage = InputImage.fromFile(putfile);
    // TextRecognizerの初期化（scriptで日本語の読み取りを指定しています※androidは日本語指定は失敗するのでデフォルトで使用すること）
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);
    // 画像から文字を読み取る（OCR処理）
    final recognizedText = await textRecognizer.processImage(inputImage);

    onImagePicked(recognizedText.text);
    textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () async {
        /*Step 1:Pick image*/
        //Install image_picker
        //Import the corresponding library
        showDialog(
            context: context,
            builder: (context) {
              return SimpleDialog(
                title: Text('選択：', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),),
                children: [
                  SimpleDialogOption(
                    child: Text('写真ライブラリから選択', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),),
                    onPressed: () async {
                      Navigator.pop(context);
                      FilePickerResult? file = await FilePicker.platform.pickFiles(
                        type:  FileType.image, //写真ファイルのみ抽出
                        // allowedExtensions: ['png', 'jpeg'], // ピックする拡張子を限定できる。
                      );

                      if (file != null) {
                        String filename = file.files.first.name;
                        print(filename);

                        // File型に変換し文字に変換
                        file_to_text(File(file.files.first.path!));
                      }
                    },
                  ),
                  SimpleDialogOption(
                    child: Text('写真を撮影', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),),
                    onPressed: () async {
                      Navigator.pop(context);
                      ImagePicker picker = ImagePicker();
                      //写真を撮る
                      final pickedFile = await picker.pickImage(source: ImageSource.camera);

                      if (pickedFile != null) {
                        print(pickedFile.path);
                        // File型に変換し文字に変換
                        file_to_text(File(pickedFile.path));
                      }
                    },
                  )
                ],
              );
            }
        );
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          border: Border.all(color: AppColors.black, width: 2,),
          boxShadow: [
            BoxShadow(
              color: AppColors.background, // 影の色
              blurRadius: 6, // ぼかしの強さ
              offset: Offset(2, 2), // 影の位置
            ),
          ],
        ),
        child: Icon(Icons.camera_alt, size: screenWidth * 0.15, color: AppColors.black),
      ),
    );
  }
}

// 音声入力を行うボタン
class AudioButton extends StatefulWidget {
  final Function(String) onTextPicked;

  const AudioButton({Key? key, required this.onTextPicked}) : super(key: key);

  @override
  _AudioButtonState createState() => _AudioButtonState();
}
class _AudioButtonState extends State<AudioButton> {
  SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  // 音声認識開始・停止の制御
  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speech.listen(
        onResult: (result) {
          setState(() {
            var speechText = result.recognizedWords;
            print(speechText);
            widget.onTextPicked(speechText); // 音声認識結果をコールバックに渡す
          });
        },
      );
    } else {
      print("失敗");
      widget.onTextPicked("音声認識の初期化に失敗しました");
    }
  }
  //音声認識停止
  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        if (_isListening) {
          _stopListening(); // すでに認識中なら停止
          print("停止");
        } else {
          _startListening(); // 音声認識を開始
          print("開始");
        }
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          border: Border.all(color: AppColors.black, width: 2,),
          boxShadow: [
            BoxShadow(
              color: AppColors.background, // 影の色
              blurRadius: 6, // ぼかしの強さ
              offset: Offset(2, 2), // 影の位置
            ),
          ],
        ),
        child: Icon(
          _isListening ? Icons.stop : Icons.mic, // 音声認識中は停止ボタン、認識していないときはマイクボタン
          size: 64,
          color: Colors.black,
        ),
      ),
    );
  }
}

// 空の文字列を返すボタン
class EmptyTextButton extends StatelessWidget {
  final Function(String) onTextPicked;
  const EmptyTextButton({Key? key, required this.onTextPicked}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        onTextPicked("");
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          border: Border.all(color: AppColors.black, width: 2,),
          boxShadow: [
            BoxShadow(
              color: AppColors.background, // 影の色
              blurRadius: 6, // ぼかしの強さ
              offset: Offset(2, 2), // 影の位置
            ),
          ],
        ),
        child: Icon(Icons.text_snippet_outlined, size: 64, color: AppColors.black),
      ),
    );
  }
}

// 難易度設定をするドロップダウン
class DifficultyDropdown extends StatefulWidget {
  @override
  _DifficultyDropdownState createState() => _DifficultyDropdownState();
}
class _DifficultyDropdownState extends State<DifficultyDropdown> {
  String selectedDifficulty = '○○';
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButton<String>(
        value: selectedDifficulty,
        style: TextStyle(fontSize: 28, color: AppColors.black, fontWeight: FontWeight.bold),
        items: ['○○', '△△', '□□']
            .map((level) => DropdownMenuItem(
          value: level,
          child: Text(
            '難易度: $level',
            style: TextStyle(fontSize: 28, color: AppColors.black, fontWeight: FontWeight.bold),
          ),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedDifficulty = value!;
          });
        },
      ),
    );
  }
}

// 問題の送信方法を選択するダイアログ
void showSendDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => SendDialog(),
  );
}
class SendDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "問題を送る",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 30),
                  // アイコンオプションを並べる
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // マイクボタン
                      _sendOption(AudioButton(onTextPicked: (String text) {
                        print("音声認識: $text"); //デバック
                        if (text.isNotEmpty) {
                          Navigator.pop(context);
                          showEditDialog(context, text);
                        }
                      },), "音声入力"),
                      _sendOption(CameraButton(onImagePicked: (String text) {
                        if (text.isNotEmpty) {
                          Navigator.pop(context);
                          showEditDialog(context, text);
                        }
                      },), "画像入力"),
                      _sendOption(EmptyTextButton(onTextPicked: (String text) {
                        Navigator.pop(context);
                        showEditDialog(context, text);
                      },), "テキスト"),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            // 左上の戻るボタン
            Positioned(
              top: 24,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: 40),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _sendOption(Widget sendButton, String label) {
    return Column(
      children: [
        sendButton,
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 20, color: AppColors.black, fontWeight: FontWeight.bold),),
      ],
    );
  }
}

// 問題を編集するダイアログ
void showEditDialog(BuildContext context, String text) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Stack(
            children: [
              Positioned(
                top: MediaQuery.of(context).size.height * 0.1,
                left: 0,
                right: 0,
                child: EditDialog(editedText: text),
              ),
            ],
          );
        },
      );
    },
  );
}
class EditDialog extends StatefulWidget {
  final String editedText;
  const EditDialog({Key? key, required this.editedText}) : super(key: key);

  @override
  _EditDialogState createState() => _EditDialogState();
}
class _EditDialogState extends State<EditDialog> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.editedText);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: GestureDetector(
          onTap: () {
            // コンテナ内をタップしたときにもフォーカスをテキストフィールドの最後尾に移動
            FocusScope.of(context).requestFocus(_focusNode);
            _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("問題を編集", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                    SizedBox(height: 16),

                    Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.black, width: 2,),
                      ),
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode, // FocusNodeを設定
                          style: TextStyle(color: AppColors.black),
                          minLines: null,
                          maxLines: null,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            String editedText = _textController.text;
                            Navigator.pop(context);
                            showLabelDialog(context, editedText);
                          },
                          child: Text("次へ →", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 左上の戻るボタン
              Positioned(
                top: 24,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: 40),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSendDialog(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ラベルを編集するダイアログ
void showLabelDialog(BuildContext context, String text) {
  showDialog(
    context: context,
    builder: (context) => LabelDialog(editedText: text,),
  );
}
class LabelDialog extends StatefulWidget {
  final String editedText;
  const LabelDialog({Key? key, required this.editedText}) : super(key: key);

  @override
  _LabelDialogState createState() => _LabelDialogState();
}
class _LabelDialogState extends State<LabelDialog> {
  List<String> _suggestedLabels = []; // 推奨ラベル
  List<String?> selectedSubjects = List.filled(4, null); // 教科ドロップダウン選択
  List<String?> selectedCategories = List.filled(4, null); // 分類ドロップダウン選択

  @override
  void initState() {
    super.initState();
    // 初期化時にテキストを元にラベルを取得
    _getSuggestedLabels(widget.editedText);
  }

  // 推奨ラベルを取得
  Future<void> _getSuggestedLabels(String inputText) async {
    if (inputText.isEmpty) return;

    try {
      List<String> labels = await ApiService.classifyText(inputText);
      setState(() {
        _suggestedLabels = labels;
      });

      // ラベルを順番に設定
      _setDropdownValues();

      // ログ出力
      debugPrint("推奨ラベル: $labels");
    } catch (e) {
      debugPrint("エラー: $e");
    }
  }

  // 推奨ラベルを元にドロップダウンに順番に値をセット
  void _setDropdownValues() {
    if (_suggestedLabels.isEmpty) return;

    setState(() {
      for (int i = 0; i < _suggestedLabels.length && i < 4; i++) {
        String label = _suggestedLabels[i];

        List<String> parts = label.split(" - ");
        if (parts.length == 2) {
          selectedSubjects[i] = parts[0];  // 教科
          selectedCategories[i] = parts[1]; // 分類
        }
      }
    });
  }

  // テキストを保存し、類似検索
  Future<void> _storeText(String inputText, List<String> editedLabels) async {
    if (inputText.isEmpty || editedLabels.isEmpty) return;

    // 保存処理
    await ApiService.storeText(inputText, editedLabels);

    // ログ出力
    debugPrint("テキストを保存: $inputText");
    debugPrint("保存したラベル: $editedLabels");
  }

  // 教科と分類のドロップダウンペア
  Widget buildDropdownPair(int index) {
    return Row(
      children: [
        Container(
          width: 100,
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text("未選択"),
              value: selectedSubjects[index],
              onChanged: (String? newValue) {
                setState(() {
                  selectedSubjects[index] = newValue;
                  selectedCategories[index] = null; // 教科変更時に分類もリセット
                });
              },
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text("未選択"), // デフォルトのnull選択肢
                ),
                ...subjectCategories.keys.toSet().toList().map((String subject) { // 重複を削除
                  print("DropdownMenuItem value: $subject"); // デバッグ出力
                  return DropdownMenuItem<String>(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text("未選択"),
                value: selectedCategories[index],
                onChanged: selectedSubjects[index] == null ? null : (String? newValue) {
                  setState(() {
                    selectedCategories[index] = newValue;
                  });
                },
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text("未選択"), // デフォルトのnull選択肢
                  ),
                  ...(subjectCategories[selectedSubjects[index]] ?? []).map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ダイアログ部分
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              // テキスト編集フィールド
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("ラベルを編集", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                  SizedBox(height: 16),

                  // 4つのドロップダウンペアを縦に並べる
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.black, width: 2,),
                    ),
                    child: Column(
                      children: [
                        buildDropdownPair(0),
                        for (int i = 1; i < 4; i++) ...[
                          Divider(color: AppColors.black,),
                          buildDropdownPair(i),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          List<String> editedLabels = [];
                          for (int i = 0; i < 4; i++) {
                            if (selectedSubjects[i] != null && selectedCategories[i] != null) {
                              editedLabels.add("${selectedSubjects[i]} - ${selectedCategories[i]}");
                            }
                          }
                          _storeText(widget.editedText, editedLabels);

                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'editedText': widget.editedText,
                              'editedLabels': editedLabels,
                            },
                          );
                        },
                        child: Text("開始 →", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 左上の戻るボタン
            Positioned(
              top: 24,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: 40),
                onPressed: () {
                  Navigator.of(context).pop();
                  showEditDialog(context, widget.editedText);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
