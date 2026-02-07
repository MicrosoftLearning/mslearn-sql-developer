-- Create the ProductReview table
IF OBJECT_ID('dbo.ProductReview', 'U') IS NOT NULL
    DROP TABLE dbo.ProductReview;
GO

CREATE TABLE dbo.ProductReview (
    ReviewID INT NOT NULL,
    ProductID INT NOT NULL,
    Rating TINYINT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    ReviewTitle NVARCHAR(200) NOT NULL,
    ReviewText NVARCHAR(MAX) NOT NULL,
    ReviewDate DATE NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_ProductReview PRIMARY KEY CLUSTERED (ReviewID)
);
GO

INSERT INTO dbo.ProductReview (ReviewID, ProductID, Rating, ReviewTitle, ReviewText, ReviewDate) VALUES
---------------------------------------------------------------------
-- ROAD BIKES
---------------------------------------------------------------------
-- Road-150 (803) — top-tier road bike
(1, 803, 5, N'Perfect commuter road bike', N'I ride 12 miles each way to work and the Road-150 handles everything from bike lanes to rough pavement. After eight months of daily use in rain and shine, the drivetrain still shifts crisply and the frame shows zero fatigue. Best commuting investment I have ever made.', '2024-03-15'),
(2, 803, 4, N'Great frame but stock wheels are heavy', N'The Road-150 frame is outstanding — stiff, light, and responsive. However, the stock wheels feel sluggish on climbs compared to aftermarket options. I upgraded the wheelset and now it flies. The frame alone makes this bike worth the price.', '2024-07-22'),
(3, 803, 2, N'Sizing chart was way off for me', N'Ordered the Road-150 based on the sizing chart and it was too large. The reach was uncomfortably long even with a shorter stem. Ended up exchanging for a smaller frame which fits much better. The bike itself is fine once you get the right size but the sizing guidance needs work.', '2024-11-08'),

-- Road-150 Red (805) — race machine
(4, 805, 5, N'Podium machine', N'Took the Road-150 Red to a state championship time trial and set a personal best by 47 seconds over 25 miles. The aerodynamic tube profiles and stiff bottom bracket make this bike disappear beneath you when the effort goes up. Worth every penny.', '2025-03-08'),
(5, 805, 5, N'Climber dream bike', N'The Road-150 Red weighs so little that the steepest hills feel merely challenging instead of impossible. I set personal records on five different climb segments in my first month of ownership. Pure climbing joy.', '2024-06-01'),
(6, 805, 2, N'Uncomfortable for rides over two hours', N'The Road-150 Red is blindingly fast but the aggressive race geometry gave me lower back pain on anything over two hours. Great for crits and time trials, not great if you want to ride all day. Know what you are buying.', '2025-01-14'),

-- Road-250 Red (808)
(7, 808, 5, N'Race-ready out of the box', N'Won my age group in six criteriums this season on the Road-250 Red. The aggressive geometry puts me in a powerful aero position and the quick handling lets me dive into corners ahead of the pack.', '2024-05-10'),
(8, 808, 3, N'Fast but harsh ride on rough roads', N'The Road-250 Red is blazing fast on smooth tarmac but on rough chip-seal roads every bump travels straight to your hands and spine. Added thicker bar tape which helped. A great race bike, not the best choice if your roads are rough.', '2024-12-18'),

-- Road-250 Black (812)
(9, 812, 4, N'Fast and comfortable for a race bike', N'Raced my first gran fondo on the Road-250 Black and averaged 19.5 mph over 80 miles. The frame is stiff enough for sprints but compliant enough that I was not destroyed at the finish. A rare combination at this price.', '2024-09-15'),
(10, 812, 3, N'Paint chips way too easily', N'The Road-250 Black rides wonderfully but the paint is fragile. After two months I had chips on the chainstay from chain slap and near the head tube from cable rub. Cosmetically disappointing for a bike at this price.', '2025-03-02'),

-- Road-450 Red (820)
(11, 820, 3, N'Good value racer with weak wheels', N'The Road-450 Red is competitive for local races but the stock wheels hold it back at higher speeds. I upgraded the wheelset and suddenly it felt like a different bike. The frame itself has great geometry for racing — budget for better wheels.', '2024-11-30'),

-- Road-550-W Yellow (825)
(12, 825, 5, N'Sunday ride perfection', N'The Road-550-W is my go-to for Sunday morning rides through the countryside. I typically cover 25-30 miles at a relaxed pace and the geometry keeps me comfortable the entire time.', '2024-07-12'),
(13, 825, 2, N'Not suited for taller riders', N'Even in the largest size the Road-550-W felt cramped for my longer torso. The top tube is noticeably shorter than other bikes in this category. Riders under 5 foot 8 will probably love it but taller riders should look elsewhere.', '2025-01-20'),

-- Road-550-W Yellow (826)
(14, 826, 5, N'Comfortable road position for smaller riders', N'Most road bikes put too much weight on my hands. The Road-550-W geometry shifts weight rearward just enough that I can ride 60 miles without wrist pain. The 40cm bars match my narrow shoulders perfectly.', '2024-09-22'),
(15, 826, 3, N'Handlebars flex during hard efforts', N'Comfortable for cruising, but when I stand and sprint the handlebars flex noticeably. Fine for recreational riding but not confidence-inspiring when pushing hard. Upgraded the bar and stem and the issue went away.', '2025-02-11'),

