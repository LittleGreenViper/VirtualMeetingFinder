// © Copyright 2026, Little Green Viper Software Development LLC. MIT License.

import XCTest
import UIKit
@testable import SwiftBMLSDK
@testable import We_Are_Never_Alone

final class VMFWidgetTests: XCTestCase {
     private let now = ISO8601DateFormatter().date(from: "2026-11-05T17:00:00Z")!

     private func meeting(_ id: Int, offset: TimeInterval = 0, service: Bool = false, duration: TimeInterval = 3600) -> VMF_WidgetMeeting {
          let start = now.addingTimeInterval(offset)
          return VMF_WidgetMeeting(id: id, name: "Meeting \(id)", timeZoneIdentifier: "America/New_York", isServiceMeeting: service,
                                   spans: [VMF_WidgetSpan(start: start, end: start.addingTimeInterval(duration)),
                                           VMF_WidgetSpan(start: start.addingTimeInterval(604800), end: start.addingTimeInterval(604800 + duration))])
     }

     func testStartIsInclusiveAndEndIsExclusive() {
          let schedule = VMF_WidgetSchedule(meetings: [meeting(1)], preferences: .init(), now: now)
          XCTAssertTrue(schedule.state(at: now.addingTimeInterval(-1)).inProgress.isEmpty)
          XCTAssertEqual(schedule.state(at: now).inProgress.map(\.id), [1])
          XCTAssertEqual(schedule.state(at: now.addingTimeInterval(3599)).inProgress.map(\.id), [1])
          XCTAssertTrue(schedule.state(at: now.addingTimeInterval(3600)).inProgress.isEmpty)
     }

     func testZeroDurationNeverAppearsInProgress() {
          let state = VMF_WidgetSchedule(meetings: [meeting(1, duration: 0)], preferences: .init(), now: now).state(at: now)
          XCTAssertTrue(state.inProgress.isEmpty)
     }

     func testAttendanceAdvancesAfterCurrentMeetingEnds() {
          let schedule = VMF_WidgetSchedule(meetings: [meeting(1, offset: -1800), meeting(2, offset: 7200)],
                                            preferences: .init(attendance: [1, 2]), now: now)
          XCTAssertEqual(schedule.state(at: now).attendance.map(\.id), [1, 2])
          XCTAssertEqual(schedule.state(at: now.addingTimeInterval(1800)).attendance.map(\.id), [2, 1])
     }

     func testServiceFilterAppliesToAllSections() {
          let meetings = [meeting(1, offset: -900, service: true), meeting(2, offset: 900, service: true), meeting(3)]
          let filtered = VMF_WidgetSchedule(meetings: meetings, preferences: .init(attendance: [1, 2, 3]), now: now).state(at: now)
          XCTAssertEqual(filtered.attendance.map(\.id), [3])
          XCTAssertEqual(filtered.inProgress.map(\.id), [3])
          XCTAssertTrue(filtered.upcoming.isEmpty)
          let unfiltered = VMF_WidgetSchedule(meetings: meetings, preferences: .init(attendance: [1, 2, 3], excludeServiceMeetings: false), now: now).state(at: now)
          XCTAssertEqual(unfiltered.attendance.map(\.id), [1, 3, 2])
          XCTAssertEqual(unfiltered.inProgress.map(\.id), [1, 3])
     }

     func testNoAttendanceLeavesRoomForLiveAndUpcomingRows() {
          let state = VMF_WidgetSchedule(meetings: [meeting(1, offset: -1800), meeting(2, offset: 900)], preferences: .init(), now: now).state(at: now)
          XCTAssertTrue(state.attendance.isEmpty)
          let layout = VMF_WidgetLayout(state: state, height: 120, unit: 12, columns: 1)
          XCTAssertTrue(layout.attendance.isEmpty)
          XCTAssertEqual(layout.inProgress.map(\.id), [1])
          XCTAssertEqual(layout.upcoming.map(\.id), [2])
     }

     func testLayoutPrioritizesLiveMeetingsAndAvoidsDuplicates() {
          let meetings = (1...20).map { meeting($0, offset: -900) } + [meeting(21, offset: 900)]
          let state = VMF_WidgetSchedule(meetings: meetings, preferences: .init(attendance: [1]), now: now).state(at: now)
          let layout = VMF_WidgetLayout(state: state, height: 270, unit: 12, columns: 1)
          XCTAssertEqual(layout.attendance.map(\.id), [1])
          XCTAssertFalse(layout.inProgress.isEmpty)
          XCTAssertFalse(layout.inProgress.contains { $0.id == 1 })
          XCTAssertTrue(layout.upcoming.isEmpty)
          let occupied = 24 + 72 + 24 + Double(layout.inProgress.count) * 36
          XCTAssertLessThanOrEqual(occupied, 270)
          let wide = VMF_WidgetLayout(state: state, height: 270, unit: 12, columns: 2)
          XCTAssertGreaterThan(wide.inProgress.count, layout.inProgress.count)
     }

     func testTimelineIncludesMeetingTransitionsAndHasBoundedSize() {
          let schedule = VMF_WidgetSchedule(meetings: [meeting(1, offset: 120)], preferences: .init(), now: now)
          let dates = schedule.timelineDates(now: now)
          XCTAssertEqual(dates.first, now)
          XCTAssertTrue(dates.contains(now.addingTimeInterval(120)))
          XCTAssertTrue(dates.contains(now.addingTimeInterval(3720)))
          XCTAssertLessThanOrEqual(dates.count, 64)
     }

     func testLargeLayoutShowsMultipleAttendedMeetingsBeforeUpcoming() {
          let state = VMF_WidgetSchedule(meetings: [meeting(1, offset: 1800), meeting(2, offset: 3600), meeting(3, offset: -900), meeting(4, offset: 900)],
                                          preferences: .init(attendance: [1, 2]), now: now).state(at: now)
          let layout = VMF_WidgetLayout(state: state, height: 292, unit: 12, columns: 1)
          XCTAssertEqual(layout.attendance.map(\.id), [1, 2])
          XCTAssertEqual(layout.inProgress.map(\.id), [3])
          XCTAssertEqual(layout.upcoming.map(\.id), [4])
     }

