# QELORYX — Official Release Sequence — Dev → Alpha → Beta → RC → Stable

**Version:** 1.0.0  
**Official Sequence:** Industry Standard — 5 Stages  
**Theme:** Midnight Aurora  
**Tagline:** Hear Beyond. Build Beyond.  
**SemVer:** MAJOR.MINOR.PATCH-CHANNEL.NUMBER

---

## 🎯 Official Release Sequence — Industry Standard

**This is the official, industry-standard release sequence used by Apple, Google, Microsoft, and all major software companies. QELORYX implements this officially.**

```
Dev (1/5) → Alpha (2/5) → Beta (3/5) → RC (4/5) → Stable (5/5) → Next Cycle
   ↓           ↓              ↓            ↓           ↓
Nightly   Internal QA   TestFlight   Final Verify   App Store   v1.1.0-dev.1
```

### Sequence Table — Official

| Order | Channel | Tag Example | Stability | Distribution | Purpose | Prerelease | Exit Criteria to Next |
|-------|---------|-------------|-----------|--------------|---------|------------|----------------------|
| 1/5 | **Dev** | `v1.0.0-dev.1` | Experimental | Internal core team only | Nightly builds, fast iteration, catch obvious crashes early, debug logs | true | No crash 5 tabs, basic playback |
| 2/5 | **Alpha** | `v1.0.0-alpha.1` | Alpha | Internal + QA | Features testable but not feature complete, internal QA, stability check | true | All 5 pillars testable, budgets met, no critical bugs, 30 min stable |
| 3/5 | **Beta** | `v1.0.0-beta.1` | Beta | TestFlight internal+external 100-1000 users | Feature complete, external feedback, real devices, large libraries, crash reporting | true | Real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged |
| 4/5 | **RC** | `v1.0.0-rc.1` | RC | TestFlight final | Code freeze, only critical fixes, final verification, App Store Connect validation | true | All 20+ RC checklist must pass all, validation pass, screenshots ready, code freeze |
| 5/5 | **Stable** | `v1.0.0` | Stable GA | App Store public | Production GA, public, all verifications passed | false | N/A — Start next cycle v1.1.0-dev.1 |

**Official Rules:**
- Strict order — No skipping — Must go Dev → Alpha → Beta → RC → Stable
- Each stage exit criteria must pass before next stage
- Versioning: SemVer `MAJOR.MINOR.PATCH-CHANNEL.NUMBER`
- Dev < Alpha < Beta < RC < Stable in stability
- Prerelease true for Dev, Alpha, Beta, RC — false for Stable only

---

## 📦 Versioning — SemVer Official

**Format:** `MAJOR.MINOR.PATCH-CHANNEL.NUMBER`

- **MAJOR:** Breaking changes (2.0.0)
- **MINOR:** New features backward compatible (1.1.0)
- **PATCH:** Bug fixes (1.0.1)
- **CHANNEL:** dev / alpha / beta / rc / (empty for stable)
- **NUMBER:** Iteration within channel (.1, .2, .3)

**Examples — Official Sequence for 1.0.0:**
```
v1.0.0-dev.1      — 1/5 Dev — First nightly
v1.0.0-dev.2      — 1/5 Dev — Second nightly, fixes from dev.1
v1.0.0-alpha.1    — 2/5 Alpha — First internal QA
v1.0.0-alpha.2    — 2/5 Alpha — Second alpha, fixes from alpha.1
v1.0.0-beta.1     — 3/5 Beta — First TestFlight beta, feature complete
v1.0.0-beta.2     — 3/5 Beta — Second beta, beta feedback fixes
v1.0.0-rc.1       — 4/5 RC — Release candidate 1, code freeze
v1.0.0-rc.2       — 4/5 RC — RC2, only critical fix from rc.1
v1.0.0            — 5/5 Stable — GA App Store
v1.0.1-dev.1      — Next patch cycle — 1/5 Dev
v1.1.0-dev.1      — Next minor cycle — 1/5 Dev
v2.0.0-dev.1      — Next major cycle — 1/5 Dev
```

**Current QELORYX Cycle — 1.0.0 — Official:**
```
Foundation 0.1.0-dev → Player 0.1.0-alpha.1 → Library 0.2.0-alpha → Lyrics 0.3.0-alpha → Downloads 0.4.0-alpha → Discovery 0.5.0-alpha → Polish 0.9.0-beta → Stable 1.0.0

Now official sequence for first public release:
v1.0.0-dev.1 (1/5) → v1.0.0-alpha.1 (2/5) → v1.0.0-beta.1 (3/5) → v1.0.0-rc.1 (4/5) → v1.0.0 (5/5 Stable)
```

---

## 🚧 Stage 1/5: Dev — Nightly — Internal — Experimental

**Tag:** `v1.0.0-dev.1`, `v1.0.0-dev.2`, `v1.0.0-dev.3`...  
**GitHub Release:** Prerelease = true  
**Name:** `QELORYX 1.0.0-dev.1 — Dev — Nightly — Internal`  
**Order:** 1/5 — First stage — Start of official sequence  
**Stability:** Experimental — May break, debug logs, unfinished features expected  
**Distribution:** Internal — Core team only (2-5 people), direct install via Xcode or ad-hoc  
**Purpose:** Daily/nightly builds from `arena/*` branches, fast iteration, catch obvious crashes early before QA

**Official Definition — Dev:**
> Dev builds are automatically or manually built from the latest development branch. They are not tested thoroughly, contain debug logging, may have unfinished features, and are only for core developers to quickly verify their changes don't break basic launch. Dev is the first stage in official release sequence.

**When to Release Dev:**
- After each major feature commit on arena branch
- Daily or after significant changes
- Before alpha, to catch obvious crashes internally
- After fixing dev feedback, new dev iteration

**Dev Entry Criteria — Minimal:**
- Code compiles — 107 Swift files, no build errors
- App launches — may crash after launch but should at least start

**Dev Exit Criteria — Must Pass Before Alpha (Relaxed):**
- [ ] App launches without immediate crash
- [ ] 5 tabs (Library/Search/Discovery/Home/Downloads) navigate without crash
- [ ] Basic playback: Play a track → Play/Pause/Seek works without crash
- [ ] No obvious memory leaks in 5 min use (check Xcode memory gauge)
- [ ] Build passes, tests pass (at least core tests)
- [ ] Cold Launch <2s (relaxed for dev, target is <1.5s but <2s OK for dev)
- [ ] Search <100ms (relaxed for dev, target <50ms but <100ms OK for dev)

**Dev Testing Checklist — Relaxed — 5 min:**
- [ ] Launch app → no crash on launch
- [ ] Navigate 5 tabs → Library, Search, Discovery, Home, Downloads — each tab open
- [ ] Library → see tracks (if any)
- [ ] Play a track → Play/Pause/Seek 3 times
- [ ] Search → type "a" → see results or empty state no crash
- [ ] Check Xcode logs for obvious errors (red errors)
- [ ] Memory gauge — no continuous increase in 5 min

