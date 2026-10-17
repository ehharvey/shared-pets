# Testing Shared Sync

How to test CloudKit sharing between household members during development.

## Accounts
- CloudKit sharing needs at least two different Apple Accounts. You cannot accept a share you created yourself.
- App Store Connect sandbox testers do not work. They are for in-app purchase testing and cannot sign in to iCloud.
- Create a dedicated free Apple Account for testing, for example using a plus-address of your email.
- iCloud requires two-factor authentication, so the test account needs a trusted phone number. It can usually share a number with your main account.
- A third account is useful later for testing households with more than two members.

| Role | Account | Used for |
|---|---|---|
| Owner | Your main Apple Account | Creates the household and shares it |
| Participant | Test account 1 | Accepts the share and contributes |
| Participant 2 (later) | Test account 2 | Multi-member and leave or remove flows |

## Environments
- Builds run from Xcode use the CloudKit **Development** environment. TestFlight and App Store builds use **Production**.
- Development data is separate from Production, so test data never reaches real users.
- Reset the Development environment from the CloudKit Console when test data gets messy. Resetting also deletes the schema, so the app recreates it on the next run.
- Deploy the schema to Production before the first TestFlight build.

## Devices

| Setup | Speed | Fidelity | When to use |
|---|---|---|---|
| Two simulators, one account each | Fastest | Good | Daily development |
| One simulator plus an iPhone | Fast | Better | Notification and background checks |
| Two physical devices | Slowest | Real | Before every TestFlight build |

- Sign each simulator into a different account in the Settings app.
- Simulators on Apple silicon Macs can receive remote notifications, so CloudKit change notifications should arrive. Confirm timing on real devices.
- Run the app on multiple simulators from Xcode by switching run destination and running again, or install the built app with `simctl`.

## Share acceptance
- Add `CKSharingSupported` set to `YES` in Info.plist.
- Accept shares in a scene delegate with `windowScene(_:userDidAcceptCloudKitShareWith:)`. SwiftUI has no native hook for this, so the app needs a small UIKit adapter.
- To open a share link in a booted simulator:

```
xcrun simctl openurl booted "<share URL>"
```

## What to test where

| Concern | Unit tests with a fake | Two-account manual test |
|---|---|---|
| Recurrence "is due" logic | Yes | No |
| Pet need decay from completions | Yes | No |
| Merging completions from several members | Yes | Spot check |
| Share invite and acceptance | No | Yes |
| Participant permissions | No | Yes |
| Concurrent writes from two members | Partly | Yes |
| Change notifications and nudges | No | Yes |
| Leaving or being removed from a household | No | Yes |

Keep sync code behind a protocol so unit tests use an in-memory fake. Only real iCloud can verify the flows in the right-hand column.

## Manual test checklist
1. Owner creates a household and pet.
2. Owner shares it. Participant accepts the link.
3. Participant sees the pet and the owner's habits.
4. Participant completes a habit. Owner sees the completion and the pet update.
5. Both complete habits within a few seconds of each other. Both completions survive on both devices.
6. One device goes offline, completes a habit, then reconnects. The completion syncs.
7. Participant sends a nudge. Owner receives a notification.
8. Owner removes the participant. Participant loses access cleanly.
9. Participant leaves the household. Owner sees them gone.

## Inspecting data
In the CloudKit Console, look at the Development environment:
- The owner's household zone lives in the owner's **private** database.
- The participant sees that same zone through their **shared** database.
- Records written by the participant still land in the owner's zone.
