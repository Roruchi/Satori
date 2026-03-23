# **Satori: Comprehensive Game Design and Technical Implementation Report**

## **Strategic Vision and the Paradigm of Permanent Emergence**

The contemporary mobile application ecosystem is heavily engineered around mechanics designed to exploit dopaminergic feedback loops through high-intensity action and rapid content consumption.1 *Satori: The Constant Garden* represents a fundamental architectural departure from this psychological paradigm. The application is conceptualized as a digital "Third Space"—a persistent, infinite sanctuary that facilitates mindful growth and cognitive decompression.1

At the core of this vision is the systemic philosophy of **Permanent Emergence**.1 Every user interaction acts as an additive, irreversible brushstroke upon a continuously expanding digital biosphere. Standard digital mechanics such as "undo" or "clear" are strictly forbidden.1 This design choice mirrors the irreversible progression of biological life. Mistakes are not deleted; they are the foundational terrain upon which new ecological complexity must be built, shifting the user from reactive consumption to proactive, meditative creation.1

## **Core Pillars of Design**

* **Organic Adjacency:** Life cannot spring from nothing. Every tile (except for the Origin) must be placed adjacent to an existing tile, causing the garden to grow like a sprawling root system.1  
* **The No-Reset Rule:** Every action is final. This enforced permanence encourages intentionality and rewards observation over quick reflexes.1  
* **Deep Metadata Discovery:** Discoveries are complex "Environmental States" triggered by multi-layered requirements involving adjacency, ratios, and distance.1

## **Analysis of Inspirational Frameworks**

* **Cascadia:** Provides the foundation for multi-layered spatial logic.3 Like *Cascadia's* wildlife scoring, *Satori* rewards specific tile configurations to summon unique lifeforms.3  
* **Dorfromantik:** Serves as the structural inspiration for infinite landscape expansion and long-term "Crown Quests" to unlock rare aesthetic variations.5  
* **Townscaper:** Borrowed for its algorithmic "recipes" where specific geometric enclosures trigger high-priority procedural modules, such as interior gardens.7  
* **Islanders:** Inspires the "Proximity Resonance" score, where buildings or biomes gain value based on their immediate neighbors, rewarding strategic arrangement.9

## **Core Systems and Interaction Model**

### **1\. The Interaction Logic: "Tactile Zen"**

* **Drag-to-Explore:** Optimized for mobile, momentum-based panning allows the user to glide across the canvas.1  
* **Long-Press to Plant:** Prevents accidental taps while scrolling (approx. 300-400ms duration).1  
* **The Mixing & Locking Rule:** Complexity is derived from **Biome Mixing**. If a player long-presses a new base tile directly *on top* of an already placed base tile, the engine algorithmically merges them into a hybrid biome. Once mixed, the tile is **Locked**, preventing further stacking and ensuring every choice is impactful.

### **2\. Sonic Resonance: Ambient Soundscape System**

To breathe life into the garden, each biome triggers its own ambient layer.11

* **Proximity Blending:** As the camera moves, the engine calculates the proportion of nearby biomes.3 Panning from a "Deep Stand" (Forest) toward a "Mirror Archipelago" (Water) causes rustling leaves and birdsong to fade as rhythmic lapping waves take over.3

### **3\. Visual Style: High-Definition Voxel Diorama**

* **AI-Generative Friendly:** Generative AI models excel at producing modular voxel textures and silhouettes, allowing for rapid iteration of environmental props.1  
* **Smart Merging:** Using Bitmask Autotiling, the engine evaluates neighbors to blend textures seamlessly. When 10+ Stone tiles connect, they "collapse" into a unified, organic **Mountain** mesh.10

## **Catalog of Discovery**

### **Macro-Biomes (10 Distinct Terrain Types)**

Created by mixing the 4 elemental base tiles: **Forest, Water, Stone, and Earth/Sand.**

| Biome Type | Creation Recipe | Aesthetic and Functional Impact |
| :---- | :---- | :---- |
| **1\. Forest (Base)** | \- | Lush green canopies; procedural size scaling. |
| **2\. Water (Base)** | \- | Reflective teal surfaces; shader-based waves. |
| **3\. Stone (Base)** | \- | Gray rocky voxels; triggers Mountain Growth at 10 tiles. |
| **4\. Earth (Base)** | \- | Textured beige; transitional neutral buffer. |
| **5\. Swamp** | Forest \+ Water | Murky green voxels with procedural fog and reeds. |
| **6\. Tundra** | Stone \+ Water | Snow-capped voxels and glacial ice; cold blue tint. |
| **7\. Mudflat** | Earth \+ Water | Dark, saturated soil; vital for amphibious spirits. |
| **8\. Mossy Crag** | Forest \+ Stone | Weathered boulders overgrown with thick green moss. |
| **9\. Savannah** | Forest \+ Earth | Golden grasslands dotted with flat-topped acacia trees. |
| **10\. Canyon** | Stone \+ Earth | Striated red and orange mesas; desert geometry. |

