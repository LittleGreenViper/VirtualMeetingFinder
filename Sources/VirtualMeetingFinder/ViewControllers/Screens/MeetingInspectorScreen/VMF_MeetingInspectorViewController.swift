/*
 © Copyright 2024, Little Green Viper Software Development LLC
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
import EventKit
import MapKit
import CoreLocation
import SwiftBMLSDK
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Meeting Inspector View Controller -
/* ###################################################################################################################################### */
/**
 This displays one meeting.
 */
class VMF_MeetingInspectorViewController: VMF_BaseViewController {
     /* ################################################################## */
     /**
      This is the font to use for the format item key.
      */
     private static let _formatKeyFont: UIFont? = .boldSystemFont(ofSize: 20)
     
     /* ################################################################## */
     /**
      This is the font to use for the format item name.
      */
     private static let _formatNameFont: UIFont? = .boldSystemFont(ofSize: 17)
     
     /* ################################################################## */
     /**
      This is the font to use for the format item description.
      */
     private static let _formatDescriptionFont: UIFont? = .italicSystemFont(ofSize: 15)
     
     /* ################################################################## */
     /**
      The duration of the open/close animation.
      */
     private static let _openingAnimationPeriodInSeconds = TimeInterval(0.25)
     
     /* ################################################################## */
     /**
      The width and height of the map
      */
     private static let _mapRegionSizeInDegrees = CLLocationDegrees(0.25)
     
     /* ################################################################## */
     /**
      This is how many display units wide, we make the format key column.
      */
     private static let _formatKeyWidth = CGFloat(50)
     
     /* ################################################################## */
     /**
      This is how many display units, vertically, will separate the top of a format item, with its predecessor.
      */
     private static let _formatSeparatorSpace = CGFloat(8)
     
     /* ################################################################## */
     /**
      This is how much "breathing room" we give stuff in a format item (display units).
      */
     private static let _formatInternalSeparatorSpace = CGFloat(4)
     
     /* ################################################################## */
     /**
      This is the height of the "Address" section of the in-person meeting display, when open.
      */
     private static let _addressSectionOpenHeight = CGFloat(100)
     
     /* ################################################################## */
     /**
      The image to use, for the bar button item, of a meeting that is selected for attendance.
      */
     private static let _checkedImage = UIImage(systemName: "checkmark.square.fill")
     
     /* ################################################################## */
     /**
      The image to use, for the bar button item, of a meeting that is not selected for attendance.
      */
     private static let _uncheckedImage = UIImage(systemName: "square")
     
     /* ################################################################## */
     /**
      The font to use for the "I Attend" bar button item.
      */
     private static let _barButtonLabelFont = UIFont.systemFont(ofSize: 17)
     
     /* ################################################################## */
     /**
      Set to true, after our first layout. We use this to prevent unnecessary animation delays.
      */
     private var _openSezMe = false
     
     /* ################################################################## */
     /**
      This references our map height constraint. We use it for expanding and collapsing the map.
      */
     @IBOutlet weak var mapHeightConstraint: NSLayoutConstraint?
     
     /* ################################################################## */
     /**
      This references our in-person address height constraint. We use it for expanding and collapsing the map.
      */
     @IBOutlet weak var addressHeightConstraint: NSLayoutConstraint?

     /* ################################################################## */
     /**
      Set to true, to open the formats section.
      */
     var isFormatsOpen = false {
          didSet {
               guard _openSezMe else {
                    formatContainerView?.isHidden = !isFormatsOpen
                    return
               }
               let imageRotation = isFormatsOpen ? Double.pi / 2 : 0
               view?.layoutIfNeeded()
               UIView.animate(withDuration: Self._openingAnimationPeriodInSeconds) {
                    self.formatHeaderDisclosureTriangle?.transform = CGAffineTransform(rotationAngle: CGFloat(imageRotation))
                    self.formatContainerView?.isHidden = !self.isFormatsOpen
                    self.view?.layoutIfNeeded()
               }
          }
     }
     
