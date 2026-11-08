# ``We_Are_Never_Alone``

Discover and attend virtual and hybrid Narcotics Anonymous meetings in your local time zone.

## Overview

![We Are Never Alone app icon](icon.png)

We Are Never Alone is a UIKit app for iPhone, iPad, and Mac Catalyst. It downloads
meetings with a virtual component through SwiftBMLSDK and presents their schedules
in the user's current time zone. This catalog documents the app's implementation
for contributors; it is not a standalone SDK.

### Find a meeting

The main screen starts with meetings in progress. Select the **Day and time**
navigation title to open a popover containing weekday selection, a scrolling list
of available start times and meeting counts, **Now**, and meeting-name search.
Weekdays follow the user's calendar order. Selecting a time shows those meetings
and closes the popover.

Search filters the main table as the query changes. **Show results**, the keyboard's
Search key, or dismissing the popover leaves the results visible. Reopening the
popover retains the query. Search ignores case, accents, character width, and
equivalent Latin glyphs such as ligatures.

Outside search, swiping the meeting list moves through adjacent start times,
skipping empty days and wrapping the week. The first forward swipe from Now selects
the first available start after the current local time. The first backward swipe
selects the latest available start at or before now.

### Inspect and save

Select a meeting to inspect its schedule, joining options, formats, and any
in-person location. Supported meeting apps appear when the app can open them;
web and phone options depend on the meeting's supplied connection details.

**I attend** saves a meeting ID locally. The main screen's attendance button opens
the saved list when it is nonempty. These selections do not synchronize between
devices. The inspector's share sheet can share the meeting link, prepare a weekly
calendar event for review, or open available map apps. The separate **Open in
Recovrr** button appears when Recovrr can be opened.

Settings controls whether recognized service meetings are hidden from weekday and
name-search results. About provides the app version, privacy information, source,
and dependency links.

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
