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
// MARK: - Settings View Controller -
/* ###################################################################################################################################### */
/**
 Edits the local service-meeting filter and opens the About screen.
 The checkbox handles touch and accessibility activation through its value-changed action.
 Its adjacent title also toggles the setting for sighted users; VoiceOver exposes one control.
 */
class VMF_SettingsViewController: VMF_BaseViewController {
     /* ################################################################## */
     /**
      The bar button item that takes you to the about screen.
      */
     @IBOutlet weak var infoBarButtonItem: UIBarButtonItem?
     
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
      
      - parameter inSender: The checkbox (already toggled), or its title button.
      */
     @IBAction func filterServiceMeetingsHit(_ inSender: Any) {
          selectionHaptic()
          let newValue = inSender is UISwitch ? (filterServiceMeetingsSwitch?.isOn ?? true) : !(filterServiceMeetingsSwitch?.isOn ?? true)
          filterServiceMeetingsSwitch?.setOn(newValue, animated: true)
          VMF_AppDelegate.prefs.excludeServiceMeetings = newValue
          filterServiceMeetingsSwitch?.accessibilityValue = (newValue ? "SLUG-ACC-ON" : "SLUG-ACC-OFF").localizedVariant
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
          
          infoBarButtonItem?.accessibilityLabel = "SLUG-ABOUT-SCREEN-TITLE".localizedVariant
          infoBarButtonItem?.accessibilityHint = "SLUG-ACC-ABOUT-BUTTON-HINT".localizedVariant
          filterServiceMeetingsSwitch?.accessibilityLabel = "SLUG-FILTER-SERVICE-MEETINGS".localizedVariant
          filterServiceMeetingsSwitch?.accessibilityHint = "SLUG-ACC-FILTER-SERVICE-MEETINGS-HINT".localizedVariant
          
          filterServiceMeetingsLabelButton?.setTitle(filterServiceMeetingsLabelButton?.title(for: .normal)?.localizedVariant, for: .normal)
          filterServiceMeetingsSwitch?.isOn = VMF_AppDelegate.prefs.excludeServiceMeetings
          filterServiceMeetingsSwitch?.accessibilityValue = (VMF_AppDelegate.prefs.excludeServiceMeetings ? "SLUG-ACC-ON" : "SLUG-ACC-OFF").localizedVariant
          filterServiceMeetingsLabelButton?.isAccessibilityElement = false
          filterServiceMeetingsLabelButton?.accessibilityElementsHidden = true
          filterServiceMeetingsExplainLabel?.text = filterServiceMeetingsExplainLabel?.text?.localizedVariant
     }
}
