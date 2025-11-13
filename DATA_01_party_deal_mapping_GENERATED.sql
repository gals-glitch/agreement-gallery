-- ============================================================================
-- [DATA-01] Party â†’ Deal Mapping (GENERATED)
-- ============================================================================
-- Generated from investor commitment data
-- Date: 2025-10-26 13:57:53
-- Party-Deal combinations: 764
-- ============================================================================

CREATE TEMP TABLE tmp_party_deal_map(
    party_name TEXT,
    deal_name TEXT  -- Will need to map to deal_id
);

-- Party â†’ Deal Name mappings (need to resolve deal IDs)
INSERT INTO tmp_party_deal_map (party_name, deal_name) VALUES
('Amit Zeevi', 'Hoschton IL Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', '100 City View Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', '1302 Eastport Road Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', '310 Tyson Drive Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', 'Hiram 2024 Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', 'Hoschton IL Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', 'Hudson Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', 'Ledge Rock Apartments I Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', 'Sarasota Shallow Bay Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', 'Statesboro Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', 'Sugarloaf Buligo LP'),
('Andrew Tanzer [company:  TanzerVest LLC]', 'Sunbelt MOB 1 Buligo LP'),
('Avi Fried', '100 City View Buligo LP'),
('Avi Fried', '201 Triple Diamond Buligo LP'),
('Avi Fried', '2840 W Orange Ave Buligo LP'),
('Avi Fried', '5 East Pointe Drive Buligo LP'),
('Avi Fried', '6501 Nevada Buligo LP'),
('Avi Fried', '9231 Penn Ave Buligo LP'),
('Avi Fried', 'Antioch Buligo LP'),
('Avi Fried', 'Ascent 430 Buligo LP'),
('Avi Fried', 'Bay Road Buligo LP'),
('Avi Fried', 'Beaufort Buligo LP'),
('Avi Fried', 'Belaire Buligo LP'),
('Avi Fried', 'Belaire Junior Loan'),
('Avi Fried', 'Berwick Buligo LP'),
('Avi Fried', 'Brentwood Buligo LP'),
('Avi Fried', 'Cartersville Buligo LP'),
('Avi Fried', 'Classic City Flats Buligo LP'),
('Avi Fried', 'Crescent Buligo LP'),
('Avi Fried', 'Dry Creek Buligo LP'),
('Avi Fried', 'Duncan Buligo LP'),
('Avi Fried', 'East Hennepin Buligo LP'),
('Avi Fried', 'Fitzroy Buligo LP'),
('Avi Fried', 'Fox Buligo LP'),
('Avi Fried', 'Gainesville 2023 Buligo LP'),
('Avi Fried', 'Gateway Buligo LP'),
('Avi Fried', 'Greenway Buligo LP'),
('Avi Fried', 'Hartford Buligo LP'),
('Avi Fried', 'Hickory Flat Buligo LP'),
('Avi Fried', 'Hiram 2024 Buligo LP'),
('Avi Fried', 'Hiram Buligo LP'),
('Avi Fried', 'Hoschton IL Buligo LP'),
('Avi Fried', 'Hudson Buligo LP'),
('Avi Fried', 'Huntsville Buligo LP'),
('Avi Fried', 'Johnstown Buligo LP'),
('Avi Fried', 'Kenall Buligo LP'),
('Avi Fried', 'Ledge Rock Apartments I Buligo LP'),
('Avi Fried', 'Mason Buligo LP'),
('Avi Fried', 'McGaw Court Buligo LP'),
('Avi Fried', 'Milagro Buligo LP'),
('Avi Fried', 'Murrells Buligo LP'),
('Avi Fried', 'Neely Ferry Buligo LP'),
('Avi Fried', 'Neely Ferry Phase II Buligo LP'),
('Avi Fried', 'Oakwood Buligo LP'),
('Avi Fried', 'Osborne Buligo LP'),
('Avi Fried', 'Parkwood Buligo LP'),
('Avi Fried', 'Parkwood Loan'),
('Avi Fried', 'Parkwood Loan - March 2025'),
('Avi Fried', 'Pencil Buligo LP'),
('Avi Fried', 'Pencil Loan'),
('Avi Fried', 'Perdido Buligo LP'),
('Avi Fried', 'Retreat at Weaverville Buligo LP'),
('Avi Fried', 'River Ridge 2023 Buligo LP'),
('Avi Fried', 'Riverside at Whitehall Buligo LP'),
('Avi Fried', 'Roswell Buligo LP'),
('Avi Fried', 'Ryans Crossing Buligo LP'),
('Avi Fried', 'Sarasota Shallow Bay Buligo LP'),
('Avi Fried', 'Statesboro Buligo LP'),
('Avi Fried', 'Thatcher Woods Buligo LP'),
('Avi Fried', 'Via Buligo LP'),
('Avi Fried', 'Weaverville Loan'),
('Avi Fried', 'Weaverville Plaza Buligo LP'),
('Avi Fried', 'Winters Creek Buligo LP'),
('Beny Shafir', 'Berwick Buligo LP'),
('Beny Shafir', 'Dry Creek Buligo LP'),
('Beny Shafir', 'Huntsville Buligo LP'),
('Beny Shafir', 'McGaw Court Buligo LP'),
('Beny Shafir', 'Riverside at Whitehall Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', '1010 Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', '10793 Harry Hines Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', '160 West Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', '160 West Member Loan'),
('Capital Link Family Office- Shiri Hybloom', 'Azalea Hill Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', 'Barcelona LP'),
('Capital Link Family Office- Shiri Hybloom', 'Ciutat 13'),
('Capital Link Family Office- Shiri Hybloom', 'Ciutat 13 Member Loan'),
('Capital Link Family Office- Shiri Hybloom', 'Duncan Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', 'Eagle Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', 'Eagle Sr Loan'),
('Capital Link Family Office- Shiri Hybloom', 'East Hennepin Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', 'Lincoln Springs Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', 'Litchfield Oaks Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', 'Perdido Buligo LP'),
('Capital Link Family Office- Shiri Hybloom', 'Skyline Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', '5949 Jackson Road'),
('Cross Arch Holdings -David Kirchenbaum', '6501 Nevada Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', '9231 Penn Ave Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Antioch Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Ashley Woods Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Azalea Hill Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Brentwood Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Cheshire Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Christina Mill Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Dry Creek Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Eagle Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Eagle Loan - May 2025'),
('Cross Arch Holdings -David Kirchenbaum', 'Eagle Member Loan'),
('Cross Arch Holdings -David Kirchenbaum', 'Eagle Sr Loan'),
('Cross Arch Holdings -David Kirchenbaum', 'Fitzroy Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Gardens at Ashley Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Gateway Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Hartford Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Hibernia Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Huntsville Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Johnstown Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Kenall Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Ledge Rock Apartments I Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Lincoln Springs Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Lincoln Springs Junior Loan'),
('Cross Arch Holdings -David Kirchenbaum', 'Marquis Crest Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'McGaw Court Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Metro Portfolio Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Oakwood Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Osborne Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Pencil Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Pencil Loan'),
('Cross Arch Holdings -David Kirchenbaum', 'Perdido Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Reserve Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'River Ridge 2023 Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Riverside at Whitehall Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Roswell Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Sea Palms Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Sherwood Ridges Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Sunbelt MOB 1 Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Towerview Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Tyde Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Tyde Buligo LP - Loan'),
('Cross Arch Holdings -David Kirchenbaum', 'Tyde II Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'Via Buligo LP'),
('Cross Arch Holdings -David Kirchenbaum', 'White House Buligo LP'),
('David Reichman', '6501 Nevada Buligo LP'),
('David Reichman', 'Antioch Buligo LP'),
('David Reichman', 'Aventine Buligo LP'),
('David Reichman', 'Beaufort Buligo LP'),
('David Reichman', 'Brentwood Buligo LP'),
('David Reichman', 'Dry Creek Buligo LP'),
('David Reichman', 'Eagle Buligo LP'),
('David Reichman', 'Eagle Member Loan'),
('David Reichman', 'East Hennepin Buligo LP'),
('David Reichman', 'Flat Rock Buligo LP'),
('David Reichman', 'Fox Buligo LP'),
('David Reichman', 'Greenway Buligo LP'),
('David Reichman', 'Hickory Flat Buligo LP'),
('David Reichman', 'Huntsville Buligo LP'),
('David Reichman', 'Johnstown Buligo LP'),
('David Reichman', 'Johnstown Loan'),
('David Reichman', 'Milagro Buligo LP'),
('David Reichman', 'Nostrand Place Buligo LP'),
('David Reichman', 'Oak Brook Buligo LP'),
('David Reichman', 'Osborne Buligo LP'),
('David Reichman', 'Pencil Buligo LP'),
('David Reichman', 'Pencil Loan'),
('David Reichman', 'Perdido Buligo LP'),
('David Reichman', 'Reems Creek Buligo LP'),
('David Reichman', 'Tribute Buligo LP'),
('David Reichman', 'Tyde Buligo LP'),
('David Reichman', 'Tyde Buligo LP - Loan'),
('David Reichman', 'Urbandale Buligo LP'),
('David Reichman', 'White House Buligo LP'),
('Dror Zetouni', '1010 Buligo LP'),
('Dror Zetouni', '201 Triple Diamond Buligo LP'),
('Dror Zetouni', 'Aventine Buligo LP'),
('Dror Zetouni', 'Berwick Buligo LP'),
('Dror Zetouni', 'Buligo Fund V INDIV LP'),
('Dror Zetouni', 'Classic City Flats Buligo LP'),
('Dror Zetouni', 'CLI Buligo LP'),
('Dror Zetouni', 'Dry Creek Buligo LP'),
('Dror Zetouni', 'Fox Buligo LP'),
('Dror Zetouni', 'Gainesville 2023 Buligo LP'),
('Dror Zetouni', 'Greenway Buligo LP'),
('Dror Zetouni', 'Groton Square Buligo LP'),
('Dror Zetouni', 'Hartford Buligo LP'),
('Dror Zetouni', 'Hickory Flat Buligo LP'),
('Dror Zetouni', 'Hiram 2024 Buligo LP'),
('Dror Zetouni', 'Hudson Buligo LP'),
('Dror Zetouni', 'Huntsville Buligo LP'),
('Dror Zetouni', 'Johnstown Loan'),
('Dror Zetouni', 'McGaw Court Buligo LP'),
('Dror Zetouni', 'Midtown Buligo LP'),
('Dror Zetouni', 'Parkwood Buligo LP'),
('Dror Zetouni', 'Parkwood Loan'),
('Dror Zetouni', 'Perdido Buligo LP'),
('Dror Zetouni', 'Riverside at Whitehall Buligo LP'),
('Dror Zetouni', 'Riverwood Buligo LP'),
('Dror Zetouni', 'Skyline Buligo LP'),
('Dror Zetouni', 'Snellville Buligo LP'),
('Dror Zetouni', 'Tyde Buligo LP'),
('Dror Zetouni', 'Tyde Buligo LP - Loan'),
('Dror Zetouni', 'Tyde II Buligo LP'),
('Formula Ventures Ltd- Shai Beilis', '100 City View Buligo LP'),
('Formula Ventures Ltd- Shai Beilis', '201 Triple Diamond Buligo LP'),
('Formula Ventures Ltd- Shai Beilis', 'Aventine Buligo LP'),
('Formula Ventures Ltd- Shai Beilis', 'Belaire Buligo LP'),
('Formula Ventures Ltd- Shai Beilis', 'Calle d''Arta'),
('Formula Ventures Ltd- Shai Beilis', 'Limited Partnership'),
('Formula Ventures Ltd- Shai Beilis', 'Roswell Buligo LP'),
('Formula Ventures Ltd- Shai Beilis', 'Thatcher Woods Buligo LP'),
('Formula Ventures Ltd- Shai Beilis', 'Weaverville Loan'),
('Formula Ventures Ltd- Shai Beilis', 'Weaverville Plaza Buligo LP'),
('Formula Ventures Ltd- Shai Beilis', 'West Side Plaza Buligo LP'),
('Formula Ventures Ltd- Shai Beilis', 'Winters Creek Buligo LP'),
('Gabriel Taub', 'Brentwood Buligo LP'),
('Gabriel Taub', 'Hartford Buligo LP'),
('Gil Haramati', '100 City View Buligo LP'),
('Gil Haramati', '6501 Nevada Buligo LP'),
('Gil Haramati', 'Aventine Buligo LP'),
('Gil Haramati', 'Brentwood Buligo LP'),
('Gil Haramati', 'CLI Buligo LP'),
('Gil Haramati', 'East Hennepin Buligo LP'),
('Gil Haramati', 'Fox Buligo LP'),
('Gil Haramati', 'Hickory Flat Buligo LP'),
('Gil Haramati', 'Perdido Buligo LP'),
('Gil Haramati', 'Tyde Buligo LP'),
('Gil Haramati', 'Tyde Buligo LP - Loan'),
('Gil Haramati', 'Tyde II Buligo LP'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Antioch Buligo LP'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Aventine Buligo LP'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Pencil Buligo LP'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Pencil Loan'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Perdido Buligo LP'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Red Willow Buligo LP'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Tyde Buligo LP'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Tyde Buligo LP - Loan'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Tyde II Buligo LP'),
('Gilad Slonim Insurance Agency Ltd- Gilad Slonim', 'Weaverville Plaza Buligo LP'),
('Guy Moses', '100 City View Buligo LP'),
('Guy Moses', '131 Devoe Buligo LP'),
('Guy Moses', '131 Devoe St Member Loan'),
('Guy Moses', '2840 W Orange Ave Buligo LP'),
('Guy Moses', '571 Commerce Buligo LP'),
('Guy Moses', '6501 Nevada Buligo LP'),
('Guy Moses', '9231 Penn Ave Buligo LP'),
('Guy Moses', 'Antioch Buligo LP'),
('Guy Moses', 'Ascent 430 Buligo LP'),
('Guy Moses', 'Athens Buligo LP'),
('Guy Moses', 'Aventine Buligo LP'),
('Guy Moses', 'Bay Road Buligo LP'),
('Guy Moses', 'Beaufort Buligo LP'),
('Guy Moses', 'Berwick Buligo LP'),
('Guy Moses', 'Brentwood Buligo LP'),
('Guy Moses', 'Classic City Flats Buligo LP'),
('Guy Moses', 'CLI Buligo LP'),
('Guy Moses', 'Columbus Buligo I'),
('Guy Moses', 'CP Phase II Buligo LP'),
('Guy Moses', 'Crescent Buligo LP'),
('Guy Moses', 'Dawsonville Buligo LP'),
('Guy Moses', 'Dry Creek Buligo LP'),
('Guy Moses', 'Duncan Buligo LP'),
('Guy Moses', 'Eagle Buligo LP'),
('Guy Moses', 'Eagle Loan - May 2025'),
('Guy Moses', 'Eagle Member Loan'),
('Guy Moses', 'Eagle Sr Loan'),
('Guy Moses', 'East Hennepin Buligo LP'),
('Guy Moses', 'Ellijay Buligo LP'),
('Guy Moses', 'Ellijay Loan'),
('Guy Moses', 'Fitzroy Buligo LP'),
('Guy Moses', 'Flat Rock Buligo LP'),
('Guy Moses', 'Fox Buligo LP'),
('Guy Moses', 'Gainesville 2023 Buligo LP'),
('Guy Moses', 'Gainesville Buligo LP'),
('Guy Moses', 'Gardens at Ashley Buligo LP'),
('Guy Moses', 'Greenway Buligo LP'),
('Guy Moses', 'Hickory Flat Buligo LP'),
('Guy Moses', 'Hiram 2024 Buligo LP'),
('Guy Moses', 'Hiram Buligo LP'),
('Guy Moses', 'Hoschton Buligo LP'),
('Guy Moses', 'Hoschton IL Buligo LP'),
('Guy Moses', 'Huntsville Buligo LP'),
('Guy Moses', 'Ironwood Buligo LP'),
('Guy Moses', 'Johnstown Buligo LP'),
('Guy Moses', 'Johnstown Loan'),
('Guy Moses', 'Kenall Buligo LP'),
('Guy Moses', 'Lafayette Buligo LP'),
('Guy Moses', 'Leland Apartments Buligo LP'),
('Guy Moses', 'Lloret'),
('Guy Moses', 'LP'),
('Guy Moses', 'Lullwater Buligo LP'),
('Guy Moses', 'Lullwater II Buligo LP'),
('Guy Moses', 'Manor Lake Athens Loan - February 2024'),
('Guy Moses', 'Mason Buligo LP'),
('Guy Moses', 'Meadows Buligo LP'),
('Guy Moses', 'Metro Portfolio Buligo LP'),
('Guy Moses', 'Midtown Buligo LP'),
('Guy Moses', 'Neely Ferry Buligo LP'),
('Guy Moses', 'Neely Ferry Buligo LP - Loan'),
('Guy Moses', 'Neely Ferry Phase II Buligo LP'),
('Guy Moses', 'Oakwood Buligo LP'),
('Guy Moses', 'Osceola Village Buligo LP'),
('Guy Moses', 'Parkwood Buligo LP'),
('Guy Moses', 'Parkwood Loan'),
('Guy Moses', 'Pencil Buligo LP'),
('Guy Moses', 'Pencil Loan'),
('Guy Moses', 'Perdido Buligo LP'),
('Guy Moses', 'Red Willow Buligo LP'),
('Guy Moses', 'Reserve Buligo LP'),
('Guy Moses', 'Retreat at Weaverville Buligo LP'),
('Guy Moses', 'River Ridge 2023 Buligo LP'),
('Guy Moses', 'Riverwood Buligo LP'),
('Guy Moses', 'Roper Mountain Buligo LP'),
('Guy Moses', 'Roswell Buligo LP'),
('Guy Moses', 'Skyline Buligo LP'),
('Guy Moses', 'Snellville Buligo LP'),
('Guy Moses', 'Statesboro Buligo LP'),
('Guy Moses', 'Sugarloaf Buligo LP'),
('Guy Moses', 'Temple Terrace Plaza'),
('Guy Moses', 'Thatcher Woods Buligo LP'),
('Guy Moses', 'Tribute Buligo LP'),
('Guy Moses', 'Tyde Buligo LP'),
('Guy Moses', 'Tyde Buligo LP - Loan'),
('Guy Moses', 'Tyde II Buligo LP'),
('Guy Moses', 'Waterford Buligo LP'),
('Guy Moses', 'Weaverville Loan'),
('Guy Moses', 'Weaverville Plaza Buligo LP'),
('Guy Moses', 'Westgate Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', '1000 W Crosby Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', '201 Triple Diamond Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Ascent 430 Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Cheshire Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Duncan Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Encore Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Enterprise Plaza Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Groton Square Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Hartford Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Haverly Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Huntsville Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Kenall Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Mason Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Meadows Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Murrells Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Oakwood Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Reems Creek Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'River Ridge 2023 Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Riverwood Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Tribute Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'Vine Street Square Buligo LP'),
('HNA Investments Limited Liability- Ilan Grinberg and Jacob Asia (together)', 'White House Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', '201 Triple Diamond Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'Duncan Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'Hamilton Mill Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'Hoschton IL Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'Lullwater Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'Reserve Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'River Ridge 2023 Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'Sunbelt MOB 1 Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'Urbandale Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'Vine Street Square Buligo LP'),
('HS Invest Pension Insurance Agency (2016) ltd- Hezi Schwartz', 'Weaverville Plaza Buligo LP'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', '1010 Buligo LP'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', 'LP'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', 'Madrid'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', 'Metro Portfolio Buligo LP'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', 'Toledo 87'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', 'Tyde Buligo LP'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', 'Tyde Buligo LP - Loan'),
('Ilan Kapelner Management Services ltd- Ilan Kapelner', 'Tyde II Buligo LP'),
('Ilanit Tirosh', '1010 Buligo LP'),
('Ilanit Tirosh', 'CLI Buligo LP'),
('Ilanit Tirosh', 'Dry Creek Buligo LP'),
('Ilanit Tirosh', 'Hiram 2024 Buligo LP'),
('Ilanit Tirosh', 'Johnstown Buligo LP'),
('Ilanit Tirosh', 'Johnstown Loan'),
('Ilanit Tirosh', 'Royal Plaza Buligo LP'),
('Iprofit Ltd- Yifat Igler', 'Lullwater Buligo LP'),
('Kuperman', '100 City View Buligo LP'),
('Kuperman', 'Ascent 430 Buligo LP'),
('Kuperman', 'Athens Buligo LP'),
('Kuperman', 'Autumn Ridge Buligo LP'),
('Kuperman', 'Autumn Ridge Junior Loan'),
('Kuperman', 'Aventine Buligo LP'),
('Kuperman', 'Beaufort Buligo LP'),
('Kuperman', 'Central Governors Buligo LP'),
('Kuperman', 'Christina Mill Buligo LP'),
('Kuperman', 'CLI Buligo LP'),
('Kuperman', 'Crescent Buligo LP'),
('Kuperman', 'Eagle Buligo LP'),
('Kuperman', 'Eagle Member Loan'),
('Kuperman', 'Ellijay Buligo LP'),
('Kuperman', 'Encore Buligo LP'),
('Kuperman', 'Enterprise Plaza Buligo LP'),
('Kuperman', 'Fox Buligo LP'),
('Kuperman', 'Gardens at Ashley Buligo LP'),
('Kuperman', 'Gateway Buligo LP'),
('Kuperman', 'Hibernia Buligo LP'),
('Kuperman', 'Hudson Buligo LP'),
('Kuperman', 'Ironwood Buligo LP'),
('Kuperman', 'Johnstown Buligo LP'),
('Kuperman', 'Johnstown Loan'),
('Kuperman', 'Ledge Rock Apartments I Buligo LP'),
('Kuperman', 'Lullwater Buligo LP'),
('Kuperman', 'Lullwater II Buligo LP'),
('Kuperman', 'Manor Lake Athens Loan - February 2024'),
('Kuperman', 'Meadows Buligo LP'),
('Kuperman', 'Metro Portfolio Buligo LP'),
('Kuperman', 'Nostrand Place Buligo LP'),
('Kuperman', 'Oakwood Buligo LP'),
('Kuperman', 'Osceola Village Buligo LP'),
('Kuperman', 'Pencil Buligo LP'),
('Kuperman', 'Pencil Loan'),
('Kuperman', 'Red Willow Buligo LP'),
('Kuperman', 'Reems Creek Buligo LP'),
('Kuperman', 'Reserve Buligo LP'),
('Kuperman', 'Retreat at Weaverville Buligo LP'),
('Kuperman', 'Sarasota Shallow Bay Buligo LP'),
('Kuperman', 'Skyline Buligo LP'),
('Kuperman', 'Temple Terrace Plaza'),
('Kuperman', 'Thatcher Woods Buligo LP'),
('Kuperman', 'Tree Trail Buligo LP'),
('Kuperman', 'Tyde Buligo LP'),
('Kuperman', 'Tyde II Buligo LP'),
('Kuperman', 'Walden Oaks Buligo LP'),
('Kuperman', 'Waterford Buligo LP'),
('Kuperman', 'Westgate Buligo LP'),
('Kuperman', 'Winters Creek Buligo LP'),
('Lighthouse F.S Ltd- Avihay', 'Cartersville Buligo LP'),
('Lighthouse F.S Ltd- Avihay', 'Hickory Flat Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', '193 Henry Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', '310 Tyson Drive Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Ascent 430 Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Aventine Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Charleston Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Cheshire Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'China Hotel Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Christina Mill Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Closegate Hotel Development (Durham) Limited'),
('Lior Stinus from Freidkes & Co. CPA', 'Closegate Hotel Development (Durham) Limited (Refinance)'),
('Lior Stinus from Freidkes & Co. CPA', 'Duncan Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Eagle Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Eagle Sr Loan'),
('Lior Stinus from Freidkes & Co. CPA', 'Hudson Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Nostrand Place Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Reigo Senior Secured Loans LLC'),
('Lior Stinus from Freidkes & Co. CPA', 'Riverside at Whitehall Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Ryans Crossing Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Tarana International'),
('Lior Stinus from Freidkes & Co. CPA', 'Weaverville Loan'),
('Lior Stinus from Freidkes & Co. CPA', 'Weaverville Plaza Buligo LP'),
('Lior Stinus from Freidkes & Co. CPA', 'Woods Edge Buligo LP'),
('Natai Investments- Alon Even Chen', 'Aventine Buligo LP'),
('Natai Investments- Alon Even Chen', 'Bay Road Buligo LP'),
('Natai Investments- Alon Even Chen', 'Brentwood Buligo LP'),
('Natai Investments- Alon Even Chen', 'Bridge Mill Investor Sr Loan LLC'),
('Natai Investments- Alon Even Chen', 'Christina Mill Buligo LP'),
('Natai Investments- Alon Even Chen', 'Classic City Flats Buligo LP'),
('Natai Investments- Alon Even Chen', 'Dry Creek Buligo LP'),
('Natai Investments- Alon Even Chen', 'Duncan Buligo LP'),
('Natai Investments- Alon Even Chen', 'Enterprise Plaza Buligo LP'),
('Natai Investments- Alon Even Chen', 'Flat Rock Buligo LP'),
('Natai Investments- Alon Even Chen', 'Greenway Buligo LP'),
('Natai Investments- Alon Even Chen', 'Hoschton IL Buligo LP'),
('Natai Investments- Alon Even Chen', 'Huntsville Buligo LP'),
('Natai Investments- Alon Even Chen', 'Ironwood Buligo LP'),
('Natai Investments- Alon Even Chen', 'Johnstown Buligo LP'),
('Natai Investments- Alon Even Chen', 'Ledge Rock Apartments I Buligo LP'),
('Natai Investments- Alon Even Chen', 'Milagro Buligo LP'),
('Natai Investments- Alon Even Chen', 'Neely Ferry Buligo LP'),
('Natai Investments- Alon Even Chen', 'Neely Ferry Buligo LP - Loan'),
('Natai Investments- Alon Even Chen', 'Neely Ferry Phase II Buligo LP'),
('Natai Investments- Alon Even Chen', 'Pond Bay Buligo LP'),
('Natai Investments- Alon Even Chen', 'Reems Creek Buligo LP'),
('Natai Investments- Alon Even Chen', 'Skyline Buligo LP'),
('Natai Investments- Alon Even Chen', 'Snellville Buligo LP'),
('Pioneer Wealth Management- Liat F', 'Calle d''Arta'),
('Pioneer Wealth Management- Liat F', 'CP Phase II Buligo LP'),
('Pioneer Wealth Management- Liat F', 'Crescent Buligo LP'),
('Pioneer Wealth Management- Liat F', 'Gainesville Buligo LP'),
('Pioneer Wealth Management- Liat F', 'Limited Partnership'),
('Pioneer Wealth Management- Liat F', 'Thatcher Woods Buligo LP'),
('Ronnie Maliniak', 'Athens Buligo LP'),
('Ronnie Maliniak', 'Beaufort Buligo LP'),
('Ronnie Maliniak', 'Eagle Buligo LP'),
('Ronnie Maliniak', 'Enterprise Plaza Buligo LP'),
('Ronnie Maliniak', 'Fox Buligo LP'),
('Ronnie Maliniak', 'GrayBul Summer Chase Apts LP'),
('Ronnie Maliniak', 'Haverly Buligo LP'),
('Ronnie Maliniak', 'Hickory Flat Buligo LP'),
('Ronnie Maliniak', 'Osceola Village Buligo LP'),
('Ronnie Maliniak', 'Parkwood Buligo LP'),
('Ronnie Maliniak', 'Skyline Buligo LP'),
('Ronnie Maliniak', 'Spring Park Buligo LP'),
('Ronnie Maliniak', 'West Coast Land Ventures LLC'),
('Roy Gold', '1000 W Crosby Buligo LP'),
('Roy Gold', '2840 W Orange Ave Buligo LP'),
('Roy Gold', 'Hartford Buligo LP'),
('Roy Gold', 'Oakwood Buligo LP'),
('Roy Gold', 'Reems Creek Buligo LP'),
('Rubin Schlussel', '100 City View Buligo LP'),
('Rubin Schlussel', '1000 W Crosby Buligo LP'),
('Rubin Schlussel', '310 Tyson Drive Buligo LP'),
('Rubin Schlussel', 'Classic City Flats Buligo LP'),
('Rubin Schlussel', 'CP Phase II Buligo LP'),
('Rubin Schlussel', 'Crescent Buligo LP'),
('Rubin Schlussel', 'Dry Creek Buligo LP'),
('Rubin Schlussel', 'East Hennepin Buligo LP'),
('Rubin Schlussel', 'Encore Buligo LP'),
('Rubin Schlussel', 'Groton Square Buligo LP'),
('Rubin Schlussel', 'Hiram 2024 Buligo LP'),
('Rubin Schlussel', 'Meitav Buligo Fund I LP'),
('Rubin Schlussel', 'Milagro Buligo LP'),
('Rubin Schlussel', 'Oak Brook Buligo LP'),
('Rubin Schlussel', 'Oakwood Buligo LP'),
('Rubin Schlussel', 'Osceola Village Buligo LP'),
('Rubin Schlussel', 'Red Willow Buligo LP'),
('Rubin Schlussel', 'River Ridge 2023 Buligo LP'),
('Rubin Schlussel', 'Riverwood Buligo LP'),
('Rubin Schlussel', 'Sarasota Shallow Bay Buligo LP'),
('Rubin Schlussel', 'Sugarloaf Buligo LP'),
('Rubin Schlussel', 'Thatcher Woods Buligo LP'),
('Rubin Schlussel', 'Tree Trail Buligo LP'),
('Rubin Schlussel', 'Urbandale Buligo LP'),
('Rubin Schlussel', 'Vine Street Square Buligo LP'),
('Saar Gavish', 'Cartersville Buligo LP'),
('Saar Gavish', 'Encore Buligo LP'),
('Saar Gavish', 'Ledge Rock Apartments I Buligo LP'),
('Saar Gavish', 'Midtown Buligo LP'),
('Saar Gavish', 'Oakwood Buligo LP'),
('Saar Gavish', 'Osceola Village Buligo LP'),
('Saar Gavish', 'Roswell Buligo LP'),
('Saar Gavish', 'Thatcher Woods Buligo LP'),
('Saar Gavish', 'Urbandale Buligo LP'),
('Sheara Einhorn', 'Cheshire Buligo LP'),
('Sheara Einhorn', 'CLI Buligo LP'),
('Sheara Einhorn', 'Columbus Buligo I'),
('Sheara Einhorn', 'Hudson Buligo LP'),
('Sheara Einhorn', 'Ironwood Buligo LP'),
('Sheara Einhorn', 'Leland Apartments Buligo LP'),
('Sheara Einhorn', 'LP'),
('Sheara Einhorn', 'Osborne Buligo LP'),
('Sheara Einhorn', 'Osceola Village Buligo LP'),
('Sheara Einhorn', 'Perdido Buligo LP'),
('Sheara Einhorn', 'Sunbelt MOB 1 Buligo LP'),
('Sheara Einhorn', 'Tree Trail Buligo LP'),
('Tal Even', '310 Tyson Drive Buligo LP'),
('Tal Even', 'Hiram 2024 Buligo LP'),
('Tal Even', 'Hoschton IL Buligo LP'),
('Tal Even', 'Reigo Senior Secured Loans LLC'),
('Tal Even', 'Weaverville Plaza Buligo LP'),
('Tal Simchony', '100 City View Buligo LP'),
('Tal Simchony', '1000 W Crosby Buligo LP'),
('Tal Simchony', '1010 Buligo LP'),
('Tal Simchony', '6501 Nevada Buligo LP'),
('Tal Simchony', 'Antioch Buligo LP'),
('Tal Simchony', 'Ascent 430 Buligo LP'),
('Tal Simchony', 'Autumn Ridge Buligo LP'),
('Tal Simchony', 'Autumn Ridge Junior Loan 3'),
('Tal Simchony', 'Aventine Buligo LP'),
('Tal Simchony', 'Barcelona LP'),
('Tal Simchony', 'Barceloneta- LP'),
('Tal Simchony', 'Bay Road Buligo LP'),
('Tal Simchony', 'Belaire Buligo LP'),
('Tal Simchony', 'Belaire Junior Loan'),
('Tal Simchony', 'Belaire Junior Loan 2'),
('Tal Simchony', 'Berwick Buligo LP'),
('Tal Simchony', 'Brentwood Buligo LP'),
('Tal Simchony', 'Bridge Mill Investor Sr Loan LLC'),
('Tal Simchony', 'Cartersville Buligo LP'),
('Tal Simchony', 'Central Governors Buligo LP'),
('Tal Simchony', 'Cheshire Buligo LP'),
('Tal Simchony', 'Christina Mill Buligo LP'),
('Tal Simchony', 'Ciutat 13'),
('Tal Simchony', 'Ciutat 13 Member Loan'),
('Tal Simchony', 'Classic City Flats Buligo LP'),
('Tal Simchony', 'Columbus Buligo I'),
('Tal Simchony', 'Dry Creek Buligo LP'),
('Tal Simchony', 'Duncan Buligo LP'),
('Tal Simchony', 'Eagle Buligo LP'),
('Tal Simchony', 'Eagle Loan - May 2025'),
('Tal Simchony', 'Eagle Member Loan'),
('Tal Simchony', 'Eagle Sr Loan'),
('Tal Simchony', 'Enterprise Plaza Buligo LP'),
('Tal Simchony', 'Farrington Buligo LP'),
('Tal Simchony', 'Fitzroy Buligo LP'),
('Tal Simchony', 'Flat Rock Buligo LP'),
('Tal Simchony', 'Fox Buligo LP'),
('Tal Simchony', 'Gainesville 2023 Buligo LP'),
('Tal Simchony', 'Gateway Buligo LP'),
('Tal Simchony', 'Hibernia Buligo LP'),
('Tal Simchony', 'Hiram 2024 Buligo LP'),
('Tal Simchony', 'Hoschton IL Buligo LP'),
('Tal Simchony', 'Hudson Buligo LP'),
('Tal Simchony', 'Johnstown Buligo LP'),
('Tal Simchony', 'Johnstown Loan'),
('Tal Simchony', 'Kenall Buligo LP'),
('Tal Simchony', 'Ledge Rock Apartments I Buligo LP'),
('Tal Simchony', 'Leland Apartments Buligo LP'),
('Tal Simchony', 'LP'),
('Tal Simchony', 'Lullwater Buligo LP'),
('Tal Simchony', 'Lullwater II Buligo LP'),
('Tal Simchony', 'Madrid'),
('Tal Simchony', 'Mason Buligo LP'),
('Tal Simchony', 'Meadows Buligo LP'),
('Tal Simchony', 'Milagro Buligo LP'),
('Tal Simchony', 'Murrells Buligo LP'),
('Tal Simchony', 'Neely Ferry Buligo LP'),
('Tal Simchony', 'Neely Ferry Buligo LP - Loan'),
('Tal Simchony', 'Neely Ferry Phase II Buligo LP'),
('Tal Simchony', 'Pencil Buligo LP'),
('Tal Simchony', 'Pencil Loan'),
('Tal Simchony', 'Perdido Buligo LP'),
('Tal Simchony', 'Pontevedra–Baluard'),
('Tal Simchony', 'Reems Creek Buligo LP'),
('Tal Simchony', 'Reserve Buligo LP'),
('Tal Simchony', 'Retreat at Weaverville Buligo LP'),
('Tal Simchony', 'River Ridge 2023 Buligo LP'),
('Tal Simchony', 'River Ridge Buligo LP'),
('Tal Simchony', 'Riverwood Buligo LP'),
('Tal Simchony', 'Ryans Crossing Buligo LP'),
('Tal Simchony', 'Sherwood Ridges Buligo LP'),
('Tal Simchony', 'Skyline Buligo LP'),
('Tal Simchony', 'Statesboro Buligo LP'),
('Tal Simchony', 'Sugarloaf Buligo LP'),
('Tal Simchony', 'Toledo 87'),
('Tal Simchony', 'Tribute Buligo LP'),
('Tal Simchony', 'Tyde Buligo LP'),
('Tal Simchony', 'Tyde Buligo LP - Loan'),
('Tal Simchony', 'Tyde II Buligo LP'),
('Tal Simchony', 'Via Buligo LP'),
('Tal Simchony', 'Walden Oaks Buligo LP'),
('Tal Simchony', 'Waterford Buligo LP'),
('Tal Simchony', 'Weaverville Plaza Buligo LP'),
('Tal Simchony', 'West Side Plaza Buligo LP'),
('Tal Simchony', 'Westgate Buligo LP'),
('Tal Simchony', 'White House Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', '1010 Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', '201 Triple Diamond Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', '571 Commerce Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', '6501 Nevada Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', '9231 Penn Ave Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Ascent 430 Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Athens Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Aventine Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Beaufort Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Berwick Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'CLI Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Dry Creek Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Duncan Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Eagle Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Eagle Member Loan'),
('ThinkWise Consulting LLC- Lior Cohen', 'Ellijay Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Ellijay Loan'),
('ThinkWise Consulting LLC- Lior Cohen', 'Fox Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Greenway Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Hickory Flat Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Hudson Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Huntsville Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Ironwood Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Johnstown Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Johnstown Loan'),
('ThinkWise Consulting LLC- Lior Cohen', 'Kenall Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Lafayette Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Lullwater Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Lullwater II Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Manor Lake Athens Loan - February 2024'),
('ThinkWise Consulting LLC- Lior Cohen', 'McGaw Court Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Midtown Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Neely Ferry Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Neely Ferry Buligo LP - Loan'),
('ThinkWise Consulting LLC- Lior Cohen', 'Neely Ferry Phase II Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Oakwood Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Osceola Village Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Pencil Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Pencil Loan'),
('ThinkWise Consulting LLC- Lior Cohen', 'Perdido Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Red Willow Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Reems Creek Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Reserve Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Retreat at Weaverville Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Roper Mountain Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Sarasota Shallow Bay Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Skyline Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Tribute Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Tyde Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Tyde Buligo LP - Loan'),
('ThinkWise Consulting LLC- Lior Cohen', 'Tyde II Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Weaverville Loan'),
('ThinkWise Consulting LLC- Lior Cohen', 'Weaverville Plaza Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'Westgate Buligo LP'),
('ThinkWise Consulting LLC- Lior Cohen', 'White House Buligo LP'),
('Uri Golani', '1000 W Crosby Buligo LP'),
('Uri Golani', 'Hoschton IL Buligo LP'),
('Uri Golani', 'Ledge Rock Apartments I Buligo LP'),
('Uri Golani', 'Oakwood Buligo LP'),
('Uri Golani', 'Reems Creek Buligo LP'),
('Uri Golani', 'Statesboro Buligo LP'),
('Uri Golani', 'Sugarloaf Buligo LP'),
('Wiser Finance- Michael Mann', '310 Tyson Drive Buligo LP'),
('Wiser Finance- Michael Mann', 'Bay Road Buligo LP'),
('Wiser Finance- Michael Mann', 'Berwick Buligo LP'),
('Wiser Finance- Michael Mann', 'Brentwood Buligo LP'),
('Wiser Finance- Michael Mann', 'Buligo Fund IV INDIV LP'),
('Wiser Finance- Michael Mann', 'Buligo Fund V INDIV LP'),
('Wiser Finance- Michael Mann', 'Classic City Flats Buligo LP'),
('Wiser Finance- Michael Mann', 'East Hennepin Buligo LP'),
('Wiser Finance- Michael Mann', 'Flat Rock Buligo LP'),
('Wiser Finance- Michael Mann', 'Fox Buligo LP'),
('Wiser Finance- Michael Mann', 'Hoschton IL Buligo LP'),
('Wiser Finance- Michael Mann', 'Huntsville Buligo LP'),
('Wiser Finance- Michael Mann', 'Ironwood Buligo LP'),
('Wiser Finance- Michael Mann', 'Leland Apartments Buligo LP'),
('Wiser Finance- Michael Mann', 'Manchac and Odyssey Buligo LP'),
('Wiser Finance- Michael Mann', 'Oak Brook Buligo LP'),
('Wiser Finance- Michael Mann', 'Oakwood Buligo LP'),
('Wiser Finance- Michael Mann', 'Reems Creek Buligo LP'),
('Wiser Finance- Michael Mann', 'River Ridge 2023 Buligo LP'),
('Wiser Finance- Michael Mann', 'Sarasota Shallow Bay Buligo LP'),
('Wiser Finance- Michael Mann', 'Westgate Buligo LP'),
('Yair Almagor', 'Via Buligo LP'),
('Yariv Avrahami', 'Hartford Buligo LP'),
('Yariv Avrahami', 'River Ridge 2023 Buligo LP'),
('Yariv Avrahami', 'Tyde Buligo LP'),
('Yariv Avrahami', 'Tyde Buligo LP - Loan'),
('Yariv Avrahami', 'Tyde II Buligo LP'),
('YL Consulting Inc- Yoav Lachover', '100 City View Buligo LP'),
('YL Consulting Inc- Yoav Lachover', '1000 W Crosby Buligo LP'),
('YL Consulting Inc- Yoav Lachover', '1010 Buligo LP'),
('YL Consulting Inc- Yoav Lachover', '310 Tyson Drive Buligo LP'),
('YL Consulting Inc- Yoav Lachover', '9231 Penn Ave Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Dry Creek Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Fitzroy Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Flat Rock Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Gainesville 2023 Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Highline Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Hiram 2024 Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Hoschton IL Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Hudson Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Johnstown Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Johnstown Loan'),
('YL Consulting Inc- Yoav Lachover', 'Ledge Rock Apartments I Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Mason Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Milagro Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Oakwood Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Pencil Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Perdido Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'River Ridge 2023 Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Skyline Buligo LP'),
('YL Consulting Inc- Yoav Lachover', 'Statesboro Buligo LP'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'Autumn Ridge Buligo LP'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'Ellijay Buligo LP'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'Ellijay Loan'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'Fox Buligo LP'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'Marquis Crest Buligo LP'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'Neely Ferry Buligo LP'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'Neely Ferry Buligo LP - Loan'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'Neely Ferry Phase II Buligo LP'),
('Yoram Avi-Guy Lawyer- Yoram Avi Guy', 'Nostrand Place Buligo LP'),
('Yoram Shalit', '131 Devoe Buligo LP'),
('Yoram Shalit', '201 Triple Diamond Buligo LP'),
('Yoram Shalit', 'Christina Mill Buligo LP'),
('Yoram Shalit', 'Hartford Buligo LP'),
('Yoram Shalit', 'LP'),
('Yoram Shalit', 'Madrid'),
('Yoram Shalit', 'Ryans Crossing Buligo LP'),
('Yoram Shalit', 'Toledo 87'),
('Yoram Shalit', 'Waterford Buligo LP'),
('Yoram Shalit', 'Winters Creek Buligo LP');

-- ============================================================================
-- Map deal names to deal IDs and create final mapping
-- ============================================================================

-- Show unmapped deal names (deals not in database)
SELECT DISTINCT
    '=== Unmapped Deal Names ===' as section,
    m.deal_name
FROM tmp_party_deal_map m
LEFT JOIN deals d ON d.name = m.deal_name
WHERE d.id IS NULL
ORDER BY m.deal_name;

-- Create final party_name â†’ deal_id mapping
CREATE TEMP TABLE tmp_party_deal_map_final AS
SELECT DISTINCT
    m.party_name,
    d.id as deal_id,
    d.name as deal_name
FROM tmp_party_deal_map m
INNER JOIN deals d ON d.name = m.deal_name
ORDER BY m.party_name, d.id;

-- Show mapping summary
SELECT
    '=== Mapping Summary ===' as section,
    COUNT(*) as total_mappings,
    COUNT(DISTINCT party_name) as unique_parties,
    COUNT(DISTINCT deal_id) as unique_deals
FROM tmp_party_deal_map_final;

-- Show sample mappings
SELECT
    '=== Sample Mappings ===' as section,
    party_name,
    deal_id,
    deal_name
FROM tmp_party_deal_map_final
ORDER BY party_name, deal_id
LIMIT 50;

-- ============================================================================
-- UNMAPPED INVESTORS (for reference)
-- ============================================================================
-- These investors have commitments but no party mapping:
-- - "Robert Ciaruffoli
-- - Aaron Epstein
-- - Aaron Shenhar
-- - Abe Schear
-- - Abraham Fisher
-- - Abraham Fuchs
-- - Abraham Havron
-- - Abraham Peri
-- - Abraham Raz
-- - Adam Abrams
-- - Adam Stramwasser
-- - Adi Danon
-- - Adi Grinberg
-- - Adi Masad
-- - Adi Mor
-- - Adi Zamir
-- - Adi Zwickel
-- - Adina Greenberg
-- - Adina Shorr
-- - Adrian Bailey
-- - Adva Mendelson
-- - Alain Goldschmidt
-- - Alan Wise
-- - Albert Milstein
-- - Albert Saplitski
-- - Alevtina Stolpnik
-- - Alex Bernstein
-- - Alex Gurevich
-- - Alex Shapira
-- - Alexander Drabkin
-- - Alexander Goudz
-- - Alexander Herman
-- - Alexander Osherov
-- - Alexander Partin
-- - Alexander Shpiner
-- - Alexandra Barth
-- - Alik Rozenberg
-- - Aline Ajami Atzmon
-- - Allan Barkat
-- - Almog Chen
-- - Almog Shimon
-- - Alon Buch
-- - Alon Eliakim
-- - Alon Even
-- - Alon Even Chen
-- - Alon Ginsburg
-- - Alon Grinker
-- - Alon Haramati
-- - Alon Kristal
-- - Alon Lev Hertz
-- - Alon Markus
-- - Alon Piltz
-- - Alon Pomeranc
-- - Alon Rabinovich
-- - Alon Reshef
-- - Amichai Steimberg
-- - Amier Levkowitz
-- - Amikam Sade
-- - Amir Even Chen
-- - Amir Grimberg
-- - Amir Harush
-- - Amir Maoz
-- - Amir Naiberg
-- - Amir Novik
-- - Amir Rimon
-- - Amir Shapira
-- - Amir Shinar
-- - Amiram Levinberg
-- - Amiram Shore
-- - Amit Berger
-- - Amit Birk
-- - Amit Flohr
-- - Amit Forlit
-- - Amit Gatenyo
-- - Amit Goren
-- - Amit Katz
-- - Amit Levine
-- - Amit Porat
-- - Amit Reichman
-- - Amit Zeevi
-- - Amitai Shaul
-- - Amnon Duchovne
-- - Amnon Fattal
-- - Amnon Kaydar
-- - Amnon Magnus
-- - Amnon Pardo
-- - Amnon Shoham
-- - Amos and Lilach Ben
-- - Amos Bar Shalev
-- - Amram Eitan
-- - Amram Golan
-- - Amy Stern
-- - Anat Haramati
-- - Anat Kaluzshner
-- - Anat Madanes
-- - Anatoliy Neymark
-- - Andrew Gundle
-- - Andrew Sucoff
-- - Andrew Tanzer
-- - Andrew Thompson
-- - Andy Reiken
-- - Ari
-- - Ari Hillel
-- - Ari Shore
-- - Arianna Shapira
-- - Arie Abramovitz
-- - Arie Cipris
-- - Arie Nadler
-- - Arie Rapoport
-- - Ariel Eldar
-- - Ariel Gordon
-- - Ariel Halperin
-- - Ariel Levanon
-- - Arik Ben Dor
-- - Arnold Kostman
-- - Arnon Carmel
-- - Aron Ezra
-- - Aryeh Stern
-- - Asaf Arieli
-- - Asaf Bareket
-- - Asaf Shaltiel
-- - Asher Grinbaum
-- - Asher Holzer
-- - Assa Zohar
-- - Assaf Korner
-- - Assaf Matityahu
-- - Assaf Ziv
-- - Atai Levy
-- - Atalia Katz
-- - Avi Blumenfeld
-- - Avi Gelman
-- - Avi Goren
-- - Avi Zeevi
-- - Aviad Segal
-- - Aviad Yehezkel
-- - Avichai Cohen
-- - Aviram Gutman
-- - Aviv Drori
-- - Aviv Kfir
-- - Aviv Oranim
-- - Aviv Shapira
-- - Avner Fish
-- - Avner Shacham
-- - Avner Shaul
-- - Avraam Fried
-- - Avraham Cohen
-- - Avraham Engel
-- - Avraham Goldin
-- - Avraham Marchavka
-- - Avraham Schwartz
-- - Avrum Weinfeld
-- - Axel Inon
-- - Aya Shahar
-- - Ayal Brenner
-- - Ayelet Arouh
-- - Bar Halpert
-- - Bar Shira
-- - Bar Stein
-- - Barak Eilam
-- - Barak Naveh
-- - Barak Perlman
-- - Barden Brown
-- - Barry Finestone
-- - Barry Shaked
-- - Baruch Lerner
-- - Baruch Morag
-- - Baruch Tratner
-- - Batya Marks
-- - Beatriz Levi
-- - Ben Amrami
-- - Ben Fruchter
-- - Ben Zion Bar
-- - Benjamin Czarny
-- - Benjamin Silberman
-- - Benny Glam
-- - Benny Pinkus
-- - Benny Porat
-- - Benyamin Koren
-- - Bo Brown
-- - Boaz Dinte
-- - Boaz Harel
-- - Boaz Israeli
-- - Boaz Palgi
-- - Boaz Sokol
-- - Boaz Waksman
-- - Bob Ciaruffoli
-- - Bradley Rosenblatt
-- - Brendan Selway
-- - Brent Gindel
-- - Brian Cooper
-- - Brian Horner
-- - Brian Nebel
-- - Brittany Gale JHTC as Trustee
-- - Bronislav Doobrovsky
-- - Carofini Segal
-- - Chaim Oren
-- - Chaim Zach
-- - Chanan Schneider
-- - Chandler Brown
-- - Chava Ben David
-- - Chava Ram
-- - Chen Carmel
-- - Chen Gaist
-- - Christina Rozen
-- - Cliff Joyner
-- - Colleen Covington
-- - Coral Kuperman
-- - Corine Kuperzsmidt
-- - Cory Sams
-- - Craig Harrison
-- - Dael Shalev
-- - Dafna Yankielowicz
-- - Dalia Johananoff
-- - Dalia Shalit
-- - Dalit and Erez Mizrahi
-- - Dan Kampel
-- - Dan Lishansky
-- - Dan Pasternak
-- - Dan Shachtman
-- - Dan Shefer
-- - Dan Stemmer
-- - Dan Tocatly
-- - Dan Wartski
-- - Dana Ben
-- - Dana Landau
-- - Dana Preminger
-- - Daniel Baranes
-- - Daniel Basch
-- - Daniel Glinert
-- - Daniel Halpern
-- - Daniel Johananoff
-- - Daniel Koss
-- - Daniel Krivelevich
-- - Daniel Levinson
-- - Daniel Macadar
-- - Daniel Magen
-- - Daniel Peretz
-- - Daniel Shalev
-- - Daniel Slimak
-- - Daniel Slivkin
-- - Daniel Slutzky
-- - Danit Levi
-- - Danny Burakov
-- - Danny Gez
-- - Darius Mirshahzadeh
-- - David Baron
-- - David Chairman
-- - David Cohen
-- - David Donenberg
-- - David Ehrenberg
-- - David Elalouf
-- - David Ezra
-- - David Feiler
-- - David Fish
-- - David Frankel
-- - David Furman
-- - David Gilat
-- - David Goder
-- - David Goldfeld
-- - David Goren
-- - David Govrin
-- - David Haramati
-- - David Johnston
-- - David Katz
-- - David Kirschenbaum
-- - David Levine
-- - David Litvak
-- - David Melinger
-- - David Perlmutter
-- - David Reichman
-- - David Reznik
-- - David Schifter
-- - David Sherbin
-- - David Sitten
-- - David Stiefel
-- - David Thaler
-- - David Truzman
-- - David Waimann
-- - David Weinberger
-- - David Yahav
-- - Demetrius Nonas
-- - Dolphin Munzer
-- - Dominic Sergi
-- - Dore Friedman
-- - Doron Alter
-- - Doron Ben Eliezer
-- - Doron Greifman
-- - Doron Navati
-- - Doron Rivlin
-- - Doron Shamir
-- - Doron Sharabany
-- - Dotan Guy
-- - Dotan Klein
-- - Dotan Siman Tov
-- - Douglas Goldsmith
-- - Douglas Ross
-- - Dov Albukrek
-- - Dov Blatt
-- - Dov Fikler
-- - Dov Lavi Bleiweiss
-- - Dror Erez
-- - Dror Goldenberg
-- - Dror Itzhaki
-- - Dror Paz
-- - Dror Shomrat
-- - Dror Zetouni
-- - Eddi Haddad
-- - Eddy Hassid
-- - Edna Mandelker
-- - Edna Rabina Wilamowski
-- - Edward Best
-- - Edward Holland
-- - Edward Parkansky
-- - Efi Goren
-- - Efraeim Cohen
-- - Efraim Cohen
-- - Efraim Grynberg
-- - Efraim Lavie
-- - Ehud Admoni
-- - Ehud Almog
-- - Ehud Arad
-- - Ehud Elizur
-- - Ehud Even
-- - Ehud Goren
-- - Ehud Hameiri
-- - Ehud Shabtai
-- - Einat Barzilai
-- - Einav Bejerano Falah
-- - Eitan Antler
-- - Eitan Azta
-- - Eitan Cohen
-- - Eitan Porat
-- - Eitan Shlisselberg
-- - Elad Ichai
-- - Elad Levi
-- - Elad Raz
-- - Elan Margulies
-- - Elazar Yakirevich
-- - Elchanan Ashkenazi
-- - Eldad Firon
-- - Elhanan Abramov
-- - Elhanan Borenstein
-- - Eli Azoulay
-- - Eli David
-- - Eli Grinberg
-- - Eli Rosenberg
-- - Eli Rosenblum
-- - Eliezer Horovitz
-- - Eliezer Oren
-- - Eliezer Piha
-- - Eliezer Stern
-- - Elimelech Rosner
-- - Elior Sorek
-- - Elisheva Margulies
-- - Eliyahou Kamhine
-- - Emanuel Parter
-- - Emil Vainshel
-- - Ephraim Cohen
-- - Eran Ben Yehuda
-- - Eran Borovik
-- - Eran Eden
-- - Eran Fuchs
-- - Eran Maoz
-- - Eran Regev
-- - Eran Tal
-- - Eran Vakrat
-- - Eran Witkon
-- - Eran Wolf
-- - Erez Ben Ezra
-- - Erez Kampel
-- - Erez Kleinman
-- - Erez Noked
-- - Erez Nossek
-- - Erez Rosenwaks
-- - Erez Shaham
-- - Eric Gagnon
-- - Eric Sirkin
-- - Eshel Bar
-- - Ester Hovev
-- - Ester Steinmetz Iny
-- - Eti Livni
-- - Etty Schnitzer Neeman
-- - Eugenia Wolf
-- - Eviatar Cohen Hav
-- - Evyatar Sagie
-- - Eyal Attia
-- - Eyal Ben Eliezer
-- - Eyal Ben Yehuda
-- - Eyal Brayer
-- - Eyal Chomski
-- - Eyal Cohen
-- - Eyal Dagan
-- - Eyal Fruchter
-- - Eyal Gutman
-- - Eyal Halimi
-- - Eyal Itzhak Cohen
-- - Eyal Levin
-- - Eyal Segal
-- - Eyal Shemesh
-- - Eyal Sheratzky
-- - Eyal Slimak
-- - Eylon Penchas
-- - Eytan Dagry
-- - Eytan Zucker
-- - Ezra Werubel
-- - Fiona Rosenberg
-- - Frederick Fiddle
-- - Gabby Rubin
-- - Gabriel Asido
-- - Gabriel Schechtman
-- - Gabriel Szendro
-- - Gad Fux
-- - Gad Novak
-- - Gadi Shvarzman
-- - Gai Berkovich
-- - Gal Dagan
-- - Gal Dalal
-- - Gal Ehrlich
-- - Gal Hassid
-- - Gal Israeli
-- - Gal Kampel
-- - Gal Kats
-- - Gal Levinsky
-- - Gal Mor
-- - Gali Stamler
-- - Galia Einav
-- - Galila Oren
-- - Galit Nahmanzon
-- - Gavriel Taub
-- - Geffen Oren
-- - George Kreisberg
-- - Gershon Schnider
-- - Gidi Raff
-- - Gil Ben Hur
-- - Gil Bigon
-- - Gil Haramati
-- - Gil Hassin
-- - Gil Hecht
-- - Gil Kerbs
-- - Gil Raveh
-- - Gil Rubinstein
-- - Gil Serok
-- - Gil Slavin
-- - Gila Ben David
-- - Gila Hakhami
-- - Gila Waimann
-- - Gilad Kapelushnik
-- - Gilad Rabina
-- - Gilad Slonim
-- - Gilly Yohanani
-- - Ginat Zilberstein
-- - Gino Borges
-- - Giora Bitan
-- - Giora Erdinast
-- - Giorah Levy
-- - Global NET team Global NET
-- - Gordon Schwartz
-- - Gregory Doobrovsky
-- - Gregory Swords
-- - Gustav Stern
-- - Guy Amit
-- - Guy Barnatan
-- - Guy Ben
-- - Guy Elbaz
-- - Guy Greenberg
-- - Guy Hadar
-- - Guy Kedar
-- - Guy Levit
-- - Guy Mandel
-- - Guy Morag
-- - Guy Moses
-- - Guy Piekarz
-- - Guy Raveh
-- - Guy Shaviv
-- - Hadas Shabat
-- - Hadas Sparfeld
-- - Hagay Alter
-- - Haidee Chiat
-- - Haim Alfandari
-- - Haim Giladi
-- - Haim Jacob
-- - Haim Marcovitz
-- - Haim Rosenbaum
-- - Hana Ron
-- - Hanna Dresner Berenbaum
-- - Harel Beit On
-- - Haya Shahak
-- - Herman Zell
-- - Hilla Lavi
-- - Hilla Mogilevsky
-- - Hillel Chapman
-- - Hilli Peri
-- - Ian Fagelson
-- - Ian Jasenof
-- - Idan Geva
-- - Idan Grossman
-- - Idan Nizri
-- - Idit Harpaz
-- - Idit Ziv
-- - Ido Bukspan
-- - Ido Dvash
-- - Ido Leonov
-- - Ido Luski
-- - Ido Tenne
-- - Ido Warshavski
-- - Ifat Ginsburg
-- - Igal Nevo
-- - Igor Lotsvin
-- - Ilan Atias
-- - Ilan Grinberg
-- - Ilan Jacobson
-- - Ilan Kedem
-- - Ilan Orenstein
-- - Ilan Shemtov
-- - Ilan Shiloah
-- - Ilan Swirsky
-- - Ilan Tamir
-- - Ilana Ben
-- - Iliya Gurevich
-- - Inna Magazinik
-- - Inon Beracha
-- - Irad Ratmansky
-- - Irad Yuval
-- - Irene Rosenthal
-- - Iris Cohen
-- - Iris Reitzes Kellerman
-- - Irit Gillath
-- - Irvin Wiesman
-- - Isaac Castiel
-- - Isaac Zinger
-- - Ishai Cohen
-- - Ishay Yaari
-- - Israel and Yael David
-- - Israel Gruber
-- - Israel Meilik
-- - Israel Shaked
-- - Issachar Gerlitz
-- - Itai Forlit
-- - Itai Yenon
-- - Itamar Dach
-- - Itamar Roth
-- - Itamar Shafir
-- - Itay Azia
-- - Itay Goren
-- - Ittai Golde
-- - Itzhak Blatt
-- - Itzhak Miron
-- - Itzhak Zarnitzky
-- - Ivan Facianof
-- - Ivan Ferrer
-- - Izaac Weitz
-- - Jaacov BenJaacov
-- - Jacob Asia
-- - Jacob Assif
-- - Jacob Cohen
-- - Jacob Herzmann
-- - Jacob Rogovin
-- - Jacob Sabo
-- - Jacob Sadan
-- - Jacob Verthaizer
-- - Jacob Yaniv
-- - Jacov Ruthstein
-- - Jakov Cohen
-- - James Bogin
-- - James Cohen
-- - James DeFalco
-- - James Levine
-- - James Schultz
-- - Jeffrey Aaron
-- - Jeffrey Herbst
-- - Jeffrey Knopping
-- - Jeffrey Theobald
-- - Jeremy Goldberg
-- - Jerry Holtz
-- - Jetash Gangwal
-- - Joav Nachshon
-- - John DeFalco
-- - Jonah Bruck
-- - Jonathan Aaron
-- - Jonathan Avni
-- - Jonathan Mann
-- - Jonathan Mor
-- - Jonathan Reis
-- - Jonathan Zabusky
-- - Jonathan Zamzok
-- - Joseph Ashkenazi
-- - Joseph Brandman
-- - Joseph Cohen
-- - Joseph Fellus
-- - Joseph Hasten
-- - Joseph Johananoff
-- - Joseph Kopatch
-- - Joseph Liran
-- - Joseph Moshkovsky
-- - Joseph Rosenblum
-- - Joseph Sergi
-- - Joseph Shine
-- - Joseph Unterman
-- - Joshua Levinberg
-- - Joshua Mor
-- - Joshua Sherbin
-- - Judy Mozes
-- - Justin Zale
-- - Karen Levine
-- - Karthikeyan Thanikachalam
-- - Kefir Sade
-- - Kelvin Ninh
-- - Kenneth Beckett
-- - Kenneth Boenish
-- - Keren Fruchtman
-- - Keren Ungar
-- - Keryn Schreiber
-- - Kfir Matalon
-- - Kiran Tatiparthi
-- - Klonymus Lieberman
-- - Kush Mirani
-- - Lauren Wolff
-- - Lavi Cohen
-- - Lea Golan
-- - Lea Preminger
-- - Leeraz Rousseau
-- - Lena Oren
-- - Lenny Recanati
-- - Leonard Eis
-- - Leora Silberg
-- - Leslie Epstein
-- - Liad Orr
-- - Liat Herman
-- - Liat Oron
-- - Lidor Dvir
-- - Lihi Tadmor
-- - Lilach Shapira
-- - Lilach Shaya
-- - Linda Rand
-- - Lion Bassat
-- - Lior Alon
-- - Lior Bahat
-- - Lior Baraf
-- - Lior Goren
-- - Lior Levin
-- - Lior Martin
-- - Lior Meron
-- - Lior Sagie
-- - Lior Sharon
-- - Lior Suchard
-- - Lior Yaffe Cohen
-- - Liran Serok
-- - Liron Polkovski
-- - Lisa Korn
-- - Lital Slavin
-- - Lotan Morad
-- - Louis Blumberg
-- - Lucy Shvarzman
-- - Luv Mirani
-- - Manly Taylor Brown
-- - Maon Jacobson
-- - Marc Grossman
-- - Marc Stern
-- - Marc Strongin
-- - Marc Yoskowitz
-- - Margaret Frank
-- - Maria Renault
-- - Marina Gurtin
-- - Mario Braun
-- - Mario Riello
-- - Maris Rosenberg
-- - Marit Slavin
-- - Mark Lippman
-- - Mark Rosenberg
-- - Mary Beth Gaspich
-- - Matan Ben Shaul
-- - Matan Bichler
-- - Matan Groen
-- - Matan Holander
-- - Matanya Bar
-- - Matatya Schechtman
-- - Mati Johananoff
-- - Matthew Duffy
-- - Matthew Rosenbluth
-- - Matthew Rubin
-- - Maury Zeff
-- - Maya Eldar
-- - Maya Shaked Azulay
-- - Megan Hall
-- - Meir Dalumi
-- - Meir Mania
-- - Meir Nachshon
-- - Meir Rozolio
-- - Meir Steinbock
-- - Meir Zohar
-- - Meirav Dvash
-- - Meitav team Meitav IRA Funds
-- - Menahem Stein
-- - Menahem Waingarten
-- - Menahem Wirtzburg
-- - Mendi Rosencrantz
-- - Merav Axelrod
-- - Meytal Schwartz
-- - Michael Ashkenazi
-- - Michael Barnatan
-- - Michael Danaher
-- - Michael Dayan
-- - Michael Ishai
-- - Michael Kessel
-- - Michael Lustig
-- - Michael Maman
-- - Michael Melinger
-- - Michael Pougach
-- - Michael Rosenfeld
-- - Michael Shless
-- - Michael Tsukerman
-- - Michael Wahrhaft
-- - Michal Avtalion Rishony
-- - Michal Blumenstyk
-- - Michal Glinert
-- - Michal Gonen
-- - Michal Hassner
-- - Michal Shohat
-- - Michal Vermus
-- - Michele Kaminsky
-- - Michele Maiman Firon
-- - Michelle Maack
-- - Mickey Hanegbee Kaplinsky
-- - Miguel Zamarripa
-- - Mika Azia
-- - Mina Beilis
-- - Miriam Attar
-- - Miriam Micky Tuttnauer
-- - Miriyam Kerbs
-- - Monica DeFruscio
-- - Mor Atlas
-- - Mor Shvarzman
-- - Moran Bar
-- - Mordechai Nimrod Gindi
-- - Mordechai Orenstein
-- - Mordechai Serock
-- - Mordechay Baitner
-- - Mordechay Eliyahoo
-- - Mordechay Maaravi
-- - Moshe Barnes
-- - Moshe Graber
-- - Moshe Lasman
-- - Moshe Lehrer
-- - Moshe Lifschitz
-- - Moshe Mashiach
-- - Moshe Matityahu
-- - Moshe Namdar
-- - Moshe Nerson
-- - Moshe Oz
-- - Moshe Ran
-- - Moshe Reuveni
-- - Moshe Salem
-- - Moshe Tsabari
-- - Moti Hamama
-- - Moti Lichi
-- - Moty Goren
-- - Naama Shmocher
-- - Nadav Golander
-- - Nadav Shachar
-- - Nadine Gesundheit
-- - Naftali and Dalia Narkys
-- - Nahman Yahav
-- - Naomi Avitan
-- - Naomi Belfer
-- - Naor Levi
-- - Natan Eitan Toledo
-- - Nathan Aronovici
-- - Nathan Palanker
-- - Nathan Ron
-- - Neil Corney
-- - Netanela Kristal
-- - Netanella Tani Zahavi
-- - Nhevo Kaufman
-- - Nick Shrayer
-- - Nicky Stup
-- - Nicolas Gortzounian
-- - Nimrod Dassa
-- - Nimrod Karni
-- - Nimrod Zuta
-- - Nir Avni
-- - Nir Avraham
-- - Nir Chanoch
-- - Nir Cohen
-- - Nir Fux
-- - Nir Hayzler
-- - Nir Jacoel
-- - Nir Nof
-- - Nisim Segalovich
-- - Nissim Adar
-- - Nissim Bar
-- - Nissim Gvili
-- - Nissim Moshe
-- - Nitzan Shapira
-- - Niv Hanan
-- - Niv Kagan
-- - Niv Raviv
-- - Niv Taiber
-- - Niv Zecler
-- - Niv Zer
-- - Noa Grinberg
-- - Noa Parag
-- - Noah Slimak
-- - Noam Goldstein
-- - Noam Wolf
-- - Noga Karni
-- - Noga Peer
-- - Noga Shteinboim Atsil
-- - Nomi Kapalner
-- - Nurit Bachrach
-- - Nurith Jaglom
-- - Octavian Patrascu
-- - Oded Edelman
-- - Oded Fuchs
-- - Oded Kopatz
-- - Oded Margalit
-- - Oded Morag
-- - Ofer Ben
-- - Ofer Eldar
-- - Ofer Iny
-- - Ofer Lowinger
-- - Ofer Lux
-- - Ofer Miller
-- - Ofer Tirosh
-- - Offer Yarkoni
-- - Ofir Fishof
-- - Ofir Rimoni
-- - Ofir Yosef
-- - Ofra Rivlin
-- - Ohad Freund
-- - Ohad Reshef
-- - Omer Avlas
-- - Omer Belsky
-- - Omer Gattenio
-- - Omer Peleg
-- - Omer Schalit
-- - Omri Gur Lavie
-- - Omri Kaftzan
-- - Omri Liba
-- - Operations team Conscientia Family Office
-- - Ophir Eis
-- - Ophir Turbovich
-- - Or Kleinman
-- - Or Peri
-- - Oren Avraham
-- - Oren Buskila
-- - Oren Cohen
-- - Oren Hadar
-- - Oren Ifrach
-- - Oren Kladnitsky
-- - Oren Lazarovich
-- - Oren Mangel
-- - Oren Mendelson
-- - Oren Pereg
-- - Oren Rosenzweig
-- - Oren Sagi
-- - Oren Shamir
-- - Oren Wener
-- - Ori Ben Moshe
-- - Ori Druker
-- - Ori Inbar
-- - Ori Kaufman Gafter
-- - Ori Stav
-- - Orit Karabel
-- - Orit Kolonimus
-- - Orit Noked
-- - Orit Shamir
-- - Orit Sinai
-- - Orna Kleinman
-- - Oron Stern
-- - Orr Barak
-- - Orren Peled
-- - Ory Milleau
-- - Osnat Levi
-- - Ovadya Hamama
-- - Patricia Margulies
-- - Paul Aiesi
-- - Phinhas and Sara Dickstein
-- - Phoenix team Phoenix
-- - Piero Marigo
-- - Pietro Sternini
-- - Pinchas Gdaliahu
-- - Pinchas Ginsburg
-- - Pinhas Gaist
-- - Prasanna Chimata
-- - Praveen Dukkipati
-- - Rachel Even Chen
-- - Rachel Gafni
-- - Rafael Aravot
-- - Rafi Albo
-- - Rafi Biton
-- - Rakefet Kuperman
-- - Rami Ben Nathan
-- - Rami Livnat
-- - Rami Romano
-- - Rammy Bahalul
-- - Ran Achituv
-- - Ran Avidan
-- - Ran Ben
-- - Ran Feiwisch
-- - Ran Heilpern
-- - Ran Kampel
-- - Ran Machtinger
-- - Ran Oz
-- - Ran Ravid
-- - Ran Ribenzaft
-- - Ran Shallish
-- - Ran Shevi
-- - Ravit Rosenberg
-- - Ravit Yanko Arzi
-- - Rebecca Brown
-- - Rebecca Mati
-- - Refael Yerushalmi
-- - Remez Bariach
-- - Rephael Germon
-- - Reuben Schrift
-- - Rev Lebardedian
-- - Richard Blau
-- - Richard Bondie
-- - Richard Kaitz
-- - Rimona Flint
-- - Rina Avraham
-- - Rivka Kompel
-- - Rivka Rubin Tautan
-- - Robert Hodge
-- - Robert Quinn
-- - Robert Sherbin
-- - Robert Weisz
-- - Robert Wizenberg
-- - Roberto Slimak
-- - Roee Schreiber
-- - Roee Shapiro
-- - Roee Vulkan
-- - Roi Ben Itzhak
-- - Roi Caspi
-- - Roi Turgeman
-- - Roi Zemmer
-- - Roie Edelman
-- - Roie Sagi
-- - Ron Eyal
-- - Ron Golan
-- - Ron Guttmann
-- - Ron Hartston
-- - Ron Konigsberg
-- - Ron Preis
-- - Ron Schechter
-- - Ron Schulman
-- - Ron Senator
-- - Ron Yakir
-- - Ron Zetouni
-- - Rona
-- - Ronen and Elynne Gold
-- - Ronen and Pessia Katan
-- - Ronen Barak
-- - Ronen Barel
-- - Ronen Ben Ami
-- - Ronen Berkovich
-- - Ronen Matry
-- - Ronen Moas
-- - Ronen Shilo
-- - Ronen Soffer
-- - Ronen Tavor
-- - Ronen Waisserberg
-- - Ronen Yablon
-- - Roni Ashuri
-- - Roni Atoun
-- - Roni Eiger
-- - Roni Stadler
-- - Roni Tuttnauer
-- - Ronnen Lovinger
-- - Ronnie Botton
-- - Ronny Cohen
-- - Rony Eitany
-- - Rony Lerner
-- - Rony Lev
-- - Ross Chaifetz
-- - Rotem Barzilay
-- - Roy Oron
-- - Rubin Schlussel
-- - Ruli Ben Michael
-- - Ruth Shafir
-- - Ruth Siegel
-- - Ryan Rapaski
-- - Sagi Hakmon
-- - Sagi Michelson
-- - Sagi Rotem
-- - Sagi Weinblat
-- - Sagiv Stavinsky
-- - Saleet Granit
-- - Sally Reidman
-- - Salo Mandelbaum
-- - Salvador Huino
-- - Sam Rabina
-- - Sami Ekhaus
-- - Sami Shiro
-- - Sammy Shukrun
-- - Samuel Sattath
-- - Samuel Zell
-- - Sanford Bokor
-- - Sara Tovi
-- - Sarah Ann Margulies
-- - Sarah Levi
-- - Sarah Pavoncello
-- - Sasha Slimak
-- - Scott Lawrence
-- - Scott Perlen
-- - Scott Spear
-- - Sean Shvarzman
-- - Shachar Levy
-- - Shahaf Shuler
-- - Shahar Ben Moshe
-- - Shahar Erez
-- - Shai Bazak
-- - Shai Beilis
-- - Shai Meirson
-- - Shai Reuven
-- - Shai Sheffer
-- - Shalom Avni
-- - Shalom Hochman
-- - Shameem Kahn
-- - Shani Shalgi
-- - Shantam Zohar
-- - Shany Alon
-- - Sharon Finkel
-- - Sharon Goldstone
-- - Sharon Hashimshoni
-- - Sharon Kotlicki
-- - Sharon Schweppe
-- - Sharon Sheer
-- - Sharon Wagner
-- - Shaul Rikman
-- - Shavit Fragman
-- - Shay Berka
-- - Shay Dayan
-- - Shay Geler
-- - Shay Shevi
-- - Shay Zadok
-- - Shimon Gesundheit
-- - Shimon Greenberg
-- - Shimon Keren
-- - Shimon Sheves
-- - Shira Lichtenstadt
-- - Shirit Harpaz
-- - Shirley Gal
-- - Shirley Schwartz
-- - Shirley Slimak Ratner
-- - Shlomi Zac
-- - Shlomit Rozenfeld
-- - Shlomit Zamir
-- - Shlomith Yaron
-- - Shlomo Hakim
-- - Shlomo Jeret
-- - Shlomo Latinik
-- - Shlomo Lifschitz
-- - Shlomo Liran
-- - Shlomo Shamir
-- - Shlomo Tamir
-- - Shlomo Waldmann
-- - Shlomo Wertheim
-- - Shlomoh Ben
-- - Shmuel Eden
-- - Shmuel Herman
-- - Shoshana Kremer
-- - Shoval Tshuva
-- - Shraga Michelson
-- - Shraga Shahak
-- - Shy Avni
-- - Sima Ben Chetrit
-- - Simon Braun
-- - Snir Hassin
-- - Sofia Kimerling
-- - Spencer Green
-- - Steven Ball
-- - Steven Greenbaum
-- - Steven Lavin
-- - Susan Wagner
-- - Susan Zechter
-- - Suzana Kugler
-- - Svetlana Hefetz
-- - Sylvie Tovy
-- - Tal Aviv
-- - Tal Berger
-- - Tal Edelman
-- - Tal Even
-- - Tal Gabay
-- - Tal Koren
-- - Tal Levine Arad
-- - Tal Rivkind
-- - Tal Simchony
-- - Tal Weissman
-- - Talia Yogev
-- - Talya Ben Tovim
-- - Tamar Golan
-- - Tamar Hirsh
-- - Tamar Mozes Borovitz
-- - Tamar Oz
-- - Tamar Schifter
-- - Tamir Azarzar
-- - Tamir Bogin
-- - Tamir Mizrahi
-- - Tamir Shabat
-- - Tanhum Oren
-- - Terry Dickerson
-- - Thomas Latsos
-- - Tianyu Wang
-- - Tlalit Prescher
-- - Tobey Sheridan
-- - Tom Azar
-- - Tom Galili
-- - Tom Livne
-- - Tom Richter
-- - Tomer Bogin
-- - Tomer Dalumi
-- - Tomer Dor
-- - Tomer Koko
-- - Tomer Schlussel
-- - Tomer Tzuman
-- - Tomer Weissman
-- - Tomer Wertheimer
-- - Total
-- - Tova Even Chen
-- - Tsahi Weiss
-- - Tsur Moses
-- - Tzipora Carmon
-- - Tziporet Koren
-- - Tzuriel Katoa
-- - Tzvi Vainer
-- - Tzvia Frank
-- - Udi Eyal Fima
-- - Udi Goren
-- - Uri Ben Menachem
-- - Uri Efroni
-- - Uri Golani
-- - Uri Levine
-- - Uri Pundak
-- - Uri Zror
-- - Uriel Fischer
-- - Uziel Waissman
-- - Valeria Tsukerman
-- - Vicky Levy
-- - Victor Levitan
-- - Victorya Rofeim
-- - Viki Bencuya Sagol
-- - Walter Miller
-- - William Bermont
-- - William Creekmore
-- - Yaacov Ben Eliezer
-- - Yaacov Kotlicki
-- - Yaakov Hadar
-- - Yaakov Ringler
-- - Ya'aqov Segal
-- - Yael Achiaz
-- - Yael Goren
-- - Yael Holdengreber
-- - Yael Sade
-- - Yael Segal
-- - Yael Strauss
-- - Yahal Zilka
-- - Yair Averbuch
-- - Yair Navot
-- - Yair Peled
-- - Yair Tzur
-- - Yair Walker
-- - Yair Ziv
-- - Yakar Sidis
-- - Yaki Razmovich
-- - Yakov Bar
-- - Yakov Machluf
-- - Yam Rubinstein
-- - Yaniv Dar
-- - Yaniv Gavish
-- - Yaniv Gruenwald
-- - Yaniv Kleinman
-- - Yaniv Levi
-- - Yaniv Nissim
-- - Yaniv Perry
-- - Yaniv Saylan
-- - Yaniv Vakrat
-- - Yariv Avrahami
-- - Yariv Haelyon
-- - Yariv Robinson
-- - Yaron Aloni
-- - Yaron Haramati
-- - Yaron Hertz
-- - Yaron Lamy
-- - Yaron Menashe
-- - Yaron Shohat
-- - Yaron Spector
-- - Yehezkel Schwartz
-- - Yehiel Ben Ari
-- - Yehonatan Hirshberg
-- - Yehoshua Sarig
-- - Yehoshua Weiss
-- - Yehoshua Zifrut
-- - Yehuda Alon
-- - Yehuda Mayshar
-- - Yehuda Tendler
-- - Yekutiel Raz
-- - Yevgeny Kliteynik
-- - Ygal Zror
-- - Yigal Funt
-- - Yigal Jacoby
-- - Yigal Pergamentzev
-- - Yigal Shefer
-- - Yigal Shemesh
-- - Yinon Kuperstein
-- - Yishai Fuchs
-- - Yishay Shachar
-- - Yitshak Ben
-- - Yitzhak Mizrahi
-- - Yizchak Zuriel
-- - Yoav Gross
-- - Yoav Holzer
-- - Yoav Lachover
-- - Yoav Levy
-- - Yoav Narkys
-- - Yohay Ben Itzhak
-- - Yonatan Malkiman
-- - Yonatan Stern
-- - Yoni Aziz
-- - Yoni Leiman
-- - Yoram Avi
-- - Yoram Burg
-- - Yoram Duchovne
-- - Yoram Dvash
-- - Yoram Hadar
-- - Yoram Hoffman
-- - Yoram Levinson
-- - Yoram Mehr
-- - Yoram Nagelstein
-- - Yoram Shalit
-- - Yoram Tietz
-- - Yoram Yohanani
-- - Yosef Barazani
-- - Yosef Ben Dor
-- - Yosef Michaeli
-- - Yosef Stern
-- - Yosi Shiloni
-- - Yossef Kasus
-- - Yossef Semeloy
-- - Yossi Reznik
-- - Yotam Elal
-- - Yudith Sarfaty
-- - Yuval Bar
-- - Yuval Bryt
-- - Yuval Harary
-- - Yuval Kamhi
-- - Yuval Katz
-- - Yuval Keren
-- - Yuval Malka
-- - Yuval Meidar
-- - Yuval Naftaly
-- - Yuval Stern
-- - Yuval Terem
-- - Zachary Ball
-- - Zeev Ariel
-- - Zeev Beer
-- - Zeev Livnat
-- - Zeevik Kopatz
-- - Zelman Fridman
-- - Zion Ben Rafael
-- - Ziv Carthy
-- - Ziv Paz
-- - Ziv Shalev
-- - Zivit Beilis
-- - Zohar Gafni
-- - Zur Erez
-- - Zvi Bar
-- - Zvi Cohen
-- - Zvi Genis
-- - Zvi Greenstein
-- - Zvi Shmueli
-- - Zvika Golos
-- - Zwi Williger
