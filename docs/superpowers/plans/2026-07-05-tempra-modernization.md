# Tempra 1.1 Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Tempra 1.1 to the App Store: the existing 2014 Objective-C app building with Xcode 26 / iOS 15+, Parse/TestFlight/RBVolume dead code removed, Game Center leaderboard working via modern GameKit APIs.

**Architecture:** Single-target iOS app (`BlindStopwatch.xcodeproj`, target `Tempra`, product `BlindStopwatch`). Nearly all logic in `BlindStopwatch/ViewController.m` (3,354 lines). Changes are surgical deletions of dead code plus literal API replacements — no refactoring.

**Tech Stack:** Objective-C, UIKit, GameKit. No test target exists and none is added: verification is `xcodebuild` success + simulator play-testing + on-device Game Center checks.

## Global Constraints

- Bundle ID stays `com.cwandt.BlindStopwatch`. Target name stays `Tempra`. Product name stays `BlindStopwatch`.
- Marketing version: `1.1`. Build number: `109`.
- Deployment target: `15.0` (all four build configurations).
- Leaderboard IDs stay `global` and `starBank` (existing ASC record).
- Keep API replacements literal — do not change game logic, timing, layout math, or naming. Deprecation *warnings* are acceptable; only fix hard errors.
- Never touch: local persistence (NSUserDefaults keys, `trialData4.dat`, `lastNTrialsData.dat`, `levelData.dat`), gameplay methods, BFPaperButton/Dots/TextArrow/Level/LevelProgressView/MachTimer classes.
- Repo root: `/Users/cwwang/CW&T Dropbox/Che-Wei Wang/My Mac (9.local)/Desktop/Tempra/TemporalDeadReckoning` — all paths below relative to it. NOTE the `&` in the absolute path: always quote shell paths.
- Build command (simulator, no signing):
  `xcodebuild -project BlindStopwatch.xcodeproj -target Tempra -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO`
- Commit after every task with the trailer:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`

---

### Task 1: Strip Parse, TestFlight, and RBVolume from source files

Dead code: Parse (service shut down 2017), TestFlight SDK (dead since 2015), RBVolumeButtons (volume-button hack, already disabled, uses removed MediaPlayer APIs). The app also reads a gitignored `configuration.plist` that doesn't exist — that read goes too.

**Files:**
- Modify: `BlindStopwatch/AppDelegate.h`
- Modify: `BlindStopwatch/AppDelegate.m`
- Modify: `BlindStopwatch/ViewController.h`
- Modify: `BlindStopwatch/ViewController.m`

**Interfaces:**
- Produces: `ViewController` no longer declares `currentUser`, `buttonStealer`, or Parse imports. `logIn` and `deviceName` methods deleted. Task 4 relies on `gameCenterEnabled` property (kept) and methods `authenticateLocalPlayer`, `reportScore`, `showGlobalLeaderboard`, `showSBLeaderboard`, `showAchievements`, `gameCenterViewControllerDidFinish:` (all kept, modernized later).

- [ ] **Step 1: Replace AppDelegate.h entirely**

New full contents of `BlindStopwatch/AppDelegate.h`:

```objc
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
```

- [ ] **Step 2: Clean AppDelegate.m**

Remove line 4 `#import "TestFlight.h"`. Replace the body of `application:didFinishLaunchingWithOptions:` (currently lines 11–49, containing the commented-out window block, `setStatusBarHidden:` — a removed API — the configuration.plist read, Parse init, PFAnalytics/PFUser calls, and TestFlight takeOff) with:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    return YES;
}
```

(Status bar hiding is preserved by `UIStatusBarHidden=true` + `UIViewControllerBasedStatusBarAppearance=false` already in Info.plist.) Leave the five empty lifecycle stubs (lines 54–93) untouched.

- [ ] **Step 3: Clean ViewController.h**

In `BlindStopwatch/ViewController.h`:
1. Delete line 10: `#import <MediaPlayer/MediaPlayer.h>`
2. Delete line 14: `#import <Parse/Parse.h>`
3. Delete line 21: `@class RBVolumeButtons;`
4. Line 23: remove `UIAlertViewDelegate ,` from the protocol list so it reads:
   ```objc
   @interface ViewController : UIViewController <GKGameCenterControllerDelegate, BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate>
   ```
