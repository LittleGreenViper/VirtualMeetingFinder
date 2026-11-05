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
import SwiftBMLSDK
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - String Extension for Localization -
/* ###################################################################################################################################### */
/// Normalizes meeting-name searches and resolves app resource strings.
extension String {
     /** A consistent search form for case, accents, width variants, and Latin ligatures. */
     var meetingSearchKey: String {
          let folded = folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
          return folded.applyingTransform(StringTransform("Latin-ASCII"), reverse: false) ?? folded
     }

     /* ################################################################## */
     /**
      Uses the toolbox's localized tables, then checks the shared nonlocalized table.
      Returns the original string when no table contains it.
      */
     var localizedVariant: String {
          let localized = localizedVariant(bundle: .main)
          guard localized == self else { return localized }
          return Bundle.main.localizedString(forKey: self, value: nil, table: "NonLocalized")
     }
}

/* ###################################################################################################################################### */
// MARK: - Abstraction for the Meeting Type -
/* ###################################################################################################################################### */
/* ###################################################################### */
/**
 The SDK meeting record used throughout the app. App-specific extensions add local attendance and link helpers.
 */
public typealias MeetingInstance = SwiftBMLSDK_Parser.Meeting

/* ###################################################################################################################################### */
// MARK: - A Special URL Button Class -
/* ###################################################################################################################################### */
/**
 This is a special button that has a string and a URL. This class lets us define them in IB.
 */
class VMF_URLButton: UIButton {
     /* ################################################################## */
     /**
      This is the URL that is associated with this button.
      */
     @IBInspectable var urlString: String?
     
     /* ################################################################## */
     /**
      The string, as a URL.
      */
     var url: URL? { URL(string: (urlString ?? "").localizedVariant) }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_URLButton {
     /* ################################################################## */
     /**
      Called when the subviews are being laid out.
      */
     override func layoutSubviews() {
          super.layoutSubviews()
          titleLabel?.numberOfLines = 0
          setTitle(title(for: .normal)?.localizedVariant, for: .normal)
          isAccessibilityElement = true
          accessibilityLabel = title(for: .normal) ?? "SLUG-PRESENTED-BY".localizedVariant
          accessibilityHint = "SLUG-ACC-OPEN-WEBSITE-HINT".localizedVariant
     }
}

/* ###################################################################################################################################### */
// MARK: - Page View Controller -
/* ###################################################################################################################################### */
/**
 This is the page controller that embeds our tables.
 */
class VMF_DayTimeSearchPageViewController: UIPageViewController { }

/* ###################################################################################################################################### */
// MARK: - Accessible Gesture Controls -
/* ###################################################################################################################################### */
/**
 A gesture-backed view that also supports VoiceOver's standard activation.
 Set ``accessibilityActivation`` to the same action as the view's tap recognizer.
 */
class VMF_ActionView: UIView {
     /// Performs the control's action. Capture its owning controller weakly.
     var accessibilityActivation: (() -> Void)?

     /// Invokes the configured action for a standard assistive-technology activation.
     override func accessibilityActivate() -> Bool {
          guard let action = accessibilityActivation else { return false }
          action()
          return true
     }
}

/// A stack-based disclosure control with the same activation contract as ``VMF_ActionView``.
class VMF_ActionStackView: UIStackView {
     /// Performs the disclosure action. Capture its owning controller weakly.
     var accessibilityActivation: (() -> Void)?

     /// Invokes the configured action for a standard assistive-technology activation.
     override func accessibilityActivate() -> Bool {
          guard let action = accessibilityActivation else { return false }
          action()
          return true
     }
}

/* ###################################################################################################################################### */
// MARK: - String Extension -
/* ###################################################################################################################################### */
/**
 This adds various functionality to Strings
 */
extension StringProtocol {
     /* ################################################################## */
     /**
      This tests a string to see if a given substring is present at the start.
      
      - parameter inSubstring: The substring to test.
      
      - returns: true, if the string begins with the given substring.
      */
     func beginsWith(_ inSubstring: String) -> Bool {
          guard let range = range(of: inSubstring),
                range.lowerBound == startIndex
          else { return false }
          return true
     }
     
     /* ################################################################## */
     /**
      This tests a string to see if a given substring is present at the end.
      
      - parameter inSubstring: The substring to test.
      
      - returns: true, if the string ends with the given substring.
      */
     func endsWith(_ inSubstring: String) -> Bool {
          guard let range = range(of: inSubstring),
                range.upperBound == endIndex
          else { return false }
          return true
     }
     