     func testAttendanceOnlyUsesAvailableRowsAndHidesOtherMeetings() {
          let state = VMF_WidgetSchedule(meetings: (1...8).map { meeting($0, offset: Double($0) * 900) } + [meeting(9, offset: -900)],
                                        preferences: .init(attendance: Set(1...6)), now: now).state(at: now)
          let layout = VMF_WidgetLayout(state: state, height: 320, unit: 12, columns: 1, onlyAttendance: true)
          XCTAssertEqual(layout.attendance.map(\.id), [1, 2, 3, 4])
          XCTAssertTrue(layout.inProgress.isEmpty)
          XCTAssertTrue(layout.upcoming.isEmpty)
          XCTAssertLessThanOrEqual(24 + Double(layout.attendance.count) * 72, 320)
     }

     func testAttendanceOnlyFallsBackWhenLastAttendedMeetingIsRemovedOrFiltered() {
          let meetings = [meeting(1, offset: 900, service: true), meeting(2, offset: -900), meeting(3, offset: 1800)]
          for attendance: Set<Int> in [[], [1]] {
               let state = VMF_WidgetSchedule(meetings: meetings, preferences: .init(attendance: attendance), now: now).state(at: now)
               let layout = VMF_WidgetLayout(state: state, height: 240, unit: 12, columns: 1, onlyAttendance: true)
               XCTAssertTrue(layout.attendance.isEmpty)
               XCTAssertEqual(layout.inProgress.map(\.id), [2])
               XCTAssertEqual(layout.upcoming.map(\.id), [3])
          }
     }

     func testAttendanceOnlyKeepsNextMeetingFirstInTallAndWideLayouts() {
          // Match the reported mix: one attended meeting in progress, three
          // attended meetings ahead, and other live/upcoming meetings to hide.
          let schedule = VMF_WidgetSchedule(meetings: [meeting(4, offset: 3600), meeting(5, offset: -7200, duration: 14400),
                                                       meeting(2, offset: 900), meeting(1, offset: -1800),
                                                       meeting(6, offset: 600), meeting(3, offset: 1800)],
                                            preferences: .init(attendance: [1, 2, 3, 4]), now: now)
          for columns in [1, 2] {
               for (date, expected) in [(now, [1, 2, 3, 4]), (now.addingTimeInterval(1800), [2, 3, 4, 1])] {
                    let layout = VMF_WidgetLayout(state: schedule.state(at: date), height: 480, unit: 12,
                                                  columns: columns, onlyAttendance: true)
                    XCTAssertEqual(layout.attendance.map(\.id), expected)
                    XCTAssertTrue(layout.inProgress.isEmpty)
                    XCTAssertTrue(layout.upcoming.isEmpty)
               }
          }
     }

     func testLocalFormattingUsesResolvedDateWithoutAddingAnOffset() {
          let occurrence = VMF_WidgetSchedule(meetings: [meeting(1)], preferences: .init(), now: now).state(at: now).inProgress[0]
          let zone = TimeZone(identifier: "America/Los_Angeles")!
          let locale = Locale(identifier: "en_US")
          XCTAssertEqual(VMF_WidgetTime.span(occurrence, relativeTo: now, timeZone: zone, locale: locale), "9:00\u{202F}AM – 10:00\u{202F}AM")
          XCTAssertEqual(VMF_WidgetTime.nativeTime(occurrence, timeZone: zone, locale: locale), "EST (12:00\u{202F}PM)")
          XCTAssertNil(VMF_WidgetTime.nativeTime(occurrence, timeZone: occurrence.meeting.timeZone))
     }

     func testSnapshotRoundTripPreservesAbsoluteDates() throws {
          let cache = VMF_WidgetCache(meetings: [meeting(1)], updatedAt: now, validUntil: now.addingTimeInterval(3600))
          let decoded = try JSONDecoder().decode(VMF_WidgetCache.self, from: JSONEncoder().encode(cache))
          XCTAssertEqual(decoded.meetings, cache.meetings)
          XCTAssertEqual(decoded.validUntil, cache.validUntil)
     }

     private func sdkMeeting(time: String, weekday: Int = 1, zone: String = "America/New_York", name: String = "DST fixture") throws -> MeetingInstance {
          let record: [String: Any] = ["server_id": 1, "meeting_id": 1, "organization_key": "na", "name": name,
                                       "weekday": weekday, "start_time": time, "duration": 7200,
                                       "time_zone": zone, "virtual_information": ["url": "https://example.com/meeting"]]
          let response: [String: Any] = ["meta": ["actual_size": 1, "page_size": -1, "starting_index": 0, "total": 1,
                                                  "total_pages": 1, "page": 0, "search_time": 0.0], "meetings": [record]]
          let parser = try XCTUnwrap(SwiftBMLSDK_Parser(jsonData: JSONSerialization.data(withJSONObject: response), specification: .init()))
          return try XCTUnwrap(parser.meetings.first)
     }