5. Delete line 27: `    PFUser *currentUser;`
6. Delete line 29: `    RBVolumeButtons *_buttonStealer;`
7. Delete line 167: `@property (retain) RBVolumeButtons *buttonStealer;`

Keep `@property BOOL gameCenterEnabled;` and `@property NSString *leaderboardIdentifier;` (Task 4 uses them).

- [ ] **Step 4: Clean ViewController.m**

In `BlindStopwatch/ViewController.m` (line numbers are pre-edit; work bottom-up so they stay valid):

1. **Delete `authenticate`-adjacent Parse method `logIn` (lines 3175–3218) and helper `deviceName` (lines 3219–3226).** Both exist only for Parse. Keep the `#pragma mark - ViewController Delegate` line (3174).
2. **Delete the `logIn` call site** in `viewDidAppear:` — line 3295: `    [self logIn];`
3. **Delete `viewDidUnload`** (lines 3231–3238) — removed lifecycle method; also the only remaining `buttonStealer` runtime reference (line 3234).
4. **Delete the Parse block in `saveTrialData`** — lines 1576–1603 inclusive, i.e. everything from `    //save to parse` through `    [pObject saveEventually];`. The method then flows from `[self saveLevelProgress];` straight to `    //update graph`. (This also removes the Parse-only `uuid` generation.)
5. **Delete line 39:** `@synthesize buttonStealer = _buttonStealer;`
6. **Delete line 8:** `#import <sys/utsname.h> // import it in your header or implementation file.` (only used by the deleted `deviceName`).

- [ ] **Step 5: Verify no dead references remain**

Run:
```bash
grep -n "PFUser\|PFObject\|PFInstallation\|PFAnalytics\|PFAnonymousUtils\|Parse\|TestFlight\|buttonStealer\|RBVolumeButtons\|UIAlertViewDelegate\|logIn\|utsname" BlindStopwatch/*.h BlindStopwatch/*.m
```
Expected: no output (a match on an unrelated word like "parse" in a comment is acceptable — verify each hit is inert).

Do NOT build yet — the project file still links the dead frameworks; that's Task 2.

- [ ] **Step 6: Commit**

```bash
git add BlindStopwatch/AppDelegate.h BlindStopwatch/AppDelegate.m BlindStopwatch/ViewController.h BlindStopwatch/ViewController.m
git commit -m "Strip Parse, TestFlight, and RBVolume dead code from sources"
```

---

### Task 2: Purge dead frameworks from the Xcode project and delete vendor directories

**Files:**
- Modify: `BlindStopwatch.xcodeproj/project.pbxproj`
- Delete: `Parse.framework/`, `Bolts.framework/`, `ParseFacebookUtils.framework/` (repo root), `BlindStopwatch/TestFlightSDK3.0.2/`, `BlindStopwatch/RBVolume/`

**Interfaces:**
- Produces: a project that builds clean for the simulator. All later tasks depend on this build command succeeding:
  `xcodebuild -project BlindStopwatch.xcodeproj -target Tempra -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO`

- [ ] **Step 1: Remove every pbxproj line containing these object IDs**

Each ID below appears in 2–4 places (PBXBuildFile, PBXFileReference, PBXGroup children, PBXFrameworksBuildPhase/PBXSourcesBuildPhase files). Delete **every line** containing each ID. All entries are single-line, so deleting whole lines is safe:

