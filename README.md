# CallBlocker

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/177288585b79415884c4bc0ba9354316)](https://app.codacy.com/manual/brianc_2/CallBlocker?utm_source=github.com&utm_medium=referral&utm_content=BCSingh/CallBlocker&utm_campaign=Badge_Grade_Dashboard)

An iOS call blocker sample app in Swift using CallKit

Helpful when you want to block all calls from all known contacts at a time without going for Airplane mode. You can whitelist selected numbers too.
On the other hand, this code can be modified and used as a call blocker app to block only the specific numbers that you add to block

Language: Swift 5

Supports from iOS 12.0

- Maintains a local blocklist in app. 
- The sample adds all your phone contacts to this blocklist
- Pull down to refresh will check for any new contacts from your Phone Contacts and add to this blocklist.
- Swipe left on numbers to delete them from blocklist (whitelisting the contact)
- Enter phone number with dial code to block it (example: +919876543210 or +19876543210)
