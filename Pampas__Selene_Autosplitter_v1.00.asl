/* 
Pampas & Selene Autosplitter v1.03
Created by NickRPGreen
Thanks to unepicfran and Jacklifear for their support, and Plywood_ for testing and reporting

Changes:
- Altered the split for defeating bosses so it splits upon the death of the boss, rather than the player being booted back to the dungeon entrance
    - This change has been made as once you've collected the heart, it's faster to teleport out of the dungeon than wait for the game
- Added in a Boss Defeated tracker so that you won't double split if you defeat a boss and die before you next save the game
*/

state("maze"){
}

startup{
    vars.U = new ExpandoObject();           // Container for variables not desired in the ASL VAR Viewer
    var u = vars.U;                         // Quick-access to container

    u.Log = (Action<string>)(x => print("Pampas & Selene Autosplitter - " + x.ToString()));     // Action to print to log
    
    // List of realm names in the order they appear in memory, plus a tracker than each realm is added to upon first visiting it
    u.realmNames = new List<string>(){"Castle","Cyclops","Arachne","Moax","Nephele","Skorpios","Python","Drakos","Gorgon","Kraken","Pyros","Lich"};
    u.realmTracker = new List<string>(){};
    
    u.roomsVisited = new List<int>(){};     // Adds each visited room to track 100% completion
    u.bossRooms = new List<int>(){0,435,259,294,279,313,333,339,372,398,416,432};   // List of room numbers that each boss appears in
    u.visitBoss = new List<string>(){};     // Tracker that adds each boss room number upon first visiting it
    u.bossDefeated = new List<int>(){};     // Tracker that adds each boss upon defeating it
    u.maxRunes = 0;    // Total number of runes collected that persists between saves
    
    u.godNames = new List<string>(){"Apollo","Hades","Uranus","Hecate","Asclepius","Ares","Zeus","Athena"};
    
    u.itemNames = new List<string>(){"Antidote","Pandora's Box","Seashell","Halo","Soul Gem","Candle","Grip Gloves","Hecate's Sceptre","Armor","Wings","Apollo's Bow","Mace","Spiked Helm","Magic Necklace","Lantern","Castle Key","Kharon's Coin","Portal","Robe","Piggy Bank","Amphora","Magic Ring","Ares' Sword","Mask","Prisoner Ball","Polymorph","Umbrella","Fireball","Golden Shield","Magic Tome","Winged Sandals","Hermes' Boots","Magic Earrings","Orb","Sea Crown","Mine","Magic Armlet","Uranus' Horn","Hades' Vengeance","Apollo's Scaled Quiver","Bucket","Wrath of Zeus"};
    u.itemsFromQuests = new List<string>(){"Antidote","Apollo's Bow","Ares Sword","Wings","Kharon's Coin","Orb","Magic Necklace","Uranus' Horn","Winged Sandals","Hecate's Sceptre","Magic Earrings","Hades' Vengeance"};
    u.itemsForQuests = new List<string>(){"Bucket, Castle Key"};
    u.itemsFound = new List<string>(){};
    u.maxItems = 0;
    u.maxSecrets = 0;

    settings.Add("behaviour", true, "Autosplitter Behavior");
    settings.Add("lastRune", false, "Last Rune Collection Only", "behaviour");
    settings.SetToolTip("lastRune", "If unchecked, will split on collecting every Rune in each Realm");
    settings.Add("doubleItemReceipt", true, "Avoid double splitting for items aquired from quests", "behaviour");
    settings.SetToolTip("doubleItemReceipt", "If using both Quest Splits and Item Splits, prevents double splitting on items obtained from quest completion");

    settings.Add("finalSplit", true, "Game Complete");
    settings.SetToolTip("finalSplit", "Splits when the in-game timer stops after the final Lich puzzle");

    settings.Add("questProgress", true, "Quest Progression");
    settings.SetToolTip("questProgress", "Splits at the end of a God's dialogue after a quest has been completed, or upon collecting the final pickup for an active quest");

    settings.Add("visitRealm", true, "Realm Entry");
    settings.SetToolTip("visitRealm", "Splits upon first entering a new realm");
    settings.Add("findRune", true, "Rune Collection");
    settings.SetToolTip("findRune", "Splits upon collecting any rune. If 'Last Rune Collection' is enabled, only splits on collecting the 8th rune in each realm");
    settings.Add("visitBoss", true, "Reach Boss");
    settings.SetToolTip("visitBoss", "Splits upon reaching a boss room for the first time, but only if you have that realm's 8 runes");
    settings.Add("defeatBoss", true, "Defeat Boss");
    settings.SetToolTip("defeatBoss", "Splits after teleporting back to the castle after a boss is defeated. Splits when Lich's health reaches 0");
    settings.Add("findItem", false, "Item Collection");
    settings.SetToolTip("findItem", "Splits upon collecting an item. Can cause double splits if the options in 'Autosplitter Behaviour' are not checked");
    settings.Add("secrets", false, "Secret Collection");
    settings.SetToolTip("secrets", "Splits upon opening a secret chest");
    settings.Add("achievement", false, "Achievements");
    settings.SetToolTip("achievement", "Splits upon completing an achievement for the first time ever. Will not split if an achievement is ever repeated");

    for(int i = 0; i < u.godNames.Count; i++) settings.Add("quest"+u.godNames[i], true, u.godNames[i], "questProgress");
    
    u.questTracker = new Dictionary<string, List<int>>(){};
    u.questItemTracker = new Dictionary<string, List<int>>(){};
    u.questLines = new Dictionary<string, List<string>>(){
        {"Apollo", new List<string> {"Meet Apollo","Collect Broken Bow","Return Broken Bow","Collect 4 Strings","Receive Apollo's Bow","Kill 16 Bats","Return Bat Blood","Defeat 4 Demons (Apollo)","Collect 8 Dark Scales","Receive Apollo's Scaled Quiver"}},
        {"Hades", new List<string> {"Meet Hades","Kill 6 Boars","Return Boar Blood","Explode 12 Golems","Return Golem Rocks","Receive Hades' Vengeance"}},
        {"Uranus", new List<string> {"Meet Uranus","Collect Feathers","Return Feathers","Collect 4 Beeswax","Receive Wings","Recieve Uranus' Horn","Retrieve Uranus' Chest","Receive Winged Sandals"}},
        {"Hecate", new List<string> {"Meet Hecate","Collect Crystal Ball","Return Crystal Ball","Collect Fire Essence","Upgrade to Fireball","Kill 16 Slimes","Return Slimes","Collect 8 Magic Essence","Return Magic Essence","Learn to Fly","Collect empty Orb","Receive Orb","Defeat 4 Demons (Hecate)","Collect Scepter","Return Scepter","Collect 8 Worm Magic Essence","Receive Hecate's Sceptre","Defeat 7 Demons (Hecate)","Collect Witch's Magic Essence","Receive Magic Earrings"}},
        {"Asclepius", new List<string> {"Meet Asclepius","Collect 8 Scorpion Poison","Return Scorpion Poison","Collect 8 Plants","Receive Antidote","Collect Bucket","Return Bucket","Defeat 3 Demons (Asclepius)","Collect 4 Shiny Pearls","Receieve Magic Necklace"}},
        {"Ares", new List<string> {"Meet Ares","Kill Werewolf with Sword","Receive Mace","Collect 8 Steel","Return Steel","Collect Anvil","Receieve Armor","Collect Ares Sword","Receive Ares Sword"}},
        {"Zeus", new List<string> {"Meet Zeus","Remove the Tower Flags","Receive Wrath of Zeus"}},
        {"Athena", new List<string> {"Meet Athena","Locate Apollo and Hecate","Collect Castle Key","Show Castle Key to Athena","Show Wings to Athena","Receive Kharon's Coin","Locate Hades","Defeat 6 Demons (Athena)","Show Winged Boots to Athena","Defeat 7 Demons (Athena)","Show Magic Earrings to Athena","Show Hades' Vengeance to Athena)"}},
    };

    for(int i = 0; i < u.godNames.Count; i++){
        for(int j = 0; j < u.questLines[u.godNames[i]].Count; j++){
            var qL = u.questLines[u.godNames[i]][j];
            settings.Add("quest"+qL, true, qL, "quest"+u.godNames[i]);
        }
    };
    
    for(int i = 1; i < u.realmNames.Count-1; i++) settings.Add("enter"+u.realmNames[i], true, u.realmNames[i], "visitRealm");
    for(int i = 1; i < u.realmNames.Count-1; i++) settings.Add("runes"+u.realmNames[i], true, u.realmNames[i], "findRune");
    for(int i = 1; i < u.realmNames.Count; i++) settings.Add("visit"+u.realmNames[i], true, u.realmNames[i], "visitBoss");
    for(int i = 1; i < u.realmNames.Count; i++) settings.Add("defeat"+u.realmNames[i], true, u.realmNames[i], "defeatBoss");

    for(int i = 0; i < u.itemNames.Count; i++){
        settings.Add("find"+u.itemNames[i], true, u.itemNames[i], "findItem");
    };

    u.achievementNames = new List<string>(){"Heroic Cyclops Slayer","Heroic Arachne Slayer","Heroic Moax Slayer","Heroic Nephele Slayer","Heroic Skorpios Slayer","Heroic Python Slayer","Heroic Drakos Slayer","Heroic Gorgon Slayer","Heroic Kraken Slayer","Heroic Pyros Slayer","Perfect Lich Slayer","Eye for An Eye EX","Free Fall EX","Setec Astronomy EX","A Good Start EX","Sudden Death EX","Floating Death EX","Cyclops Slayer","Arachne Slayer","Moax Slayer","Nephele Slayer","Skorpios Slayer","Python Slayer","Drakos Slayer","Gorgon Slayer","Kraken Slayer","Pyros Slayer","Lich Slayer","Eye for An Eye","Free Fall","Setec Astronomy","A Good Start","Sudden Death","Floating Death","Overheat","Old Ending","New Ending","The Archer","The Sorceress","Rune Master","Coup De Grace","Forget-Me-Not","The Collector","As You Wish","Heroes Never Die","You Nearly Got it","Your Own Worst Enemy","Is That Thing On?","Prisoner of War","Music For My Ears","Perfect!","Feathers and Armors","The Great Escape","Fishing","The Floor Is Lava","Sword Master","Wand Master","Pacifist","Ladder Killer","Bone Breaker","Growing Up Together","Ghost 2.0","An Apple A Day","Karma","Rusty Armor","Well Prepared","Marksmanship","Grand Master"};
    for(int i = 0; i < u.achievementNames.Count; i++) settings.Add(u.achievementNames[i], false, u.achievementNames[i], "achievement");

    u.soulNames = new List<string>(){"Empty","Axe Boomerang","Twin Bone","Dual Knife","Skyward Blast","Bubbles","Ghost Assassin","Bat Swarm","Fist Punch","Magic Wave","Bouncing Bomb","Conjure Apples","Ring Blast","Sentry Shooter","Slow Time","Scorpion Slash","Boar Rush","Waterwalk","Downward Thrust","Bee Sting","Drop Below","Lightning Wall","Spike Shield","Worms Armageddeon","Turn Undead","Speed Boost","Rising Volley","Invulnerability","Fire Protection","Mushroom Mines","Drain Life","Soul Mastery","Prancing Pinwheel","Back Cannon","Descending Eye","Earthquake","Rapid Sword","Conjure Mana","Wave Attack","Absorb Bullets","Grip"};

    u.castleRooms = new Dictionary<int, string>(){
                                                                                                                                                 { 15,"5,-13"},
                                                                                                                                   { 26,"4,-12"},{ 10,"5,-12"},{ 28,"6,-12"},
                                                                                                                     { 14,"3,-11"},{  9,"4,-11"},{255,"5,-11"},{  8,"6,-11"},{ 12,"7,-11"},
                                                                                                                                   { 16,"4,-10"},{  7,"5,-10"},{ 19,"6,-10"},
                                                                                                                     {180, "3,-9"},{ 20, "4,-9"},{  6, "5,-9"},{ 17, "6,-9"},{181, "7,-9"},
                                                                                                                                   {  5, "4,-8"},              {  4, "6,-8"},
                                                                                                                                   { 18, "4,-7"},              { 21, "6,-7"},             { 29,"8,-7"},{ 24,"9,-7"},                                                                                           {216,"17,-7"},{223,"18,-7"},{220,"19,-7"},{221,"20,-7"},{218,"21,-7"},             
                                                                                           { 47,"1,-6"},{ 44,"2,-6"},              {  1, "4,-6"},{  3, "5,-6"},{ 41, "6,-6"},             { 25,"8,-6"},{ 33,"9,-6"},                                                                                           {212,"17,-6"},{213,"18,-6"},{214,"19,-6"},{215,"20,-6"},{211,"21,-6"},
                                                                                           {146,"1,-5"},{ 53,"2,-5"},              {178, "4,-5"},{251, "5,-7"},{179, "6,-5"},{ 22,"7,-5"},{ 34,"8,-5"},{ 35,"9,-5"},                                                                                           {209,"17,-5"},{217,"18,-5"},{210,"19,-5"},{222,"20,-5"},{ 43,"21,-5"},
                                                                                           { 55,"1,-4"},{ 51,"2,-4"},{ 23, "3,-4"},{177, "4,-4"},{176, "5,-4"},{175, "6,-4"},             {143,"8,-4"},{ 36,"9,-4"},                                                                                                         {206,"18,-4"},{207,"19,-4"},{208,"20,-4"},
                                                                                           {145,"1,-3"},{ 42,"2,-3"},              {172, "4,-3"},{173, "5,-3"},{174, "6,-3"},{ 39,"7,-3"},{ 38,"8,-3"},                                                                                                                      {204,"18,-3"},{ 46,"19,-3"},{205,"20,-3"},
                                                                                                        { 58,"2,-2"},{ 56, "3,-2"},{170, "4,-2"},{240, "5,-2"},{171, "6,-2"},                                                                                                                                                {202,"18,-2"},{ 48,"19,-2"},{203,"20,-2"},
                                                                                                                                   {168, "4,-1"},              {166, "6,-1"},                                                                                                                                                {199,"18,-1"},{200,"19,-1"},{201,"20,-1"},
        {110, "-5,0"},{126, "-4,0"},{127, "-3,0"},{128, "-2,0"},{ 73, "-1,0"},                                                     {163,  "3,0"},{164,  "4,0"},{165,  "5,0"},{169, "6,0"},{167, "7,0"},                                       {219,"11,0"},{ 86,"12,0"},{ 87,"13,0"},{ 88,"14,0"},{ 45,"15,0"},              {124, "18,0"},              {129, "20,0"},
        {446, "-5,1"},{125, "-4,1"},              {123, "-2,1"},{450, "-1,1"},{109, "0,1"},{ 67, "1,1"},{147, "2,1"},              {160,  "4,1"},              {162,  "6,1"},             {158, "8,1"},{157, "9,1"},{156,"10,1"},{448,"11,1"},{ 84,"12,1"},             { 89,"14,1"},{ 70,"15,1"},                           { 49, "18,1"},{252, "19,1"},{ 66, "20,1"},
        {445, "-5,2"},{120, "-4,2"},{ 65, "-3,2"},{ 64, "-2,2"},{451, "-1,2"},{  2, "0,2"},{243, "1,2"},{ 61, "2,2"},{148,  "3,2"},{ 37,  "4,2"},{161,  "5,2"},{ 57,  "6,2"},{ 60,"7, 2"},{159, "8,2"},{236, "9,2"},{155,"10,2"},{447,"11,2"},{ 85,"12,2"},{ 97,"13,2"},{ 90,"14,2"},{460,"15,2"},{ 31,"16,2"},{ 30, "17,2"},{ 27, "18,2"},{189, "19,2"},{198, "20,2"},{197,"21,2"},{196,"22,2"},
        {234, "-5,3"},{121, "-4,3"},{ 68, "-3,3"},{ 69, "-2,3"},{ 80, "-1,3"},{ 71, "0,3"},{ 72, "1,3"},{154, "2,3"},{ 74,  "3,3"},{ 75,  "4,3"},{ 76,  "5,3"},{ 77,  "6,3"},{ 78,"7, 3"},{ 81, "8,3"},{ 92, "9,3"},{ 94,"10,3"},{ 79,"11,3"},{ 83,"12,3"},{ 96,"13,3"},{ 91,"14,3"},{182,"15,3"},{ 32,"16,3"},{247, "17,3"},{187, "18,3"},{188, "19,3"},{190, "20,3"},{246,"21,3"},{195,"22,3"},{248,"23,3"},
                      {113, "-4,4"},              {106, "-2,4"},              {141, "0,4"},{245, "1,4"},{153, "2,4"},              {142,  "4,4"},{253,  "5,4"},{151,  "6,4"},             { 99, "8,4"},{241, "9,4"},{104,"10,4"},             { 98,"12,4"},             {103,"14,4"},             { 11,"16,4"},{242, "17,4"},{249, "18,4"},{186, "19,4"},{250, "20,4"},{226,"21,4"},{194,"22,4"},
                      {112, "-4,5"},{130, "-3,5"},{132, "-2,5"},              {134, "0,5"},{133, "1,5"},{152, "2,5"},{135,  "3,5"},{136,  "4,5"},{137,  "5,5"},{138,  "6,5"},{139,"7, 5"},{100, "8,5"},{101, "9,5"},{102,"10,5"},             { 82,"12,5"},{ 95,"13,5"},{ 93,"14,5"},             { 13,"16,5"},{183, "17,5"},{184, "18,5"},{185, "19,5"},{191, "20,5"},{192,"21,5"},{193,"22,5"},
                                    { 62, "-3,6"},                                                      {108, "2,6"},                                                                     {118, "8,6"},                                                    { 40,"13,6"},  
                                    {150, "-3,7"},                                         {116, "1,7"},{107, "2,7"},                                                                     {140, "8,7"},{119, "9,7"},                                       { 50,"13,7"},
                                                                                                        {115, "2,8"},{105,  "3,8"},{449,  "4,8"},{  0,  "5,8"},              {227, "7,8"},{117, "8,8"},
                                                                              {131, "0,9"},{111, "1,9"},{114, "2,9"},                            { 63,  "5,9"},                           {228, "8,9"},{225, "9,9"},{224,"10,9"},
                                                                                                        {122,"2,10"},                            { 54, "5,10"},                           {229,"8,10"},
                                                                                           { 52,"1,11"},{149,"2,11"},{ 59, "3,11"},{144, "4,11"},{235, "5,11"},{230, "6,11"},{231,"7,11"},{232,"8,11"},{233,"9,11"},
                                                                                                                                                 {239, "5,12"},
                                                                                                                                                 {237, "5,13"},
                                                                                                                                                 {238, "5,14"},
                                                                                                                                                 {244, "5,15"}
    };

    u.cyclopsRooms = new Dictionary<int, string>(){
                      {423,"32,-9"},{424,"33,-9"},
                                    {438,"33,-8"},
        {425,"31,-7"},{426,"32,-7"},{427,"33,-7"},{428,"34,-7"},{429,"35,-7"},
                      {431,"32,-6"},              {422,"34,-6"},
        {433,"31,-5"},{434,"32,-5"},              {436,"34,-5"},{435,"35,-5"}
    };

    u.arachneRooms = new Dictionary<int, string>(){
                                  {259,"33,-1"},
                     {262,"32,0"},{263, "33,0"},{256,"34,0"},
                     {260,"32,1"},              {261,"34,1"},
        {258,"31,2"},{257,"32,2"},{444, "33,2"},{254,"34,2"},{456,"35,2"},
                                  {443, "33,3"},
                     {441,"32,4"},{442, "33,4"},{437,"34,4"},
                                  {440, "33,5"}
    };

    u.moaxRooms = new Dictionary<int, string>(){
                     {270,"39,1"},{277,"40,1"},{294,"41,1"},
        {266,"38,2"},             {264,"40,2"},             {271,"42,2"},
        {267,"38,3"},{278,"39,3"},{280,"40,3"},{276,"41,3"},{272,"42,3"},
        {268,"38,4"},             {274,"40,4"},             {273,"42,4"},
                     {265,"39,5"},{275,"40,5"},{269,"41,5"}
    };
    
    u.nepheleRooms = new Dictionary<int, string>(){
                                    {295,"40,-11"},{299,"41,-11"},{279,"42,-11"},
                                                   {298,"41,-10"}, 
                                                   {297, "41,-9"},
                                                   {296, "41,-8"},
                      {293,"39,-7"},               {288, "41,-7"},               {282, "43,-7"},
                      {283,"39,-6"},{281, "40,-6"},{285, "41,-6"},{292, "42,-6"},{287, "43,-6"},
        {290,"38,-5"},{289,"39,-5"},               {284, "41,-5"},               {286, "43,-5"},{291, "44,-5"},
    };

    u.skorpiosRooms = new Dictionary<int, string>(){
                      {303,"33, 8"},
        {316,"32, 9"},{312,"33, 9"},
                      {311,"33,10"},              {315,"35,10"},              {317,"37,10"},
                      {310,"33,11"},{306,"34,11"},{304,"35,11"},              {308,"37,11"},{313,"38,11"},
        {301,"32,12"},{300,"33,12"},              {302,"35,12"},{305,"36,12"},{307,"37,12"},
        {314,"32,13"},                                                        {309,"37,13"},
    };

    u.pythonRooms = new Dictionary<int, string>(){
        {326,"41,10"},{321,"42,10"},{332,"43,10"},{333,"44,10"},
                      {322,"42,11"},
        {334,"41,12"},{323,"42,12"},{324,"43,12"},{319,"44,12"},{320,"45,12"},
                                                  {330,"44,13"},
        {331,"41,14"},{325,"42,14"},{328,"43,14"},{329,"44,14"},
        {335,"41,15"},{327,"42,15"}
    };

    u.drakosRooms = new Dictionary<int, string>(){
                      {342,"33,17"},              {338,"35,17"},              {339,"37,17"},
        {351,"32,18"},{337,"33,18"},{336,"34,18"},{341,"35,18"},{318,"36,18"},{340,"37,18"},{343,"38,18"},              
                      {344,"33,19"},              {347,"35,19"},              {355,"37,19"},
        {352,"32,20"},{349,"33,20"},{345,"34,20"},{346,"35,20"},{350,"36,20"},{348,"37,20"},{357,"38,20"},
                      {353,"33,21"},              {354,"35,21"},              {356,"37,21"},
    };

    u.gorgonRooms = new Dictionary<int, string>(){
        {359,"40,17"},{360,"41,17"},                                          {371,"45,17"},{372,"46,17"},
                      {358,"41,18"},{361,"42,18"},              {369,"44,18"},{370,"45,18"},
                                    {362,"42,19"},{363,"43,19"},{368,"44,19"},
                      {365,"41,20"},{364,"42,20"},              {373,"44,20"},{374,"45,20"},
        {367,"40,21"},{366,"41,21"},                                          {375,"45,21"},{376,"46,21"}
    };

    u.krakensRooms = new Dictionary<int, string>(){
                                    {390,"34,23"},              {393,"36,23"},
        {396,"32,24"},              {382,"34,24"},              {391,"36,24"},              {397,"38,24"},
        {394,"32,25"},{386,"33,25"},{384,"34,25"},{383,"35,25"},{387,"36,25"},{392,"37,25"},{395,"38,25"},
                      {385,"33,26"},              {381,"35,26"},              {388,"37,26"},
        {399,"32,27"},{377,"33,27"},{378,"34,27"},{380,"35,27"},{389,"36,27"},{379,"37,27"},{398,"38,27"}
    };

    u.pyrosRooms = new Dictionary<int, string>(){
        {401,"40,24"},{400,"41,24"},              {409,"43,24"},              {416,"45,24"},{414,"46,24"},
        {402,"40,25"},                            {408,"43,25"},                            {413,"46,25"},
        {403,"40,26"},{404,"41,26"},{406,"42,26"},{407,"43,26"},{410,"44,26"},{411,"45,26"},{412,"46,26"},
        {405,"40,27"},                            {417,"43,27"},                            {415,"46,27"},
                                                  {418,"43,28"},
                                    {420,"42,29"},{419,"43,29"},{421,"44,29"}
    };
}