| What | IDs |
|---|---|
| libTestFlight.a | `4436041419E822CE00184D13`, `4436041A19E822CE00184D13` |
| Parse.framework | `44FD6D9719C49A6D006C7099`, `44FD6D9819C49A6D006C7099` |
| Bolts.framework | `44FD6DA719C49BB7006C7099`, `44FD6DA819C49BB7006C7099` |
| ParseFacebookUtils.framework | `44FD6DA919C49C3E006C7099`, `44FD6DAA19C49C3E006C7099` |
| CFNetwork.framework | `44FD6D9919C49A86006C7099`, `44FD6D9A19C49A86006C7099` |
| CoreLocation.framework | `44FD6D9B19C49A8B006C7099`, `44FD6D9C19C49A8B006C7099` |
| libz.dylib | `44FD6D9D19C49A9A006C7099`, `44FD6D9E19C49A9A006C7099` |
| MobileCoreServices.framework | `44FD6D9F19C49A9F006C7099`, `44FD6DA019C49A9F006C7099` |
| Security.framework | `44FD6DA119C49AA7006C7099`, `44FD6DA219C49AA7006C7099` |
| SystemConfiguration.framework | `44FD6DA519C49AB3006C7099`, `44FD6DA619C49AB3006C7099` |
| MediaPlayer.framework | `70C2EB611475FE4900751AE8`, `70C2EB621475FE4900751AE8` |
| RBVolumeButtons.m/.h | `443CA73119C0BFDB003BACD8`, `443CA72F19C0BFDB003BACD8`, `443CA73019C0BFDB003BACD8` |

Keep: GameKit (weak), AVFoundation, AudioToolbox, QuartzCore, UIKit, Foundation, CoreGraphics.

- [ ] **Step 2: Remove the RBVolume group block**

Delete the whole PBXGroup block (pbxproj lines ~172–179 pre-edit):

