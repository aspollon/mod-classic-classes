# mod-classic-classes

**English** · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [简体中文](README.zh-Hans.md)

An AzerothCore module for **Conquest of Azeroth** (CoA): the classic classes - Warrior, Paladin, Hunter, Rogue, Priest,
Shaman, Mage, Warlock and Druid - next to the 21 classes of CoA, for players and for the random bots.

## How it works

CoA already plays the classic classes the way Ascension's **Warcraft Reborn** realms did: their Reborn spells (the
classic spells as Ascension tuned them for a world that ends at 60), class trainers that teach those spells, the
starting kit, the rank ladders, the talents and the creatures the spells summon. But CoA does that only on a realm
that offers nothing else (`CoA.ClassModel = "wcr"`), and the game client then shows only those classes.

This module brings both together:

- **The server** (`patches/core-classic-classes.patch`): a CoA realm also plays the classic classes the Warcraft
  Reborn way while `ClassicClasses.Enable` is on. Mystic altars and scrolls stay as on any CoA realm.
- **The scripts of the classes** (`patches/core-bronzebeard-lookups.patch`): the classic classes learn the Reborn
  copies of their spells (stock id + 1,100,000), while the scripts ask for the stock spells and auras. A question for a
  stock id that finds nothing asks for its copy as well.
- **Which classes** (`conf/mod_classic_classes.conf.dist`): `ClassicClasses.Classes` lists the classes that can be
  created; the others are added to the server's `CharacterCreating.Disabled.ClassMask`, which mod-playerbots honours
  for its random bots too. The Death Knight is never offered: his spells begin at 55.
- **Every race, every classic class** (`data/sql/db-world`): a race and class pair the server had no start for gets
  the start of its race and the starting action bars of its class - a Gnome Druid starts in Dun Morogh, a Tauren Mage
  in Mulgore. For these pairs CoA keeps only a showcase of high level armour as start outfit, without items; they get
  the start outfit of their class and sex from another race of the same faction instead (the Orc Druid, who has none,
  the Troll Druid's), on the server and in the character creation. The client patch adds the same pairs to the character creation (`CharBaseInfo.dbc`). The Hero (the
  free-pick class) stays closed outside a free-pick realm, for players and bots.
- **The game client** (`client/ClassicClasses.lua`): the class choice of the character creation shows the classic
  classes in a row of their own under the classes of CoA. The client otherwise shows either the one or the other.
- **The talent trees** of the classic classes show the Reborn talents only, instead of the stock ones on top of them.
- **The game's frames** (`client/ClassicClassesFrame.lua`): the client looks up the Reborn talents of a classic class
  only while the player plays a classic class himself; a player of a CoA class who inspected a classic character saw
  an empty build. The classic classes now always use the Reborn talents there. The Mystic Enchants tab of the
  character frame and of the inspect frame is left out, as CoA does for its own classes.
- **Talents of the bots** (`src/ClassicBots.cpp`): players pick the talents of a classic class in CoA's Character
  Advancement; mod-playerbots knows only the WotLK talent tree. The stock talents of the classic tabs, which CoA keeps
  piled on the first tier, are set aside on the server, so a bot learns the Reborn talents; and what a bot learns is
  written into its Character Advancement build too, so it can be inspected like a player. A bot made before keeps its
  talents and gets its build at its next login; making the bots anew gives all of them the Reborn talents.
- **Talent templates of the bots**: the Reborn trees are the WotLK trees, so mod-playerbots' templates (tank, healer
  and damage specializations, PvE and PvP) fit 22 of the 27 trees as they are. For the five Ascension changed -
  Protection (Warrior), Subtlety, Holy (Priest), Enhancement and Arcane - the module puts the templates in their order
  into playerbots.conf (`settings` in `afk-realm.json`); a point for a talent the Reborn tree lacks goes where the bot
  sees fit. The bots play the classic classes with mod-playerbots' own class AI: it finds spells by their names, and the
  Reborn copies carry the names of the stock spells.

The talent points are those of CoA: 51 at level 60, as for the CoA classes. The spells come up to the level of the
realm; with a level cap of 60 the ranks above 60 are never learned.

## Installation

**With [AFK Realm](https://github.com/aspollon/AFK-Realm)** (0.8.4 or newer): add the module. AFK Realm applies the
two patches, sets `AiPlayerbot.CoaClassesOnly = 0` in playerbots.conf, applies the SQL of the module, builds the client
patch from your own game client (`Data\patch-Y.MPQ`: the class choice, the race and class pairs and the talent table)
and puts it into your game, and offers once to make the random bots anew so they come in the classic classes too. *Modules › Game client › Export as ZIP* gives the other
players the same patch.

**By hand:**

1. Clone the module into `modules/` and apply both patches in the core (`git apply modules/mod-classic-classes/patches/<patch>`).
2. Rebuild, and copy `conf/mod_classic_classes.conf.dist` next to the other module configs as `mod_classic_classes.conf`.
3. Apply `data/sql/db-world/*.sql` to the world database (the core's updater does it for module SQL).
4. Set `AiPlayerbot.CoaClassesOnly = 0` in playerbots.conf, and delete the random bots once
   (`AiPlayerbot.DeleteRandomBotAccounts = 1` for one start).
5. The client: an MPQ patch that loads after the client's own (for example `Data\patch-Y.MPQ`) with
   - `Interface\GlueXML\ClassicClasses.lua` from `client/`,
   - `Interface\GlueXML\GlueXML.toc` of your client with the line `ClassicClasses.lua` after `CharacterCreate.xml`,
   - `Interface\FrameXML\ClassicClassesFrame.lua` from `client/`,
   - `Interface\FrameXML\FrameXML.toc` of your client with the line `ClassicClassesFrame.lua` after
     `Ascension_CharacterFrame\CharacterFrame.xml`,
   - `DBFilesClient\Talent.dbc` of your client without the talents below id 100000 of the classic talent tabs
     (the list is in `afk-realm.json`),
   - `DBFilesClient\CharBaseInfo.dbc` of your client with a row for every race and classic class pair it lacks
     (two bytes a row: race, class; races 1-8, 10, 11; classes 1-5, 7-9, 11). The character creation takes at most
     30 classes for a race and crashes with more, so the rows of the Death Knight and the Hero (neither can be
     created next to the classic classes) and a row the table has twice make room: 30 classes a race.
   - `DBFilesClient\CharStartOutfit.dbc` of your client with an outfit for the Orc Druid (a copy of the Troll
     Druid's), and the items of a sibling in the outfits CoA keeps only for show (see below).

## Status

**Test version.** Compiled against the CoA core of 10 October 2026; the client patch built from the CoA client and
read back with StormLib. Not yet played on a server: the class choice, the talent window and the bots of the classic
classes still need a look in the game.

## Credits

- Conquest of Azeroth (Conquest-of-AzerothCore/azerothcore-wotlk-coa) for its Warcraft Reborn classes.
- ilusixn's CoA Custom (https://github.com/ilusixn/azerothcore-wotlk-coa), which showed the way: the lookup of the
  Reborn copies and the class choice of the client follow its work.

## License

GNU AGPL v3, like AzerothCore.

## Languages

`lang/<code>.json` carries the texts AFK Realm shows of this module (its option descriptions, the names and reasons of `afk-realm.json`) in German, French, Spanish, Portuguese (Brazil), Russian and Simplified Chinese. AFK Realm's `tools/lang.py --module <folder> check` lists what a change left untranslated.
