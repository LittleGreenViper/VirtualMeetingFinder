// © Copyright 2026, Little Green Viper Software Development LLC. MIT License.

import XCTest
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

     func testNoAttendanceDoesNotHideOtherMeetings() {
          let state = VMF_WidgetSchedule(meetings: [meeting(1, offset: -1800), meeting(2, offset: 900)], preferences: .init(), now: now).state(at: now)
          XCTAssertTrue(state.attendance.isEmpty)
          let layout = VMF_WidgetLayout(state: state, height: 270, unit: 12, columns: 1)
          XCTAssertEqual(layout.inProgress.map(\.id), [1])
          XCTAssertEqual(layout.upcoming.first?.id, 2)
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

     private func sdkMeeting(time: String, weekday: Int = 1, zone: String = "America/New_York") throws -> MeetingInstance {
          let record: [String: Any] = ["server_id": 1, "meeting_id": 1, "organization_key": "na", "name": "DST fixture",
                                       "weekday": weekday, "start_time": time, "duration": 7200,
                                       "time_zone": zone, "virtual_information": ["url": "https://example.com/meeting"]]
          let response: [String: Any] = ["meta": ["actual_size": 1, "page_size": -1, "starting_index": 0, "total": 1,
                                                  "total_pages": 1, "page": 0, "search_time": 0.0], "meetings": [record]]
          let parser = try XCTUnwrap(SwiftBMLSDK_Parser(jsonData: JSONSerialization.data(withJSONObject: response), specification: .init()))
          return try XCTUnwrap(parser.meetings.first)
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
