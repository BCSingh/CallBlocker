//
//  AppDelegate.swift
//  CallBlocker
//
//  Created by Brian on 29/03/17.
//  Copyright © 2017 BCS. All rights reserved.
//

import UIKit
import Contacts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func applicationDidFinishLaunching(_ application: UIApplication) {
        self.loadContacts()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    public func loadContacts() {
        
        let status = CNContactStore.authorizationStatus(for: CNEntityType.contacts) as CNAuthorizationStatus
        if status == CNAuthorizationStatus.denied || status == CNAuthorizationStatus.restricted {
            self.promptUserForContactAccess()
            return
        }
        
        let contactStore = CNContactStore()
        contactStore.requestAccess(for: .contacts, completionHandler: { (granted, error) -> Void in
            if granted == false {
                // request again
                self.promptUserForContactAccess()
            }
            else {
                let predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactStore.defaultContainerIdentifier())
                var contacts: [CNContact]! = []
                do {
                    contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactPhoneNumbersKey as CNKeyDescriptor])
                    
                    if contacts.count == 0 {
                        return
                    }
                    
                    let finalArrayForContacts = NSMutableArray()
                    
                    for contactTemp in contacts {
                        let contactNew = contactTemp
                        let tempArray : NSMutableArray = NSMutableArray()
                        if (contactNew.phoneNumbers).count > 0 {
                            
                            var numArray : NSArray = NSArray()
                            numArray = contactNew.phoneNumbers as NSArray
                            for cnLblValue in numArray {
                                let cnLabelValue = cnLblValue as! CNLabeledValue<CNPhoneNumber>
                                let cnPhNum = cnLabelValue.value
//                                let phNum : CNPhoneNumber = CNPhoneNumber(stringValue: cnPhNum.stringValue)
//                                var cnPhNum : CNPhoneNumber = CNPhoneNumber()
//                                cnPhNum = (cnLblValue as AnyObject).value(forKey: "value") as! CNPhoneNumber
//                                var tempStr : NSString = NSString()
//                                tempStr = cnPhNum.value(forKey: "digits") as! NSString
                                let tempStr = self.removeFormat(fromMobileNumber: cnPhNum.stringValue) as NSString
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
                        }
                        
                    }
                    
                    finalArrayForContacts.sort(using: [NSSortDescriptor.init(key: "self", ascending: true)])
                    
                    let defaults = UserDefaults(suiteName: "group.com.incomingBlocker")
                    defaults?.set(finalArrayForContacts, forKey: "blockList")
                    defaults?.synchronize()
                    
                }catch {
                    
                }
            }
        })
        
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
    
    
    public func promptUserForContactAccess() {
        
        let alert = UIAlertController(title: "Access to contacts.",
                                      message: "This app requires access to contacts",
                                      preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { (UIAlertAction) in
            UIApplication.shared.open(NSURL.init(string: UIApplication.openSettingsURLString)! as URL, options: [:], completionHandler: nil)
        }
        alert.addAction(settingsAction)
        
        self.window?.rootViewController?.present(alert, animated: true) {
            
        }
    }

}

