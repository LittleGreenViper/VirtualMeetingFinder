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
 */
class VMF_SettingsViewController: VMF_BaseViewController {
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var filterServiceMeetingsLabel: UILabel?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var filterServiceMeetingsSwitch: UISwitch?
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_SettingsViewController {
    /* ################################################################## */
    /**
     */
    @IBAction func filterServiceMeetingsHit(_ inSender: NSObjectProtocol) {
        if let switcher = inSender as? UISwitch {
            VMF_Prefs().excludeServiceMeetings = switcher.isOn
        } else {
            filterServiceMeetingsSwitch?.setOn(!(filterServiceMeetingsSwitch?.isOn ?? true), animated: true)
            filterServiceMeetingsSwitch?.sendActions(for: .valueChanged)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_SettingsViewController {
    /* ################################################################## */
    /**
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        filterServiceMeetingsLabel?.textColor = .tintColor
        filterServiceMeetingsLabel?.text = filterServiceMeetingsLabel?.text?.localizedVariant
        filterServiceMeetingsSwitch?.isOn = VMF_Prefs().excludeServiceMeetings
    }
}
