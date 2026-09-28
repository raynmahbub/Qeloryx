# QELORYX — Release Flow — Dev → Beta → RC → Stable

**Version:** 1.0.0  
**Strategy:** Greenfield — Dev, Beta, RC, Stable channels  
**Theme:** Midnight Aurora  
**Tagline:** Hear Beyond. Build Beyond.

---

## 🎯 Overview — 4 Channel Release Flow

```
Dev (internal) → Beta (TestFlight) → RC (final verification) → Stable (App Store)
v1.0.0-dev.1   → v1.0.0-beta.1    → v1.0.0-rc.1             → v1.0.0
```

**Philosophy:**
- **Dev:** Fast iteration, internal team only, debug logs, may break
- **Beta:** Feature complete, external testers, feedback collection
- **RC:** Code freeze, only critical fixes, final verification
- **Stable:** Production, App Store public, all gates passed

---

## 📦 Versioning — SemVer with Channel

**Format:** `MAJOR.MINOR.PATCH-CHANNEL.NUMBER`

- **MAJOR:** Breaking changes
- **MINOR:** New features backward compatible
- **PATCH:** Bug fixes
- **CHANNEL:** dev / beta / rc / (empty for stable)
- **NUMBER:** Iteration within channel

**Examples:**
- `v1.0.0-dev.1` — First dev build of 1.0.0
- `v1.0.0-dev.2` — Second dev build, fixes from dev.1 feedback
- `v1.0.0-beta.1` — First beta, feature complete
- `v1.0.0-beta.2` — Second beta, beta feedback fixes
- `v1.0.0-rc.1` — Release candidate 1, code freeze
- `v1.0.0-rc.2` — RC2, only critical fix from rc.1
- `v1.0.0` — Stable App Store release
- `v1.1.0-dev.1` — Next minor dev cycle
- `v1.0.1-dev.1` — Patch dev cycle

**Current Cycle — 1.0.0:**
```
1.0.0-dev.1 → 1.0.0-dev.2 (if needed) → 1.0.0-beta.1 → 1.0.0-beta.2 (if needed) → 1.0.0-rc.1 → 1.0.0-rc.2 (if needed) → 1.0.0 Stable
```

---

## 🚧 Channel 1: Dev — Internal Testing

**Tag:** `v1.0.0-dev.1`, `v1.0.0-dev.2`, etc  
**GitHub Release:** Prerelease = true  
**Name:** `QELORYX 1.0.0-dev.1 — Dev — Internal Testing`  
**Distribution:** Internal — Direct install, not TestFlight  
**Stability:** Experimental

**Purpose:**
- Core team internal testing
- Fast iteration
- Latest commits from `arena/01a0e693-qeloryx`
- Debug logs enabled
- Performance monitoring active

**When to Release Dev:**
- After major feature complete (Player, Library, etc done)
- Before beta, to catch obvious crashes internally
- After fixing dev feedback, new dev iteration

**Dev Checklist — Must Pass Before Beta:**
- [ ] App launches without crash
- [ ] Cold Launch <1.5s, Warm <0.6s
- [ ] 5 tabs navigate without crash
- [ ] Search <50ms
- [ ] Library open <200ms with 1000 tracks
- [ ] Play/Pause/Seek/Queue work
- [ ] No memory leak in 10 min use
- [ ] All 107 Swift files compile
- [ ] Tests pass

**How to Release Dev:**

```bash
# 1. Ensure arena branch is up to date and pushed
git checkout arena/01a0e693-qeloryx
git pull origin arena/01a0e693-qeloryx

# 2. Tag dev build
git tag -a v1.0.0-dev.1 -m "QELORYX v1.0.0-dev.1 — Dev — Internal Testing — First dev build — All engines production — Performance budgets check"

# 3. Push tag — triggers release.yml → prerelease GitHub Release + build
git push origin v1.0.0-dev.1

# 4. Check GitHub Actions → release.yml → 3 jobs: detect-channel, create-release (prerelease true), build-for-release

# 5. Download artifact from Actions or Release page, install on device, test dev checklist

# 6. If issues found, fix on arena branch, commit, push, then:
git tag -a v1.0.0-dev.2 -m "QELORYX v1.0.0-dev.2 — Dev — Fixes from dev.1 feedback — Library crash fix — Search debounce fix"
git push origin v1.0.0-dev.2
```

**Dev Release Notes Auto Generated:**
- Dev purpose, stability, distribution
- What's in dev, checklist, known issues, next beta

---

## 🧪 Channel 2: Beta — TestFlight External Testing