**Known Issues — Dev — Expected — Not Bugs:**
- Unfinished UI polish — expected, not a bug for dev
- Debug logs affect performance slightly — expected
- Some edge cases not handled — expected
- May crash on rare flows — report and fix for next dev iteration, not blocker for dev itself
- Performance budgets may be slightly over relaxed thresholds — OK for dev

**How to Release Dev — Official:**

```bash
# 1. Ensure arena branch is up to date and pushed, build readiness verified
git checkout arena/01a0e693-qeloryx
git pull origin arena/01a0e693-qeloryx
git status # should be clean
cat Docs/BUILD_READINESS.md | head -20 # verify build ready

# 2. Tag dev build — annotated tag with detailed message
git tag -a v1.0.0-dev.1 -m "QELORYX v1.0.0-dev.1 — Dev — Nightly — Internal — 1/5 — First dev build — 107 Swift files production — All engines — Fast iteration — Midnight Aurora

Official Sequence: Dev(1/5) → Alpha(2/5) → Beta(3/5) → RC(4/5) → Stable(5/5)
Channel: Dev — 1/5 — Experimental — Internal core team only
Purpose: Nightly build from arena branch, catch obvious crashes early
Entry: Code compiles, app launches
Exit to Alpha: No crash 5 tabs, basic playback works
Next: v1.0.0-alpha.1 Alpha Internal QA"

# 3. Push tag — triggers .github/workflows/release.yml → auto-detect channel=dev order=1/5 prerelease=true → create GitHub Release + build iOS Release + tests
git push origin v1.0.0-dev.1

# 4. Watch GitHub Actions
# https://github.com/raynmahbub/Qeloryx/actions
# Jobs: detect-channel (dev 1/5), create-release (prerelease true Dev notes), build-for-release (Xcode 15.4 build), notify-channel (next Alpha)

# 5. Download artifact from Actions or Release page, install on device via Xcode, test dev checklist 5 min

# 6. If issues found, fix on arena branch, commit, push, then next dev iteration:
git add .
git commit -m "fix(dev): fix crash on Library tab when empty — dev.1 feedback"
git push origin arena/01a0e693-qeloryx
git tag -a v1.0.0-dev.2 -m "QELORYX v1.0.0-dev.2 — Dev — Nightly — Fixes from dev.1 — Library empty crash fix — Search debounce fix — 1/5"
git push origin v1.0.0-dev.2

# 7. Repeat until dev exit criteria pass → then Alpha
```

**Dev Release Notes Auto Generated by release.yml:**
- Official sequence context diagram with YOU ARE HERE Dev
- Dev purpose, stability experimental, distribution internal, nightly fast iteration
- What's in dev, entry/exit criteria, testing checklist relaxed 5 min, known issues expected, next Alpha command

---

## 🔬 Stage 2/5: Alpha — Internal Testing — QA

**Tag:** `v1.0.0-alpha.1`, `v1.0.0-alpha.2`, etc  
**GitHub Release:** Prerelease = true  
**Name:** `QELORYX 1.0.0-alpha.1 — Alpha — Internal Testing`  
**Order:** 2/5 — Second stage  
**Stability:** Alpha — Features testable but not feature complete, internal QA  
**Distribution:** Internal — Core team + QA (5-10 people), direct install + TestFlight internal only  
**Purpose:** Internal QA, feature testing, stability check before external beta, verify all 5 pillars testable

**Official Definition — Alpha:**
> Alpha builds are feature testable but not feature complete. They have passed dev exit criteria, are tested by internal QA, have reduced debug logs, and performance budgets are checked strictly from alpha onwards. Alpha is for internal QA to verify features work before external beta.

**When to Release Alpha:**
- After dev exit criteria passes — no crash 5 tabs, basic playback works
- All 5 pillars at least testable (Player, Library, Search, Lyrics, Downloads, Discovery)
- Ready for internal QA, not yet for external

**Alpha Entry Criteria — Must Have Passed Dev Exit:**
- Dev exit criteria all passed
- No crash on 5 tabs navigation
- Basic playback works Play/Pause/Seek
- Build passes, tests pass

**Alpha Exit Criteria — Must Pass Before Beta — Strict from Alpha:**
- [ ] All 5 pillars testable — Player, Library, Search, Lyrics, Downloads, Discovery — each at least basic flow works
- [ ] Cold Launch <1.5s ✅ — strict from alpha onwards (not relaxed)
- [ ] Warm Launch <0.6s ✅ — strict
- [ ] Search <50ms ✅ — strict
- [ ] Library Open <200ms ✅ — strict
- [ ] Queue Instant <10ms ✅
- [ ] Seek <50ms ✅
- [ ] Play/Pause Instant + Haptics <10ms ✅
- [ ] Lyrics Sync <50ms ✅
- [ ] Download Enqueue <50ms ✅
- [ ] No crash in 30 min continuous internal use — 2+ QA testers
- [ ] No critical bugs — crash, data loss, security
- [ ] Build passes 107 files production, tests pass CoreTests+DesignSystemTests

**Alpha Testing Checklist — 30 min — Internal QA:**
- [ ] Cold Launch <1.5s, Warm Launch <0.6s — measure with PerformanceMonitor
- [ ] Library scan 1000 tracks → open <200ms
- [ ] Search 1000 tracks → <50ms
- [ ] Player: Play/Pause/Seek/Next/Prev/Shuffle/Repeat — 10 times each
- [ ] Queue: Add 10 tracks, Remove 2, Reorder 2 — no crash
- [ ] Downloads: Enqueue 3, Pause 1, Resume 1, Cancel 1 — state machine works
- [ ] Lyrics: Open track with lyrics → Synced display, Karaoke word highlight, Fullscreen
- [ ] Discovery: Taste DNA profile generation <200ms, Recommendations <100ms
- [ ] 5 tabs navigation — 10 times each tab — no crash
- [ ] Background playback 15 min — lock screen, control center
- [ ] Artwork cache — scroll library fast — no flicker, memory stable
- [ ] No memory leak — Xcode memory gauge stable in 30 min

**Known Issues — Alpha — Should be Minor:**
- UI polish may still be in progress — minor, not critical
- Edge cases may still exist — should be rare
- Performance should meet budgets — verify, if fails fix before beta

**How to Release Alpha — Official:**

