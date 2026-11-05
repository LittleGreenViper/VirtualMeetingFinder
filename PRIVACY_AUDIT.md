# We Are Never Alone privacy audit

Reviewed November 5, 2026. App source: commit `a59441e4c8ad247e99179fd6d121a69e874e232f`, version 2.0.0, build 0003, plus the manifest packaging change described below. The public App Store listing reviewed during this audit shows version 1.4.0; this is a source audit of the next version, not an inspection of Apple's distributed binary.

## Conclusion

The reviewed app and pinned dependencies contain no account system, advertising, tracking, analytics upload, or transmission of attendance preferences or meeting-name searches. Its design minimizes developer access to user information. However, the app **does handle and store user data**: “I Attend” meeting IDs and a filter preference are saved locally, and searches are held in memory. Attendance choices can reveal an interest in recovery meetings even though they contain no name or account identifier.

The App Store's **Data Not Collected** label is consistent with the reviewed client code, subject to verification of production server and hosting logs. Apple excludes processing confined to the device from its collection definition, but includes information sent off the device and retained beyond servicing the request. The owner confirmed that log retention is currently unknown. This audit therefore does not give an unconditional clearance for the label. See [Apple's collection definition and on-device processing guidance](https://developer.apple.com/app-store/app-privacy-details/).

## Findings and actions

| Finding | Significance | Action or status |
| --- | --- | --- |
| App manifest was absent from Copy Bundle Resources | The existing root `PrivacyInfo.xcprivacy` was visible in Xcode but was not included by the app's resource build phase. Dependency manifests do not substitute for the app's declaration. | **Fixed:** added the existing file to the app target's resources and verified the built result. |
| “Stores no user data” is inaccurate | Attendance meeting IDs and the service-meeting filter persist in User Defaults. They are local user data, with potentially sensitive meaning. | Describe local preferences explicitly. No transmission of these values was found. |
| Backup and deletion promises are too broad | The website says selections stay only on the device and disappear when the app is deleted. User Defaults databases can be included in device backups and restored later; deleting the app does not erase previously made backups or calendar exports. | Explain that the app does not provide synchronization, while system backup and restore may retain or transfer preferences. |
| Production request logging is unverified | Meeting downloads necessarily expose the connecting IP address and HTTP request metadata to the endpoint and infrastructure serving it. Retention cannot be established from the app or local PHP code. | **Open:** verify access, error, security, proxy/CDN and hosting logs, their fields, retention, access and use. Include `meetings.recovrr.org` and the `vmf.littlegreenviper.com` shared-link service. |
| External actions are missing from the privacy explanation | Calendar events, map requests, meeting joins, Recovrr links and shares pass selected meeting information to a destination chosen by the user. Calendar entries may sync to the user's calendar service. | Explain these actions and the receiving services' own privacy practices. They do not upload the user's saved attendance list. |

Apple documents that persistent User Defaults databases are included in device backups. Absence of app synchronization is consequently a narrower claim than absence of transfer through backups. See [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults) and [Apple's backup explanation](https://support.apple.com/en-us/108770).

## Data flow inventory

| Feature | Information and storage | Destination or access |
| --- | --- | --- |
| Meeting download | Public virtual and hybrid meeting records are held in the app's in-memory collection. The request uses a fixed virtual/hybrid filter. | HTTPS to `https://meetings.recovrr.org/entrypoint.php`, through SwiftBMLSDK. No attendance list, typed search, account token, app-generated user identifier or device location is added by this flow. The server sees connection/request metadata. |
| Attendance | Array of selected meeting IDs in `UserDefaults.standard`, through RVS_PersistentPrefs, with an on-device App Group file copy for the widget. | App-local preferences; not supplied to the meeting request. Subject to the operating system's storage, backup and restore behavior. |
| Settings | `excludeServiceMeetings` Boolean in the same preferences store and the widget's App Group preference file. | Used locally to filter the downloaded collection and all widget sections. |
| Home Screen widget | Public meeting names, source timezones, service flags, and SDK-resolved start/end intervals are cached in the on-device App Group. Attendance/filter choices are stored in a separate shared file. Files use protection until first unlock. | Shared only between the app and its extension; no new network request or attendance upload. Widget content may be visible on the member's Home Screen. |
| Search, selected day/time and timezone conversion | Search text and navigation state are in memory; the device's timezone and calendar are used locally. | Meeting-name matching occurs against downloaded records, not through server searches. |
| Hybrid meeting map | Public meeting coordinates and map region are passed to MapKit. | Apple map services may receive map requests. No app call to obtain the device's current location was found; the app does not request location permission. |
| Open in Maps | Selected meeting coordinates, plus its name for Apple Maps. | Apple Maps, Google Maps or Waze, on the user's action. The Apple Maps link currently uses `http://maps.apple.com`; prefer HTTPS as a small hardening change. This audit did not establish whether the OS handles that link locally or makes an HTTP request. |
| Add to Calendar | Meeting title, time, recurrence, links, comments and formats are placed in an event editor. | Saved only if the user chooses to save. iOS 17+ requests write-only calendar access; iOS 16 uses the older read/write permission API. No enumeration or upload of existing events was found. Calendar retention and synchronization are independent of deleting this app. |
| Share and open another app | The share sheet receives a public meeting URL and a meeting event. Recovrr receives the selected meeting ID; conferencing apps or browsers receive the selected connection URL and any meeting credentials included in it. Telephone actions open the meeting's dial-in number. | The user-selected destination can handle and retain this information under its own practices. A shared link identifies a meeting, not the sender or their saved attendance list. Link previews or browser fallback can contact the shared-link host. |
| App availability checks | `canOpenURL` checks a declared set of compatible app schemes to decide which controls to display. | Used on the device; no upload of these results was found. |

SwiftBMLSDK uses `URLSessionConfiguration.default` with requests that ignore existing local cache data. That cache policy does not itself disable response caching or cookies. Although no attendance or search data enters the requests, the network layer should not be described as necessarily leaving no persistent cache or cookie data. An ephemeral session with cookies disabled is an optional hardening improvement if persistent network state is unnecessary.

The public directory can itself contain meeting contact names, telephone numbers, addresses and connection credentials. These are handled as meeting content; they are distinct from information collected about the person using the app.

### Source evidence

- `Sources/VirtualMeetingFinder/Support/VMF_Persistent_Prefs.swift`: the two persistent keys, attendance IDs and the filter setting.
- `Sources/VirtualMeetingFinder/Support/VMF_Extensions.swift`: local attendance updates and public meeting links.
- `Sources/VirtualMeetingFinder/MainApp/VMF_AppDelegate.swift` and `Meta/Info.plist` under the same app source directory: server selection and collection loading.
- `Sources/VirtualMeetingFinder/ViewControllers/Screens/MainScreen/VMF_MainViewController_Methods.swift`: local meeting-name filtering.
- `Sources/VirtualMeetingFinder/ViewControllers/Screens/MeetingInspectorScreen/VMF_MeetingInspectorViewController.swift` and `VMF_Activity.swift` in that directory: map regions, event contents, permissions, app links and shares.
- Pinned SwiftBMLSDK `SwiftBMLSDK_Query.swift` and `SwiftBMLSDK_Parser_UI_Extensions.swift`: request configuration and the initial virtual/hybrid query.
- Local `LGV_MeetingServer/Sources/LGV_MeetingServer_Entrypoint.php`: query processing. No visitor-recording implementation was found in the reviewed PHP sources; this does not establish the deployed host's logging configuration.

## Website and nutrition label review

The [public App Store nutrition label](https://apps.apple.com/us/app/we-are-never-alone/id6504826025) says **Data Not Collected**. The [app website privacy section](https://littlegreenviper.com/portfolio/the-virtual-na-meeting-finder-app/#privacy), which is also linked from the app and App Store, says no account is required, no personal information is collected, and attendance selections stay local without synchronization. The website contains privacy prose rather than a separate structured nutrition label. The non-portfolio website address referenced in the README exposes the same privacy wording.

The no-account statement is supported. The lack of app synchronization and attendance uploads is supported. The local-only wording needs the backup qualification above, and the collection statement remains conditional on infrastructure retention. The stronger claim in `README.md` and `PRIVACY.md` that the project collects absolutely no information from anyone at any time should also be narrowed.

Retained IP addresses or request metadata require an assessment of what is actually stored and how it is used. Do not automatically call all logs tracking, and do not automatically exclude security logs from collection. If retained information falls within Apple's disclosure requirements, update both App Store Connect responses and the manifest's collected-data declarations with the appropriate types, purposes, linkage and tracking answers. If metadata is discarded when the request completes, Apple's real-time request exception may apply. Manifest edits do not update the App Store label automatically.

### Proposed public privacy wording

We Are Never Alone requires no account. The app does not upload your “I Attend” selections or meeting-name searches, and contains no advertising or tracking tools.

Your selected meeting IDs and the service-meeting filter setting are saved in local app preferences. The app does not synchronize these preferences between devices. They may be included in your device backups and restored from those backups. Deleting the app removes its current local preferences; it does not delete earlier backups or events you saved to a calendar.

The app downloads public meeting information over HTTPS. The server and services handling the connection receive network information such as your IP address and request metadata. **Before publication, add the verified logging and retention practices here.**

Hybrid meeting maps use Apple map services. When you choose to join, call, share, open another app, or save a calendar event, the selected meeting information is passed to that destination. Calendar entries may synchronize through your calendar provider. Those services apply their own privacy practices.

## Privacy manifest and dependencies

`PrivacyInfo.xcprivacy` declares `NSPrivacyTracking = false`, empty tracking domains and collected-data arrays, and `NSPrivacyAccessedAPICategoryUserDefaults` with reason **CA92.1** for app-local preferences. These declarations reflect the reviewed client implementation; the server verification above remains necessary. Meeting API and shared-link domains are not tracking domains merely because the app uses them.

CA92.1 covers reading and writing defaults accessible only to the app. The app has no App Group entitlement and does not configure a shared defaults suite. No additional required-reason category was identified in the reviewed app source or packaged dependency source. See [Apple's approved reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype) and [manifest packaging requirements](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk).

The Xcode dependency checkouts matched both resolved package files exactly:

| Dependency | Version | Manifest result |
| --- | --- | --- |
| SwiftBMLSDK | 1.5.7 | No collection or tracking declared. |
| PhoneNumberKit | 5.0.13 | No collection or tracking declared; parses public meeting telephone numbers locally. |
| RVS_PersistentPrefs | 1.17.0 | No collection or tracking; declares User Defaults reasons CA92.1 and 1C8F.1. Its shared-group User Defaults capability is not used; the widget shares separate JSON files in an App Group. |
| RVS_BasicGCDTimer | 1.8.0 | No collection or tracking declared. |
| RVS_Checkbox | 3.1.0 | No collection or tracking declared. |
| RVS_Generic_Swift_Toolbox | 1.18.1 | No collection or tracking declared. |
| RVS_UIKit_Toolbox | 1.7.6 | No collection or tracking declared. |

The dependency review covered shipped source, manifests and resource declarations, including network, persistence, identifiers and required-reason API searches. Test harnesses and examples are not part of the shipped targets. No advertising or telemetry SDK was identified. LGV_MeetingServer and its server-side dependencies are not embedded iOS SDKs.

## Verification and remaining limits

- Manifest and Xcode project property-list validation passed, as did `git diff --check`.
- The ordinary app scheme built successfully in **Release** for a generic iOS Simulator with code signing disabled and pinned package resolution enforced.
- The built version 2.0.0 app contains the root manifest plus all seven dependency manifests. Each parsed successfully; none declares collection or tracking. The app's embedded manifest matches the source declaration.
- Production infrastructure logging remains unverified. No full device traffic capture, backup/restore exercise, independent penetration test or signed distribution-archive/App Store validation was performed. Static source findings establish the reviewed implementation, not every behavior of the operating system or external services.

Before release, resolve infrastructure logging, publish the corrected privacy explanation, and review the privacy report from the actual distribution archive. Revisit the declarations when data flows, dependencies or hosting practices change.
