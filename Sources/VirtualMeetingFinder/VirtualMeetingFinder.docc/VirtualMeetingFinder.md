# ``We_Are_Never_Alone``

@Metadata {
    @DisplayName("We Are Never Alone")
    @TitleHeading("App")
    @PageImage(purpose: icon, source: "icon.png", alt: "We Are Never Alone app icon")
}

Discover and attend virtual and hybrid Narcotics Anonymous meetings in your local time zone.

## Overview

![We Are Never Alone app icon](icon.png)

**Version 2.0.0** brings a worldwide meeting directory to iPhone, iPad, and
compatible Macs running the iPhone/iPad app. Find a meeting in progress, browse
by day and time, search meeting names, and save the meetings you attend.

This version introduces refreshed app and splash artwork, light and dark
backgrounds, a day/time and search popover, and Home Screen widgets. Greek and
Latin American Spanish join the existing translations, with terminology aligned
with Recovrr.

[Download the free app from the App Store](https://apps.apple.com/us/app/we-are-never-alone/id6504826025).

The UIKit app downloads virtual and hybrid meetings from
[LGV_MeetingServer](https://github.com/LittleGreenViper/LGV_MeetingServer) through
[SwiftBMLSDK](https://github.com/LittleGreenViper/SwiftBMLSDK). Start and end times
are converted to the member's current time zone. The app loads the directory
when needed at startup, checks for a refresh after four hours away, and supports
pull-to-refresh outside name search.

This catalog explains the app's behavior and implementation. Begin with the
overview below, then use the contributor guides and symbol reference in Topics
to explore the code.

### Find a meeting

![Meetings in progress in version 2.0.0](fig01.png)

The main screen starts with meetings in progress. Select the **Day and time**
navigation title to open a popover containing weekday selection, a scrolling list
of available start times and meeting counts, **Now**, and meeting-name search.
Weekdays follow the user's calendar order. Selecting a time shows those meetings
and closes the popover.

Search filters the main table as the query changes. **Show results**, the keyboard's
Search key, or dismissing the popover leaves the results visible. Reopening the
popover retains the query. Search ignores case, accents, character width, and
equivalent Latin glyphs such as ligatures.

![Day and time popover in dark appearance](fig02.png)

Outside search, swiping the meeting list moves through adjacent start times,
skipping empty days and wrapping the week. The first forward swipe from Now selects
the first available start after the current local time. The first backward swipe
selects the latest available start at or before now.

### Inspect and join

![Meeting inspector in dark appearance](fig04.png)

Select a meeting to inspect its schedule, joining options, formats, and any
in-person location. Supported meeting apps appear when the app can open them;
web and phone options depend on the meeting's supplied connection details.

Expand formats to learn about the meeting or expand a hybrid meeting's location
to see its in-person details. Local schedules include source time-zone
information when it differs from the member's time zone.

The inspector's share sheet can share the meeting link, prepare a weekly
calendar event in Apple's editor for review, or open available map apps. The
separate **Open in Recovrr** button appears when Recovrr can be opened.

### Keep your attendance list

![My Attendance in light appearance](fig03.png)

**I attend** saves a meeting ID locally. The main screen's attendance button opens
the saved list when it is nonempty. Meetings in progress appear first, followed
by the next upcoming occurrences. Attendance selections also supply the widget
and do not synchronize between devices.

### Add a Home Screen widget

![Large Meetings widget in light appearance](fig07.png)

Add **Meetings** from the We Are Never Alone widget gallery. Medium shows the next
meeting marked **I attend**, including one already in progress. Large and
extra-large sizes show attended meetings first, then meetings in progress and
upcoming meetings when space permits. Extra-large sizes depend on device and OS
support. The widget shares the app's splash artwork and light and dark gradients.

Tap a meeting to open its inspector, whether the app is already open or starts
from the widget. Links wait for the initial download when necessary. With no
attendance selections, medium shows a centered splash logo; larger sizes show
that logo above in-progress and upcoming meetings. Tap the centered logo to open
the main meeting screen.

Widget times follow the member's current time zone and locale. Attended meetings
include a start–end span and, when different, the source time zone and native
start time. The service-meeting filter applies to every widget section, and a
meeting already shown under attendance is not repeated in another section.

The app publishes an on-device meeting snapshot and preference copies through
the App Group `group.org.littlegreenviper.VMF`. SwiftBMLSDK resolves eight upcoming
occurrences per meeting, including daylight saving changes, before exporting
absolute dates. The widget selects and formats those dates without its own
meeting requests or recurrence calculations. Opening or refreshing the app
renews the schedule; attendance and filter changes request a widget update.
WidgetKit controls update timing. Before the first download or after the cached
schedule expires, the widget shows its centered icon.

### Settings and About

![Settings in light appearance](fig05.png)

Settings controls whether recognized service meetings are hidden from weekday and
name-search results. The widget also honors this preference.

![About this app in dark appearance](fig06.png)

About provides the installed app version and build, publisher information,
privacy, source, and dependency links. Its icon changes with light and dark
appearance.

### Languages and accessibility

The app and widget support English, French, German, Greek, Italian, Brazilian
Portuguese, Spanish (Spain), and Latin American Spanish. Foundation supplies
localized weekdays, date and time formatting, and calendar order. Meeting names
remain in their source language.

VoiceOver labels and hints describe navigation, joining controls, disclosure
state, and attendance. Meeting rows expose a custom attendance action as well as
the action that opens the inspector. See <doc:AccessibilityAndLocalization> for
translation conventions and review guidance.

### Privacy

The app collects no personal information. Attendance and settings stay on the
device in User Defaults, with local copies in the App Group for the widget.
Attendance does not synchronize between devices. The meeting directory is
downloaded by the app; the widget reads its on-device snapshot.

Read the [privacy policy](https://littlegreenviper.com/the-virtual-na-meeting-finder-app#privacy).

### Build and contribute

Open `VirtualMeetingFinder.xcodeproj` or `VirtualMeetingFinder.xcworkspace` in
Xcode, allow Swift packages to resolve, and select **We Are Never Alone** with an
iOS simulator. Choose **Product > Build Documentation** to build this catalog.
The app target includes internal symbols so contributors can explore controllers
and support types without changing their access levels.

For device signing and widget support, enable App Groups on **We Are Never Alone**
and **VMFWidgets** with `group.org.littlegreenviper.VMF`. Both entitlement files
already declare the group; the signing team must register it and include it in
both provisioning profiles. The app embeds the extension automatically. Keep
their version and build numbers in sync.

Use <doc:BuildingDocumentation> for command-line builds and the dedicated
screenshot scheme. Use <doc:Architecture> for data loading, local schedules,
screen coordination, widget snapshots, and meeting links. Widget regression
tests run in the regular scheme's Test action and cover filtering, priorities,
meeting boundaries, localization, and SDK date export across daylight saving
changes and midnight.

The app uses SwiftBMLSDK, PhoneNumberKit, RVS_BasicGCDTimer, RVS_Checkbox,
RVS_Generic_Swift_Toolbox, RVS_PersistentPrefs, and RVS_UIKit_Toolbox. Its meeting
service uses LGV_MeetingServer, LGV_TZ_Lookup, and the Basic Meeting List Toolbox.

We Are Never Alone is an MIT-licensed project from
[Little Green Viper Software Development LLC](https://littlegreenviper.com).
See the [source repository](https://github.com/LittleGreenViper/VirtualMeetingFinder)
for the README, version history, license, and dependencies, or visit the
[app website](https://littlegreenviper.com/the-virtual-na-meeting-finder-app/)
for more information.

## Topics

### Contributor Guides

- <doc:Architecture>
- <doc:BuildingDocumentation>
- <doc:AccessibilityAndLocalization>

### App Lifecycle and Data

- ``VMF_AppDelegate``
- ``VMF_SceneDelegate``
- ``VMF_Persistent_Prefs``
- ``MeetingInstance``

### Widget Data and Meeting Links

- ``VMF_WidgetBridge``
- ``VMF_MeetingLink``

### Meeting Screens

- ``VMF_MainViewController``
- ``VMF_DayTimeSelectionViewController``
- ``VMF_DayTimeSearchPageViewController``
- ``VMF_AttendanceViewController``
- ``VMF_MeetingInspectorViewController``
- ``VMF_SettingsViewController``
- ``VMF_AboutViewController``

### Shared Views and Coordination

- ``VMF_BaseViewController``
- ``VMF_BaseProtocol``
- ``VMF_MasterTableControllerProtocol``
- ``VMF_EmbeddedTableControllerProtocol``
- ``VMF_EmbeddedTableController``
- ``VMF_TableCell``
- ``VMF_ActionView``
- ``VMF_ActionStackView``
- ``VMF_URLButton``
- ``VMF_RecovrrButton``
- ``VMF_DisappearingBarButton``
- ``VMF_StyledSegmentedControl``
- ``VMF_DayTimePopoverBackgroundView``
- ``VMF_MapAnnotation``
- ``VMF_MapMarker``

### Share-Sheet Activities

- ``VMF_Base_Activity``
- ``VMF_AddToCalendar_Activity``
- ``VMF_OpenLocationIn_Activity``
- ``VMF_OpenInRecovrr_Activity``