```bash
# 1. After dev exit OK, checkout arena, ensure all dev fixes committed, alpha checklist 30 min internal QA pass
git checkout arena/01a0e693-qeloryx
git log --oneline -5 # verify dev fixes
./Scripts/lint.sh # arch check

# 2. Tag alpha
git tag -a v1.0.0-alpha.1 -m "QELORYX v1.0.0-alpha.1 — Alpha — Internal Testing — 2/5 — Features testable — All 5 pillars — Budgets met — Internal QA — Midnight Aurora

Official Sequence: Dev(1/5) → Alpha(2/5) → Beta(3/5) → RC(4/5) → Stable(5/5)
Channel: Alpha — 2/5 — Internal QA — Features testable but not feature complete
Purpose: Internal QA, stability check before external beta
Entry: Dev exit passed — No crash 5 tabs, basic playback
Exit to Beta: All 5 pillars testable, budgets met Cold <1.5s Search <50ms etc, no critical bugs, 30 min stable
Next: v1.0.0-beta.1 Beta TestFlight external"

# 3. Push tag
git push origin v1.0.0-alpha.1

# 4. GitHub Actions → release.yml auto-detect channel=alpha order=2/5 prerelease true → create GitHub Release Alpha notes + build + tests

# 5. Internal QA 30 min checklist, 2+ testers

# 6. Fix alpha feedback on arena branch, then next alpha iteration if needed:
git tag -a v1.0.0-alpha.2 -m "QELORYX v1.0.0-alpha.2 — Alpha — Fixes from alpha.1 — Queue reorder crash fix — Lyrics sync fix — 2/5"
git push origin v1.0.0-alpha.2

# 7. Repeat until alpha exit criteria pass → then Beta
```

**Alpha Release Notes Auto Generated:**
- Official sequence context diagram YOU ARE HERE Alpha
- Alpha purpose internal QA features testable but not feature complete, distribution internal+QA
- What's in alpha, entry/exit criteria strict budgets, testing checklist 30 min internal QA, known issues minor, next Beta command

---

## 🧪 Stage 3/5: Beta — TestFlight — External Testing — Feature Complete

**Tag:** `v1.0.0-beta.1`, `v1.0.0-beta.2`, etc  
**GitHub Release:** Prerelease = true  
**Name:** `QELORYX 1.0.0-beta.1 — Beta — TestFlight`  
**Order:** 3/5 — Third stage  
**Stability:** Beta — Feature complete, needs external feedback  
**Distribution:** TestFlight — Internal + External testers (100-1000 users), App Store Connect TestFlight  
**Purpose:** External beta testing, real device testing, large libraries, feedback collection, crash reporting, performance on real devices

**Official Definition — Beta:**
> Beta builds are feature complete. All planned features for this version are implemented and testable. They are distributed via TestFlight to internal and external testers for real-world testing, feedback collection, and crash reporting. Beta is for external validation before RC.

**When to Release Beta:**
- After alpha exit criteria passes — all 5 pillars testable, budgets met, no critical bugs, 30 min stable internal
- All milestones for this version complete — for 1.0.0: Foundation, Player, Library, Lyrics, Downloads, Discovery, Polish, Stable all done
- Performance budgets all met strictly
- Ready for external eyes — TestFlight

**Beta Entry Criteria — Must Have Passed Alpha Exit:**
- Alpha exit criteria all passed
- All 5 pillars testable and stable — Player, Library DNA, Taste DNA, Audio Lab, Spaces production
- Cold <1.5s, Warm <0.6s, Search <50ms, Library <200ms, Queue Instant, Seek <50ms, Play/Pause Instant+Haptics <10ms, Lyrics <50ms, etc all met
- No critical bugs — crash, data loss, security
- Build passes 107 files, tests pass

**Beta Exit Criteria — Must Pass Before RC — External Validation:**
- [ ] Real device testing iPhone 12, 13, 14, 15, iOS 17+ — 5+ different devices
- [ ] Library scanning 10k+ tracks works — incremental indexing, no crash
- [ ] Background playback 1 hour stable — lock screen, control center, background
- [ ] Artwork cache 500MB LRU eviction works — scroll fast 10k library, no flicker, memory stable
- [ ] Download resume after network loss works — airplane mode toggle, resume
- [ ] Lyrics sync accuracy verified — LRC, enhanced karaoke, translation
- [ ] Taste DNA recommendations quality acceptable — top genres, artists, mood
- [ ] No crash in 1 hour continuous use — 10+ external testers, each 1h
- [ ] Crash-free rate >99% in TestFlight — App Store Connect crash reports
- [ ] Feedback — No critical issues, minor issues triaged, critical fixes done
- [ ] Performance budgets all met on real devices — not just simulator
- [ ] Accessibility VoiceOver + Dynamic Type tested — at least basic
- [ ] Haptics all interactions tested — Play/Pause/Seek/Queue/Favorite/Download/TabChange

**Beta Testing Focus Areas — 1 hour per tester:**
- [ ] Real device iPhone 12-15, iOS 17+ — 5+ devices
- [ ] Library 10k+ tracks scanning and open <200ms
- [ ] Background playback stability 1h — lock, control center, background fetch
- [ ] Artwork cache 500MB LRU — scroll fast, no flicker, eviction works
- [ ] Download resume after network loss — airplane mode, WiFi off/on, resumeData
- [ ] Lyrics sync accuracy — standard LRC, enhanced <mm:ss.xx>word karaoke, translation es/fr/de/ja/ko/zh/bn
- [ ] Taste DNA quality — top genres percentage+color, top artists playCount, mood energy/valence, eras, diversityScore
- [ ] Recommendations quality — becauseYouLiked, genreDeepDive, rediscover, moodMatch, favoritesMix, newReleases
- [ ] Accessibility VoiceOver + Dynamic Type — VoiceOver navigate 5 tabs, Dynamic Type larger text
- [ ] Haptics all interactions — play medium, pause light, favorite success, seek selection, queueAdd light, downloadStart medium, downloadComplete success, error error, tabChange selection, lyricTap light
- [ ] Dark mode Midnight Aurora theme — Aurora Blue #3B82F6, Midnight #050816, Emerald #10B981, Sunset #F97316, Ice White #F8FAFC
- [ ] Memory usage — no leaks in 1h — Instruments check if possible
- [ ] Battery usage — reasonable — no excessive drain in background

**Beta Feedback to Collect — For Triage:**
- Crashes with steps to reproduce — critical, fix before RC
- Performance issues — launch, search, library open over budget — critical if budget fail
- UI glitches, layout issues — minor unless critical
- Audio playback issues — critical if no sound, background fail
- Feature requests — for next minor (1.1.0), not this release (1.0.0) — defer
- Taste DNA recommendations not relevant — minor, tune for next minor

**How to Release Beta — Official:**

