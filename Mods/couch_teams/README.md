# Couch teams

A multiplayer script mod for 8-player couch sessions on one PC, where every player runs
their own copy of Black Ops II through Plutonium and joins one LAN private match
(for example with BO2 Split Launcher, which tiles four game windows per TV).

The game engine caps local splitscreen at 4 players, so 8 players means 8 game copies in one
match. This mod makes that match behave like a couch game:

- **One team per TV.** In team modes (TDM, Domination, S&D, Kill Confirmed and so on), players
  1-4 go on one team and players 5-8 on the other, so the players sharing a TV are teammates
  and nobody gains anything by watching the other TV.
- **Locked teams.** Picking a different team from the in-game menu is refused, so the sides stay put.
- **Team announcement.** On their first spawn each player sees which player number and team they are.

Free-for-all modes and bots are left alone.

## Install

The mod only has to be on the PC that hosts the match. Copy `scripts/mp/couch_teams.gsc` to:

```
%LOCALAPPDATA%\Plutonium\storage\t6\scripts\mp\couch_teams.gsc
```

Plutonium compiles and loads it when you host a match. No other build step is needed.
To remove it, delete the file.

## Player order

The mod numbers players from the `couch_order` setting: player names in order, separated by commas.
BO2 Split Launcher fills this in automatically from the lobby join order (the same order it uses to
place windows, players 1-4 on TV 1). If players swap quarters with the screen picker, teams still
follow the join order.

Without the launcher, add it to the host's command line, or type it in the host's console before
starting the match:

```
+set couch_order "Alice,Bob,Carl,Dana,Ed,Fay,Gus,Hal"
```

Players who aren't in the list are numbered after it, in the order they connect.

## Settings

| Setting | Default | What it does |
|---|---|---|
| `couch_teams` | `auto` | `tv`: players 1-4 against 5-8. `alternate`: players 1, 3, 5, 7 against 2, 4, 6, 8. `auto`: `tv` when `couch_order` lists more than one TV's worth of players, otherwise `alternate`. `off`: the game's normal team picking. |
| `couch_tv_size` | `4` | Players per TV. |
| `couch_lock` | `1` | `1` refuses team changes from the menu. `0` allows them. |
| `couch_order` | empty | Player names in order (see above). |

## Status

Not yet tested in game. It was checked by hand against this repo's
[compiler limitations](../../compiler%20limitations.md), but it hasn't been compiled or run.
If Plutonium reports a script error on load, the console line and number point at the problem.