init{
    var u = vars.U;
    u.Log("Running init");
    u.ready = false;
}

update{
    var u = vars.U; 
    if (!u.ready){
        u.Log("Scanning for MARK");

        var module = modules.First(x => x.ModuleName == "maze.exe");
        var scanner = new SignatureScanner(game, module.BaseAddress, module.ModuleMemorySize);
        var target = new SigScanTarget(2, "00 00 4D 41 52 4B");
        IntPtr mark = scanner.Scan(target);
        
        if (mark == IntPtr.Zero){
            u.Log("Waiting for game to initialize...");
            return false;
        }        

        u.Log("MARK found");
        u.statLst = new MemoryWatcherList(){
            // Note: in a single player game, Player [1] is the active character and Player [2] is the inactive character
            //       in a multiplayer game, Player [1] is the Left or Host player, and Player [2] is the Right or Remote player  
            
            // States
            new MemoryWatcher<float>    (mark + 0x4)     { Name = "globalTimer" },
            new MemoryWatcher<float>    (mark + 0x8)     { Name = "gameTimer" },
            new MemoryWatcher<byte>     (mark + 0xC)     { Name = "menuType" },                      // 0 = in game, 1 = main menu, 2 = paused
            new MemoryWatcher<byte>     (mark + 0x154)   { Name = "pampas" },                        // 0 = Selene selected, 1 = Pampas selected

            // Locations
            new MemoryWatcher<int>      (mark + 0x10)    { Name = "currentRoomIdx[1]" },
            new MemoryWatcher<int>      (mark + 0x14)    { Name = "currentRoomIdx[2]" },
            new MemoryWatcher<byte>     (mark + 0x18)    { Name = "world[1]" },                      // 0 = Castle, 1-10 Realms, 11 = Lich
            new MemoryWatcher<byte>     (mark + 0x19)    { Name = "world[2]" },
            new MemoryWatcher<int>      (mark + 0xE8)    { Name = "lastSavecurrentRoomIdx" },
            new MemoryWatcher<int>      (mark + 0xEC)    { Name = "lastGravecurrentRoomIdx" },

            // Ammo
            new MemoryWatcher<int>      (mark + 0xF0)    { Name = "arrowNum[1]" },
            new MemoryWatcher<int>      (mark + 0xF4)    { Name = "arrowNum[2]" },
            new MemoryWatcher<int>      (mark + 0xF8)    { Name = "manaNum[1]" },
            new MemoryWatcher<int>      (mark + 0xFC)    { Name = "manaNum[2]" },
            new MemoryWatcher<int>      (mark + 0x100)   { Name = "coinNum" },                       // Start with 5
            new MemoryWatcher<int>      (mark + 0x118)   { Name = "soul[1]" },                       
            new MemoryWatcher<int>      (mark + 0x11C)   { Name = "soul[2]" },
            new MemoryWatcher<int>      (mark + 0x120)   { Name = "soulCharge[1]" },                 // 0 = single charge Soul, or empty, 1-3 = number of charges, -1 = single charge Soul used
            new MemoryWatcher<int>      (mark + 0x124)   { Name = "soulCharge[2]" },

            // Status
            new MemoryWatcher<int>      (mark + 0x104)   { Name = "hpNum[1]" },
            new MemoryWatcher<int>      (mark + 0x108)   { Name = "hpNum[2]" },
            new MemoryWatcher<int>      (mark + 0x10C)   { Name = "expNum[1]" },
            new MemoryWatcher<int>      (mark + 0x110)   { Name = "expNum[2]" },
            new MemoryWatcher<byte>     (mark + 0x114)   { Name = "expLevel[1]" },
            new MemoryWatcher<byte>     (mark + 0x115)   { Name = "expLevel[2]" },
            new MemoryWatcher<byte>     (mark + 0x116)   { Name = "heartLevel[1]" },
            new MemoryWatcher<byte>     (mark + 0x117)   { Name = "heartLevel[2]" },
            new MemoryWatcher<byte>     (mark + 0x1A3)   { Name = "secretPerc" },
            new MemoryWatcher<byte>     (mark + 0x1A4)   { Name = "gameFinished"},
        };

        u.questLst = new MemoryWatcherList();      // Quest Progress - numbered state of each god's quest line
        for(int i = 0; i < u.godNames.Count; i++) u.questLst.Add(new MemoryWatcher<byte>(mark + 0x1A + 0x0 + (i*1)){Name = u.godNames[i]});

        u.questItemLst = new MemoryWatcherList();  // Quest Items - number of items picked up for the current quest for each god
        for(int i = 0; i < u.godNames.Count; i++) u.questItemLst.Add(new MemoryWatcher<byte>(mark + 0x22 + 0x0 + (i*1)){Name = u.godNames[i]});

        u.itemLst = new MemoryWatcherList();       // Item List - 0 = unobtained, 1 = obtained
        for(int i = 0; i < u.itemNames.Count; i++) u.itemLst.Add(new MemoryWatcher<int>(mark + 0x2C + 0x0 + (i*4)){Name = u.itemNames[i]});

        u.realmLst = new MemoryWatcherList();      // Realm List - 0 = not visited, 1 = visited
        for(int i = 1; i < u.realmNames.Count-1; i++) u.realmLst.Add(new MemoryWatcher<byte>(mark + 0xD4 + 0x0 + (i-1)){Name = u.realmNames[i]});
        
        u.bossLst = new MemoryWatcherList();       // Boss List - 0 = alive, 1 = defeated, 2 = heart picked up
        for(int i = 1; i < u.realmNames.Count-1; i++) u.bossLst.Add(new MemoryWatcher<byte>(mark + 0xDE + 0x0 + (i*1)-1){Name = u.realmNames[i]});

        u.bossHealthLst = new MemoryWatcherList(); // Boss Health - starts at 50hp (except Lich), 9999 if not spawned
        for(int i = 1; i < u.realmNames.Count; i++) u.bossHealthLst.Add(new MemoryWatcher<int>(mark + 0x128 + 0x0 + (i*4)-4){Name = u.realmNames[i]});

        u.achievementsLst = new MemoryWatcherList(); // Achievements - 0 = incomplete, 1 = complete
        for(int i = 0; i < u.achievementNames.Count; i++) u.achievementsLst.Add(new MemoryWatcher<byte>(mark + 0x155 + 0x0 + (i*1)){Name = u.achievementNames[i]});

        u.runesLst = new MemoryWatcherList();      // How many of each realm's runes have been collected
        for(int i = 1; i < u.realmNames.Count-1; i++) u.runesLst.Add(new MemoryWatcher<byte>(mark + 0x199 + 0x0 + (i*1)-1){Name = u.realmNames[i]});

        u.ready = true;
        u.Log("Splitter is ready");
    }
    
    // Memory Update
    u.statLst.UpdateAll(game);
    u.questLst.UpdateAll(game);
    u.questItemLst.UpdateAll(game);
    u.itemLst.UpdateAll(game);
    u.realmLst.UpdateAll(game);
    u.bossLst.UpdateAll(game);
    u.bossHealthLst.UpdateAll(game);
    u.runesLst.UpdateAll(game);
    u.achievementsLst.UpdateAll(game);

    if(u.statLst["menuType"].Current == 0) current.gameStatus = "In Game";
    else if(u.statLst["menuType"].Current == 2) current.gameStatus = "Paused";
    else if(u.statLst["menuType"].Current == 1) current.gameStatus = "Main Menu";
    else if(u.statLst["menuType"].Current == 3) current.gameStatus = "Game Over";

    // Both Players' Current Realms
    if(current.gameStatus == "Main Menu"){
        current.realmP1 = "Main Menu";
        current.realmP2 = "Main Menu";
    }
    else {
        current.realmP1 = u.realmNames[u.statLst["world[1]"].Current];
        current.realmP2 = u.realmNames[u.statLst["world[2]"].Current];
    }

    // Variable Checkers
    // Add Player 1's Room to roomsVisited
    if(current.realmP1 == "Castle" && u.statLst["currentRoomIdx[1]"].Changed && !u.roomsVisited.Contains(u.statLst["currentRoomIdx[1]"].Current)) u.roomsVisited.Add(u.statLst["currentRoomIdx[1]"].Current);

    // Add Player 2's Room to roomsVisited
    if(current.realmP2 == "Castle" && u.statLst["currentRoomIdx[2]"].Changed && !u.roomsVisited.Contains(u.statLst["currentRoomIdx[2]"].Current)) u.roomsVisited.Add(u.statLst["currentRoomIdx[2]"].Current);
    
    // Current Room - Player 1
    if(current.gameStatus == "Main Menu") current.roomP1 = "Main Menu";
    else if (u.castleRooms.ContainsKey(u.statLst["currentRoomIdx[1]"].Current)) current.roomP1 = u.castleRooms[u.statLst["currentRoomIdx[1]"].Current];
    else if (u.cyclopsRooms.ContainsKey(u.statLst["currentRoomIdx[1]"].Current)) current.roomP1 = u.cyclopsRooms[u.statLst["currentRoomIdx[1]"].Current];
    else if (u.arachneRooms.ContainsKey(u.statLst["currentRoomIdx[1]"].Current)) current.roomP1 = u.arachneRooms[u.statLst["currentRoomIdx[1]"].Current];
    else if (u.moaxRooms.ContainsKey(u.statLst["currentRoomIdx[1]"].Current)) current.roomP1 = u.moaxRooms[u.statLst["currentRoomIdx[1]"].Current];
    else if (u.nepheleRooms.ContainsKey(u.statLst["currentRoomIdx[1]"].Current)) current.roomP1 = u.nepheleRooms[u.statLst["currentRoomIdx[1]"].Current];
    else if (u.skorpiosRooms.ContainsKey(u.statLst["currentRoomIdx[1]"].Current)) current.roomP1 = u.skorpiosRooms[u.statLst["currentRoomIdx[1]"].Current];
    else if (u.pythonRooms.ContainsKey(u.statLst["currentRoomIdx[1]"].Current)) current.roomP1 = u.pythonRooms[u.statLst["currentRoomIdx[1]"].Current];
    else if (u.pyrosRooms.ContainsKey(u.statLst["currentRoomIdx[1]"].Current)) current.roomP1 = u.pyrosRooms[u.statLst["currentRoomIdx[1]"].Current];
    else current.roomP1 = "Room Not Found";

    // Current Room - Player 2
    if(current.gameStatus == "Main Menu") current.roomP2 = "Main Menu";
    else if (u.castleRooms.ContainsKey(u.statLst["currentRoomIdx[2]"].Current)) current.roomP2 = u.castleRooms[u.statLst["currentRoomIdx[2]"].Current];
    else if (u.cyclopsRooms.ContainsKey(u.statLst["currentRoomIdx[2]"].Current)) current.roomP2 = u.cyclopsRooms[u.statLst["currentRoomIdx[2]"].Current];
    else if (u.arachneRooms.ContainsKey(u.statLst["currentRoomIdx[2]"].Current)) current.roomP2 = u.arachneRooms[u.statLst["currentRoomIdx[2]"].Current];
    else if (u.moaxRooms.ContainsKey(u.statLst["currentRoomIdx[2]"].Current)) current.roomP2 = u.moaxRooms[u.statLst["currentRoomIdx[2]"].Current];
    else if (u.nepheleRooms.ContainsKey(u.statLst["currentRoomIdx[2]"].Current)) current.roomP2 = u.nepheleRooms[u.statLst["currentRoomIdx[2]"].Current];
    else if (u.skorpiosRooms.ContainsKey(u.statLst["currentRoomIdx[2]"].Current)) current.roomP2 = u.skorpiosRooms[u.statLst["currentRoomIdx[2]"].Current];
    else if (u.pythonRooms.ContainsKey(u.statLst["currentRoomIdx[2]"].Current)) current.roomP2 = u.pythonRooms[u.statLst["currentRoomIdx[2]"].Current];
    else if (u.pyrosRooms.ContainsKey(u.statLst["currentRoomIdx[2]"].Current)) current.roomP2 = u.pyrosRooms[u.statLst["currentRoomIdx[2]"].Current];
    else current.roomP2 = "Room Not Found";

    // Total Current Runes
    vars.runesCollected = 0;
    for(int i = 1; i < u.realmNames.Count-1; i++) vars.runesCollected = vars.runesCollected + u.runesLst[u.realmNames[i]].Current;
    
    // Total Items Collected
    vars.itemsCollected = 0;
    for(int i = 0; i < u.itemNames.Count; i++){
        var iN = u.itemNames[i];
        vars.itemsCollected = vars.itemsCollected + u.itemLst[iN].Current;
    }

    // Current Soul
    var charges = "";
    if(u.statLst["soulCharge[1]"].Current == 0) charges = "";
    else if(u.statLst["soulCharge[1]"].Current == 1) charges = " - 1 charge";
    else charges = " - " + u.statLst["soulCharge[1]"].Current + " charges";
    current.soulType = u.soulNames[u.statLst["soul[1]"].Current] + charges;

    // Percentage Complete Variables
    vars.itemsPercentage = "Items: " + (Math.Floor(((double)vars.itemsCollected/(u.itemNames.Count))*100)/100).ToString("P0");
    vars.castleRoomsFound = u.roomsVisited.Count;
    if((Math.Ceiling(((double)(u.roomsVisited.Count-2)/(u.castleRooms.Count))*100)/100) == 0) vars.castlePercentage = "Castle: 1%";
    else vars.castlePercentage = "Castle: " + (Math.Ceiling(((double)(u.roomsVisited.Count-2)/(u.castleRooms.Count))*100)/100).ToString("P0");
    vars.secretsCollected = Math.Round(u.statLst["secretPerc"].Current/2.858, 0);
    vars.secretsPercentage = "Secrets: " + u.statLst["secretPerc"].Current+"%";
    vars.completionProgress = vars.itemsPercentage + " - " + vars.castlePercentage + " - " + vars.secretsPercentage;
}

