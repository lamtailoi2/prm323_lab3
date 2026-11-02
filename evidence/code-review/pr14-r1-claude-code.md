<!-- Raw output of the AI review (Claude Code, Opus 5.5 subagent, independent context: given only the PR diff and AGENTS.md), saved verbatim. 2026-11-02. -->

## PR #14 — R1 review
Reviewed: `9ab527c...107c2a2` (diff of lib/, test/)

| # | File:line (dev HEAD) | Kind | Severity | Finding |
|---|---|---|---|---|
| 1 | lib/features/internships/viewmodels/apply_form_viewmodel.dart:286 | bug | major | After an upload fails, `continueToReview()` quietly returns the Profile CV while the form still shows "CV could not be uploaded", so the student moves on with a CV they never picked. |
| 2 | lib/features/internships/screens/apply_form_screen.dart:95 (also :142) | bug | major | `Edit skills` / `Edit profile` / `Go to Profile` call `context.go(AppRoutes.profile)`. This removes the Detail and the Apply Form, so the CV uploaded for this internship is lost, any upload still running is cut off, and Back never returns to the form. |
| 3 | lib/features/internships/viewmodels/apply_form_viewmodel.dart:314 (also :266, :310) | security | minor | CVs uploaded for one internship are never deleted. `Use CV from Profile`, `Replace` and leaving the form all leave CV PDFs (personal data) in `cvs/{uid}` that nothing references. `cv_upload` is still logged when the result is thrown away. |
| 4 | lib/features/internships/viewmodels/apply_form_viewmodel.dart:187 | bug | minor | When the profile stream fails, the error is swallowed and the form shows it as "Profile has no CV": the tip plus the empty dropzone, with no error state and no Retry. |
| 5 | test/features/internships/apply_form_viewmodel_test.dart:91 | test gap | minor | The "apply_start once" test invalidates a value-overridden `currentUserIdProvider`, so the ViewModel never rebuilds. The user-switch path (rule 11), the saved-copy fallback (G-25 #5) and leaving mid-upload are all untested. |
| 6 | lib/features/internships/screens/apply_form_screen.dart:146 | maintainability | minor | The doc comment on `_banner` says nothing is shown once a CV was uploaded for this internship, but the code still shows the tip whenever `profileCv == null`. |

### Details
1. **Continue to review hands over a CV the student did not choose.** Scenario: the student has `Profile_CV.pdf`, taps `Replace`, picks `Job_CV.pdf`, taps `Update CV`, then taps `Cancel` while it uploads. The sheet closes and the upload keeps going, which is the intended flow and is tested. The upload then fails. The state is now `pending=Job_CV`, `uploadError=network`, `uploadedCv=null`, `progress=null`. The form shows "CV could not be uploaded" with `Retry` / `Use CV from Profile`, and `Continue to review` is enabled because only `isUploading` disables it. Tapping it runs `continueToReview()`, which returns `state.cv` = `ApplyCv(Profile_CV, CvSource.profile)`, and the screen shows "Your CV is ready…". So the button made the choice that `Use CV from Profile` exists to make explicitly. Flow 4 will receive the wrong CV, which goes against rule 7 ("never fake success"). Fix: treat an unresolved upload as blocking.
   ```dart
   ApplyCv? continueToReview() {
     if (state.isUploading || state.pending != null) return null; // failed upload not resolved
     ...
   }
   ```
   Also disable the button (or show the error) while `uploadError != null && pending != null`, and add a ViewModel test for it.

2. **Profile links throw away the form.** `/home/internships/:jobKey/apply` and its Detail both sit on `rootNavigatorKey`. `context.go('/profile')` sets the location to `/profile`, so both pages are removed and the autoDispose `applyFormViewModelProvider` is disposed. Scenario: the student uploads `Job_CV.pdf` for this internship and sees "Missing: Java", taps `Edit skills`, and lands on Profile. Back does not return to the form. Opening the listing → `Apply now` again shows the Profile CV, and the uploaded file is gone (see #3). The skill line (and its `Edit skills`) stays visible during an upload, so the same tap also cuts off a running upload. The widget test only checks that "Profile tab" appears. Fix: keep the form on the stack:
   - `onEditSkills: () => showAppSheet(context, (_) => const EditSkillsSheet())`. The ViewModel already listens to the profile, so the match updates live. Consider moving the sheet to `core/widgets` if importing it across features is not wanted.
   - For the banner, use `context.push(AppRoutes.editProfile)` (that route is already on the root navigator, so Back returns to the form).

3. **Orphaned per-internship CV uploads.** Each `_upload` writes a new `cvs/{uid}/<slug>-<random>.pdf`, and only Flow 4 would ever reference it. Three cases leave the object in Storage with no Firestore pointer:
   - `useProfileCv()` (:266) just nulls `uploadedCv`.
   - A second `Replace` overwrites `uploadedCv` in state only.
   - Leaving the form (Back, or #2) while uploading lets the upload finish, logs `cv_upload` (:310), then hits `if (!ref.mounted) return true` (:314) and drops the result.

   Result: a student's CVs pile up where they cannot see or delete them, against the zero-cost quota, and `cv_upload{source: apply_form}` counts uploads that were never used. Two possible fixes:
   - Add `deleteFile(storagePath)` to `FileStorageService` (still under `cvs/{uid}`). Call it when an uploaded CV is replaced or dropped, when `!ref.mounted` after an upload, and from `ref.onDispose` for an `uploadedCv` that was never submitted. Move the analytics call after the mounted check.
   - Or upload only at submit.

   Also consider a `PopScope` confirm while `isUploading`.

4. **A profile load error looks like "no CV".** `onError` only sets `profileLoaded: true`, so `profileCv` stays null. Scenario: the Firestore read fails (offline cold start, permission or transient error) for a student who has a Profile CV. The form shows "Tip: complete your Profile once…", an empty `Upload CV` dropzone, and no skill line. `Continue to review` then shows "Add a CV to continue". No error or Retry is shown (rule 6), and `retry()` only re-subscribes the listing. Fix: keep a `profileError` (AppException) in state. Show a `StateView.error`-style inline message with `Retry` in the CV section that re-listens to `watchProfile`, and hide the tip while the profile is unknown.

5. **Tests don't exercise the risky paths.** `container.invalidate(currentUserIdProvider)` on an `overrideWithValue` provider rebuilds to the same uid. `Provider.updateShouldNotify` is `previous != next`, so `ApplyFormViewModel.build` never runs again, and the "once" assertion passes without being tested. Nothing checks that a user change drops `uploadedCv` / `pending` (rule 11). Nothing seeds `FakeSavedInternshipService`, so the `_savedCopies` fallback (`_emitListing`, G-25 #5) is untested. There is also no test for #1 (Continue after a failed upload) or for disposing the form mid-upload. Fix: drive `authStateChangesProvider` from a `StreamController` (or override `currentUserIdProvider` with a mutable source). Emit user B after an upload and assert `read().uploadedCv == null` and one `apply_start`. Add a case with the key removed from `byKey` but present in `saved`, expecting `ViewData`.

6. **`_banner` code and doc comment disagree.** With no Profile CV, uploading `Job_CV.pdf` for this internship leaves `state.cv.source == uploaded` and `profileCv == null`. The code reaches `if (state.profileCv == null)` (:146) and still shows the tip, while the comment (:133–135) promises "nothing … when a CV was uploaded for this internship". The current screen tests don't pin either behaviour. Decide which one is intended: either check `state.uploadedCv == null` before the tip, or correct the comment. Then add a widget assertion for the post-upload banner.
