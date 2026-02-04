import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import 'package:app/global_var.dart';
import 'package:app/model/assessment.dart';
import 'package:app/model/chapter_status.dart';
import 'package:app/model/user.dart';
import 'package:app/service/chapter_service.dart';
import 'package:app/service/user_chapter_service.dart';
import 'package:app/utils/colors.dart';

class AssessmentScreen extends StatefulWidget {
  final ChapterStatus status;
  final Student user;
  final int? courseId;
  final int? level;
  final String? chapterName;
  final Function(bool) updateMaterialLocked;
  final Function(ChapterStatus) updateStatus;
  final Function(bool) updateAssessmentStarted;
  final Function(bool) updateAssessmentFinished;
  const AssessmentScreen({
    super.key,
    required this.status,
    required this.user,
    this.courseId,
    this.level,
    this.chapterName,
    required this.updateMaterialLocked,
    required this.updateStatus,
    required this.updateAssessmentStarted,
    required this.updateAssessmentFinished
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool _assessmentStarted = false;
  bool _assessmentFinished = false;
  bool tapped = false;
  bool assessmentDone = false;
  bool allQuestionsAnswered = false;
  int correctAnswer = 0;
  int _grade = 0;
  int _pointsEarned = 0;
  String? _aiFeedback;
  String? _newDifficultyLabel;
  bool _isSubmitting = false;
  Student? user;
  late ChapterStatus status;
  Assessment? question;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    getAssessment(widget.status.chapterId);
    allQuestionsAnswered = widget.status.assessmentDone;
    assessmentDone = widget.status.assessmentDone;
    status = widget.status;
    user = widget.user;
    _assessmentFinished = assessmentDone;
    tapped = assessmentDone;
    _grade = status.assessmentGrade;
    super.initState();
  }

  void getAssessment(int id) async {
    final resultAssessment = await ChapterService.getAssessmentByChapterId(id);
    setState(() {
      question = resultAssessment;
    });
    if (assessmentDone) {
      _prefillCompletedAnswers();
    }
  }

  void _prefillCompletedAnswers() {
    if (question == null || status.assessmentAnswer.isEmpty) {
      return;
    }

    int tempCorrect = 0;
    for (int index = 0; index < question!.questions.length; index++) {
      if (index >= status.assessmentAnswer.length) {
        break;
      }
      final answer = status.assessmentAnswer[index];
      question!.questions[index].selectedAnswer = answer;
      final isCorrect = answer.trim().toLowerCase() ==
          question!.questions[index].correctedAnswer.trim().toLowerCase();
      question!.questions[index].isCorrect = isCorrect;
      if (isCorrect) {
        tempCorrect++;
      }
    }

    setState(() {
      correctAnswer = tempCorrect;
    });
  }

  void _showFinishConfirmation() {
    setState(() {
      // isSubmitted = true;
      allQuestionsAnswered = question!.questions.every(
            (q) => q.selectedAnswer.isNotEmpty || q.selectedMultAnswer.isNotEmpty,
      );
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Selesaikan Assessment', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor),),
        content: Text('Apakah anda yakin ingin menyelesaikan assessment?', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    updateProgressAssessment();
                  },
                  child: Text('Selesai', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  updateProgressAssessment() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(allQuestionsAnswered) {
        showCompletionDialog(context, "🎉 Great! You’ve answered all questions!");
      } else {
        showCompletionDialog(context, "⚠️ You missed some questions, check again!");
      }
    });
  }

  void showCompletionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            !allQuestionsAnswered ? "Progress Not Completed!" : "Progress Completed!",
            style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('lib/assets/pixels/check.png', height: 72),
                SizedBox(height: 16,),
                Text(
                  message,
                  style: TextStyle(fontFamily: 'DIN_Next_Rounded'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor
                ),
                onPressed: () {
                  if(allQuestionsAnswered) {
                    Navigator.pop(context);
                    _submitAssessment();
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  "OK",
                  style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white),
                ),
              ),
            ),
          ],
        );

      },
    );
  }

  Future<void> _submitAssessment() async {
    if (question == null || user == null || _isSubmitting) {
      return;
    }

    final answersPayload = question!.questions.asMap().entries.map((entry) {
      final selected = entry.value.selectedAnswer.isNotEmpty
          ? entry.value.selectedAnswer
          : entry.value.selectedMultAnswer.join(', ');
      return {
        'index': entry.key,
        'answer': selected,
      };
    }).toList();

    final payload = {
      'userId': user!.id,
      'chapterId': status.chapterId,
      'answers': answersPayload,
    };

    setState(() {
      _isSubmitting = true;
    });

    bool loaderVisible = false;
    if (mounted) {
      loaderVisible = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ).then((_) {
        loaderVisible = false;
      });
    }

    try {
      final response = await http.post(
        Uri.parse('${GlobalVar.baseUrl}/assessment/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal mengirim jawaban assessment');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _applySubmissionResult(data);
    } catch (error) {
      _showSubmissionError(error.toString());
    } finally {
      if (loaderVisible && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _applySubmissionResult(Map<String, dynamic> data) {
    if (question == null) {
      return;
    }

    final evaluations = data['evaluations'] as List<dynamic>?;
    final answers = question!.questions.map((q) => q.selectedAnswer).toList();

    setState(() {
      _grade = (data['grade'] ?? 0) as int;
      _pointsEarned = (data['pointsEarned'] ?? 0) as int;
      _aiFeedback = data['aiFeedback'] as String?;
      _newDifficultyLabel = data['newDifficulty']?.toString();
      correctAnswer = (data['correctAnswers'] ?? correctAnswer) as int;
      assessmentDone = true;
      status.assessmentDone = true;
      status.assessmentGrade = _grade;
      status.assessmentAnswer = answers;
      allQuestionsAnswered = true;
      tapped = true;
      _assessmentFinished = true;
      user?.points = (user?.points ?? 0) + _pointsEarned;
    });

    _applyEvaluationsToQuestions(evaluations);

    widget.updateStatus(status);
    widget.updateAssessmentFinished(true);
    widget.updateAssessmentStarted(false);
    widget.updateMaterialLocked(false);
    updateStatus();
  }

  void _applyEvaluationsToQuestions(List<dynamic>? evaluations) {
    if (question == null || evaluations == null) {
      return;
    }

    for (final evaluation in evaluations) {
      if (evaluation is! Map<String, dynamic>) {
        continue;
      }
      final index = evaluation['index'];
      if (index is! int || index < 0 || index >= question!.questions.length) {
        continue;
      }
      final submitted = (evaluation['submittedAnswer'] ?? '').toString();
      final isCorrect = evaluation['isCorrect'] == true;
      question!.questions[index].selectedAnswer = submitted;
      question!.questions[index].isCorrect = isCorrect;
      question!.questions[index].score = isCorrect
          ? (100 / question!.questions.length).ceil()
          : 0;
    }
  }

  void _showSubmissionError(String message) {
    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gagal Mengirim Jawaban'),
        content: Text(message, style: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          )
        ],
      ),
    );
  }

  Future<void> updateStatus() async {
    status = await UserChapterService.updateChapterStatus(status.id, status);
  }

  @override
  Widget build(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (!_assessmentStarted && !widget.status.assessmentDone) {
      return _buildAssessmentInitial(isLandscape: isLandscape);
    } else if (!_assessmentFinished && !widget.status.assessmentDone ) {
      return question != null && question!.questions.isNotEmpty
          ? Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/assets/pictures/background-pattern.png'
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: !isLandscape ? const EdgeInsets.all(16.0) : const EdgeInsets.all(0.0),
              child: LinearProgressIndicator(
                value: question!.questions
                    .where((q) =>
                q.selectedAnswer.isNotEmpty ||
                    q.selectedMultAnswer.isNotEmpty)
                    .length /
                    question!.questions.length,
                backgroundColor: Colors.grey.shade300,
                valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
            Padding(
              padding: !isLandscape ? const EdgeInsets.all(8.0) : const EdgeInsets.all(1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  question!.questions.length,
                      (index) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: _currentPage == index
                                ? AppColors.primaryColor
                                : question!.questions[index].selectedAnswer.isNotEmpty || question!.questions[index].selectedMultAnswer.isNotEmpty
                                ? AppColors.secondaryColor
                                : Colors.grey.shade400,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ),

            // CONTENT
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: question!.questions.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, count) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _buildSingleQuestion(count),
                  );
                },
              ),
            ),

            // PAGE ACTION BUTTON
            !isLandscape ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor
                    ),
                    onPressed:
                    _currentPage > 0
                        ? () {
                      _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut
                      );
                    }
                        : null,
                    icon: Icon(LineAwesomeIcons.angle_left_solid, color: Colors.white),
                    label: Text('Back', style: TextStyle(color: Colors.white, fontFamily: 'DIN_Next_Rounded'),),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor
                    ),
                    onPressed: () {
                      if (_currentPage < question!.questions.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _showFinishConfirmation();
                      }
                    },
                    icon: Icon(LineAwesomeIcons.angle_right_solid, color: Colors.white),
                    iconAlignment: IconAlignment.end,
                    label: Text(_currentPage < question!.questions.length - 1
                        ? 'Next'
                        : 'Finish', style: TextStyle(color: Colors.white, fontFamily: 'DIN_Next_Rounded')),
                  ),
                ],
              ),
            ) : Row (
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor
                  ),
                  onPressed:
                  _currentPage > 0
                      ? () {
                    _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut
                    );
                  }
                      : null,
                  icon: Icon(LineAwesomeIcons.angle_left_solid, color: Colors.white),
                  label: Text('Back', style: TextStyle(color: Colors.white, fontFamily: 'DIN_Next_Rounded'),),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor
                  ),
                  onPressed: () {
                    if (_currentPage < question!.questions.length - 1) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _showFinishConfirmation();
                    }
                  },
                  icon: Icon(LineAwesomeIcons.angle_right_solid, color: Colors.white),
                  iconAlignment: IconAlignment.end,
                  label: Text(_currentPage < question!.questions.length - 1
                      ? 'Next'
                      : 'Finish', style: TextStyle(color: Colors.white, fontFamily: 'DIN_Next_Rounded')),
                ),
              ],
            ),
          ],
        ),
      )
          : _emptyState();
    } else {
      if(question != null && assessmentDone){
        tapped = true;
        return _buildQuizResult();
      } else {
        return _emptyState();
      }
    }
  }

  Widget _buildAssessmentInitial({bool isLandscape = false}) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
              'lib/assets/pictures/background-pattern.png'
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: !isLandscape ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('lib/assets/pixels/assessment-pixel.png', height: 50),
              SizedBox(height: 16),
              Text(
                'Assessment',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded'),
              ),
              SizedBox(height: 4),
              Text(
                question?.instruction ?? 'Pilihlah jawaban yang menurut anda paling benar!',
                style: TextStyle(fontFamily: 'DIN_Next_Rounded'),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _assessmentStarted = true;
                      print("Starttt Anjinggggggg");
                      widget.updateAssessmentStarted(_assessmentStarted);
                      widget.updateMaterialLocked(true);
                    });
                  },
                  icon: Icon(LineAwesomeIcons.paper_plane, color: Colors.white,),
                  label: Text('Mulai', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
                ),
              ),
            ],
          ) : SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('lib/assets/pixels/assessment-pixel.png', height: 50),
                SizedBox(height: 16),
                Text(
                  'Assessment',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded'),
                ),
                SizedBox(height: 4),
                Text(
                  question?.instruction ?? 'Pilihlah jawaban yang menurut anda paling benar!',
                  style: TextStyle(fontFamily: 'DIN_Next_Rounded'),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _assessmentStarted = true;
                        widget.updateAssessmentStarted(_assessmentStarted);
                        widget.updateMaterialLocked(true);
                      });
                    },
                    icon: Icon(LineAwesomeIcons.paper_plane, color: Colors.white,),
                    label: Text('Mulai', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
                  ),
                ),
              ],
            ),
          )
        ),
      ),
    );
  }

  Widget _buildQuestion(int number) {
    switch (question?.questions[number].type) {
      case 'PG':
      case 'TF':
      case 'MC':
        return Card.outlined(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Text('${number + 1}', style: TextStyle(fontSize: 20, fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor)),
              isThreeLine: true,
              title: Column(
                children: [
                  allQuestionsAnswered && tapped ? Text("Skor : ${question?.questions[number].score} / ${(100 / (question!.questions.length)).ceil()}", style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold)) : SizedBox(),
                  Text(question?.questions[number].question ?? 'No question available', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
                ],
              ),
              subtitle: question?.questions[number].option.isNotEmpty ?? false
                  ? _buildChoiceAnswer(question!.questions[number], number)
                  : null,
            ),
          ),
        );
      case 'EY':
        return Card.outlined(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Text('${number + 1}', style: TextStyle(fontSize: 20, fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor)),
              isThreeLine: true,
              title: Column(
                children: [
                  allQuestionsAnswered && tapped ? Text("Skor : ${question?.questions[number].score} / ${(100 / (question!.questions.length)).ceil()}", style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold)) : SizedBox(),
                  Text(question?.questions[number].question ?? 'No question available', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
                ],
              ),
              subtitle: _buildTextAnswer(question!.questions[number]),
            ),
          ),
        );
      default:
        return const SizedBox(
          width: double.infinity,
          height: 100,
          child: Center(
            child: Text('There is no Question yet', style: TextStyle(fontFamily: 'DIN_Next_Rounded'),),
          ),
        );
    }
  }

  Widget _buildSingleQuestion(int number) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question?.questions[number].question ?? 'Belum ada pertanyaan',
            style: TextStyle(fontFamily: 'DIN_Next_Rounded'),
          ),
          SizedBox(height: 16),
          if (question?.questions[number].type == 'TF')
            _buildTFOptions(question!.questions[number], number)
          else if (question?.questions[number].type == 'MC')
            _buildChoiceAnswer(question!.questions[number], number)
          else if (question?.questions[number].type == 'EY')
              _buildTextAnswer(question!.questions[number]),
        ],
      ),
    );
  }

  Widget _buildTFOptions(Question q, int number){
    return Row(
      children: [
        ElevatedButton(onPressed: (){
          setState(() {
            q.selectedAnswer = 'True';
          });
        }, child: Text("True"), style: ElevatedButton.styleFrom(backgroundColor: q.selectedAnswer == "True" ? Colors.blue : Colors.grey),),
        SizedBox(width: 10,),
        ElevatedButton(onPressed: (){
          setState(() {
            q.selectedAnswer = 'False';
          });
        }, child: Text("False"), style: ElevatedButton.styleFrom(backgroundColor: q.selectedAnswer == "False" ? Colors.blue : Colors.grey),)
      ],
    );
  }

  Widget _buildChoiceAnswer(Question question, int number) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: question.option.map((answer) {
        final bool isSelected = question.selectedAnswer == answer;
        final bool isCorrectAnswer = answer == question.correctedAnswer;
        final bool isIncorrectSelected = isSelected && !question.isCorrect;

        Color borderColor;
        Color backgroundColor;

        if (tapped) {
          if (isIncorrectSelected) {
            borderColor = Colors.red;
            backgroundColor = Colors.red.shade50;
          } else if (isCorrectAnswer) {
            borderColor = AppColors.secondaryColor;
            backgroundColor = Colors.green.shade50;
          } else {
            borderColor = Colors.grey.shade300;
            backgroundColor = Colors.white;
          }
        } else {
          borderColor = isSelected ? AppColors.primaryColor : Colors.grey.shade300;
          backgroundColor = isSelected ? Colors.deepPurple.shade50 : Colors.white;
        }

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.2),
                blurRadius: 6,
                spreadRadius: 1,
                offset: Offset(0, 2),
              )
            ]
                : [],
          ),
          child: RadioListTile<String>(
            title: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'DIN_Next_Rounded',
                color: isSelected ? AppColors.primaryColor : Colors.black87,
              ),
            ),
            value: answer,
            groupValue: question.selectedAnswer,
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.zero,
            onChanged: tapped
                ? null
                : (String? value) {
              if (value != null) {
                setState(() {
                  question.selectedAnswer = value;
                  question.isCorrect = value == question.correctedAnswer;
                });
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextAnswer(Question question) {
    TextEditingController controller = TextEditingController(text: question.selectedAnswer ?? '');
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Jawaban:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'DIN_Next_Rounded',
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: controller, // ✅ Always initializes with selectedAnswer
              maxLines: 4,
              minLines: 2,
              keyboardType: TextInputType.multiline,
              readOnly: allQuestionsAnswered && tapped ? true : false,
              style: TextStyle(
                fontFamily: 'DIN_Next_Rounded',
              ),
              decoration: InputDecoration(
                hintText: "Ketikkan jawaban anda...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.deepPurple.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                ),
                contentPadding: EdgeInsets.all(16),
              ),
              enabled: !tapped,

              onChanged: (String answer) {
                setState(() {
                  question.selectedAnswer = answer; // ✅ Saves the answer
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResult() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
              'lib/assets/pictures/background-pattern.png'
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: AppColors.primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hasil Assessment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'DIN_Next_Rounded')),
                          SizedBox(height: 4),
                          Table(
                            columnWidths: {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Text('Jumlah Benar', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Text(': $correctAnswer / ${question!.questions.length}', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded', color: Colors.white),),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Text('Skor', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Text(': $_grade / 100', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Text('Poin', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Text(': +$_pointsEarned', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_newDifficultyLabel != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.deepPurple),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tingkat kesulitan berikutnya: $_newDifficultyLabel',
                              style: const TextStyle(fontFamily: 'DIN_Next_Rounded'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (_aiFeedback != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Masukan AI', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
                          const SizedBox(height: 8),
                          Text(_aiFeedback!, style: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 8),
              Column(
                children: List.generate(
                  question!.questions.length,
                      (count) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _buildQuestion(count),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          )
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('lib/assets/empty.png', width: 120, height: 120),
          SizedBox(height: 20),
          Text(
            'No questions available yet.',
            style: TextStyle(fontSize: 16, fontFamily: 'DIN_Next_Rounded'),
          ),
        ],
      ),
    );
  }
}
