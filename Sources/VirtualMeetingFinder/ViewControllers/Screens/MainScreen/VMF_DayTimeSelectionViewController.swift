/*
 © Copyright 2024-2026, Little Green Viper Software Development LLC
 LICENSE:

 MIT License

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

/* ###################################################################################################################################### */
// MARK: - Day and Time Selection Popover -
/* ###################################################################################################################################### */
/**
 Browses the available start times for a weekday and searches meeting names.
 Search filters the main table live; dismissing the popover keeps those results visible.
 */
class VMF_DayTimeSelectionViewController: UIViewController, UIPopoverPresentationControllerDelegate {
     static let browsingSize = CGSize(width: 600, height: 500)
     static let searchSize = CGSize(width: 600, height: 180)

     weak var mainController: VMF_MainViewController?

     private let weekdaySelector = VMF_StyledSegmentedControl()
     private let weekdayLabel = UILabel()
     private let timeTableView = UITableView(frame: .zero, style: .plain)
     private let emptyLabel = UILabel()
     private let nowButton = UIButton(type: .system)
     private let searchButton = UIButton(type: .system)
     private let searchTextField = UITextField()
     private let searchContainer = UIScrollView()
     private let showResultsButton = UIButton(type: .system)
     private var isShowingSearch = false
     private var selectedDayIndex = 1
     private var timeSlots: [Int] = []
     private var timeTitles: [Int: String] = [:]
     private var timeCounts: [Int: Int] = [:]
     private var selection: (dayIndex: Int, time: Int)?
     private var didScrollToSelection = false

     override func viewDidLoad() {
          super.viewDidLoad()
          view.backgroundColor = .systemBackground
          let accentColor = UIColor(named: "AccentColor") ?? .systemBlue
          view.tintColor = accentColor
          view.accessibilityViewIsModal = true
          view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16)

          if let main = mainController {
               let day = main.tableDisplayController?.dayIndex ?? 0
               selectedDayIndex = (1...7).contains(day) ? day : main.nowIs.weekday
               if day == 0, !main.isNameSearchMode,
                  let slot = main.adjacentTimeSlot(fromDay: 0, timeIndex: 0, forward: false),
                  let time = main.getTimeOf(dayIndex: slot.dayIndex, timeIndex: slot.timeIndex) {
                    // Now opens the picker at the latest available start at or before now.
                    selectedDayIndex = slot.dayIndex
                    selection = (slot.dayIndex, time)
               } else if let time = main.getTimeOf(dayIndex: day, timeIndex: main.tableDisplayController?.timeIndex ?? 0) {
                    selection = (day, time)
               }
          }

