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

/* ###################################################################################################################################### */
// MARK: - Abstraction for the Meeting Type -
/* ###################################################################################################################################### */
/* ###################################################################### */
/**
 This allows us to play around with the SDK.
 */
public typealias MeetingInstance = SwiftBMLSDK_Parser.Meeting

/* ###################################################################################################################################### */
// MARK: - String Extension -
/* ###################################################################################################################################### */
/* ###################################################################### */
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
extension MeetingInstance {
    /* ################################################################## */
    /**
     This allows us to return a string for the meeting time. The return is localized, with our strings for noon and midnight.
     */
    var timeString: String {
        let integerTime = integerStartIme
        
        guard 1200 != integerTime else { return "SLUG-NOON-TIME".localizedVariant }
        guard 1159 != integerTime else { return "SLUG-MIDNIGHT-TIME".localizedVariant }

        var mutableSelf = self
        
        let formatter = DateFormatter()
        formatter.dateFormat = .none
        formatter.timeStyle = .short
        return formatter.string(from: mutableSelf.getNextStartDate(isAdjusted: true))
    }
}
