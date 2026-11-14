// © Copyright 2026, Little Green Viper Software Development LLC. MIT License.

import Foundation

/// Widget links use the app's registered scheme, so opening a meeting never needs
/// a browser or a network round trip through the universal-link website.
enum VMF_MeetingLink {
     static func url(for meetingID: Int) -> URL? {
          guard meetingID > 0 else { return nil }
          return URL(string: "lgv-vmf://meeting?\(meetingID)")
     }

     /// Also accepts the existing public meeting links shared by the app.
     static func meetingID(in url: URL) -> Int? {
          let scheme = url.scheme?.lowercased()
          let host = url.host?.lowercased()
          guard scheme == "lgv-vmf" || ((scheme == "https" || scheme == "http") && host == "vmf.littlegreenviper.com"),
                let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.query,
                let id = Int(query), id > 0 else { return nil }
          return id
     }
}

/// Absolute intervals calculated by SwiftBMLSDK in the app, including DST.
struct VMF_WidgetSpan: Codable, Equatable {
     let start: Date
     let end: Date
}

/// The small, Foundation-only contract shared by the app and its widget extension.
/// The widget never reconstructs a weekly schedule or applies a timezone offset.
struct VMF_WidgetMeeting: Codable, Equatable, Identifiable {
     let id: Int
     let name: String
     let timeZoneIdentifier: String
     let isServiceMeeting: Bool
     let spans: [VMF_WidgetSpan]

     var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .gmt }
}

struct VMF_WidgetPreferences: Codable, Equatable {
     var attendance: Set<Int> = []
     var excludeServiceMeetings = true
}

struct VMF_WidgetCache: Codable {
     let meetings: [VMF_WidgetMeeting]
     let updatedAt: Date
     let validUntil: Date
}

/// App-owned preferences and meeting data have separate files so a preference change
/// never needs to rewrite the entire meeting collection. Atomic writes protect readers.
enum VMF_WidgetStore {
     static let groupID = "group.org.littlegreenviper.VMF"
     static let kind = "VMF_MeetingsWidget"
     static let openAppURL = URL(string: "lgv-vmf://open")!
     static let openMainScreenURL = URL(string: "lgv-vmf://main")!

     private static func file(_ name: String) -> URL? {
          FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?
               .appendingPathComponent(name)
     }

     static func readCache() -> VMF_WidgetCache? { read("widget-meetings.json") }
     static func readPreferences() -> VMF_WidgetPreferences { read("widget-preferences.json") ?? VMF_WidgetPreferences() }

     @discardableResult static func writeCache(_ cache: VMF_WidgetCache) -> Bool { write(cache, to: "widget-meetings.json") }
     @discardableResult static func writePreferences(_ preferences: VMF_WidgetPreferences) -> Bool { write(preferences, to: "widget-preferences.json") }

     private static func read<T: Decodable>(_ name: String) -> T? {
          guard let url = file(name), let data = try? Data(contentsOf: url) else { return nil }
          return try? JSONDecoder().decode(T.self, from: data)
     }

     private static func write<T: Encodable>(_ value: T, to name: String) -> Bool {
          guard let url = file(name), let data = try? JSONEncoder().encode(value) else { return false }
          do {
               try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
               return true
          } catch {
               return false
          }
     }
}

struct VMF_WidgetOccurrence: Identifiable {
     let meeting: VMF_WidgetMeeting
     let start: Date
     let end: Date
     var id: Int { meeting.id }
     func isInProgress(at date: Date) -> Bool { start <= date && date < end }
}

struct VMF_WidgetState {
     var attendance: [VMF_WidgetOccurrence] = []
     var inProgress: [VMF_WidgetOccurrence] = []
     var upcoming: [VMF_WidgetOccurrence] = []
}

/// Fits complete rows in priority order. Extra-wide widgets use two columns.
/// Attendance comes first while reserving at least one row for live meetings.
struct VMF_WidgetLayout {
     var attendance: [VMF_WidgetOccurrence] = []
     var inProgress: [VMF_WidgetOccurrence] = []
     var upcoming: [VMF_WidgetOccurrence] = []

     init(state: VMF_WidgetState, height: Double, unit: Double, columns: Int, onlyAttendance: Bool = false) {
          let heading = unit * 2
          let attendanceHeight = unit * 6
          let compactHeight = unit * 3
          // An empty attendance list always falls back to the normal meeting lists.
          if onlyAttendance, !state.attendance.isEmpty {
               let rows = max(0, Int((height - heading) / attendanceHeight))
               attendance = Array(state.attendance.prefix(rows * columns))
               return
          }
          var remaining = height
          if !state.attendance.isEmpty {
               let liveReservation = state.inProgress.isEmpty ? 0 : heading + compactHeight
               let rows = max(1, min(3, Int((height - heading - liveReservation) / attendanceHeight)))
               attendance = Array(state.attendance.prefix(rows * columns))
               let attendanceRows = (attendance.count + columns - 1) / columns
               remaining -= heading + Double(attendanceRows) * attendanceHeight
          }
          let shown = Set(attendance.map(\.id))
          let active = state.inProgress.filter { !shown.contains($0.id) }
          let activeRows = max(0, Int((remaining - heading) / compactHeight))
          inProgress = Array(active.prefix(activeRows * columns))
          if !inProgress.isEmpty {
               remaining -= heading + Double((inProgress.count + columns - 1) / columns) * compactHeight
          }
          // Only add upcoming rows once all the in-progress candidates fit.
          if inProgress.count == active.count {
               let upcomingRows = max(0, Int((remaining - heading) / compactHeight))
               upcoming = Array(state.upcoming.filter { !shown.contains($0.id) }.prefix(upcomingRows * columns))
          }
     }
}

