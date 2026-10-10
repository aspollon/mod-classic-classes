/*
 * mod-classic-classes - the classic classes next to the classes of Conquest of Azeroth.
 * Released under GNU AGPL v3: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 *
 * Conquest of Azeroth plays the classic classes the way Ascension's Warcraft Reborn realms did - their Reborn spells,
 * trainers, talents and summons - but only on a realm that offers nothing else (CoA.ClassModel = "wcr"). The core
 * patch of this module (patches/core-classic-classes.patch) lets a Conquest of Azeroth realm offer them too, while
 * ClassicClasses.Enable is on. This file decides which of them can be created: the Death Knight never (his spells
 * begin at 55), the others as ClassicClasses.Classes says.
 */

#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "StringConvert.h"
#include "Tokenize.h"
#include "World.h"

#include <set>
#include <string>

namespace
{
    constexpr uint32 Bit(uint32 classId) { return 1u << (classId - 1); }

    // The classic classes a character can be created in: all of them but the Death Knight.
    constexpr uint32 PLAYABLE = Bit(CLASS_WARRIOR) | Bit(CLASS_PALADIN) | Bit(CLASS_HUNTER) | Bit(CLASS_ROGUE) |
        Bit(CLASS_PRIEST) | Bit(CLASS_SHAMAN) | Bit(CLASS_MAGE) | Bit(CLASS_WARLOCK) | Bit(CLASS_DRUID);
    constexpr uint32 ALL_CLASSIC = PLAYABLE | Bit(CLASS_DEATH_KNIGHT);

    char const* Name(uint32 classId)
    {
        switch (classId)
        {
            case CLASS_WARRIOR: return "Warrior";
            case CLASS_PALADIN: return "Paladin";
            case CLASS_HUNTER: return "Hunter";
            case CLASS_ROGUE: return "Rogue";
            case CLASS_PRIEST: return "Priest";
            case CLASS_DEATH_KNIGHT: return "Death Knight";
            case CLASS_SHAMAN: return "Shaman";
            case CLASS_MAGE: return "Mage";
            case CLASS_WARLOCK: return "Warlock";
            case CLASS_DRUID: return "Druid";
            default: return "?";
        }
    }

    /// The classic classes ClassicClasses.Classes lets players create, as a class mask.
    uint32 Wanted()
    {
        std::string const list = sConfigMgr->GetOption<std::string>("ClassicClasses.Classes", "1 2 3 4 5 7 8 9 11");
        uint32 mask = 0;
        for (std::string_view token : Acore::Tokenize(list, ' ', false))
            if (Optional<uint32> classId = Acore::StringTo<uint32>(token))
                if (*classId >= 1 && *classId <= 11 && (Bit(*classId) & ALL_CLASSIC))
                    mask |= Bit(*classId);
        if (mask & Bit(CLASS_DEATH_KNIGHT))
            LOG_WARN("module", "mod-classic-classes: the Death Knight cannot be played - his spells begin at 55; left out");
        return mask & PLAYABLE;
    }
}

class ClassicClassesWorld : public WorldScript
{
public:
    ClassicClassesWorld() : WorldScript("ClassicClassesWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

    /// The core reads CharacterCreating.Disabled.ClassMask from worldserver.conf just before this; the classic classes
    /// not offered are added to it. mod-playerbots creates its random bots by the same mask.
    void OnAfterConfigLoad(bool /*reload*/) override
    {
        uint32 mask = sWorld->getIntConfig(CONFIG_CHARACTER_CREATING_DISABLED_CLASSMASK);
        bool const enabled = sConfigMgr->GetOption<bool>("ClassicClasses.Enable", true);
        uint32 const wanted = enabled ? Wanted() : 0;
        mask |= ALL_CLASSIC & ~wanted;
        // The Hero (class 10) is the free-pick class of a realm with CoA.ClassModel = "hero". Elsewhere nobody can
        // play him, and mod-playerbots, once it may create other classes than those of CoA, would make random bots
        // of him that it cannot give talents to - the world server stops at the first of them.
        std::string const model = sConfigMgr->GetOption<std::string>("CoA.ClassModel", "coa");
        if (model != "hero")
            mask |= Bit(CLASS_HERO);
        sWorld->setIntConfig(CONFIG_CHARACTER_CREATING_DISABLED_CLASSMASK, mask);

        if (!enabled)
        {
            LOG_INFO("module", "mod-classic-classes: off - only the classes of Conquest of Azeroth can be created");
            return;
        }
        if (model != "coa")
            LOG_WARN("module", "mod-classic-classes: CoA.ClassModel is \"{}\" in coa.conf; the classic classes are offered next to "
                "the classes of Conquest of Azeroth only with \"coa\"", model);

        std::string names;
        for (uint32 classId = CLASS_WARRIOR; classId <= CLASS_DRUID; ++classId)
            if (wanted & Bit(classId))
                names += std::string(names.empty() ? "" : ", ") + Name(classId);
        LOG_INFO("module", "mod-classic-classes: classic classes next to Conquest of Azeroth: {}", names.empty() ? "none" : names);
    }

    /// Random bots of the Hero made before this module kept mod-playerbots from making them: removed before the bots
    /// come into the world, since the first of them would stop the world server.
    void OnStartup() override
    {
        if (sConfigMgr->GetOption<std::string>("CoA.ClassModel", "coa") == "hero")
            return;
        std::string const prefix = sConfigMgr->GetOption<std::string>("AiPlayerbot.RandomBotAccountPrefix", "rndbot");
        if (prefix.empty())
            return;
        QueryResult accounts = LoginDatabase.Query("SELECT id FROM account WHERE username LIKE '{}%'", prefix);
        if (!accounts)
            return;
        std::string ids;
        do
            ids += (ids.empty() ? "" : ",") + std::to_string((*accounts)[0].Get<uint32>());
        while (accounts->NextRow());
        QueryResult heroes = CharacterDatabase.Query("SELECT guid, account FROM characters WHERE class = {} AND account IN ({})",
            uint32(CLASS_HERO), ids);
        if (!heroes)
            return;
        uint32 removed = 0;
        do
        {
            Field* fields = heroes->Fetch();
            Player::DeleteFromDB(fields[0].Get<uint32>(), fields[1].Get<uint32>(), false, true);
            ++removed;
        } while (heroes->NextRow());
        LOG_INFO("module", "mod-classic-classes: removed {} random bot(s) of the Hero class, which only a free-pick realm plays", removed);
    }
};

void AddSC_classic_classes()
{
    new ClassicClassesWorld();
}