     /* ################################################################## */
     /**
      This tests a string to see if a given substring is present anywhere
      
      - parameter inSubstring: The substring to test.
      
      - returns: true, if the string contains the given substring.
      */
     func contains(_ inSubstring: String) -> Bool {
          guard let range = range(of: inSubstring),
                !range.isEmpty
          else { return false }
          return true
     }
}

/* ###################################################################################################################################### */
// MARK: - Additional Function for Meetings -
/* ###################################################################################################################################### */
/**
 This extension adds some methods to the individual meeting class.
 */
extension MeetingInstance {
     /* ################################################################## */
     /**
      This returns the start weekday. It is adjusted, so may sometimes be different
      from the one specified by the meeting. It is always in 1 = Sunday space.
      */
     var adjustedWeekday: Int {
         let startDate = self.nextOccurrenceDateFast()
         var calendar = Calendar.autoupdatingCurrent
         calendar.timeZone = .autoupdatingCurrent
         return calendar.component(.weekday, from: startDate)
     }
     
     /* ################################################################## */
     /**
      This marks our attendance in the app local preferences.
      */
     var iAttend: Bool {
          get { VMF_AppDelegate.prefs.attendance.contains(Int(id)) }
          set { setAttendance(newValue) }
     }

     /// Changes local attendance preferences without mutating the meeting record.
     /// Works with SDK versions that represent meetings as either structs or classes.
     func setAttendance(_ inAttendance: Bool) {
          let id = Int(id)
          if VMF_AppDelegate.prefs.attendance.contains(id), !inAttendance {
               VMF_AppDelegate.prefs.attendance.removeAll { $0 == id }
          } else if inAttendance, !VMF_AppDelegate.prefs.attendance.contains(id) {
               VMF_AppDelegate.prefs.attendance.append(id)
          }
     }
     
     /* ################################################################## */
     /**
      If this meeting has a format code for a Service meeting, this returns true.
      */
     var isServiceMeeting: Bool {
          // I know, I know, I should use reduce(), or some other higher-order methodology, but the classic for loop is a lot faster.
          for index in 0..<formats.count {
               switch formats[index].key.lowercased() {
               case "asm", "sub-rp":
                    return true
                    
               default:
                    continue
               }
          }
          
          return false
     }
     
