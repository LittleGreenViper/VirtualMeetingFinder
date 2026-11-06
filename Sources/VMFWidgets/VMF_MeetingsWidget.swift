// © Copyright 2026, Little Green Viper Software Development LLC. MIT License.

import SwiftUI
import WidgetKit

struct VMF_WidgetEntry: TimelineEntry {
     let date: Date
     let state: VMF_WidgetState
}

struct VMF_WidgetProvider: TimelineProvider {
     func placeholder(in context: Context) -> VMF_WidgetEntry { Self.preview }

     func getSnapshot(in context: Context, completion: @escaping (VMF_WidgetEntry) -> Void) {
          guard !context.isPreview else {
               completion(Self.preview)
               return
          }
          completion(entries().first!)
     }

     func getTimeline(in context: Context, completion: @escaping (Timeline<VMF_WidgetEntry>) -> Void) {
          let entries = entries()
          completion(Timeline(entries: entries, policy: .after(entries.last!.date.addingTimeInterval(60))))
     }

     private func entries() -> [VMF_WidgetEntry] {
          let now = Date()
          guard let cache = VMF_WidgetStore.readCache(), now < cache.validUntil else {
               return [VMF_WidgetEntry(date: now, state: VMF_WidgetState())]
          }
          let schedule = VMF_WidgetSchedule(meetings: cache.meetings, preferences: VMF_WidgetStore.readPreferences(), now: now)
          return schedule.timelineDates(now: now).map { date in
               let state = date < cache.validUntil ? schedule.state(at: date) : VMF_WidgetState()
               return VMF_WidgetEntry(date: date, state: state)
          }
     }

     /// Gallery data is never written to the shared cache or used for a live widget.
     static var preview: VMF_WidgetEntry {
          let now = Date()
          func occurrence(_ id: Int, _ name: String, _ offset: TimeInterval, zone: String = TimeZone.current.identifier) -> VMF_WidgetOccurrence {
               let start = now.addingTimeInterval(offset)
               let end = start.addingTimeInterval(3600)
               let meeting = VMF_WidgetMeeting(id: id, name: name, timeZoneIdentifier: zone,
                                               isServiceMeeting: false, spans: [VMF_WidgetSpan(start: start, end: end)])
               return VMF_WidgetOccurrence(meeting: meeting, start: start, end: end)
          }
          return VMF_WidgetEntry(date: now, state: VMF_WidgetState(
               attendance: [occurrence(1, "We Are Never Alone", 1800, zone: "America/Los_Angeles"),
                            occurrence(2, "Just for Today", 7200)],
               inProgress: [occurrence(3, "Together We Can", -1800), occurrence(4, "Experience, Strength and Hope", -900)],
               upcoming: [occurrence(5, "A New Way to Live", 900), occurrence(6, "Keep Coming Back", 1800)]))
     }
}

struct VMF_WidgetView: View {
     let entry: VMF_WidgetEntry
     @Environment(\.widgetFamily) private var family
     @Environment(\.widgetRenderingMode) private var renderingMode
     @Environment(\.locale) private var locale
     @ScaledMetric(relativeTo: .caption) private var unit = 12.0

     private var columns: Int { family == .systemExtraLarge ? 2 : 1 }
     private var hasAttendance: Bool { !entry.state.attendance.isEmpty }
     private var headerLogoSize: CGFloat { hasAttendance ? 28 : 44 }

     var body: some View {
          GeometryReader { geometry in
               if family == .systemMedium && !hasAttendance {
                    let size = min(geometry.size.width, geometry.size.height) * 0.55
                    logoLink(size: size, destination: VMF_WidgetStore.openMainScreenURL)
                         .frame(maxWidth: .infinity, maxHeight: .infinity)
               } else {
                    VStack(alignment: .leading, spacing: 8) {
                         header.frame(height: headerLogoSize)
                         if family == .systemMedium, let meeting = entry.state.attendance.first {
                              medium(meeting)
                         } else {
                              meetingLists(height: max(0, geometry.size.height - headerLogoSize - 8))
                         }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
               }
          }
          .containerBackground(for: .widget) {
               Image("BackgroundGradient").resizable()
                    .scaleEffect(x: 1.02, y: 1)
                    .clipped()
          }
          .widgetURL(hasAttendance ? VMF_WidgetStore.openAppURL : VMF_WidgetStore.openMainScreenURL)
     }

     @ViewBuilder private var header: some View {
          if hasAttendance {
               HStack(spacing: 8) {
                    logoLink(size: headerLogoSize, destination: VMF_WidgetStore.openAppURL)
                    Text("WIDGET-APP-NAME")
                         .font(.caption.weight(.semibold))
                         .lineLimit(1)
                         .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
               }
          } else {
               logoLink(size: headerLogoSize, destination: VMF_WidgetStore.openMainScreenURL)
                    .frame(maxWidth: .infinity)
          }
     }

     private func logoLink(size: CGFloat, destination: URL) -> some View {
          Link(destination: destination) {
               splashLogo.scaledToFit().frame(width: size, height: size)
          }
          .accessibilityLabel(Text("WIDGET-OPEN-APP"))
     }

     @ViewBuilder private var splashLogo: some View {
          let logo = Image("SplashLogo").resizable()
          if #available(iOS 18.0, *), renderingMode == .accented {
               logo.widgetAccentedRenderingMode(.accentedDesaturated)
          } else {
               logo
          }
     }

