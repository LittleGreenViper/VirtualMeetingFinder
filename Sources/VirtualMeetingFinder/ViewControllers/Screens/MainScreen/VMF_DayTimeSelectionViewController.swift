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
     /// Preferred popover size while browsing weekday start times.
     static let browsingSize = CGSize(width: 600, height: 500)
     /// Preferred popover height while entering a meeting-name query.
     private static let searchHeight: CGFloat = 180
     /// Opaque light/dark background shared with the popover outline.
     static let backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? .black : .white }

     /// Owns the meeting data and receives time selections and live search changes.
     weak var mainController: VMF_MainViewController?

     private let backgroundDimmingView: UIView = {
          let dimmingView = UIView()
          dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.32)
          dimmingView.alpha = 0
          dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          dimmingView.isUserInteractionEnabled = false
          dimmingView.accessibilityElementsHidden = true
          return dimmingView
     }()

     private let weekdaySelector = VMF_WeekdaySegmentedControl()
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

     /// Builds the picker and search controls from the main screen's current selection.
     override func viewDidLoad() {
          super.viewDidLoad()
          view.backgroundColor = Self.backgroundColor
          view.isOpaque = true
          view.layer.cornerRadius = VMF_DayTimePopoverBackgroundView.cornerRadius - VMF_DayTimePopoverBackgroundView.borderWidth / 2
          view.clipsToBounds = true
          popoverPresentationController?.backgroundColor = Self.backgroundColor
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
          weekdayLabel.accessibilityIdentifier = "popover-weekday-heading"
          weekdayLabel.isUserInteractionEnabled = true
          let doubleTap = UITapGestureRecognizer(target: self, action: #selector(selectPreviousTimeSlot))
          doubleTap.numberOfTapsRequired = 2
          weekdayLabel.addGestureRecognizer(doubleTap)
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
          weekdaySelector.isAccessibilityElement = false
          weekdaySelector.weekdayAccessibilityElements = (0..<7).map { index in
               let day = mainController?.unMapWeekday(index + 1) ?? ((Calendar.current.firstWeekday + index - 1) % 7 + 1)
               return VMF_WeekdayAccessibilityElement(selector: weekdaySelector, index: index,
                                                     label: Calendar.current.standaloneWeekdaySymbols[day - 1])
          }
          weekdaySelector.selectedSegmentTintColor = accentColor
          let weekdayFont = UIFont.systemFont(ofSize: 16, weight: .medium)
          weekdaySelector.setTitleTextAttributes([.foregroundColor: accentColor, .font: weekdayFont], for: .normal)
          weekdaySelector.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: weekdayFont], for: .selected)
          weekdaySelector.setTitleTextAttributes([.foregroundColor: UIColor.tertiaryLabel, .font: weekdayFont], for: .disabled)
          let weekdayHeight = weekdaySelector.heightAnchor.constraint(equalToConstant: 36)
          weekdayHeight.priority = UILayoutPriority(999)
          weekdayHeight.isActive = true
          weekdaySelector.addTarget(self, action: #selector(selectWeekday), for: .valueChanged)

          timeTableView.dataSource = self
          timeTableView.delegate = self
          timeTableView.backgroundColor = Self.backgroundColor
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
          searchTextField.accessibilityLabel = "SLUG-ACC-MEETING-NAME-MI-LABEL".localizedVariant
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
          showResultsButton.accessibilityLabel = "SLUG-SHOW-SEARCH-RESULTS".localizedVariant
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

     /// Mutes the presenting screen while UIKit keeps the popover above it.
     override func viewWillAppear(_ inIsAnimated: Bool) {
          super.viewWillAppear(inIsAnimated)
          if let background = mainController?.navigationController?.viewIfLoaded ?? mainController?.viewIfLoaded {
               backgroundDimmingView.frame = background.bounds
               background.addSubview(backgroundDimmingView)
               setBackgroundDimmingVisible(true)
          }
     }

     /// Focuses the retained search field when the popover opens in search mode.
     override func viewDidAppear(_ inIsAnimated: Bool) {
          super.viewDidAppear(inIsAnimated)
          if isShowingSearch { searchTextField.becomeFirstResponder() }
     }

     /// Releases the search keyboard and confirms dismissal with a sharp haptic while the scene is active.
     override func viewWillDisappear(_ inIsAnimated: Bool) {
          super.viewWillDisappear(inIsAnimated)
          setBackgroundDimmingVisible(false)
          searchTextField.resignFirstResponder()
          if isBeingDismissed, view.window?.windowScene?.activationState == .foregroundActive {
               mainController?.hardImpactHaptic()
          }
     }

     /// Clears the dimming layer after every dismissal path.
     override func viewDidDisappear(_ inIsAnimated: Bool) {
          super.viewDidDisappear(inIsAnimated)
          backgroundDimmingView.removeFromSuperview()
     }

     private func setBackgroundDimmingVisible(_ inIsVisible: Bool) {
          let dimmingView = backgroundDimmingView
          guard let background = dimmingView.superview else { return }

          let alpha: CGFloat = inIsVisible ? 1 : 0
          if transitionCoordinator?.animateAlongsideTransition(in: background, animation: { _ in dimmingView.alpha = alpha }) != true {
               dimmingView.alpha = alpha
          }
     }

     /// Fits visual weekday titles and scrolls to the selected time. Spoken names stay unabbreviated.
     override func viewDidLayoutSubviews() {
          super.viewDidLayoutSubviews()
          updateWeekdayTitles()
          if !isShowingSearch, !didScrollToSelection, !timeSlots.isEmpty, timeTableView.bounds.height > 0 {
               let index = mainController?.getNearestIndex(dayIndex: selectedDayIndex, time: selection?.time ?? mainController?.lastTime ?? 0) ?? 0
               timeTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: false)
               didScrollToSelection = true
          }
     }

     /** Keeps the larger font legible on narrow screens in every supported locale. */
     private func updateWeekdayTitles() {
          guard weekdaySelector.bounds.width > 0,
                let font = weekdaySelector.titleTextAttributes(for: .normal)?[.font] as? UIFont else { return }
          let calendar = Calendar.current
          // Leave room for UIKit's title padding as well as the inset selection background.
          let availableWidth = weekdaySelector.bounds.width / 7 - 20
          let shortTitles = calendar.shortStandaloneWeekdaySymbols
          let shortTitlesFit = shortTitles.allSatisfy { ($0 as NSString).size(withAttributes: [.font: font]).width <= availableWidth }
          let titles = shortTitlesFit ? shortTitles : calendar.veryShortStandaloneWeekdaySymbols
          for index in 0..<7 {
               let day = mainController?.unMapWeekday(index + 1) ?? ((calendar.firstWeekday + index - 1) % 7 + 1)
               if weekdaySelector.titleForSegment(at: index) != titles[day - 1] {
                    weekdaySelector.setTitle(titles[day - 1], forSegmentAt: index)
               }
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

     /** Resets the day and time to the latest available start at or before now, keeping the picker open. */
     @objc private func selectPreviousTimeSlot() {
          guard !isShowingSearch,
                let main = mainController,
                let slot = main.adjacentTimeSlot(fromDay: 0, timeIndex: 0, forward: false),
                let time = main.getTimeOf(dayIndex: slot.dayIndex, timeIndex: slot.timeIndex) else { return }
          selectedDayIndex = slot.dayIndex
          selection = (slot.dayIndex, time)
          weekdaySelector.selectedSegmentIndex = main.mapWeekday(slot.dayIndex) - 1
          main.openTo(dayIndex: slot.dayIndex, time: time)
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
          weekdayLabel.accessibilityHint = inIsSearching ? nil : "SLUG-ACC-LATEST-TIME-HINT".localizedVariant
          weekdayLabel.accessibilityCustomActions = inIsSearching ? nil : [UIAccessibilityCustomAction(name: "SLUG-ACC-LATEST-TIME-LABEL".localizedVariant) { [weak self] _ in
               guard let self = self else { return false }
               self.selectPreviousTimeSlot()
               return true
          }]
          var configuration = searchButton.configuration
          configuration?.image = UIImage(systemName: inIsSearching ? "xmark.circle" : "magnifyingglass")
          searchButton.configuration = configuration
          searchButton.accessibilityLabel = (inIsSearching ? "SLUG-ACC-CLOSE-SEARCH-BUTTON-LABEL" : "SLUG-ACC-WEEKDAY-SWITCH-8-LABEL").localizedVariant
          searchButton.accessibilityHint = (inIsSearching ? "SLUG-ACC-CLOSE-SEARCH-BUTTON-HINT" : "SLUG-ACC-WEEKDAY-SWITCH-8-HINT").localizedVariant
          preferredContentSize.height = inIsSearching ? Self.searchHeight : Self.browsingSize.height
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

     /// Preserves popover presentation in compact layouts.
     func adaptivePresentationStyle(for inController: UIPresentationController) -> UIModalPresentationStyle { .none }

     /// Preserves the popover when the presentation environment's traits change.
     func adaptivePresentationStyle(for inController: UIPresentationController, traitCollection inTraitCollection: UITraitCollection) -> UIModalPresentationStyle { .none }

     /// Dismisses the picker for the standard accessibility escape gesture.
     override func accessibilityPerformEscape() -> Bool {
          dismiss(animated: true)
          return true
     }
}

/// Exposes a stable accessibility container even when UIKit rebuilds its visual segments.
private final class VMF_WeekdaySegmentedControl: VMF_StyledSegmentedControl {
     var weekdayAccessibilityElements: [UIAccessibilityElement] = []

     override func accessibilityElementCount() -> Int { weekdayAccessibilityElements.count }

     override func accessibilityElement(at inIndex: Int) -> Any? {
          weekdayAccessibilityElements.indices.contains(inIndex) ? weekdayAccessibilityElements[inIndex] : nil
     }

     override func index(ofAccessibilityElement inElement: Any) -> Int {
          guard let element = inElement as? UIAccessibilityElement else { return NSNotFound }
          return weekdayAccessibilityElements.firstIndex(where: { $0 === element }) ?? NSNotFound
     }
}

/**
 A full-name weekday target independent of UIKit's private segment subviews.
 Its frame follows the segment's layout direction and its selected trait follows the control.
 */
private final class VMF_WeekdayAccessibilityElement: UIAccessibilityElement {
     private weak var selector: UISegmentedControl?
     private let index: Int

     init(selector inSelector: UISegmentedControl, index inIndex: Int, label inLabel: String) {
          selector = inSelector
          index = inIndex
          super.init(accessibilityContainer: inSelector)
          accessibilityLabel = inLabel
          accessibilityHint = "SLUG-ACC-POPOVER-WEEKDAY-HINT".localizedVariant
     }

     override var accessibilityTraits: UIAccessibilityTraits {
          get {
               var traits: UIAccessibilityTraits = .button
               if selector?.selectedSegmentIndex == index { traits.insert(.selected) }
               if selector?.isEnabled == false { traits.insert(.notEnabled) }
               return traits
          }
          set { super.accessibilityTraits = newValue }
     }

     override var accessibilityFrameInContainerSpace: CGRect {
          get {
               guard let selector = selector, selector.numberOfSegments > index else { return .zero }
               let width = selector.bounds.width / CGFloat(selector.numberOfSegments)
               let visualIndex = selector.effectiveUserInterfaceLayoutDirection == .rightToLeft ? selector.numberOfSegments - index - 1 : index
               return CGRect(x: selector.bounds.minX + CGFloat(visualIndex) * width,
                             y: selector.bounds.minY, width: width, height: selector.bounds.height)
          }
          set { super.accessibilityFrameInContainerSpace = newValue }
     }

     override func accessibilityActivate() -> Bool {
          guard let selector = selector, selector.isEnabled,
                selector.numberOfSegments > index, selector.isEnabledForSegment(at: index) else { return false }
          selector.selectedSegmentIndex = index
          selector.sendActions(for: .valueChanged)
          return true
     }
}

/* ###################################################################################################################################### */
// MARK: Popover Outline
/* ###################################################################################################################################### */
/** Draws the opaque body and pointer as one shape, with a continuous one-point label-colored border. */
final class VMF_DayTimePopoverBackgroundView: UIPopoverBackgroundView {
     /// Width in points of the continuous body-and-arrow outline.
     static let borderWidth: CGFloat = 1
     /// Preferred radius in points of the popover body corners.
     static let cornerRadius: CGFloat = 40

     private var storedArrowOffset: CGFloat = 0
     private var storedArrowDirection: UIPopoverArrowDirection = .up

     /// Arrow displacement from the center, supplied by UIKit.
     override var arrowOffset: CGFloat {
          get { storedArrowOffset }
          set { storedArrowOffset = newValue; setNeedsDisplay() }
     }

     /// Arrow orientation supplied by UIKit.
     override var arrowDirection: UIPopoverArrowDirection {
          get { storedArrowDirection }
          set { storedArrowDirection = newValue; setNeedsDisplay() }
     }

     /// Width in points of the pointer's base.
     override class func arrowBase() -> CGFloat { 26 }
     /// Height in points reserved for the pointer.
     override class func arrowHeight() -> CGFloat { 13 }
     /// Insets content by the outline width so it does not overlap the border.
     override class func contentViewInsets() -> UIEdgeInsets {
          UIEdgeInsets(top: borderWidth, left: borderWidth, bottom: borderWidth, right: borderWidth)
     }

     /// Configures transparent, bounds-aware drawing for a programmatically created outline.
     override init(frame: CGRect) {
          super.init(frame: frame)
          configureDrawing()
     }

     /// Configures drawing after decoding.
     required init?(coder: NSCoder) {
          super.init(coder: coder)
          configureDrawing()
     }

     private func configureDrawing() {
          backgroundColor = .clear
          isOpaque = false
          contentMode = .redraw
     }

     /// Draws one filled outline, rotated to match UIKit's arrow direction.
     override func draw(_ inRect: CGRect) {
          let isHorizontal = arrowDirection == .left || arrowDirection == .right
          let size = isHorizontal ? CGSize(width: bounds.height, height: bounds.width) : bounds.size
          let inset = Self.borderWidth / 2
          let body = CGRect(x: inset, y: Self.arrowHeight() + inset,
                            width: size.width - Self.borderWidth, height: size.height - Self.arrowHeight() - Self.borderWidth)
          guard body.width > 0, body.height > 0 else { return }
          let radius = min(Self.cornerRadius, body.width / 2, body.height / 2)
          let halfBase = min(Self.arrowBase() / 2, max(0, body.width / 2 - radius))
          let offset = arrowDirection == .down || arrowDirection == .left ? -arrowOffset : arrowOffset
          let center = max(body.minX + radius + halfBase, min(body.maxX - radius - halfBase, body.midX + offset))
          let path = UIBezierPath()
          path.move(to: CGPoint(x: body.minX + radius, y: body.minY))
          path.addLine(to: CGPoint(x: center - halfBase, y: body.minY))
          path.addCurve(to: CGPoint(x: center, y: inset),
                        controlPoint1: CGPoint(x: center - halfBase / 2, y: body.minY),
                        controlPoint2: CGPoint(x: center - 3, y: inset))
          path.addCurve(to: CGPoint(x: center + halfBase, y: body.minY),
                        controlPoint1: CGPoint(x: center + 3, y: inset),
                        controlPoint2: CGPoint(x: center + halfBase / 2, y: body.minY))
          path.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
          path.addArc(withCenter: CGPoint(x: body.maxX - radius, y: body.minY + radius), radius: radius,
                      startAngle: -.pi / 2, endAngle: 0, clockwise: true)
          path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
          path.addArc(withCenter: CGPoint(x: body.maxX - radius, y: body.maxY - radius), radius: radius,
                      startAngle: 0, endAngle: .pi / 2, clockwise: true)
          path.addLine(to: CGPoint(x: body.minX + radius, y: body.maxY))
          path.addArc(withCenter: CGPoint(x: body.minX + radius, y: body.maxY - radius), radius: radius,
                      startAngle: .pi / 2, endAngle: .pi, clockwise: true)
          path.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
          path.addArc(withCenter: CGPoint(x: body.minX + radius, y: body.minY + radius), radius: radius,
                      startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
          path.close()

          // Draw one upward-pointing outline, then rotate it for UIKit's actual arrow direction.
          switch arrowDirection {
          case .down: path.apply(CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: bounds.width, ty: bounds.height))
          case .left: path.apply(CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: bounds.height))
          case .right: path.apply(CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: bounds.width, ty: 0))
          default: break
          }
          VMF_DayTimeSelectionViewController.backgroundColor.resolvedColor(with: traitCollection).setFill()
          path.fill()
          UIColor.label.resolvedColor(with: traitCollection).setStroke()
          path.lineWidth = Self.borderWidth
          path.lineJoinStyle = .round
          path.stroke()
     }
}