     /* ################################################################## */
     /**
      Set to true, to open the formats section.
      */
     var isLocationOpen = false {
          didSet {
               guard _openSezMe else {
                    inPersonContainer?.isHidden = !isLocationOpen
                    locationMapView?.isHidden = !isLocationOpen
                    return
               }
               let imageRotation = isLocationOpen ? Double.pi / 2 : 0
               view?.layoutIfNeeded()
               if self.isLocationOpen {
                    self.locationMapView?.isHidden = false
                    self.inPersonContainer?.isHidden = false
               }
               UIView.animate(withDuration: Self._openingAnimationPeriodInSeconds, animations: {
                    self.inPersonDisclosureTriangle?.transform = CGAffineTransform(rotationAngle: CGFloat(imageRotation))
                    if !self.isLocationOpen {
                         self.addressHeightConstraint?.constant = 0
                         self.mapHeightConstraint?.constant = 0
                    } else if let mapView = self.locationMapView {
                         self.addressHeightConstraint?.constant = Self._addressSectionOpenHeight
                         self.mapHeightConstraint?.constant = mapView.bounds.size.width
                    }
                    
                    self.view?.layoutIfNeeded()
               }, completion: { _ in
                    self.locationMapView?.isHidden = !self.isLocationOpen
                    self.inPersonContainer?.isHidden = !self.isLocationOpen
               })
          }
     }
     
     /* ################################################################## */
     /**
      The meeting that this screen is displaying.
      */
     var meeting: MeetingInstance?
     
     /* ################################################################## */
     /**
      The controller that "owns" this instance.
      */
     var myController: (any VMF_EmbeddedTableControllerProtocol)?
     
     /* ################################################################## */
     /**
      This will allow us to add events to the Calendar, without leaving this app.
      */
     let eventStore = EKEventStore()
     
     /* ################################################################## */
     /**
      The label that displays the meeting name.
      */
     @IBOutlet weak var meetingNameLabel: UILabel?
     
     /* ################################################################## */
     /**
      The label that displays the meeting start time and weekday.
      */
     @IBOutlet weak var timeAndDayLabel: UILabel?
     
     /* ################################################################## */
     /**
      This label is displayed if the meeting is in progress.
      */
     @IBOutlet weak var inProgressLabel: UILabel?
     
     /* ################################################################## */
     /**
      The label that displays the meeting timezone.
      */
     @IBOutlet weak var timeZoneLabel: UILabel?
     
     /* ################################################################## */
     /**
      This contains any additional comments.
      */
     @IBOutlet weak var commentsTextView: UITextView?
     
     /* ################################################################## */
     /**
      This contains the tappable links.
      */
     @IBOutlet weak var linkContainer: UIView?
     
     /* ################################################################## */
     /**
      The vertical container for the phone button.
      */
     @IBOutlet weak var phoneButtonContainer: UIView?
     
     /* ################################################################## */
     /**
      This is the phone in button's label.
      */
     @IBOutlet weak var phoneLabelButton: UILabel?
     
     /* ################################################################## */
     /**
      The vertical container for the globe button.
      */
     @IBOutlet weak var globeButtonContainer: UIView?
     
     /* ################################################################## */
     /**
      This is the Web link button's label.
      */
     @IBOutlet weak var globeLabelButton: UILabel?
     
     /* ################################################################## */
     /**
      The vertical container for the video button.
      */
     @IBOutlet weak var videoButtonContainer: UIView?
     
     /* ################################################################## */
     /**
      This is the video link button's label.
      */
     @IBOutlet weak var videoLabelButton: UILabel?
     
     /* ################################################################## */
     /**
      Contains any phone info that can't be turned into a URL.
      */
     @IBOutlet weak var phoneInfoTextView: UITextView?
     
     /* ################################################################## */
     /**
      This has any extra info for virtual meetings.
      */
     @IBOutlet weak var virtualExtraInfoTextView: UITextView?
     
     /* ################################################################## */
     /**
      This contains the header for the in-person location information.
      */
     @IBOutlet weak var inPersonHeader: UIView?
     
     /* ################################################################## */
     /**
      This is the disclosure triangle for the in-person section.
      */
     @IBOutlet weak var inPersonDisclosureTriangle: UIImageView?
     
     /* ################################################################## */
     /**
      Contains the in-person meeting stuff.
      */
     @IBOutlet weak var inPersonContainer: UIStackView?
     
     /* ################################################################## */
     /**
      The heading for the in-person meeting stuff.
      */
     @IBOutlet weak var inPersonHeaderLabel: UILabel?
     
     /* ################################################################## */
     /**
      The text view that displays an address for in-person meetings.
      */
     @IBOutlet weak var inPersonAddressTextView: UITextView?
     