### **Tier 1: Sub-Discoveries & Biome Clusters (12 Total)**

*Triggered by sizing/purity constraints. Each features a unique audio "Bed."*

1. **The River:** 10+ tiles of 1-tile-wide Water. (Audio: Bubbling stream).  
2. **The Deep Stand:** 10+ Forest tiles with no adjacent Stone. (Audio: Echoey birds).  
3. **The Glade:** 1 Earth tile surrounded by 6 Forest tiles. (Audio: Wind chimes).  
4. **Mirror Archipelago:** 5+ alternating Water/Sand pairs. (Audio: Sea birds).  
5. **Barren Expanse:** 25+ Earth tiles with no Water nearby. (Audio: Howling wind).  
6. **Great Reef:** 15 Water tiles containing 3 non-adjacent Stone. (Audio: Underwater hum).  
7. **Lotus Pond:** Water surrounded by Earth, then by Forest. (Audio: Harmonic chord).  
8. **The Mountain Peak:** Triggered by the 10th contiguous Stone tile. (Audio: Deep boom).  
9. **Boreal Forest:** 5 Forest \+ 5 Tundra tiles interwoven. (Audio: Cold wind).  
10. **The Peat Bog:** 20+ Swamp tiles. (Audio: Low-frequency gurgling).  
11. **Obsidian Expanse:** Mixed Canyon surrounded by Water. (Audio: Glassy clinks).  
12. **The Waterfall:** A River touching the edge of a Mountain Peak. (Audio: Rushing water).

### **Tier 2: Structural Landmarks (10 Total)**

*Triggered by specific geometric shape recipes.*

1. **Origin Shrine:** A cross (+) of Water with Stone at (0,0).  
2. **Bridge of Sighs:** A 3-tile Stone line spanning across Water.  
3. **Lotus Pagoda:** A 2x2 square of Mixed Swamp tiles.  
4. **Monk’s Rest:** 1 Earth tile completely enclosed by 6 Forest tiles.  
5. **Star-Gazing Deck:** 1 Stone tile atop a 20+ Mountain cluster.  
6. **Sun-Dial:** 5 Sand tiles in a ring with Stone in the center.  
7. **Whale-Bone Arch:** A U-shape of 5 Sand mixed with Stone.  
8. **Echoing Cavern:** A 3x3 Stone ring with an empty center.  
9. **Bamboo Chime:** A 5-tile line of Forest mixed with Sand.  
10. **Floating Pavilion:** A Water/Forest mix tile isolated from land.

### **Tier 3: Ecological Synergy and Spirit Animals (30 Total)**

*Autonomous entities summoned by multi-variable algorithms. Discovery is often presented as a Riddle.*

**Forest Spirits**

1. **Red Fox:** 3 Forest tiles in a triangle.  
2. **Mist Stag:** Complete a Deep Stand cluster.  
3. **Emerald Snake:** 7 Forest tiles in a straight line.  
4. **Owl of Silence:** Forest tile adjacent to a Monk’s Rest.  
5. **Tree Frog:** Forest tile bordering a Swamp.

**Water Spirits**

6\. **White Heron:** 5 Water tiles in a line.

7\. **Koi Fish:** 2x2 square of pure Water.

8\. **River Otter:** 10 Water tiles in a "curvy" line.

9\. **Blue Kingfisher:** Forest mixed with Water.

10\. **Dragonfly:** 1 Water tile surrounded by 4 Sand.

**Stone Spirits**

11\. **Mountain Goat:** Stone tile touching a 10+ Mountain cluster.

12\. **Stone Golem:** 3x3 solid block of pure Stone.

13\. **Granite Ram:** Complete a Granite Range cluster.

14\. **Sun-Lizard:** Stone tile adjacent to 4 Sand tiles.

15\. **Rock Badger:** Stone tile at the very edge of the garden.

**Meadow & Earth Spirits**