-- Road-650 Black (836)
(16, 836, 4, N'Solid daily commuter', N'Switched from the bus to cycling 9 miles to my office. The Road-650 Black is lightweight enough for hills and stable enough for traffic. Wish it came with fender mounts — had to get creative with clip-ons for rainy commutes.', '2024-05-22'),
(17, 836, 3, N'Decent but component quality is mixed', N'The Road-650 frame is great for the price but some components feel cheap. The brake pads wore out in two months and the cables stretched within the first month requiring adjustment. Budget a bit extra for part upgrades.', '2024-09-14'),
(18, 836, 4, N'Great first road bike', N'Transitioned from a hybrid to the Road-650 Black and was nervous about the drop bars. Within a week I was comfortable in every hand position and wondering why I waited so long. It is fast, fun, and less intimidating than expected.', '2024-05-07'),

-- Road-650 Red (830)
(19, 830, 4, N'Reliable rain or shine commuter', N'Replaced my car with the Road-650 Red for a 7-mile commute and have not looked back. I ride through rain, wind, and cold and the bike handles everything without drama. The stock saddle got uncomfortable after month three but a replacement fixed that.', '2024-09-17'),
(20, 830, 1, N'Arrived with a bent derailleur hanger', N'The Road-650 Red showed up with a visibly bent derailleur hanger. Could not shift into the three smallest cogs at all. Had to take it to a shop for realignment before I could ride it. Very disappointing for a new bike.', '2025-01-05'),
(21, 830, 5, N'Best budget road bike for daily riding', N'Compared the Road-650 Red against three competitors at the same price and nothing came close. You get decent components, a solid frame that could accept future upgrades, and enough speed to make commuting fun. Smart money goes here.', '2024-04-27'),

-- Road-350-W (816, 817)
(22, 816, 4, N'Comfortable geometry for smaller frames', N'The Road-350-W fits my 5 foot 3 frame perfectly. The shorter top tube and narrower handlebars eliminate the shoulder strain I experienced on unisex bikes. I can ride for three hours without any numbness or discomfort.', '2024-06-24'),
(23, 816, 5, N'Proportions that actually make sense', N'The Road-350-W has the right proportions for smaller riders. The shorter crank arms match my leg length, the handlebars match my shoulder width, and the saddle is comfortable from mile one. This is how bikes should be built for different body types.', '2024-03-10'),
(24, 817, 4, N'Keeps up with more expensive bikes', N'I ride 30-40 miles every Saturday with a group and the Road-350-W keeps up with riders on bikes costing twice as much. The components are dependable and the paint scheme looks great. Excellent value.', '2025-04-18'),
(25, 819, 4, N'Handles hilly terrain gracefully', N'My usual loop has 3,500 feet of climbing over 40 miles. The Road-350-W makes these rides achievable with its compact crankset and wide-range cassette. I arrive home tired but not broken.', '2024-11-09'),

---------------------------------------------------------------------
-- MOUNTAIN BIKES
---------------------------------------------------------------------
-- Mountain-100 Silver (771) — top-tier MTB
(26, 771, 5, N'Absolute trail weapon', N'The Mountain-100 Silver tears through rocky singletrack. The suspension soaks up root gardens and the hydraulic brakes inspire total confidence on steep descents. I have never felt more capable on technical terrain.', '2024-01-20'),
(27, 771, 5, N'Conquers any climb on loose terrain', N'Took the Mountain-100 Silver up a 2,000-foot climb on loose switchbacks and the combination of low gearing and front suspension traction was unstoppable. The lightweight frame makes standing climbs feel natural. This bike eats elevation.', '2024-01-25'),
(28, 771, 3, N'Developed a creaky bottom bracket', N'The Mountain-100 Silver rides amazingly but developed an annoying creak in the bottom bracket after about four months. The shop re-torqued it and applied fresh grease which helped temporarily. The creak returned. Frame and components are otherwise excellent.', '2024-10-05'),

-- Mountain-100 Black (775) — top-tier MTB
(29, 775, 5, N'Dominates rough technical terrain', N'Raced the Mountain-100 Black in three enduro events this season and finished on the podium twice. It is incredibly composed at speed through rock gardens and the frame stiffness translates every pedal stroke into forward motion on the climbs.', '2024-04-05'),
(30, 775, 5, N'Durability after years of hard riding', N'Three years and 8,000 miles of aggressive trail riding on the Mountain-100 Black and the frame shows zero cracks, dents, or fatigue marks. I have replaced consumables but the chassis itself seems indestructible. Built to last.', '2024-03-18'),
(31, 775, 2, N'Rear shock leaked oil after five months', N'The Mountain-100 Black frame is outstanding but the rear shock started leaking oil after five months of normal trail riding. Got it replaced under warranty which took three weeks. Bike has been fine since but not what you expect at this price point.', '2025-01-14'),
(32, 776, 5, N'Night and day upgrade from an old bike', N'Coming from a decade-old hardtail the Mountain-100 Black feels like it is from another dimension. The suspension eats rocks I used to detour around and the single-chainring drivetrain simplifies everything. Modern mountain bikes are incredible.', '2025-02-08'),

