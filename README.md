# CallBlocker

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/177288585b79415884c4bc0ba9354316)](https://app.codacy.com/manual/brianc_2/CallBlocker?utm_source=github.com&utm_medium=referral&utm_content=BCSingh/CallBlocker&utm_campaign=Badge_Grade_Dashboard)

An iOS call blocker sample app in Swift using CallKit

Helpful when you want to block all calls from all known contacts at a time without going for Airplane mode. You can whitelist selected numbers too.

Language: Swift 3

Support from iOS 10

- Maintains a local blocklist in app. 
- All your phone contacts will be added to this blocklist
- Pull down to refresh will check and add any new contacts from your Phone Contacts to this blocklist.
- Swipe right to left for deleting the number from blocklist (whitelisting the contact)
- Multi select and delete contacts from blocklist
- Text entry any phone number with local code to block it