/* ###################################################################################################################################### */
// MARK: Meeting Name Search
/* ###################################################################################################################################### */
extension VMF_DayTimeSelectionViewController: UITextFieldDelegate {
     /// Keeps the live query results and dismisses the popover when Search is pressed.
     func textFieldShouldReturn(_ inTextField: UITextField) -> Bool {
          showSearchResults()
          return true
     }
}

/* ###################################################################################################################################### */
// MARK: Available Meeting Times
/* ###################################################################################################################################### */
extension VMF_DayTimeSelectionViewController: UITableViewDataSource, UITableViewDelegate {
     /// Returns the number of distinct start times for the selected weekday.
     func tableView(_ inTableView: UITableView, numberOfRowsInSection inSection: Int) -> Int { timeSlots.count }

     /// Presents a local start time, meeting count, and accessible selection state.
     func tableView(_ inTableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
          let cell = inTableView.dequeueReusableCell(withIdentifier: "meeting-time", for: inIndexPath)
          cell.backgroundColor = Self.backgroundColor
          let time = timeSlots[inIndexPath.row]
          let title = timeTitles[time] ?? ""
          let main = mainController
          let isSelected = main?.isNameSearchMode == false && selection?.dayIndex == selectedDayIndex && selection?.time == time
          let foregroundColor: UIColor = isSelected ? Self.backgroundColor : view.tintColor
          let textStyle: UIFont.TextStyle = isSelected ? .headline : .body
          var background = UIBackgroundConfiguration.clear()
          background.backgroundColor = isSelected ? view.tintColor : Self.backgroundColor
          background.cornerRadius = isSelected ? 6 : 0
          background.backgroundInsets = isSelected ? NSDirectionalEdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8) : .zero
          cell.backgroundConfiguration = background
          let count = NumberFormatter.localizedString(from: NSNumber(value: timeCounts[time] ?? 0), number: .decimal)
          var content = cell.defaultContentConfiguration()
          // Match the accessory's trailing spacing so both ends of the highlight have the same padding.
          content.directionalLayoutMargins.leading = 24
          content.text = title
          content.textProperties.font = .preferredFont(forTextStyle: textStyle)
          content.textProperties.adjustsFontForContentSizeCategory = true
          content.textProperties.color = foregroundColor
          content.secondaryText = count
          content.secondaryTextProperties.font = .preferredFont(forTextStyle: textStyle)
          content.secondaryTextProperties.adjustsFontForContentSizeCategory = true
          content.secondaryTextProperties.color = foregroundColor
          content.prefersSideBySideTextAndSecondaryText = true
          cell.contentConfiguration = content
          cell.tintColor = foregroundColor
          // Reserve the same trailing space so the counts line up on every row.
          let checkmark = (cell.accessoryView as? UIImageView) ?? UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
          checkmark.image = isSelected ? UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)) : nil
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

     /// Opens the chosen weekday/start time in the main screen and dismisses the picker.
     func tableView(_ inTableView: UITableView, didSelectRowAt inIndexPath: IndexPath) {
          guard timeSlots.indices.contains(inIndexPath.row) else { return }
          mainController?.openTo(dayIndex: selectedDayIndex, time: timeSlots[inIndexPath.row])
          dismiss(animated: true)
     }
}
