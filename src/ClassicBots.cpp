/*
 * mod-classic-classes - the classic classes next to the classes of Conquest of Azeroth.
 * Released under GNU AGPL v3: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 *
 * The talents of the classic classes. A player of a classic class picks them in CoA's Character Advancement, as on
 * Ascension's Warcraft Reborn realms: the build is kept with the character and grants the Reborn talents (Talent.dbc
 * rows from id 100000 on, whose spells are the Reborn copies). The random bots of mod-playerbots know only the talent
 * tree of WotLK. Two things let them play these classes too:
 *
 * - The stock talents of the classic tabs (ids below 100000) are taken out of their tab. CoA keeps them only for its
 *   own data - all piled on the first tier, with spells of their own - and a bot that took them would learn those
 *   instead of the Reborn talents beside them.
 * - What a bot learns in the talent tree is written into its Character Advancement build as well, so that it can be
 *   inspected like a player and CoA keeps its talents.
 */

#include "AscensionFreepick.h"
#include "AscensionFreepickRules.h"
#include "Config.h"
#include "DBCStores.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "WorldSession.h"

#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
    // The talent tabs of the classic classes (Warrior to Druid, without the Death Knight).
    std::unordered_set<uint32> const CLASSIC_TABS = { 161, 163, 164, 381, 382, 383, 361, 362, 363, 181, 182, 183, 201, 202, 203,
        261, 262, 263, 41, 61, 81, 301, 302, 303, 281, 282, 283 };

    struct Spot
    {
        uint32 EntryId = 0;
        uint32 Rank = 0;
    };

    // Reborn talent spell -> (Character Advancement entry, rank), per class.
    std::unordered_map<uint64, Spot> spots;
    bool active = false;

    uint64 Key(uint32 classId, uint32 spellId) { return (uint64(classId) << 32) | spellId; }

    bool Enabled()
    {
        return sConfigMgr->GetOption<bool>("ClassicClasses.Enable", true) &&
            sConfigMgr->GetOption<std::string>("CoA.ClassModel", "coa") == "coa";
    }

    bool IsClassicBot(Player const* player)
    {
        return active && player && player->GetSession() && player->GetSession()->IsBot() &&
            AscensionFreepick::HasFreepickBuild(player);
    }

    std::vector<AscensionCoATalentState::KnownEntry> Known(Player const* player)
    {
        return AscensionFreepick::KnownEntries(player);
    }

    void Upload(Player* player, std::vector<AscensionCoATalentState::KnownEntry> const& entries, char const* why)
    {
        AscensionFreepick::UploadResult const result = AscensionFreepick::ApplyUpload(player, entries);
        if (std::string(result.Result) != "CA_UPDATE_ENTRIES_OK")
            LOG_DEBUG("module", "mod-classic-classes: the Character Advancement of bot {} was not changed ({}): {} {} entry {} rank {}",
                player->GetName(), why, result.Result, result.Learn, result.EntryId, result.Rank);
    }

    /// The bot's talents of the active spec as Character Advancement entries.
    std::vector<AscensionCoATalentState::KnownEntry> FromTalents(Player const* player)
    {
        std::vector<AscensionCoATalentState::KnownEntry> entries;
        std::unordered_map<uint32, size_t> at;
        for (auto const& [spellId, talent] : player->GetTalentMap())
        {
            if (!talent || talent->State == PLAYERSPELL_REMOVED || !talent->IsInSpec(player->GetActiveSpec()))
                continue;
            auto spot = spots.find(Key(player->getClass(), spellId));
            if (spot == spots.end())
                continue;
            auto known = at.find(spot->second.EntryId);
            if (known == at.end())
            {
                at[spot->second.EntryId] = entries.size();
                entries.push_back({ spot->second.EntryId, spot->second.Rank, spot->second.Rank, false, uint32(entries.size() + 1) });
            }
            else if (entries[known->second].Rank < spot->second.Rank)
                entries[known->second].Rank = entries[known->second].LearnedSpellRank = spot->second.Rank;
        }
        return entries;
    }
}

class ClassicBotsWorld : public WorldScript
{
public:
    ClassicBotsWorld() : WorldScript("ClassicBotsWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        active = false;
        spots.clear();
        if (!Enabled())
            return;

        uint32 hidden = 0;
        for (TalentEntry const* talent : sTalentStore)
            if (talent && talent->TalentID < 100000 && CLASSIC_TABS.count(talent->TalentTab))
            {
                const_cast<TalentEntry*>(talent)->TalentTab = 0;
                ++hidden;
            }

        AscensionFreepick::Catalog catalog;
        if (!AscensionFreepick::LoadCatalog(catalog))
        {
            LOG_ERROR("module", "mod-classic-classes: the Character Advancement data did not load; the bots of the classic classes keep "
                "their talents without a build");
            return;
        }
        for (uint32 classId = CLASS_WARRIOR; classId <= CLASS_DRUID; ++classId)
        {
            if (classId == CLASS_DEATH_KNIGHT || classId == CLASS_HERO)
                continue;
            for (auto const& [entryId, row] : catalog.Rows)
            {
                if (row.Type != AscensionFreepick::ENTRY_TALENT || !AscensionFreepick::ClassAdmits(catalog, row, classId))
                    continue;
                for (uint32 rank = 0; rank < AscensionFreepick::RANK_COUNT && row.Spells[rank]; ++rank)
                    spots.emplace(Key(classId, row.Spells[rank]), Spot{ entryId, rank + 1 });
            }
        }
        active = true;
        LOG_INFO("module", "mod-classic-classes: {} stock talent(s) of the classic tabs set aside, {} Reborn talent rank(s) known to the "
            "bots' Character Advancement", hidden, spots.size());
    }
};

class ClassicBotsPlayer : public PlayerScript
{
public:
    ClassicBotsPlayer() : PlayerScript("ClassicBotsPlayer", { PLAYERHOOK_ON_PLAYER_LEARN_TALENTS, PLAYERHOOK_ON_TALENTS_RESET, PLAYERHOOK_ON_LOGIN }) { }

    /// A talent a bot learns goes into its build as well.
    void OnPlayerLearnTalents(Player* player, uint32 /*talentId*/, uint32 /*talentRank*/, uint32 spellId) override
    {
        if (!IsClassicBot(player))
            return;
        auto spot = spots.find(Key(player->getClass(), spellId));
        if (spot == spots.end())
            return;
        auto entries = Known(player);
        bool found = false;
        for (auto& entry : entries)
            if (entry.EntryId == spot->second.EntryId)
            {
                if (entry.Rank >= spot->second.Rank)
                    return;
                entry.Rank = entry.LearnedSpellRank = spot->second.Rank;
                found = true;
            }
        if (!found)
            entries.push_back({ spot->second.EntryId, spot->second.Rank, spot->second.Rank, false, uint32(entries.size() + 1) });
        Upload(player, entries, "talent learned");
    }

    /// A bot that resets its talents (mod-playerbots does when it makes a bot anew) empties its build too.
    void OnPlayerTalentsReset(Player* player, bool /*noCost*/) override
    {
        if (IsClassicBot(player) && !Known(player).empty())
            Upload(player, {}, "talents reset");
    }

    /// A bot made before this module knew the talents: its build follows the talents it has.
    void OnPlayerLogin(Player* player) override
    {
        if (!IsClassicBot(player) || !Known(player).empty())
            return;
        auto entries = FromTalents(player);
        if (!entries.empty())
            Upload(player, entries, "login");
    }
};

void AddSC_classic_bots()
{
    new ClassicBotsWorld();
    new ClassicBotsPlayer();
}
