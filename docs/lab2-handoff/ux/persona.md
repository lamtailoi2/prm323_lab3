# Internship Finder — Persona and Problem Statement

This document defines the target user and problem for Internship Finder. It is the starting point for `ux/user-flow.md`, `design/DESIGN.md` and `design/screen-spec.md`.

**How to read this document.** Minh is a fictional persona. Details marked **(A)** are team assumptions that must be validated by the interviews in section 12. Details marked **(S)** are supported by a published source listed in section 12.1. Nothing in this file is presented as a real interview result.

---

## 1. Persona Snapshot

| Item | Description |
|---|---|
| Name | Minh Nguyen |
| Age range | 20–22 (age 21) |
| Role | Third-year Software Engineering student at a university in Ho Chi Minh City, about to start the internship semester |
| Living situation (A) | Rents a room near campus, commutes to class by bus or motorbike |
| Skills | Flutter, React, NestJS, basic MongoDB; two course projects and one personal project on GitHub |
| Languages | Vietnamese for daily use; reads English job descriptions slowly |
| Internship target | A 3-month internship starting next semester; prefers a paid role, open to hybrid or remote because of class schedule (A) |
| Experience with job hunting | First time applying for an internship; has no professional experience and a short CV (A) |

**One-line summary:** a busy third-year IT student who searches in short mobile sessions, applies to several companies, and needs to know where each application stands.

---

## 2. Context

### 2.1 Daily context

Minh has classes on campus most mornings and works on group projects in the afternoon. He checks his phone between classes, on the bus and in the evening. He browses roles in short sessions of 2 to 5 minutes, not in long sit-down searches. He plans to apply to about five to eight companies because he is not sure how competitive he is (A).

### 2.2 A typical day and where the app fits (A)

| Time | Situation | What Minh does with the app |
|---|---|---|
| 07:30 | On the bus, one hand holding a rail | Opens Search, types a skill, scans results |
| 12:00 | Lunch break, 10 minutes | Reviews saved listings, opens one Internship Detail |
| 15:30 | Between classes, campus Wi-Fi | Checks My Applications for new status updates |
| 21:00 | At home, more time | Completes an application: fills the form, uploads CV, reviews, submits |

### 2.3 Environment

- Campus Wi-Fi and mobile data that can be slow or drop (A).
- Phone used outdoors in bright light and with reduced brightness to save battery (A).
- Frequent interruptions; he must be able to leave a task and come back.

---

## 3. Goals and Motivations

| Goal | Why it matters to Minh |
|---|---|
| Find internships that match his skills (Flutter, React, NestJS) | Does not want to read through unrelated listings |
| Compare work mode and location quickly | He has classes and commutes by bus |
| Save interesting listings and return to them later | He decides over several days, not in one session |
| Apply quickly by reusing his profile and CV | Retyping the same information discourages him |
| Know the status of every application | Avoids applying twice and missing replies |

**Motivation:** gain real project experience before graduation and reduce the anxiety of not knowing whether his applications are moving forward.

---

## 4. Pain Points

Each pain point carries an evidence status. Update the status after the interviews in section 12.2.

| # | Pain point | Consequence for Minh | Evidence status |
|---|---|---|---|
| P1 | Listings are spread across several job sites, social groups and faculty announcements | Misses opportunities and sees duplicates | (A) validate |
| P2 | Hard to filter by skill and work mode; most sites focus on keywords and titles | Opens many listings that do not fit | (A) validate |
| P3 | Listings are long and unstructured; requirements are hard to find | Spends too long deciding whether to apply | (A) validate |
| P4 | Each application asks for the same information and CV again | Gives up halfway or makes mistakes | (A) validate; related finding on CV difficulty in 12.1 |
| P5 | Cannot easily see where he applied and what the status is | Risks applying twice or missing a reply | (A) validate |
| P6 | Uploads fail on unstable Wi-Fi without a clear explanation | Loses form progress and trust in the app | (A) validate |
| P7 | A listing found online may not reflect a real, open recruitment round | Wastes time applying to inactive postings | (S) see 12.1 |
| P8 | Limited personal connections make it hard to learn about opportunities | Depends on public listings only | (S) see 12.1 |

---

## 5. Behaviors and Device Habits

- Android phone, screen width about 360–412 dp. Android is the most widely used mobile operating system in Vietnam (S), so Android is the primary design target.
- Mostly one-handed use with the thumb in the lower half of the screen; important actions stay near the bottom.
- Short, interrupted sessions; he expects the app to keep his place.
- Needs clear error messages and a retry action when the network drops.
- Opens PDF CVs from phone storage or a cloud drive.
- Currently tracks applications in his head, in notes or in chat messages (A).

---

## 6. Accessibility Needs

| Need | Design requirement |
|---|---|
| Readable on a small screen in bright light | Body text at least 14sp; text contrast at least 4.5:1 |
| One-handed use | Touch targets at least 48 × 48 dp; primary actions near the bottom |
| Hard to distinguish colors in sunlight or at low brightness | Application status and validation errors never rely on color alone; every status has a text label and an icon |
| Interrupted use | Forms keep entered data; clear feedback after every action |

---

## 7. Journey Map

| Stage | What Minh does | Thinks or feels | Pain points | Opportunity (screens) |
|---|---|---|---|---|
| 1. Discover | Opens the app, types a skill, applies filters | "Which ones fit me?" | P1, P2 | Home, Search, Filter sheet |
| 2. Evaluate | Scans results, opens a listing | "Is this worth applying to?" | P3 | Search Results, Internship Detail |
| 3. Save | Bookmarks promising listings | "I'll decide tonight." | P1 | Saved Internships |
| 4. Apply | Fills the form, uploads CV, reviews, submits | "I hope nothing breaks." | P4, P6 | Application Form, Review, Success, Profile |
| 5. Track | Checks status in the following days | "Did they read it?" | P5 | My Applications, Application Detail |

