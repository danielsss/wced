# Wow Classic Enemy Detector

Current version: v0.28.14

## Overview

Wow Classic Enemy Detector is an enemy-faction detection and Battle.net relay addon for World of Warcraft Classic Era permanent level-60 realms.

Repository: https://github.com/danielsss/wced

## Installation

Copy the entire `WowDetector` folder into the addon directory shared by both clients:

`World of Warcraft/_classic_era_/Interface/AddOns/WowDetector`

The characters must use different Battle.net accounts, be Battle.net friends, and be online simultaneously. Enable the addon on both clients.

## Initial configuration

On the detector:

```
/wd role detector
/wd peer ListenerBattleTag#Number
```

On the listener:

```
/wd role listener
/wd peer DetectorBattleTag#Number
```

Enter the other account's complete BattleTag, for example `Nickname#1234`. Any number of peers can be added; the list supports scrolling and individual removal, and an older single-peer setting migrates automatically. Both accounts must be friends and online.

The detector sends a full character-friend snapshot initially, individual changes immediately, and a reconciliation snapshot every three minutes. Intel shows name, zone, and online state; online names use class colors and offline names are gray.

The first Intel column enables announcements per friend. Login or logout sends `[Name] Online/Offline -> Zone` to raid, or party when not in a raid. The initial snapshot sends no announcements.

The detector can grant management permission. An authorized listener can right-click an Intel name to copy it into chat or request removal from the detector's friend list.

Enemy queries, tracking, filters, and statistics announcements have been removed. Team retains same-faction level-60 queries; at 50 results, manually select a class and query again.

## Commands

- `/wd role detector|listener`: Set detector or listener role.
- `/wd peer Nickname#Number`: Add the other account's complete BattleTag.
- `/wd query`: Query the built-in zone selected in Team.
- `/wd queryui on|off`: Show or hide the detector query button.
- `/wd show`, `/wd hide`: Show or hide the team-query window.
- `/wd status`: Show current status.

## Limitations

- The addon records only enemies exposed to the client through visible nameplates, target, mouseover, or combat logs.
- `/who` queries only online players of the current faction.
- Every `/who` query requires a user click or key press; compliant background polling is impossible. The server also rate-limits queries, so wait for current results.
- Combat logs often provide only a name. Guild, level, class, and race may show Unknown unless the enemy is in valid unit range.
- Guild information is limited by distance and client cache and may temporarily be Unknown.
- Friend zones use Blizzard's cache and may lag behind real movement.
- This is not a map-wide scanner and does not read another game process's memory.
