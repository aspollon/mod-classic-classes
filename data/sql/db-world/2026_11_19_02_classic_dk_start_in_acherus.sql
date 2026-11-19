-- mod-classic-classes: a new Death Knight starts in Acherus for the intro video, as mod-dk has it. ModDk.cpp sends
-- him to the racial start once the video has played (DkTeleportAfterCinematicEvent). This file sorts after
-- 2026_11_18_18_classic_dk_start_at_race.sql and takes its place.

UPDATE `playercreateinfo`
SET `map` = 609,
    `zone` = 0,
    `position_x` = 2355.84,
    `position_y` = -5664.77,
    `position_z` = 426.028,
    `orientation` = 3.65997
WHERE `class` = 6;