---

## 8. Scenario

On the bus after class, Minh opens the app, types "Flutter", filters for Remote and Hybrid, and compares three internships in under a minute. He saves two. That evening he opens one, uses his stored CV to apply, and gets a confirmation. If the CV upload fails on the campus network, he sees a plain explanation and retries without losing his form. A week later he opens Applications and sees at a glance which companies are still under review.

---

## 9. Problem Statement

IT students in their third and fourth year need a fast way to find, save and track internship applications that match their skills, because listings are scattered across many sources and they lose track of where they have applied.

---

## 10. Success Criterion

**Primary (measurable):** A student can find an internship by skill and work mode in under 30 seconds and submit an application from Internship Detail in under 2 minutes, without needing help.

| Measure | Target |
|---|---|
| Time from Home to a filtered result list (skill + work mode) | Under 30 seconds |
| Time from `Apply now` to Application Success with a stored CV | Under 2 minutes |
| Tasks completed without errors in the prototype test (find and save, apply, check status) | At least 4 out of 5 testers |
| Recovery from a failed CV upload using `Retry` | Completed without asking for help |

---

## 11. Design Implications

| Persona insight | Design response | Screens |
|---|---|---|
| Short, interrupted sessions (2–5 minutes) | Few steps per task; one primary action per screen | All |
| Needs to filter by skill and work mode (P2) | Filter chips on Search; Filter sheet on Search Results | Search, Search Results |
| Retypes information each time (P4) | Application Form prefilled from Profile; stored CV | Application Form, Profile |
| Forgets what he applied to (P5) | Visible status labels per application | My Applications, Application Detail |
| Long, unstructured listings (P3) | Sections with headings and bullets; `Apply now` visible | Internship Detail |
| One-handed use | Bottom navigation; sticky primary buttons at the bottom | All |
| Unstable network (P6) | Skeleton loading, plain-language errors and `Retry` | Search Results, Application Form |
| Status must not depend on color | Every status badge has a text label and an icon | My Applications, Application Detail |
| Android is the main platform | Material-style components, 360 × 800 dp, checked at 412 dp | All |

---

## 12. Evidence and Validation

### 12.1 Secondary research (published sources)

These sources were found online and are summarized in the team's own words. Their limits are stated so they are not overstated.

| Source | Finding (paraphrased) | Used for | Limitation |
|---|---|---|---|
| Huỳnh Văn Sơn, "Từ những khó khăn của sinh viên mới tốt nghiệp nhìn về một số kĩ năng mềm nhằm chuẩn bị thích ứng nghề", Tạp chí Khoa học ĐHSP TP.HCM, no. 60, 2014. https://journal.hcmue.edu.vn/index.php/hcmuejos/article/download/2041/2025 | Survey of 200 graduates from three universities in Ho Chi Minh City. About 76% reported having few personal connections, which made it hard to reach job opportunities, and about 81% reported difficulty writing a CV and searching for jobs. The author also notes that a posting found on a website sometimes did not match a real recruitment round when the applicant arrived at the company. | P4 (CV effort), P7, P8 | Published in 2014; the sample is new graduates, not IT interns, and includes non-IT majors. Use only as background, not as proof for third-year IT students. |
| Statista, "Market share of mobile operating systems in Vietnam from 2009 to 2025" (data from StatCounter). https://www.statista.com/statistics/928956/vietnam-mobile-os-share | Android held the largest share of the mobile operating system market in Vietnam in 2025. | Choosing Android as the primary platform | General population, not students. The exact percentage is behind a paywall and is not quoted here. |
| StatCounter Global Stats, Android version share in Vietnam, June 2026. https://gs.statcounter.com/android-version-market-share/mobile/viet-nam | Android versions 11 to 16 each hold roughly 11% to 19% of Vietnamese Android devices, so users are spread across several versions. | Designing with standard Material components and avoiding very new platform features | Share of all Android users, not students. |

Sources searched but not used because they were not about Vietnamese IT students looking for internships: news about job fairs, and articles about the US and Singapore job markets.

### 12.2 Primary research: quick interviews (to be completed by the team)

Interview 3 to 5 classmates (about 5 minutes each) and write their answers in the table in their own words. Do not invent entries; the review session may ask about them. Names can be replaced by "Student A", "Student B".

**Script (read the same questions to everyone):**
1. Which sites, groups or channels do you use to find internships?
2. Think of the last time you looked for or applied to an internship. What was the most frustrating part?
3. How do you keep track of where you applied and what happened?
4. Do you search mostly on your phone or on a laptop? Where are you when you do it?
5. If an app could solve one thing for you, what would it be?

| # | Interviewee (year, major) | Q1: Where do you look? | Q2: Biggest frustration | Q3: How do you track applications? | Q4: Device and place | Q5: Wanted feature |
|---|---|---|---|---|---|---|
| 1 | *to fill* | *to fill* | *to fill* | *to fill* | *to fill* | *to fill* |
| 2 | *to fill* | *to fill* | *to fill* | *to fill* | *to fill* | *to fill* |
| 3 | *to fill* | *to fill* | *to fill* | *to fill* | *to fill* | *to fill* |

### 12.3 After the interviews

1. For each pain point P1 to P6 in section 4, change its status to "supported by interview #N" or remove it if no one confirmed it.
2. If interviewees describe a different main frustration, add it as a new pain point and adjust the design implications in section 11.
3. If most interviewees search on a laptop rather than a phone, record that and justify why the project still targets mobile (the course requires a mobile app).
4. Add a short note in `design/design-decisions.md` about any decision that changed because of the interviews.