```bash
# 1. After alpha exit OK, checkout arena, ensure all alpha fixes committed, alpha checklist 30 min internal QA pass, all 5 pillars production
git checkout arena/01a0e693-qeloryx
git log --oneline -10 # verify alpha fixes
cat Docs/ACC/ACC.md | grep -A2 "Performance" # verify budgets met

# 2. Tag beta
git tag -a v1.0.0-beta.1 -m "QELORYX v1.0.0-beta.1 — Beta — TestFlight — 3/5 — Feature complete — All pillars production — Budgets met — External testing — Midnight Aurora

Official Sequence: Dev(1/5) → Alpha(2/5) → Beta(3/5) → RC(4/5) → Stable(5/5)
Channel: Beta — 3/5 — Feature complete — TestFlight internal+external
Purpose: External beta testing, real devices, large libraries, feedback, crash reporting
Entry: Alpha exit passed — All 5 pillars testable, budgets met, no critical bugs, 30 min stable
Exit to RC: Real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged
Next: v1.0.0-rc.1 RC Release Candidate code freeze"

# 3. Push tag
git push origin v1.0.0-beta.1

# 4. GitHub Actions → release.yml auto-detect channel=beta order=3/5 prerelease true → create GitHub Release Beta notes TestFlight focus + build + tests

# 5. App Store Connect → My Apps → QELORYX → TestFlight → iOS → Add build from GitHub Actions artifact or Xcode archive → Add external testers group (100-1000) → Submit for Beta App Review (if external) → Collect feedback 1-2 weeks

# 6. Fix beta feedback on arena branch — critical fixes only for this release, feature requests defer to next minor, then next beta iteration if needed:
git add .
git commit -m "fix(beta): fix background playback crash after 30 min — beta.1 feedback — critical"
git push origin arena/01a0e693-qeloryx
git tag -a v1.0.0-beta.2 -m "QELORYX v1.0.0-beta.2 — Beta — Fixes from beta.1 — Background crash fix — Artwork cache eviction fix — 3/5"
git push origin v1.0.0-beta.2

# 7. Repeat until beta exit criteria pass crash-free >99% no critical issues → then RC
```

**Beta Release Notes Auto Generated:**
- Official sequence context diagram YOU ARE HERE Beta
- Beta purpose feature complete TestFlight internal+external, distribution 100-1000 users, feedback crash reporting
- What's in beta feature complete all milestones budgets met, entry/exit criteria, testing focus areas 1h per tester real device 10k tracks background 1h artwork cache download resume lyrics sync Taste DNA accessibility haptics dark mode memory battery, feedback to collect, next RC command

---

## 🎯 Stage 4/5: RC — Release Candidate — Final Verification — Code Freeze

**Tag:** `v1.0.0-rc.1`, `v1.0.0-rc.2`, etc  
**GitHub Release:** Prerelease = true (but close to stable, final before stable)  
**Name:** `QELORYX 1.0.0-rc.1 — RC — Release Candidate — Final Verification`  
**Order:** 4/5 — Fourth stage — Final before stable  
**Stability:** RC — Stable, code freeze, only critical fixes allowed  
**Distribution:** TestFlight — Final verification, internal + external final testers (50-100), App Store Connect validation  
**Purpose:** Final verification before App Store, App Store Connect validation pass, no new features, only critical bug fixes

**Official Definition — RC:**
> Release Candidate builds are code freeze. No new features are allowed. Only critical bug fixes (crash, data loss, security, performance budget fail, App Store rejection risk) are allowed. RC is for final verification, App Store Connect validation, and final TestFlight testing before stable GA.

**When to Release RC:**
- After beta exit criteria passes — real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged no critical bugs
- All performance budgets met strictly on real devices
- All tests pass, build passes
- Ready for App Store submission but need final verification
- Code freeze — team agrees no new features for this version

**RC Entry Criteria — Must Have Passed Beta Exit:**
- Beta exit criteria all passed — real device 5+ devices, 10k tracks, 1h background stable, crash-free >99%, feedback triaged, no critical bugs
- All performance budgets met on real devices
- No critical bugs — crash, data loss, security, App Store rejection risk
- Feedback triaged — critical fixes done, minor deferred to next minor, feature requests deferred to next minor/major

**RC Rules — Strict — Must Follow — No Exception — Official:**
- ❌ No new features — absolute, no matter how small
- ✅ Only critical bug fixes — crash, data loss, security, performance budget fail (with proof budget fails), App Store rejection risk (e.g., privacy description missing)
- ✅ Only performance fixes if budget fails — with proof budget fails on real device, minimal fix
- ✅ Docs updates allowed — README, CHANGELOG, BUILD_READINESS, RELEASE_FLOW, ACC — docs only, no code except critical fixes
- ❌ No refactoring — even if code is ugly, no refactoring in RC
- ❌ No new UI — even if UI can be improved, no new UI in RC
- ❌ No non-critical fixes — minor UI glitches, minor performance improvements not budget-related, minor accessibility improvements — defer to next minor
- ❌ No dependency updates unless critical security fix — e.g., SwiftLint version update not allowed unless security

**RC Exit Criteria — Must Pass All — No Exception — Before Stable — Official:**
- [ ] Build passes 107 Swift files production — no warnings (or warnings triaged)
- [ ] Tests pass CoreTests 11 files + DesignSystemTests — All Pass
- [ ] Cold Launch <1.5s ✅ — strict, real device iPhone 12-15
- [ ] Warm Launch <0.6s ✅ — strict
- [ ] Search <50ms ✅ — strict, 1000 tracks
- [ ] Library Open <200ms ✅ — strict, 1000 tracks
- [ ] Queue Instant <10ms ✅
- [ ] Seek <50ms ✅
- [ ] Play/Pause Instant + Haptics <10ms ✅
- [ ] Lyrics Sync <50ms ✅
- [ ] Karaoke <100ms ✅
- [ ] Download Enqueue <50ms ✅
- [ ] Taste DNA Gen <200ms ✅
- [ ] Recommendations <100ms ✅
- [ ] Animations <16ms 60fps ✅
- [ ] Haptics <10ms ✅
- [ ] Navigation <50ms ✅
- [ ] No crashes in 1 hour continuous use — 5+ devices iPhone 12-15 iOS 17+, each 1h, total 5h+ no crash
- [ ] Background playback 1 hour stable — lock screen, control center, background, no stop
- [ ] No memory leaks — Instruments Leaks check, or Xcode memory gauge stable in 1h
- [ ] Accessibility VoiceOver pass — VoiceOver navigate 5 tabs, play track, search
- [ ] App Store Connect validation pass — no warnings, no errors — Xcode Organizer validation
- [ ] TestFlight final build tested on 5+ devices iPhone 12-15 iOS 17+ — each 1h
- [ ] Screenshots, description, keywords, privacy policy, support URL, App Icon, launch screen ready for App Store — App Store Connect ready
- [ ] No new features since beta — code freeze verified via `git diff v1.0.0-beta.1..v1.0.0-rc.1 --stat` — only critical fixes, minimal diff
- [ ] Only critical fixes if any — minimal change, each fix justified as critical

**RC Verification Checklist — Official:**
- [ ] Instruments — Leaks — No leaks, reasonable memory (<200MB for 1000 tracks)
- [ ] TestFlight — 5+ devices, 1h each, no crash, background 1h stable
- [ ] App Store Connect — Validation pass — Xcode Organizer → Validate App → No warnings/errors
- [ ] No new features since beta — `git diff v1.0.0-beta.1..v1.0.0-rc.1 --stat` — only critical fixes, minimal diff, no new files unless critical
- [ ] Only critical fixes if any — minimal diff, each fix has issue reference, critical justification
- [ ] Docs complete — ADR 12, EPL 8, IL 8, SHM 8 51 research, ACC 1.0.0 Stable, README 1.0.0 Stable, CHANGELOG 1.0.0 Stable, BUILD_READINESS 1.0.0 Stable, RELEASE_FLOW Official Sequence

**How to Release RC — Official:**

