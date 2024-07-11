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
import MapKit
import SwiftBMLSDK
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Meeting Inspector View Controller -
/* ###################################################################################################################################### */
/**
 This displays one meeting.
 */
class VMF_MeetingViewController: VMF_BaseViewController {
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
     Contains the in-person meeting stuff.
     */
    @IBOutlet weak var inPersonContainer: UIStackView?
    
    /* ################################################################## */
    /**
     The heading for the in-person meeting stuff.
     */
    @IBOutlet weak var inPersonHeader: UILabel?

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
     The heading for the format section.
     */
    @IBOutlet weak var formatHeaderLabel: UILabel?
    
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
}

/* ###################################################################################################################################### */
// MARK: Static Functions
/* ###################################################################################################################################### */
extension VMF_MeetingViewController {
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
extension VMF_MeetingViewController {
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
            let allowedChars = CharacterSet(charactersIn: "0123456789 ()-+")
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
        
        meetingNameLabel?.text = meeting?.name
        phoneLabelButton?.text = phoneLabelButton?.text?.localizedVariant
        globeLabelButton?.text = globeLabelButton?.text?.localizedVariant
        videoLabelButton?.text = videoLabelButton?.text?.localizedVariant

        super.viewDidLoad()
        
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
        inPersonContainer?.isHidden = true
        locationMapView?.isHidden = true
        formatHeaderLabel?.isHidden = true
        formatContainerView?.isHidden = true
        inPersonExtraInfoLabel?.isHidden = true
        virtualExtraInfoTextView?.isHidden = true
        
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
        
        if !directPhoneNumberString.isEmpty,
           let directURI = URL(string: directPhoneNumberString),
           UIApplication.shared.canOpenURL(directURI) {
            linkContainer?.isHidden = false
            phoneButtonContainer?.isHidden = false
        }
        
        if let directApp = meeting?.directApp {
            linkContainer?.isHidden = false
            videoButtonContainer?.isHidden = false
            videoLabelButton?.text = directApp.appName.localizedVariant
            videoButtonContainer?.accessibilityLabel = String(format: "SLUG-VIDEO-MI-LABEL-FORMAT".accessibilityLocalizedVariant, directApp.appName.localizedVariant)
            videoButtonContainer?.accessibilityHint = String(format: "SLUG-VIDEO-MI-HINT-FORMAT".accessibilityLocalizedVariant, directApp.appName.localizedVariant)
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
            inPersonContainer?.isHidden = false
            inPersonHeader?.text = inPersonHeader?.text?.localizedVariant
            inPersonAddressTextView?.text = basicAddress
            if let extraInfo = meeting?.locationInfo,
               meeting?.comments?.lowercased() != extraInfo.lowercased(),
               !extraInfo.isEmpty {
                inPersonExtraInfoLabel?.isHidden = false
                inPersonExtraInfoLabel?.text = extraInfo
            }
        }
        
        if let coords = meeting?.coords,
           CLLocationCoordinate2DIsValid(coords) {
            setUpMap(coords)
        }
        
        if let formats = meeting?.formats,
           !formats.isEmpty {
            setUpFormats(formats)
        }
        
        setBarButton()
    }
    
    /* ################################################################## */
    /**
     Called before the screen appears.
     
     Let the app know that we're here.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        VMF_AppDelegate.openMeeting = self
        guard let meeting = meeting else { return }
        iAttendBarButton?.isAccessibilityElement = true
        iAttendBarButton?.accessibilityLabel = "SLUG-I-\(meeting.iAttend ? "" : "DO-NOT-")ATTEND-BAR-BUTTON-LABEL".accessibilityLocalizedVariant
        iAttendBarButton?.accessibilityHint = "SLUG-I-\(meeting.iAttend ? "" : "DO-NOT-")ATTEND-BAR-BUTTON-HINT".accessibilityLocalizedVariant
    }
    
    /* ################################################################## */
    /**
     Called before the screen disappears.
     
     Let the app know that we're done.
     
     - parameter inIsAnimated: True, if the disappearance is animated.
     */
    override func viewWillDisappear(_ inIsAnimated: Bool) {
        super.viewWillDisappear(inIsAnimated)
        VMF_AppDelegate.openMeeting = nil
        
        if isMovingFromParent {
            hardImpactHaptic()
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_MeetingViewController {
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
     */
    func setUpMap(_ inCoords: CLLocationCoordinate2D) {
        locationMapView?.isHidden = false
        if let initialRegion = locationMapView?.regionThatFits(MKCoordinateRegion(center: inCoords, span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25))) {
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
        formatHeaderLabel?.isHidden = false
        formatContainerView?.isHidden = false
        
        guard let formatContainerView = formatContainerView else { return }

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
        let barButtonView = UIView()
        barButtonView.isUserInteractionEnabled = true
        barButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iAttendHit)))
        let useThisImage = (meeting?.iAttend ?? false) ? Self._checkedImage : Self._uncheckedImage
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
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_MeetingViewController {
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
            VMF_AppDelegate.open(url: webLinkURL)
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
     The "I Attend" bar button item was hit.
     
     - parameter: ignored
     */
    @objc func iAttendHit(_: Any) {
        guard var meeting = meeting else { return }
        let originalState = meeting.iAttend
        meeting.iAttend = !originalState
        
        iAttendBarButton?.accessibilityLabel = "SLUG-I-\(meeting.iAttend ? "" : "DO-NOT-")ATTEND-BAR-BUTTON-LABEL".accessibilityLocalizedVariant
        iAttendBarButton?.accessibilityHint = "SLUG-I-\(meeting.iAttend ? "" : "DO-NOT-")ATTEND-BAR-BUTTON-HINT".accessibilityLocalizedVariant

        selectionHaptic()
        
        // HACK ALERT!
        // This actually prevents that momentary delay, as the table recalculates, when we go back.
        myController?.valueTable?.reloadData()
        setBarButton()
    }
}

/* ###################################################################################################################################### */
// MARK: MKMapViewDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_MeetingViewController: MKMapViewDelegate {
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