-- Mountain-200 (783, 779)
(33, 783, 4, N'Great mid-range trail bike', N'The Mountain-200 Black handles Pacific Northwest trails with ease. Mud, roots, loose gravel — nothing fazes this bike. It is a step down from the 100 series in components but the frame itself is superb for the money.', '2024-06-18'),
(34, 783, 3, N'Fork bottoms out on bigger hits', N'The Mountain-200 Black is solid for moderate trails but the fork bottoms out on bigger drops and rock gardens. Fine for cross-country riding but if you want to ride aggressively budget for a fork upgrade down the road.', '2025-02-28'),
(35, 779, 5, N'Massive upgrade from my old hardtail', N'Replaced a 14-year-old hardtail with the Mountain-200 Silver and the technology leap is staggering. Modern suspension, hydraulic disc brakes, and improved geometry made trails I used to struggle on feel approachable. Should have upgraded years ago.', '2024-02-18'),

-- Mountain-300 (787, 790)
(36, 787, 4, N'Solid entry into serious trail riding', N'Upgraded from a department store bike to the Mountain-300 and the difference is staggering. I can finally ride the intermediate trails at the local park without walking half the obstacles. The frame is confidence-inspiring on moderate drops.', '2024-12-01'),
(37, 787, 4, N'Frame integrity after years of hard use', N'Riding the Mountain-300 Black for over two years on rocky desert trails. The frame has taken direct hits from rocks and rough handling. Not a single crack or warranty issue. Impressive longevity for a mid-range bike.', '2025-03-15'),
(38, 787, 2, N'Brakes squeal constantly in wet weather', N'Every time it rains the Mountain-300 brakes make an embarrassing squealing noise. Tried different pads and bedding-in procedures but nothing eliminates it completely. Dry performance is fine but wet braking is loud and weak.', '2024-08-19'),
(39, 790, 4, N'Reliable climbing gears', N'The Mountain-300 has a gear range that lets me spin up 15 percent grades without straining my knees. The cassette offers tight enough spacing that I am never caught between gears on variable-grade climbs. Descends capably too.', '2024-08-22'),

-- Mountain-400-W (791, 793)
(40, 791, 4, N'First mountain bike that fits properly', N'The Mountain-400-W is the first mountain bike where I did not have to modify every contact point. The stock setup works for my proportions. I am clearing technical features I could not ride on my old bike. Confidence-boosting geometry.', '2024-06-15'),
(41, 791, 2, N'Stem length is awkwardly short', N'The Mountain-400-W comes with an extremely short stem that made the steering feel twitchy and nervous on fast descents. Swapping to a slightly longer stem transformed the handling. Strange choice for a stock setup.', '2025-03-09'),
(42, 793, 4, N'Fit that works for smaller riders', N'The Mountain-400-W solved every fit issue I had with other mountain bikes. The saddle is comfortable, the reach is natural, and I can weight the front wheel without overextending. Finally a real option for smaller mountain bikers.', '2025-04-10'),

-- Mountain-500 (795, 796, 797, 799, 800)
(43, 795, 5, N'Perfect weekend trail companion', N'We take the Mountain-500 Silver out every Saturday morning on the greenway trails. It is forgiving enough for casual riding but capable enough when we hit the gravel sections. Best recreational mountain bike at this price.', '2024-02-14'),
(44, 795, 3, N'Pedal threads stripped out of the crank', N'After six months of riding the left pedal thread stripped right out of the aluminum crank arm. The shop said the threads were not properly faced at the factory. Warranty covered the replacement but I was without my bike for two weeks.', '2024-12-03'),
(45, 796, 5, N'Best first real mountain bike', N'Just started mountain biking at 34. The Mountain-500 Silver was recommended by the shop and it has been incredibly forgiving of rookie mistakes. The wide tires keep me stable and the gearing lets me crawl up hills I would otherwise walk. Great beginner bike.', '2024-01-30'),
(46, 797, 5, N'Incredible value for the money', N'The Mountain-500 Silver offers components and ride quality that I would expect at twice the price. The hydraulic brakes alone are worth the entry fee. For anyone wanting a capable mountain bike on a budget this is it.', '2024-02-05'),
(47, 799, 3, N'Decent starter but has limits', N'The Mountain-500 Black is fine for fire roads and easy trails but it struggles on more technical terrain. The fork feels underdamped on rocky descents. Good starter mountain bike but I am already eyeing an upgrade after six months.', '2025-02-10'),
(48, 800, 4, N'Great family weekend bike', N'Bought the Mountain-500 Black for Saturday rides with the family. The gearing makes it easy to keep pace on flat paths and I can still tackle moderate hills. Comfortable enough for our typical 15-mile loops around the lake.', '2024-04-08'),
(49, 800, 2, N'Chain drops constantly on bumpy terrain', N'On anything bumpier than a gravel path the chain on the Mountain-500 drops off the front chainring at least once per ride. Added a chain guide which fixed it but this should not be necessary on a bike at this price point.', '2025-04-01'),

---------------------------------------------------------------------
-- TOURING BIKES
---------------------------------------------------------------------
-- Touring-1000 Yellow (842, 843, 844)
(50, 842, 5, N'Built for the long haul', N'Took the Touring-1000 Yellow on a 600-mile ride along the coast. The steel frame absorbed road vibrations beautifully and the triple crankset handled every coastal climb. This bike was born for loaded touring.', '2024-03-28'),
(51, 842, 5, N'Home on two wheels', N'Spent six weeks bikepacking through the mountains on the Touring-1000 and it never let me down. The frame geometry distributes loaded weight perfectly keeping the steering neutral even with full panniers front and rear. Already planning my next adventure.', '2025-01-18'),
(52, 842, 3, N'Very heavy when riding unloaded', N'The Touring-1000 Yellow is fantastic when loaded with gear but riding it unloaded around town feels like pedaling a tank. The steel frame weight is very noticeable without panniers to justify it. Great touring bike but not a do-everything bike.', '2024-10-12'),
(53, 843, 4, N'Huge step up for touring', N'My old touring bike weighed 35 pounds and had friction shifters. The Touring-1000 Yellow is lighter, shifts precisely, and stops confidently in any weather including heavy rain. It renewed my enthusiasm for multi-day rides.', '2024-08-14'),
(54, 844, 5, N'Carries 50 pounds like it is nothing', N'Loaded the Touring-1000 with front and rear panniers totaling 50 pounds for a month-long tour. The bike handled predictably even when fully loaded and the triple chainring made mountain passes manageable. A true pack mule for touring.', '2024-12-08'),

