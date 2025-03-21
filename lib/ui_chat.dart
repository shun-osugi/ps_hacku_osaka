import 'package:flutter/material.dart';
import 'main.dart';
import 'ui_result.dart';
import 'colors.dart';
import 'tts_service.dart';

// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
const apiKey = 'AIzaSyBKSKfHy_6DjTpx-3Zep78Vf-FXZWP1Tsw';

class chat{
  int p; //0:自分 1:相手
  String str; //会話内容
  chat(this.p,this.str);
}

void main() {
  runApp(ChatPage());
}

class ChatPage extends StatefulWidget {

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String inputText = "";
  bool isFirstSend = false;
  bool _isSending = false;
  List<String> labels = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<chat> chats = []; //会話リスト
  late final GenerativeModel _model;
  late final ChatSession AI;
  late List<dynamic> similarQuestions = [];
  final TTSService _ttsService = TTSService(); //音声読み上げサービス

  @override
  void initState() {
    super.initState();
    // dotenv.load(fileName: ".env");
    // var apiKey = dotenv.get('GEMINI_API_KEY');
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    AI = _model.startChat();
    AI.sendMessage(Content.text('これから送る問題を教えて欲しいのですが、解き方を一気に教えられても難しいので順序立てて出力し、こちらの解答を待ってから次にやることを出力するようにしてください'));
    AI.sendMessage(Content.text('こちらが答えるとき，文章で説明し回答しなければならないような質問を，ときどきお願いします'));
    AI.sendMessage(Content.text('出力は数式表現や文字効果（**A**などの），コードフィールドなどの環境依存のものは無しでプレーンテキストでお願いします'));
    AI.sendMessage(Content.text('出力文字数は，多くても100文字程度になるようにしてください'));
    AI.sendMessage(Content.text('口調は友達のような感じで大丈夫だよ！'));
  }

