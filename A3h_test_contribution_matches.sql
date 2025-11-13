-- Test if specific names from contributions CSV exist

-- From contributions CSV line 2: 310 Tyson Drive GP LLC,310 Tyson Drive Operating LP
SELECT 'Investor' as type, name FROM investors WHERE name = '310 Tyson Drive GP LLC'
UNION ALL
SELECT 'Deal' as type, name FROM deals WHERE name = '310 Tyson Drive Operating LP';

-- From contributions CSV line 3: Aaron Shenhar,9231 Penn Avenue
SELECT 'Investor' as type, name FROM investors WHERE name = 'Aaron Shenhar'
UNION ALL
SELECT 'Deal' as type, name FROM deals WHERE name = '9231 Penn Avenue';

-- Check if deal has "Buligo LP" suffix
SELECT name FROM deals WHERE name LIKE '%9231 Penn%';
SELECT name FROM deals WHERE name LIKE '%310 Tyson%';

-- Check actual deal names (first 20)
SELECT name FROM deals ORDER BY name LIMIT 20;