-- Touring-1000 Blue (846)
(55, 846, 5, N'Crossed three states on this bike', N'Completed a two-week tour with 40 pounds of gear on the racks and the bike remained stable and predictable. The frame eyelets for racks and fenders made setup effortless. Highly recommend for loaded touring.', '2024-05-15'),
(56, 846, 4, N'Reliable but gearing could be lower', N'The Touring-1000 Blue handles loaded climbing well but on truly steep mountain passes with full panniers I wished for one more low gear. The rest of the drivetrain is bulletproof. Consider your terrain before buying.', '2025-02-06'),

-- Touring-2000 (850)
(57, 850, 4, N'Capable mid-range touring platform', N'The Touring-2000 handled a 400-mile charity ride without a single mechanical issue. It is not as plush as the 1000 series but at this price point the value is exceptional. Recommend upgrading the saddle for multi-day rides though.', '2024-09-10'),
(58, 850, 2, N'Rack eyelets were not threaded properly', N'Tried to mount a rear rack and discovered the frame eyelets were cross-threaded from the factory. Had to have a shop chase the threads before I could bolt anything on. For a touring bike rack mounts should be perfect out of the box.', '2025-04-14'),

-- Touring-3000 (854, 855, 856, 857, 859)
(59, 854, 4, N'Enjoyable leisure touring', N'We have ridden canal towpaths, converted rail trails, and gentle forest roads without any issues. The relaxed position means no sore neck after hours in the saddle. Great for light touring and recreational riding.', '2024-08-20'),
(60, 854, 3, N'Fine for paved paths but limited on gravel', N'The Touring-3000 is comfortable on smooth surfaces but the narrow tires and limited clearance mean gravel roads are sketchy. If your touring plans include unpaved sections you will want wider tires and this frame cannot accommodate them.', '2025-01-27'),
(61, 855, 5, N'Touring made easy for a first-timer', N'Never toured before but bought the Touring-3000 Blue and did a 200-mile trip along a canal towpath. The stable handling and comfortable position made it feel effortless. This bike turned me into a lifelong touring enthusiast.', '2025-03-25'),
(62, 856, 5, N'Budget touring done right', N'The Touring-3000 Blue delivered a comfortable 500-mile tour through the Midwest at a price that left money in the budget for camping gear. It lacks the refinement of the 1000 series but on tour that honestly did not matter.', '2024-10-19'),
(63, 859, 4, N'Good entry-level touring bike', N'Bought the Touring-3000 Yellow for a first bike tour. The relaxed geometry is comfortable and it completed a 3-day 150-mile tour without any issues. A great starting point for anyone curious about touring.', '2024-11-25'),

---------------------------------------------------------------------
-- HELMETS
---------------------------------------------------------------------
-- Sport-100 Red (707)
(64, 707, 5, N'Bright and visible for safety', N'Chose the Sport-100 Red specifically for visibility during dawn and dusk rides. The bright red shell paired with the integrated reflective strips makes me easy to spot. Comfortable enough to forget I am wearing it. Safety first.', '2024-10-25'),
(65, 707, 3, N'Runs warm in summer heat', N'The Sport-100 Red looks great and fits well but the ventilation is lacking on hot days. Anything above 80 degrees and my head overheats noticeably. Fine for spring and fall riding but I switch to a different helmet in summer.', '2025-03-20'),

-- Sport-100 Blue (708)
(66, 708, 5, N'Great starter helmet for new riders', N'The Sport-100 Blue was the first piece of cycling gear I bought. It is lightweight, well-ventilated, and the protection gives me peace of mind as a new rider still learning to handle the bike in traffic. Essential safety gear.', '2024-07-19'),
(67, 708, 5, N'Perfect helmet for beginners', N'The Sport-100 Blue fits perfectly and looks good. The adjustable retention system is easy to use and the overall construction quality is solid. Great entry-level safety gear that does not cut corners.', '2024-09-12'),
(68, 708, 2, N'Chin strap buckle pinches skin', N'Every time I fasten the Sport-100 Blue chin strap it pinches the skin under my chin. The helmet itself fits fine but the buckle design is uncomfortable. I have to hold a finger between the buckle and my chin while fastening it.', '2025-01-30'),

-- Sport-100 Black (709)
(69, 709, 5, N'Visible and ventilated for night riding', N'The Sport-100 in black has reflective accents that light up dramatically in headlights. Drivers give me noticeably more room at night. The ventilation channels keep my head cool on warm evening rides too. Great for year-round commuting.', '2024-05-18'),