     /* ################################################################## */
     /**
      This is a universal link for this meeting, in this app.
      */
     var linkURL: URL? { URL(string: String(format: "SLUG-UNIVERSAL-LINK-FORMAT".localizedVariant, id)) }
}

/* ###################################################################################################################################### */
// MARK: - Bundle Extension -
/* ###################################################################################################################################### */
/**
 This extension adds a simple accessor to fetch the root server URL.
 */
public extension Bundle {
     /* ################################################################## */
     /**
      The root server URI as a string.
      */
     var rootServerURI: String? { object(forInfoDictionaryKey: "VMF_BaseServerURI") as? String }
}

/* ###################################################################################################################################### */
// MARK: - SwiftBMLSDK_MeetingLocalTimezoneCollection Extension -
/* ###################################################################################################################################### */
/**
 This extension adds a simple accessor to fetch the meetings that we have marked as ones that we attend.
 */
extension SwiftBMLSDK_MeetingLocalTimezoneCollection {
     /* ################################################################## */
     /**
      These are the meetings that the user has marked as ones that they attend.
      */
     var meetingsThatIAttend: [CachedMeeting] { meetings.filter { $0.meeting.iAttend } }
}

/* ###################################################################################################################################### */
// MARK: - Special Bar Button Item That Disappears, When Disabled -
/* ###################################################################################################################################### */
/**
 This will not turn grey. Instead, it will become clear.
 */
class VMF_DisappearingBarButton: UIBarButtonItem {
    /* ################################################################## */
    /**
     If the control is disabled, we return clear.
     */
    override var isEnabled: Bool {
        get { super.isEnabled }
        set {
            super.isEnabled = newValue
             super.tintColor = newValue ? nil : .clear
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Recovrr Meeting Button -
/* ###################################################################################################################################### */
/// Recovrr's solid button fill and sampled HSL gradient border, with its original-color logo.
final class VMF_RecovrrButton: UIButton {
     private let _borderGradient = CAGradientLayer()
     private let _borderMask = CAShapeLayer()

     /// Installs the Recovrr logo, title, and gradient border after storyboard decoding.
     override func awakeFromNib() {
          super.awakeFromNib()
          var style = UIButton.Configuration.plain()
          style.title = title(for: .normal)?.localizedVariant
          style.image = UIImage(named: "RecovrrButtonLogo")?.preparingThumbnail(of: CGSize(width: 22, height: 22))?.withRenderingMode(.alwaysOriginal)
          style.imagePlacement = .leading
          style.imagePadding = 6
          style.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
          style.titleLineBreakMode = .byWordWrapping
          style.cornerStyle = .fixed
          style.background.cornerRadius = 8
          configuration = style
          titleLabel?.adjustsFontForContentSizeCategory = true
          _borderGradient.startPoint = CGPoint(x: 0, y: 0)
          _borderGradient.endPoint = CGPoint(x: 1, y: 1)
          _borderGradient.colors = Self._gradientColors
          _borderGradient.mask = _borderMask
          _borderMask.fillRule = .evenOdd
          layer.addSublayer(_borderGradient)
          heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
     }

     /// Updates the text and fill for the current highlighted and enabled state.
     override func updateConfiguration() {
          super.updateConfiguration()
          guard var style = configuration else { return }
          let foreground = UIColor.label.withAlphaComponent(isEnabled && !isHighlighted ? 1 : 0.55)
          style.baseForegroundColor = foreground
          style.background.backgroundColor = UIColor(named: "RecovrrButtonFill")
          style.background.backgroundColorTransformer = UIConfigurationColorTransformer { $0 }
          style.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
               var attributes = incoming
               attributes.font = UIFont.preferredFont(forTextStyle: .body)
               attributes.foregroundColor = foreground
               return attributes
          }
          configuration = style
     }

     /// Fits the gradient border to the current button bounds.
     override func layoutSubviews() {
          super.layoutSubviews()
          CATransaction.begin()
          CATransaction.setDisableActions(true)
          _borderGradient.frame = bounds
          _borderMask.frame = bounds
          let border = UIBezierPath(roundedRect: bounds, cornerRadius: 8)
          border.append(UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 7))
          _borderMask.path = border.cgPath
          CATransaction.commit()
     }

     // 32 HSL samples between Recovrr's GradientStartColor and GradientEndColor.
     private static let _gradientColors: [CGColor] = [
          UIColor(red: 0.58431373, green: 0.26274510, blue: 0.83137255, alpha: 1).cgColor,
          UIColor(red: 0.55744334, green: 0.26720208, blue: 0.83362018, alpha: 1).cgColor,
          UIColor(red: 0.53080881, green: 0.27167397, blue: 0.83585291, alpha: 1).cgColor,
          UIColor(red: 0.50441489, green: 0.27616076, blue: 0.83807073, alpha: 1).cgColor,
          UIColor(red: 0.47826632, green: 0.28066247, blue: 0.84027365, alpha: 1).cgColor,
          UIColor(red: 0.45236785, green: 0.28517908, blue: 0.84246166, alpha: 1).cgColor,
          UIColor(red: 0.42672423, green: 0.28971059, blue: 0.84463476, alpha: 1).cgColor,
          UIColor(red: 0.40134022, green: 0.29425701, blue: 0.84679296, alpha: 1).cgColor,
          UIColor(red: 0.37622056, green: 0.29881834, blue: 0.84893624, alpha: 1).cgColor,
          UIColor(red: 0.35136999, green: 0.30339458, blue: 0.85106463, alpha: 1).cgColor,
          UIColor(red: 0.32679328, green: 0.30798572, blue: 0.85317810, alpha: 1).cgColor,
          UIColor(red: 0.31259177, green: 0.32268837, blue: 0.85527667, alpha: 1).cgColor,
          UIColor(red: 0.31721272, green: 0.35594504, blue: 0.85736033, alpha: 1).cgColor,
          UIColor(red: 0.32184858, green: 0.38894343, blue: 0.85942909, alpha: 1).cgColor,
          UIColor(red: 0.32649935, green: 0.42167879, blue: 0.86148294, alpha: 1).cgColor,
          UIColor(red: 0.33116503, green: 0.45414636, blue: 0.86352188, alpha: 1).cgColor,
          UIColor(red: 0.33584561, green: 0.48634139, blue: 0.86554591, alpha: 1).cgColor,
          UIColor(red: 0.34054110, green: 0.51825915, blue: 0.86755504, alpha: 1).cgColor,
          UIColor(red: 0.34525149, green: 0.54989487, blue: 0.86954927, alpha: 1).cgColor,
          UIColor(red: 0.34997680, green: 0.58124381, blue: 0.87152858, alpha: 1).cgColor,
          UIColor(red: 0.35471700, green: 0.61230122, blue: 0.87349299, alpha: 1).cgColor,
          UIColor(red: 0.35947212, green: 0.64306235, blue: 0.87544249, alpha: 1).cgColor,
          UIColor(red: 0.36424214, green: 0.67352245, blue: 0.87737709, alpha: 1).cgColor,
          UIColor(red: 0.36902707, green: 0.70367677, blue: 0.87929678, alpha: 1).cgColor,
          UIColor(red: 0.37382690, green: 0.73352056, blue: 0.88120156, alpha: 1).cgColor,
          UIColor(red: 0.37864165, green: 0.76304907, blue: 0.88309143, alpha: 1).cgColor,
          UIColor(red: 0.38347130, green: 0.79225756, blue: 0.88496640, alpha: 1).cgColor,
          UIColor(red: 0.38831585, green: 0.82114127, blue: 0.88682646, alpha: 1).cgColor,
          UIColor(red: 0.39317531, green: 0.84969545, blue: 0.88867162, alpha: 1).cgColor,
          UIColor(red: 0.39804968, green: 0.87791535, blue: 0.89050187, alpha: 1).cgColor,
          UIColor(red: 0.40293896, green: 0.89231721, blue: 0.87883819, alpha: 1).cgColor,
          UIColor(red: 0.40784314, green: 0.89411765, blue: 0.85490196, alpha: 1).cgColor
     ]
}
