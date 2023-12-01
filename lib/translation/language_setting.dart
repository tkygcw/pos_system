import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:pos_system/utils/sharePreference.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AppLocalizations.dart';
import 'appLanguage.dart';


class LanguageDialog extends StatefulWidget {
  LanguageDialog();

  @override
  _LanguageDialogState createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<LanguageDialog> {
  var selectedLanguage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setSelectedLanguage();
  }

  setSelectedLanguage() async {
    var languageCode = await SharedPreferences.getInstance().then((prefs) {
      return prefs.getString('language_code');
    });
    if (languageCode == null) {
      selectedLanguage = 'English';

    }
    selectedLanguage = getLanguage(languageCode);

    setState(() {});

  }

  @override
  Widget build(BuildContext context) {
    var appLanguage = Provider.of<AppLanguage>(context);

    final _status = ["English", "中文", "Malay"];
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.translate('language'),
        style: GoogleFonts.cantoraOne(
          textStyle: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      content: SingleChildScrollView(
        child: Container(
          width: 400,
          child: ListBody(
            children: <Widget>[
              RadioGroup<String>.builder(
                groupValue: selectedLanguage,
                onChanged: (value) => setState(() {
                  print(value);
                  this.selectedLanguage = value ?? 'English';
                }),
                items: _status,
                itemBuilder: (item) => RadioButtonBuilder(
                  item,
                ),
                fillColor: Colors.red,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('${AppLocalizations.of(context)!.translate('cancel')}',
            style: TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(
            '${AppLocalizations.of(context)!.translate('confirm')}',
          ),
          onPressed: () {
            appLanguage.changeLanguage(Locale(getLanguageCode(selectedLanguage)));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  String getLanguage(selectedLanguage) {
    switch (selectedLanguage) {
      case 'zh':
        return '中文';
      case 'ms':
        return 'Malay';
      default:
        return 'English';
    }
  }

  String getLanguageCode(selectedLanguage) {
    switch (selectedLanguage) {
      case '中文':
        return 'zh';
      case 'Malay':
        return 'ms';
      default:
        return 'en';
    }
  }
}
