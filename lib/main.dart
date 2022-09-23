import 'package:flutter/material.dart';
import 'package:flutter_keychain/flutter_keychain.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const Color primaryColor = Color(0xFF13B5A2);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  biometric() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    if(canAuthenticate) {
      final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to login',
          options: const AuthenticationOptions(stickyAuth: true, useErrorDialogs: true)
      );
      if(didAuthenticate) {
        // get username and password from secure storage and pass them to login()
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logged in successfully!"),));
      }
    }
  }

  final TextEditingController _usernameController =
  TextEditingController(text: "");
  final TextEditingController _passwordController =
  TextEditingController(text: "");

  bool passwordHidden = true;
  bool _savePassword = true;

  // Read values
  Future<void> _readFromStorage() async {
    _usernameController.text = await FlutterKeychain.get(key: "KEY_USERNAME") ?? '';
    _passwordController.text = await FlutterKeychain.get(key: "KEY_PASSWORD") ?? '';
  }

  _onFormSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_savePassword) {
        // Write values
        await FlutterKeychain.put(key: "KEY_USERNAME", value: _usernameController.text);
        await FlutterKeychain.put(key: "KEY_PASSWORD", value: _passwordController.text);
      } else {
        await FlutterKeychain.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logged in successfully!"),));
    }
  }

  @override
  void initState() {
    super.initState();
    biometric();
    _readFromStorage();
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          padding: EdgeInsets.all(size.width - size.width * .85),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: size.height * .15,
              ),
              AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Username",
                          labelStyle: const TextStyle(color: primaryColor),
                          focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(0), borderSide: const BorderSide(color: primaryColor, width: 2),),
                        ),
                        controller: _usernameController,
                        autofillHints: const [AutofillHints.username],
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Required field';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.none,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(
                        height: size.height * .02,
                      ),
                      TextFormField(
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          return value!.isEmpty ? "Required field" : null;
                        },
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Color(0xFF95989A)),
                          focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(0), borderSide: const BorderSide(color: primaryColor, width: 2),),
                          suffixIcon: InkWell(
                            onTap: () {
                              setState(() {
                                passwordHidden = !passwordHidden;
                              });
                            },
                            child: Icon(
                              passwordHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xff747881),
                              size: 23,
                            ),
                          ),
                        ),
                        controller: _passwordController,
                        obscureText: passwordHidden,
                        enableSuggestions: false,
                        toolbarOptions: const ToolbarOptions(
                          copy: false,
                          paste: false,
                          cut: false,
                          selectAll: false,
                          //by default all are disabled 'false'
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CheckboxListTile(
                value: _savePassword,
                onChanged: (bool? newValue) {
                  setState(() {
                    _savePassword = newValue!;
                  });
                },
                title: const Text("Remember me"),
                activeColor: primaryColor,
              ),
              SizedBox(
                height: size.height * .05,
              ),
              SizedBox(
                width: size.width,
                child: ElevatedButton(
                  onPressed: _onFormSubmit,
                  child: const Text("Sign In"),
                  style: ElevatedButton.styleFrom(
                      primary: primaryColor,
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