```bash
# 1. After beta exit OK, code freeze on arena — team agrees no new features for 1.0.0
git checkout arena/01a0e693-qeloryx
git log --oneline -10 # verify beta fixes
git diff v1.0.0-beta.1..HEAD --stat # should be minimal, only critical fixes if any

# 2. Tag RC
git tag -a v1.0.0-rc.1 -m "QELORYX v1.0.0-rc.1 — RC — Release Candidate — 4/5 — Code freeze — All gates passed — Final verification — Midnight Aurora

Official Sequence: Dev(1/5) → Alpha(2/5) → Beta(3/5) → RC(4/5) → Stable(5/5)
Channel: RC — 4/5 — Code freeze — Only critical fixes — Final verification
Purpose: Final verification before App Store, App Store Connect validation, no new features
Entry: Beta exit passed — Real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged
Exit to Stable: All 20+ RC checklist must pass all — Cold <1.5s Search <50ms etc No crashes 1h Background 1h stable No leaks VoiceOver App Store validation Screenshots ready Code freeze no new features
Rules: No new features absolute, only critical fixes crash/data loss/security/budget fail/App Store rejection, docs allowed, no refactoring, no new UI, no non-critical fixes, no dep updates unless security
Next: v1.0.0 Stable GA App Store"

# 3. Push tag
git push origin v1.0.0-rc.1

# 4. GitHub Actions → release.yml auto-detect channel=rc order=4/5 prerelease true → create GitHub Release RC notes strict checklist 20+ must pass all + RC rules + build + tests

# 5. TestFlight final verification 5+ devices 1h each, App Store Connect validation Xcode Organizer Validate App, Instruments Leaks check, Screenshots/description/keywords ready

# 6. If critical bug found, fix ONLY that bug, minimal change, no refactoring, no new features, then next RC iteration:
git add .
git commit -m "fix(rc): fix critical crash on background playback after 45 min — rc.1 feedback — critical — minimal change — no new features

Critical justification: Crash on background playback after 45 min on iPhone 13 iOS 17.5, 100% reproducible, App Store rejection risk, crash-free rate drops to 98%
Fix: Minimal change — 3 lines — add nil check in NowPlayingManager
No new features, no refactoring, only critical fix
Tested: 1h background playback stable on iPhone 13, no crash"
git push origin arena/01a0e693-qeloryx
git tag -a v1.0.0-rc.2 -m "QELORYX v1.0.0-rc.2 — RC — Critical fix from rc.1 — Background playback crash fix — No new features — Minimal change — 4/5"
git push origin v1.0.0-rc.2

# 7. Repeat until RC exit criteria all pass no critical bugs → then Stable
```

**RC Release Notes Auto Generated:**
- Official sequence context diagram YOU ARE HERE RC Final Verification
- RC purpose code freeze only critical fixes final verification, distribution TestFlight final, stability RC stable
- What's in RC code freeze no new features only critical fixes all budgets met all gates passed App Store Ready verification, entry/exit criteria 20+ must pass all no exception, RC rules strict no new features only critical fixes docs allowed no refactoring no new UI no non-critical fixes no dep updates unless security, verification checklist Instruments TestFlight validation no new features since beta only critical fixes if any, next Stable command

---

## 🎉 Stage 5/5: Stable — GA — App Store Ready — Production

**Tag:** `v1.0.0`, `v1.1.0`, `v1.0.1`, etc (no channel suffix, plain SemVer)  
**GitHub Release:** Prerelease = false — Production GA  
**Name:** `QELORYX 1.0.0 — Stable — App Store — GA`  
**Order:** 5/5 — Final stage — General Availability — DONE  
**Stability:** Stable — Production ready, all verifications passed, GA  
**Distribution:** App Store — Public — Production — Public users  
**Purpose:** Production App Store release, public distribution, GA, official sequence completed

**Official Definition — Stable/GA:**
> Stable or General Availability (GA) builds are production ready. They have passed all previous stages exit criteria, all RC checklist must pass all, App Store Connect validation pass, screenshots/description ready, no critical bugs, crash-free >99.5%. Stable is public App Store release, official sequence completed.

**When to Release Stable:**
- After RC exit criteria all pass — 20+ checklist must pass all, no exception
- App Store Connect validation pass — no warnings, no errors — Xcode Organizer Validate App
- Screenshots, description, keywords, privacy policy, support URL, App Icon, launch screen ready — App Store Connect ready
- No critical bugs, crash-free >99.5% in TestFlight RC
- Team agrees ready for public

**Stable Entry Criteria — Must Have Passed RC Exit — All Must Pass — No Exception:**
- RC exit criteria all passed — 20+ items — Cold <1.5s, Warm <0.6s, Search <50ms, Library <200ms, Queue Instant, Seek <50ms, Play/Pause Instant+Haptics <10ms, Lyrics <50ms, Karaoke <100ms, Download Enqueue <50ms, Taste DNA <200ms, Recommendations <100ms, Animations <16ms 60fps, Haptics <10ms, Navigation <50ms, No crashes 1h 5+ devices, Background 1h stable, No leaks, VoiceOver pass, App Store validation pass, TestFlight 5+ devices 1h, Screenshots ready, No new features since beta, Only critical fixes if any minimal
- App Store Connect validation pass — no warnings/errors
- Screenshots, description, keywords, privacy policy, support URL, App Icon, launch screen ready
- All docs complete — ADR 12, EPL 8, IL 8, SHM 8 51 research, ACC 1.0.0 Stable, README 1.0.0 Stable, CHANGELOG 1.0.0 Stable, BUILD_READINESS 1.0.0 Stable, RELEASE_FLOW Official Sequence
- No critical bugs, crash-free >99.5% in TestFlight RC

**What's in Stable — 1.0.0 — Official:**
- Production ready 1.0.0 — All milestones completed — Foundation 0.1.0-dev, Player 0.1.0-alpha.1 QEL-012, Library 0.2.0-alpha QEL-024, Lyrics 0.3.0-alpha QEL-032, Downloads 0.4.0-alpha QEL-041, Discovery 0.5.0-alpha QEL-051, Polish 0.9.0-beta, Stable 1.0.0
- All 5 pillars production — Astryx Player, Library DNA, Taste DNA, Astryx Audio Lab, Astryx Spaces
- All performance budgets met strictly — Cold <1.5s, Warm <0.6s, Search <50ms, Library <200ms, Queue Instant, Seek <50ms, Play/Pause Instant+Haptics <10ms, Lyrics <50ms, Karaoke <100ms, Download Enqueue <50ms, Taste DNA <200ms, Recommendations <100ms, Animations <16ms 60fps, Haptics <10ms, Navigation <50ms
- All quality gates passed — Build 107 files production, Tests pass, Docs complete, Architecture respected, Naming QELORYX/Astryx, Performance, Accessibility, Haptics, Animations, Theme Midnight Aurora, Greenfield ownership
- App Store submission ready — Xcode archive ready, validation pass
- Docs complete, tests all pass, build App Store Ready

**How to Release Stable — Official — GA:**

