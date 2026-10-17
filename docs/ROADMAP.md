# Roadmap

Each milestone should end with a build that runs on a real iPhone.

## M0: Foundations
- [ ] Rename the app target and bundle identifier from the template.
- [ ] Set up folder structure: Models, Features, Services, Resources.
- [ ] Add a unit test target with Swift Testing.
- [ ] Enable the iCloud capability with a CloudKit container.
- [ ] Create a second Apple Account for testing. See [Testing Shared Sync](TESTING_SHARED_SYNC.md).

## M0.5: Shared sync spike (timebox: 3 days)
CloudKit sharing itself is proven. This spike checks our specific combination before the data model is locked in M1. The code is throwaway.

Goal: prove the shape of the sync layer, not build it.
- [ ] Owner creates a household zone with one Pet and one Completion record.
- [ ] Owner shares the zone with `CKShare`. Participant accepts it through the scene delegate.
- [ ] Both accounts write Completion records with `CKSyncEngine`. Both see each other's records.
- [ ] Two near-simultaneous completions both survive.
- [ ] A change notification reaches the other device.
- [ ] Decide how SwiftData models map to CloudKit records, or whether to drop SwiftData for a simpler local store.

Exit criteria: write the findings into [Architecture](ARCHITECTURE.md). If the spike fails, fall back to Core Data with `NSPersistentCloudKitContainer` sharing.

## M1: Solo habit tracker (local only)
- [ ] SwiftData models for Habit and Completion.
- [ ] Recurrence enum and "is due on date" logic with tests.
- [ ] Today screen listing due habits with a check-off action.
- [ ] Create and edit habit form, including care act choice.
- [ ] Local reminder notifications.

## M2: Pet prototype (local only)
- [ ] Pet model with needs and decay logic, fully unit tested.
- [ ] Shih Tzu art prototype with idle, happy, sad, and messy states.
- [ ] Care act animations for Feed, Walk, Groom, Play.
- [ ] Pet home screen that reacts to completions.

## M3: Shared raising
- [ ] Build the production sync layer using the M0.5 findings.
- [ ] Create a household and invite members with `CKShare`.
- [ ] Sync habits, completions, and pet state across members.
- [ ] Contribution feed.
- [ ] Nudges via CloudKit subscriptions, rate limited to one per member per day.

## M4: Polish and TestFlight
- [ ] Onboarding: name your pet, create your first habit, invite someone.
- [ ] Pet growth rewards: tricks and grooming styles.
- [ ] Accessibility pass: VoiceOver, Dynamic Type, contrast.
- [ ] TestFlight with a few real households.

## Later (optional)
- Apple Watch app and complications.
- iPad layout tuning.
- Widgets and Live Activities for the pet.
- macOS.
- More breeds.