```
		443CA72E19C0BFDB003BACD8 /* RBVolume */ = {
			isa = PBXGroup;
			children = (
			);
			path = RBVolume;
			sourceTree = "<group>";
		};
```
(The children lines were already removed in Step 1; delete the now-empty block plus the line referencing `443CA72E19C0BFDB003BACD8` in its parent group's children — pre-edit line 255.)

Also grep for any remaining `TestFlight` references:
```bash
grep -n "TestFlight" BlindStopwatch.xcodeproj/project.pbxproj
```
If a `TestFlightSDK3.0.2` PBXGroup block or header file references exist, delete those blocks/lines the same way. Expected after cleanup: no matches except possibly `LIBRARY_SEARCH_PATHS` (next step).

- [ ] **Step 3: Remove TestFlight library search paths**

In both target build configurations (Debug pre-edit lines 493–496, Release 520–523), delete the whole setting:

```
				LIBRARY_SEARCH_PATHS = (
					"$(inherited)",
					"$(PROJECT_DIR)/BlindStopwatch/TestFlightSDK3.0.2",
				);
```

Leave `FRAMEWORK_SEARCH_PATHS` alone (harmless).

- [ ] **Step 4: Validate project file integrity**

```bash
plutil -lint BlindStopwatch.xcodeproj/project.pbxproj
xcodebuild -project BlindStopwatch.xcodeproj -list
```
Expected: `OK` and the target list showing `Tempra`.

- [ ] **Step 5: Delete vendor directories and stale artifacts**

```bash
git rm -r --quiet Parse.framework Bolts.framework ParseFacebookUtils.framework "BlindStopwatch/TestFlightSDK3.0.2" BlindStopwatch/RBVolume BlindStopwatch/BlindStopwatch.ipa
```

- [ ] **Step 6: First build**

```bash
xcodebuild -project BlindStopwatch.xcodeproj -target Tempra -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
```
Expected: `** BUILD SUCCEEDED **`. Deprecation warnings are fine (GKScore etc. — fixed in Task 4).

If there are hard errors from other removed APIs, fix each with the most literal modern equivalent possible (do not restructure), and note what was changed in the commit message. Known-safe leftovers that should NOT error: `statusBarOrientation` in `screenshot` (deprecated, not removed), `shouldAutorotateToInterfaceOrientation:` (inert override).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Remove Parse/TestFlight/RBVolume frameworks and vendor dirs from project"
```

---

### Task 3: Modernize project settings and Info.plist

**Files:**
- Modify: `BlindStopwatch.xcodeproj/project.pbxproj`
- Modify: `BlindStopwatch/BlindStopwatch-Info.plist`

**Interfaces:**
- Produces: deployment target 15.0, automatic signing (team chosen later in Xcode by the user), version 1.1 (109). Task 7 (archive) depends on these.

- [ ] **Step 1: Deployment target and signing in pbxproj**

1. Replace all four occurrences of `IPHONEOS_DEPLOYMENT_TARGET = 7.1;` with `IPHONEOS_DEPLOYMENT_TARGET = 15.0;` (project Debug/Release ~lines 438/469, target Debug/Release ~lines 492/~517).
2. Delete both `PROVISIONING_PROFILE = "...";` lines (project-level Debug/Release).
3. Delete all `CODE_SIGN_IDENTITY` lines (project level: empty + `"iPhone Developer"`; target level: `"iPhone Developer"` Debug, `"iPhone Distribution"` Release — 6 lines total).
4. In both **target-level** build configuration blocks (the ones containing `PRODUCT_NAME = BlindStopwatch;`), add:
   ```
				CODE_SIGN_STYLE = Automatic;
   ```
5. In both target-level blocks, delete:
   ```
				ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME = LaunchImage;
   ```

- [ ] **Step 2: Info.plist updates**

In `BlindStopwatch/BlindStopwatch-Info.plist`:
1. `CFBundleShortVersionString`: `1.02` → `1.1`
2. `CFBundleVersion`: `1.08` → `109`
3. Delete the whole `UIRequiredDeviceCapabilities` key and its array (`armv7` is obsolete; `gamekit` as a hard requirement is deprecated).

Leave everything else (launch/main storyboard = `MainStoryboard` is correct — the file exists at `BlindStopwatch/en.lproj/MainStoryboard.storyboard`).

- [ ] **Step 3: Build**

```bash
xcodebuild -project BlindStopwatch.xcodeproj -target Tempra -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -10
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add BlindStopwatch.xcodeproj/project.pbxproj BlindStopwatch/BlindStopwatch-Info.plist
git commit -m "Modernize build settings: iOS 15 target, automatic signing, v1.1 (109)"
```

---

### Task 4: Modernize Game Center (auth, score submission, leaderboard UI)

`GKScore`, `GKGameCenterViewController.viewState/.leaderboardIdentifier`, and `loadDefaultLeaderboardIdentifierWithCompletionHandler` are deprecated (some removed from modern GameKit). Replace with iOS 14+ APIs, same behavior.

**Files:**
- Modify: `BlindStopwatch/ViewController.m`

**Interfaces:**
- Consumes: `gameCenterEnabled` property (ViewController.h line ~179, kept in Task 1).
- Produces: working score submission to leaderboard IDs `global` and `starBank`; leaderboard UI presentation. `leaderboardIdentifier` property becomes unused by code (leave the declaration; do not remove — minimal churn).

- [ ] **Step 1: Replace `authenticateLocalPlayer` (currently lines ~3322–3350, last method in file)**

New implementation:

```objc
-(void)authenticateLocalPlayer{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];

    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil) {
            [self presentViewController:viewController animated:YES completion:nil];
        }
        else{
            self->_gameCenterEnabled = [GKLocalPlayer localPlayer].isAuthenticated;
        }
    };
}
```

- [ ] **Step 2: Replace `reportScore` (currently lines ~1785–1816)**

New implementation (keep the commented-out experiencepoints block deleted; scores keep their original scaling — `best*10.0` and raw `starBank`):

```objc
-(void)reportScore{
    if(!_gameCenterEnabled) return;

    [GKLeaderboard submitScore:(NSInteger)(best*10.0)
                       context:0
                        player:[GKLocalPlayer localPlayer]
                leaderboardIDs:@[@"global"]
             completionHandler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }];

    [GKLeaderboard submitScore:starBank
                       context:0
                        player:[GKLocalPlayer localPlayer]
                leaderboardIDs:@[@"starBank"]
             completionHandler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}
```

(The old `if(_leaderboardIdentifier)` gate becomes the `_gameCenterEnabled` gate — same effect: skip silently when not authenticated.)

- [ ] **Step 3: Replace the three presentation methods (currently lines ~1844–1864)**

```objc
-(void)showGlobalLeaderboard{
    GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] initWithLeaderboardID:@"global" playerScope:GKLeaderboardPlayerScopeGlobal timeScope:GKLeaderboardTimeScopeAllTime];
    gcViewController.gameCenterDelegate = self;
    [self presentViewController:gcViewController animated:YES completion:nil];
}