---------------------------------------------------------------------
-- TIRES
---------------------------------------------------------------------
-- HL Mountain Tire (739)
(70, 739, 5, N'Grip for days on loose terrain', N'Switched to the HL Mountain Tire and the difference on loose gravelly climbs is night and day. I am carrying speed through corners I used to have to brake for. The knob pattern clears mud quickly too. Transformed my trail riding.', '2024-08-09'),
(71, 739, 4, N'Amazing off-road but noisy on pavement', N'The HL Mountain Tire has incredible trail grip but it is painfully loud on paved roads. The ride to the trailhead sounds like a swarm of bees. Once on dirt though this tire is outstanding. Just be prepared for the road noise.', '2025-02-17'),
(72, 739, 5, N'These tires saved me on a wet descent', N'Hit an unexpected rainstorm halfway through a mountain ride. The HL Mountain Tires gripped wet rocks and muddy switchbacks like they were dry. Other riders were walking but I rode everything. These tires handle wet conditions brilliantly.', '2024-11-02'),

-- ML Mountain Tire (741)
(73, 741, 4, N'Good wet weather traction', N'The ML Mountain Tire holds its grip well on wet roots and muddy climbs that used to send me sliding. The compound stays pliable in cool damp conditions. Reasonable rolling resistance on pavement for the ride to the trailhead too.', '2024-04-19'),
(74, 741, 2, N'Sidewall punctured within a month', N'The ML Mountain Tire has decent tread grip but the sidewalls are paper thin. Hit one moderately sharp rock and got a gash that no patch could fix. For the price the sidewall protection should be much better.', '2024-11-06'),

-- LL Mountain Tire (743)
(75, 743, 3, N'Okay in winter but slips on ice', N'The LL Mountain Tire is serviceable on cold hard-packed trails but struggles on icy patches. If you ride where temperatures frequently drop below freezing you will want something with more aggressive siping. Fine for dry winter days though.', '2025-02-20'),
(76, 743, 2, N'Wore out in under 500 miles', N'The LL Mountain Tire compound is soft enough for decent grip but it wears out incredibly fast. I got maybe 400 miles before the knobs were visibly rounded. At this wear rate it is actually not a budget tire at all.', '2025-04-06'),

-- HL Road Tire (734)
(77, 734, 4, N'Confidence in wet corners', N'The HL Road Tire channels water effectively and I have not had a single slip on wet pavement this autumn. The grip in rain-soaked roundabouts is remarkable. They do wear faster than budget tires but safety in the rain is worth the trade-off.', '2025-02-14'),
(78, 734, 5, N'Extraordinary tire life and puncture resistance', N'Got 4,500 miles out of a pair of HL Road Tires with only moderate wear showing. The compound resists cuts and the casing has survived glass and gravel that would have ended lesser tires. Premium durability and puncture protection at a fair price.', '2024-06-09'),
(79, 734, 5, N'Best all-weather road tire I have used', N'The HL Road Tire performs equally well in rain, heat, and cold. The compound stays grippy across a wide temperature range and the tread pattern sheds water without sacrificing rolling speed. My go-to tire for year-round commuting.', '2024-10-20'),

-- ML Road Tire (736)
(80, 736, 3, N'Fair tire for the money', N'The ML Road Tire is a reasonable choice if you are not racing. Grip is adequate, wear rate is acceptable, and the price lets me replace them frequently without guilt. Not exciting but sensible and reliable.', '2025-01-22'),

-- LL Road Tire (738)
(81, 738, 4, N'Forgiving road tire for new cyclists', N'As a beginner I wanted tires that grip well even when braking hard in corners. The LL Road Tire has a generous contact patch and I have felt secure even on sandy pavement. They are heavier than racing tires but that is fine for building confidence.', '2024-10-03'),
(82, 738, 2, N'Puncture magnet', N'The LL Road Tire seems to attract every piece of glass and thorn on the road. I was patching or replacing tubes nearly every week until I switched to a tire with better puncture protection. Not worth the frustration.', '2025-04-08'),

-- Touring Tire (921)
(83, 921, 4, N'Durable long-distance touring tire', N'Put 2,800 miles of loaded touring on these tires before seeing any significant wear. They handled everything from smooth asphalt to packed gravel forest roads. Only had one flat in all those miles which is remarkable for a touring tire.', '2024-11-22'),
(84, 921, 5, N'Puncture resistant and long lasting', N'Over 3,000 miles of loaded touring with only one flat. The reinforced casing shrugs off gravel and road debris. These tires just keep going. The best investment for any long-distance rider who does not want to deal with constant punctures.', '2025-03-10'),

---------------------------------------------------------------------
-- TUBES
---------------------------------------------------------------------
(85, 922, 4, N'Reliable mountain tube', N'Carried the Mountain Tire Tube as a spare for six months before finally needing it. When I did get a flat on a rocky descent the swap was fast and the tube held air perfectly. No complaints — it does its job well.', '2025-01-05'),
(86, 922, 3, N'Valve stem leaked on two out of three', N'Bought three Mountain Tire Tubes and two of them had slow leaks at the valve stem. Fine once I found ones without the defect but the quality control could be better for something this simple.', '2025-04-15'),
(87, 923, 3, N'Does the job but nothing special', N'The Road Tire Tube holds air adequately but loses a few PSI overnight requiring a top-up before each ride. Heavier than premium tubes but far more durable. Acceptable for everyday training and commuting.', '2025-03-12'),
(88, 924, 3, N'Functional touring spare tube', N'The Touring Tire Tube holds air reliably and fits touring tires without pinching. Nothing glamorous but when carrying gear and needing a backup tube you want something you can trust. Packs flat in a pannier pocket.', '2025-03-01'),