**Tag:** `v1.0.0-beta.1`, `v1.0.0-beta.2`, etc  
**GitHub Release:** Prerelease = true  
**Name:** `QELORYX 1.0.0-beta.1 — Beta — TestFlight Ready`  
**Distribution:** TestFlight — External + Internal testers  
**Stability:** Beta — Feature complete

**Purpose:**
- Feature complete 1.0.0
- External beta testing via TestFlight
- Real device testing, large libraries, feedback collection
- Crash reporting

**When to Release Beta:**
- After dev checklist passes
- All 5 pillars production complete
- Performance budgets all met
- Ready for external eyes

**Beta Checklist — Focus Areas:**
- [ ] Real device iPhone 12-15, iOS 17+
- [ ] Library scanning 10k+ tracks
- [ ] Background playback 1 hour stable
- [ ] Artwork cache 500MB LRU eviction works
- [ ] Download resume after network loss
- [ ] Lyrics sync accuracy
- [ ] Taste DNA recommendations quality
- [ ] Accessibility VoiceOver + Dynamic Type
- [ ] Haptics all interactions
- [ ] Dark mode Midnight Aurora theme
- [ ] No crash in 1 hour continuous use

**How to Release Beta:**

```bash
# 1. After dev OK, checkout arena, ensure all fixes committed
git checkout arena/01a0e693-qeloryx
git log --oneline -5

# 2. Tag beta
git tag -a v1.0.0-beta.1 -m "QELORYX v1.0.0-beta.1 — Beta — TestFlight Ready — Feature complete 1.0.0 — All pillars production — Performance budgets met — Ready for external testing"

# 3. Push tag
git push origin v1.0.0-beta.1

# 4. GitHub Actions → release.yml creates prerelease Beta with TestFlight notes + build

# 5. Upload to App Store Connect → TestFlight → Add external testers → Collect feedback

# 6. Fix beta feedback on arena branch, then:
git tag -a v1.0.0-beta.2 -m "QELORYX v1.0.0-beta.2 — Beta — Fixes from beta.1 feedback — Background playback fix — Artwork cache fix"
git push origin v1.0.0-beta.2
```

**Beta Release Notes Auto Generated:**
- Beta purpose, stability, TestFlight distribution
- What's in beta, testing focus, feedback instructions, next RC

---

## 🎯 Channel 3: RC — Release Candidate — Final Verification

**Tag:** `v1.0.0-rc.1`, `v1.0.0-rc.2`, etc  
**GitHub Release:** Prerelease = true (but close to stable)  
**Name:** `QELORYX 1.0.0-rc.1 — RC — Release Candidate`  
**Distribution:** TestFlight — Final verification  
**Stability:** RC — Stable, code freeze

**Purpose:**
- Code freeze — No new features
- Only critical bug fixes
- Final verification before App Store
- All quality gates must pass

**When to Release RC:**
- After beta feedback fixes, no major issues
- All performance budgets met
- All tests pass
- Ready for App Store submission but need final verification

**RC Rules — Strict:**
- ❌ No new features
- ✅ Only critical bug fixes (crash, data loss, performance budget fail)
- ✅ Only performance fixes if budget fails
- ✅ Docs updates allowed
- ❌ No refactoring, no new UI

**RC Checklist — Must Pass All — No Exception:**
- [ ] Build passes 107 Swift files production
- [ ] Tests pass CoreTests + DesignSystemTests
- [ ] Cold Launch <1.5s
- [ ] Warm Launch <0.6s
- [ ] Search <50ms
- [ ] Library Open <200ms
- [ ] Queue Instant <10ms
- [ ] Seek <50ms
- [ ] Play/Pause Instant + Haptics <10ms
- [ ] Lyrics Sync <50ms
- [ ] Karaoke <100ms
- [ ] Download Enqueue <50ms
- [ ] Taste DNA Gen <200ms
- [ ] Recommendations <100ms
- [ ] Animations <16ms 60fps
- [ ] Haptics <10ms
- [ ] Navigation <50ms
- [ ] No crashes in 1 hour continuous use
- [ ] Background playback 1 hour stable
- [ ] No memory leaks
- [ ] Accessibility VoiceOver pass
- [ ] App Store Connect validation pass (no warnings)
- [ ] TestFlight final build tested on 3+ devices

**How to Release RC:**

