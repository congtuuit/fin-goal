const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

// Parse command line arguments
// Usage: node scripts/build_app.js [apk|appbundle|ipa] [dev|prod]
const args = process.argv.slice(2);
const target = args[0] || 'apk'; // apk, appbundle, ipa
const env = args[1] || 'prod'; // dev, prod

if (!['apk', 'appbundle', 'ipa', 'ios'].includes(target)) {
  console.error(`❌ Target không hợp lệ: "${target}". Vui lòng chọn: apk, appbundle, ipa, ios.`);
  process.exit(1);
}

if (!['dev', 'prod'].includes(env)) {
  console.error(`❌ Environment không hợp lệ: "${env}". Vui lòng chọn: dev, prod.`);
  process.exit(1);
}

// 1. Xác định file .env cần load
let envFile = env === 'prod' ? '.env.production' : '.env.development';
let envPath = path.resolve(__dirname, '..', envFile);

if (!fs.existsSync(envPath)) {
  // Dự phòng dùng file .env chung ở thư mục gốc
  envPath = path.resolve(__dirname, '..', '.env');
}

if (!fs.existsSync(envPath)) {
  console.warn(`⚠️ Không tìm thấy file môi trường (${envFile} hoặc .env). Sẽ build bằng cấu hình mặc định.`);
}

// 2. Đọc và parse file .env
const dartDefines = [];
if (fs.existsSync(envPath)) {
  const content = fs.readFileSync(envPath, 'utf-8');
  // Xử lý xuống dòng cho cả Windows (\r\n) và Unix (\n)
  const lines = content.split(/\r?\n/);
  
  for (let line of lines) {
    line = line.trim();
    // Bỏ qua comments và dòng trống
    if (!line || line.startsWith('#')) continue;
    
    // Tìm dấu = đầu tiên
    const index = line.indexOf('=');
    if (index > 0) {
      const key = line.slice(0, index).trim();
      const val = line.slice(index + 1).trim();
      
      // Nếu có giá trị key thì push vào dartDefines
      if (key) {
        // Bọc giá trị trong dấu nháy kép nếu chứa dấu cách
        const formattedVal = val.includes(' ') ? `"${val}"` : val;
        dartDefines.push(`--dart-define=${key}=${formattedVal}`);
      }
    }
  }
}

// 3. Xác định entry point
const entryPoint = env === 'dev' ? 'lib/main_dev.dart' : 'lib/main.dart';

// 4. Chuẩn bị lệnh build
const mobileDir = path.resolve(__dirname, '..', 'mobile');

// Flutter build target
let flutterTarget = target;
if (target === 'ipa') {
  flutterTarget = 'ipa';
}

const buildArgs = [
  'build',
  flutterTarget,
  '--release',
  '-t', entryPoint,
  ...dartDefines
];

console.log(`\n🚀 Bắt đầu quá trình Build/Release cho ${target.toUpperCase()} (${env.toUpperCase()})`);
console.log(`📍 Thư mục làm việc: ${mobileDir}`);
console.log(`📄 Sử dụng môi trường từ: ${fs.existsSync(envPath) ? path.basename(envPath) : 'None (Default)'}`);
console.log(`🛠️ Lệnh thực thi: flutter ${buildArgs.join(' ')}\n`);

// 5. Chạy lệnh Flutter
const result = spawnSync('flutter', buildArgs, {
  cwd: mobileDir,
  stdio: 'inherit',
  shell: true
});

if (result.status !== 0) {
  console.error(`\n❌ Quá trình build thất bại với mã thoát (exit code): ${result.status}`);
  process.exit(result.status || 1);
} else {
  console.log(`\n🎉 Build thành công cho ${target.toUpperCase()} (${env.toUpperCase()})!`);
}
