//
//  CallDirectoryHandler.swift
//  CallDirectoryHandler
//
//  Created by Brian on 29/03/17.
//  Copyright © 2017 BCS. All rights reserved.
//

import Foundation
import CallKit
import Contacts

class CallDirectoryHandler: CXCallDirectoryProvider {
    
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self
        
        self.loadContacts()
        
        do {
            try addBlockingPhoneNumbers(to: context)
        } catch {
            NSLog("Unable to add blocking phone numbers")
            let error = NSError(domain: "CallDirectoryHandler", code: 1, userInfo: nil)
            context.cancelRequest(withError: error)
            return
        }
        
        do {
            try addIdentificationPhoneNumbers(to: context)
        } catch {
            NSLog("Unable to add identification phone numbers")
            let error = NSError(domain: "CallDirectoryHandler", code: 2, userInfo: nil)
            context.cancelRequest(withError: error)
            return
        }
        
        context.completeRequest()
    }
    
    private func addBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) throws {
        // Retrieve phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        
        let defaults = UserDefaults(suiteName: "group.com.incomingBlocker")
        var phoneNumbers : NSMutableArray = NSMutableArray()
        phoneNumbers = NSMutableArray(array: (defaults?.object(forKey: "blockList") as? NSArray)!)
        
        for phoneNumber in phoneNumbers {
            let phStr = phoneNumber as! NSString
            let phInt = Int64(phStr as String)
            context.addBlockingEntry(withNextSequentialPhoneNumber: phInt!)
        }
    }
    
    private func addIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) throws {
        // Retrieve phone numbers to identify and their identification labels from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        
        let defaults = UserDefaults(suiteName: "group.com.incomingBlocker")
        var phoneNumbers : NSMutableArray = NSMutableArray()
        phoneNumbers = NSMutableArray(array: (defaults?.object(forKey: "blockList") as? NSArray)!)
        
        for phoneNumber in phoneNumbers {
            let phStr = phoneNumber as! NSString
            let phInt = Int64(phStr as String)
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phInt!, label: "BCS TEST")
        }
    }
    
    func loadContacts() {
        
        let defaults = UserDefaults(suiteName: "group.com.incomingBlocker")
        let blockedContacts = defaults?.value(forKey: "blockList")
        if blockedContacts != nil {
            return
        }
        
        let contactStore = CNContactStore()
        //        let keysToFetch = [CNContactPhoneNumbersKey]
        contactStore.requestAccess(for: .contacts, completionHandler: { (granted, error) -> Void in
            if granted {
                let predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactStore.defaultContainerIdentifier())
                var contacts: [CNContact]! = []
                do {
                    contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactPhoneNumbersKey as CNKeyDescriptor])
                    
                    if contacts.count == 0 {
                        return
                    }
                    
                    var finalArrayForContacts = NSMutableArray()
                    
                    for contactTemp in contacts {
                        let contactNew = contactTemp
                        var tempArray : NSMutableArray = NSMutableArray()
                        if (contactNew.phoneNumbers).count > 0 {
                            
                            var numArray : NSArray = NSArray()
                            numArray = contactNew.phoneNumbers as NSArray
                            for cnLblValue in numArray {
                                var cnPhNum : CNPhoneNumber = CNPhoneNumber()
                                cnPhNum = (cnLblValue as AnyObject).value(forKey: "value") as! CNPhoneNumber
                                var tempStr : NSString = NSString()
                                tempStr = cnPhNum.value(forKey: "digits") as! NSString
                                tempStr = self.removeFormat(fromMobileNumber: tempStr as String) as NSString
                                tempArray.add(tempStr);
                            }
                            
                            for i in 0  ..< tempArray.count
                            {
                                let phoneNumber : String = (tempArray.object(at: i)) as! String
                                if phoneNumber.count > 0 {
                                    let resultString : String = (phoneNumber.components(separatedBy: NSCharacterSet.whitespaces) as NSArray).componentsJoined(by: "")
                                    finalArrayForContacts.add(resultString)
                                }
                            }
                        }else{
                            // no number saved
                        }
                    }
                    
                    //finalArrayForContacts.sort(using: [NSSortDescriptor.init(key: "self", ascending: true)])
                    let sortedArray = self.sortArray(arrayToSort: (finalArrayForContacts as NSArray) as! [String]) as NSArray
                    finalArrayForContacts = NSMutableArray(array: (sortedArray as? NSArray)!)
                    
                    let defaults = UserDefaults(suiteName: "group.com.incomingBlocker")
                    defaults?.set(finalArrayForContacts, forKey: "blockList")
                    
                }catch {
                    
                }
            }
        })
        
    }
    
    func sortArray(arrayToSort: [String])->[String] {
        let sortedArray = arrayToSort.sorted(by:) {
            (first, second) in
            first.compare(second, options: .numeric) == ComparisonResult.orderedAscending
        }
        print(sortedArray)
        return sortedArray
    }
    
    func removeFormat(fromMobileNumber num: String) -> String {
        var mobileNumber: String = num
        mobileNumber = mobileNumber.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        mobileNumber = mobileNumber.trimmingCharacters(in: CharacterSet.symbols)
        mobileNumber = mobileNumber.trimmingCharacters(in: CharacterSet.punctuationCharacters)
        mobileNumber = mobileNumber.trimmingCharacters(in: CharacterSet.controlCharacters)
        mobileNumber = mobileNumber.replacingOccurrences(of: "+", with: "")
        mobileNumber = mobileNumber.replacingOccurrences(of: " ", with: "")
        mobileNumber = mobileNumber.replacingOccurrences(of: "\u{00a0}", with: "")
        return mobileNumber
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {

    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // An error occurred while adding blocking or identification entries, check the NSError for details.
        // For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
        //
        // This may be used to store the error details in a location accessible by the extension's containing app, so that the
        // app may be notified about errors which occured while loading data even if the request to load data was initiated by
        // the user in Settings instead of via the app itself.
    }

}