16\. **Golden Bee:** 10+ connected Savannah tiles.

17\. **Jade Beetle:** 15+ connected Forest/Meadow tiles.

18\. **Meadow Lark:** Complete a Verdant Valley cluster.

19\. **Field Mouse:** Tile adjacent to 3 different macro-biome types.

20\. **Hare:** 4 Savannah tiles in a straight line.

**Mixed Wilds Spirits** 21\. **Marsh Frog:** 7 Swamp tiles in a contiguous line. 22\. **Peat Salamander:** Exact center of a Peat Bog discovery. 23\. **Swamp Crane:** Swamp tile adjacent to a River and Forest. 24\. **Murk Crocodile:** Swamp tiles enclosing a Water tile. 25\. **Mud Crab:** Mudflat tile adjacent to a Great Reef. 26\. **Frost Owl:** Roosts in a Boreal Forest. 27\. **Boreal Wolf:** 10 Tundra tiles bordering a Forest. 28\. **Tundra Lynx:** River intersecting a Tundra biome. 29\. **Ice Cavern Bat:** Enclosed Ice Cavern landmark. 30\. **Sky-Whale:** Manifests at 1,000 tiles with perfect biome balance.9

## **Requirements Specification**

### **1\. Functional Requirements**

* **Infinite Tiling Engine:** System must support a coordinate-based grid that expands infinitely without boundaries.1  
* **Pattern Matching Scan:** A background thread must scan tile arrays after every placement to trigger Discoveries without interrupting the 60fps render loop.15  
* **Voxel Mesh Merging:** Contiguous clusters of specific biomes (like 10+ Stone) must collapse individual voxels into a single high-definition Mountain mesh.10

### **2\. Non-Functional Requirements**

* **Load Times:** Core gameplay must be reachable within 10 seconds of app launch.7  
* **Performance:** Stable 60fps on mid-range hardware (e.g., iPhone 13\) via **World Partitioning** (16x16 chunks).16  
* **Accessibility:**  
  * Interactable elements must be in "thumb range" (bottom corners).18  
  * Haptic intensity must be toggleable.2  
  * High-contrast colorblind-friendly voxel palettes.18

## **Roadmap and Testing Phases**

### **Phase 1: Technical Foundation (Weeks 1-4)**

* **Deliverable:** Prototype infinite grid and "Organic Adjacency" rules in Godot 4.x.

### **Phase 2: Procedural Mechanics (Weeks 5-10)**

* **Deliverable:** Working "Alchemy" (Mixing/Locking) system and background pattern matching.

### **Phase 3: Voxel Aesthetic & AI Asset Pipeline (Weeks 11-16)**

* **Deliverable:** Implementation of the 10 macro-biomes with procedural blending and AI-assisted environmental props.

### **Phase 4: Testing & Polish (Weeks 17-22)**

* **Alpha:** Stress test infinite scroll and memory management.7  
* **Beta:** Limited release to evaluate Zero-HUD usability and "Zen Flow."  
* **QA:** Performance optimization across diverse mobile chipsets.19

#### **Works cited**