/// Selects from the SDK-resolved intervals. No recurrence or offset math runs here.
struct VMF_WidgetSchedule {
     let occurrences: [VMF_WidgetOccurrence]
     let preferences: VMF_WidgetPreferences

     init(meetings: [VMF_WidgetMeeting], preferences: VMF_WidgetPreferences, now: Date) {
          self.preferences = preferences
          occurrences = meetings.filter { !preferences.excludeServiceMeetings || !$0.isServiceMeeting }.flatMap { meeting -> [VMF_WidgetOccurrence] in
               // Only the current/next occurrence and its successor can affect this
               // four-hour timeline. Avoid expanding the whole eight-week cache.
               meeting.spans.filter { $0.end > now || $0.start >= now }.prefix(2).map {
                    VMF_WidgetOccurrence(meeting: meeting, start: $0.start, end: $0.end)
               }
          }.sorted {
               if $0.start != $1.start { return $0.start < $1.start }
               let leftOffset = $0.meeting.timeZone.secondsFromGMT(for: $0.start)
               let rightOffset = $1.meeting.timeZone.secondsFromGMT(for: $1.start)
               if leftOffset != rightOffset { return leftOffset < rightOffset }
               let order = $0.meeting.name.localizedCaseInsensitiveCompare($1.meeting.name)
               return order == .orderedSame ? $0.id < $1.id : order == .orderedAscending
          }
     }

     func state(at date: Date) -> VMF_WidgetState {
          var state = VMF_WidgetState()
          var seenAttendance = Set<Int>()
          var seenUpcoming = Set<Int>()
          for occurrence in occurrences {
               let active = occurrence.isInProgress(at: date)
               guard active || occurrence.start >= date else { continue }
               if preferences.attendance.contains(occurrence.id), seenAttendance.insert(occurrence.id).inserted, state.attendance.count < 12 {
                    state.attendance.append(occurrence)
               }
               if active, state.inProgress.count < 24 { state.inProgress.append(occurrence) }
               if active { seenUpcoming.insert(occurrence.id) }
               if !active, seenUpcoming.insert(occurrence.id).inserted, state.upcoming.count < 24 { state.upcoming.append(occurrence) }
          }
          return state
     }

     /// Meeting boundaries advance the display without running the app or a timer.
     /// Quarter-hour entries also keep local day/time presentation current.
     func timelineDates(now: Date) -> [Date] {
          let horizon = now.addingTimeInterval(4 * 3600)
          var dates: Set<Date> = [now, horizon]
          for occurrence in occurrences {
               for date in [occurrence.start, occurrence.end] where now < date && date < horizon { dates.insert(date) }
          }
          for interval in 1..<16 { dates.insert(now.addingTimeInterval(TimeInterval(interval * 900))) }
          return Array(dates.sorted().prefix(64))
     }
}

/// Locale-aware formatting of absolute instants. Native-zone context is only added
/// for attended meetings whose scheduled zone differs from the member's current zone.
enum VMF_WidgetTime {
     static func start(_ occurrence: VMF_WidgetOccurrence, relativeTo date: Date, timeZone: TimeZone = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> String {
          var calendar = Calendar.autoupdatingCurrent
          calendar.timeZone = timeZone
          let formatter = DateFormatter()
          formatter.locale = locale
          formatter.timeZone = timeZone
          formatter.setLocalizedDateFormatFromTemplate(calendar.isDate(occurrence.start, inSameDayAs: date) ? "jm" : "EEEjm")
          return formatter.string(from: occurrence.start)
     }

     static func span(_ occurrence: VMF_WidgetOccurrence, relativeTo date: Date, timeZone: TimeZone = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> String {
          let formatter = DateFormatter()
          formatter.locale = locale
          formatter.timeZone = timeZone
          formatter.timeStyle = .short
          return start(occurrence, relativeTo: date, timeZone: timeZone, locale: locale) + " – " + formatter.string(from: occurrence.end)
     }

     static func nativeTime(_ occurrence: VMF_WidgetOccurrence, timeZone: TimeZone = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> String? {
          let native = occurrence.meeting.timeZone
          guard native.identifier != timeZone.identifier else { return nil }
          let formatter = DateFormatter()
          formatter.locale = locale
          formatter.timeZone = native
          formatter.timeStyle = .short
          let style: TimeZone.NameStyle = native.isDaylightSavingTime(for: occurrence.start) ? .shortDaylightSaving : .shortStandard
          let name = native.localizedName(for: style, locale: locale) ?? native.identifier
          return name + " (" + formatter.string(from: occurrence.start) + ")"
     }
}
