import 'dart:io';

import 'package:app/global_var.dart';
import 'package:app/service/user_service.dart';
import 'package:app/utils/colors.dart';
import 'package:app/view/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../model/login.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void login() async {
    setState(() => isLoading = true);

    try {
      var client = http.Client();
      final response = await UserService.login(emailController.text, passwordController.text).timeout(Duration(seconds: 15));

      if (response['code'] == 200) {
        // Simpan token ke SharedPreferences
        Login credential = response['value'];
        SharedPreferences prefs = await SharedPreferences.getInstance();

        if(credential.role == 'STUDENT') {
          await prefs.setInt('userId', credential.id);
          await prefs.setString('name', credential.name);
          await prefs.setString('role', credential.role);
          await prefs.setString('token', credential.token);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Mainscreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Mohon Login sebagai mahasiswa")),
          );
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${response['message']}")),
        );
      }
      client.close();
    } on TimeoutException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Waktu koneksi habis. Coba lagi nanti.")),
      );
      print("Waktu koneksi habis. Coba lagi nanti.");
    }
    on SocketException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tidak dapat terhubung ke server. Periksa koneksi internet Anda.")),
      );
      print("Tidak dapat terhubung ke server. Periksa koneksi internet Anda.");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: ${e.toString()}")),
      );
      print("Terjadi kesalahan: ${e.toString()}");
    }

    setState(() => isLoading = false);
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'archicosemb@gmail.com',
      queryParameters: {
        'subject': 'Levelearn Mobile Help Request - Authentication',
        'body': '''
            Saya menulis email ini untuk meminta bantuan terkait [jelaskan masalah atau pertanyaan Anda secara singkat].

            Berikut adalah detail masalah yang saya alami:
            
            * [Deskripsi masalah dengan jelas dan detail]
            * [Langkah-langkah yang sudah Anda coba]
            * [Informasi perangkat atau akun jika relevan]
            
            Saya berharap dapat segera mendapatkan solusi atau bantuan dari tim Anda.
            
            Terima kasih atas perhatian dan bantuannya.
            
            Hormat saya,
            
            [Nama Anda]
            [Kontak (opsional)]
        ''',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Tidak dapat meluncurkan email';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fontSize = width * 0.035;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 16,
            ),
            !isLandscape ? SizedBox(
              height: 400,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: -40,
                    height: 400,
                    width: width,
                    child: FadeInUp(
                        duration: Duration(seconds: 1),
                        child: Container(
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage(
                                      'lib/assets/images/background.png'),
                                  fit: BoxFit.fill)),
                        )),
                  ),
                  Positioned(
                    height: 400,
                    width: width + 20,
                    child: FadeInUp(
                        duration: Duration(milliseconds: 1000),
                        child: Container(
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage(
                                      'lib/assets/vectors/welcome_primary.png'))),
                        )),
                  )
                ],
              ),
            ) : SizedBox(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(
                      duration: Duration(milliseconds: 1500),
                      child: Text(
                        "Login",
                        style: TextStyle(
                            color: GlobalVar.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize * 1.5,
                            fontFamily: 'DIN_Next_Rounded'),
                      )),
                  SizedBox(
                    height: 30,
                  ),
                  FadeInUp(
                      duration: Duration(milliseconds: 1700),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            border: Border.all(
                                color: const Color.fromRGBO(68, 31, 127, .3)),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(68, 31, 127, .3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              )
                            ]),
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Color.fromRGBO(
                                              68, 31, 127, .3)))),
                              child: TextField(
                                style: TextStyle(
                                    fontFamily: 'DIN_Next_Rounded'
                                ),
                                controller: emailController,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Username",
                                    hintStyle:
                                    TextStyle(
                                        color: Colors.grey.shade700,
                                        fontFamily: 'DIN_Next_Rounded',
                                        fontSize: fontSize
                                    )),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: TextField(
                                style:
                                TextStyle(fontFamily: 'DIN_Next_Rounded'),
                                controller: passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Password",
                                    hintStyle:
                                    TextStyle(
                                        color: Colors.grey.shade700,
                                        fontFamily: 'DIN_Next_Rounded',
                                        fontSize: fontSize
                                    )),
                              ),
                            )
                          ],
                        ),
                      )),
                  SizedBox(
                    height: 20,
                  ),
                  FadeInUp(
                      duration: Duration(milliseconds: 1700),
                      child: Center(
                          child: TextButton(
                              onPressed: _launchEmail,
                              child: Text(
                                "Butuh Bantuan?",
                                style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontFamily: 'DIN_Next_Rounded',
                                    fontSize: fontSize),
                              )))),
                  SizedBox(
                    height: 30,
                  ),
                  FadeInUp(
                      duration: Duration(milliseconds: 1900),
                      child: MaterialButton(
                        onPressed: login,
                        color: GlobalVar.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        height: 50,
                        child: Center(
                          child: isLoading ?
                          CircularProgressIndicator() :
                          Text(
                            "Login",
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'DIN_Next_Rounded',
                                fontSize: fontSize
                            ),
                          ),
                        ),
                      )),
                  SizedBox(
                    height: 30,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