          var nowConfiguration = UIButton.Configuration.plain()
          nowConfiguration.title = "SLUG-NOW".localizedVariant
          nowConfiguration.baseForegroundColor = accentColor
          nowButton.configuration = nowConfiguration
          nowButton.accessibilityLabel = "SLUG-ACC-WEEKDAY-SWITCH-0-LABEL".localizedVariant
          nowButton.accessibilityHint = "SLUG-ACC-WEEKDAY-SWITCH-0-HINT".localizedVariant
          nowButton.accessibilityIdentifier = "select-meetings-now"
          nowButton.addTarget(self, action: #selector(selectNow), for: .touchUpInside)

          var searchConfiguration = UIButton.Configuration.plain()
          searchConfiguration.image = UIImage(systemName: "magnifyingglass")
          searchConfiguration.baseForegroundColor = accentColor
          searchButton.configuration = searchConfiguration
          searchButton.accessibilityLabel = "SLUG-ACC-WEEKDAY-SWITCH-8-LABEL".localizedVariant
          searchButton.accessibilityHint = "SLUG-ACC-WEEKDAY-SWITCH-8-HINT".localizedVariant
          searchButton.accessibilityIdentifier = "search-meetings"
          searchButton.addTarget(self, action: #selector(selectSearch), for: .touchUpInside)
          for button in [nowButton, searchButton] {
               button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
               button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
          }

          weekdayLabel.font = .preferredFont(forTextStyle: .headline)
          weekdayLabel.adjustsFontForContentSizeCategory = true
          weekdayLabel.textAlignment = .center
          weekdayLabel.numberOfLines = 2
          weekdayLabel.accessibilityTraits = .header
          let actions = UIStackView(arrangedSubviews: [nowButton, weekdayLabel, searchButton])
          actions.alignment = .center
          actions.spacing = 8
          nowButton.setContentHuggingPriority(.required, for: .horizontal)
          searchButton.setContentHuggingPriority(.required, for: .horizontal)

          for index in 0..<7 {
               let day = mainController?.unMapWeekday(index + 1) ?? ((Calendar.current.firstWeekday + index - 1) % 7 + 1)
               weekdaySelector.insertSegment(withTitle: Calendar.current.shortStandaloneWeekdaySymbols[day - 1], at: index, animated: false)
          }
          weekdaySelector.selectedSegmentIndex = (mainController?.mapWeekday(selectedDayIndex) ?? 1) - 1
          weekdaySelector.accessibilityLabel = "SLUG-ACC-POPOVER-WEEKDAY-LABEL".localizedVariant
          weekdaySelector.accessibilityHint = "SLUG-ACC-POPOVER-WEEKDAY-HINT".localizedVariant
          weekdaySelector.accessibilityIdentifier = "popover-weekday-selector"
          weekdaySelector.selectedSegmentTintColor = accentColor
          weekdaySelector.setTitleTextAttributes([.foregroundColor: accentColor], for: .normal)
          weekdaySelector.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
          weekdaySelector.setTitleTextAttributes([.foregroundColor: UIColor.tertiaryLabel], for: .disabled)
          let weekdayHeight = weekdaySelector.heightAnchor.constraint(equalToConstant: 30)
          weekdayHeight.priority = UILayoutPriority(999)
          weekdayHeight.isActive = true
          weekdaySelector.addTarget(self, action: #selector(selectWeekday), for: .valueChanged)

          timeTableView.dataSource = self
          timeTableView.delegate = self
          timeTableView.register(UITableViewCell.self, forCellReuseIdentifier: "meeting-time")
          timeTableView.rowHeight = UITableView.automaticDimension
          timeTableView.estimatedRowHeight = 48
          timeTableView.accessibilityLabel = "SLUG-ACC-AVAILABLE-TIMES-LABEL".localizedVariant
          timeTableView.accessibilityIdentifier = "available-meeting-times"
          emptyLabel.text = "SLUG-NO-MEETING-TIMES".localizedVariant
          emptyLabel.font = .preferredFont(forTextStyle: .body)
          emptyLabel.adjustsFontForContentSizeCategory = true
          emptyLabel.textAlignment = .center
          emptyLabel.numberOfLines = 0

          searchTextField.borderStyle = .roundedRect
          searchTextField.font = .preferredFont(forTextStyle: .body)
          searchTextField.adjustsFontForContentSizeCategory = true
          searchTextField.placeholder = "SLUG-SEARCH-PLACEHOLDER".localizedVariant
          searchTextField.accessibilityLabel = "SLUG-ACC-ENTER-SEARCH-TEXT-LABEL".localizedVariant
          searchTextField.accessibilityHint = "SLUG-ACC-ENTER-SEARCH-TEXT-HINT".localizedVariant
          searchTextField.accessibilityIdentifier = "popover-meeting-name-search"
          searchTextField.clearButtonMode = .whileEditing
          searchTextField.autocapitalizationType = .none
          searchTextField.autocorrectionType = .no
          searchTextField.spellCheckingType = .no
          searchTextField.returnKeyType = .search
          searchTextField.text = mainController?.searchText
          searchTextField.delegate = self
          searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

          var resultsConfiguration = UIButton.Configuration.filled()
          resultsConfiguration.title = "SLUG-SHOW-SEARCH-RESULTS".localizedVariant
          resultsConfiguration.baseBackgroundColor = accentColor
          resultsConfiguration.baseForegroundColor = .white
          showResultsButton.configuration = resultsConfiguration
          showResultsButton.accessibilityHint = "SLUG-ACC-SHOW-SEARCH-RESULTS-HINT".localizedVariant
          showResultsButton.accessibilityIdentifier = "show-meeting-search-results"
          showResultsButton.addTarget(self, action: #selector(showSearchResults), for: .touchUpInside)
          let searchControls = UIStackView(arrangedSubviews: [searchTextField, showResultsButton])
          searchControls.axis = .vertical
          searchControls.spacing = 12
          searchContainer.addSubview(searchControls)
          searchControls.translatesAutoresizingMaskIntoConstraints = false
          NSLayoutConstraint.activate([
               searchTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
               showResultsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
               searchControls.topAnchor.constraint(equalTo: searchContainer.contentLayoutGuide.topAnchor),
               searchControls.leadingAnchor.constraint(equalTo: searchContainer.contentLayoutGuide.leadingAnchor),
               searchControls.trailingAnchor.constraint(equalTo: searchContainer.contentLayoutGuide.trailingAnchor),
               searchControls.bottomAnchor.constraint(equalTo: searchContainer.contentLayoutGuide.bottomAnchor),
               searchControls.widthAnchor.constraint(equalTo: searchContainer.frameLayoutGuide.widthAnchor)
          ])

          let controls = UIStackView(arrangedSubviews: [actions, weekdaySelector])
          controls.axis = .vertical
          controls.spacing = 8
          for subview in [controls, timeTableView, searchContainer] {
               view.addSubview(subview)
               subview.translatesAutoresizingMaskIntoConstraints = false
          }
          let margins = view.layoutMarginsGuide
          NSLayoutConstraint.activate([
               controls.topAnchor.constraint(equalTo: margins.topAnchor),
               controls.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
               controls.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
               timeTableView.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 8),
               timeTableView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
               timeTableView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
               timeTableView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
               searchContainer.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 8),
               searchContainer.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
               searchContainer.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
               searchContainer.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
          ])
          reloadTimes()
          setSearchMode(mainController?.isNameSearchMode ?? false)
     }

     override func viewDidAppear(_ inIsAnimated: Bool) {
          super.viewDidAppear(inIsAnimated)
          if isShowingSearch { searchTextField.becomeFirstResponder() }
     }

     override func viewWillDisappear(_ inIsAnimated: Bool) {
          super.viewWillDisappear(inIsAnimated)
          searchTextField.resignFirstResponder()
     }

     override func viewDidLayoutSubviews() {
          super.viewDidLayoutSubviews()
          // Segment titles can be abbreviated visually while VoiceOver speaks the full weekday.
          for index in 0..<7 {
               let day = mainController?.unMapWeekday(index + 1) ?? ((Calendar.current.firstWeekday + index - 1) % 7 + 1)
               if let element = weekdaySelector.accessibilityElement(at: index) as? NSObject {
                    element.accessibilityLabel = Calendar.current.standaloneWeekdaySymbols[day - 1]
                    element.accessibilityHint = "SLUG-ACC-POPOVER-WEEKDAY-HINT".localizedVariant
               }
          }
          if !isShowingSearch, !didScrollToSelection, !timeSlots.isEmpty, timeTableView.bounds.height > 0 {
               let index = mainController?.getNearestIndex(dayIndex: selectedDayIndex, time: selection?.time ?? mainController?.lastTime ?? 0) ?? 0
               timeTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: false)
               didScrollToSelection = true
          }
     }