start{
    var u = vars.U;
    return u.statLst["gameTimer"].Old == 0 && u.statLst["gameTimer"].Current > 0 && u.statLst["gameTimer"].Current < 2.05 && current.gameStatus == "In Game";
}

gameTime{
    return TimeSpan.FromSeconds(vars.U.statLst["gameTimer"].Current);
}

isLoading{
    return true;
}

onStart{
    var u = vars.U;
    u.Log("BEGINNING STARTING VALUES UPDATE");

    u.roomsVisited.Clear();
    u.roomsVisited.Add(154);
    u.itemsFound.Clear();
    u.visitBoss.Clear();
    u.bossDefeated.Clear();
    u.maxRunes = vars.runesCollected;
    u.maxItems = vars.itemsCollected;
    u.maxSecrets = u.statLst["secretPerc"].Current;

    u.realmTracker.Clear();
    u.realmTracker.Add("Castle");

    // Add already visited realms to realmTracker if loading a save
    for(int i = 1; i<u.realmNames.Count-1; i++){
        if(u.realmLst[i-1].Current == 1) u.realmTracker.Add(u.realmNames[i]);
    }
    u.Log("Visited Realms: "+string.Join(",",u.realmTracker));
    
    u.questTracker.Clear();
    u.questTracker.Add("Apollo", new List<int> {3,100,4,400,5,1600,6,7,800,9,1000});
    u.questTracker.Add("Hades", new List<int> {1,600,2,1200,5,7,1000});
    u.questTracker.Add("Uranus", new List<int> {3,100,4,400,5,7,100,10,1000});
    u.questTracker.Add("Hecate", new List<int> {1,100,2,100,3,1600,4,800,5,6,100,7,9,100,10,800,11,12,100,14,1000});
    u.questTracker.Add("Asclepius", new List<int> {1,800,2,800,3,100,4,5,400,7,1000});
    u.questTracker.Add("Ares", new List<int> {2,100,3,800,4,100,6,100,8,1000});
    u.questTracker.Add("Zeus", new List<int> {2,200,4,1000});
    u.questTracker.Add("Athena", new List<int> {2,5,100,8,13,16,19,22,25,28,32,1000});
    
    // Add already collected items to itemsFound list if loading a save
    for(int i = 0; i < u.itemNames.Count; i++){
        if(u.itemLst[u.itemNames[i]].Current == 1) u.itemsFound.Add(u.itemNames[i]);
    }

    // Set checks on Bucket and Castle Key and remove their quests if already collected when loading a save
    u.bucketCheck = false;
    if(u.itemsFound.Contains("Bucket")){
        u.bucketCheck = true;
        u.questTracker["Asclepius"].Remove(100);
    } 

    u.castleKeyCheck = false;
    if(u.itemsFound.Contains("Castle Key")) {
        u.castleKeyCheck = true;
        u.questTracker["Athena"].Remove(100);
    }

    // Remove already completed quests from questTracker if loading a save
    for(int i = 0; i<u.godNames.Count; i++){
        var gN = u.godNames[i];
        var qT = u.questTracker[gN];
        var printBefore = gN + " Start: ";
        for(int j = 0; j<qT.Count ; j++) printBefore = printBefore + qT[j] + ",";
        qT.RemoveRange(0,qT.IndexOf(u.questLst[gN].Current)+1);
        if(qT.Count>0 && u.questItemLst[gN].Current*100 == qT[0]) qT.RemoveAt(0);
        var printAfter = gN + " Loaded To: ";
        for(int k = 0; k<qT.Count ; k++) printAfter = printAfter + qT[k] + ",";
        u.Log(printAfter);
    }

    // Count number of collected achievements upon starting/loading
    vars.achievementsUnlocked = 0;
    for(int i = 0; i < u.achievementNames.Count; i++) vars.achievementsUnlocked = vars.achievementsUnlocked + u.achievementsLst[u.achievementNames[i]].Current;

    u.Log("VALUES UPDATED. RUN STARTED");
}

