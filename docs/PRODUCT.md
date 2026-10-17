# Product Brief: Shared Pets (working title)

## Pitch
A social habit tracker. Completing a habit performs a "care act" for a virtual pet that you raise together with friends, family, or a partner. The pet reflects how well the group is keeping up its habits, so everyone has a reason to show up.

## Target users
- Couples, roommates, and small friend groups (2 to 6 people) who want light accountability.
- People who bounce off plain checklist habit apps and respond better to something they care for.

## Core concepts

| Concept | Description |
|---|---|
| Pet | A shared virtual animal. First breed: Shih Tzu. Has needs that decay over time. |
| Household | The group of people raising one pet. A user can belong to more than one. |
| Habit | A personal recurring task owned by one member, e.g. "Run 20 min". |
| Care act | What a habit completion does for the pet: Feed, Walk, Groom, Play, Train. |
| Need | A pet stat restored by care acts: Hunger, Energy, Hygiene, Happiness. |
| Nudge | A lightweight "poke" sent to a member who has not done today's habit. |

## How habits map to the pet
- Each habit is assigned a care act when created. The app suggests one based on the habit category, e.g. exercise maps to Walk, chores map to Groom.
- Completing a habit restores the matching need and adds an animation for everyone in the household.
- Needs decay slowly on a schedule. The decay rate scales with household size so larger groups are not trivially easy.
- The pet never dies. Neglect leads to visible sadness, messy fur, and lower energy. Recovery is always possible. Punishing designs drive people away from habit apps.

## Recurrence (first proposal)
1. Daily.
2. Specific weekdays, e.g. Mon, Wed, Fri.
3. X times per week, any days.
4. Every N days.

Monthly and custom schedules are deferred until real usage shows a need.

## Social mechanics (to refine)
- **Shared raising.** The pet's mood is the sum of everyone's contributions. A member's missed habit is visible to the group as an unmet need, not as a public shame list.
- **Nudges.** One tap sends a poke to a member. Limit it to one nudge per member per day to avoid spam.
- **Contribution feed.** A short timeline such as "Sam walked Biscuit (Morning run)".
- **Streaks as pet growth.** Group consistency unlocks tricks, accessories, and grooming styles. Shih Tzu haircuts are a natural cosmetic reward.
- **Privacy.** Members choose whether habit names are shown or only the care act.

## Platforms
| Platform | Priority |
|---|---|
| iPhone | Required for v1 |
| Apple Watch | Optional. Quick habit check-off and complications. |
| iPad | Optional. Mostly free with an adaptive SwiftUI layout. |
| macOS | Optional. Low priority. |

## Non-goals for v1
- Public social network, followers, or leaderboards with strangers.
- Android or web clients.
- Monetization. Revisit after v1 with cosmetic items only.
- Multiple pet types. The data model should allow them later.

## Success signals
- Members in a household complete habits on most scheduled days after four weeks.
- Most households keep at least two active members after four weeks.
- Nudges lead to a completion the same day more often than not.