-(void)showSBLeaderboard{
    GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] initWithLeaderboardID:@"starBank" playerScope:GKLeaderboardPlayerScopeGlobal timeScope:GKLeaderboardTimeScopeAllTime];
    gcViewController.gameCenterDelegate = self;
    [self presentViewController:gcViewController animated:YES completion:nil];
}
-(void)showAchievements{
    GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] initWithState:GKGameCenterViewControllerStateAchievements];
    gcViewController.gameCenterDelegate = self;
    [self presentViewController:gcViewController animated:YES completion:nil];
}
```

Keep `gameCenterViewControllerDidFinish:` exactly as-is.

- [ ] **Step 4: Build, checking Game Center deprecation warnings are gone**

```bash
xcodebuild -project BlindStopwatch.xcodeproj -target Tempra -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "warning.*GK|error" ; echo "---" ; xcodebuild -project BlindStopwatch.xcodeproj -target Tempra -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3
```
Expected: no GK deprecation warnings, no errors, `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add BlindStopwatch/ViewController.m
git commit -m "Modernize Game Center: GKLeaderboard submitScore, modern GKGameCenterViewController"
```

---

### Task 5: Modern app icon and privacy manifest

**Files:**
- Modify: `BlindStopwatch/Images.xcassets/AppIcon.appiconset/` (rewrite Contents.json, add 1024 icon, delete legacy PNGs)
- Delete: `BlindStopwatch/Images.xcassets/LaunchImage.launchimage/`
- Create: `BlindStopwatch/PrivacyInfo.xcprivacy`
- Modify: `BlindStopwatch.xcodeproj/project.pbxproj` (add privacy manifest to Resources)

**Interfaces:**
- Produces: single-size app icon (Xcode 14+ style) and privacy manifest bundled as a resource. Task 7's archive/upload depends on both.

- [ ] **Step 1: Rebuild AppIcon set as single-size**

```bash
cd "BlindStopwatch/Images.xcassets/AppIcon.appiconset"
cp "iTunesArtwork@2x.png" AppIcon1024.png   # verified 1024x1024
git rm --quiet Icon*.png "iTunesArtwork@2x.png"
```

Then write `Contents.json` in that directory with exactly:

```json
{
  "images" : [
    {
      "filename" : "AppIcon1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Check the icon has no alpha channel (App Store rejects icons with alpha):
```bash
sips -g hasAlpha AppIcon1024.png
```
If `hasAlpha: yes`, flatten it:
```bash
sips -s format jpeg AppIcon1024.png --out tmp.jpg && sips -s format png tmp.jpg --out AppIcon1024.png && rm tmp.jpg
```

- [ ] **Step 2: Delete legacy launch images**

```bash
git rm -r --quiet "BlindStopwatch/Images.xcassets/LaunchImage.launchimage"
```
(The `ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME` setting was removed in Task 3; launch UI comes from `UILaunchStoryboardName` = MainStoryboard.)

- [ ] **Step 3: Create the privacy manifest**

Write `BlindStopwatch/PrivacyInfo.xcprivacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyCollectedDataTypes</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>CA92.1</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

(UserDefaults is the only privacy-listed API the app touches; CA92.1 = app's own data. No tracking, no collected data — Parse is gone.)

- [ ] **Step 4: Add the manifest to the Xcode target's Resources**

In `BlindStopwatch.xcodeproj/project.pbxproj`:

1. In the `PBXBuildFile` section (alphabetical block near the top), add:
```
		44AA100119C4AA0100000001 /* PrivacyInfo.xcprivacy in Resources */ = {isa = PBXBuildFile; fileRef = 44AA100019C4AA0100000000 /* PrivacyInfo.xcprivacy */; };
```
2. In the `PBXFileReference` section, add:
```
		44AA100019C4AA0100000000 /* PrivacyInfo.xcprivacy */ = {isa = PBXFileReference; lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; };
```
3. In the `BlindStopwatch` PBXGroup (the group whose `path = BlindStopwatch;` — it contains `BlindStopwatch-Info.plist`), add to `children`:
```
				44AA100019C4AA0100000000 /* PrivacyInfo.xcprivacy */,
```
4. In the `PBXResourcesBuildPhase` block's `files` list, add:
```
				44AA100119C4AA0100000001 /* PrivacyInfo.xcprivacy in Resources */,
```

- [ ] **Step 5: Build and verify resources**

```bash
plutil -lint BlindStopwatch/PrivacyInfo.xcprivacy
xcodebuild -project BlindStopwatch.xcodeproj -target Tempra -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: `OK`, `** BUILD SUCCEEDED **`. Then confirm both landed in the product:
```bash
ls ~/Library/Developer/Xcode/DerivedData 2>/dev/null >/dev/null; APP=$(find build -name "BlindStopwatch.app" -path "*iphonesimulator*" | head -1); ls "$APP/PrivacyInfo.xcprivacy" && ls "$APP" | grep -i assets
```
Expected: the manifest path prints, and `Assets.car` is present.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Single-size 1024 app icon, drop legacy launch images, add privacy manifest"
```

---

### Task 6: Simulator play-test and modern-screen layout check

The layout is hand-computed from `screenWidth`/`screenHeight` (set from `[UIScreen mainScreen] bounds`), with device-detection macros (`IS_IPHONE_6` etc.) that all miss on modern phones and fall back to iPhone-5-era constants (e.g. `vbuttonY=137` at ViewController.m:56–61). Verify what actually breaks; fix ONLY visible breakage, minimally.

**Files:**
- Possibly modify: `BlindStopwatch/ViewController.m` (targeted layout constants only)

**Interfaces:**
- Consumes: the buildable app from Tasks 1–5.
- Produces: screenshots proving the game plays correctly on a modern iPhone; any layout fix keeps the existing constant-based style (no Auto Layout conversion).

- [ ] **Step 1: Boot a modern iPhone simulator and install**

```bash
xcrun simctl list devices available | grep -i iphone
```
Pick the newest iPhone (call it `DEVICE`). Then:
```bash
xcrun simctl boot "DEVICE"
open -a Simulator
xcodebuild -project BlindStopwatch.xcodeproj -target Tempra -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO
APP=$(find build -name "BlindStopwatch.app" -path "*iphonesimulator*" | head -1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.cwandt.BlindStopwatch
```
Expected: app launches (Game Center auth will log an error in simulator without a signed-in account — that's fine; gameplay must not be blocked).

- [ ] **Step 2: Screenshot the main states**

```bash
sleep 3 && xcrun simctl io booted screenshot /tmp/tempra-01-launch.png
```
Interact via `simctl` is limited — take a launch screenshot, then READ the screenshot image to check: intro/play UI visible, nothing clipped by the notch/Dynamic Island area (status bar is hidden; top content at y≈0 may sit under the island), bottom buttons (trophy/medal row at `screenHeight-66`) not colliding with the home indicator.

- [ ] **Step 3: Judge and fix only real breakage**

- Content merely *near* the island/home-indicator: acceptable, ship it.
- Content *obscured or unusable* (e.g. buttons under the home indicator, labels split by the island): apply the smallest constant fix, using the existing safe-area insets at runtime. Pattern to use if needed (matches existing code style):

```objc
    //modern screens: pad for notch/home indicator
    UIEdgeInsets safe = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;
    buttonYPos = screenHeight - 66 - safe.bottom;
```

- Also relaunch after a play session and confirm progress persisted (the level shown survives relaunch): terminate (`xcrun simctl terminate booted com.cwandt.BlindStopwatch`), relaunch, screenshot, compare.
- Take final screenshots of whatever states are reachable and keep them in `/tmp/` for the user to review; report findings.

- [ ] **Step 4: Commit (only if fixes were made)**

```bash
git add BlindStopwatch/ViewController.m
git commit -m "Safe-area layout fixes for modern iPhones"
```

---

### Task 7: Device test, App Store Connect setup, archive, and submission

This task is user-in-the-loop: signing team selection, ASC verification, and physical-device testing need the user. Coordinate; don't skip checkpoints.

**Files:**
- None modified (except possible team ID in pbxproj chosen by Xcode)

**Interfaces:**
- Consumes: everything above, pushed to GitHub.

- [ ] **Step 1: Push all work to GitHub**

```bash
git push origin master
```
(Confirm branch name with `git branch` first — repo may use `master`.)

- [ ] **Step 2: USER ACTION — signing + device run**

Ask the user to:
1. Open `BlindStopwatch.xcodeproj` in Xcode, select the `Tempra` target → Signing & Capabilities → check "Automatically manage signing", pick their team, and confirm the **Game Center** capability is present (add it if missing — this writes an entitlements file; commit it).
2. Plug in their iPhone, select it as the run destination, and Run.
3. Play a round signed into Game Center, then tap the trophy button (bottom center) — the Game Center leaderboard sheet should open.

- [ ] **Step 3: USER ACTION — App Store Connect verification**

Walk the user through checking at appstoreconnect.apple.com:
1. My Apps → Tempra (existing record for `com.cwandt.BlindStopwatch`) exists and is editable.
2. Services/Features → Game Center: leaderboards `global` and `starBank` exist. If missing, create Classic leaderboards with those exact IDs (score format: integer; `global` sort ascending? — NO: verify against gameplay: `best*10.0` where higher `best` = better, so sort DESCENDING; `starBank` descending too).
3. Create version 1.1 in ASC; attach both leaderboards to the version (Game Center section of the version page).
4. App Privacy: "Data Not Collected" (Parse removed; Game Center is Apple-operated).

If the record or leaderboards are gone, adjust: create new leaderboard IDs and update the two IDs in `reportScore`/`showGlobalLeaderboard`/`showSBLeaderboard` before archiving.

- [ ] **Step 4: Archive and upload**

```bash
xcodebuild -project BlindStopwatch.xcodeproj -scheme BlindStopwatch -destination "generic/platform=iOS" archive -archivePath build/Tempra.xcarchive
```
Then upload — either via Xcode Organizer (user) or:
```bash
xcodebuild -exportArchive -archivePath build/Tempra.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/export
```
with `ExportOptions.plist` containing `method: app-store-connect`, then upload with `xcrun altool`/Transporter per current tooling. If CLI export hits signing friction, fall back to Xcode Organizer → Distribute App (user clicks).

- [ ] **Step 5: TestFlight sanity + submit**

1. Wait for the build to process in ASC; install via TestFlight on the user's phone; confirm launch + leaderboard.
2. User takes/approves screenshots (6.9" and 6.5" iPhone screenshots required for the version page; capture from simulator: `xcrun simctl io booted screenshot`).
3. Fill in "What's New" (e.g. "Tempra is back: rebuilt for modern iPhones. Game Center leaderboards restored."), submit for review.

- [ ] **Step 6: Final commit and push**

```bash
git add -A
git commit -m "Tempra 1.1: entitlements and release artifacts"
git push origin master
```

---

## Self-review notes (spec coverage)

- Strip Parse → Tasks 1–2. TestFlight/RBVolume (discovered during ground-truth pass, same dead-code class) → Tasks 1–2.
- Game Center working (modern auth, submitScore, in-app leaderboard via existing trophy/medal buttons at ViewController.m:221–243) → Task 4. Trophy button already wired to `showGlobalLeaderboard` — no new UI needed.
- 2026 App Store compliance: deployment target/SDK → Task 3; `UIRequiredDeviceCapabilities` → Task 3; privacy manifest → Task 5; icons → Task 5; modern screens → Task 6; version 1.1 → Task 3.
- Info.plist storyboard "mismatch" from spec: resolved as NOT a bug — `MainStoryboard.storyboard` exists in `en.lproj/`. No change made.
- Verify & ship → Tasks 6–7.
- Out of scope respected: no Swift, no refactor, no backend, no new gameplay. iPad: target stays universal (`TARGETED_DEVICE_FAMILY = "1,2"`) because narrowing device support on an existing App Store app is risky; existing `IS_IPAD` branches remain.