```bash
# 1. After beta OK, code freeze on arena
git checkout arena/01a0e693-qeloryx

# 2. Tag RC
git tag -a v1.0.0-rc.1 -m "QELORYX v1.0.0-rc.1 — RC — Release Candidate — Code freeze — All budgets met — All gates passed — Final verification before App Store"

# 3. Push tag
git push origin v1.0.0-rc.1

# 4. GitHub Actions → release.yml creates prerelease RC with strict checklist + build

# 5. TestFlight final verification, App Store Connect validation

# 6. If critical bug found, fix ONLY that bug, minimal change, then:
git tag -a v1.0.0-rc.2 -m "QELORYX v1.0.0-rc.2 — RC — Critical fix from rc.1 — Background playback crash fix — No new features — Minimal change"
git push origin v1.0.0-rc.2

# 7. If no critical bugs, proceed to Stable
```

**RC Release Notes Auto Generated:**
- RC purpose, stability, code freeze rules
- Full verification checklist 20+ items must pass all, RC rules, next stable

---

## 🎉 Channel 4: Stable — App Store Production

**Tag:** `v1.0.0`, `v1.1.0`, etc (no channel suffix)  
**GitHub Release:** Prerelease = false  
**Name:** `QELORYX 1.0.0 — Hear Beyond. Build Beyond. — Stable`  
**Distribution:** App Store — Public  
**Stability:** Stable — Production ready

**Purpose:**
- Production App Store release
- Public distribution
- All verifications passed
- All quality gates passed

**When to Release Stable:**
- After RC verification passes all checklist, no critical bugs
- App Store Connect validation passes
- Ready for public

**Stable Checklist — Final:**
- [ ] RC checklist all passed
- [ ] App Store Connect validation no warnings/errors
- [ ] Screenshots, description, keywords ready
- [ ] Privacy policy, support URL ready
- [ ] App Icon, launch screen ready
- [ ] All docs complete ADR 12 EPL 8 IL 8 SHM 8 ACC 1.0.0 Stable README CHANGELOG BUILD_READINESS RELEASE_FLOW

**How to Release Stable:**

```bash
# 1. After RC OK, final check
git checkout arena/01a0e693-qeloryx
git log --oneline -10

# 2. Tag Stable — no suffix, prerelease false
git tag -a v1.0.0 -m "QELORYX v1.0.0 — Stable — App Store Ready — Hear Beyond. Build Beyond. — All milestones completed — 107 Swift files production — All budgets met — All gates passed — Midnight Aurora"

# 3. Push tag — triggers release.yml → stable GitHub Release prerelease false + build
git push origin v1.0.0

# 4. GitHub Actions → release.yml creates Stable release with full notes + build + artifacts

# 5. Xcode Archive → App Store Connect → Submit for Review
xcodegen generate
xcodebuild archive -project Qeloryx.xcodeproj -scheme Qeloryx -configuration Release -archivePath build/Qeloryx.xcarchive CODE_SIGNING_ALLOWED=NO
# Open Organizer → Distribute App → App Store Connect

# 6. After stable released, start next cycle:
git checkout -b arena/1.1.0-dev
# Update project.yml MARKETING_VERSION to 1.1.0
# Then dev cycle again:
git tag -a v1.1.0-dev.1 -m "QELORYX v1.1.0-dev.1 — Dev — Next cycle — New features"
git push origin v1.1.0-dev.1
```

**Stable Release Notes Auto Generated:**
- Full milestones history 0.1.0-dev → 1.0.0 Stable
- Performance budgets table all met
- Architecture 107 files layers DesignSystem tech stack quality gates greenfield 5 pillars
- Docs complete, tests all pass, build App Store Ready, future expansion

---

## 🔄 Workflow — How release.yml Handles Channels

**File:** `.github/workflows/release.yml`

**Trigger:** tags `v*`, `v*-dev*`, `v*-beta*`, `v*-rc*`, `1.0.0`, `1.0.*`, `1.*.*` + workflow_dispatch with version+channel inputs

**Jobs:**
1. **detect-channel:** Auto-detect channel from tag
   - `v1.0.0-dev.1` → channel dev, prerelease true, name "Dev — Internal Testing"
   - `v1.0.0-beta.1` → channel beta, prerelease true, name "Beta — TestFlight Ready"
   - `v1.0.0-rc.1` → channel rc, prerelease true, name "RC — Release Candidate"
   - `v1.0.0` → channel stable, prerelease false, name "Stable"

2. **create-release:** Generate channel-specific release notes + create GitHub Release via `softprops/action-gh-release@v1` with `prerelease` flag + files ACC, README, CHANGELOG, BUILD_READINESS

3. **build-for-release:** Setup Xcode 15.4, install xcodegen/swiftlint, lint, generate project, build Release generic/platform=iOS, run tests

4. **notify-channel:** Echo next steps based on channel

