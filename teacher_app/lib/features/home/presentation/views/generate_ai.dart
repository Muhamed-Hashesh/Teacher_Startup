import 'package:flutter/material.dart';
import 'package:teacher_app/features/home/presentation/views/widgets/manual_dialog.dart';
import 'package:teacher_app/features/quiz/presentation/views/live_exam.dart';
import 'package:teacher_app/features/home/presentation/data/question_generator.dart';
import 'package:teacher_app/widgets/ai_generated_question.dart';
import 'package:teacher_app/widgets/manual_question_form.dart';


class GeneratePage extends StatefulWidget {
  const GeneratePage({super.key});

  @override
  GeneratePageState createState() => GeneratePageState();
}

class GeneratePageState extends State<GeneratePage> {
  final List<Map<String, dynamic>> _manuallyAddedQuestions = [];
  final List<bool> _isCorrectAnswerVisible = [];
  bool generateQuestions = false;
  bool isGenerateMoreQuestions = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> questions_AI = [];
  String _subject = '';

  Future<void> _fetchQuestions({bool isGenerateMore = false}) async {
    if (_subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      if (!isGenerateMore) {
        questions_AI = [];
        generateQuestions = false;
        isGenerateMoreQuestions = false;
      }
    });

    try {
      List<Map<String, dynamic>> newQuestions = await QuestionGenerator.generateQuestions(_subject);

      for (var question in newQuestions) {
        question['selected'] ??= false;
      }

      if (isGenerateMore) {
        List<Map<String, dynamic>> selectedQuestions = questions_AI.where((q) => q['selected'] == true).toList();

        questions_AI = List.from(selectedQuestions);
        questions_AI.addAll(newQuestions.where((q) => !q['selected']).take(10 - selectedQuestions.length));
      } else {
        questions_AI = newQuestions;
      }

      setState(() {
        questions_AI = questions_AI.take(10).toList();
        generateQuestions = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Questions generated successfully')),
      );

    } catch (e) {
      debugPrint('Error generating questions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error generating questions')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    double horizontalPadding = screenWidth * 0.05;
    double verticalPadding = screenHeight * 0.02;
    double fontSize = screenWidth * 0.045;
    double buttonFontSize = screenWidth * 0.04;

    fontSize = fontSize.clamp(14.0, 20.0);
    buttonFontSize = buttonFontSize.clamp(12.0, 18.0);

    return Scaffold(
      drawer: const Drawer(
        backgroundColor: Colors.white,
      ),
      appBar: AppBar(
        foregroundColor: Colors.white,
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 1, 151, 168),
        title: Text(
          "Generate Quiz using AI",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Which lesson or topic do you want the questions to be about?",
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: verticalPadding),
            Container(
              height: screenHeight * 0.1,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Outline lesson or topic",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: fontSize * 0.9,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    _subject = value;
                  },
                ),
              ),
            ),
            SizedBox(height: verticalPadding * 2),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _fetchQuestions(isGenerateMore: false),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    backgroundColor: const Color.fromARGB(255, 1, 151, 168),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Generate Questions Using AI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: verticalPadding * 2),
            if (generateQuestions)
              ...List.generate(questions_AI.length, (index) {
                final question = questions_AI[index];
                final options = question['options'] as List<String>;
                return AiGeneratedQuestion(
                  question: question['question'],
                  options: options,
                  correctAnswer: question['answer'],
                  questionNumber: index,
                  selectedListItem: question['selected'],
                  onSelectionChanged: (bool isSelected) {
                    setState(() {
                      question['selected'] = isSelected;
                    });
                  },
                );
              }),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _fetchQuestions(isGenerateMore: true),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding / 2,
                        vertical: verticalPadding,
                      ),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: Text(
                      "Generate more questions",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ),
                SizedBox(width: horizontalPadding / 2),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final questionData =
                      await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (BuildContext context) {
                          return const ManualQuestionForm(
                            selectedFileName: '',
                          );
                        },
                      );

                      if (questionData != null) {
                        setState(() {
                          _manuallyAddedQuestions.add(questionData);
                          _isCorrectAnswerVisible.add(false);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding / 2,
                          vertical: verticalPadding * 1.66),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: Text(
                      "Ask Manually",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: verticalPadding * 2),
            if (isGenerateMoreQuestions)
              ...questions_AI
                  .where((question) => question['selected'] == true)
                  .map((question) {
                final options = question['options'] as List<String>;
                return AiGeneratedQuestion(
                  question: question['question'],
                  options: options,
                  correctAnswer: question['answer'],
                  questionNumber: questions_AI.indexOf(question),
                  selectedListItem: question['selected'],
                  onSelectionChanged: (bool value) {},
                );
              }).toList(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Filter selected questions
                  final selectedQuestions = questions_AI.where((q) => q['selected'] == true).toList();

                  if (selectedQuestions.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => LiveExam(questions: selectedQuestions),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one question to start the quiz')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: verticalPadding),
                  backgroundColor: const Color.fromARGB(255, 1, 151, 168),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Start Quiz",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_manuallyAddedQuestions.isNotEmpty) ...[
              SizedBox(height: verticalPadding * 2),
              Text(
                "Questions:",
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: verticalPadding),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _manuallyAddedQuestions.length,
                itemBuilder: (context, index) {
                  final question = _manuallyAddedQuestions[index];
                  final isCorrectAnswerVisible = _isCorrectAnswerVisible[index];
                  return QuestionCardGeneratingAi(
                    index: index,
                    questionData: question,
                    isCorrectAnswerVisible: isCorrectAnswerVisible,
                    onVisibilityToggle: () {
                      setState(() {
                        _isCorrectAnswerVisible[index] =
                        !_isCorrectAnswerVisible[index];
                      });
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}