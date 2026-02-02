import 'package:app/service/badge_service.dart';
import 'package:app/utils/colors.dart';
import 'package:app/view/course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/badge.dart';
import '../model/chapter.dart';
import '../model/course.dart';
import '../service/course_service.dart';

class CourseInitialScreen extends StatefulWidget {
  final int id;

  const CourseInitialScreen({super.key, required this.id});

  @override
  State<CourseInitialScreen> createState() => _CourseInitialScreenState();
}

class _CourseInitialScreenState extends State<CourseInitialScreen> {
  Course? courseDetail;
  int progress = 0;
  List<Chapter> listChapter = [];
  List<BadgeModel>? listBadge;
  late SharedPreferences pref;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getCourseDetail();
    getBadges();
    getChapters();
  }

  void getCourseDetail() async {
    final result = await CourseService.getCourse(widget.id);
    setState(() {
      courseDetail = result;
    });
  }

  void getBadges() async {
    final result = await BadgeService.getBadgeListCourseByCourseId(widget.id);
    setState(() {
      listBadge = result;
    });
  }

  void getChapters() async {
    final result = await CourseService.getChapterByCourse(widget.id);
    setState(() {
      listChapter = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return courseDetail == null
        ? Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/assets/pictures/background-pattern.png'
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Mulai Course untuk mengaktifkan halaman ini',
                  style: TextStyle(
                      fontFamily: 'DIN_Next_Rounded'
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    )
        : Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Course Overview"),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          onPressed: (){
            Navigator.pop(context);
          },
          icon: Icon(LineAwesomeIcons.angle_left_solid, color: Colors.white,)),
        titleTextStyle: TextStyle(
          fontFamily: 'DIN_Next_Rounded',
          fontSize: 24,
          color: Colors.white
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  'lib/assets/pictures/imk-picture.jpg',
                  width: double.infinity,
                  height: 320,
                  fit: BoxFit.cover,
                ),
                Container(
                  // margin: const EdgeInsets.only(top: -20),
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseDetail!.courseName,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DIN_Next_Rounded',
                            color: AppColors.primaryColor
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DIN_Next_Rounded',
                          color: AppColors.primaryColor
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(courseDetail!.description!, style: TextStyle(fontFamily: 'DIN_Next_Rounded'),),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.white,
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              listBadge!.isEmpty
                                  ? Text('Tidak ada badge pada Course ini.', style: TextStyle(fontFamily: 'DIN_Next_Rounded'),)
                                  : Row(
                                spacing: 32,
                                children: [
                                  Column(
                                    children: [
                                      Image.network(listBadge![0].image!, width: 50, height: 50),
                                      Text('Beginner', style: TextStyle(fontFamily: 'DIN_Next_Rounded'),)
                                    ],
                                  ),Column(
                                    children: [
                                      Image.network(listBadge![1].image!, width: 50, height: 50),
                                      Text('Intermediate', style: TextStyle(fontFamily: 'DIN_Next_Rounded'))
                                    ],
                                  ),Column(
                                    children: [
                                      Image.network(listBadge![2].image!, width: 50, height: 50),
                                      Text('Advance', style: TextStyle(fontFamily: 'DIN_Next_Rounded'))
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Daftar Chapter',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DIN_Next_Rounded',
                            color: AppColors.primaryColor
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listChapter.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey, width: 1.0),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: ListTile(
                              minTileHeight: 72,
                              leading: Text('${index + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold, color: AppColors.primaryColor),),
                              title: Text(listChapter[index].name, style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
                              trailing: listChapter[index].isCheckpoint == 1
                                  ? Icon(LineAwesomeIcons.medal_solid, color: Colors.teal)
                                  : listChapter[index].isCheckpoint == 2
                                    ? Icon(LineAwesomeIcons.medal_solid, color: Colors.blueAccent)
                                    : listChapter[index].isCheckpoint == 3
                                      ? Icon(LineAwesomeIcons.medal_solid, color: Colors.red)
                                      : null
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                )
              ],
            ),
          ),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(id: widget.id),
                          ),
                        );
                      },
                      child: Text(
                        'Kerjakan Course',
                        style: TextStyle(
                            fontFamily: 'DIN_Next_Rounded',
                            color: Colors.white
                        ),
                      )
                  ),
                ),
              )
          )
        ],
      ),
    );
  }
}
