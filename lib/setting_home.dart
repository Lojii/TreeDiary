import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:treediary/generated/l10n.dart';
// import 'package:treediary/provider/locale_model.dart';
import 'package:treediary/provider/setting_model.dart';
// import 'package:treediary/provider/theme_model.dart';
// import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

class SettingHome extends StatefulWidget {
  const SettingHome({Key? key}) : super(key: key);

  @override
  _SettingHomeState createState() => _SettingHomeState();
}

class _SettingHomeState extends State<SettingHome> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(S.of(context).appName),
          centerTitle: false
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const <Widget>[
              SizedBox(height: 20),
              DarkThemeWidget(),
              SizedBox(height: 20),
              // ColorThemeWidget(),
              // SizedBox(height: 20),
              LanguageWidget(),
              SizedBox(height: 20),
              // FontWidget()
            ],
          ),
        ),
      ),
    );
  }
}

class DarkThemeWidget extends StatelessWidget {
  const DarkThemeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
          Theme.of(context).brightness == Brightness.light
              ? Icons.brightness_5
              : Icons.brightness_2,
          color: Theme.of(context).primaryColor),
      title: Text(S.of(context).darkMode),
      trailing: CupertinoSwitch(
        activeColor: Theme.of(context).primaryColor,
        value: Theme.of(context).brightness == Brightness.dark,
        onChanged: (value) {
          switchDarkMode(context);
        },
      ),
    );
  }

  ///切换黑夜模式
  void switchDarkMode(BuildContext context) {
      Provider.of<SettingModel>(context, listen: false).switchTheme(Theme.of(context).brightness == Brightness.light ? 'dark' : 'light');
  }
}

class LanguageWidget extends StatelessWidget {
  const LanguageWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            S.of(context).settingLanguage,
            style: const TextStyle(),
          ),
          Text(
            // SettingModel.localeName(Provider.of<SettingModel>(context).language, context),
            "",
            style: Theme.of(context).textTheme.caption,
          )
        ],
      ),
      leading: Icon(
        Icons.public,
        color: Theme.of(context).primaryColor,
      ),
      children: <Widget>[
        ListView.builder(
            shrinkWrap: true,
            itemCount: languageTypes.length,
            itemBuilder: (context, index) {
              var model = Provider.of<SettingModel>(context);
              var value = languageTypes[index].keys.first;
              return RadioListTile(
                value: value,
                onChanged: (v) {
                  // model.switchLanguage(value);
                },
                groupValue: Provider.of<SettingModel>(context).language,
                // title: Text(SettingModel.localeName(value, context)),

              );
            })
      ],
    );
  }
}
