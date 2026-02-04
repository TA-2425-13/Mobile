import 'package:app/model/chapter.dart';
import 'package:app/model/chapter_status.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/course_service.dart';
import 'package:app/service/user_chapter_service.dart';
import 'package:app/service/user_course_service.dart';
import 'package:app/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/model/badge.dart';
import 'package:app/model/course.dart';
import 'package:app/model/user.dart';
import 'package:app/model/user_course.dart';
import 'package:app/utils/colors.dart';
import 'package:app/view/chapter_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int id;

  const CourseDetailScreen({super.key, required this.id});

  @override
  State<CourseDetailScreen> createState()  => _CourseDetail();
}

class _CourseDetail extends State<CourseDetailScreen> {
  Course? courseDetail;
  List<Chapter> listChapter = [];
  late SharedPreferences pref;
  int idCourse = 0;
  int idUser = 0;
  bool isLoading = true;
  UserCourse? uc;
  Student? user;
  List<BadgeModel>? listBadge;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getCourseDetail();
    getUserFromSharedPreference();
  }

  Future<void> updateStatus(index) async {
    final result = await UserChapterService.updateChapterStatus(listChapter[index].status!.id, listChapter[index].status!);
    setState(() {
      listChapter[index].status = result;
    });
  }

  void getUser(int id) async {
    user = await UserService.getUserById(id);
  }

  void getCourseDetail() async {
    pref = await SharedPreferences.getInstance();
    setState(() {
      idCourse = pref.getInt('lastestSelectedCourse') ?? 0;
    });
    final idUser = pref.getInt('userId');
    if(idUser != null) {
      getUser(idUser);
    }
    if(idCourse != 0){
      final result = await CourseService.getCourse(idCourse);
      setState(() {
        courseDetail = result;
      });
      getChapter(idCourse);
      await getListBadge(idCourse);
    }
  }

  void getUserCourse() async {
    uc = await UserCourseService.getUserCourse(idUser, idCourse);
  }

  void updateUserCourse() async {
    await UserCourseService.updateUserCourse(uc!.id, uc!);
  }

  void getChapter(int id) async {
    setState(() {
      isLoading = true; // Start loading
    });

    final result = await CourseService.getChapterByCourse(id);
    final updatedList = await getStatusChapter(result);

    setState(() {
      listChapter = updatedList;
      isLoading = false; // Stop loading
    });
  }

  Future<void> getListBadge(int courseId) async {
    listBadge = await BadgeService.getBadgeListCourseByCourseId(courseId);
  }

  Future<List<Chapter>> getStatusChapter(List<Chapter> list) async {
    await Future.forEach(list, (Chapter chapter) async {
      chapter.status = await UserChapterService.getChapterStatus(idUser, chapter.id);
    });
    return list;
  }

  void getUserFromSharedPreference() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('userId') ?? 0;
    });
    if (idUser != 0 && idCourse != 0) {
      getUserCourse();
    }
  }

  int idOfBadge(int isCheckpoint) {
    int idbadge = 0;
    switch(isCheckpoint) {
      case 1 : {
        for(BadgeModel i in listBadge!) {
          if(i.type == 'BEGINNER') {
            idbadge = i.id as int;
          }
        }
      }
      case 2 : {
        for(BadgeModel i in listBadge!) {
          if(i.type == 'INTERMEDIATE') {
            idbadge = i.id as int;
          }
        }
      }
      case 3 : {
        for(BadgeModel i in listBadge!) {
          if(i.type == 'ADVANCE') {
            idbadge = i.id as int;
          }
        }
      }
      default : idbadge = 0;
    }
    return idbadge;
  }

  @override
  Widget build(BuildContext context) {
    return _buildDetailCourse();
  }

  Widget _buildDetailCourse() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
                image: AssetImage("lib/assets/learnbg.png"),
                fit: BoxFit.cover,
                opacity: 0.7
            ),
          ),
        ),
        idCourse != 0 && courseDetail != null
        ? Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Level', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
                const SizedBox(height: 4),
                Text(
                  courseDetail!.courseName,
                  style: TextStyle(fontSize: 12, fontFamily: 'DIN_Next_Rounded'),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryColor,
            titleTextStyle: TextStyle(
                fontFamily: 'DIN_Next_Rounded',
                fontSize: 24,
                color: Colors.white
            ),
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
          body: isLoading
          ? SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Mohon Tunggu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded'),
                  ),
                ],
              ),
            )
          )
          : Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              itemCount: listChapter.length,
              itemBuilder: (context, count) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: count <= uc!.currentChapter - 1 ? _buildCourseItem(count) : _buildCourseItemLocked(count),
                );
              },
            ),
          ),
        )
        : Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(
                        'lib/assets/pictures/background-pattern.png'),
                    fit: BoxFit.cover
                )
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('lib/assets/pixels/lock-pixel.png', height: 50,),
                      SizedBox(height: 16,),
                      Text('Belum ada Course yang dikerjakan', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold,color: AppColors.primaryColor),),
                      Text('Akses course terlebih dahulu untuk mengaktifkan halaman ini!', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'DIN_Next_Rounded'),),
                    ],
                  )
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseItem(int index) {
    final chapter = listChapter[index];

    return Padding(
      padding: index == listChapter.length - 1 ? EdgeInsets.only(top: 32, bottom: 16) : EdgeInsets.only(top: 32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppColors.primaryColor,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                uc?.currentChapter = uc!.currentChapter < chapter.level ? chapter.level : uc!.currentChapter;
                updateUserCourse();
                if (!chapter.status!.isStarted){
                  chapter.status?.timeStarted = DateTime.now();
                  chapter.status?.isStarted = true;
                }
                updateStatus(index);

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Chapterscreen(
                      status: chapter.status!,
                      chapterIndexInList: index,
                      uc: uc!,
                      chLength: listChapter.length,
                      user: user!,
                      chapterName: listChapter[index].name,
                      idBadge: idOfBadge(listChapter[index].isCheckpoint),
                      level: listChapter[index].level,
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    listChapter[result['index']].status = ChapterStatus.fromJson(result['status']);
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
                child: Column(
                  children: [
                    SizedBox(height: 48), // Space for the floating badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusIcon(chapter.status!.materialDone, Icons.menu_book),
                        SizedBox(width: 10),
                        _buildStatusIcon(chapter.status!.assessmentDone, Icons.task),
                        SizedBox(width: 10),
                        _buildStatusIcon(chapter.status!.assignmentDone, Icons.file_copy),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      chapter.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                          fontFamily: 'DIN_Next_Rounded'
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      chapter.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                          fontFamily: 'DIN_Next_Rounded'
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          listChapter[index].isCheckpoint == 1
          ? Positioned(
            top: 32, // Offset to be outside the card
            right: 32,
            child: Icon(
              LineAwesomeIcons.medal_solid,
              size: 50,
              color: chapter.status!.materialDone && chapter.status!.assessmentDone && chapter.status!.assignmentDone
              ? Colors.tealAccent :Colors.white54
            )
          )
          : listChapter[index].isCheckpoint == 2
          ? Positioned(
            top: 32, // Offset to be outside the card
            right: 32,
            child: Icon(
              LineAwesomeIcons.medal_solid,
              size: 50,
                color: chapter.status!.materialDone && chapter.status!.assessmentDone && chapter.status!.assignmentDone
                ? Colors.blueAccent :Colors.white54
            )
          )
          : listChapter[index].isCheckpoint == 3
          ? Positioned(
            top: 32, // Offset to be outside the card
            right: 32,
            child: Icon(
              LineAwesomeIcons.medal_solid,
              size: 50,
                color: chapter.status!.materialDone && chapter.status!.assessmentDone && chapter.status!.assignmentDone
                ? Colors.redAccent :Colors.white54
            )
          )
          : SizedBox(),
          // Floating Level Badge
          Positioned(
            top: -25, // Offset to be outside the card
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryColor, // Base green color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade900,
                      spreadRadius: 2,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Level text
                    Center(
                      child: Text(
                        '${chapter.level}',
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontFamily: 'Modak',
                          shadows: [
                            Shadow(
                              color: Colors.green.shade900.withOpacity(0.7), // Shadow behind text
                              blurRadius: 0,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItemLocked(int index) {
    final chapter = listChapter[index];

    return Padding(
      padding: index == listChapter.length - 1 ? EdgeInsets.only(top: 32, bottom: 16) : EdgeInsets.only(top: 32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: AppColors.lightGrey,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40,),
                      Icon(Icons.lock, size: 50, color: AppColors.darkGrey),
                      SizedBox(height: 10),
                      Text(
                        "Selesaikan dahulu level sebelumnya!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: AppColors.darkGrey, fontFamily: 'DIN_Next_Rounded'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Level Badge
          Positioned(
            top: -25, // Offset to be outside the card
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade600, // Base green color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade900.withOpacity(0.8),
                      blurRadius: 10, // Increased for a softer shadow
                      spreadRadius: 2,
                      offset: Offset(0, 6), // Adjusted offset for realistic shadowing
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${chapter.level}',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontFamily: 'Modak',
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 4, // Added blur for better depth
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Status Icons
  Widget _buildStatusIcon(bool isDone, IconData icon) {
    return Icon(
      icon,
      size: 24,
      color: isDone ? Colors.yellow : Colors.white54,
    );
  }
}