     @MainActor func testMeetingCellRetainsAllTextWhenOptionalLabelsChange() throws {
          let controller = try XCTUnwrap(UIStoryboard(name: "VMF", bundle: .main).instantiateViewController(withIdentifier: VMF_EmbeddedTableController.storyboardID) as? VMF_EmbeddedTableController)
          controller.loadViewIfNeeded()
          let table = try XCTUnwrap(controller.valueTable)
          let cell = try XCTUnwrap(table.dequeueReusableCell(withIdentifier: VMF_TableCell.reuseID) as? VMF_TableCell)
          cell.myController = controller
          let name = try XCTUnwrap(cell.nameLabel)
          let time = try XCTUnwrap(cell.timeAndDayLabel)
          let zone = try XCTUnwrap(cell.timeZoneLabel)
          let progress = try XCTUnwrap(cell.inProgressLabel)

          // Live name search reuses the same cell for meetings with different optional lines.
          for width: CGFloat in [320, 368, 700] {
               cell.frame = CGRect(x: 0, y: 0, width: width, height: 150)
               cell.setNeedsLayout()
               cell.layoutIfNeeded()
               for showsZone in [true, false, true, false, true] {
                    for showsProgress in [false, true, false] {
                         name.text = "'Je' devient 'Nous'"
                         time.text = "Saturday, 5:00 AM – 6:30 AM"
                         zone.text = "Time zone: Central European Standard Time (11:00 AM)"
                         zone.isHidden = !showsZone
                         progress.text = "In progress"
                         progress.isHidden = !showsProgress
                         let size = cell.contentView.systemLayoutSizeFitting(CGSize(width: width, height: 0),
                              withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
                         cell.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
                         cell.setNeedsLayout()
                         cell.layoutIfNeeded()

                         let visibleLabels = [name, time, zone, progress].filter { !$0.isHidden }
                         for label in visibleLabels {
                              XCTAssertGreaterThanOrEqual(label.bounds.height, label.font.lineHeight - 1,
                                   "Clipped \(label.text ?? "") after changing optional lines at width \(width)")
                              let frame = label.convert(label.bounds, to: cell.contentView)
                              XCTAssertGreaterThanOrEqual(frame.minY, 7)
                              XCTAssertLessThanOrEqual(frame.maxY, cell.contentView.bounds.maxY - 7)
                         }
                         for (above, below) in zip(visibleLabels, visibleLabels.dropFirst()) {
                              XCTAssertGreaterThanOrEqual(below.frame.minY, above.frame.maxY + 3)
                         }
                    }
               }
          }
     }

     @MainActor func testSearchReloadSizesFirstMeetingRowAfterOptionalLinesChange() async throws {
          let controller = try XCTUnwrap(UIStoryboard(name: "VMF", bundle: .main).instantiateViewController(withIdentifier: VMF_EmbeddedTableController.storyboardID) as? VMF_EmbeddedTableController)
          let main = VMF_WidgetLinkTestController()
          main.isNameSearchMode = true
          main.tableDisplayController = controller
          controller.myController = main
          let weekday = Calendar.current.component(.weekday, from: Date().addingTimeInterval(86400))
          let local = try sdkMeeting(time: "12:00:00", weekday: weekday, zone: TimeZone.current.identifier, name: "Local fixture")
          let foreignZone = TimeZone.current.identifier == "Europe/Paris" ? "America/New_York" : "Europe/Paris"
          let foreign = try sdkMeeting(time: "12:00:00", weekday: weekday, zone: foreignZone, name: "Foreign fixture with a long meeting name that wraps onto another line")
          let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
          let originalWindow = scene.keyWindow
          let window = UIWindow(windowScene: scene)
          window.rootViewController = main
          main.loadViewIfNeeded()
          main.addChild(controller)
          main.view.addSubview(controller.view)
          controller.view.frame = main.view.bounds
          controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          controller.didMove(toParent: main)
          window.makeKeyAndVisible()
          defer {
               window.isHidden = true
               originalWindow?.makeKeyAndVisible()
          }
          let table = try XCTUnwrap(controller.valueTable)

          main.searchMeetings = [local, foreign] + (try (0..<40).map { index in
               try sdkMeeting(time: "12:00:00", weekday: weekday,
                    zone: index.isMultiple(of: 2) ? TimeZone.current.identifier : foreignZone,
                    name: "\(index.isMultiple(of: 2) ? "Local" : "Foreign") fixture \(index)" + (index.isMultiple(of: 3) ? " with a longer name that wraps onto another line in the meeting list" : ""))
          })
          for query in ["", "local", "local", "foreign", "foreign", "missing", "", "fixture", "local", "foreign", ""] {
               main.searchText = query
               controller.view.setNeedsLayout()
               controller.view.layoutIfNeeded()
               table.layoutIfNeeded()
               let expectedMeetings = main.getCurentMeetings()
               XCTAssertEqual(table.numberOfRows(inSection: 0), expectedMeetings.count)
               if !expectedMeetings.isEmpty {
                    table.scrollToRow(at: IndexPath(row: expectedMeetings.count - 1, section: 0), at: .bottom, animated: false)
                    table.layoutIfNeeded()
               }
               // Check again after UIKit's deferred stack layout and visibility updates.
               for delay: UInt64 in [50_000_000, 200_000_000] {
                    try await Task.sleep(nanoseconds: delay)
                    XCTAssertEqual(table.visibleCells.isEmpty, expectedMeetings.isEmpty)
                    for cell in table.visibleCells.compactMap({ $0 as? VMF_TableCell }) {
                         let meeting = try XCTUnwrap(cell.myMeeting)
                         let indexPath = try XCTUnwrap(table.indexPath(for: cell))
                         XCTAssertTrue(meeting === expectedMeetings[indexPath.row])
                         let zone = try XCTUnwrap(cell.timeZoneLabel)
                         let expectedZone = controller.getMeetingTimeZone(meeting)
                         XCTAssertEqual(zone.isHidden, expectedZone.isEmpty, "Timezone visibility changed after search: \(query)")
                         XCTAssertEqual(zone.text, expectedZone.isEmpty ? nil : expectedZone)
                         let progress = try XCTUnwrap(cell.inProgressLabel)
                         XCTAssertEqual(progress.isHidden, !meeting.isMeetingInProgress())
                         let labels = [cell.nameLabel, cell.timeAndDayLabel, zone, progress]
                              .compactMap { $0 }.filter { !$0.isHidden }
                         for label in labels {
                              XCTAssertEqual(label.alpha, 1)
                              XCTAssertGreaterThanOrEqual(label.bounds.height, label.font.lineHeight - 1,
                                   "Search row clipped \(label.text ?? "")")
                              XCTAssertLessThanOrEqual(label.convert(label.bounds, to: cell.contentView).maxY,
                                   cell.contentView.bounds.maxY - 7)
                         }
                         let last = try XCTUnwrap(labels.last)
                         XCTAssertEqual(last.convert(last.bounds, to: cell.contentView).maxY + 8,
                              cell.contentView.bounds.height, accuracy: 1, "Search row retained a blank gap")
                    }
               }
          }

          func descendants(of view: UIView) -> [UIView] {
               [view] + view.subviews.flatMap { descendants(of: $0) }
          }
          for _ in 0..<3 {
               let picker = VMF_DayTimeSelectionViewController()
               picker.mainController = main
               picker.modalPresentationStyle = .popover
               picker.preferredContentSize = CGSize(width: 350, height: 180)
               let popover = try XCTUnwrap(picker.popoverPresentationController)
               popover.delegate = picker
               popover.sourceView = main.view
               popover.sourceRect = CGRect(x: 100, y: 60, width: 1, height: 1)
               main.present(picker, animated: true)
               try await Task.sleep(nanoseconds: 600_000_000)
               let controls = descendants(of: picker.view)
               let field = try XCTUnwrap(controls.first { $0.accessibilityIdentifier == "popover-meeting-name-search" } as? UITextField)
               let showResults = try XCTUnwrap(controls.first { $0.accessibilityIdentifier == "show-meeting-search-results" } as? UIButton)
               field.text = "g"
               field.sendActions(for: .editingChanged)
               try await Task.sleep(nanoseconds: 100_000_000)
               field.text = "ge"
               field.sendActions(for: .editingChanged)
               try await Task.sleep(nanoseconds: 100_000_000)
               showResults.sendActions(for: .touchUpInside)
               try await Task.sleep(nanoseconds: 600_000_000)
               XCTAssertNil(main.presentedViewController)
               XCTAssertFalse(table.visibleCells.isEmpty)
               for cell in table.visibleCells.compactMap({ $0 as? VMF_TableCell }) {
                    let meeting = try XCTUnwrap(cell.myMeeting)
                    let zone = try XCTUnwrap(cell.timeZoneLabel)
                    let expectedZone = controller.getMeetingTimeZone(meeting)
                    XCTAssertEqual(zone.isHidden, expectedZone.isEmpty)
                    XCTAssertEqual(zone.text, expectedZone.isEmpty ? nil : expectedZone)
                    if !expectedZone.isEmpty {
                         XCTAssertEqual(zone.alpha, 1)
                         XCTAssertEqual(zone.layer.opacity, 1)
                         XCTAssertGreaterThanOrEqual(zone.bounds.height, zone.font.lineHeight - 1)
                    }
                    let labels = [cell.nameLabel, cell.timeAndDayLabel, zone, cell.inProgressLabel].compactMap { $0 }.filter { !$0.isHidden }
                    let last = try XCTUnwrap(labels.last)
                    XCTAssertEqual(last.convert(last.bounds, to: cell.contentView).maxY + 8,
                         cell.contentView.bounds.height, accuracy: 1, "Show Results left a blank gap")
               }
          }
     }

     @MainActor func testMeetingCellVisibilitySurvivesRepeatedConfiguration() async throws {
          let controller = try XCTUnwrap(UIStoryboard(name: "VMF", bundle: .main).instantiateViewController(withIdentifier: VMF_EmbeddedTableController.storyboardID) as? VMF_EmbeddedTableController)
          controller.loadViewIfNeeded()
          let table = try XCTUnwrap(controller.valueTable)
          let cell = try XCTUnwrap(table.dequeueReusableCell(withIdentifier: VMF_TableCell.reuseID) as? VMF_TableCell)
          cell.myController = controller
          let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
          let host = UIViewController()
          window.rootViewController = host
          host.view.addSubview(cell)
          cell.frame = CGRect(x: 0, y: 0, width: 320, height: 150)
          window.isHidden = false
          defer { window.isHidden = true }
          let weekday = Calendar.current.component(.weekday, from: Date().addingTimeInterval(86400))
          let local = try sdkMeeting(time: "12:00:00", weekday: weekday, zone: TimeZone.current.identifier)
          let foreignZone = TimeZone.current.identifier == "Europe/Paris" ? "America/New_York" : "Europe/Paris"
          let foreign = try sdkMeeting(time: "12:00:00", weekday: weekday, zone: foreignZone)
          let zone = try XCTUnwrap(cell.timeZoneLabel)
          for _ in 0..<5 {
               for meeting in [local, foreign] {
                    // Reuse/reload can configure a row several times before a layout pass.
                    for _ in 0..<5 { cell.myMeeting = meeting }
                    cell.setNeedsLayout()
                    cell.layoutIfNeeded()
                    try await Task.sleep(nanoseconds: 50_000_000)
                    XCTAssertEqual(zone.isHidden, meeting === local)
                    XCTAssertEqual(zone.text, meeting === local ? nil : controller.getMeetingTimeZone(meeting),
                         "A reused row retained another meeting's timezone text")
                    XCTAssertNil(cell.inProgressLabel?.text, "An upcoming meeting retained an old in-progress line")
               }
          }
          // A search can reconfigure cells while the keyboard/popover is animating.
          for _ in 0..<5 {
               for meeting in [local, foreign] {
                    UIView.animate(withDuration: 0.2) {
                         cell.myMeeting = meeting
                         cell.layoutIfNeeded()
                    }
                    try await Task.sleep(nanoseconds: 50_000_000)
               }
          }
          cell.myMeeting = foreign
          cell.layoutIfNeeded()
          try await Task.sleep(nanoseconds: 400_000_000)
          XCTAssertFalse(zone.isHidden)
          XCTAssertEqual(zone.alpha, 1)
          XCTAssertEqual(zone.layer.opacity, 1)
          XCTAssertGreaterThanOrEqual(zone.bounds.height, zone.font.lineHeight - 1)
          cell.prepareForReuse()
          XCTAssertNil(cell.myMeeting)
          XCTAssertNil(zone.text)
          XCTAssertTrue(zone.isHidden)
          XCTAssertNil(cell.inProgressLabel?.text)
          XCTAssertEqual(cell.inProgressLabel?.isHidden, true)
     }

     func testWidgetMeetingLinksRetainFullSDKIdentifiers() throws {
          for id in [1, 17592186044417, Int.max] {
               let url = try XCTUnwrap(VMF_MeetingLink.url(for: id))
               XCTAssertEqual(url.scheme, "lgv-vmf")
               XCTAssertEqual(VMF_MeetingLink.meetingID(in: url), id)
          }
          XCTAssertNil(VMF_MeetingLink.url(for: 0))
          XCTAssertNil(VMF_MeetingLink.url(for: -1))
          XCTAssertEqual(VMF_MeetingLink.meetingID(in: URL(string: "https://vmf.littlegreenviper.com?17592186044417")!), 17592186044417)
          for url in ["lgv-vmf://open", "lgv-vmf://meeting?0", "lgv-vmf://meeting?-1", "lgv-vmf://meeting?invalid", "https://example.com?123"] {
               XCTAssertNil(VMF_MeetingLink.meetingID(in: URL(string: url)!))
          }
     }

     func testWidgetBundlesEveryAppLanguageAndLocalizedMeetingHint() throws {
          let widgetURL = try XCTUnwrap(Bundle.main.builtInPlugInsURL?.appendingPathComponent("VMFWidgets.appex"))
          let widget = try XCTUnwrap(Bundle(url: widgetURL))
          let languages = Set(Bundle.main.localizations).subtracting(["Base"])
          XCTAssertEqual(Set(widget.localizations).subtracting(["Base"]), languages)
          for language in languages {
               let app = try XCTUnwrap(Bundle(path: Bundle.main.path(forResource: language, ofType: "lproj")!))
               let localized = try XCTUnwrap(Bundle(path: widget.path(forResource: language, ofType: "lproj")!))
               for key in ["WIDGET-TITLE", "WIDGET-DESCRIPTION", "WIDGET-APP-NAME", "WIDGET-NEXT-MEETING", "WIDGET-IN-PROGRESS", "WIDGET-UPCOMING", "WIDGET-OPEN-APP", "WIDGET-OPEN-MEETING-HINT", "WIDGET-ONLY-ATTENDANCE", "WIDGET-FILTER-ON", "WIDGET-FILTER-OFF", "WIDGET-ATTENDANCE-REQUIRED"] {
                    let value = localized.localizedString(forKey: key, value: nil, table: "Localizable")
                    XCTAssertFalse(value.isEmpty)
                    XCTAssertNotEqual(value, key, "Missing \(language) widget translation for \(key)")
               }
               let appName = app.localizedString(forKey: "CFBundleDisplayName", value: nil, table: "InfoPlist")
               XCTAssertEqual(localized.localizedString(forKey: "WIDGET-APP-NAME", value: nil, table: "Localizable"), appName)
               XCTAssertEqual(localized.localizedString(forKey: "CFBundleDisplayName", value: nil, table: "InfoPlist"), appName)
          }
     }

     @MainActor func testMeetingLinkWaitsForDataAndReplacesAnOpenInspector() throws {
          let configuration = URLSessionConfiguration.ephemeral
          configuration.protocolClasses = [VMF_WidgetFixtureProtocol.self]
          let query = SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://widget-fixture.invalid/"), session: URLSession(configuration: configuration))
          let loaded = expectation(description: "Fixture collection loaded")
          let collection = SwiftBMLSDK_MeetingLocalTimezoneCollection(query: query) { _ in loaded.fulfill() }
          wait(for: [loaded], timeout: 3)
          XCTAssertEqual(collection.meetings.count, 2)

          let originalMain = VMF_AppDelegate.mainScreenController
          let originalInspector = VMF_AppDelegate.openMeeting
          let originalPending = VMF_SceneDelegate.urlMeetingID
          let originalDelegate = VMF_SceneDelegate.sceneDelegateInstance
          let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
          let originalWindow = windowScene.keyWindow
          let window = UIWindow(windowScene: windowScene)
          let main = VMF_WidgetLinkTestController()
          let navigation = UINavigationController(rootViewController: main)
          let table = try XCTUnwrap(UIStoryboard(name: "VMF", bundle: .main).instantiateViewController(withIdentifier: VMF_EmbeddedTableController.storyboardID) as? VMF_EmbeddedTableController)
          let scene = VMF_SceneDelegate()
          scene.window = window
          var availableMeetings: [MeetingInstance]?
          scene.meetingSource = { availableMeetings }
          defer {
               window.isHidden = true
               window.rootViewController = nil
               VMF_AppDelegate.mainScreenController = originalMain
               VMF_AppDelegate.openMeeting = originalInspector
               VMF_SceneDelegate.urlMeetingID = originalPending
               VMF_SceneDelegate.sceneDelegateInstance = originalDelegate
               originalWindow?.makeKeyAndVisible()
          }
          VMF_AppDelegate.mainScreenController = main
          VMF_SceneDelegate.urlMeetingID = 0
          VMF_SceneDelegate.sceneDelegateInstance = scene
          main.loadViewIfNeeded()
          main.addChild(table)
          main.view.addSubview(table.view)
          table.didMove(toParent: main)
          table.myController = main
          main.tableDisplayController = table
          window.rootViewController = navigation
          window.makeKeyAndVisible()

          let firstID = Int(collection.meetings[0].meeting.id)
          let secondID = Int(collection.meetings[1].meeting.id)
          scene.resolveURL(try XCTUnwrap(VMF_MeetingLink.url(for: firstID)))
          table.checkForUniversalLink()
          XCTAssertEqual(VMF_SceneDelegate.urlMeetingID, firstID, "A link must survive until meeting data arrives")
          XCTAssertTrue(navigation.topViewController === main)

          scene.resolveURL(VMF_WidgetStore.openAppURL)
          XCTAssertEqual(VMF_SceneDelegate.urlMeetingID, 0, "The icon must cancel a meeting link still waiting for data")
          scene.resolveURL(try XCTUnwrap(VMF_MeetingLink.url(for: firstID)))

          availableMeetings = collection.meetings.map(\.meeting)
          scene.openPendingLink()
          let initiallyOpened = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
               (navigation.topViewController as? VMF_MeetingInspectorViewController)?.meeting?.id == UInt64(firstID)
          }, object: nil)
          wait(for: [initiallyOpened], timeout: 3)
          XCTAssertEqual((navigation.topViewController as? VMF_MeetingInspectorViewController)?.meeting?.id, UInt64(firstID))
          XCTAssertEqual(VMF_SceneDelegate.urlMeetingID, 0)

