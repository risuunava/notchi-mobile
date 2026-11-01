import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  static AppStrings of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context).languageCode);
  }

  bool get _isIndonesian => languageCode == 'id';

  String _t(String id, String en) => _isIndonesian ? id : en;

  String get appTitle => 'Notchi';

  String get homeTitle => _t('Notchi Mobile', 'Notchi Mobile');

  String get homeSubtitle => _t(
    'Kendalikan PC dari HP di jaringan yang sama.',
    'Control your PC from your phone on the same network.',
  );

  String get notPairedTitle => _t('Belum terhubung', 'Not connected');

  String get notPairedBody => _t(
    'Pindai QR di Notchi PC untuk memasangkan HP ini.',
    'Scan the QR code in Notchi PC to pair this phone.',
  );

  String get scanQr => _t('Pindai QR', 'Scan QR');

  String get manualConnect => _t('Hubungkan manual', 'Connect manually');

  String get connectedTitle => _t('Terhubung', 'Connected');

  String connectedTo(String name) =>
      _t('Terhubung ke $name', 'Connected to $name');

  String get forgetDevice => _t('Lupakan perangkat', 'Forget device');

  String get forgetTitle => _t('Lupakan perangkat ini?', 'Forget this device?');

  String get forgetBody => _t(
    'Token akan dihapus dari HP. Kamu perlu memindai QR lagi untuk terhubung.',
    'The token will be removed from this phone. You will need to scan the QR code again.',
  );

  String get forgetRemoteFailed => _t(
    'Dihapus dari HP, tetapi PC tidak terjangkau. Cabut juga perangkat ini di Settings Notchi PC.',
    'Removed from this phone, but the PC was unreachable. Also revoke this device in Notchi PC settings.',
  );

  String get scanTitle => _t('Pindai QR', 'Scan QR');

  String get scanHint => _t(
    'Arahkan kamera ke QR yang ditampilkan Notchi PC.',
    'Point the camera at the QR code shown in Notchi PC.',
  );

  String get flashlight => _t('Senter', 'Flashlight');

  String get cameraError => _t(
    'Kamera tidak bisa dibuka. Periksa izin kamera lalu coba lagi.',
    'The camera could not be opened. Check the camera permission and try again.',
  );

  String get manualTitle => _t('Hubungkan manual', 'Connect manually');

  String get manualHint => _t(
    'Masukkan alamat dan token dari QR Notchi PC.',
    'Enter the address and token from the Notchi PC QR code.',
  );

  String get hostLabel => _t('Alamat PC', 'PC address');

  String get hostHint => '192.168.1.10';

  String get portLabel => _t('Port', 'Port');

  String get tokenLabel => _t('Pairing token', 'Pairing token');

  String get connect => _t('Hubungkan', 'Connect');

  String get cancel => _t('Batal', 'Cancel');

  String get retry => _t('Coba lagi', 'Retry');

  String get back => _t('Kembali', 'Back');

  String get done => _t('Selesai', 'Done');

  String get connectingTitle => _t('Menghubungkan...', 'Connecting...');

  String get verifyingPc => _t('Memeriksa PC...', 'Checking the PC...');

  String get waitingTitle => _t('Menunggu persetujuan', 'Waiting for approval');

  String get waitingBody => _t(
    'Setujui "Izinkan perangkat ini?" di Notchi PC.',
    'Approve "Allow this device?" in Notchi PC.',
  );

  String get successTitle => _t('Berhasil terpasang', 'Paired successfully');

  String get successBody => _t(
    'HP ini sekarang terhubung ke Notchi PC.',
    'This phone is now connected to Notchi PC.',
  );

  String get errorTitle => _t('Gagal terhubung', 'Connection failed');

  String get invalidHost => _t('Alamat PC tidak valid.', 'Invalid PC address.');

  String get invalidPort => _t(
    'Port harus berupa angka 1-65535.',
    'Port must be a number between 1 and 65535.',
  );

  String get missingToken =>
      _t('Pairing token wajib diisi.', 'Pairing token is required.');

  String get errorInvalidQr =>
      _t('QR tidak dikenali.', 'Unrecognized QR code.');

  String get errorUnsupportedVersion => _t(
    'Versi Notchi PC tidak didukung. Perbarui aplikasi.',
    'This Notchi PC version is not supported. Update the app.',
  );

  String get errorPcMismatch => _t(
    'QR tidak cocok dengan PC yang ditemukan.',
    'The QR code does not match the PC that was found.',
  );

  String get errorInvalidToken => _t(
    'Token tidak valid atau sudah dicabut.',
    'The token is invalid or has been revoked.',
  );

  String get errorPairingExpired => _t(
    'QR sudah kedaluwarsa atau pernah dipakai. Tampilkan QR baru di PC.',
    'The QR code expired or was already used. Show a new one on the PC.',
  );

  String get errorPairingDenied =>
      _t('Permintaan ditolak di PC.', 'The request was denied on the PC.');

  String get errorPairingTimeout => _t(
    'Tidak ada persetujuan dari PC. Coba lagi.',
    'The PC did not approve in time. Try again.',
  );

  String get errorAlreadyPaired => _t(
    'Perangkat ini sudah terpasang. Cabut dulu di Settings Notchi PC.',
    'This device is already paired. Revoke it in Notchi PC settings first.',
  );

  String get errorRateLimited => _t(
    'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
    'Too many attempts. Wait a moment and try again.',
  );

  String get errorFeatureDisabled => _t(
    'Notchi Mobile dimatikan di PC.',
    'Notchi Mobile is disabled on the PC.',
  );

  String get errorNetwork => _t(
    'PC tidak terjangkau. Pastikan HP dan PC berada di Wi-Fi yang sama.',
    'The PC is unreachable. Make sure the phone and PC are on the same Wi-Fi.',
  );

  String get errorTimeout =>
      _t('Koneksi ke PC timeout.', 'The connection to the PC timed out.');

  String get errorServer =>
      _t('Terjadi kesalahan di PC.', 'Something went wrong on the PC.');

  String get errorUnknown => _t('Terjadi kesalahan.', 'Something went wrong.');

  String get connectionOnline => _t('Terhubung', 'Connected');

  String get connectionConnecting => _t('Menghubungkan...', 'Connecting...');

  String get connectionReconnecting =>
      _t('Menyambung ulang...', 'Reconnecting...');

  String get connectionOffline => _t('Tidak terhubung', 'Not connected');

  String get connectionRevoked =>
      _t('Akses dicabut. Pasangkan ulang.', 'Access revoked. Pair again.');

  String get connectionDisabled => _t(
    'Notchi Mobile dimatikan di PC.',
    'Notchi Mobile is disabled on the PC.',
  );

  String get connectionUnauthorized => _t(
    'Token tidak valid. Pasangkan ulang.',
    'Invalid token. Pair again.',
  );

  String get mediaTitle => _t('Media', 'Media');

  String get mediaNoMedia =>
      _t('Tidak ada media yang diputar', 'No media playing');

  String get mediaNoMediaHint => _t(
    'Buka aplikasi musik atau video di PC.',
    'Open a music or video app on the PC.',
  );

  String get mediaPlay => _t('Putar', 'Play');

  String get mediaPause => _t('Jeda', 'Pause');

  String get mediaPrevious => _t('Sebelumnya', 'Previous');

  String get mediaNext => _t('Berikutnya', 'Next');
}
