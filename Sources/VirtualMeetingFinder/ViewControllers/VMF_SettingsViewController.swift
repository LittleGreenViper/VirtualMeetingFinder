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
import SwiftBMLSDK
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Settings View Controller -
/* ###################################################################################################################################### */
/**
 This displays the settings screen.
 
 NOTE: You will see a double-tap gesture recognizer in the IB file.
 
 This "eats" double-taps. It prevents the switch from doing an "about face," if the user is too fast.
 
 The single-tap gesture recognizer does the same thing, but is the principal trigger.
 
 We use gesture recognizers, instead of controls. Messes with the accessibility a bit, but the delay in responding, means that the user can accidentally trigger multiple switches.
 */
class VMF_SettingsViewController: VMF_BaseViewController {
     /* ################################################################## */
     /**
      The bar button item that takes you to the about screen.
      */
     @IBOutlet weak var infoBarButtonItem: UIBarButtonItem?
     
     @IBOutlet weak var filterServiceMeetingsSwitchContainer: UIView?
     
     /* ################################################################## */
     /**
      The label for the filter Service meetings switch.
      */
     @IBOutlet weak var filterServiceMeetingsLabelButton: UIButton?
     
     /* ################################################################## */
     /**
      The switch, that, if on, means that Service meetings will be removed from the data.
      */
     @IBOutlet weak var filterServiceMeetingsSwitch: UISwitch?
     
     /* ################################################################## */
     /**
      */
     @IBOutlet weak var singleTapGestureRecognizer: UITapGestureRecognizer?
     
     /* ################################################################## */
     /**
      This is used to prevent double-taps.
      */
     @IBOutlet weak var doubleTapEaterGestureRecognizer: UITapGestureRecognizer?
     
     /* ################################################################## */
     /**
      This is displayed below the switch, and explains its utility.
      */
     @IBOutlet weak var filterServiceMeetingsExplainLabel: UILabel?
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_SettingsViewController {
     /* ################################################################## */
     /**
      Called when either the label or switch to filter Service meetings is hit.
      
      - parameter inSender: The gesture recognizer or switch.
      */
     @IBAction func filterServiceMeetingsHit(_ inSender: NSObjectProtocol) {
          if let switcher = inSender as? UISwitch {   // If the switch, we execute it.
               VMF_AppDelegate.prefs.excludeServiceMeetings = switcher.isOn
               guard let searchController = VMF_AppDelegate.mainScreenController,
                     let tableDisplayController = searchController.tableDisplayController
               else { return }
               
               let dayIndex = tableDisplayController.dayIndex
               let timeIndex = tableDisplayController.timeIndex
               guard let time = searchController.getTimeOf(dayIndex: dayIndex, timeIndex: timeIndex) else { return }
               searchController.reorganizeMeetings()
               searchController.openTo(dayIndex: dayIndex, time: time)
          } else if inSender is UITapGestureRecognizer {    // If the label, we toggle the switch, and send the value changed message (which calls us again).
               selectionHaptic()
               let newValue = !(filterServiceMeetingsSwitch?.isOn ?? true)
               filterServiceMeetingsSwitch?.setOn(newValue, animated: true)
               filterServiceMeetingsSwitch?.isEnabled = false
               filterServiceMeetingsSwitch?.sendActions(for: .valueChanged)
               filterServiceMeetingsSwitch?.isEnabled = true
          }
     }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_SettingsViewController {
     /* ################################################################## */
     /**
      Called when the view hierarchy has loaded and initialized.
      */
     override func viewDidLoad() {
          super.viewDidLoad()
          
          guard let dtg = doubleTapEaterGestureRecognizer else { return }
          singleTapGestureRecognizer?.require(toFail: dtg)
          
          infoBarButtonItem?.accessibilityLabel = "SLUG-ACC-ABOUT-BUTTON-LABEL".accessibilityLocalizedVariant
          infoBarButtonItem?.accessibilityHint = "SLUG-ACC-ABOUT-BUTTON-HINT".accessibilityLocalizedVariant
          filterServiceMeetingsSwitchContainer?.accessibilityLabel = "SLUG-ACC-FILTER-SERVICE-MEETINGS-LABEL".accessibilityLocalizedVariant
          filterServiceMeetingsSwitchContainer?.accessibilityHint = "SLUG-ACC-FILTER-SERVICE-MEETINGS-HINT".accessibilityLocalizedVariant
          
          filterServiceMeetingsLabelButton?.setTitle(filterServiceMeetingsLabelButton?.title(for: .normal)?.localizedVariant, for: .normal)
          filterServiceMeetingsSwitch?.isOn = VMF_AppDelegate.prefs.excludeServiceMeetings
          filterServiceMeetingsExplainLabel?.text = filterServiceMeetingsExplainLabel?.text?.localizedVariant
     }
}
