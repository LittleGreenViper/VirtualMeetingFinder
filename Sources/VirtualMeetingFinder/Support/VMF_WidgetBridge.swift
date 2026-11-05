// © Copyright 2026, Little Green Viper Software Development LLC. MIT License.

import Foundation
import SwiftBMLSDK
import WidgetKit

/// Publishes app-owned data to the extension without sharing SDK objects or changing
/// the existing preference store. Existing attendance selections migrate on launch.
enum VMF_WidgetBridge {
     private static let queue = DispatchQueue(label: "org.littlegreenviper.VMF.widget-cache", qos: .utility)

     static func preferencesChanged(_ preferences: VMF_Persistent_Prefs) {
          let snapshot = VMF_WidgetPreferences(attendance: Set(preferences.attendance),
                                               excludeServiceMeetings: preferences.excludeServiceMeetings)
          if VMF_WidgetStore.writePreferences(snapshot) {
               WidgetCenter.shared.reloadTimelines(ofKind: VMF_WidgetStore.kind)
          }
     }

     static func publish(_ collection: SwiftBMLSDK_MeetingLocalTimezoneCollection) {
          // An SDK fetch failure also returns an empty collection. Keep the last
          // usable schedule instead of erasing the widget during a network outage.
          guard !collection.meetings.isEmpty else { return }
          let source = collection.meetings.map(\.meeting)
          queue.async {
               let snapshot = snapshot(meetings: source, now: .now)
               if VMF_WidgetStore.writeCache(snapshot) {
                    WidgetCenter.shared.reloadTimelines(ofKind: VMF_WidgetStore.kind)
               }
          }
     }

     /// Exporting absolute SDK results keeps time calculations identical to the app.
     static func snapshot(meetings source: [MeetingInstance], now: Date) -> VMF_WidgetCache {
          let meetings = source.map { meeting -> VMF_WidgetMeeting in
               var spans: [VMF_WidgetSpan] = []
               let previous = meeting.previousOccurrenceDateFast(from: now)
               if previous <= now, now < previous.addingTimeInterval(meeting.duration) {
                    spans.append(VMF_WidgetSpan(start: previous, end: previous.addingTimeInterval(meeting.duration)))
               }
               var reference = now
               // SDK resolves each occurrence independently, so future DST
               // changes are already applied before data leaves this layer.
               for _ in 0..<8 {
                    let start = meeting.nextOccurrenceDateFast(from: reference)
                    if spans.last?.start != start {
                         spans.append(VMF_WidgetSpan(start: start, end: start.addingTimeInterval(meeting.duration)))
                    }
                    reference = start.addingTimeInterval(1)
               }
               return VMF_WidgetMeeting(id: Int(meeting.id), name: meeting.name,
                                        timeZoneIdentifier: meeting.timeZone.identifier,
                                        isServiceMeeting: meeting.isServiceMeeting, spans: spans)
          }
          // Stop before any meeting runs out of future SDK-resolved occurrences.
          return VMF_WidgetCache(meetings: meetings, updatedAt: now,
                                   validUntil: meetings.compactMap { $0.spans.last?.start }.min() ?? now)
     }
}