          // A second widget tap can arrive while the first inspector is animating.
          scene.resolveURL(try XCTUnwrap(VMF_MeetingLink.url(for: secondID)))
          let replaced = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
               (navigation.topViewController as? VMF_MeetingInspectorViewController)?.meeting?.id == UInt64(secondID)
          }, object: nil)
          wait(for: [replaced], timeout: 3)
          XCTAssertEqual(navigation.viewControllers.count, 2)
          XCTAssertEqual(VMF_SceneDelegate.urlMeetingID, 0)

          let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in navigation.transitionCoordinator == nil }, object: nil)
          wait(for: [settled], timeout: 3)
          navigation.pushViewController(UIViewController(), animated: false)
          scene.resolveURL(try XCTUnwrap(VMF_MeetingLink.url(for: firstID)))
          let returned = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
               (navigation.topViewController as? VMF_MeetingInspectorViewController)?.meeting?.id == UInt64(firstID)
          }, object: nil)
          wait(for: [returned], timeout: 3)
          XCTAssertEqual((navigation.topViewController as? VMF_MeetingInspectorViewController)?.meeting?.id, UInt64(firstID))
          XCTAssertEqual(navigation.viewControllers.count, 2, "A link from another screen returns to one inspector above the main screen")

          scene.resolveURL(VMF_WidgetStore.openAppURL)
          XCTAssertEqual(VMF_SceneDelegate.urlMeetingID, 0, "The icon's normal-open URL must not select a meeting")

          availableMeetings = nil
          scene.resolveURL(VMF_WidgetStore.openMainScreenURL)
          let returnedToMain = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
               navigation.topViewController === main && navigation.viewControllers.count == 1
          }, object: nil)
          wait(for: [returnedToMain], timeout: 3)

          availableMeetings = collection.meetings.map(\.meeting)
          scene.resolveURL(try XCTUnwrap(VMF_MeetingLink.url(for: firstID)))
          scene.resolveURL(try XCTUnwrap(VMF_MeetingLink.url(for: secondID)))
          let latestLink = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
               (navigation.topViewController as? VMF_MeetingInspectorViewController)?.meeting?.id == UInt64(secondID)
                    && navigation.viewControllers.count == 2
          }, object: nil)
          wait(for: [latestLink], timeout: 3)
     }

     func testSDKResolvesSpringDSTBeforeExport() throws {
          let reference = ISO8601DateFormatter().date(from: "2026-03-07T12:00:00Z")!
          let meeting = try sdkMeeting(time: "02:30:00")
          let cache = VMF_WidgetBridge.snapshot(meetings: [meeting], now: reference)
          let span = try XCTUnwrap(cache.meetings.first?.spans.first)
          XCTAssertEqual(span.start, meeting.nextOccurrenceDateFast(from: reference))
          XCTAssertEqual(span.start, ISO8601DateFormatter().date(from: "2026-03-08T07:30:00Z"))
          XCTAssertEqual(span.end.timeIntervalSince(span.start), 7200)
     }

     private func reviewQuery(host: String = "review-fixture.invalid") -> SwiftBMLSDK_Query {
          let configuration = URLSessionConfiguration.ephemeral
          configuration.protocolClasses = [VMF_ReviewFixtureProtocol.self]
          return SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://\(host)/"), session: URLSession(configuration: configuration))
     }

     private func reviewCollection() -> SwiftBMLSDK_MeetingLocalTimezoneCollection {
          let loaded = expectation(description: "Review fixture loaded")
          let collection = SwiftBMLSDK_MeetingLocalTimezoneCollection(query: reviewQuery()) { _ in loaded.fulfill() }
          wait(for: [loaded], timeout: 3)
          XCTAssertEqual(collection.meetings.count, 2)
          XCTAssertEqual(collection.meetings.filter { $0.meeting.isServiceMeeting }.count, 1)
          return collection
     }

     /// Hosted tests may begin while the app's normal startup download is still running.
     /// Join that request before starting an isolated fixture download.
     private func waitForStartupDownload() {
          let settled = expectation(description: "Startup download settled")
          VMF_AppDelegate.findMeetings(query: nil, timeout: 0) { _ in settled.fulfill() }
          wait(for: [settled], timeout: 35)
     }

     @MainActor func testServiceFilterUpdatesWeekdayAndSearchAfterSettings() throws {
          let original = VMF_AppDelegate.virtualService
          let originalMain = VMF_AppDelegate.mainScreenController
          let filter = VMF_AppDelegate.prefs.excludeServiceMeetings
          defer {
               VMF_AppDelegate.virtualService = original
               VMF_AppDelegate.mainScreenController = originalMain
               VMF_AppDelegate.prefs.excludeServiceMeetings = filter
          }
          VMF_AppDelegate.virtualService = reviewCollection()
          VMF_AppDelegate.prefs.excludeServiceMeetings = false
          let navigation = try XCTUnwrap(UIStoryboard(name: "VMF", bundle: .main).instantiateInitialViewController() as? UINavigationController)
          let main = try XCTUnwrap(navigation.viewControllers.first as? VMF_MainViewController)
          main.loadViewIfNeeded()
          main.reorganizeMeetings()
          let meeting = try XCTUnwrap(VMF_AppDelegate.virtualService?.meetings.first?.meeting)
          main.openTo(dayIndex: meeting.adjustedWeekday, time: meeting.adjustedIntegerStartTime)
          XCTAssertEqual(main.tableDisplayController?.meetings.count, 2)

          VMF_AppDelegate.prefs.excludeServiceMeetings = true
          main.viewWillAppear(false)
          XCTAssertEqual(main.tableDisplayController?.meetings.count, 1)
          XCTAssertFalse(main.tableDisplayController?.meetings.contains(where: \.isServiceMeeting) ?? true)

          main.isNameSearchMode = true
          main.searchText = "Review fixture"
          VMF_AppDelegate.prefs.excludeServiceMeetings = false
          main.viewWillAppear(false)
          XCTAssertTrue(main.isNameSearchMode)
          XCTAssertEqual(main.searchText, "Review fixture")
          XCTAssertEqual(main.tableDisplayController?.meetings.count, 2)
          VMF_AppDelegate.prefs.excludeServiceMeetings = true
          main.viewWillAppear(false)
          XCTAssertEqual(main.tableDisplayController?.meetings.count, 1)
     }

     @MainActor func testNowUsesTheServiceMeetingFilter() {
          let original = VMF_AppDelegate.virtualService
          let filter = VMF_AppDelegate.prefs.excludeServiceMeetings
          defer { VMF_AppDelegate.virtualService = original; VMF_AppDelegate.prefs.excludeServiceMeetings = filter }
          VMF_AppDelegate.virtualService = reviewCollection()
          let main = VMF_MainViewController()
          VMF_AppDelegate.prefs.excludeServiceMeetings = false
          XCTAssertEqual(main.inProgressMeetings.count, 2)
          VMF_AppDelegate.prefs.excludeServiceMeetings = true
          XCTAssertEqual(main.inProgressMeetings.count, 1)
          XCTAssertFalse(main.inProgressMeetings.contains(where: \.isServiceMeeting))
     }

     @MainActor func testTimeZoneLabelsFollowDaylightSavingAtTheMeetingStart() throws {
          let controller = VMF_BaseViewController()
          // The opposite hemispheres exercise daylight-saving names throughout the year.
          for zone in ["America/New_York", "Australia/Sydney"] where zone != TimeZone.current.identifier {
               let meeting = try sdkMeeting(time: "12:00:00", zone: zone)
               let date = meeting.isMeetingInProgress() ? meeting.previousOccurrenceDateFast() : meeting.nextOccurrenceDateFast()
               let style: TimeZone.NameStyle = meeting.timeZone.isDaylightSavingTime(for: date) ? .daylightSaving : .standard
               let name = try XCTUnwrap(meeting.timeZone.localizedName(for: style, locale: .current))
               XCTAssertTrue(controller.getMeetingTimeZone(meeting).contains(name))
          }
     }

     @MainActor func testAttendanceRemovalUpdatesSavedListAndReturnFromInspector() throws {
          let original = VMF_AppDelegate.virtualService
          let attendance = VMF_AppDelegate.prefs.attendance
          defer { VMF_AppDelegate.virtualService = original; VMF_AppDelegate.prefs.attendance = attendance }
          VMF_AppDelegate.virtualService = reviewCollection()
          let records = try XCTUnwrap(VMF_AppDelegate.virtualService?.meetings.map(\.meeting))
          VMF_AppDelegate.prefs.attendance = records.map { Int($0.id) }
          let controller = VMF_AttendanceViewController()
          let table = VMF_EmbeddedTableController()
          table.myController = controller
          controller.tableDisplayController = table
          controller.setAttendance()
          XCTAssertEqual(table.meetings.count, 2)
          table.attendanceChanged(records[0])
          XCTAssertEqual(table.meetings.map(\.id), [records[1].id])
          records[1].setAttendance(false)
          controller.viewWillAppear(false)
          XCTAssertTrue(table.meetings.isEmpty)
     }

     @MainActor func testFailedAndEmptyRefreshKeepTheLoadedCollection() {
          waitForStartupDownload()
          let original = VMF_AppDelegate.virtualService
          defer { VMF_AppDelegate.virtualService = original }
          let loaded = reviewCollection()
          VMF_AppDelegate.virtualService = loaded
          for host in ["review-error.invalid", "review-empty.invalid"] {
               let finished = expectation(description: host)
               VMF_AppDelegate.findMeetings(query: reviewQuery(host: host), timeout: 1) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertNil(result)
                    XCTAssertTrue(VMF_AppDelegate.virtualService === loaded)
                    finished.fulfill()
               }
               wait(for: [finished], timeout: 3)
          }
     }

     @MainActor func testTimedOutDownloadCannotCompleteAgainOrReplaceNewerData() {
          waitForStartupDownload()
          let original = VMF_AppDelegate.virtualService
          defer { VMF_AppDelegate.virtualService = original }
          let timedOut = expectation(description: "Timeout completes once")
          var completionCount = 0
          VMF_AppDelegate.findMeetings(query: reviewQuery(host: "review-slow.invalid"), timeout: 0.03) { result in
               completionCount += 1
               XCTAssertNil(result)
               timedOut.fulfill()
          }
          wait(for: [timedOut], timeout: 3)
          let refreshed = expectation(description: "Newer download completes")
          var newer: SwiftBMLSDK_MeetingLocalTimezoneCollection?
          VMF_AppDelegate.findMeetings(query: reviewQuery(), timeout: 1) { result in
               newer = result
               refreshed.fulfill()
          }
          wait(for: [refreshed], timeout: 3)
          let lateResponse = expectation(description: "Late response has arrived")
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { lateResponse.fulfill() }
          wait(for: [lateResponse], timeout: 3)
          XCTAssertNotNil(newer)
          XCTAssertEqual(completionCount, 1)
          XCTAssertTrue(VMF_AppDelegate.virtualService === newer)
     }

     @MainActor func testConcurrentDownloadCallersReceiveTheSameCollection() {
          waitForStartupDownload()
          let original = VMF_AppDelegate.virtualService
          defer { VMF_AppDelegate.virtualService = original }
          let finished = expectation(description: "Both callers finish")
          finished.expectedFulfillmentCount = 2
          var results: [SwiftBMLSDK_MeetingLocalTimezoneCollection] = []
          let completion: (SwiftBMLSDK_MeetingLocalTimezoneCollection?) -> Void = { result in
               XCTAssertTrue(Thread.isMainThread)
               XCTAssertNotNil(result)
               if let result { results.append(result) }
               finished.fulfill()
          }
          VMF_AppDelegate.findMeetings(query: reviewQuery(host: "review-slow.invalid"), timeout: 1, completion: completion)
          VMF_AppDelegate.findMeetings(query: nil, timeout: 0, completion: completion)
          wait(for: [finished], timeout: 3)
          XCTAssertEqual(results.count, 2)
          if results.count == 2 { XCTAssertTrue(results[0] === results[1]) }
     }

     func testSDKResolvesRepeatedAutumnHourBeforeExport() throws {
          let reference = ISO8601DateFormatter().date(from: "2026-10-31T12:00:00Z")!
          let meeting = try sdkMeeting(time: "01:30:00")
          let cache = VMF_WidgetBridge.snapshot(meetings: [meeting], now: reference)
          XCTAssertEqual(cache.meetings[0].spans[0].start, ISO8601DateFormatter().date(from: "2026-11-01T05:30:00Z"))
          XCTAssertEqual(cache.meetings[0].spans[1].start, ISO8601DateFormatter().date(from: "2026-11-08T06:30:00Z"))
     }

     func testSDKExportRetainsAnInProgressMeetingAcrossMidnight() throws {
          let meeting = try sdkMeeting(time: "23:30:00", weekday: 4)
          let reference = ISO8601DateFormatter().date(from: "2026-11-05T05:15:00Z")!
          let cache = VMF_WidgetBridge.snapshot(meetings: [meeting], now: reference)
          let state = VMF_WidgetSchedule(meetings: cache.meetings, preferences: .init(attendance: [Int(meeting.id)]), now: reference).state(at: reference)
          XCTAssertEqual(state.inProgress.first?.start, meeting.previousOccurrenceDateFast(from: reference))
          XCTAssertEqual(state.attendance.first?.start, ISO8601DateFormatter().date(from: "2026-11-05T04:30:00Z"))
     }
}