---------------------------------------------------------------------
-- PEDALS
---------------------------------------------------------------------
-- HL Mountain Pedal (936)
(89, 936, 4, N'Platform pedals done right', N'The HL Mountain Pedals have the grip and durability you would expect at this price. The pins dig into shoes on rough descents and the sealed bearings have survived a full season of wet muddy conditions. Highly recommend for trail riding.', '2024-10-14'),
(90, 936, 4, N'Pedal upgrade that transformed my ride', N'Swapped department-store pedals for the HL Mountain Pedals and immediately noticed better foot stability and power transfer. The difference a quality pedal makes is hard to overstate. A worthwhile upgrade at any level.', '2024-11-27'),
(91, 936, 2, N'Grip pins fell out after a few rides', N'Three of the grip pins fell out of the HL Mountain Pedals within the first two weeks. Without the pins traction on the platform is mediocre. I had to buy replacement pins and threadlock them in myself. Disappointing quality control.', '2025-03-18'),

-- ML Mountain Pedal (937)
(92, 937, 3, N'Decent pedal but cramped platform', N'The ML Mountain Pedal works fine mechanically but the platform is a bit narrow for larger feet. Feet overhang the edges on longer rides causing hot spots. Riders with smaller feet will probably love them.', '2024-09-08'),

-- LL Mountain Pedal (938)
(93, 938, 3, N'Budget pedal for light use', N'The LL Mountain Pedal gets the job done on casual rides but bearing play developed after about six months. Fine for recreational riders who are not putting in huge mileage but serious riders should invest in the HL version for durability.', '2025-02-25'),

-- HL Road Pedal (939)
(94, 939, 4, N'Stiff and responsive road pedals', N'The HL Road Pedals have a satisfying clip-in engagement and the wide platform distributes pressure evenly during hard efforts. Noticed better power transfer on threshold intervals. Only minor complaint is they are a bit heavy.', '2024-07-23'),

-- LL Road Pedal (941)
(95, 941, 4, N'Affordable clipless pedal upgrade', N'The LL Road Pedal proves you do not need to spend a fortune on clipless pedals. They engage and release reliably the float is adequate and they have survived a season of use without play. Best upgrade under 50 dollars.', '2024-07-11'),
(96, 941, 1, N'Release mechanism stuck and caused a fall', N'The LL Road Pedal release mechanism seized up on one side and I could not unclip at a stop. Tipped over at an intersection. After cleaning and lubrication it works again but losing trust in your pedals is not acceptable. Check them frequently.', '2025-04-20'),

---------------------------------------------------------------------
-- LIGHTS
---------------------------------------------------------------------
-- Taillight (888)
(97, 888, 5, N'Essential for commuter visibility', N'I mounted this taillight on my seatpost and it is visible from over 300 feet away. Two drivers have told me they spotted me easily in early morning fog. The rechargeable battery lasts an entire work week without charging. A must-have for safety.', '2024-06-10'),
(98, 888, 4, N'Bright and reliable tail light', N'The flashing mode on this taillight is extremely attention-grabbing. I ride home through a poorly lit area and feel much safer with this beacon on my bike. Battery could last a bit longer on the brightest setting though.', '2024-08-11'),
(99, 888, 2, N'Mounting bracket cracked in cold weather', N'The taillight itself is bright and visible but the plastic mounting bracket snapped during a cold snap below 20 degrees. The bracket material becomes brittle in winter. Had to zip-tie it to my seatpost instead. Needs a metal bracket option.', '2025-01-10'),

-- Headlight dual-beam (889)
(100, 889, 5, N'Game changer for predawn rides', N'My shift starts at 5 AM so I ride in pitch darkness six months out of the year. These dual-beam headlights illuminate the entire bike path and I can switch between wide flood and focused beam. No more guessing where potholes are. Incredible for dark commuting.', '2024-08-03'),
(101, 889, 5, N'Lights up the darkest rural roads', N'These dual-beam headlights turned sketchy nighttime rural rides into enjoyable experiences. The high beam reaches far enough to spot road hazards at 20 mph and the low beam does not blind oncoming cyclists. Superb engineering for night riding.', '2025-01-06'),
(102, 889, 3, N'Charging port cover loosens over time', N'The headlights are very bright and the dual beam is great. But the rubber charging port cover gets looser over time and eventually fell off. Now the port is exposed to rain. The light still works but I worry about water getting in.', '2025-04-01'),

-- Weatherproof headlight (890)
(103, 890, 5, N'Survives any weather condition', N'The weatherproof headlights survived a month of rain and still blast 800 lumens down the path. The wide beam pattern lights up the edges of the trail where animals tend to appear. Essential safety equipment for all-weather riding.', '2024-03-05'),
(104, 890, 5, N'Survived a torrential downpour', N'Got caught in a torrential downpour on a 50-mile ride and these weatherproof headlights never flickered. The seals kept every drop of water out. Other lights I have owned would have failed in the first ten minutes of that storm.', '2024-09-29'),
(105, 890, 3, N'Battery indicator is wildly inaccurate', N'The light itself is great — bright, waterproof, good beam pattern. But the battery indicator jumps from three bars to dead without warning. I have been left in the dark twice because it showed plenty of charge then suddenly cut out.', '2025-03-14'),

