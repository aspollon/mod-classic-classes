-- mod-classic-classes: level 1 Death Knights start where their race starts, not in Acherus.
-- The base mod-dk SQL (2026_11_18_10) puts every DK in Acherus for the Ebon Hold cinematic; this module starts
-- them at level 1, so the cinematic is skipped. Level 55+ can still reach Acherus through the Ebon Herald (reentry).
-- Every race gets the start of its first non-Death-Knight class (the same start the other classic classes use).

UPDATE `playercreateinfo` p
JOIN (
    SELECT `race`, MIN(`class`) AS `donor`
    FROM `playercreateinfo`
    WHERE `class` <> 6
    GROUP BY `race`
) d ON d.`race` = p.`race`
JOIN `playercreateinfo` s ON s.`race` = d.`race` AND s.`class` = d.`donor`
SET p.`map` = s.`map`,
    p.`zone` = s.`zone`,
    p.`position_x` = s.`position_x`,
    p.`position_y` = s.`position_y`,
    p.`position_z` = s.`position_z`,
    p.`orientation` = s.`orientation`
WHERE p.`class` = 6;
