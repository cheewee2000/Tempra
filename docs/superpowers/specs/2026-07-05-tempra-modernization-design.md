# Tempra 1.1 — Modernization & App Store Update Design

**Date:** 2026-07-05
**Repo:** https://github.com/cheewee2000/TemporalDeadReckoning
**App:** Tempra (Xcode project "BlindStopwatch", bundle ID `com.cwandt.BlindStopwatch`)

## Goal

Ship an update to the existing Tempra App Store listing: built with Xcode 26 /
current iOS SDK, dead Parse dependency removed, Game Center leaderboard
actually working, gameplay code otherwise untouched.

## Context

- The app is a blind time-estimation game ("temporal dead reckoning"),
  written in 2014-era Objective-C. Nearly all logic lives in
  `BlindStopwatch/ViewController.m` (3,354 lines).
- It bundles Parse.framework (service shut down 2017) for results upload,
  anonymous users, analytics, and push installations — all dead code.
- It reports scores via the long-deprecated `GKScore` API to Game Center
  leaderboards `global` and `starBank`.
- Previously published on the App Store as "Tempra" (marketing version 1.02,
  build 1.08 in repo; repo last touched May 2015). The app was 32-bit era
  (`armv7`) and was presumably delisted in Apple's 32-bit purge; the App
  Store Connect record is expected to still exist.
- The user has an active paid Apple Developer Program membership.

## Decisions (from brainstorming)

1. **Keep Objective-C, minimal fixes.** No Swift rewrite. Fix only what is
   required to compile, pass review, and work on modern devices. Keep API
   replacements as literal as possible so game feel/timing doesn't change.
2. **Strip Parse entirely.** No replacement backend. Results and progress
   remain in existing local storage.
3. **Game Center must work.** Modernize authentication and score reporting;
   leaderboard is the app's social feature.
4. **Distribution: public App Store release** (v1.1 update to the existing
   record).

## Design

### 1. Strip Parse

- Delete `Parse.framework`, `Bolts.framework`, `ParseFacebookUtils.framework`
  directories from the repo; remove their references and Parse-only linked
  frameworks (CoreLocation, CFNetwork, etc. — verify each is otherwise
  unused) from the Xcode project.
- Remove Parse code paths:
  - `AppDelegate.m`: Parse initialization, `PFAnalytics`, `PFUser`
    run-counter.
  - `ViewController.m`: results upload (`PFObject` class `results`),
    anonymous-user login, `PFInstallation` push setup.
  - Remove Parse/Facebook imports in headers.
- Where surrounding logic expects these calls, replace with no-ops rather
  than restructuring. Local persistence is untouched.

### 2. Game Center modernization

- Replace `GKScore` reporting with `GKLeaderboard submitScore:...` (iOS 14+
  API), keeping the same leaderboard IDs (`global`, `starBank`) if they
  still exist on the ASC record; otherwise create new IDs and update the
  code to match.
- Add proper `GKLocalPlayer.authenticateHandler` authentication at launch
  (modern flow, presents Apple's sign-in UI when needed).
- Present the leaderboard in-app via `GKGameCenterViewController`, wired to
  the existing leaderboard/trophy UI element if one exists (wireframes
  include `trophy.png`); otherwise add a minimal button consistent with the
  existing UI style.
- App Store Connect (user-driven, with exact steps provided): verify Game
  Center is enabled on the app record and the leaderboards exist and are
  attached to the new version.

### 3. App Store compliance (2026)

- Deployment target iOS 15+; build with the current SDK in Xcode 26.6.
- Fix `UIRequiredDeviceCapabilities` (remove `armv7`; reconsider `gamekit`).
- Add privacy manifest (`PrivacyInfo.xcprivacy`). With Parse gone the app
  collects nothing itself; Game Center data handling is Apple's. App
  Privacy questionnaire answered accordingly in ASC.
- App icon: full modern asset-catalog icon set including the 1024pt
  marketing icon, regenerated from existing art.
- Modern screen support: verify layout on notch/Dynamic Island devices in
  the simulator; make targeted safe-area fixes only where actually broken.
  Status bar is hidden by design — keep.
- Fix Info.plist inconsistency: it references `MainStoryboard` for both
  launch and main storyboard, but the repo contains only
  `Launch.storyboard` and `ViewController.xib`. Point launch/main UI at the
  files that actually exist.
- Version: marketing version **1.1**, fresh build number.
- Fix whatever compile errors surface from SDK drift. Deprecation warnings
  are left alone; only removed APIs get literal, minimal replacements.

### 4. Verification & shipping

- Build and play-test in the iOS Simulator: start a trial, get a result,
  progress persists across relaunch, leaderboard UI opens.
- Test on the user's iPhone via Xcode (automatic signing with their team).
- Game Center end-to-end check on device: authentication, score submission,
  leaderboard shows the score.
- Archive → upload to App Store Connect → TestFlight sanity check →
  submit for review with updated screenshots.
- Commit and push to the existing GitHub repo throughout.

## Error handling

- Game Center unavailable/not signed in: app plays normally; score
  submission is skipped silently (same graceful-degradation behavior as the
  old code).
- If ASC leaderboards were deleted with the old app: create new leaderboard
  IDs, update the two submission call sites and the leaderboard viewer.

## Out of scope

- Any backend/data collection (Parse replacement).
- Swift rewrite or refactoring of ViewController.m.
- New gameplay features.
- iPad-specific layout work (app is iPhone, portrait only).

## Risks

- 3,354-line ViewController.m may use removed APIs (old MediaPlayer,
  UIAlertView-era patterns); fixes kept literal and minimal.
- ASC record state (delisted app, leaderboard survival) unverified until we
  look; fallback documented above.
- 2014 hand-laid frames may misbehave on modern aspect ratios; fix only
  what's visibly broken.