---------------------------------------------------------------------
-- FENDERS
---------------------------------------------------------------------
(106, 876, 5, N'Indispensable for rainy-weather commuting', N'Living in a rainy climate means riding in rain eight months a year. These mountain fenders keep the rooster tail off my back and the spray out of my face. They have survived two seasons of daily use without cracking or loosening. Essential for wet commuting.', '2024-02-08'),
(107, 876, 4, N'Must-have for year-round commuters', N'These fenders keep road spray off my work clothes. Installation was straightforward with basic tools and the coverage is generous enough that my shoes stay dry. Fit the Mountain-500 frame perfectly with no rubbing.', '2024-11-05'),
(108, 876, 2, N'Rattles and buzzes on every bump', N'The mountain fenders work well at keeping water off but they rattle and vibrate on every bump. The mounting hardware loosens constantly. I retighten every few rides and it still buzzes. Functional but annoying on rough roads.', '2025-04-02'),

---------------------------------------------------------------------
-- WATER BOTTLES AND BOTTLE CAGES
---------------------------------------------------------------------
(109, 870, 5, N'Stays cold for hours on long rides', N'We do 3-hour family rides along the river trail every weekend and this water bottle still has cold water at the end. The wide mouth makes it easy to add ice cubes and the 30 oz capacity means fewer refill stops.', '2024-06-28'),
(110, 870, 5, N'Perfect family hydration solution', N'Bought four of these 30 oz water bottles — one for each family member. They fit standard cages and the wide mouth makes adding ice easy. The volume means fewer stops during our weekend rides. Great value.', '2024-04-15'),
(111, 870, 3, N'Cap leaks when squeezed while riding', N'The water bottle cap does not seal tightly. When squeezing the bottle to drink while riding water drips down the side and onto my frame. Not a huge deal but a properly sealing cap should be expected at any price point.', '2025-02-05'),
(112, 872, 4, N'Rugged mountain bottle cage', N'The Mountain Bottle Cage holds my oversized insulated bottle securely on the roughest trails. Other cages ejected my bottle on bumps — this one has a tighter grip without making extraction difficult. Simple product executed well.', '2024-07-16'),
(113, 872, 5, N'Virtually indestructible', N'The Mountain Bottle Cage has been on my bike through three seasons of trail debris impacts and general hard use. It is scratched but fully functional. Other cages I have owned snapped in half under similar treatment. Buy-it-for-life quality.', '2025-04-22'),
(114, 871, 5, N'Featherweight and functional road cage', N'The Road Bottle Cage weighs almost nothing and holds my bottle firmly even on cobblestone streets. The finish matches my Road-250 frame beautifully. After 3,000 miles the cage has not loosened or cracked.', '2024-09-28'),

---------------------------------------------------------------------
-- PANNIERS
---------------------------------------------------------------------
(115, 886, 5, N'Best touring panniers available', N'Loaded the Touring Panniers with 30 pounds of camping gear for a week-long ride. The roll-top closure sealed out a surprise thunderstorm and the internal organizer pockets kept small items accessible. The mounting hardware is rock solid.', '2024-04-01'),
(116, 886, 5, N'Waterproof and well organized', N'These large touring panniers carried everything I needed for a 10-day trip through the mountains. The waterproof lining kept my sleeping bag dry through two days of rain and the quick-release mounting system made hotel stops hassle-free. Indispensable for touring.', '2024-07-04'),
(117, 886, 3, N'Shoulder strap attachment point tore', N'The panniers are great on the bike but the shoulder strap attachment point ripped out the first time I carried one as a bag off the bike. The main body is tough but this stitching detail was clearly an afterthought. Frustrating design flaw.', '2025-03-22'),

---------------------------------------------------------------------
-- CLOTHING AND GLOVES
---------------------------------------------------------------------
-- AWC Logo Cap (712)
(118, 712, 5, N'Great casual cycling cap', N'Bought the AWC Logo Cap for weekend group rides. It fits perfectly under a helmet and wicks sweat away from my eyes on hot summer days. The quality is outstanding — no fading after dozens of washes.', '2024-10-02'),

-- Long-Sleeve Logo Jersey (713, 714, 715)
(119, 713, 5, N'Perfect base layer for cold rides', N'The Long-Sleeve Logo Jersey works brilliantly as a base layer under a winter jacket. The moisture-wicking fabric keeps sweat from chilling me during rest stops on cold rides. I have worn it in 20 degree weather and stayed completely dry underneath.', '2024-12-15'),
(120, 714, 4, N'Jersey that endures hundreds of washes', N'The Long-Sleeve Logo Jersey has been through over a hundred wash cycles and the colors have not faded. The stitching is intact the zipper works perfectly and the fabric has not pilled. This is how cycling apparel should be made. Great durability.', '2024-12-20'),
(121, 715, 5, N'Matching jerseys for the whole family', N'Ordered the Long-Sleeve Logo Jersey in different sizes for the whole family. We look like a proper team on our Sunday rides through the countryside. The quality is consistent across all sizes and the fit runs true.', '2025-04-05'),

-- Classic Vest (864)
(122, 864, 4, N'Versatile layer for cool weather', N'The Classic Vest blocks wind on the chest while letting heat escape through the back on hard efforts. It is the perfect piece for those 40-50 degree days when a full jacket is too much but short sleeves are not enough. Essential for transitional weather.', '2025-01-28'),
(123, 864, 2, N'Zipper jammed on third wear', N'The Classic Vest fabric and fit are great but the zipper jammed completely on just the third time wearing it. Could not get it up or down without forcing it. For the price the zipper quality is unacceptable.', '2025-04-09'),

