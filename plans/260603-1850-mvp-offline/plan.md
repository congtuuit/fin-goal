# Plan: MVP Offline Hoàn Toàn & Định hướng Hybrid

Created: 2026-06-03T18:50:00Z
Status: ✅ Completed

## Overview
Kế hoạch này giúp chuyển đổi ứng dụng **fin-goal** sang chế độ Offline-first hoàn toàn. Dữ liệu được lưu cục bộ qua Isar DB, màn hình Login chỉ yêu cầu nhập tên và tích hợp cài đặt API Key AI của riêng khách hàng.

## Tech Stack
- Frontend: Flutter
- Local DB: Isar Database & SharedPreferences
- AI Integration: Gọi API REST trực tiếp (Gemini/OpenAI) từ client-side sử dụng Key cá nhân của khách hàng.

## Phases

| Phase | Name | Status | Progress |
|-------|------|--------|----------|
| 01 | [Design Architecture & Interfaces](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-01-architecture.md) | ✅ Complete | 100% |
| 02 | [Offline Auth Module](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-02-offline-auth.md) | ✅ Complete | 100% |
| 03 | [Local Database (Isar Setup)](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-03-local-database.md) | ✅ Complete | 100% |
| 04 | [AI Client-Side Settings](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-04-ai-client-side.md) | ✅ Complete | 100% |

## Quick Commands
- Start Phase 1: `/code phase-01`
- Check progress: `/next`
- Save context: `/save-brain`