1. Satori: Design Plan  
2. RULEBOOK \- Alderac Entertainment, accessed on March 7, 2026, [https://www.alderac.com/wp-content/uploads/2023/07/Cascadia\_Landmarks\_EN\_1P\_Rules\_Rulebook\_FINAL\_compressed-1.pdf](https://www.alderac.com/wp-content/uploads/2023/07/Cascadia_Landmarks_EN_1P_Rules_Rulebook_FINAL_compressed-1.pdf)  
3. Journey Into the Pacific Northwest – An Overview of Cascadia \- News \- Dire Wolf Digital, accessed on March 7, 2026, [https://news.direwolfdigital.com/journey-into-the-pacific-northwest-an-overview-of-cascadia/](https://news.direwolfdigital.com/journey-into-the-pacific-northwest-an-overview-of-cascadia/)  
4. Games like Dorfromantik? : r/CozyGamers \- Reddit, accessed on March 7, 2026, [https://www.reddit.com/r/CozyGamers/comments/1r096tt/games\_like\_dorfromantik/](https://www.reddit.com/r/CozyGamers/comments/1r096tt/games_like_dorfromantik/)  
5. Dorfromantik tips and tricks: a beginner's guide | Rock Paper Shotgun, accessed on March 7, 2026, [https://www.rockpapershotgun.com/dorfromantik-tips-and-tricks-beginners-guide](https://www.rockpapershotgun.com/dorfromantik-tips-and-tricks-beginners-guide)  
6. Challenges \- Dorfromantik Wiki \- Fandom, accessed on March 7, 2026, [https://dorfromantik.fandom.com/wiki/Challenges](https://dorfromantik.fandom.com/wiki/Challenges)  
7. How Townscaper Works: A Story Four Games in the Making, accessed on March 7, 2026, [https://www.gamedeveloper.com/game-platforms/how-townscaper-works-a-story-four-games-in-the-making](https://www.gamedeveloper.com/game-platforms/how-townscaper-works-a-story-four-games-in-the-making)  
8. World building with Townscaper, a short tutorial \- Project Dizary, accessed on March 7, 2026, [https://www.dizary.nl/world-building-with-townscaper-a-short-tutorial/](https://www.dizary.nl/world-building-with-townscaper-a-short-tutorial/)  
9. Islanders: Console Edition Review \- Video Chums, accessed on March 7, 2026, [https://videochums.com/review/islanders-console-edition](https://videochums.com/review/islanders-console-edition)  
10. Guide :: Islanders Score & Strategy Bible \[WIP\] \- Steam Community, accessed on March 7, 2026, [https://steamcommunity.com/sharedfiles/filedetails/?id=1704459130](https://steamcommunity.com/sharedfiles/filedetails/?id=1704459130)  
11. (PDF) What's Zen about Zen Modes? Prajna Knowledge versus Mindfulness in Game Design \- ResearchGate, accessed on March 7, 2026, [https://www.researchgate.net/publication/317777996\_What's\_Zen\_about\_Zen\_Modes\_Prajna\_Knowledge\_versus\_Mindfulness\_in\_Game\_Design](https://www.researchgate.net/publication/317777996_What's_Zen_about_Zen_Modes_Prajna_Knowledge_versus_Mindfulness_in_Game_Design)  
12. RULEBOOK, accessed on March 7, 2026, [https://www.bsbwlibrary.org/wp-content/uploads/2023/09/Cascadia-Part-1.pdf](https://www.bsbwlibrary.org/wp-content/uploads/2023/09/Cascadia-Part-1.pdf)  
13. Games like dorfromantik? : r/CozyGamers \- Reddit, accessed on March 7, 2026, [https://www.reddit.com/r/CozyGamers/comments/1d194xd/games\_like\_dorfromantik/](https://www.reddit.com/r/CozyGamers/comments/1d194xd/games_like_dorfromantik/)  
14. Victor Navarro-Remesal, "Zen and Slow Games" (MIT Press, 2026\) | MIT Learn, accessed on March 7, 2026, [https://learn.mit.edu/search?q=statistics\&resource=86427](https://learn.mit.edu/search?q=statistics&resource=86427)  
15. Unity vs. Godot, pros and cons of each? Which is better for an absolute beginner? \- Reddit, accessed on March 7, 2026, [https://www.reddit.com/r/gamedev/comments/1fxd33a/unity\_vs\_godot\_pros\_and\_cons\_of\_each\_which\_is/](https://www.reddit.com/r/gamedev/comments/1fxd33a/unity_vs_godot_pros_and_cons_of_each_which_is/)  
16. Infinite TileMap with Godot 4 \- Roger Clotet, accessed on March 7, 2026, [https://clotet.dev/blog/infinite-tilemap-with-godot-4](https://clotet.dev/blog/infinite-tilemap-with-godot-4)  
17. \[Showcase\] I built an isometric Game Engine using only Jetpack Compose & Kotlin (No game engine, no ads, completely offline). Performance is 60fps on mid range devices. : r/developersIndia \- Reddit, accessed on March 7, 2026, [https://www.reddit.com/r/developersIndia/comments/1psrx2f/showcase\_i\_built\_an\_isometric\_game\_engine\_using/](https://www.reddit.com/r/developersIndia/comments/1psrx2f/showcase_i_built_an_isometric_game_engine_using/)  
18. Dorfromantik | Guide for Complete Beginners | Episode 1 \- YouTube, accessed on March 7, 2026, [https://www.youtube.com/watch?v=YGD53nn6VtE](https://www.youtube.com/watch?v=YGD53nn6VtE)  
19. \[WIP\] A Definitive Guide to Townscaper \- Steam Community, accessed on March 7, 2026, [https://steamcommunity.com/sharedfiles/filedetails/?id=2186511914](https://steamcommunity.com/sharedfiles/filedetails/?id=2186511914)