     /* ################################################################## */
     /**
      This has any extra info for in-person meetings.
      */
     @IBOutlet weak var inPersonExtraInfoLabel: UILabel?
     
     /* ################################################################## */
     /**
      The map view that displays the meeting location (if it has an in-person component).
      */
     @IBOutlet weak var locationMapView: MKMapView?
     
     /* ################################################################## */
     /**
      This contains the format header and disclosure triangle.
      */
     @IBOutlet weak var formatHeader: UIView?
     
     /* ################################################################## */
     /**
      The heading for the format section.
      */
     @IBOutlet weak var formatHeaderLabel: UILabel?
     
     /* ################################################################## */
     /**
      The disclosure triangle for the format section.
      */
     @IBOutlet weak var formatHeaderDisclosureTriangle: UIImageView?
     
     /* ################################################################## */
     /**
      This contains individual formats.
      */
     @IBOutlet weak var formatContainerView: UIView?
     
     /* ################################################################## */
     /**
      The navbar button to mark attendance.
      */
     @IBOutlet weak var iAttendBarButton: UIBarButtonItem?
     
     /* ################################################################## */
     /**
      The navbar button to copy the URI.
      */
     @IBOutlet weak var actionBarButton: UIBarButtonItem?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_MeetingInspectorViewController {
     /* ################################################################## */
     /**
      This creates an attendance event for the next meeting start time.
      
      > NOTE: This sets the event in the meeting's native timezone. The calendar is responsible for converting the TZ.
      
      - returns: a new EKEvent for the meeting, or nil.
      */
     var attendanceEvent: EKEvent? {
          guard var meeting = meeting,
                let appURI = meeting.linkURL
          else { return nil }
          
          let event = EKEvent(eventStore: eventStore)
          
          event.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil))
          event.title = meeting.name
          event.timeZone = meeting.timeZone
          event.startDate = meeting.getNextStartDate(isAdjusted: true)
          event.endDate = event.startDate.addingTimeInterval(meeting.duration)
          event.url = appURI
          event.location = meeting.directAppURI?.absoluteString ?? appURI.absoluteString
          event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)]
          
          var notes = [String]()
          
          if let myCurrentTimezoneName = TimeZone.current.localizedName(for: .standard, locale: .current),
             let zoneName = meeting.timeZone.localizedName(for: .standard, locale: .current),
             myCurrentTimezoneName != zoneName {
               let nativeTime = meeting.getNextStartDate(isAdjusted: false)
               notes.append(String(format: "SLUG-TIMEZONE-FORMAT".localizedVariant, zoneName, nativeTime.localizedTime))
          }
          
          if let comments = meeting.comments,
             !comments.isEmpty {
               notes.append(comments)
          }
          
          for format in meeting.formats {
               let key = format.key
               let name = format.name
               let description = format.description
               let mainString = String(format: "%@ - %@", key, name)
               notes.append("\(mainString)\n\(description)")
          }
          
          event.notes = notes.joined(separator: "\n\n")
          
          return event
     }
     
     /* ################################################################## */
     /**
      This returns the valid activities that we can have, in our action sheet.
      */
     var validActivities: [UIActivity] {
          guard let event = attendanceEvent else { return [] }
          
          var activities: [UIActivity] = [VMF_AddToCalendar_Activity(meetingEvent: event, myController: self)]
          
          if .hybrid == meeting?.meetingType || .inPerson == meeting?.meetingType,
             let coords = meeting?.coords,
             let name = (meeting?.name ?? "SLUG-NA-MEETING".localizedVariant).urlEncodedString,
             CLLocationCoordinate2DIsValid(coords) {
               var placeMark: CLPlacemark
               if let postalAddress = meeting?.inPersonAddress {
                    placeMark = MKPlacemark(coordinate: coords, postalAddress: postalAddress)
               } else {
                    placeMark = MKPlacemark(coordinate: coords)
               }
               let apps: [VMF_OpenLocationIn_Activity.LocationHandlerApp] = [
                    .appleMaps(location: placeMark, name: name),
                    .googleMaps(location: placeMark, name: name),
                    .waze(location: placeMark, name: name)
               ]
               
               apps.forEach {
                    if nil != $0.appURL {
                         activities.append(VMF_OpenLocationIn_Activity(app: $0, myController: self))
                    }
               }
          }
          
          return activities
     }
}

