import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/currency_service.dart';



/// Display preferences only. Changing currency does not exchange or convert

/// financial amounts, and changing timezone does not change the device clock.

class CurrencyRegionScreen extends StatefulWidget {

  const CurrencyRegionScreen({super.key});



  @override

  State<CurrencyRegionScreen> createState() => _CurrencyRegionScreenState();

}



class _CurrencyOption {

  const _CurrencyOption(this.code, this.flag, this.name, this.symbol);

  final String code;

  final String flag;

  final String name;

  final String symbol;

}



class _RegionOption {

  const _RegionOption(this.name, this.flag, this.area);

  final String name;

  final String flag;

  final String area;

}



class _ZoneOption {

  const _ZoneOption(this.id, this.label, this.detail);

  final String id;

  final String label;

  final String detail;

}



const _currencies = <_CurrencyOption>[

  _CurrencyOption('INR', '🇮🇳', 'Indian Rupee', '₹'),

  _CurrencyOption('USD', '🇺🇸', 'US Dollar', r'$'),

  _CurrencyOption('EUR', '🇪🇺', 'Euro', '€'),

  _CurrencyOption('GBP', '🇬🇧', 'British Pound', '£'),

];



const _regions = <_RegionOption>[

  _RegionOption('India', '🇮🇳', 'Asia'),

  _RegionOption('United States', '🇺🇸', 'North America'),

  _RegionOption('United Kingdom', '🇬🇧', 'Europe'),

  _RegionOption('European Union', '🇪🇺', 'Europe'),

];



const _zones = <_ZoneOption>[

  _ZoneOption('Asia/Kolkata', 'India Standard Time', 'UTC+05:30 · Kolkata, Mumbai, New Delhi'),

  _ZoneOption('Etc/UTC', 'Coordinated Universal Time', 'UTC+00:00'),

  _ZoneOption('America/New_York', 'US Eastern Time', 'New York · daylight saving may apply'),

  _ZoneOption('America/Los_Angeles', 'US Pacific Time', 'Los Angeles · daylight saving may apply'),

  _ZoneOption('Europe/London', 'United Kingdom Time', 'London · daylight saving may apply'),

  _ZoneOption('Europe/Berlin', 'Central European Time', 'Berlin · daylight saving may apply'),

];



class _CurrencyRegionScreenState extends State<CurrencyRegionScreen> {

  static const _currencyKey = 'dhanviq_currency';

  static const _regionKey = 'dhanviq_region';

  static const _formatKey = 'dhanviq_number_format';

  static const _dateKey = 'dhanviq_date_format';

  static const _timezoneKey = 'dhanviq_timezone';



  String _currency = 'INR';

  String _region = 'India';

  String _numberFormat = 'Indian';

  String _dateFormat = 'dd MMM yyyy';

  String _timezone = 'Asia/Kolkata';

  bool _ready = false;

  bool _saving = false;



  bool _dark(BuildContext context) =>

      Theme.of(context).brightness == Brightness.dark;

  Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

  Color _background(BuildContext context) =>

      _dark(context) ? const Color(0xFF10141E) : const Color(0xFFF7F8FF);

  Color _card(BuildContext context) =>

      _dark(context) ? const Color(0xFF1B2030) : Colors.white;

  Color _ink(BuildContext context) =>

      _dark(context) ? const Color(0xFFF5F6FF) : const Color(0xFF151C34);

  Color _muted(BuildContext context) =>

      _dark(context) ? const Color(0xFFAAB2C7) : const Color(0xFF7B8398);

  Color _border(BuildContext context) =>

      _dark(context) ? const Color(0xFF32394B) : const Color(0xFFE8EAF4);

  Color _tint(BuildContext context) =>

      _accent(context).withValues(alpha: _dark(context) ? .15 : .075);

  Color _onAccent(BuildContext context) =>

      _accent(context).computeLuminance() > .54 ? Colors.black : Colors.white;



  _CurrencyOption get _selectedCurrency => _currencies.firstWhere(

        (c) => c.code == _currency,

        orElse: () => _currencies.first,

      );

  _RegionOption get _selectedRegion => _regions.firstWhere(

        (r) => r.name == _region,

        orElse: () => _regions.first,

      );

  _ZoneOption get _selectedZone => _zones.firstWhere(

        (z) => z.id == _timezone,

        orElse: () => _zones.first,

      );



  @override

  void initState() {

    super.initState();

    _load();

  }



