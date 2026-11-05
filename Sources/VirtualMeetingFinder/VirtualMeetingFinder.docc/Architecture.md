# Meeting Data and Navigation

Understand how the app loads meetings, maps local schedules, and coordinates its screens.

## Overview

The storyboard in `Resources/Base.lproj/VMF.storyboard` defines the navigation
stack and most screens. ``VMF_DayTimeSelectionViewController`` builds its popover
in code. ``VMF_BaseViewController`` supplies the storyboard screens with shared
navigation styling, localization of accessibility tokens, and haptics.

### Loading and caching

``VMF_AppDelegate`` reads `VMF_BaseServerURI` from the app's Info.plist and creates
a SwiftBMLSDK query. Its shared `virtualService` holds an in-memory collection of
virtual and hybrid meetings. The fetch has a 30-second timeout. There is no
persistent on-disk meeting cache in this app.

``VMF_MainViewController`` loads the collection when absent or empty and supports
pull-to-refresh outside name search. Its age check uses a four-hour interval
measured from entering the background. The foreground timestamp is set to the
distant future to suppress age-based reloads during continuous use. The age check
runs when the main screen appears; it is not a repeating background fetch.

On foreground entry, ``VMF_SceneDelegate`` refreshes occurrence caches and returns
the main list to Now when no meeting inspector is open. This recomputes local
occurrences using the loaded collection, rather than downloading a fresh list.

### Weekdays, times, and search

Keep three representations distinct:

- A day index is **0** for Now, or **1–7** for Sunday through Saturday.
- A time index is a **zero-based position** in a weekday's sorted, distinct start times.
- An integer start time is **HHMM**, such as `930` for 09:30. It is not a time index.

Foundation supplies local weekday names and time formatting. The base controller
maps Sunday-based weekday values to and from the user's preferred first weekday
for the popover. Meeting occurrence dates determine adjusted local weekdays and
start times; a meeting's source time zone can place it on a different local day.

``VMF_MainViewController`` organizes weekday groups and a name-sorted search set.
The service-meeting setting excludes recognized `ASM` and `SUB-RP` format codes
from those sets. The in-progress list and attendance list are derived separately
from the shared collection. Do not assume that every display uses the same filter.

Name search is a Boolean mode independent of the day index. It uses cached,
normalized names and a similarly normalized query. The underlying weekday/time
selection survives switching to search. Paging is disabled while searching.

### Table ownership and attendance

Both the main and attendance screens conform to
``VMF_MasterTableControllerProtocol``. They provide meetings to an embedded
``VMF_EmbeddedTableController``, which owns the row display and inspector segue.
The main screen also embeds a ``VMF_DayTimeSearchPageViewController`` for paging.

``VMF_Persistent_Prefs`` stores attended meeting IDs and the service-meeting
setting in local user defaults. Meeting helpers access this separate preference
store without changing the SDK record. The attendance list places in-progress
meetings first, then sorts by next occurrence and name.

### Meeting links and external actions

The app generates meeting links using `SLUG-UNIVERSAL-LINK-FORMAT`. The current
format carries a positive meeting ID in the query, for example
`https://vmf.littlegreenviper.com?123`. The scene delegate records that ID and the
embedded table opens the corresponding inspector when the meeting is available
in the loaded collection. This differs from Recovrr's `/meeting/<ID>` path.

The app declares the `lgv-vmf` URL scheme as well. The direct Recovrr button uses
`rcvr://meeting/<ID>` and checks app availability. Its share-sheet Recovrr activity
uses an HTTPS universal link, which can also open a website. Map actions depend
on valid coordinates and app availability. Calendar actions request write-only
event access on iOS 17 and later, then present Apple's editor so the user can
review or cancel the proposed weekly event.