```bash
# 1. After RC exit OK — all 20+ RC checklist pass, validation pass, screenshots ready, no critical bugs, crash-free >99.5%
git checkout arena/01a0e693-qeloryx
git log --oneline -10 # verify RC fixes minimal
git diff v1.0.0-rc.1..HEAD --stat # should be minimal or empty if no rc.2 needed
cat Docs/ACC/ACC.md | grep "1.0.0 Stable" # verify ACC 1.0.0 Stable

# 2. Tag Stable — no suffix, plain SemVer, prerelease false — GA
git tag -a v1.0.0 -m "QELORYX v1.0.0 — Stable — App Store Ready — GA — 5/5 — Hear Beyond. Build Beyond. — All milestones completed — 107 Swift files production — All budgets met — All gates passed — Official Sequence Completed — Midnight Aurora

Official Sequence: Dev(1/5) → Alpha(2/5) → Beta(3/5) → RC(4/5) → Stable(5/5) — Completed ✅
Channel: Stable — 5/5 — GA — Production — App Store public
Purpose: Production App Store release, public GA, official sequence completed
Entry: RC exit passed — All 20+ checklist must pass all — Cold <1.5s Search <50ms etc No crashes 1h Background 1h stable No leaks VoiceOver Validation Screenshots ready Code freeze
What's in Stable: Foundation 0.1.0-dev, Player 0.1.0-alpha.1 QEL-012, Library 0.2.0-alpha QEL-024, Lyrics 0.3.0-alpha QEL-032, Downloads 0.4.0-alpha QEL-041, Discovery 0.5.0-alpha QEL-051, Polish 0.9.0-beta, Stable 1.0.0 — All 5 pillars production — All budgets met — All gates passed — App Store Ready
Next: Start next cycle v1.1.0-dev.1 Dev or v1.0.1-dev.1 Patch"

# 3. Push tag — triggers .github/workflows/release.yml → auto-detect channel=stable order=5/5 prerelease false → create GitHub Release Stable GA with full milestones notes + build + tests + files ACC README CHANGELOG BUILD_READINESS RELEASE_FLOW
git push origin v1.0.0

# 4. GitHub Actions → release.yml creates Stable release prerelease false + build + tests + notify official sequence completed

# 5. Xcode Archive → App Store Connect → Submit for Review — Official GA
xcodegen generate
xcodebuild archive -project Qeloryx.xcodeproj -scheme Qeloryx -configuration Release -archivePath build/Qeloryx.xcarchive CODE_SIGNING_ALLOWED=NO
open build/Qeloryx.xcarchive
# Xcode Organizer → Distribute App → App Store Connect → Upload → App Store Connect → My Apps → QELORYX → App Store → Add build → Screenshots, description, keywords, privacy, support URL, icon, launch screen → Submit for Review

# 6. After stable released and approved, start next cycle:
git checkout -b arena/1.1.0-dev
# Update project.yml MARKETING_VERSION to 1.1.0
# Update Docs/ACC/ACC.md to 1.1.0-dev
# Then dev cycle again official sequence:
git tag -a v1.1.0-dev.1 -m "QELORYX v1.1.0-dev.1 — Dev — Nightly — 1/5 — Next cycle — New features — Minor"
git push origin v1.1.0-dev.1
# Then alpha, beta, rc, stable for 1.1.0

# Or patch cycle if critical fix needed after stable:
git checkout -b arena/1.0.1-dev
# Fix critical bug minimal change
git tag -a v1.0.1-dev.1 -m "QELORYX v1.0.1-dev.1 — Dev — Patch — Critical fix"
git push origin v1.0.1-dev.1
# Then alpha, beta, rc, stable for 1.0.1
```

**Stable Release Notes Auto Generated:**
- Official sequence context diagram YOU ARE HERE Stable GA DONE! Official Sequence Completed ✅ Dev→Alpha→Beta→RC→Stable
- Stable purpose production GA public App Store, entry criteria RC exit all must pass, what's in stable full milestones history 0.1.0-dev→1.0.0 Stable all 5 pillars budgets gates App Store Ready, after stable next cycle commands v1.1.0-dev.1 patch v1.0.1-dev.1 major v2.0.0-dev.1
- Official sequence table, performance budgets table all met, architecture 107 files layers DesignSystem tech stack quality gates greenfield 5 pillars, docs complete, tests all pass, build App Store Ready

---

## 🔄 Workflow — How release.yml Implements Official Sequence

**File:** `.github/workflows/release.yml` — Official Sequence Implementation

**Trigger:** tags `v*`, `v*-dev*`, `v*-alpha*`, `v*-beta*`, `v*-rc*`, `1.0.0`, `1.0.*`, `1.*.*` + workflow_dispatch with version+channel (dev/alpha/beta/rc/stable) + prerelease

**Jobs — Official:**

1. **detect-channel:** Auto-detect official channel from tag
   - `v1.0.0-dev.1` → channel dev, order 1/5 Dev, prerelease true, name "Dev — Nightly — Internal"
   - `v1.0.0-alpha.1` → channel alpha, order 2/5 Alpha, prerelease true, name "Alpha — Internal Testing"
   - `v1.0.0-beta.1` → channel beta, order 3/5 Beta, prerelease true, name "Beta — TestFlight"
   - `v1.0.0-rc.1` → channel rc, order 4/5 RC, prerelease true, name "RC — Release Candidate — Final Verification"
   - `v1.0.0` → channel stable, order 5/5 Stable, prerelease false, name "Stable — App Store — GA"
   - Official sequence echo: Dev(1)→Alpha(2)→Beta(3)→RC(4)→Stable(5), current order

2. **create-release:** Generate official channel-specific release notes with official sequence context diagram YOU ARE HERE, entry/exit criteria, testing checklist, known issues, next command, official sequence table, performance budgets, architecture, docs, tests, build + create GitHub Release via `softprops/action-gh-release@v1` with prerelease flag and files ACC README CHANGELOG BUILD_READINESS RELEASE_FLOW

3. **build-for-release:** Setup Xcode 15.4, install xcodegen/swiftlint, lint strict, generate project, build Release generic/platform=iOS, run tests CoreTests+DesignSystemTests

4. **notify-channel:** Echo official sequence next steps based on channel — dev→alpha, alpha→beta, beta→rc, rc→stable, stable→next cycle v1.1.0-dev.1 + official sequence completed

**Release Notes Generation — Official — 5 Channels:**