     /** Uses the same sorted, distinct start times as the main meeting pages. */
     private func reloadTimes() {
          let dailyMeetings = mainController?.getDailyMeetings(for: selectedDayIndex) ?? [:]
          timeSlots = dailyMeetings.keys.sorted()
          timeCounts = dailyMeetings.mapValues { $0.count }
          let formatter = DateFormatter()
          formatter.locale = .current
          formatter.timeZone = .autoupdatingCurrent
          formatter.timeStyle = .short
          formatter.dateStyle = .none
          timeTitles = dailyMeetings.reduce(into: [:]) { titles, entry in
               if let meeting = entry.value.first {
                    titles[entry.key] = formatter.string(from: meeting.nextOccurrenceDateFast())
               }
          }
          weekdayLabel.text = Calendar.current.standaloneWeekdaySymbols[selectedDayIndex - 1]
          timeTableView.backgroundView = timeSlots.isEmpty ? emptyLabel : nil
          timeTableView.reloadData()
          didScrollToSelection = false
          view.setNeedsLayout()
     }

     @objc private func selectWeekday() {
          selectedDayIndex = mainController?.unMapWeekday(weekdaySelector.selectedSegmentIndex + 1) ?? 1
          reloadTimes()
          UISelectionFeedbackGenerator().selectionChanged()
     }

     @objc private func selectNow() {
          mainController?.openTo(dayIndex: 0)
          dismiss(animated: true)
     }

     @objc private func selectSearch() {
          setSearchMode(!isShowingSearch)
          if isShowingSearch { searchTextField.becomeFirstResponder() }
     }

