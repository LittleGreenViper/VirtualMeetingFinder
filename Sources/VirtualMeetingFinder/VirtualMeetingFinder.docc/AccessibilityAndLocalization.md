# Accessibility and Localization

Maintain useful spoken controls and consistent translations across the supported languages.

## Overview

The app supports English, German, Greek, Spanish, Latin American Spanish, French,
Italian, and Brazilian Portuguese. Labels, hints, alerts, and interface text live
in each language's `Resources/<language>.lproj/Localizable.strings`.

### Spoken interaction

Give every app-owned action a concise label and a hint describing its result.
Use button traits for tappable views and expose state separately. A control must
also respond to accessibility activation; labeling a gesture-only view is
insufficient. ``VMF_ActionView`` and ``VMF_ActionStackView`` route that activation
to the inspector's existing actions. The settings checkbox and attendance button
use their native control actions.

``VMF_TableCell`` is one accessibility element containing the meeting name,
schedule, source time-zone information when different, in-progress status, and
attendance state. Normal activation opens the inspector. Its custom attendance
action changes attendance without opening the inspector. Decorative checkmarks
are not separate focus stops.

The day/time popover speaks full weekday names even when visible segment titles
are abbreviated. Time rows include the localized meeting count and selected
trait. Its weekday heading offers a custom action to select the latest available
start at or before now, matching the heading's sighted double-tap shortcut.
The standard accessibility escape gesture dismisses the popover.

Inspector disclosure controls announce expanded or collapsed state and the
effect of activation. Text fields and labels with generic spoken names must
retain their actual content in the spoken value. About links announce their
titles, including the logo-only publisher link, and explain that they open a
website. System-owned alerts, share-sheet items, calendar controls, and map
navigation retain UIKit, EventKitUI, and MapKit's accessibility behavior.

### String lookup and cleanup

The app's `String.localizedVariant` accessor uses RVS_Generic_Swift_Toolbox's
Accessibility, Errors, and Localizable lookup, then falls back to the shared
`Resources/NonLocalized.strings` table. Product names, URLs, and universal-link
formats belong in that nonlocalized table. Identical visual and spoken phrases
share a key when they have the same meaning.

SwiftBMLSDK supplies the six `SLUG-DIRECT-URI-*` app-name keys dynamically.
They are required even without literal references in app source. Keep them in
the shared table. Check Swift source, storyboard values and accessibility
attributes, Info.plist, and dependency-provided keys before deleting a string.

`InfoPlist.strings` remains separate: the system reads the app display name and
calendar permission prompts from it. Preserve format placeholders and their
types, including `%@` and the meeting-ID `%lu`. Foundation supplies weekday names;
avoid translations that attach language-specific plural endings to them.

### Review after an interface change

1. Build the app and DocC catalog, and check app-source diagnostics.
2. Check that all eight Localizable tables have the same keys, no duplicates,
   matching format placeholders, and no overlap with NonLocalized.
3. With VoiceOver enabled on a simulator or device, traverse each screen in order.
   Check the navigation title, all weekday segments, time rows, search field and
   results button, meeting rows and their custom actions, attendance, settings,
   disclosures, joining controls, map, About links, and back navigation.
4. Verify actual meeting names, times, connection details, and addresses are spoken;
   toggle state must remain accurate after activation. Confirm hidden sections
   are absent from navigation and focus remains useful after search or disclosure.
5. Repeat key flows with a non-English language and an accessibility text size.
   Assess spoken clarity on real hardware before release.
