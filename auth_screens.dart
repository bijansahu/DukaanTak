import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'services.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A56DB), Color(0xFF0E3A9E), Color(0xFF16A34A)])),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(26)),
                child: const Text('🛍️', style: TextStyle(fontSize: 46))),
            const SizedBox(height: 18),
            const Text('DukaanTak', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Aapke Bazaar Se Aapke Ghar Tak', style: TextStyle(color: Colors.white70)),
          ]),
        ),
      );
}

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});
  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  final _c = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 40),
            const Text('Namaste! 🙏', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kText)),
            const SizedBox(height: 6),
            const Text('Enter your mobile number to get started', style: TextStyle(color: kMuted)),
            const SizedBox(height: 28),
            TextField(
              controller: _c,
              keyboardType: TextInputType.number,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(prefixText: '+91  ', hintText: '10-digit mobile number', counterText: ''),
            ),
            const SizedBox(height: 18),
            BigButton('Continue', _c.text.length == 10
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: _c.text)))
                : null),
          ]),
        )),
      );
}

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _auth = AuthService();
  final _c = TextEditingController();
  Timer? _t;
  int _left = 30;
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _send() {
    _err = null;
    _left = 30;
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left = max(0, _left - 1));
      if (_left == 0) t.cancel();
    });
    _auth.sendOtp(widget.phone,
        onSent: () {},
        onError: (m) {
          if (mounted) setState(() => _err = m);
        },
        onAuto: _done);
  }

  void _done() {
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await _auth.verify(_c.text);
      _done();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _err = e.code == 'invalid-verification-code' ? 'Wrong OTP. Please try again.' : (e.message ?? 'Verification failed');
      });
      _c.clear();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Verify OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kText)),
            const SizedBox(height: 6),
            Text('We sent a 6-digit code to +91 ${widget.phone}', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 28),
            // Firebase SMS codes are 6 digits (your HTML mock showed 4).
            TextField(
              controller: _c,
              autofocus: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 14),
              decoration: const InputDecoration(counterText: '', hintText: '------'),
              onChanged: (v) {
                if (v.length == 6 && !_busy) _verify(); // auto-verify
              },
            ),
            if (_err != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_err!, style: const TextStyle(color: kRed))),
            const SizedBox(height: 18),
            Center(
                child: _busy
                    ? const CircularProgressIndicator()
                    : _left > 0
                        ? Text('Resend code in ${_left}s', style: const TextStyle(color: kMuted))
                        : TextButton(onPressed: () => setState(_send), child: const Text('Resend OTP'))),
          ]),
        ),
      );
}

/// Used for first-time profile setup AND for "Edit address" (pass onDone: pop).
class SetupScreen extends StatefulWidget {
  final VoidCallback onDone;
  final bool editing;
  const SetupScreen({super.key, required this.onDone, this.editing = false});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController(), _village = TextEditingController(), _lm = TextEditingController();
  double? _lat, _lng;
  String _gps = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _name.text = p['name'] ?? '';
    _village.text = p['village'] ?? '';
    _lm.text = p['landmark'] ?? '';
    _lat = (p['lat'] as num?)?.toDouble();
    _lng = (p['lng'] as num?)?.toDouble();
  }

  bool get _valid => _name.text.trim().isNotEmpty && _village.text.trim().isNotEmpty && _lm.text.trim().isNotEmpty;

  Future<void> _detect() async {
    setState(() => _gps = 'Detecting…');
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _gps = 'Permission denied – you can still type your village.');
        return;
      }
      final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
      setState(() {
        _lat = p.latitude;
        _lng = p.longitude;
        _gps = '✅ Location detected (${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})';
      });
    } catch (_) {
      setState(() => _gps = 'Could not detect location. Please try again outdoors.');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final user = FirebaseAuth.instance.currentUser!;
    final data = {
      'name': _name.text.trim(),
      'phone': user.phoneNumber,
      'village': _village.text.trim(),
      'landmark': _lm.text.trim(),
      'lat': _lat,
      'lng': _lng,
    };
    await Db().saveProfile(user.uid, data);
    if (!mounted) return;
    context.read<AppState>().setProfile(data);
    widget.onDone();
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: kMuted, fontSize: 13)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.editing ? AppBar(title: const Text('Edit address')) : null,
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
          if (!widget.editing) ...[
            const SizedBox(height: 10),
            const Text('Set up your profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kText)),
            const SizedBox(height: 6),
            const Text('So shops can find you easily', style: TextStyle(color: kMuted)),
          ],
          _label('Full name'),
          TextField(controller: _name, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'e.g. Rahul Mondal')),
          _label('Village / Area name'),
          TextField(controller: _village, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'e.g. Maheshpur')),
          const SizedBox(height: 16),
          BigButton('📍 Detect Current Location (GPS)', _detect, outlined: true),
          if (_gps.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_gps, style: const TextStyle(color: kMuted))),
          _label('Nearby landmark *'),
          TextField(
              controller: _lm,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'e.g. Near Primary School, Kali Mandir, Main Road')),
          const SizedBox(height: 24),
          _saving ? const Center(child: CircularProgressIndicator()) : BigButton('Save & Start Shopping', _valid ? _save : null, color: kGreen),
        ])),
      );
}
