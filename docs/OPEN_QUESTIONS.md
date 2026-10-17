# Open Questions

Decisions needed before or during the milestone listed.

| # | Question | Needed by | Current lean |
|---|---|---|---|
| 1 | Which recurrence types ship in v1? | M1 | Daily, weekdays, X per week, every N days |
| 2 | Does every habit feed the shared pet, or can some be private? | M1 | All feed the pet. Titles can be hidden. |
| 3 | Can one person belong to multiple households and pets? | M3 | Yes, but design v1 screens around one |
| 4 | Is there a household size cap? | M3 | Six members |
| 5 | How should a member who stops participating be handled? | M3 | Decay scales by active members only |
| 6 | 2D art style and source: commission, generate, or hand draw? | M2 | Prototype with placeholder art first |
| 7 | SpriteKit versus layered SwiftUI images for the pet? | M2 | Try SwiftUI first. It is simpler to integrate. |
| 8 | Minimum iOS version? | M0 | Latest major iOS minus one. `CKSyncEngine` needs iOS 17. |
| 9 | Do nudges include an optional short message? | M3 | Preset emoji or phrases only, to keep it light |
| 10 | Final app name? | M4 | Open |
