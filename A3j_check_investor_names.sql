-- Check actual investor names in database

-- Show first 20 investor names
SELECT name FROM investors ORDER BY name LIMIT 20;

-- Check if specific names from contributions CSV exist
SELECT 'EXISTS' as status, name FROM investors WHERE name IN (
  '310 Tyson Drive GP LLC',
  'Aaron Shenhar',
  'Abraham Fuchs',
  'Abraham Raz',
  'Adam Gotskind',
  'Adi Danon',
  'Adi Grinberg',
  'Adi Zwickel'
);