-- Full-Finger Gloves L (861)
(124, 861, 5, N'Warm hands well below freezing', N'Rode through an entire winter with the Full-Finger Gloves and never had cold fingers even at minus 5 degrees with wind chill. The fleece lining is cozy without being bulky and I can still operate my brake levers precisely. Essential cold weather gear.', '2024-01-12'),
(125, 861, 4, N'Good down to about 20 degrees', N'The Full-Finger Gloves kept me warm on rides down to about 20 degrees. Below that I needed heavier gloves but for the vast majority of winter commuting days these are ideal. The fleece lining dries quickly between rides too.', '2024-11-18'),
(126, 861, 2, N'Fingertip seams cause blisters on long rides', N'The Full-Finger Gloves are warm but the interior seams across the fingertips create friction points. After a two-hour winter ride I had blisters on two fingertips. The insulation is good but the internal construction needs refinement.', '2025-03-05'),

-- Full-Finger Gloves M (862)
(127, 862, 4, N'Good winter commuting glove', N'These Full-Finger Gloves kept me comfortable on rides down to about 25 degrees. Below that I needed heavier gloves but for typical winter commuting they are ideal. The silicone grip patches really help on cold sweaty handlebars.', '2024-02-25'),

-- Half-Finger Gloves S (858)
(128, 858, 4, N'Padding in all the right spots', N'The Half-Finger Gloves have padding in exactly the right spots to prevent nerve compression on long rides. After a century ride my hands felt fine — no numbness or tingling. The fit is snug without being restrictive. Great for warm weather.', '2024-11-14'),

-- Half-Finger Gloves L (860)
(129, 860, 4, N'Gloves that actually fit smaller hands', N'Finding cycling gloves for small hands is frustrating — most small sizes are still huge. The Half-Finger Gloves fit my medium-small hands perfectly. The padding aligns with my palm and the closure cinches tight. Finally.', '2025-01-15'),
(130, 860, 1, N'Padding fell apart after three rides', N'The Half-Finger Gloves padding started disintegrating after just three rides. Gel pieces shifted inside the palm and created lumps that made riding uncomfortable. Returned them for a refund. Worst durability I have experienced in cycling gloves.', '2025-04-25'),

---------------------------------------------------------------------
-- MAINTENANCE AND REPAIR
---------------------------------------------------------------------
-- Bike Wash Dissolver (879)
(131, 879, 5, N'Bike cleaning made effortless', N'One bottle of Bike Wash Dissolver has lasted me four months of weekly cleanings. It dissolves chain grease, removes brake dust, and leaves the frame looking showroom fresh. Just spray wait and rinse. Essential for regular bike maintenance at home.', '2024-03-22'),
(132, 879, 4, N'Cuts through mud and grime easily', N'After muddy rides I spray the Bike Wash on the frame and drivetrain wait five minutes and hose it off. Cuts through caked mud and road grime without scrubbing. It has saved me hours of cleaning time. Makes post-ride maintenance quick and painless.', '2024-07-07'),

-- Bike Stand (881)
(133, 881, 5, N'Workshop essential for home mechanics', N'This bike stand makes every maintenance task ten times easier. Chain cleaning, brake adjustment, derailleur indexing — all done comfortably at waist height. The clamp rotates 360 degrees without slipping. Worth every penny for anyone who maintains their own bike.', '2024-10-30'),
(134, 881, 5, N'Buy-it-for-life quality', N'Bought this stand four years ago for home maintenance and it is still as solid as day one. The clamp mechanism has not lost tension the tripod legs remain stable and the finish has not chipped. True lasting quality.', '2024-09-01'),
(135, 881, 2, N'Tripod legs slip on smooth floors', N'The bike stand works great on rough concrete garage floors but on smooth tile or hardwood the rubber feet slide when I apply torque to a stuck bolt. Nearly knocked my bike over twice. Needs grippier feet or a wider base for indoor use.', '2025-03-30'),

-- Patch Kit (925)
(136, 925, 4, N'Saved me 30 miles from anywhere', N'The patch kit fixed a sidewall puncture 30 miles from the nearest bike shop and held for the rest of my 80-mile ride. The included tire levers are surprisingly sturdy. Every cyclist should carry one of these.', '2024-06-05'),
(137, 925, 3, N'Patches work but glue dries out in storage', N'The patch kit patches stick well when the glue is fresh but the glue tube dried out sitting in my saddle bag after about three months. When I needed it on the road it was useless. Wish they used self-adhesive patches instead.', '2025-02-22'),

-- Mountain Pump (926)
(138, 926, 4, N'Reliable trailside inflation', N'The Mountain Pump got me from flat to rideable pressure in about 90 strokes. Not the fastest pump but the build quality is excellent and it is compact enough to mount on the frame. The pressure gauge is a helpful addition for hitting the right PSI.', '2024-08-17'),

-- Minipump (887)
(139, 887, 4, N'Compact and surprisingly effective', N'The Minipump is small enough to carry in a jersey pocket and can actually generate enough pressure to re-inflate mountain bike tires. Great for self-sufficiency on the trail. Smart design for emergency roadside repairs.', '2025-02-16'),
(140, 887, 2, N'Hose connection leaks air on Presta valves', N'The Minipump hose connection does not seal properly on Presta valves. Every stroke half the air leaks out around the fitting. Took forever to get even minimal pressure. Works fine on Schrader valves though. Frustrating for road bikes.', '2025-04-12');
GO