/* ###################################################################################################################################### */
// MARK: Static Functions
/* ###################################################################################################################################### */
extension VMF_MeetingInspectorViewController {
     /* ################################################################## */
     /**
      "Cleans" a URI.
      
      - parameter urlString: The URL, as a String. It can be optional.
      
      - returns: an optional String. This is the given URI, "cleaned up" ("https://" or "tel:" may be prefixed)
      */
     private static func _cleanURI(urlString inURLString: String?) -> String? {
          guard var ret: String = inURLString?.urlEncodedString,
                let regex = try? NSRegularExpression(pattern: "^(http://|https://|tel://|tel:)", options: .caseInsensitive)
          else { return nil }
          
          // We specifically look for tel URIs.
          let wasTel = ret.lowercased().beginsWith("tel:")
          
          // Yeah, this is pathetic, but it's quick, simple, and works a charm.
          ret = regex.stringByReplacingMatches(in: ret, options: [], range: NSRange(location: 0, length: ret.count), withTemplate: "")
          
          if ret.isEmpty {
               return nil
          }
          
          if wasTel {
               ret = "tel:" + ret
          } else {
               ret = "https://" + ret
          }
          
          return ret
     }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_MeetingInspectorViewController {
     /* ################################################################## */
     /**
      Called when the view hierarchy has loaded.
      */
     override func viewDidLoad() {
          /* ############################################################## */
          /**
           This simply strips out all non-decimal characters in the string, leaving only valid decimal digits.
           - parameter from: The string to be stripped.
           - returns: The stripped string.
           */
          func stripPhoneNumber(from inString: String) -> String {
               let allowedChars = CharacterSet(charactersIn: "0123456789,()-+")
               guard !inString.reduce(false, { current, next in
                    // The higher-order function stuff will convert each character into an aggregate integer, which then becomes a Unicode scalar. Very primitive, but shouldn't be a problem for us, as we only need a very limited ASCII set.
                    guard !current,
                          let cha = UnicodeScalar(next.unicodeScalars.map { $0.value }.reduce(0, +))
                    else { return true }
                    return !allowedChars.contains(cha)
               })
               else { return "" }
               
               return inString.decimalOnly
          }
          
          super.viewDidLoad()
          
          meetingNameLabel?.text = meeting?.name
          phoneLabelButton?.text = phoneLabelButton?.text?.localizedVariant
          globeLabelButton?.text = globeLabelButton?.text?.localizedVariant
          videoLabelButton?.text = videoLabelButton?.text?.localizedVariant
          
          actionBarButton?.accessibilityLabel = "SLUG-ACC-ACTION-BUTTON-LABEL".accessibilityLocalizedVariant
          actionBarButton?.accessibilityHint = "SLUG-ACC-ACTION-BUTTON-HINT".accessibilityLocalizedVariant
          
          navigationItem.title = ((.hybrid == meeting?.meetingType) ? "SLUG-HYBRID-MEETING" : "SLUG-VIRTUAL-MEETING").localizedVariant
          
          setTimeZone()
          setTimeAndWeekday()
          
          inProgressLabel?.text = inProgressLabel?.text?.localizedVariant
          phoneButtonContainer?.isHidden = true
          videoButtonContainer?.isHidden = true
          globeButtonContainer?.isHidden = true
          phoneInfoTextView?.isHidden = true
          commentsTextView?.isHidden = true
          linkContainer?.isHidden = true
          inPersonExtraInfoLabel?.isHidden = true
          virtualExtraInfoTextView?.isHidden = true
          
          if let formats = meeting?.formats,
             !formats.isEmpty {
               setUpFormats(formats)
          } else {
               formatHeader?.isHidden = true
               formatContainerView?.isHidden = true
          }
          
          if let comments = meeting?.comments,
             !comments.isEmpty {
               commentsTextView?.isHidden = false
               commentsTextView?.text = comments
          }
          
          var directPhoneNumberString = meeting?.directPhoneURI?.absoluteString.replacingOccurrences(of: "https://", with: "tel:") ?? ""
          
          if directPhoneNumberString.isEmpty,
             let numbersTemp = meeting?.virtualPhoneNumber {
               let numbers = stripPhoneNumber(from: numbersTemp)
               if !numbers.isEmpty {
                    directPhoneNumberString = "tel:\(numbers)"
               }
          }
          
          if !directPhoneNumberString.isEmpty {
               linkContainer?.isHidden = false
               phoneButtonContainer?.isHidden = false
          }
          
          if let directApp = meeting?.directApp {
               linkContainer?.isHidden = false
               videoButtonContainer?.isHidden = false
               videoLabelButton?.text = directApp.appName.localizedVariant
               videoButtonContainer?.accessibilityLabel = String(format: "SLUG-ACC-VIDEO-MI-LABEL-FORMAT".accessibilityLocalizedVariant, directApp.appName.localizedVariant)
               videoButtonContainer?.accessibilityHint = String(format: "SLUG-ACC-VIDEO-MI-HINT-FORMAT".accessibilityLocalizedVariant, directApp.appName.localizedVariant)
          }
          
          if let webLinkURL = meeting?.virtualURL,
             UIApplication.shared.canOpenURL(webLinkURL) {
               linkContainer?.isHidden = false
               globeButtonContainer?.isHidden = false
          }
          
          if (phoneButtonContainer?.isHidden ?? true),
             let vPhone = meeting?.virtualPhoneNumber,
             !vPhone.isEmpty {
               phoneInfoTextView?.isHidden = false
               phoneInfoTextView?.text = String(format: "SLUG-PHONE-NUMBER-FORMAT".localizedVariant, vPhone)
          }
          
          if let extraInfo = meeting?.virtualInfo,
             meeting?.comments?.lowercased() != extraInfo.lowercased(),
             !extraInfo.isEmpty {
               virtualExtraInfoTextView?.isHidden = false
               virtualExtraInfoTextView?.text = extraInfo
          }
          
          if let basicAddress = meeting?.basicInPersonAddress,
             !basicAddress.isEmpty {
               inPersonHeaderLabel?.text = inPersonHeaderLabel?.text?.localizedVariant
               inPersonHeaderLabel?.textColor = .tintColor
               inPersonAddressTextView?.text = basicAddress
               if let extraInfo = meeting?.locationInfo,
                  meeting?.comments?.lowercased() != extraInfo.lowercased(),
                  !extraInfo.isEmpty {
                    inPersonExtraInfoLabel?.isHidden = false
                    inPersonExtraInfoLabel?.text = extraInfo
               }
          }
          
          if meeting?.hasInPerson ?? false,
             let coords = meeting?.coords,
             CLLocationCoordinate2DIsValid(coords) {
               inPersonHeader?.isHidden = false
               setUpMap(coords)
          } else {
               inPersonHeader?.isHidden = true
               inPersonContainer?.isHidden = true
          }
     }
     
     /* ################################################################## */
     /**
      Called before the screen appears.
      
      - parameter inIsAnimated: True, if the appearance is animated.
      */
     override func viewWillAppear(_ inIsAnimated: Bool) {
          super.viewWillAppear(inIsAnimated)
          VMF_AppDelegate.openMeeting = self  // Let the app know that we're here.
          _openSezMe = false
          
          isFormatsOpen = false
          isLocationOpen = false
          setBarButton()
     }
     
     /* ################################################################## */
     /**
      Called before the screen disappears.
      
      - parameter inIsAnimated: True, if the disappearance is animated.
      */
     override func viewWillDisappear(_ inIsAnimated: Bool) {
          super.viewWillDisappear(inIsAnimated)
          VMF_AppDelegate.openMeeting = nil   // Let the app know that we're done.
          presentedViewController?.dismiss(animated: false)
          if isMovingFromParent {
               hardImpactHaptic()
          }
     }
     
     /* ################################################################## */
     /**
      Called when the layout is done. We use this to set the "please animate" flag.
      */
     override func viewDidLayoutSubviews() {
          super.viewDidLayoutSubviews()
          _openSezMe = true
     }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_MeetingInspectorViewController {
     /* ################################################################## */
     /**
      Sets the time and weekday (local) for the meeting.
      */
     func setTimeAndWeekday() {
          guard var meeting = meeting,
                (1..<8).contains(meeting.weekday)
          else { return }
          
          let weekday = Calendar.current.weekdaySymbols[meeting.adjustedWeekday - 1]
          let prevTime = meeting.getPreviousStartDate(isAdjusted: true)
          let startTime = meeting.getNextStartDate(isAdjusted: true)
          
          if 0 < meeting.duration {
               timeAndDayLabel?.text = String(format: "SLUG-WEEKDAY-TIME-DURATION-FORMAT".localizedVariant, weekday, startTime.localizedTime, startTime.addingTimeInterval(meeting.duration).localizedTime)
               inProgressLabel?.isHidden = !(prevTime...prevTime.addingTimeInterval(meeting.duration)).contains(.now)
          } else {
               timeAndDayLabel?.text = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant, weekday, startTime.localizedTime)
               inProgressLabel?.isHidden = true
          }
     }
     
     /* ################################################################## */
     /**
      Sets the time zone string (or hides it).
      */
     func setTimeZone() {
          guard let meeting = meeting else { return }
          
          let timeZoneString = getMeetingTimeZone(meeting)
          if !timeZoneString.isEmpty {
               timeZoneLabel?.text = timeZoneString
          } else {
               timeZoneLabel?.isHidden = true
          }
     }
     
     /* ################################################################## */
     /**
      Initializes the map view.
      
      - parameter inCoords: The center coordinate for the map (the marker location).
      */
     func setUpMap(_ inCoords: CLLocationCoordinate2D) {
          if let initialRegion = locationMapView?.regionThatFits(MKCoordinateRegion(center: inCoords, span: MKCoordinateSpan(latitudeDelta: Self._mapRegionSizeInDegrees, longitudeDelta: Self._mapRegionSizeInDegrees))) {
               locationMapView?.region = initialRegion
               locationMapView?.addAnnotation(VMF_MapAnnotation(coordinate: inCoords))
          }
     }
     
     /* ################################################################## */
     /**
      Populates the formats section.
      
      - parameter inFormats: An array of format instances.
      */
     func setUpFormats(_ inFormats: [SwiftBMLSDK_Parser.Meeting.Format]) {
          formatHeaderLabel?.text = formatHeaderLabel?.text?.localizedVariant
          formatHeaderLabel?.textColor = .tintColor
          formatHeader?.isHidden = false
          
          guard let formatContainerView = formatContainerView else { return }
          
          formatContainerView.isHidden = !isFormatsOpen
          
          formatContainerView.subviews.forEach { $0.removeFromSuperview() }
          
          var lastTopAnchor = formatContainerView.topAnchor
          
          for format in inFormats.enumerated() {
               let key = format.element.key
               let name = format.element.name
               let description = format.element.description
               
               let container = UIView()
               
               let keyLabel = UILabel()
               keyLabel.font = Self._formatKeyFont
               keyLabel.adjustsFontSizeToFitWidth = true
               keyLabel.minimumScaleFactor = 0.5
               keyLabel.text = key
               container.addSubview(keyLabel)
               keyLabel.translatesAutoresizingMaskIntoConstraints = false
               keyLabel.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
               keyLabel.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
               keyLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor).isActive = true
               keyLabel.widthAnchor.constraint(equalToConstant: Self._formatKeyWidth).isActive = true
               
               let nameLabel = UILabel()
               nameLabel.font = Self._formatNameFont
               nameLabel.numberOfLines = 0
               nameLabel.lineBreakMode = .byWordWrapping
               nameLabel.text = name
               container.addSubview(nameLabel)
               nameLabel.translatesAutoresizingMaskIntoConstraints = false
               nameLabel.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
               nameLabel.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
               nameLabel.leftAnchor.constraint(equalTo: keyLabel.rightAnchor, constant: Self._formatInternalSeparatorSpace).isActive = true
               
               let descriptionLabel = UILabel()
               descriptionLabel.font = Self._formatDescriptionFont
               descriptionLabel.text = description
               descriptionLabel.numberOfLines = 0
               descriptionLabel.lineBreakMode = .byWordWrapping
               container.addSubview(descriptionLabel)
               descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
               descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Self._formatInternalSeparatorSpace).isActive = true
               descriptionLabel.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
               descriptionLabel.leftAnchor.constraint(equalTo: keyLabel.rightAnchor, constant: Self._formatInternalSeparatorSpace).isActive = true
               descriptionLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
               
               formatContainerView.addSubview(container)
               container.translatesAutoresizingMaskIntoConstraints = false
               container.topAnchor.constraint(equalTo: lastTopAnchor, constant: Self._formatSeparatorSpace).isActive = true
               container.leftAnchor.constraint(equalTo: formatContainerView.leftAnchor).isActive = true
               container.rightAnchor.constraint(equalTo: formatContainerView.rightAnchor).isActive = true
               
               if format.offset == (inFormats.count - 1) {
                    container.bottomAnchor.constraint(equalTo: formatContainerView.bottomAnchor).isActive = true
               } else {
                    lastTopAnchor = container.bottomAnchor
               }
          }
     }
     
     /* ################################################################## */
     /**
      Sets up the bar button item, with the state of attendance.
      */
     func setBarButton() {
          guard let meeting = meeting else { return }
          
          let barButtonView = UIView()
          barButtonView.isUserInteractionEnabled = true
          barButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iAttendHit)))
          let useThisImage = meeting.iAttend ? Self._checkedImage : Self._uncheckedImage
          let barButtonImage = UIImageView(image: useThisImage?.withRenderingMode(.alwaysTemplate).withTintColor(view.tintColor))
          let barButtonLabel = UILabel()
          barButtonLabel.text = "SLUG-I-ATTEND".localizedVariant
          barButtonLabel.font = Self._barButtonLabelFont
          barButtonLabel.textColor = view.tintColor
          barButtonView.addSubview(barButtonLabel)
          barButtonLabel.translatesAutoresizingMaskIntoConstraints = false
          barButtonLabel.leftAnchor.constraint(equalTo: barButtonView.leftAnchor).isActive = true
          barButtonLabel.topAnchor.constraint(equalTo: barButtonView.topAnchor).isActive = true
          barButtonLabel.bottomAnchor.constraint(equalTo: barButtonView.bottomAnchor).isActive = true
          barButtonView.addSubview(barButtonImage)
          barButtonImage.translatesAutoresizingMaskIntoConstraints = false
          barButtonImage.widthAnchor.constraint(equalTo: barButtonImage.heightAnchor).isActive = true
          barButtonImage.widthAnchor.constraint(equalToConstant: 24).isActive = true
          barButtonImage.leftAnchor.constraint(equalTo: barButtonLabel.rightAnchor, constant: 4).isActive = true
          barButtonImage.rightAnchor.constraint(equalTo: barButtonView.rightAnchor).isActive = true
          barButtonImage.topAnchor.constraint(equalTo: barButtonView.topAnchor).isActive = true
          barButtonImage.bottomAnchor.constraint(equalTo: barButtonView.bottomAnchor).isActive = true
          iAttendBarButton?.customView = barButtonView
          iAttendBarButton?.target = self
          iAttendBarButton?.action = #selector(iAttendHit)
          
          iAttendBarButton?.accessibilityLabel = "SLUG-I-\(meeting.iAttend ? "" : "DO-NOT-")ATTEND-BAR-BUTTON-LABEL".accessibilityLocalizedVariant
          iAttendBarButton?.accessibilityHint = "SLUG-I-\(meeting.iAttend ? "" : "DO-NOT-")ATTEND-BAR-BUTTON-HINT".accessibilityLocalizedVariant
     }
     
     /* ################################################################## */
     /**
      This displays the alert for links to Zoom, telling the user they need to download the app.
      */
     func displayMacZoomAlert() {
          guard let zoomURI = URL(string: "SLUG-ZOOM-DOWNLOAD-URL".localizedVariant) else { return }
          let style: UIAlertController.Style = .alert
          let alertController = UIAlertController(title: "SLUG-ZOOM-WARING-ALERT-HEADER".localizedVariant, message: "SLUG-ZOOM-WARING-ALERT-BODY".localizedVariant, preferredStyle: style)
          
          let okAction = UIAlertAction(title: "SLUG-CANCEL-BUTTON-TEXT".localizedVariant, style: .cancel, handler: nil)
          
          alertController.addAction(okAction)
          
          let downloadAction = UIAlertAction(title: "SLUG-ZOOM-WARING-ALERT-APP-BUTTON".localizedVariant, style: .default, handler: { _ in
               VMF_AppDelegate.open(url: zoomURI)
          })
          
          alertController.addAction(downloadAction)
          
          present(alertController, animated: true, completion: nil)
     }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_MeetingInspectorViewController {
     /* ################################################################## */
     /**
      The phone in button was hit.
      
      - parameter: ignored
      */
     @IBAction func phoneButtonHit(_: Any) {
          var directPhoneNumberString = meeting?.directPhoneURI?.absoluteString.replacingOccurrences(of: "https://", with: "tel:") ?? ""
          
          if directPhoneNumberString.isEmpty,
             let numbers = meeting?.virtualPhoneNumber?.decimalOnly,
             !numbers.isEmpty {
               directPhoneNumberString = "tel:\(numbers)"
          }
          
          if !directPhoneNumberString.isEmpty,
             let directURI = URL(string: directPhoneNumberString),
             UIApplication.shared.canOpenURL(directURI) {
               hardImpactHaptic()
               VMF_AppDelegate.open(url: directURI)
          }
     }
     
     /* ################################################################## */
     /**
      The globe button was hit.
      
      - parameter: ignored
      */
     @IBAction func globeButtonHit(_: Any) {
          if let webLinkURL = meeting?.virtualURL,
             UIApplication.shared.canOpenURL(webLinkURL) {
               hardImpactHaptic()
               // HACK ALERT!
               // Apple does not allow Mac Safari to connect directly to meetings in Zoom, because of the immediate download, so we need to tell the user to get the app, and join from there.
               #if targetEnvironment(macCatalyst)
                    if webLinkURL.absoluteString.contains("zoom.us") {
                         displayMacZoomAlert()
                    } else {
                         VMF_AppDelegate.open(url: webLinkURL)
                    }
               #else
                    VMF_AppDelegate.open(url: webLinkURL)
               #endif
          }
     }
     
     /* ################################################################## */
     /**
      The video button was hit.
      
      - parameter: ignored
      */
     @IBAction func videoButtonHit(_: Any) {
          if let videoLinkURL = meeting?.directAppURI {
               hardImpactHaptic()
               VMF_AppDelegate.open(url: videoLinkURL)
          }
     }
     
     /* ################################################################## */
     /**
      The format header was hit (open or close the format section).
      
      - parameter: ignored
      */
     @IBAction func formatSectionHeaderHit(_: Any) {
          selectionHaptic()
          isFormatsOpen = !isFormatsOpen
     }
     
     /* ################################################################## */
     /**
      The in-person location header was hit (open or close the location section).
      
      - parameter: ignored
      */
     @IBAction func locationSectionHeaderHit(_: Any) {
          selectionHaptic()
          isLocationOpen = !isLocationOpen
     }
     
     /* ################################################################## */
     /**
      Called to handle action tasks.
      
      - parameter inButton: The action BarButtonItem
      */
     @IBAction func actionItemHit(_ inButton: UIBarButtonItem) {
          guard let meeting = meeting,
                let url = meeting.linkURL,
                let event = attendanceEvent
          else { return }
          
          let viewController = UIActivityViewController(activityItems: [url, event], applicationActivities: validActivities)
          viewController.excludedActivityTypes = [.assignToContact, .openInIBooks, .print, .saveToCameraRoll, .addToReadingList]
          
          // iPad uses a popover.
          if .pad == traitCollection.userInterfaceIdiom,
             let size = view?.bounds.size {
               viewController.modalPresentationStyle = .popover
               viewController.preferredContentSize = CGSize(width: size.width, height: size.height)
               viewController.popoverPresentationController?.barButtonItem = inButton
               viewController.popoverPresentationController?.permittedArrowDirections = [.up]
          }
          
          selectionHaptic()
          
          present(viewController, animated: true, completion: nil)
     }
     
     /* ################################################################## */
     /**
      The "I Attend" bar button item was hit.
      
      - parameter: ignored
      */
     @objc func iAttendHit(_: Any) {
          guard var meeting = meeting else { return }
          let originalState = meeting.iAttend
          meeting.iAttend = !originalState
          
          selectionHaptic()
          
          // HACK ALERT!
          // This actually prevents that momentary delay, as the table recalculates, when we go back.
          (myController as? VMF_MainViewController)?.organizedMeetings = []
          setBarButton()
     }
}

/* ###################################################################################################################################### */
// MARK: MKMapViewDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_MeetingInspectorViewController: MKMapViewDelegate {
     /* ################################################################## */
     /**
      This is called to fetch an annotation (marker) for the map.
      
      - parameter: The map view (ignored)
      - parameter viewFor: The annotation we're getting the marker for.
      - returns: The marker view for the annotation.
      */
     func mapView(_: MKMapView, viewFor inAnnotation: MKAnnotation) -> MKAnnotationView? {
          var ret: MKAnnotationView?
          
          if let myAnnotation = inAnnotation as? VMF_MapAnnotation {
               ret = VMF_MapMarker(annotation: myAnnotation, reuseIdentifier: VMF_MapMarker.reuseID)
          }
          
          return ret
     }
}