/// Suppresses the main screen's real download during isolated navigation tests.
private final class VMF_WidgetLinkTestController: VMF_MainViewController {
     override func viewDidLoad() { }
     override func viewWillAppear(_ animated: Bool) { }
     override func viewDidAppear(_ animated: Bool) { }
     override func viewDidLayoutSubviews() { }
}

/// Supplies real SDK parsing and collection behavior without a network request.
private final class VMF_WidgetFixtureProtocol: URLProtocol {
     override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "widget-fixture.invalid" }
     override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
     override func startLoading() {
          let records: [[String: Any]] = (1...2).map { id in
               ["server_id": 1, "meeting_id": id, "organization_key": "na", "name": "Link fixture \(id)",
                "weekday": 1, "start_time": "12:00:00", "duration": 3600, "time_zone": "America/New_York",
                "virtual_information": ["url": "https://example.com/meeting"]]
          }
          let response: [String: Any] = ["meta": ["actual_size": 2, "page_size": -1, "starting_index": 0, "total": 2, "total_pages": 1, "page": 0, "search_time": 0.0], "meetings": records]
          let data = try! JSONSerialization.data(withJSONObject: response)
          client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!, cacheStoragePolicy: .notAllowed)
          client?.urlProtocol(self, didLoad: data)
          client?.urlProtocolDidFinishLoading(self)
     }
     override func stopLoading() { }
}

