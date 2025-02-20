import 'package:app/service/userService.dart';
import 'package:flutter/material.dart';

import '../model/user.dart';

Color purple = Color(0xFF441F7F);
Color backgroundNavHex = Color(0xFFF3EDF7);
const url = 'https://www.globalcareercounsellor.com/blog/wp-content/uploads/2018/05/Online-Career-Counselling-course.jpg';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _FriendsScreen();
}

class _FriendsScreen extends State<FriendsScreen> {

  List<User> user = [];

  List<User> sortUserbyPoint(List<User> list) {
    list.sort((a, b) => b.points!.compareTo(a.points!));
    return list;
  }

  List<User> studentRole(List<User> list) {
    return list.where((user) => user.role == 'STUDENT').toList();
  }

  void getAllUser() async {
    final result = await UserService.getAllUser();
    setState(() {
      user = sortUserbyPoint(studentRole(result));
    });
  }

  @override
  void initState() {
    super.initState();
    getAllUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 450,
        backgroundColor: purple,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Papan Peringkat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 30),),
              _buildLeaderBoard(user),
            ],
          ),
        ),
      ),
      body: _listFriends(), 
    );
  }

  Widget _listFriends() {
    user = sortUserbyPoint(user);
    return ListView.builder(
      itemCount: user.length,
      itemBuilder: (context, count) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 1.0),
          child: _listFriendsItem(user[count], count),
        );
      },
    );
  }

  Widget _listFriendsItem(User user, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ (switch (index) {
              0 => Colors.amber.shade300,
              1 => Colors.blueGrey.shade400,
              2 => Colors.orange.shade400,
              _ => Colors.grey.shade300
            }), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: index <= 2 ? Image.asset(
              switch (index) {
                0 => 'lib/assets/1st.png',
                1 => 'lib/assets/2nd.png',
                2 => 'lib/assets/3rd.png',
                _ => ''
              }
          ) : Text('#${index + 1}', style: TextStyle(fontSize: 25),),
          title: Text(
            user.username,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          subtitle: Text(
            user.studentId!,
            style: TextStyle(fontSize: 13, color: Colors.black),
          ),
          trailing: Text(
            '${user.points} Point',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderBoard(List<User> list) {
    return Container(
      margin: EdgeInsets.all(13),
      height: 300,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(url),
                child: Icon(Icons.person, size: 20,),
              ),
              Text(list.isNotEmpty && list.length >= 2? list[1].username : '', style: TextStyle(color: Colors.white),),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                    padding: EdgeInsets.all(10),
                  child: Text('${list.isNotEmpty && list.length >= 2 ? list[1].points : 0} pts', style: TextStyle(fontSize: 12),),
                ),
              ),
              SizedBox(
                height: 10,
                width: 10,
              ),
              Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                    color: Colors.blueGrey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('#2', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),),
              )
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(url),
                child: Icon(Icons.person, size: 20,),
              ),
              Text(list.isNotEmpty ? list[0].username : '', style: TextStyle(color: Colors.white),),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('${list.isNotEmpty? list[0].points : 0} pts', style: TextStyle(fontSize: 12),),
                ),
              ),
              SizedBox(
                height: 10,
                width: 10,
              ),
              Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.amber.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('#1', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),),
              )
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(url),
                child: Icon(Icons.person, size: 20,),
              ),
              Text(list.isNotEmpty && list.length >= 3 ? list[2].username : '', style: TextStyle(color: Colors.white),),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('${list.isNotEmpty && list.length >= 3 ? list[2].points : 0} pts', style: TextStyle(fontSize: 12),),
                ),
              ),
              SizedBox(
                height: 10,
                width: 10,
              ),
              Container(
                width: 100,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('#3', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),),
              )
            ],
          ),
        ],
      ),
    );
  }
}
