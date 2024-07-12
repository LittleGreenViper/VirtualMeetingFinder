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
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - The URL Button Class -
/* ###################################################################################################################################### */
/**
 This is a special button that has a string and a URL.
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
    }
}

/* ###################################################################################################################################### */
// MARK: - About View Controller -
/* ###################################################################################################################################### */
/**
 This displays the About screen.
 */
class VMF_AboutViewController: VMF_BaseViewController {
    /* ################################################################## */
    /**
     This displays the app name.
     */
    @IBOutlet weak var appNameLabel: UILabel?
    
    /* ################################################################## */
    /**
     This displays the full version of the app.
     */
    @IBOutlet weak var versionLabel: UILabel?
    
    /* ################################################################## */
    /**
     The header for the dependency list
     */
    @IBOutlet weak var dependencySectionHeader: UILabel?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_AboutViewController {
    /* ################################################################## */
    /**
     Called when the view has completed loading.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        appNameLabel?.text = Bundle.main.appDisplayName
        
        let mainVersion = Bundle.main.appVersionString
        let buildVersion = Bundle.main.appVersionBuildString
        
        versionLabel?.text = String(format: "SLUG-VERSION-FORMAT".localizedVariant, mainVersion, buildVersion)
        
        dependencySectionHeader?.text = dependencySectionHeader?.text?.localizedVariant
    }
    
    /* ################################################################## */
    /**
     Called when the view is about to appear.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        successHaptic()
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_AboutViewController {
    /* ################################################################## */
    /**
     This is called when one of the URL buttons is hit, and takes us to the site.
     
     - parameter: the button.
     */
    @IBAction func urlButtonHit(_ inButton: VMF_URLButton) {
        guard let url = inButton.url else { return }
        UIApplication.shared.open(url)
        hardImpactHaptic()
    }
}