reset{
    var u = vars.U;
    if(u.statLst["menuType"].Old != 1 && current.gameStatus == "Main Menu" && current.roomP1 == "Main Menu") return true;
}

split{
    var u = vars.U;    
    if(current.gameStatus == "Main Menu" | u.realmLst["Cyclops"].Current + u.bossHealthLst["Cyclops"].Current == 0) return false;    // won't split if on the main menu, or if all values in game are zero on first startup
    
    else{
        var thisWorldP1 = u.statLst["world[1]"].Current;
        var thisWorldP2 = u.statLst["world[2]"].Current;

        // Realm Only Splits - Player 1
        if(current.realmP1 != "Castle"){
            // Enter Unvisited Realm - Player 1
            if(current.realmP1 != "Lich"){
                if(settings["enter"+current.realmP1]){
                    if(!u.realmTracker.Contains(current.realmP1)){ 
                        u.realmTracker.Add(current.realmP1);    
                        u.Log("SPLIT: "+current.realmP1+" Visited");
                        return true;
                    } 
                }
            }

            // Rune Collection
            if(vars.runesCollected > u.maxRunes && current.realmP1 != "Lich"){
                u.maxRunes = vars.runesCollected;
                if(settings["runes"+current.realmP1] && u.runesLst[current.realmP1].Changed){
                    u.Log("SPLIT: "+current.realmP1+" Rune Collected");
                    // Find any Rune in Current Realm - Player 1
                    if(!settings["lastRune"]) return true;
                    // Split for only last Rune in Current Realm - Player 1
                    else if(settings["lastRune"] && u.runesLst[current.realmP1].Current == 8) return true;
                }
            }

            // Enter Specific Boss Room - Player 1
            if(settings["visitBoss"] && u.statLst["currentRoomIdx[1]"].Current == u.bossRooms[thisWorldP1] && !u.visitBoss.Contains(current.realmP1)){
                if(settings["visit"+current.realmP1]){
                    if(current.realmP1 == "Lich"){
                        u.visitBoss.Add(current.realmP1);
                        u.Log("SPLIT: Reached Lich");
                        return true;
                    }
                    if(u.runesLst[current.realmP1].Current == 8) {
                        u.visitBoss.Add(current.realmP1);
                        u.Log("SPLIT: Reached "+current.realmP1);
                        return true;
                    }
                }
            }
        }

        // Realm Only Splits - Player 2
        if(current.realmP2 != "Castle"){        
            // Enter Unvisited Realm - Player 2
            if(current.realmP2 != "Lich"){
                if(settings["enter"+current.realmP2] && current.realmP2 != "Lich"){
                    if(!u.realmTracker.Contains(current.realmP2)){ 
                        u.realmTracker.Add(current.realmP2);    
                        u.Log("SPLIT: "+current.realmP2+" Visited");
                        return true;
                    } 
                }
            }

            // Rune Collection
            if(vars.runesCollected > u.maxRunes && current.realmP2 != "Lich"){
                u.maxRunes = vars.runesCollected;
                if(settings["runes"+current.realmP2] && u.runesLst[current.realmP2].Changed){
                    u.Log("SPLIT: "+current.realmP2+" Rune Collected");
                    // Find any Rune in Current Realm - Player 2
                    if(!settings["lastRune"]) return true;
                    // Split for only last Rune in Current Realm - Player 2
                    else if(settings["lastRune"] && u.runesLst[current.realmP2].Current == 8) return true;
                }
            }

            // Enter Specific Boss Room - Player 2
            if(settings["visitBoss"] && u.statLst["currentRoomIdx[2]"].Current == u.bossRooms[thisWorldP2] && !u.visitBoss.Contains(current.realmP2)){
                if(settings["visit"+current.realmP2]){
                    if(current.realmP2 == "Lich"){
                        u.visitBoss.Add(current.realmP2);
                        u.Log("SPLIT: Reached Lich");
                        return true;
                    }
                    if(u.runesLst[current.realmP2].Current == 8){
                        u.visitBoss.Add(current.realmP2);
                        u.Log("SPLIT: Reached "+current.realmP2);
                        return true;
                    }
                }
            }
        }

        // Item Splits
        if(vars.itemsCollected > u.maxItems){
            u.maxItems = vars.itemsCollected;
            for(int i = 0; i < u.itemNames.Count; i++){
                var iN = u.itemNames[i];
                if(u.itemLst[iN].Changed && !u.itemsFound.Contains(iN)){
                    u.itemsFound.Add(iN);
                    u.Log("Item Collected: "+iN);
                    if(settings["find"+iN]){
                        if(u.itemsFromQuests.Contains(iN)){
                            if(settings["doubleItemReceipt"] && settings["questReceive "+iN]) return false;
                            else {
                                u.Log("SPLIT: Collected "+iN);
                                return true;
                            }
                        }
                        else if(u.itemsForQuests.Contains(iN)) return false;
                        else{
                            u.Log("SPLIT: Collected "+iN);
                            return true;
                        }
                    }
                }
            }
        }

        // Bucket & Castle Key Splits - these are separate as they can be collected before triggering the quest for them and as such need special behaviour
        if(u.itemLst["Bucket"].Changed && u.bucketCheck == false){
            u.bucketCheck = true;
            u.questTracker["Asclepius"].Remove(100);
            if(settings["findBucket"] | settings["questCollect Bucket"]){
                u.Log("SPLIT: Collected Bucket");
                return true;
            }
        }

        if(u.itemLst["Castle Key"].Changed && u.castleKeyCheck == false){
            u.castleKeyCheck = true;
            u.questTracker["Athena"].Remove(100);
            if(settings["findCastle Key"] | settings["questCollect Castle Key"]){
                u.Log("SPLIT: Collected Castle Key");
                return true;
            }
        }

        // Quest Splits
        for(int i = 0; i < u.godNames.Count; i++){
            var gN = u.godNames[i];
            if(u.questLst[gN].Changed | u.questItemLst[gN].Changed){
                u.Log("CHECK 1 - "+gN.ToString()+": "+u.questLst[gN].Changed.ToString()+"/"+u.questItemLst[gN].Changed.ToString());         
                for(int j = 0; j < u.questLines[gN].Count; j++){
                    if(u.questLines[gN][j] == "Collect Bucket" | u.questLines[gN][j] == "Collect Castle Key") return false;
                    if((u.questLst[gN].Changed && u.questLst[gN].Current == u.questTracker[gN][0]) | (u.questItemLst[gN].Changed && (u.questItemLst[gN].Current)*100 == u.questTracker[gN][0])){
                        u.questTracker[gN].RemoveAt(0);
                        if(settings["quest"+u.questLines[gN][j]]){
                            u.Log("SPLIT: "+gN+" Quest Complete");
                            return true;
                        }
                    }
                }
            }
        }

        // Achievement Splits
        for(int i = 0; i < u.achievementNames.Count; i++){
            var aN = u.achievementNames[i];
            if(u.achievementsLst[aN].Changed){
                u.Log("SPLIT: Achievement Unlocked - "+aN);
                vars.achievementsUnlocked++;
                if(settings[aN]) return true;
            }
        }

        // Secret Splits
        if(u.statLst["secretPerc"].Current > u.maxSecrets){
            u.maxSecrets = u.statLst["secretPerc"].Current;
            if(settings["secrets"]){
                u.Log("SPLIT: Secret Found");
                return true;
            }
        }
 
        // Defeat Boss
        if(settings["defeatBoss"]){
            for(int i = 1; i < u.realmNames.Count-1; i++){
                var rN = u.realmNames[i];
                if(settings["defeat"+rN]){
                    if(u.bossLst[rN].Old == 0 && u.bossLst[rN].Current == 1 && !u.bossDefeated.Contains(i)){
                        u.Log("SPLIT: Defeated "+rN);
                        u.bossDefeated.Add(i);
                        return true;
                    }
                    if(u.bossHealthLst["Lich"].Old > 0 && u.bossHealthLst["Lich"].Current == 0 && !u.bossDefeated.Contains(i)){
                        u.Log("SPLIT: Defeated Lich");
                        u.bossDefeated.Add(i);
                        return true;
                    }
                }
            }
        }

        // End Game
        if(settings["finalSplit"]){
            if(u.statLst["gameFinished"].Old == 0 && u.statLst["gameFinished"].Current == 1){
                u.Log("SPLIT: Game Completed");
                return true;
            }
        }
    }
}