  void _sendMessage() {
    if (_isSending) return;

    String text = _textController.text.trim(); // 入力値を取得し、前後の空白を削除
    if (text.isEmpty) return; // 入力が空の場合は送信しない

    setState(() {
      _isSending = true;
      chats.add(chat(0, text)); // ユーザーのメッセージを会話リストに追加
    });
    _getAIResponse(text); // AIからの応答を取得
    _textController.clear(); // 入力欄をクリア

    // メッセージ送信後にスクロールを最下部に移動
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0.0, // 一番下に移動
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _getAIResponse(String userMessage) async {
    final response = await AI.sendMessage(Content.text(userMessage)); // AIにメッセージを送信
    String aiMessage = response.text ?? 'AIの返答に失敗しました'; // AIの返答を取得

    setState(() {
      chats.add(chat(1, aiMessage)); // AIの返答を会話リストに追加
      _isSending = false;
    });

    //AI側のメッセージを読み上げ（新しいメッセージがきたら新しい方を読み上げはじめる）
    await _ttsService.stop();
    await _ttsService.speak(aiMessage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 引数を受け取る
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      // inputTextを取得
      final receivedText = args['inputText'] as String?;
      if (receivedText != null && !isFirstSend) {
        setState(() {
          chats.add(chat(0, receivedText));
        });
        _getAIResponse(receivedText);
        isFirstSend = true;
        inputText = receivedText;
      }

      // labelsを取得
      final receivedLabels = args['labels'] as List<String>?;
      if (receivedLabels != null) {
        labels = receivedLabels;
      }

      // similarQuestionsを取得
      /*final receivedSimilarQuestions = args['similarQuestions'] as List<dynamic>?;
      if (receivedSimilarQuestions != null) {
        similarQuestions = receivedSimilarQuestions;
      }*/
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      body: Stack(
        children: [
          // アバター表示
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            left: MediaQuery.of(context).size.width * -0.1,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.26,
              width: MediaQuery.of(context).size.width * 0.7,
              child: ModelViewer(
                src: 'assets/avatar0.glb',
                alt: 'A 3D model of AI avatar',
                cameraOrbit: "-25deg 90deg 0deg",
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

          Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: MediaQuery.of(context).size.width * 0.05,
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.subColor, AppColors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Text('イオ', style: TextStyle(
                    color: AppColors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: AppColors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,),)
              )
          ),

          // 会話部分
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05,),

              // 問題文を表示するボタン
              Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.subColor, AppColors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppColors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mainColor.withOpacity(0.7),
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.95,
                            height: MediaQuery.of(context).size.height * 0.6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.subColor, AppColors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.white, width: 4),
                            ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    icon: Icon(Icons.close, color: AppColors.white,),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      inputText,
                                      style: TextStyle(
                                        color: AppColors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),),
                        );
                      },
                    );
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
                    inputText,
                    style: TextStyle(
                      color: AppColors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: AppColors.black,
                          offset: Offset(0, 0),
                        ),
                      ],
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.22),

              // チャット部分
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(16),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[chats.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: chat.p == 0
                            ? MainAxisAlignment.end // ユーザー: 右寄せ
                            : MainAxisAlignment.start, // AI: 左寄せ
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                                  minWidth: MediaQuery.of(context).size.width * 0.2,
                                ),
                                child: IntrinsicWidth(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    margin: EdgeInsets.only(bottom: 8, left: chat.p == 0 ? 40 : 8, right: chat.p == 0 ? 8 : 40),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [chat.p == 0 ? AppColors.mainColor : AppColors.subColor, chat.p == 0 ? AppColors.mainColor : AppColors.white],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      chat.str,
                                      style: TextStyle(color: chat.p == 0 ? AppColors.white : AppColors.black, fontSize: 16, fontWeight: FontWeight.bold,),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: chat.p == 0 ? 0 : null, // ユーザー（右側）の場合はbottomに配置
                                top: chat.p != 0 ? 0 : null,     // AI（左側）の場合はtopに配置
                                right: chat.p == 0 ? 8 : null,
                                left: chat.p == 0 ? null : 8,
                                child: CustomPaint(
                                  painter: ChatBubbleTriangle(p: chat.p),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 入力部分
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        cursorColor: _isSending ? AppColors.subColor : AppColors.mainColor,
                        controller: _textController,
                        enabled: !_isSending,
                        decoration: InputDecoration(
                          hintText: _isSending ? "イオの応答を待っています..." : "メッセージを入力...",
                          hintStyle: TextStyle(color: AppColors.mainColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.mainColor,
                              width: 2, // 枠線の太さ
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _isSending ? null : _sendMessage,
                      child: Icon(Icons.send, color: AppColors.white),
                      backgroundColor: _isSending ? AppColors.background : AppColors.mainColor,
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            ],
          ),

          // ボタングループ
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: MediaQuery.of(context).size.width * 0.5,
            child: Container(
                width: MediaQuery.of(context).size.width * 0.4,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ホームボタン
                      CircleIconButton(
                        icon: Icons.home,
                        onPressed: () {
                          Navigator.pushNamed(context, '/home');
                        },
                      ),

                      SizedBox(height: MediaQuery.of(context).size.width * 0.1),

                      // やり直しボタン
                      CircleIconButton(
                        icon: Icons.change_circle_outlined,
                        onPressed: () {
                          setState(() {
                            chats.clear();
                            chats.add(chat(0, inputText));
                          });
                          AI.sendMessage(Content.text('もう一度始めから教えて！'));
                          _getAIResponse(inputText);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                  // チャット終了ボタン
                  Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.06,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentColor, AppColors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: AppColors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentColor.withOpacity(0.7),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async { //フィードバックへ遷移
                        final feedback = await AI.sendMessage(Content.text('今回の会話はどうだった？私が苦手なところとか分かったら短く一文で教えてほしいな。またね！'));
                        final feedbackMessage = feedback.text ?? 'フィードバックの作成に失敗しました';
                        Navigator.pushNamed(
                          context, '/result',
                          arguments: {
                            'inputText': inputText,
                            'feedbackText': feedbackMessage,
                            'labels': labels,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        '解けた！',
                        style: TextStyle(
                          color: AppColors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: AppColors.black,
                              offset: Offset(0, 0),
                            ),
                          ],
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              )
            ),
          ),

        ],
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color color;
  final Color shadowColor;

  const CircleIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.size = 60.0,
    this.color = AppColors.mainColor,
    this.shadowColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.7),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: size * 0.6,
          color: Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class ChatBubbleTriangle extends CustomPainter {
  final int p;

  ChatBubbleTriangle({required this.p});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = p == 0 ? AppColors.mainColor : AppColors.subColor
      ..style = PaintingStyle.fill;

    final Path path = Path();
    if (p == 0) {
      // 右下に三角形
      path.moveTo(-44, -8);
      path.quadraticBezierTo(-32, 8, -8, 16);
      path.quadraticBezierTo(-18, 8, -24, -8);
    } else {
      // 左上に三角形
      path.moveTo(44, 0);
      path.quadraticBezierTo(32, -16, 8, -24);
      path.quadraticBezierTo(18, -16, 24, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}