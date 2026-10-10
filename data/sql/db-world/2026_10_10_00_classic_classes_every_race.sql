-- mod-classic-classes: every race can be every classic class (Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage,
-- Warlock, Druid). A pair the server has no start for gets one: the place where its race starts (the start of its
-- first classic class) and the starting action bars of its class (those of the first race that already plays it).
-- Pairs that exist are not touched, so running this again changes nothing. The client patch of the module lets the character creation offer
-- the same pairs (CharBaseInfo.dbc).

INSERT INTO `playercreateinfo_action` (`race`, `class`, `button`, `action`, `type`)
SELECT p.`race`, p.`class`, a.`button`, a.`action`, a.`type`
FROM (SELECT r.`race`, c.`class`
      FROM (SELECT 1 AS `race` UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
            SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 10 UNION ALL SELECT 11) r
      CROSS JOIN (SELECT 1 AS `class` UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
                  SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 11) c
      WHERE NOT EXISTS (SELECT 1 FROM `playercreateinfo` x WHERE x.`race` = r.`race` AND x.`class` = c.`class`)) p
JOIN (SELECT `class`, MIN(`race`) AS `donor` FROM `playercreateinfo_action` WHERE `race` BETWEEN 1 AND 11 GROUP BY `class`) d
  ON d.`class` = p.`class`
JOIN `playercreateinfo_action` a ON a.`race` = d.`donor` AND a.`class` = p.`class`
WHERE NOT EXISTS (SELECT 1 FROM `playercreateinfo_action` y WHERE y.`race` = p.`race` AND y.`class` = p.`class`);

INSERT INTO `playercreateinfo` (`race`, `class`, `map`, `zone`, `position_x`, `position_y`, `position_z`, `orientation`)
SELECT r.`race`, c.`class`, w.`map`, w.`zone`, w.`position_x`, w.`position_y`, w.`position_z`, w.`orientation`
FROM (SELECT 1 AS `race` UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
      SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 10 UNION ALL SELECT 11) r
CROSS JOIN (SELECT 1 AS `class` UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
            SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 11) c
JOIN (SELECT `race`, MIN(`class`) AS `donor` FROM `playercreateinfo` WHERE `class` <= 11 GROUP BY `race`) s ON s.`race` = r.`race`
JOIN `playercreateinfo` w ON w.`race` = r.`race` AND w.`class` = s.`donor`
WHERE NOT EXISTS (SELECT 1 FROM `playercreateinfo` x WHERE x.`race` = r.`race` AND x.`class` = c.`class`);
