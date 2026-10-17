# Architecture Proposal

## Guiding constraint: minimal infra cost
Use Apple's CloudKit instead of running a server. Private and shared CloudKit data counts against each user's own iCloud storage, so the developer pays nothing for typical usage. Sign in is implicit through the user's Apple Account.

## Stack
| Layer | Choice | Notes |
|---|---|---|
| UI | SwiftUI | iOS first. Adaptive layouts keep iPad cheap. |
| State | Observation (`@Observable`) | No Combine. async/await everywhere. |
| Local storage | SwiftData | Source of truth on device. Works offline. |
| Sync and sharing | CloudKit with `CKSyncEngine` | SwiftData's built-in CloudKit sync does not support shared databases, so sharing needs its own sync layer. |
| Invitations | `CKShare` with the system share sheet | Invite by Messages or link. No custom accounts. |
| Notifications | Local notifications for reminders. CloudKit subscriptions for nudges and feed updates. | No push server needed. |
| Pet rendering | SpriteKit or layered SwiftUI images, decided after a prototype | See open questions. |
| Tests | Swift Testing for logic. XCUIAutomation for key flows. | |

## Data model sketch
```
Household   id, name, petID, createdAt                    (CKShare root record)
Member      id, householdID, displayName, avatar
Pet         id, householdID, name, breed, needs{hunger, energy, hygiene, happiness}, needsUpdatedAt, xp, cosmetics
Habit       id, householdID, ownerID, title, careAct, recurrence, reminderTime, isPrivateTitle, archivedAt
Completion  id, habitID, memberID, date, careAct
Nudge       id, fromMemberID, toMemberID, habitID?, sentAt
```

## Key design decisions
- **Derive pet needs from completions.** Store completions as immutable events. Compute needs from events plus time-based decay. This avoids sync conflicts when two members complete habits at the same moment. Cache the computed value for speed.
- **Decay is deterministic.** Every device computes the same needs from the same events and clock time. No server tick is required.
- **Recurrence is a value type.** An enum with associated values, encoded as a small Codable payload. "Is this due on date D" lives in one pure function that is easy to unit test.
- **Household data lives in a shared zone.** The creator owns the zone in their private database. Members access it through the shared database.
- **Personal-only habits stay in the private database** if a later feature adds habits that do not feed a pet.

## Risks
- `CKSyncEngine` sharing is more work than SwiftData's automatic sync. The M0.5 spike in the [Roadmap](ROADMAP.md) checks it before the data model is locked. Testing setup is in [Testing Shared Sync](TESTING_SHARED_SYNC.md).
- CloudKit subscription delivery is best effort. Nudges may arrive late. That is acceptable for this app.
- Time zones differ between members. Habit "days" should use each owner's local calendar.
