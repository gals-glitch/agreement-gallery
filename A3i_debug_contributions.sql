-- Debug why contributions aren't showing up

-- 1. Total counts
SELECT 'Contributions' as table_name, COUNT(*) as count FROM contributions
UNION ALL SELECT 'Agreements', COUNT(*) FROM agreements
UNION ALL SELECT 'Investors', COUNT(*) FROM investors
UNION ALL SELECT 'Parties', COUNT(*) FROM parties;

-- 2. Sample a specific contribution from CSV to see if it exists
-- CSV line 2: 310 Tyson Drive GP LLC,310 Tyson Drive Operating LP,10890.0
SELECT
  i.name as investor_name,
  d.name as deal_name,
  c.amount,
  c.id as contribution_id
FROM investors i
CROSS JOIN deals d
LEFT JOIN contributions c ON c.investor_id = i.id AND c.deal_id = d.id
WHERE i.name = '310 Tyson Drive GP LLC'
  AND d.name LIKE '310 Tyson%'
LIMIT 5;

-- 3. Check if investor names from CSV actually exist
SELECT name FROM investors WHERE name IN (
  '310 Tyson Drive GP LLC',
  'Aaron Shenhar',
  'Abraham Fuchs',
  'Adi Grinberg'
);

-- 4. Check if those investors have ANY contributions
SELECT
  i.name as investor_name,
  COUNT(c.id) as contribution_count
FROM investors i
LEFT JOIN contributions c ON c.investor_id = i.id
WHERE i.name IN ('310 Tyson Drive GP LLC', 'Aaron Shenhar', 'Abraham Fuchs', 'Adi Grinberg')
GROUP BY i.name;
