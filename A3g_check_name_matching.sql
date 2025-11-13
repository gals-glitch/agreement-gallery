-- Check if CSV names match database names

-- 1. Check a sample party name from CSV exists in parties table
SELECT name FROM parties WHERE name = 'Agamim Commercial Real Estate';
SELECT name FROM parties WHERE name = 'Kuperman Capital';
SELECT name FROM parties WHERE name = 'Kuperman';

-- 2. Check a sample investor name from CSV exists in investors table
SELECT name FROM investors WHERE name = '310 Tyson Drive GP LLC';
SELECT name FROM investors WHERE name = 'Aaron Shenhar';

-- 3. Check a sample deal name from CSV exists in deals table
SELECT name FROM deals WHERE name = '310 Tyson Drive Operating LP';
SELECT name FROM deals WHERE name = '9231 Penn Avenue';
SELECT name FROM deals WHERE name = '100 City View Buligo LP';

-- 4. Show first 10 actual party names
SELECT name FROM parties ORDER BY name LIMIT 10;

-- 5. Show first 10 actual investor names
SELECT name FROM investors ORDER BY name LIMIT 10;

-- 6. Show first 10 actual deal names
SELECT name FROM deals ORDER BY name LIMIT 10;
