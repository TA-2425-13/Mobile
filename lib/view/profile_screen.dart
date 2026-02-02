import 'package:app/global_var.dart';
import 'package:app/model/chapter.dart';
import 'package:app/model/user_badge.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/chapter_service.dart';
import 'package:app/service/user_service.dart';
import 'package:app/view/about_app.dart';
import 'package:app/view/quick_access_screen.dart';
import 'package:app/view/trade_screen.dart';
import 'package:app/view/update_profile_screeen.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/badge.dart';
import '../model/course.dart';
import '../model/user.dart';
import '../service/course_service.dart';
import '../utils/colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  late SharedPreferences prefs;
  Student? user;
  bool isLoading = true;
  List<Student> list = [];
  int rank = 0;
  List<UserBadge>? userBadges = [];
  Course? course;
  Chapter? chapter;
  List<Course>? allCourses;

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  Future<void> getUserData() async {
    prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('userId');
    if (idUser != null) {
      Student fetchedUser = await UserService.getUserById(idUser);
      setState(() {
        user = fetchedUser;
        isLoading = false;
      });
      getUserBadges(idUser);
      getAllUser();
      getEnrolledCourse(idUser);
    }
  }

  List<Student> sortUserbyPoint(List<Student> list) {
    print(list);
    list.sort((a, b) => b.points!.compareTo(a.points!));
    return list;
  }

  Future<void> getAllUser() async {
    final result = await UserService.getAllUser();
    setState(() {
      list = sortUserbyPoint(studentRole(result));
    });
    for (int i = 0; i < list.length; i++) {
      if(list[i].id == user?.id){
        setState(() {
          rank = i + 1;
        });
        break;
      }
    }
  }

  Future<void> getEnrolledCourse(int userId) async {
    final result = await CourseService.getEnrolledCourse(userId);
    setState(() {
      allCourses = result;
    });
  }

  Future<void> getUserBadges(int userId) async {
    final result = await BadgeService.getUserBadgeListByUserId(userId);
    setState(() {
      userBadges = result;
    });
  }

  List<Student> studentRole(List<Student> list) {
    return list.where((user) => user.role == 'STUDENT').toList();
  }

  Future<Course> getCourseById(int id) {
    return CourseService.getCourse(id);
  }

  Future<Chapter> getChapterById(int id) {
    return ChapterService.getChapterById(id);
  }

  void logout() {
    prefs.clear();
  }

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return isLoading ? Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/assets/pictures/background-pattern.png'
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10), // Space between progress bar and text
                  Text("Mohon Tunggu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
        ),
      )
    ) : Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalVar.primaryColor,
        // leading: IconButton(
        //     onPressed: (){
        //       Navigator.pushReplacement(
        //         context,
        //         MaterialPageRoute(
        //             builder: (context) => Mainscreen()),
        //       );
        //     },
        //     icon: Icon(LineAwesomeIcons.angle_left_solid, color: Colors.white,)
        // ),
        automaticallyImplyLeading: false,
        title: Text(
            "Profile",
            style: TextStyle(
                fontFamily: 'DIN_Next_Rounded',
                color: Colors.white
            )),
        // actions: [IconButton(onPressed: (){}, icon: Icon(isDark ? LineAwesomeIcons.sun : LineAwesomeIcons.moon))],
      ),
      body:  Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(
                        'lib/assets/pictures/background-pattern.png'),
                    fit: BoxFit.cover
                )
            ),
          ),
          isLoading 
          ? Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'lib/assets/pictures/background-pattern.png'
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10), // Space between progress bar and text
                        Text("Mohon Tunggu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
              ),
            )
          ) 
          : Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(
                            'lib/assets/pictures/background-pattern.png'),
                        fit: BoxFit.cover
                    )
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        color: GlobalVar.primaryColor,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: user?.image != "" && user?.image != null ? Image.network(user!.image!, fit: BoxFit.cover,)
                                        : Icon(Icons.person, size: 100, color: Colors.white,),
                                  ),
                                ),
                              Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => UpdateProfile(user: user!,)),
                                      );
                                    },
                                    child: Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: GlobalVar.secondaryColor),
                                      child: const Icon(
                                        LineAwesomeIcons.pencil_alt_solid,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  )
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(user!.name,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontFamily: 'DIN_Next_Rounded',
                                  color: Colors.white
                              )),
                          Text(user!.studentId!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'DIN_Next_Rounded',
                                  color: GlobalVar.accentColor
                              )),
                          const SizedBox(height: 16),
                          // const Divider(),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 32),
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 24,
                              children: [
                                _buildInfoColumn(LineAwesomeIcons.medal_solid,
                                    'Lencana', '${userBadges?.length}', GlobalVar.secondaryColor),
                                _buildInfoColumn(LineAwesomeIcons.user_check_solid,
                                    'Course', '${allCourses != null ? allCourses?.length : '0'}', GlobalVar.secondaryColor),
                                _buildInfoColumn(LineAwesomeIcons.trophy_solid,
                                    'Peringkat', '$rank / ${list.length}', GlobalVar.secondaryColor),
                                _buildInfoColumn(LineAwesomeIcons.gem_solid,
                                    'Poin', '${user?.points != null ? user?.points : 0}', GlobalVar.secondaryColor)
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                      SizedBox(
                      height: 4,
                    ),
                      Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            'Lencana Saya',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: GlobalVar.primaryColor,
                              fontFamily: 'DIN_Next_Rounded',
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            height: 64,
                            child: userBadges!.isNotEmpty ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: userBadges?.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    _showBadgeDetails(context, userBadges![index].badge);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: userBadges?[index].badge.image != null && userBadges?[index].badge.image != '' ?
                                      Image.network(userBadges![index].badge.image!, fit: BoxFit.cover) : Image.asset('lib/assets/pictures/icon.png', fit: BoxFit.cover)
                                    ),
                                  ),
                                );
                              },
                            ) : Center(
                              child: Text('Kamu belum mempunyai badge', style: TextStyle(fontFamily: 'DIN_Next_Rounded'),),
                            )
                          ),
                          SizedBox(
                            height: 8,
                          ),
                        ],
                      ),
                    ),
                      ProfileMenuWidget(
                        title: "Trades",
                        icon: LineAwesomeIcons.coins_solid,
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TradeScreen(user: user!,)),
                          );
                        },
                      ),
                      ProfileMenuWidget(
                        title: "Update Profile",
                        icon: LineAwesomeIcons.person_booth_solid,
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UpdateProfile(user: user!,)),
                          );
                        },
                      ),
                      ProfileMenuWidget(
                        title: "Quick Access",
                        icon: LineAwesomeIcons.accessible,
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => QuickAccessScreen()),
                          );
                        },
                      ),
                      ProfileMenuWidget(
                        title: "App Rating",
                        icon: LineAwesomeIcons.star,
                        onPress: () {},
                      ),
                      ProfileMenuWidget(
                        title: "About App",
                        icon: LineAwesomeIcons.info_circle_solid,
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AboutAppScreen()),
                          );
                        },
                      ),
                      SizedBox(
                          height: 16
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () {
                                logout();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GlobalVar.primaryColor,
                                side: BorderSide.none,
                                shape: const StadiumBorder(),
                              ),
                              child: Text("Log Out", style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontFamily: 'DIN_Next_Rounded',
                                  color: Colors.white
                              ),)
                          ),
                        ),
                      ),
                      SizedBox(
                          height: 16
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ]
      )
    );
  }

  void _showBadgeDetails(BuildContext context, BadgeModel badge) async {
    Course resultCourse = await getCourseById(badge.courseId);
    Chapter resultChapter = await getChapterById(badge.chapterId);
    setState(() {
      course = resultCourse;
      chapter = resultChapter;
    });

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: badge.image != null  ?
                  Image.network(badge.image!, fit: BoxFit.cover) : Image.asset('lib/assets/pictures/icon.png', fit: BoxFit.cover),
                ),
                SizedBox(height: 16),
                Text(
                  badge.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DIN_Next_Rounded',
                    color: AppColors.primaryColor,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '(${badge.type})',
                  style: TextStyle(fontFamily: 'DIN_Next_Rounded'),
                ),
                SizedBox(height: 8),
                Text(
                  'Badge ini diperoleh karena telah berhasil menyelesaikan ${course!.courseName} sampai pada chapter ${chapter!.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'DIN_Next_Rounded'),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Tutup',
                    style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildInfoColumn(
      IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28,),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                // fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily:
                'DIN_Next_Rounded',
              ),
            ),
            Text(value,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: GlobalVar.primaryColor,
                    fontFamily: 'DIN_Next_Rounded'))
          ],
        )
      ],
    );
  }
}

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.onPress,
    this.endIcon = true,
    this.textColor
  });

  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
          onTap: onPress,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: AppColors.primaryColor,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(title, style: Theme
              .of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
            color: textColor,
            fontFamily: 'DIN_Next_Rounded',
          )),
          trailing: endIcon ? Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.grey.withOpacity(0.1),
              ),
              child: const Icon(LineAwesomeIcons.angle_right_solid, size: 18.0,
                  color: Colors.grey)) : null
      ),
    );
  }
}