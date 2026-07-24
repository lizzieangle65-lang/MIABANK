import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MIABankApp());
}

class MIABankApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIABank',
      debugShowCheckedModeBanner: false,
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return DashboardScreen();
        return LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLogin = true;

  Future<void> auth() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailCtrl.text, password: passCtrl.text);
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailCtrl.text, password: passCtrl.text);
        String accNum = (1000000 + Random().nextInt(9000000)).toString();
        await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
          "email": emailCtrl.text, "name": "JAMES COMTES", "balance": 120000,
          "accountNumber": accNum, "routingNumber": "021000021"
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account Created! \$120,000 deposited")));
      }
    } catch(e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFF4500)])),
        child: Center(child: Container(padding: EdgeInsets.all(30), margin: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("🏦 MIABank", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF4500))),
            SizedBox(height: 20),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder())),
            SizedBox(height: 20),
            ElevatedButton(onPressed: auth, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF4500), minimumSize: Size(double.infinity, 50)), child: Text(isLogin ? "Log In" : "Sign Up - Get \$120,000", style: TextStyle(color: Colors.white))),
            TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "Create Account" : "Back to Login", style: TextStyle(color: Color(0xFFFF4500))))
          ]),
        )),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData;
  @override
  void initState() { super.initState(); loadData(); }
  Future<void> loadData() async {
    var doc = await FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).get();
    setState(() => userData = doc.data());
  }
  @override
  Widget build(BuildContext context) {
    if (userData == null) return Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(appBar: AppBar(title: Text("🏦 MIABank"), backgroundColor: Color(0xFFFF4500)),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFF4500)])),
        child: Center(child: Container(padding: EdgeInsets.all(30), margin: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("WELCOME ${userData!['name']}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF4500))),
            SizedBox(height: 20),
            Container(padding: EdgeInsets.all(15), decoration: BoxDecoration(color: Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text("Account Number: ${userData!['accountNumber']}"),
                Text("Routing Number: ${userData!['routingNumber']}"),
                Text("Balance: \$${userData!['balance']}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF4500))),
              ]),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => FirebaseAuth.instance.signOut(), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey), child: Text("Log Out", style: TextStyle(color: Colors.white)))
          ]),
        )),
      ),
    );
  }
}
