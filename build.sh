#!/bin/bash

# Thiết lập UTF-8
export LANG=en_US.UTF-8

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "      🛠️  FIN-GOAL BUILD TOOL UTILITY (Unix) 🛠️"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Kiểm tra Node.js
if ! command -v node &> /dev/null; then
    echo "[❌ ERROR] Dự án yêu cầu cài đặt Node.js để chạy script build."
    echo "Vui lòng tải Node.js tại https://nodejs.org/ và thử lại."
    exit 1
fi

# Kiểm tra Flutter
if ! command -v flutter &> /dev/null; then
    echo "[❌ ERROR] Không tìm thấy Flutter CLI trong hệ thống."
    echo "Vui lòng thêm Flutter vào PATH của bạn."
    exit 1
fi

# Khởi tạo giá trị
TARGET=""
ENV=""

show_menu() {
    echo "Chọn nền tảng bạn muốn build:"
    echo "  [1] Android APK (File cài đặt trực tiếp)"
    echo "  [2] Android App Bundle - AAB (Để phát hành Google Play)"
    echo "  [3] iOS IPA (Yêu cầu macOS để chạy)"
    echo "  [4] Thoát"
    echo ""
    read -p "Nhập lựa chọn của bạn [1-4]: " platform_choice

    case $platform_choice in
        1)
            TARGET="apk"
            show_env_menu
            ;;
        2)
            TARGET="appbundle"
            show_env_menu
            ;;
        3)
            TARGET="ipa"
            show_env_menu
            ;;
        4)
            echo "Cảm ơn bạn đã sử dụng. Hẹn gặp lại!"
            exit 0
            ;;
        *)
            echo ""
            echo "[❌ Lựa chọn không hợp lệ! Vui lòng thử lại.]"
            echo ""
            show_menu
            ;;
    esac
}

show_env_menu() {
    echo ""
    echo "Chọn môi trường cấu hình:"
    echo "  [1] Development (Sử dụng .env.development / lib/main_dev.dart)"
    echo "  [2] Production (Sử dụng .env.production / lib/main.dart)"
    echo "  [3] Quay lại menu trước"
    echo ""
    read -p "Nhập lựa chọn của bạn [1-3]: " env_choice

    case $env_choice in
        1)
            ENV="dev"
            run_build
            ;;
        2)
            ENV="prod"
            run_build
            ;;
        3)
            echo ""
            show_menu
            ;;
        *)
            echo ""
            echo "[❌ Lựa chọn không hợp lệ! Vui lòng thử lại.]"
            echo ""
            show_env_menu
            ;;
    esac
}

run_build() {
    echo ""
    echo "⏳ Đang chạy lệnh build: node scripts/build_app.js $TARGET $ENV"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    node scripts/build_app.js $TARGET $ENV

    if [ $? -ne 0 ]; then
        echo ""
        echo "[❌ BUILD THẤT BẠI] Đã xảy ra lỗi trong quá trình build."
        echo ""
        read -p "Bấm Enter để quay lại menu chính..."
        show_menu
    else
        echo ""
        echo "[🎉 HOÀN THÀNH] Quá trình build hoàn tất thành công!"
        echo ""
        read -p "Bấm Enter để quay lại menu chính..."
        show_menu
    fi
}

# Chạy menu khởi đầu
show_menu