- **Dev 1/5:** Official sequence context YOU ARE HERE Dev Start, purpose nightly fast iteration, what's in dev latest commits debug logs, entry minimal code compiles launches, exit relaxed no crash 5 tabs basic playback Cold <2s Search <100ms, testing checklist relaxed 5 min, known issues expected not bugs, next alpha command
- **Alpha 2/5:** Official sequence YOU ARE HERE Alpha Internal QA, purpose internal QA features testable but not feature complete, what's in alpha 5 pillars testable not complete internal QA debug reduced budgets strict from alpha, entry dev exit passed, exit strict all 5 pillars testable budgets met Cold <1.5s Search <50ms etc no critical bugs 30 min stable, testing checklist 30 min internal QA, known issues minor, next beta command
- **Beta 3/5:** Official sequence YOU ARE HERE Beta External Testing, purpose external beta feature complete TestFlight internal+external feedback real devices large libraries crash reporting, what's in beta feature complete all milestones budgets met TestFlight feedback crash reporting accessibility haptics polished, entry alpha exit passed, exit real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged, testing focus 1h per tester real device 10k background artwork cache download resume lyrics sync Taste DNA recommendations accessibility haptics dark mode memory battery, feedback to collect crashes performance UI audio feature requests, next RC command
- **RC 4/5:** Official sequence YOU ARE HERE RC Final Verification, purpose final verification code freeze only critical fixes App Store validation, what's in RC code freeze no new features only critical fixes all budgets met all gates passed App Store Ready verification final TestFlight, entry beta exit passed crash-free >99% no critical bugs feedback triaged, RC rules strict no new features only critical fixes crash/data loss/security/budget fail/App Store rejection docs allowed no refactoring no new UI no non-critical no dep updates unless security, exit must pass all 20+ RC checklist no exception Cold <1.5s Warm <0.6s Search <50ms Library <200ms Queue Instant Seek <50ms Play/Pause Instant+Haptics <10ms Lyrics <50ms Karaoke <100ms Download Enqueue <50ms TasteDNA <200ms Recommendations <100ms Animations <16ms Haptics <10ms Navigation <50ms No crashes 1h 5+ devices Background 1h stable No leaks VoiceOver validation TestFlight 5+ devices Screenshots ready No new features since beta Only critical fixes minimal, verification checklist Instruments Leaks TestFlight validation no new features since beta only critical fixes, next Stable command
- **Stable 5/5:** Official sequence YOU ARE HERE Stable GA DONE! Official Sequence Completed ✅ Dev→Alpha→Beta→RC→Stable, purpose production GA public App Store official sequence completed, entry RC exit all must pass validation screenshots ready no critical bugs crash-free >99.5%, what's in stable full milestones 0.1.0-dev→1.0.0 all 5 pillars budgets gates App Store Ready docs tests build, after stable next cycle v1.1.0-dev.1 patch v1.0.1-dev.1 major v2.0.0-dev.1 commands

**Official Sequence Table in Release Notes:**
- Table with order, channel, tag example, stability, distribution, purpose, prerelease, exit criteria
- Rules: Dev→Alpha no crash 5 tabs basic playback, Alpha→Beta all 5 pillars testable budgets met no critical bugs 30 min stable, Beta→RC real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged, RC→Stable all 20+ RC checklist must pass all validation screenshots code freeze, Stable→Next Dev start next cycle v1.1.0-dev.1 or v1.0.1-dev.1

---

## 📋 Quick Commands — Official Sequence — Copy Paste

**Official Sequence — First Time — 1.0.0 — From Scratch:**

```bash
# === Stage 1/5: Dev — Nightly — Internal ===
git checkout arena/01a0e693-qeloryx
git pull origin arena/01a0e693-qeloryx
git status # clean
./Scripts/bootstrap.sh # verify build ready

git tag -a v1.0.0-dev.1 -m "QELORYX v1.0.0-dev.1 — Dev — Nightly — 1/5 — First dev build — 107 Swift files — All engines — Midnight Aurora"
git push origin v1.0.0-dev.1
# → Actions → release.yml dev 1/5 prerelease true → GitHub Release Dev + Build
# → Test dev checklist 5 min → fix if needed → dev.2, dev.3...

# === Stage 2/5: Alpha — Internal QA ===
# After dev exit pass — no crash 5 tabs basic playback
git tag -a v1.0.0-alpha.1 -m "QELORYX v1.0.0-alpha.1 — Alpha — Internal Testing — 2/5 — Features testable — All 5 pillars — Budgets met — QA"
git push origin v1.0.0-alpha.1
# → Actions → alpha 2/5 prerelease true → Release Alpha + Build
# → Internal QA 30 min 2+ testers → fix → alpha.2...

# === Stage 3/5: Beta — TestFlight External ===
# After alpha exit pass — all 5 pillars testable budgets met no critical bugs 30 min stable
git tag -a v1.0.0-beta.1 -m "QELORYX v1.0.0-beta.1 — Beta — TestFlight — 3/5 — Feature complete — All pillars — Budgets met — External testing"
git push origin v1.0.0-beta.1
# → Actions → beta 3/5 prerelease true → Release Beta + Build
# → App Store Connect → TestFlight → External testers 100-1000 → Feedback 1-2 weeks → fix critical → beta.2...

# === Stage 4/5: RC — Release Candidate — Code Freeze ===
# After beta exit pass — real device 5+ devices 10k tracks 1h background stable crash-free >99% feedback triaged
git tag -a v1.0.0-rc.1 -m "QELORYX v1.0.0-rc.1 — RC — Release Candidate — 4/5 — Code freeze — All gates passed — Final verification"
git push origin v1.0.0-rc.1
# → Actions → rc 4/5 prerelease true → Release RC strict 20+ checklist + Build
# → TestFlight final 5+ devices 1h each, Instruments leaks, App Store validation, screenshots ready → fix only critical minimal → rc.2...

# === Stage 5/5: Stable — GA — App Store ===
# After RC exit pass — all 20+ checklist must pass all validation pass screenshots ready no critical bugs crash-free >99.5%
git tag -a v1.0.0 -m "QELORYX v1.0.0 — Stable — App Store Ready — GA — 5/5 — Hear Beyond. Build Beyond. — All milestones — All budgets — All gates — Official Sequence Completed — Midnight Aurora"
git push origin v1.0.0
# → Actions → stable 5/5 prerelease false → Release Stable GA full notes + Build + Files
# → Xcode archive → App Store Connect → Submit for Review → Public

# === Next Cycle — 1.1.0 ===
git checkout -b arena/1.1.0-dev
# Update project.yml MARKETING_VERSION to 1.1.0
git tag -a v1.1.0-dev.1 -m "QELORYX v1.1.0-dev.1 — Dev — Nightly — 1/5 — Next cycle — New features"
git push origin v1.1.0-dev.1
# → Again Dev → Alpha → Beta → RC → Stable for 1.1.0
```

**Manual Workflow Dispatch Alternative:**

```bash
# GitHub Actions → Release workflow → Run workflow
# Inputs:
# version: 1.0.0-dev.1 (or alpha.1, beta.1, rc.1, 1.0.0)
# channel: dev (or alpha, beta, rc, stable)
# prerelease: auto true for dev/alpha/beta/rc, false for stable
```

---

## 🎯 Current Status — QELORYX 1.0.0 — Official Sequence

