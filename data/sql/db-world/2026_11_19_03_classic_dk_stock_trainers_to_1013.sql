-- The Ebon Hold / Acherus death knight trainers still used the stock trainer 13 (55-80).
-- Map them to trainer 1013, the classic 1-60 trainer added by 2026_11_18_03, so a
-- level 1 death knight sees Plague Strike and the rest of the 1-60 progression.

UPDATE `creature_default_trainer`
SET `TrainerId` = 1013
WHERE `TrainerId` = 13
  AND `CreatureId` IN (28471, 28472, 28474, 29194, 29195, 29196, 31084);
