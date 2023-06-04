import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';

class GeneralSettingsRoute extends StatefulWidget {
  const GeneralSettingsRoute({Key? key}) : super(key: key);
  @override
  _GeneralSettingsRouteState createState() => _GeneralSettingsRouteState();
}

class _GeneralSettingsRouteState extends State<GeneralSettingsRoute> {
  /// Needed as init value and also to check whether setting
  /// value has been increased or decreased.
  int minFileDuration = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitleMarquee(text: l10n.general),
        leading: const NFBackButton(),
      ),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: Settings.confirmExitingWithBackButton,
            builder: (context, value, child) => SwitchListTile(
              title: Text(l10n.confirmExitingWithBackButtonSetting),
              value: value,
              onChanged: Settings.confirmExitingWithBackButton.set,
            ),
          ),
          if (DeviceInfoControl.instance.useScopedStorageForFileModifications)
            ValueListenableBuilder<bool>(
              valueListenable: Settings.useMediaStoreForFavoriteSongs,
              builder: (context, value, child) => SwitchListTile(
                title: Text(l10n.useMediaStoreForFavoriteSongsSetting),
                value: value,
                onChanged: Settings.useMediaStoreForFavoriteSongs.set,
              ),
            ),
          // _MinFileDurationSlider(
          //   initValue: minFileDuration,
          // ),
        ],
      ),
    );
  }
}

// class _MinFileDurationSlider extends StatefulWidget {
//   final Function onChangeEnd;
//   final int initValue;
//   _MinFileDurationSlider(
//       {Key key, @required this.initValue, @required this.onChangeEnd})
//       : assert(initValue != null),
//         assert(onChangeEnd != null),
//         super(key: key);

//   _MinFileDurationSliderState createState() => _MinFileDurationSliderState();
// }

// class _MinFileDurationSliderState extends State<_MinFileDurationSlider> {
//   double _value;

//   @override
//   void initState() {
//     super.initState();
//     _value = widget.initValue.toDouble();
//   }

//   String _calcLabel() {
//     String seconds = (_value % 60).round().toString();
//     if (seconds.length < 2) seconds = '0$seconds';
//     return '${_value ~/ 60}:$seconds';
//   }

//   void _handleChange(double newValue) {
//     setState(() {
//       _value = newValue;
//     });
//   }

//   void _handleChangeEnd(double newValue) {
//     widget.onChangeEnd(_value.toInt());
//     setState(() {
//       _value = newValue;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = getl10n(context);
//     return SettingItem(
//       title: l10n.settingMinFileDuration,
//       description: l10n.settingHideFilesShorterThan + _calcLabel(),
//       content: LabelledSlider(
//         inactiveColor: Constants.Theme.sliderInactive.auto,
//         min: 0,
//         max: 60 * 5.0,
//         divisions: 60,
//         value: _value,
//         onChanged: _handleChange,
//         onChangeEnd: _handleChangeEnd,
//         label: _calcLabel(),
//         minLabel: '0 ' + l10n.secondsShorthand,
//         maxLabel: '5 ' + l10n.minutesShorthand,
//       ),
//     );
//   }
// }