**Release Notes Generation:**
- Dev: internal testing checklist, known issues, next beta
- Beta: TestFlight focus, feedback instructions, next RC
- RC: strict verification checklist 20+ items must pass all, RC rules, next stable
- Stable: full milestones, budgets, architecture, docs, tests, build

---

## 📋 Quick Commands — Copy Paste

**Dev Release Now — First Dev Build:**

```bash
# From arena/01a0e693-qeloryx branch, after verifying build readiness
git checkout arena/01a0e693-qeloryx
git pull origin arena/01a0e693-qeloryx
git status

# Tag dev
git tag -a v1.0.0-dev.1 -m "QELORYX v1.0.0-dev.1 — Dev — Internal Testing — First dev build — 107 Swift files production — All engines — Performance budgets check — Midnight Aurora"

# Push tag — triggers release workflow
git push origin v1.0.0-dev.1

# Watch GitHub Actions
# https://github.com/raynmahbub/Qeloryx/actions

# After dev testing OK → Beta
git tag -a v1.0.0-beta.1 -m "QELORYX v1.0.0-beta.1 — Beta — TestFlight Ready — Feature complete — All pillars — Budgets met"
git push origin v1.0.0-beta.1

# After beta feedback fixes → RC
git tag -a v1.0.0-rc.1 -m "QELORYX v1.0.0-rc.1 — RC — Release Candidate — Code freeze — All gates passed — Final verification"
git push origin v1.0.0-rc.1

# After RC verification → Stable
git tag -a v1.0.0 -m "QELORYX v1.0.0 — Stable — App Store Ready — Hear Beyond. Build Beyond. — All milestones — All budgets — All gates — Midnight Aurora"
git push origin v1.0.0
```

**Manual Workflow Dispatch (alternative to tag push):**

```bash
# Go to GitHub Actions → Release workflow → Run workflow
# Inputs:
# version: 1.0.0-dev.1
# channel: dev
# prerelease: true (auto true for dev/beta/rc, false for stable)
```

---

## 🎯 Current Status — 1.0.0 Cycle

**Completed:**
- [x] Foundation 0.1.0-dev
- [x] Player 0.1.0-alpha.1 QEL-012
- [x] Library 0.2.0-alpha QEL-024
- [x] Lyrics 0.3.0-alpha QEL-032
- [x] Downloads 0.4.0-alpha QEL-041
- [x] Discovery 0.5.0-alpha QEL-051
- [x] Polish 0.9.0-beta
- [x] Stable 1.0.0 — App Store Ready code complete
- [x] Workflows ci.yml build.yml release.yml performance.yml production
- [x] Scripts bootstrap/lint/generate-docs 1.0.0 Stable
- [x] Docs ADR 12 EPL 8 IL 8 SHM 8 ACC 1.0.0 Stable README CHANGELOG BUILD_READINESS
- [x] Build readiness verified — First build ready

**Next — Release Flow:**
- [ ] **NOW:** Dev release `v1.0.0-dev.1` — Internal testing (you asked for this)
- [ ] Beta release `v1.0.0-beta.1` — TestFlight external
- [ ] RC release `v1.0.0-rc.1` — Final verification code freeze
- [ ] Stable release `v1.0.0` — App Store public

**After Stable:**
- [ ] Start next cycle `v1.1.0-dev.1` — New features

---

## 📊 Release Artifacts

Each release (dev/beta/rc/stable) includes:

- **GitHub Release:** With channel-specific notes, auto generated release notes
- **Build:** iOS Release build via xcodebuild CODE_SIGNING_ALLOWED=NO
- **Tests:** CoreTests + DesignSystemTests run
- **Files:** ACC.md, README.md, CHANGELOG.md, BUILD_READINESS.md attached
- **Tag:** Git tag with annotated message

**For Stable additionally:**
- Xcode archive ready for App Store Connect submission
- Full changelog history

---

## 🚀 App Store Submission — After Stable Tag

```bash
# 1. Generate project
xcodegen generate

# 2. Archive
xcodebuild archive -project Qeloryx.xcodeproj -scheme Qeloryx -configuration Release -archivePath build/Qeloryx.xcarchive CODE_SIGNING_ALLOWED=NO

# 3. Open Xcode Organizer
open build/Qeloryx.xcarchive

# 4. Distribute App → App Store Connect → Upload

# 5. App Store Connect → TestFlight → Add to App Store submission → Submit for Review
```

---

*QELORYX Release Flow — Dev → Beta → RC → Stable — 1.0.0 — Hear Beyond. Build Beyond. — Midnight Aurora 🌌 — Qeloryx Labs*
