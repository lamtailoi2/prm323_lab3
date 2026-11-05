# Flow 3 — Application Detail: Kế hoạch triển khai đầy đủ

> Mục đích: tài liệu này chứa **toàn bộ** quyết định, hợp đồng dữ liệu, thiết kế màn hình, route, test và tài liệu cần cập nhật cho Flow 3. Agent/người triển khai không cần đọc lại toàn bộ repo trước khi làm; chỉ cần đọc file này + các file được liệt kê ở mục "File sẽ sửa".

## 1. Bối cảnh và mục tiêu

- Repo: `C:\Users\Tu\Documents\PRM323\prm323_lab3`
- Nhánh làm việc: `dev` (base commit `c13c3b5`, merge PR #17 `feat/search-ui`).
- Kiến trúc bắt buộc: **MVVM + Riverpod 3 + go_router**.
  - View → ViewModel → Service → Firebase.
  - View không import Firebase, không gọi service trực tiếp.
  - ViewModel không giữ `BuildContext`.
- Flow 3 gồm:
  1. Mở Application Detail từ My Applications.
  2. Xem trạng thái ứng tuyển, timeline, thông tin ứng viên/CV đã nộp.
  3. Xử lý lỗi tải dữ liệu + Retry (error/recovery).
- **Không** làm trong PR này:
  - Withdraw application + Undo (Flow 3d) — hoãn, xem `DC-27`.
  - Application Success (Flow 4) — Hảo làm.
  - CV Upload changes — Hảo làm.
  - Không thêm `statusHistory`, `companyWebsite`, `companyDescription`, `companySize`, `cvVersion`, `withdrawn`.

## 2. Quyết định phạm vi đã chốt

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Có làm Withdraw + Undo (3d) không? | **Không, để sau.** Ẩn nút/dialog Withdraw; giữ `G-18` mở; ghi `DC-27`. |
| 2 | Có mở rộng schema application ngay không? | **Có.** Thêm các field snapshot optional; Flow 4 sẽ ghi các field này. |
| 3 | Timeline lấy dữ liệu từ đâu? | **Suy ra từ 5 status hiện có.** Chỉ hiện ngày từ `appliedAt`/`nextStepAt`; không bịa note. |
| 4 | Có làm Application Success / CV Upload không? | **Không.** Chỉ Flow 3. |

## 3. Invariants / golden rules áp dụng

- Chỉ dùng token: `AppColors`, `AppSpacing`, `AppRadii`, `AppSizes`, `AppElevation`, `Theme.of(context).textTheme`. Không `Color(0x...)`, không số spacing/radius/font thô trong feature code.
- Tái sử dụng widget trong `lib/core/widgets/` trước khi tạo mới.
- Mọi data screen có `ViewState` (`lib/core/state/view_state.dart`): loading / empty / error / data.
- Không fake success, không hard-code “uploaded”, không nút chết, không dữ liệu bịa.
- Dữ liệu người dùng nằm dưới `users/{uid}/...`; không đổi Firestore rules.
- UI copy lấy đúng từ design, sentence case.
- Touch target ≥ 48 dp; icon-only button có `tooltip`; trạng thái không chỉ thể hiện bằng màu.
- Test ở 360 và 412 dp; `flutter analyze` sạch; `flutter test` xanh.
- Cập nhật tài liệu trong cùng PR.

## 4. Hợp đồng dữ liệu

### 4.1. Hiện trạng `InternshipApplication`

File: `lib/models/internship_application.dart`

Các field hiện có:

- `jobKey` (`String`, required)
- `title` (`String`, required)
- `companyName` (`String`, required)
- `appliedAt` (`DateTime`, required)
- `status` (`ApplicationStatus`, required)
- `nextStepAt` (`DateTime?`)

`ApplicationStatus` hiện có:

| storageValue | label |
|---|---|
| `submitted` | Submitted |
| `under_review` | Under review |
| `interview` | Interview |
| `accepted` | Accepted |
| `rejected` | Rejected |

`withdrawn` đang bị malformed (xem `G-18` / `DC-22`). Không thêm mới trong PR này.

### 4.2. Field bổ sung (optional, snapshot)

Thêm vào `InternshipApplication`:

| Field | Type | Ghi chú |
|---|---|---|
| `logoUrl` | `String?` | Logo công ty tại thời điểm nộp. |
| `location` | `String?` | Địa điểm. |
| `workMode` | `WorkMode?` | Storage: `remote` / `hybrid` / `on_site`. |
| `salary` | `String?` | Chuỗi hiển thị, ví dụ `$20–25/hour`. |
| `postedAt` | `DateTime?` | Ngày đăng tin. |
| `matchedSkills` | `List<String>` | Mặc định `const []`. |
| `applicant` | `ApplicantSnapshot?` | Snapshot ứng viên lúc nộp. |
| `cv` | `CvFile?` | Snapshot CV lúc nộp. |

Thêm model mới:

```dart
@immutable
class ApplicantSnapshot {
  const ApplicantSnapshot({
    this.fullName,
    this.email,
    this.phone,
  });

  final String? fullName;
  final String? email;
  final String? phone;

  bool get isEmpty =>
      (fullName == null || fullName!.isEmpty) &&
      (email == null || email!.isEmpty) &&
      (phone == null || phone!.isEmpty);

  factory ApplicantSnapshot.fromMap(Map<String, Object?>? data) { ... }
  Map<String, Object?> toMap() { ... }
}
```

### 4.3. Quy tắc parse

- Field required giữ nguyên: thiếu/sai kiểu → `FormatException`.
- `status` lạ hoặc `withdrawn` → `FormatException`.
- Field optional thiếu → `null` / `const []`.
- `cv` hoặc `applicant` malformed → coi như `null`, **application vẫn load được**.
- `workMode` lạ → `null`.
- `matchedSkills` không phải list string → bỏ phần tử sai, không làm hỏng document.
- Không override `==` chỉ theo ID.

### 4.4. Hợp đồng với Flow 4

Khi tạo application, Flow 4 ghi snapshot:

```text
title, companyName, appliedAt, status,
logoUrl, location, workMode, salary, postedAt,
matchedSkills, applicant, cv, nextStepAt
```

- `applicant` là snapshot dữ liệu lúc nộp, không phải tham chiếu live profile.
- `cv` copy từ map của CV đã nộp, không phải tham chiếu file hiện tại.

## 5. Service

File: `lib/services/application_service.dart`

Thêm method:

```dart
Stream<InternshipApplication?> watchApplication(String jobKey);
```

Hành vi:

- Chưa đăng nhập → phát `null`.
- Document không tồn tại → phát `null`.
- Document malformed → log Crashlytics + phát `AppException` với message an toàn:
  - singular: `This application is not available. Please try again.`
  - load error: `We could not load this application. Check your connection and try again.`
- Lỗi Firebase → map sang `AppException(kind, userMessage, cause: e)`.
- Không thêm write method trong PR này.
- Không đổi đường dẫn collection: vẫn `users/{uid}/applications/{jobKey}`.

## 6. ViewModel

File mới: `lib/features/applications/viewmodels/application_detail_viewmodel.dart`

```dart
final applicationDetailViewModelProvider =
    NotifierProvider.autoDispose
        .family<ApplicationDetailViewModel, ViewState<InternshipApplication>, String>(
  ApplicationDetailViewModel.new,
);
```

Hành vi:

- `build()`:
  - đọc `currentUserIdProvider` và `applicationServiceProvider` **trước** await;
  - nếu user null → `ViewEmpty`;
  - subscribe `watchApplication(jobKey)`;
  - state ban đầu `ViewLoading`.
- `retry()`:
  - bỏ qua nếu `state.isLoading`;
  - huỷ subscription cũ, subscribe lại, set `ViewLoading`.
- Kết quả stream:
  - `null` → `ViewEmpty`;
  - data → `ViewData`;
  - `AppException` → `ViewError(message, onRetry: retry)`.
- Analytics:
  - log `view_application` **một lần** khi lần đầu có data:
    - `internship_id`: `jobKey`
    - `status`: `status.storageValue`
  - không log lại khi status đổi live.
- `previewCv()`:
  - nếu không có `cv` → trả `AppException` (“This application has no submitted CV.”);
  - gọi `ExternalLinkService.open(cv.url)`;
  - trả `AppException?` để View hiện SnackBar.
- Sau mỗi await kiểm tra `ref.mounted` trước khi chạm `state`.
- Provider autoDispose + watch `currentUserIdProvider` để sign-out drop dữ liệu.

## 7. Screen và widget

### 7.1. File mới

- `lib/features/applications/screens/application_detail_screen.dart`
- `lib/features/applications/widgets/application_detail_parts.dart`
- `lib/features/applications/widgets/application_status_tracker.dart`
- `lib/features/applications/widgets/application_detail_skeleton.dart`

### 7.2. `ApplicationDetailScreen`

AppBar dùng `AppTopBar.back`:

- title: `Application Detail`
- subtitle: `Back to Applications`
- không share, không avatar.

Body theo `ViewState`:

| State | UI |
|---|---|
| `ViewLoading` | `ApplicationDetailSkeleton`, semantics label `Loading application`. |
| `ViewEmpty` | `Application not found` + `It may have been removed from this account.` + button `Back to Applications`. |
| `ViewError` | `StateView.error(message, onRetry: retry)`. |
| `ViewData` | Các section bên dưới. |

Các section của `ViewData`:

1. **Company summary**
   - `CompanyLogo` + title + company name.
   - Meta chips: location, work mode label, salary.
   - Dòng `Submitted {formatShortDate(appliedAt)}`.
   - Nếu có `postedAt`: `Posted {formatPostedAgeLong(postedAt)}`.
2. **Status Tracker**
   - Mapping:
     | status | bước | progress |
     |---|---|---|
     | `submitted` | 1 | 25% |
     | `underReview` | 2 | 50% |
     | `interview` | 3 | 75% |
     | `accepted` | 4 | 100%, label `Offer decision` |
     | `rejected` | ẩn tracker | `Application closed` + badge `Rejected` |
   - Next-step box:
     - `underReview` + `nextStepAt` → `Expected review outcome by {formatShortDate}`.
     - `interview` + `nextStepAt` → `Interview scheduled for {formatMonthDayTime}`.
     - còn lại: không hiện.
   - Timeline labels: `Submitted`, `Under review`, `Interview`, `Offer decision`.
   - Chỉ hiện ngày ở bước 1 (`appliedAt`) và bước interview (`nextStepAt`).
   - Không hiện note/ghi chú bịa.
3. **Applicant & Submitted CV**
   - Nếu có `cv`: `CvFileTile`:
     - details: `{formatFileSize} • Uploaded {formatShortDate}`;
     - trailing: `AppButton(label: 'Preview', icon: Symbols.visibility_rounded, variant: text)`.
   - Các row: `Full Name`, `University Email`, `Phone Number` (chỉ row có dữ liệu).
   - `Matched Candidate Skills`: `AppTag` cho từng skill.
   - Ẩn toàn bộ card nếu không có CV, applicant, hoặc skills.
4. **About the company**
   - `CompanyLogo` + company name + location.
   - Không description, không website, không company size.

- **Không** hiển thị `Withdraw application`.

### 7.3. Widget phụ

`application_detail_parts.dart`:

- `ApplicationSectionCard`: card có title + child.
- `ApplicationMetaChip`: icon + label, dùng token.
- `ApplicationIconText`: icon + text.
- `ApplicationInfoRow`: label + value.

`application_status_tracker.dart`:

- `ApplicationStatusTracker`
- `_NextStepBox`
- `_TimelineStep`
- `_RejectedSummary`

`application_detail_skeleton.dart`:

- `ApplicationDetailSkeleton` dùng `SkeletonBox`, giữ layout giống data state.

### 7.4. Shared widgets

- `lib/core/widgets/company_logo.dart`: tách `DetailCompanyLogo` từ `lib/features/internships/widgets/detail_parts.dart` thành `CompanyLogo`.
  - Cập nhật import/usage ở `internship_detail_screen.dart` và `apply_form_parts.dart`.
  - Xoá `DetailCompanyLogo` khỏi `detail_parts.dart` sau khi tách.
- `lib/core/widgets/app_top_bar.dart`: thêm `String? subtitle`.
  - Khi có subtitle: height = `AppSizes.appBarHeight + AppSpacing.s16` (72).
  - Title column gồm title + subtitle `bodySmall` / `textSecondary`.
  - Cập nhật test `test/core/widgets/components_test.dart`.

### 7.5. Format helpers

Dùng helper sẵn có trong `lib/core/utils/`:

- `formatShortDate`
- `formatPostedAgeLong`
- `formatMonthDayTime`
- `formatFileSize`

Không thêm dependency mới.

## 8. Navigation

File: `lib/app/router.dart`

- Thêm helper:

```dart
static String applicationDetail(String jobKey) => '/applications/$jobKey';
```

- Thêm route con dưới nhánh Applications:

```dart
GoRoute(
  path: ':jobKey',
  name: 'application_detail',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => ApplicationDetailScreen(
    jobKey: state.pathParameters['jobKey']!,
  ),
),
```

- Route nằm trên shell → không có bottom navigation.
- Back quay về Applications.

File: `lib/features/applications/screens/my_applications_screen.dart`

- Bỏ SnackBar “coming soon”.
- `_ApplicationsBody.onOpen` đổi thành `ValueChanged<InternshipApplication>`.
- Card tap và `Review offer` đều gọi:

```dart
context.push(AppRoutes.applicationDetail(app.jobKey));
```

File: `lib/features/internships/screens/internship_detail_screen.dart`

- `View application` đổi từ `context.go(AppRoutes.applications)` sang:

```dart
context.push(AppRoutes.applicationDetail(data.application!.jobKey));
```

## 9. Test

### 9.1. Model — `test/models/internship_application_test.dart`

- Document đầy đủ snapshot → parse đúng tất cả field.
- Document tối thiểu → optional null/rỗng.
- `cv` malformed → `cv == null`, application vẫn load.
- `applicant` malformed → `applicant == null`.
- `workMode` lạ → `null`.
- `matchedSkills` có phần tử sai → bỏ phần tử sai.
- `status` lạ / `withdrawn` → `FormatException`.

### 9.2. ViewModel — `test/features/applications/application_detail_viewmodel_test.dart`

- loading → data.
- document missing → `ViewEmpty`.
- lỗi service → `ViewError`.
- `retry()` thành công sau lỗi.
- `retry()` bị bỏ qua khi đang loading.
- `view_application` log đúng 1 lần.
- status đổi live → data cập nhật, không log lại.
- đổi account → provider drop/reset.
- `previewCv()`:
  - có CV → gọi `ExternalLinkService`;
  - lỗi mở link → trả `AppException`;
  - không có CV → trả `AppException`.

Dùng `ProviderContainer.test` + `FakeApplicationService` trong `test/helpers/fakes.dart`.

### 9.3. Screen — `test/features/applications/application_detail_screen_test.dart`

Ở cả 360 và 412 dp (`checkWidths`, `pumpThemed`):

- render đủ section khi có data đầy đủ;
- loading hiện skeleton;
- empty hiện `Application not found`;
- error hiện message + `Retry`;
- status `rejected` → `Application closed`, không có tracker 4 bước;
- status `accepted` → `Offer decision` 100%;
- ẩn section applicant/CV/skills khi thiếu dữ liệu;
- `Preview` lỗi → SnackBar;
- không có nút `Withdraw application`;
- `meetsGuideline(androidTapTargetGuideline)` cho widget tương tác.

### 9.4. Navigation

- `test/features/applications/my_applications_screen_test.dart`: card + `Review offer` mở detail.
- `test/features/internships/internship_detail_screen_test.dart`: `View application` mở detail.
- `test/app/router_test.dart`:
  - điều hướng tới `application_detail`;
  - log `screen_view` đúng;
  - log `view_application` đúng `internship_id` + `status`;
  - Back về Applications.

### 9.5. Shared widget

- `test/core/widgets/components_test.dart`: `AppTopBar.back` có subtitle render đúng, height 72.

### 9.6. E2E

File mới: `e2e_test/test_applications.py`

- `TC-09`: Application Detail khớp dữ liệu list (title, company, status).
- `TC-10`: airplane mode → error + `Retry` phục hồi.

Cập nhật `docs/test-plan.md`: đánh dấu `Ready (not run)` nếu chưa chạy được môi trường.

## 10. Tài liệu và bằng chứng

Cập nhật trong cùng PR:

| File | Nội dung |
|---|---|
| `docs/architecture.md` | §3/§6/§7: Application Detail, `watchApplication`, ViewModel. |
| `docs/design-traceability.md` | Row 11, Flow 3, components, `DC-22`, `DC-27`, §5. |
| `docs/design/design-system.md` | App Bar subtitle, Progress Stepper note. |
| `docs/analytics-plan.md` | Row 11 `view_application` → Implemented; row 12 vẫn Planned. |
| `docs/records/handoff-gaps.md` | Ghi chú `G-18` (withdraw hoãn). |
| `docs/records/test-report.md` | Kết quả chạy thật. |
| `docs/records/implementation-ai-log.md` | Prompt/output/verification cho AI dùng trong PR. |
| `docs/code-review.md` | Disclosure + finding/decision. |
| `README.md` | AI tools used. |
| `docs/test-plan.md` | TC-09/TC-10. |
| `evidence/applications/` | Ảnh/screenshot flow + failure case. |
| `evidence/analytics/` | DebugView `view_application` hoặc ghi “not run”. |

### 10.1. `DC-27` (design deviation)

Tóm tắt để ghi vào `docs/design-traceability.md` §4:

- Không có Withdraw/Undo (3d hoãn, `G-18`).
- Không share/avatar trên App Bar.
- Không hiện “Version 2.4”.
- Timeline dùng status label, không note.
- `rejected` ẩn tracker 4 bước.
- About company chỉ logo/name/location.
- Ngày dùng short format.
- Section optional ẩn khi snapshot thiếu.
- Thêm App Bar subtitle.

## 11. Thứ tự thực hiện

1. Model + parse + test model.
2. Service `watchApplication` + fake.
3. ViewModel + test.
4. Shared `CompanyLogo`, `AppTopBar.subtitle` + test.
5. Widget phụ + skeleton.
6. Screen + route + navigation.
7. Test screen/navigation.
8. Docs + E2E.
9. Chạy format/analyze/test.
10. AI review (tối đa 3 vòng) + log.

## 12. Lệnh kiểm tra

```bash
dart format lib test
flutter analyze
flutter test
```

Kỳ vọng:

- `dart format`: không còn file thay đổi.
- `flutter analyze`: `No issues found!`
- `flutter test`: tất cả pass.

E2E (nếu môi trường sẵn sàng):

```bash
uv run pytest e2e_test/test_applications.py --count 3 -v
```

Nếu không chạy được: ghi `not run` + lý do, không bịa kết quả.

## 13. Rủi ro / lưu ý

- `ApplicationStatus.withdrawn` malformed: không chạm trong PR này; test cũ vẫn phải xanh.
- Flow 4 chưa ghi snapshot: UI phải ẩn section thiếu dữ liệu, không crash.
- `AppTopBar` height thay đổi có thể ảnh hưởng test cũ: cập nhật test cùng PR.
- Route detail nằm trên shell: kiểm tra Back và deep link.
- Analytics chỉ log một lần: tránh log lặp khi stream emit lại.
- Không thêm dependency mới.
- Không đổi Firestore rules.

## 14. Trạng thái file kế hoạch

- File này được tạo để tránh agent phải đọc lại repo.
- Khi triển khai xong, cập nhật lại mục “Trạng thái” trong PR description và `docs/records/test-report.md`.

## 15. Trạng thái triển khai (2026-11-04)

- Code, test, docs và E2E đã xong theo §11 bước 1–8, trên branch `feat/application-detail` (tạo từ `dev` `c13c3b5`). **Chưa commit** — chủ repo tự commit/push.
- Kiểm tra thật: `dart format lib test` sạch, `flutter analyze` → `No issues found!`, `flutter test` → **577 passed** (Run 23 trong `docs/records/test-report.md`).
- Đã sửa 4 chỗ docs lệch code (Company Logo, Progress Stepper, tham số `CompanyLogo`, dòng giải thích của trạng thái Rejected trong DC-27).
- Còn lại, phải làm sau khi commit/thiết bị:
  - vòng AI review R1 trên `git diff dev...HEAD` + ghi `docs/code-review.md` và raw output;
  - screenshot `evidence/screens/application-detail-*` (360/412, rejected, error + Retry);
  - DebugView `view_application` (`evidence/analytics/`), nếu không chạy được thì ghi “not run”;
  - E2E TC-09/TC-10 với ARTEMIS (hiện `Ready (not run)`).

