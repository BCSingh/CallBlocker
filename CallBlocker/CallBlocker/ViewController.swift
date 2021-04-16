//
//  ViewController.swift
//  CallBlocker
//
//  Created by Brian on 29/03/17.
//  Copyright © 2017 BCS. All rights reserved.
//

import UIKit
import Foundation
import Contacts
import CallKit

let appDelegate = UIApplication.shared.delegate as! AppDelegate

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var phoneTextFld: UITextField!
    @IBOutlet weak var tblView: UITableView!
    var refreshControl: UIRefreshControl!
    var blockList: [String] = []

    // MARK: - System methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.title = "Call blocklist";
        
        // add pull down to refresh
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Checking for new phone contacts")
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        self.tblView.refreshControl = refreshControl
        
        // show blocklist on screen
        self.loadContacts()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Button actions
    
    @IBAction func blockBtnAction(_ sender: Any) {
        
        var tel: String = String()
        tel = self.phoneTextFld.text!
        if tel.count == 0 {
            print("tel is nil")
            return
        }
        if !tel.hasPrefix("+") {
            print("Enter country dial code followed by phone number")
            return
        }
        tel = tel.removeFormat()
        
        self.phoneTextFld.text = ""
        self.view.endEditing(true)
        
        if self.blockList.contains(tel) {
            return
        }
        
        // add num to blocklist
        self.blockList.append(tel)
        
        //sort blocklist in ascending order
        self.blockList.sort()
        
        //reload listview
        self.tblView.reloadData();
        
        // Sync user defaults with the updated blocklist
        self.syncUD()
    }
    
    
    // MARK: - User defined methods
    
    @objc func refreshData(_ sender: Any) {
        self.loadContacts()
    }
    
    func syncUD() {
        //save blocklist in userdefaults
        appDelegate.updateBlockedContactsList(contacts: self.blockList)
        //reload extension to update blocklist entries
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.bcs.incomingBlocker.CallDirectoryHandler", completionHandler: nil)
    }
    
    func loadContacts() {
        // Check if user granted access to fetch contacts
        let status = CNContactStore.authorizationStatus(for: CNEntityType.contacts) as CNAuthorizationStatus
        if status == CNAuthorizationStatus.denied || status == CNAuthorizationStatus.restricted {
            let appDel = AppDelegate()
            appDel.promptUserForContactAccess()
            return
        }
        let contactStore = CNContactStore()
        contactStore.requestAccess(for: .contacts, completionHandler: { (granted, error) -> Void in
            if granted {
                // if granted access, contacts would have been stored in user defaults
                // so get the blocklist from user defaults
                DispatchQueue.main.async {
                    let blockedContacts = appDelegate.getBlockedContacts()
                    if blockedContacts.count == 0 {
                        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.bcs.incomingBlocker.CallDirectoryHandler", completionHandler: nil)
                        return
                    }
                    if blockedContacts.count > 0 {
                        // sort and display the blocklist
                        self.blockList = blockedContacts.sorted()
                        self.tblView.reloadData()
                    }
                }
            } else {
                appDelegate.promptUserForContactAccess()
            }
        })
        self.refreshControl.endRefreshing()
        
        //reload extension to update blocklist entries
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.bcs.incomingBlocker.CallDirectoryHandler", completionHandler: nil)
    }
    
    /* Function to sort the blocklist array by numerically ascending */
    func sortArray(arrayToSort: [String])->[String] {
        let sortedArray = arrayToSort.sorted(by:) {
            (first, second) in
            first.compare(second, options: .numeric) == ComparisonResult.orderedAscending
        }
        print(sortedArray)
        return sortedArray
    }
    
    // MARK: - Table view delegates & datasources
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        let number = self.blockList.count
        return number
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.tintColor = UIColor(red: 255.0/255.0, green:102.0/255.0, blue:102.0/255.0, alpha:1.0)
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        cell.selectionStyle = .none // to prevent cells from being "highlighted"
        
        let num = self.blockList[(indexPath as NSIndexPath).row]
        cell.textLabel!.text = num
        print("row \(indexPath.row) and item \(self.blockList[indexPath.row])")
        return cell
    }
    
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            self.blockList.remove(at: indexPath.row)
            self.tblView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            self.syncUD()
        }
    }
}