     /** Switches the popover's controls without dismissing it or clearing the query. */
     private func setSearchMode(_ inIsSearching: Bool) {
          isShowingSearch = inIsSearching
          mainController?.isNameSearchMode = inIsSearching
          weekdaySelector.isHidden = inIsSearching
          timeTableView.isHidden = inIsSearching
          searchContainer.isHidden = !inIsSearching
          weekdayLabel.text = inIsSearching ? "SLUG-SEARCH-MODE-TITLE".localizedVariant : Calendar.current.standaloneWeekdaySymbols[selectedDayIndex - 1]
          var configuration = searchButton.configuration
          configuration?.image = UIImage(systemName: inIsSearching ? "xmark.circle" : "magnifyingglass")
          searchButton.configuration = configuration
          searchButton.accessibilityLabel = (inIsSearching ? "SLUG-ACC-CLOSE-SEARCH-BUTTON-LABEL" : "SLUG-ACC-WEEKDAY-SWITCH-8-LABEL").localizedVariant
          searchButton.accessibilityHint = (inIsSearching ? "SLUG-ACC-CLOSE-SEARCH-BUTTON-HINT" : "SLUG-ACC-WEEKDAY-SWITCH-8-HINT").localizedVariant
          preferredContentSize = inIsSearching ? Self.searchSize : Self.browsingSize
          if !inIsSearching {
               searchTextField.resignFirstResponder()
               timeTableView.reloadData()
               didScrollToSelection = false
          }
          view.setNeedsLayout()
     }

     @objc private func searchTextChanged() {
          mainController?.searchText = searchTextField.text ?? ""
     }

     @objc private func showSearchResults() {
          searchTextChanged()
          searchTextField.resignFirstResponder()
          dismiss(animated: true)
     }

     func adaptivePresentationStyle(for inController: UIPresentationController) -> UIModalPresentationStyle { .none }

     func adaptivePresentationStyle(for inController: UIPresentationController, traitCollection inTraitCollection: UITraitCollection) -> UIModalPresentationStyle { .none }

     override func accessibilityPerformEscape() -> Bool {
          dismiss(animated: true)
          return true
     }
}

/* ###################################################################################################################################### */
// MARK: Meeting Name Search
/* ###################################################################################################################################### */
extension VMF_DayTimeSelectionViewController: UITextFieldDelegate {
     func textFieldShouldReturn(_ inTextField: UITextField) -> Bool {
          showSearchResults()
          return true
     }
}

/* ###################################################################################################################################### */
// MARK: Available Meeting Times
/* ###################################################################################################################################### */
extension VMF_DayTimeSelectionViewController: UITableViewDataSource, UITableViewDelegate {
     func tableView(_ inTableView: UITableView, numberOfRowsInSection inSection: Int) -> Int { timeSlots.count }

     func tableView(_ inTableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
          let cell = inTableView.dequeueReusableCell(withIdentifier: "meeting-time", for: inIndexPath)
          let time = timeSlots[inIndexPath.row]
          let title = timeTitles[time] ?? ""
          let main = mainController
          let isSelected = main?.isNameSearchMode == false && selection?.dayIndex == selectedDayIndex && selection?.time == time
          let count = NumberFormatter.localizedString(from: NSNumber(value: timeCounts[time] ?? 0), number: .decimal)
          var content = cell.defaultContentConfiguration()
          content.text = title
          content.textProperties.font = .preferredFont(forTextStyle: .body)
          content.textProperties.adjustsFontForContentSizeCategory = true
          content.textProperties.color = view.tintColor
          content.secondaryText = count
          content.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
          content.secondaryTextProperties.adjustsFontForContentSizeCategory = true
          content.secondaryTextProperties.color = view.tintColor
          content.prefersSideBySideTextAndSecondaryText = true
          cell.contentConfiguration = content
          cell.tintColor = view.tintColor
          // Reserve the same trailing space so the counts line up on every row.
          let checkmark = (cell.accessoryView as? UIImageView) ?? UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
          checkmark.image = isSelected ? UIImage(systemName: "checkmark") : nil
          checkmark.contentMode = .center
          checkmark.isAccessibilityElement = false
          cell.accessoryView = checkmark
          cell.accessoryType = .none
          cell.accessibilityLabel = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant,
                                          Calendar.current.weekdaySymbols[selectedDayIndex - 1], title)
          cell.accessibilityValue = String(format: "SLUG-ACC-TIME-SLOT-COUNT-FORMAT".localizedVariant, count)
          cell.accessibilityHint = "SLUG-ACC-SELECT-TIME-HINT".localizedVariant
          cell.accessibilityTraits = isSelected ? [.button, .selected] : .button
          cell.accessibilityIdentifier = "meeting-time-\(selectedDayIndex)-\(time)"
          return cell
     }

     func tableView(_ inTableView: UITableView, didSelectRowAt inIndexPath: IndexPath) {
          guard timeSlots.indices.contains(inIndexPath.row) else { return }
          mainController?.openTo(dayIndex: selectedDayIndex, time: timeSlots[inIndexPath.row])
          dismiss(animated: true)
     }
}