  Future<void> _load() async {

    try {

      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      final savedCurrency = prefs.getString(_currencyKey) ?? 'INR';

      final savedRegion = prefs.getString(_regionKey) ?? 'India';

      final savedTimezone = prefs.getString(_timezoneKey) ?? 'Asia/Kolkata';

      setState(() {

        _currency = _currencies.any((v) => v.code == savedCurrency)

            ? savedCurrency

            : 'INR';

        _region = _regions.any((v) => v.name == savedRegion)

            ? savedRegion

            : 'India';

        _timezone = _zones.any((v) => v.id == savedTimezone)

            ? savedTimezone

            : 'Asia/Kolkata';

        _numberFormat = prefs.getString(_formatKey) == 'International'

            ? 'International'

            : 'Indian';

        final date = prefs.getString(_dateKey) ?? 'dd MMM yyyy';

        _dateFormat = const ['dd MMM yyyy', 'dd/MM/yyyy', 'MM/dd/yyyy']

                .contains(date)

            ? date

            : 'dd MMM yyyy';

        _ready = true;

      });

    } catch (_) {

      if (mounted) {

        setState(() => _ready = true);

        _toast('Unable to load saved preferences.');

      }

    }

  }



  void _toast(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context)

      ..hideCurrentSnackBar()

      ..showSnackBar(SnackBar(content: Text(message)));

  }



  Future<void> _saveCurrency(String code) async {

    if (_saving || code == _currency) return;

    final previous = _currency;

    setState(() {

      _currency = code;

      _saving = true;

    });

    try {
      await CurrencyService.instance.setCurrency(code);

    } catch (_) {

      if (mounted) {

        setState(() => _currency = previous);

        _toast('Currency could not be saved.');

      }

    } finally {

      if (mounted) setState(() => _saving = false);

    }

  }



  Future<void> _pickRegion() async {

    final selected = await _chooseSheet<_RegionOption>(

      'Choose Region / Country',

      [

        for (final region in _regions)

          _choiceTile(

            icon: Text(region.flag, style: const TextStyle(fontSize: 22)),

            title: region.name,

            subtitle: region.area,

            selected: region.name == _region,

            onTap: (sheetContext) => Navigator.pop(sheetContext, region),

          ),

      ],

    );

    if (selected == null || selected.name == _region || !mounted) return;

    final previous = _region;

    setState(() => _region = selected.name);

    try {
      await CurrencyService.instance.setRegion(selected.name);

    } catch (_) {

      if (mounted) {

        setState(() => _region = previous);

        _toast('Region could not be saved.');

      }

    }

  }



  Future<void> _pickTimezone() async {

    final selected = await _chooseSheet<_ZoneOption>(

      'Choose Timezone',

      [

        for (final zone in _zones)

          _choiceTile(

            icon: Icon(Icons.schedule_rounded, color: _accent(context), size: 22),

            title: zone.label,

            subtitle: zone.detail,

            selected: zone.id == _timezone,

            onTap: (sheetContext) => Navigator.pop(sheetContext, zone),

          ),

      ],

    );

    if (selected == null || selected.id == _timezone || !mounted) return;

    final previous = _timezone;

    setState(() => _timezone = selected.id);

    try {
      await CurrencyService.instance.setTimezone(selected.id);

    } catch (_) {

      if (mounted) {

        setState(() => _timezone = previous);

        _toast('Timezone could not be saved.');

      }

    }

  }



  Future<T?> _chooseSheet<T>(String title, List<Widget> items) {

    return showModalBottomSheet<T>(

      context: context,

      isScrollControlled: true,

      backgroundColor: _card(context),

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      builder: (sheetContext) => SafeArea(

        top: false,

        child: ConstrainedBox(

          constraints: BoxConstraints(

            maxHeight: MediaQuery.sizeOf(sheetContext).height * .76,

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              const SizedBox(height: 12),

              Container(

                width: 38,

                height: 4,

                decoration: BoxDecoration(

                  color: _border(sheetContext),

                  borderRadius: BorderRadius.circular(5),

                ),

              ),

              Padding(

                padding: const EdgeInsets.fromLTRB(20, 17, 12, 7),

                child: Row(

                  children: [

                    Expanded(

                      child: Text(title,

                          style: TextStyle(

                            color: _ink(sheetContext),

                            fontSize: 18,

                            fontWeight: FontWeight.w800,

                          )),

                    ),

                    IconButton(

                      onPressed: () => Navigator.pop(sheetContext),

                      icon: const Icon(Icons.close_rounded),

                    ),

                  ],

                ),

              ),

              Flexible(

                child: ListView(

                  shrinkWrap: true,

                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),

                  children: items,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _choiceTile({

    required Widget icon,

    required String title,

    required String subtitle,

    required bool selected,

    required void Function(BuildContext) onTap,

  }) {

    return Builder(

      builder: (tileContext) => ListTile(

        onTap: () => onTap(tileContext),

        leading: SizedBox(width: 30, child: Center(child: icon)),

        title: Text(title,

            style: TextStyle(

              color: _ink(tileContext),

              fontSize: 13,

              fontWeight: FontWeight.w700,

            )),

        subtitle: Text(subtitle,

            style: TextStyle(color: _muted(tileContext), fontSize: 11)),

        trailing: Icon(

          selected ? Icons.check_circle_rounded : Icons.circle_outlined,

          color: selected ? _accent(tileContext) : _muted(tileContext),

        ),

      ),

    );

  }



  Future<void> _pickFormats() async {

    String number = _numberFormat;

    String date = _dateFormat;

    final result = await showModalBottomSheet<(String, String)>(

      context: context,

      isScrollControlled: true,

      backgroundColor: _card(context),

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      builder: (sheetContext) => StatefulBuilder(

        builder: (sheetContext, update) => SafeArea(

          top: false,

          child: Padding(

            padding: EdgeInsets.fromLTRB(

              20, 14, 20, 20 + MediaQuery.viewInsetsOf(sheetContext).bottom,

            ),

            child: SingleChildScrollView(

              child: Column(

                mainAxisSize: MainAxisSize.min,

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Center(

                    child: Container(

                      width: 38,

                      height: 4,

                      decoration: BoxDecoration(

                        color: _border(sheetContext),

                        borderRadius: BorderRadius.circular(5),

                      ),

                    ),

                  ),

                  const SizedBox(height: 18),

                  Text('Number & Date Format',

                      style: TextStyle(

                        color: _ink(sheetContext),

                        fontSize: 18,

                        fontWeight: FontWeight.w800,

                      )),

                  const SizedBox(height: 15),

                  Text('NUMBER GROUPING',

                      style: TextStyle(

                        color: _muted(sheetContext),

                        fontSize: 11,

                        fontWeight: FontWeight.w800,

                      )),

                  RadioGroup<String>(

                    groupValue: number,

                    onChanged: (value) {

                      if (value != null) update(() => number = value);

                    },

                    child: Column(

                      children: const [

                        RadioListTile<String>(

                          value: 'Indian',

                          title: Text('Indian · 1,23,456.78'),

                          contentPadding: EdgeInsets.zero,

                        ),

                        RadioListTile<String>(

                          value: 'International',

                          title: Text('International · 123,456.78'),

                          contentPadding: EdgeInsets.zero,

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 8),

                  Text('DATE DISPLAY',

                      style: TextStyle(

                        color: _muted(sheetContext),

                        fontSize: 11,

                        fontWeight: FontWeight.w800,

                      )),

                  RadioGroup<String>(

                    groupValue: date,

                    onChanged: (value) {

                      if (value != null) update(() => date = value);

                    },

                    child: Column(

                      children: const [

                        RadioListTile<String>(

                          value: 'dd MMM yyyy',

                          title: Text('12 Mar 2026'),

                          contentPadding: EdgeInsets.zero,

                        ),

                        RadioListTile<String>(

                          value: 'dd/MM/yyyy',

                          title: Text('12/03/2026'),

                          contentPadding: EdgeInsets.zero,

                        ),

                        RadioListTile<String>(

                          value: 'MM/dd/yyyy',

                          title: Text('03/12/2026'),

                          contentPadding: EdgeInsets.zero,

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 10),

                  SizedBox(

                    width: double.infinity,

                    height: 48,

                    child: FilledButton(

                      onPressed: () => Navigator.pop(sheetContext, (number, date)),

                      style: FilledButton.styleFrom(

                        backgroundColor: _accent(sheetContext),

                        foregroundColor: _onAccent(sheetContext),

                      ),

                      child: const Text('Apply Format',

                          style: TextStyle(fontWeight: FontWeight.w800)),

                    ),

                  ),

                ],

              ),

            ),

          ),

        ),

      ),

    );

    if (result == null || !mounted) return;

    final oldNumber = _numberFormat;

    final oldDate = _dateFormat;

    setState(() {

      _numberFormat = result.$1;

      _dateFormat = result.$2;

    });

    try {
      await CurrencyService.instance.setNumberFormat(result.$1);
      await CurrencyService.instance.setDateFormat(result.$2);

    } catch (_) {

      if (mounted) {

        setState(() {

          _numberFormat = oldNumber;

          _dateFormat = oldDate;

        });

        _toast('Number format could not be saved.');

      }

    }

  }



  String get _amountPreview {

    final grouped = _numberFormat == 'Indian' ? '1,23,456' : '123,456';

    return '${_selectedCurrency.symbol}$grouped.78';

  }



  String get _datePreview => switch (_dateFormat) {

        'dd/MM/yyyy' => '12/03/2026',

        'MM/dd/yyyy' => '03/12/2026',

        _ => '12 Mar 2026',

      };



  Widget _sectionTitle(BuildContext context, IconData icon, String title,

      String subtitle, Color color) {

    return Padding(

      padding: const EdgeInsets.fromLTRB(13, 12, 12, 10),

      child: Row(

        children: [

          Container(

            width: 35,

            height: 35,

            decoration: BoxDecoration(

              color: color.withValues(alpha: _dark(context) ? .21 : .12),

              borderRadius: BorderRadius.circular(10),

            ),

            child: Icon(icon, color: color, size: 19),

          ),

          const SizedBox(width: 10),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(title,

                    style: TextStyle(

                      color: _ink(context),

                      fontSize: 14,

                      fontWeight: FontWeight.w800,

                    )),

                const SizedBox(height: 3),

                Text(subtitle,

                    style: TextStyle(color: _muted(context), fontSize: 10.5)),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _panel(BuildContext context, Widget child) => Container(

        width: double.infinity,

        decoration: BoxDecoration(

          color: _card(context),

          borderRadius: BorderRadius.circular(17),

          border: Border.all(color: _border(context)),

          boxShadow: _dark(context)

              ? null

              : [

                  const BoxShadow(

                    color: Color(0x090B1745),

                    blurRadius: 18,

                    offset: Offset(0, 5),

                  ),

                ],

        ),

        child: child,

      );



  Widget _optionRow(BuildContext context, _CurrencyOption option) {

    final active = option.code == _currency;

    return Material(

      color: active ? _tint(context) : Colors.transparent,

      child: InkWell(

        onTap: _saving ? null : () => _saveCurrency(option.code),

        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

          child: Row(

            children: [

              Container(

                width: 26,

                height: 23,

                alignment: Alignment.center,

                decoration: BoxDecoration(

                  borderRadius: BorderRadius.circular(5),

                  color: _dark(context)

                      ? const Color(0xFF30394C)

                      : const Color(0xFFF3F5FA),

                ),

                child: Text(option.flag, style: const TextStyle(fontSize: 17)),

              ),

              const SizedBox(width: 12),

              Text(option.code,

                  style: TextStyle(

                    color: _ink(context),

                    fontSize: 12,

                    fontWeight: FontWeight.w800,

                  )),

              const SizedBox(width: 10),

              Expanded(

                child: Text('${option.name} (${option.symbol})',

                    style: TextStyle(color: _muted(context), fontSize: 11.5)),

              ),

              Icon(

                active ? Icons.check_circle_rounded : Icons.circle_outlined,

                color: active ? _accent(context) : _muted(context),

                size: 20,

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _selectionRow(

    BuildContext context, {

    required String flag,

    required String title,

    required String subtitle,

    required VoidCallback onTap,

  }) {

    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(12),

        child: Padding(

          padding: const EdgeInsets.fromLTRB(14, 9, 12, 10),

          child: Row(

            children: [

              Text(flag, style: const TextStyle(fontSize: 21)),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(title,

                        style: TextStyle(

                          color: _ink(context),

                          fontSize: 12,

                          fontWeight: FontWeight.w800,

                        )),

                    const SizedBox(height: 2),

                    Text(subtitle,

                        style: TextStyle(color: _muted(context), fontSize: 11)),

                  ],

                ),

              ),

              Icon(Icons.chevron_right_rounded, color: _muted(context)),

            ],

          ),

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final accent = _accent(context);

    final dark = _dark(context);

    return Scaffold(

      backgroundColor: _background(context),

      appBar: AppBar(

        backgroundColor: _background(context),

        foregroundColor: _ink(context),

        elevation: 0,

        scrolledUnderElevation: 0,

        titleSpacing: 0,

        title: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text('Currency and Region',

                style: TextStyle(

                    color: _ink(context),

                    fontSize: 17,

                    fontWeight: FontWeight.w800)),

            const SizedBox(height: 3),

            Text('Set your preferred currency and region',

                style: TextStyle(color: _muted(context), fontSize: 10.5)),

          ],

        ),

      ),

      body: !_ready

          ? Center(child: CircularProgressIndicator(color: accent))

          : SafeArea(

              top: false,

              child: ListView(

                padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),

                children: [

                  _panel(

                    context,

                    ClipRRect(

                      borderRadius: BorderRadius.circular(17),

                      child: Column(

                        children: [

                          _sectionTitle(context, Icons.tune_rounded, 'Currency',

                              'Choose the currency for your transactions', accent),

                          for (var i = 0; i < _currencies.length; i++) ...[

                            if (i > 0)

                              Divider(

                                  height: 1,

                                  indent: 15,

                                  endIndent: 15,

                                  color: _border(context)),

                            _optionRow(context, _currencies[i]),

                          ],

                          const SizedBox(height: 3),

                        ],

                      ),

                    ),

                  ),

                  const SizedBox(height: 12),

                  _panel(

                    context,

                    Padding(

                      padding: const EdgeInsets.only(bottom: 9),

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          _sectionTitle(context, Icons.calendar_month_rounded,

                              'Number Format',

                              'Choose how numbers, dates and amounts are shown',

                              const Color(0xFFFFA21D)),

                          Padding(

                            padding: const EdgeInsets.symmetric(horizontal: 12),

                            child: Material(

                              color: dark ? const Color(0xFF202539) : _tint(context),

                              borderRadius: BorderRadius.circular(11),

                              child: InkWell(

                                onTap: _pickFormats,

                                borderRadius: BorderRadius.circular(11),

                                child: Container(

                                  padding: const EdgeInsets.fromLTRB(13, 10, 10, 10),

                                  decoration: BoxDecoration(

                                    borderRadius: BorderRadius.circular(11),

                                    border: Border.all(color: _border(context)),

                                  ),

                                  child: Row(

                                    children: [

                                      Expanded(

                                        child: Column(

                                          crossAxisAlignment: CrossAxisAlignment.start,

                                          children: [

                                            Text('Preview',

                                                style: TextStyle(

                                                  color: _muted(context),

                                                  fontSize: 10,

                                                )),

                                            const SizedBox(height: 3),

                                            Text(_amountPreview,

                                                style: TextStyle(

                                                  color: _ink(context),

                                                  fontSize: 18,

                                                  fontWeight: FontWeight.w900,

                                                )),

                                            const SizedBox(height: 3),

                                            Text('$_datePreview  |  Thursday',

                                                style: TextStyle(

                                                  color: _muted(context),

                                                  fontSize: 10.5,

                                                )),

                                          ],

                                        ),

                                      ),

                                      Icon(Icons.chevron_right_rounded,

                                          color: _muted(context)),

                                    ],

                                  ),

                                ),

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                  const SizedBox(height: 12),

                  _panel(

                    context,

                    Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        _sectionTitle(context, Icons.location_on_rounded,

                            'Region / Country',

                            'Set your country to get localized experience', accent),

                        _selectionRow(

                          context,

                          flag: _selectedRegion.flag,

                          title: _selectedRegion.name,

                          subtitle: _selectedRegion.area,

                          onTap: _pickRegion,

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 12),

                  _panel(

                    context,

                    Column(

                      children: [

                        _sectionTitle(context, Icons.access_time_rounded,

                            'Timezone', 'Used for date, time and reminders',

                            const Color(0xFF286EF0)),

                        _selectionRow(

                          context,

                          flag: '🌐',

                          title: _selectedZone.label,

                          subtitle: _selectedZone.detail,

                          onTap: _pickTimezone,

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 16),

                  Padding(

                    padding: const EdgeInsets.symmetric(horizontal: 3),

                    child: Text(

                      'Preferences save automatically on this device. '

                      'Changing the currency does not convert recorded amounts; '

                      'other app screens need to read these preferences to use '

                      'the selected formats or timezone.',

                      style: TextStyle(

                        color: _muted(context),

                        fontSize: 10.5,

                        height: 1.45,

                      ),

                    ),

                  ),

                ],

              ),

            ),

    );

  }

}
