-- mod-classic-classes: the Death Knight plays levels 1-60 (mod_dk_spell_progression ends at 60). The trainer of
-- mod-dk (2026_11_18_03) also lists the stock WotLK spells 61-80, which a classic Death Knight can never reach, so
-- they are taken out here. This file sorts after 2026_11_18_03, so the trainer import keeps them out.

DELETE FROM `trainer_spell` WHERE `TrainerId` = 1013 AND `ReqLevel` > 60;
