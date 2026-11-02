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

  String get connectionUnauthorized =>
      _t('Token tidak valid. Pasangkan ulang.', 'Invalid token. Pair again.');

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

  String get errorFileTooLarge => _t(
    'Ukuran file melebihi batas yang diizinkan di PC.',
    'File size exceeds the allowed limit on the PC.',
  );

  String get shelfTitle => _t('Drop Shelf', 'Drop Shelf');

  String get sendToShelf => _t('Kirim ke Drop Shelf', 'Send to Drop Shelf');

  String get sendFile => _t('Kirim File', 'Send File');

  String get sendText => _t('Kirim Catatan/Teks', 'Send Note/Text');

  String get textToShelfHint => _t(
    'Ketik catatan atau teks untuk dikirim ke PC...',
    'Type note or text to send to PC...',
  );

  String get send => _t('Kirim', 'Send');

  String get uploading => _t('Mengunggah...', 'Uploading...');

  String get uploadSuccess =>
      _t('Berhasil dikirim ke PC', 'Sent to PC successfully');

  String get uploadFailed => _t('Gagal mengirim ke PC', 'Failed to send to PC');

  String get statusTitle => _t('Status PC', 'PC Status');

  String get cpuUsage => _t('CPU', 'CPU');

  String get ramUsage => _t('RAM', 'RAM');

  String get diskUsage => _t('Penyimpanan', 'Disk');

  String get battery => _t('Baterai', 'Battery');

  String get charging => _t('Mengisi daya', 'Charging');

  String get notCharging => _t('Tidak mengisi daya', 'Not charging');

  String get navHome => _t('Beranda', 'Home');

  String get navFolder => _t('Folder', 'Folder');

  String get navNote => _t('Catatan', 'Note');

  String get navSettings => _t('Pengaturan', 'Setting');

  List<String> get _weekdays => _isIndonesian
      ? const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']
      : const [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];

  List<String> get _monthsShort => _isIndonesian
      ? const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ]
      : const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

  String dateShortLabel(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _monthsShort[date.month - 1];
    return '$weekday, ${date.day} $month';
  }

  String timeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get servicesTitle => _t('Layanan', 'Services');

  String get serviceIssue => _t('Laporkan Masalah', 'Report Issue');

  String get reportConnectionIssue =>
      _t('Laporkan masalah koneksi', 'Report connection issue');

  String get serviceSource => _t('Kode Sumber', 'Source Code');

  String get serviceWindows => _t('Notchi Windows', 'Notchi Windows');

  String get serviceMobile => _t('Notchi Mobile', 'Notchi Mobile');

  String get linkOpenFailed => _t(
    'Tautan tidak bisa dibuka di perangkat ini.',
    'The link could not be opened on this device.',
  );

  String get pcInfoTitle => _t('Informasi PC', 'PC Information');

  String get pcNameLabel => _t('Nama PC', 'PC name');

  String get ipAddressLabel => _t('Alamat IP', 'IP address');

  String get portLabelShort => _t('Port', 'Port');

  String get apiVersionLabel => _t('Versi API', 'API version');

  String get statusLabel => _t('Status', 'Status');

  String get folderSubtitle => _t(
    'Kirim file dari HP ke Drop Shelf PC.',
    'Send files from your phone to the PC Drop Shelf.',
  );

  String get dropShelfHint => _t(
    'Pilih file atau kirim catatan, lalu lihat riwayatnya di bawah.',
    'Pick a file or send a note, then see its history below.',
  );

  String get droppedFilesTitle =>
      _t('File yang sudah dikirim', 'Dropped files');

  String get noDroppedFiles => _t('Belum ada file', 'No files yet');

  String get noDroppedFilesHint => _t(
    'File yang kamu kirim ke PC akan muncul di sini.',
    'Files you send to the PC will appear here.',
  );

  String get clearHistory => _t('Hapus riwayat', 'Clear history');

  String get historyCleared => _t('Riwayat dihapus', 'History cleared');

  String get notesTitle => _t('Catatan', 'Notes');

  String get notesSubtitle => _t(
    'Catatan cepat yang tersimpan di HP ini.',
    'Quick notes stored on this phone.',
  );

  String get newNote => _t('Catatan baru', 'New note');

  String get noteTitleHint => _t('Judul catatan', 'Note title');

  String get noteBodyHint => _t('Tulis sesuatu...', 'Write something...');

  String get noteEmpty => _t('Belum ada catatan', 'No notes yet');

  String get noteEmptyHint => _t(
    'Tekan tombol catatan baru untuk mulai menulis.',
    'Tap the new note button to start writing.',
  );

  String get saveNote => _t('Simpan', 'Save');

  String get deleteNoteTitle => _t('Hapus catatan?', 'Delete note?');

  String get deleteNoteBody => _t(
    'Catatan ini akan dihapus dari HP.',
    'This note will be removed from the phone.',
  );

  String get delete => _t('Hapus', 'Delete');

  String get edit => _t('Edit', 'Edit');

  String get sendToPc => _t('Kirim ke PC', 'Send to PC');

  String get noteSentToPc =>
      _t('Catatan terkirim ke PC', 'Note sent to the PC');

  String get noteSendFailed => _t(
    'Catatan gagal dikirim. Periksa koneksi ke PC.',
    'The note could not be sent. Check the connection to the PC.',
  );

  String get settingsTitle => _t('Pengaturan', 'Settings');

  String get settingsSubtitle => _t(
    'Atur koneksi, bahasa, dan perangkat.',
    'Manage connection, language, and device.',
  );

  String get connectionSection => _t('Koneksi', 'Connection');

  String get languageSection => _t('Bahasa', 'Language');

  String get languageEnglish => 'English';

  String get languageIndonesian => 'Bahasa Indonesia';

  String get disconnectDevice => _t('Putuskan koneksi', 'Disconnect');

  String get disconnectTitle =>
      _t('Putuskan koneksi ke PC?', 'Disconnect from the PC?');

  String get disconnectBody => _t(
    'Perangkat ini akan dicabut dari Notchi PC. Kamu perlu memindai QR lagi untuk terhubung.',
    'This device will be revoked from Notchi PC. You will need to scan the QR code again to connect.',
  );

  String get disconnectFailed => _t(
    'Koneksi diputus di HP, tetapi PC tidak terjangkau. Cabut juga perangkat ini di Settings Notchi PC.',
    'Disconnected from this phone, but the PC was unreachable. Also revoke this device in Notchi PC settings.',
  );

  String get connectFirstTitle => _t('Hubungkan PC dulu', 'Connect a PC first');

  String get connectFirstBody => _t(
    'Pindai QR di Notchi PC supaya fitur ini bisa dipakai.',
    'Scan the QR code in Notchi PC to use this feature.',
  );

  String get aboutSection => _t('Tentang', 'About');

  String get appVersionLabel => _t('Versi aplikasi', 'App version');

  String get shelfUploadingLabel => _t('Mengunggah', 'Uploading');

  String dropShelfFiles(int count) => _t(
    '$count file di Drop Shelf',
    '$count ${count == 1 ? 'file' : 'files'} in Drop Shelf',
  );

  String get waitingPcStatus =>
      _t('Menunggu data status PC...', 'Waiting for PC status...');

  String get nowPlaying => _t('Sedang diputar', 'Now playing');

  String get unknownTrack => _t('Tidak ada media', 'No media');
}