/// Local responses for service filtering, refresh failures, and late downloads.
private final class VMF_ReviewFixtureProtocol: URLProtocol {
     override class func canInit(with request: URLRequest) -> Bool { request.url?.host?.hasPrefix("review-") == true }
     override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
     override func startLoading() {
          if request.url?.host == "review-error.invalid" {
               client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
               return
          }
          let respond = { [self] in
               let date = Date().addingTimeInterval(-1800)
               var calendar = Calendar(identifier: .gregorian)
               calendar.timeZone = TimeZone(secondsFromGMT: 0)!
               let formatter = DateFormatter()
               formatter.locale = Locale(identifier: "en_US_POSIX")
               formatter.timeZone = calendar.timeZone
               formatter.dateFormat = "HH:mm:00"
               let records: [[String: Any]] = self.request.url?.host == "review-empty.invalid" ? [] : (1...2).map { id in
                    ["server_id": 1, "meeting_id": id, "organization_key": "na", "name": "Review fixture \(id)",
                     "weekday": calendar.component(.weekday, from: date), "start_time": formatter.string(from: date),
                     "duration": 7200, "time_zone": "UTC", "virtual_information": ["url": "https://example.com/meeting"],
                     "formats": id == 2 ? [["id": 1, "key": "ASM", "name": "Service", "description": "Service meeting"]] : []]
               }
               let response: [String: Any] = ["meta": ["actual_size": records.count, "page_size": -1, "starting_index": 0, "total": records.count, "total_pages": 1, "page": 0, "search_time": 0.0], "meetings": records]
               let data = try! JSONSerialization.data(withJSONObject: response)
               self.client?.urlProtocol(self, didReceive: HTTPURLResponse(url: self.request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!, cacheStoragePolicy: .notAllowed)
               self.client?.urlProtocol(self, didLoad: data)
               self.client?.urlProtocolDidFinishLoading(self)
          }
          if request.url?.host == "review-slow.invalid" {
               DispatchQueue.global().asyncAfter(deadline: .now() + 0.2, execute: respond)
          } else { respond() }
     }
     override func stopLoading() { }
}