**Completed — Code Complete — Build Ready:**
- [x] Foundation 0.1.0-dev — Repository structure, Core skeletons, DesignSystem Midnight Aurora, Platform isolation, Docs, CI, Tests
- [x] Player 0.1.0-alpha.1 QEL-012 — Play/Pause/Seek/Queue/Shuffle/Repeat/Background/Dynamic Island/Lock Screen/AirPlay
- [x] Library 0.2.0-alpha QEL-024 — Multi-library, Album/Artist/Genre/Folder/Favorites/History/Recently Added, Incremental indexing, Artwork cache 500MB LRU, Metadata normalization, Duplicate detection
- [x] Lyrics 0.3.0-alpha QEL-032 — LRC parsing, Synced Lyrics, Karaoke word-level, Translation-ready es/fr/de/ja/ko/zh/bn, Fullscreen
- [x] Downloads 0.4.0-alpha QEL-041 — State machine Queued→Downloading→Paused→Retry→Completed→Failed+Cancelled, Resume resumeData, Retry exponential backoff, Priority Queue, Offline optimization, Background session
- [x] Discovery 0.5.0-alpha QEL-051 — Taste DNA evolving profile, Recommendations offline, Audio Lab EQ+signal path+spectrum+diagnostics, Spaces shared queue+reactions, Dashboard overview, Discovery combined entry
- [x] Polish 0.9.0-beta — Performance monitoring, Launch optimization Cold <1.5s Warm <0.6s, Haptics semantic <10ms pre-warming, Animations 60fps <16ms, Accessibility VoiceOver+Dynamic Type, Theme Midnight Aurora dark-first
- [x] Stable 1.0.0 — Search production <50ms universal, Time Capsule production Today Last Year/Monthly Story/Heatmap, RootView production 5 tabs + Player sheet + Mini Player, Final verification
- [x] Workflows production — ci.yml 7 jobs, build.yml 3 jobs Archive App Store Ready, release.yml 5 channels official sequence Dev→Alpha→Beta→RC→Stable, performance.yml 5 jobs budgets
- [x] Scripts production — bootstrap.sh, lint.sh, generate-docs.sh 1.0.0 Stable
- [x] Docs complete — ADR 12, EPL 8, IL 8, SHM 8 51 research, ACC 1.0.0 Stable, README 1.0.0 Stable, CHANGELOG 1.0.0 Stable, BUILD_READINESS 1.0.0 Stable, RELEASE_FLOW Official Sequence
- [x] Build readiness verified — First build ready — 107 Swift files production — All budgets met — All gates passed — Info.plist MARKETING_VERSION fix

**Next — Official Release Sequence — 1.0.0 — To Do:**

- [ ] **Stage 1/5 Dev — NOW — You asked for dev build release:** `v1.0.0-dev.1` — Nightly internal — 5 min checklist — fix → dev.2 if needed
- [ ] **Stage 2/5 Alpha:** `v1.0.0-alpha.1` — Internal QA — 30 min checklist 2+ testers — fix → alpha.2 if needed
- [ ] **Stage 3/5 Beta:** `v1.0.0-beta.1` — TestFlight external 100-1000 users — 1h per tester real device 5+ devices 10k tracks background 1h crash-free >99% — fix critical → beta.2 if needed
- [ ] **Stage 4/5 RC:** `v1.0.0-rc.1` — Release Candidate code freeze — 20+ checklist must pass all — TestFlight final 5+ devices 1h Instruments leaks validation screenshots — fix only critical minimal → rc.2 if needed
- [ ] **Stage 5/5 Stable:** `v1.0.0` — GA App Store — Public — Official sequence completed ✅

**After Stable — Next Cycle:**

- [ ] `v1.1.0-dev.1` — Next minor — New features — Again Dev→Alpha→Beta→RC→Stable
- [ ] `v1.0.1-dev.1` — Patch if critical fix needed after stable

---

## 📊 Release Artifacts — Per Channel — Official

Each release (dev/alpha/beta/rc/stable) includes:

- **GitHub Release:** Channel-specific notes with official sequence context diagram YOU ARE HERE, entry/exit criteria, checklist, known issues, next command, official sequence table, performance budgets, architecture, docs, tests, build
- **Build:** iOS Release build via xcodebuild CODE_SIGNING_ALLOWED=NO — generic/platform=iOS Release
- **Tests:** CoreTests 11 files + DesignSystemTests — run
- **Files Attached:** ACC.md, README.md, CHANGELOG.md, BUILD_READINESS.md, RELEASE_FLOW.md
- **Tag:** Annotated git tag with detailed message official sequence position
- **Prerelease Flag:** true for dev/alpha/beta/rc, false for stable only
- **Order:** 1/5 Dev, 2/5 Alpha, 3/5 Beta, 4/5 RC, 5/5 Stable

**For Stable Additionally:**
- Xcode archive ready for App Store Connect submission — `build/Qeloryx.xcarchive`
- Full changelog history 0.1.0-dev→1.0.0
- Official sequence completed badge

---

## 🚀 App Store Submission — After Stable — Official GA

```bash
# 1. Generate project
xcodegen generate

# 2. Archive — Stable
xcodebuild archive -project Qeloryx.xcodeproj -scheme Qeloryx -configuration Release -archivePath build/Qeloryx.xcarchive CODE_SIGNING_ALLOWED=NO

# 3. Open archive in Organizer
open build/Qeloryx.xcarchive
# Or: Xcode → Window → Organizer → Archives

# 4. Validate App — Must pass no warnings/errors
# Organizer → Distribute App → App Store Connect → Validate — No warnings/errors required for RC/Stable

# 5. Distribute App → App Store Connect → Upload

# 6. App Store Connect → My Apps → QELORYX → App Store → iOS App → Add build from TestFlight → Screenshots (6.5", 6.7", 5.5", iPad), description, keywords, privacy policy URL, support URL, App Icon 1024x1024, launch screen

# 7. Submit for Review — Official Stable GA

# 8. After approval — Public — Official sequence completed ✅
```

---

## 📚 References — Official Release Sequence Industry Standard

**Industry Standard — 5 Stages:**
- **Apple:** Dev (internal) → Alpha (internal) → Beta (TestFlight) → RC (Release Candidate) → Stable (App Store)
- **Google:** Dev (Canary) → Alpha → Beta → RC → Stable
- **Microsoft:** Dev → Alpha → Beta → RC → GA (General Availability)
- **SemVer:** 1.0.0-dev.1 < 1.0.0-alpha.1 < 1.0.0-alpha.2 < 1.0.0-beta.1 < 1.0.0-rc.1 < 1.0.0 — Official ordering

**QELORYX Official Sequence:**
- **Dev 1/5:** Nightly, internal core team, experimental, fast iteration
- **Alpha 2/5:** Internal QA, features testable but not feature complete, internal QA
- **Beta 3/5:** TestFlight external, feature complete, external feedback, real devices
- **RC 4/5:** Release Candidate, code freeze, only critical fixes, final verification
- **Stable 5/5:** GA, App Store public, production, official sequence completed

**No Skipping:** Must go Dev → Alpha → Beta → RC → Stable — Strict order — Each stage exit criteria must pass before next

---

*QELORYX Official Release Sequence — Dev → Alpha → Beta → RC → Stable — 5 Stages — Industry Standard — 1.0.0 — Hear Beyond. Build Beyond. — Midnight Aurora 🌌 — Qeloryx Labs — Official Implementation*