     private func medium(_ meeting: VMF_WidgetOccurrence) -> some View {
          VStack(alignment: .leading, spacing: 3) {
               Text("WIDGET-I-ATTEND").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
               meetingLink(meeting, attendance: true)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
     }

     private func meetingLists(height: Double) -> some View {
          let layout = VMF_WidgetLayout(state: entry.state, height: height, unit: unit, columns: columns)
          return VStack(alignment: .leading, spacing: 0) {
               if !layout.attendance.isEmpty {
                    sectionHeading("WIDGET-I-ATTEND")
                    grid(layout.attendance, height: unit * 6, attendance: true)
               }
               if !layout.inProgress.isEmpty {
                    sectionHeading("WIDGET-IN-PROGRESS")
                    grid(layout.inProgress, height: unit * 3)
               }
               if !layout.upcoming.isEmpty {
                    sectionHeading("WIDGET-UPCOMING")
                    grid(layout.upcoming, height: unit * 3)
               }
               Spacer(minLength: 0)
          }
     }

     private func sectionHeading(_ key: LocalizedStringKey) -> some View {
          Text(key).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
               .frame(maxWidth: .infinity, alignment: .leading)
               .frame(height: unit * 2, alignment: .top)
               .accessibilityAddTraits(.isHeader)
     }

     private func grid(_ meetings: [VMF_WidgetOccurrence], height: Double, attendance: Bool = false) -> some View {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .leading), count: columns),
                    alignment: .leading, spacing: 0) {
               ForEach(meetings) { meeting in
                    meetingLink(meeting, attendance: attendance, height: height)
               }
          }
     }

     private func meetingLink(_ occurrence: VMF_WidgetOccurrence, attendance: Bool, height: Double? = nil) -> some View {
          Link(destination: VMF_MeetingLink.url(for: occurrence.id) ?? VMF_WidgetStore.openAppURL) {
               Group {
                    if attendance { attendanceRow(occurrence) } else { compactRow(occurrence) }
               }
               .frame(maxWidth: .infinity, alignment: .topLeading)
               .frame(height: height.map { CGFloat($0) }, alignment: .top)
               .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityHint(Text("WIDGET-OPEN-MEETING-HINT"))
     }

     private func attendanceRow(_ occurrence: VMF_WidgetOccurrence) -> some View {
          VStack(alignment: .leading, spacing: 2) {
               Text(verbatim: occurrence.meeting.name).font(.subheadline.weight(.semibold)).lineLimit(2)
               Text(VMF_WidgetTime.span(occurrence, relativeTo: entry.date, locale: locale)).font(.caption).lineLimit(1)
               if let native = VMF_WidgetTime.nativeTime(occurrence, locale: locale) {
                    Text(native).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
               }
          }
          .accessibilityElement(children: .combine)
     }

     private func compactRow(_ occurrence: VMF_WidgetOccurrence) -> some View {
          VStack(alignment: .leading, spacing: 1) {
               Text(verbatim: occurrence.meeting.name).font(.caption.weight(.medium)).lineLimit(1)
               Text(VMF_WidgetTime.start(occurrence, relativeTo: entry.date, locale: locale))
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
          }
          .accessibilityElement(children: .combine)
     }
}

@main
struct VMF_MeetingsWidget: Widget {
     var body: some WidgetConfiguration {
          StaticConfiguration(kind: VMF_WidgetStore.kind, provider: VMF_WidgetProvider()) { entry in
               VMF_WidgetView(entry: entry)
          }
          .configurationDisplayName("WIDGET-TITLE")
          .description("WIDGET-DESCRIPTION")
          .supportedFamilies(families)
     }

     private var families: [WidgetFamily] {
          var families: [WidgetFamily] = [.systemMedium, .systemLarge, .systemExtraLarge]
          if #available(iOS 27.0, *) { families.append(.systemExtraLargePortrait) }
          return families
     }
}

#Preview(as: .systemMedium) { VMF_MeetingsWidget() } timeline: { VMF_WidgetProvider.preview }
#Preview(as: .systemLarge) { VMF_MeetingsWidget() } timeline: { VMF_WidgetProvider.preview }
#Preview(as: .systemExtraLarge) { VMF_MeetingsWidget() } timeline: { VMF_WidgetProvider.preview }
