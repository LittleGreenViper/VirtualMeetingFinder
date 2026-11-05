# We Are Never Alone

An app that makes it simple to discover and attend virtual (and hybrid) NA meetings.

## Overview

![Icon](icon.png)

This app works by downloading a large list of virtual (and hybrid) meetings from a worldwide database, then presents them to the user, in a form that is directly useful to the user.

### Get the application, itself

|The app is available for free, from the iOS/iPadOS/MacOS Apple App Store|
|:-:|
|[![Apple App Store Badge](img/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg)](https://apps.apple.com/us/app/we-are-never-alone/id6504826025)|

## Usage

This app connects to an instance of [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer), and downloads the entire dataset for all meetings that have a virtual component (Either full virtual, or hybrid Virtual/in-Person). It either does this, when starting "cold," after 4 hours have passed, or at the user's behest (by doing a "pull-to refresh" on the table).

It then converts meeting start and end times to the user's current timezone. Select the weekday and time in the navigation bar to open the day/time popover. Choose a weekday to see its available meeting start times, then tap a time to display those meetings and close the popover. The time list scrolls when needed. **Now** shows meetings in progress, and the search button opens the meeting-name field inside the popover and filters the main table as you type. Select **Show results**, use the keyboard’s Search key, or dismiss the popover to view the results; reopening it preserves your query. Search ignores case, accents, character-width differences, and equivalent Latin glyphs such as ligatures.

Each meeting can be inspected individually, in order to see things like formats, in-person addresses, and virtual URLs. Also, if the user has an app installed (for example, [Zoom](https://zoom.us)), and the meeting has a join URL, the app will translate it to that app's URL scheme, and open the app directly (without having to go through Safari).

Users can select a meeting as one they attend, which allows those meetings to be grouped into a separate screen.

### Home Screen widget

Add **Meetings** from the We Are Never Alone widget gallery. Medium shows the next meeting marked **I attend**, including a meeting already in progress, or an empty-attendance message. Large and extra-large show attended meetings first, then meetings in progress, followed by upcoming meetings when space permits. Extra-large sizes are offered where the device and OS support them. The icon follows light, dark, and tinted appearances; tapping it opens the app normally.

Tap an attended, in-progress, or upcoming meeting to open its inspector directly in the app. This works on startup and when the app is already open on another screen. Links wait for the initial meeting download when needed. The icon and unused widget background continue to open the app normally.

All primary times use the member's current timezone and locale. Attended meetings include a start–end span and, when their timezone differs, the source timezone and native start time. The widget honors the service-meeting filter and avoids repeating displayed attended meetings in the other sections.

The app publishes its downloaded meeting collection and preferences to an on-device App Group. SwiftBMLSDK resolves eight upcoming occurrences per meeting, including DST, before dates reach the widget. The widget selects and formats these absolute dates; it does not calculate recurrences, apply offsets, or make its own meeting requests. Opening or refreshing the app renews the schedule; attendance and filter changes request a widget update. WidgetKit controls update timing. Before the first download, or when the cached dates run out, the widget asks the member to open the app.

For device signing, enable the **App Groups** capability on both **We Are Never Alone** and **VMFWidgets**, using `group.org.littlegreenviper.VMF`. Both entitlement files already declare this group; the signing team must register it and include it in both provisioning profiles. The app target embeds the extension automatically. Keep the two targets' version/build numbers in sync, and update the widget's icon image sets when replacing the app icon artwork.

Widget regression tests are included in the regular scheme's Test action. They cover service filtering, list priority, meeting boundaries, local formatting, and SDK date export across DST and midnight.

## The Specifics

### The Screens

#### The Main Screen

The navigation title shows the selected weekday and time, or the current search/Now mode. Its popover contains the weekday selector, the available start times, Now, and search. Weekdays follow the user's local calendar order. Swiping the meeting list still moves between time slots. From Now, the first swipe opens the latest available start at or before the current local time. Further swipes move through adjacent start times, skipping days without meetings.

#### The Attendance Screen

![Attendance Screen](img/fig03.png)

If the user has selected one or more meetings as ones they attend, a bar button enables in the Main Screen, allowing the user to bring in another screen, with just the meetings they marked as ones they attend.

#### The Meeting Inspector Screen

![Meeting Inspector Screen](img/fig04.png)

If the user selects a single meeting from the list, another screen is brought in, that displays specific and detailed information about that meeting.

#### The Settings Screen

![Settings Screen](img/fig05.png)

This is a screen that is brought in from the Main Screen, that allows the user to specify various settings.

#### The About This App Screen

![About Screen](img/fig06.png)

This is another screen that is brought in from the Settings Screen, that has information about the app, such as its specific version, and links to dependencies.

## Screenshots

Select the **We Are Never Alone (For Screenshots)** scheme and an iPhone or iPad simulator. Its Screenshots configuration displays the supported virtual-meeting app control for the meeting's connection URL, even when that app is not installed, and displays Open in Recovrr. These controls are for screenshot presentation; the simulator does not gain cameras or installed apps.

Archiving is disabled in the scheme, and a build guard rejects archive/install actions using the Screenshots configuration. Regular Debug and Release builds retain their normal availability checks.

## Localization

The app supports English, German, Greek, Spanish, Latin American Spanish, French, Italian, and Brazilian Portuguese. App text, alerts, and VoiceOver labels and hints share `Localizable.strings` in each language’s resource folder. The app’s `String.localizedVariant` accessor uses RVS_Generic_Swift_Toolbox to check Accessibility, Errors, and Localizable, then falls back to the shared NonLocalized table.

`Resources/NonLocalized.strings` holds shared product names, URLs, and universal-link formats in one nonlocalized resource. This includes the six `SLUG-DIRECT-URI-*` app-name keys supplied dynamically by SwiftBMLSDK; retain these even though they have no literal callers in app source. Callers use `String.localizedVariant` for both shared values and translated text, without choosing a table. Keep this table out of the language-specific folders and translation work.

`InfoPlist.strings` remains separate because iOS reads the app display name and calendar permission prompts from that table. Use plain language consistent with Recovrr and local NA terminology. Preserve format placeholders, product names, and URLs. Weekday names are supplied by Foundation; avoid adding language-specific plural endings to them.

The widget uses `Sources/VMFWidgets/Localizable.xcstrings` and `InfoPlist.xcstrings` for the same eight languages, including its header, gallery description, empty/refresh messages, accessibility hints, and extension display name. Attendance and in-progress labels match the app's terminology. Meeting names remain in their source language; dates and timezone names use the widget's current locale. Regression tests check every compiled widget translation and compare its app name and attendance label with the corresponding app localization.

## Building Documentation

Select the **We Are Never Alone** scheme and an iOS simulator in Xcode, then choose **Product > Build Documentation**. The app target includes internal symbols so the catalog covers its controllers and support types. The catalog contains guides to architecture, documentation builds, accessibility, and localization.

For a command-line build from the repository root:

```sh
xcodebuild docbuild -project VirtualMeetingFinder.xcodeproj \
  -scheme 'We Are Never Alone' -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/VMFDocumentation CODE_SIGNING_ALLOWED=NO
```

Open `/tmp/VMFDocumentation/Build/Products/Debug-iphonesimulator/We Are Never Alone.doccarchive` in Xcode. The older generated site in `docs/` is separate from this DocC output.

## Dependencies

- [`RVS_BasicGCDTimer`](https://github.com/RiftValleySoftware/RVS_BasicGCDTimer)

- [`RVS_Generic_Swift_Toolbox`](https://github.com/RiftValleySoftware/RVS_Generic_Swift_Toolbox)

- [`RVS_PersistentPrefs`](https://github.com/RiftValleySoftware/RVS_PersistentPrefs)

- [`RVS_UIKit_Toolbox`](https://github.com/RiftValleySoftware/RVS_UIKit_Toolbox)

- [`SwiftBMLSDK`](https://github.com/LittleGreenViper/SwiftBMLSDK)

- [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer)

- [`LGV_TZ_Lookup`](https://github.com/LittleGreenViper/LGV_TZ_Lookup)

- [The Basic Meeting List Toolbox (BMLT)](https://bmlt.app)

## More Information

- [This is a page with a much more detailed explanation of the app.](https://littlegreenviper.com/the-virtual-na-meeting-finder-app/)

- [This is the internal Technical Documentation for the Project](https://littlegreenviper.github.io/VirtualMeetingFinder/)

## Privacy

[The Privacy Policy](https://littlegreenviper.com/the-virtual-na-meeting-finder-app#privacy)

This project collects **absolutely no information at all**, from anyone, at any time.

The "I Attend" data is kept local, on your device, using [User Defaults](https://developer.apple.com/documentation/foundation/userdefaults) (which means that deleting the app, also deletes this information, and it will not sync to your other devices).

## Source Code

[The GitHub Repository with the Source Code for This App](https://github.com/LittleGreenViper/VirtualMeetingFinder)

## Presented By

[![LGV Icon](LGV.png)](https://littlegreenviper.com)

[Little Green Viper Software Development LLC](https://littlegreenviper.com)

## License

MIT License
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

