# SpicyATC (INSTRUCTIONS UPDATED 09/08/2025)

SpicyATC is a custom Lua script for Digital Combat Simulator (DCS) that replaces or augments the built‑in ATC system with a more realistic, BMS‑style sequence. It introduces state‑driven F10 radio menus, automatic airbase assignment, and simple but improved radio lines. The script is coalition‑aware and works in single‑player or co‑op missions (thats all i have tested. The logic is there for multiplayer. Every function probably wont work). ALSO, THERE IS NO WAY TO REMOVE DEFAULT ATC from DCS. I have tried. That thing will show up no matter what. Well, see if i figure it out.

TUTORIAL VIDEO IS HERE --> ([Watch the video](https://youtu.be/wROWrwPhODA?si=41r6IErKsQECUcN9))

Built by Spicy @spicy2160 (discord)

## UPDATES!!!
-At this point I have slowed development(i work a ton + some other personal life stuff) but have not abandoned project. I am working with every bit of free time I have and am slowly making progress on the next update for this script. I want it to be filled with improvments, as well as custom audios. I am writing this solo (if you know how to help please reach out, I never wanted this to become laborious, LOL), and also, I am not a software dev. Learning as we go along. Now, for those still reading, I have added the tool to package custom audios to a .miz file, which is necessary since I am not planning on making .miz files for this, and want to work with YOUR files.

![test](test1.png)

## Features

- Automatic home base assignment – when a player spawns, the script finds the nearest airbase owned by their coalition and sets it as their home base. (this can be changed at any time)

- State‑driven ATC flow – follows a logical sequence: Startup → Taxi → Takeoff → Handoff → Inbound → Approach → Landing → Parking → Shutdown. Most menu Options force you to follow the steps.

- Simplified radio messages – taxi and takeoff instructions omit specific taxiways and runways but still feel authentic. Each message tells the player who to contact next. I plan to expand on this heavily.

- Hand-offs for radio controllers. Like BMS, I have added a "hand-off" I also want to expand on these

- Queue management – the script queues aircraft for takeoff and landing and notifies each pilot of their position.

- Redundancy – if a player requests taxi clearance again after already being cleared, the script repeats the original clearance instead of returning an error. (I will work on more robust error handling. However it wont crash)

- Automatic landing and "inbound detection".

## Architecture overview

- **Centralized player lifecycle** – every pilot is tracked through an explicit state machine (`not_started → … → parked`). Menu handlers, DCS engine events, and watchdog timers coordinate to keep pilots in sequence and reject out-of-order requests.
- **Coalition-aware radio menus** – F10 menus are created lazily for each coalition and rebuilt automatically if DCS clears them. Ground, Tower, and Slasher (approach) submenus expose the scripted flow without affecting the stock ATC.
- **Automatic home-base context** – spawn events and menu handlers call the nearest-owned airbase heuristic so a player always has a valid destination even if they never touch the “Select Home Airbase” list.
- **Queue-driven clearances** – per-airbase tables keep takeoff and landing requests in order. Only the front-of-line pilot receives clearance, mirroring real-world tower control.
- **Telemetry safeguards** – periodic sampling records position and speed so the script can prove that taxi actually happened, infer FARPs/carrier departures when `RUNWAY_TAKEOFF` is missing, and auto-advance inbound aircraft that forget to hit the menus.
- **Event reconciliation** – authoritative DCS events (`BIRTH`, `ENGINE_STARTUP`, `RUNWAY_TAKEOFF`, `LAND`) override menu assumptions to keep the lifecycle honest if a player skips steps or if lag delays callbacks.
- **Resilient watchdogs** – timers rebuild menus after scripting resets, refresh telemetry, and auto-transition aircraft into approach so long missions stay synchronized.
- **Mission-agnostic integration** – initialization seeds all coalition menus and registers the global event handler, so mission authors only need a single “Do Script” trigger.

## Reading path for developers

1. **State & data tables** – skim the top of `SpicyATC.lua` to understand the player record, queue structures, and telemetry store that drive every menu callback.
2. **Menu construction** – review `ensureMenusForCoalition` and `rebuildAirbaseList` to see how the F10 tree is built and refreshed.
3. **Player flow handlers** – follow the ground-to-air-to-ground sequence (`requestStartup` through `requestShutdown`) to understand the nominal progression and queue bookkeeping.
4. **Event handler** – study `onEvent` to learn how DCS engine signals reconcile the script with simulator truth and recover from skipped menus.
5. **Watchdogs/timers** – finish with `periodicApproachTick` and `retryAddMenus`, which keep telemetry fresh and menus present during long missions.

## Operational flow at a glance

- **Startup & taxi** – ground handlers require the previous state, automatically assign a home base, and capture taxi telemetry before tower calls are honored.
- **Departure sequence** – tower adds the pilot to the takeoff queue, and only `RUNWAY_TAKEOFF` (or speed heuristics) unlocks the handoff to Slasher.
- **Recovery pipeline** – Slasher manages inbound and approach gating, while tower landing calls consult the queue until `S_EVENT_LAND` promotes the next pilot.
- **Post-landing wrap-up** – ground commands transition crews through parking and shutdown for immersion even though DCS lacks parking occupancy events.

## Installation

1. Download the latest release .zip file from the releases page.

2. Copy the script into your DCS mission’s Scripts folder or another location of your choice. (C:\Users\ {user}\Saved Games\DCS\Scripts)

3. In the DCS Mission Editor, add a trigger at mission start (i use the following):

- Trigger: ONCE, NO EVENT

- Condition: Time More (1 second)

- Action: "Do Script File" and point it to spicyATC.lua

4. Save and run your mission. (Script should work on start-up)

No additional mods or tools are required.

## Usage (tutorial in youtube above)

When you start the mission, open the F10 menu and select SpicyATC. You will see submenus for Ground, Tower, and Slasher (idk what the terminology is called in BMS, for now pretend it is your overlord/air controller). I have tested it for jets and helicopters in single player and it works with full text- functionality. I have also tested on red and blue coalition.

At any point, under the ground menu, hit refresh airbase list, and then return to ground menu, to change your home airbase.

Follow the sequence of calls:

- Ground → Request Startup
Clears you (or your flight) to start engines.

- Ground → Request Taxi
Provides taxi instructions and hands you off to the tower.

- Tower → Request Takeoff
Places you in the takeoff queue; when first in line, you are cleared to depart and told to contact again for hand‑off.

- Tower → Request Handoff
After becoming airborne, triggers a hand‑off to Slasher, advises you to check in.

- Slasher → Check In
Acknowledge the hand‑off; Slasher tells you to fly your mission.

- Slasher → Request Inbound
On your way back, request inbound; Slasher confirms and tells you to call for approach clearance. (I also have auto detection logic. If you are within 10 NMs you can call in, or watch for approach alert)

- Slasher → Request Approach
This is automatic, or if you feel the need to do it, it will work within 10nms, otherwise will tell you that you are too far.

- Tower → Request Landing
Clears you to land or informs you of your position in the landing queue, Tells u to contact ground for taxi.

- Ground → Taxi to Parking
Once landed and stopped off of runway, call for taxi clearance and instructions.

- Ground → Shutdown
The ground crew will tell you that you are cleared for shutdown, and sign off.

If you call a step out of sequence (e.g., request taxi before startup), the script will let you know.

## Plans for updates

While I have grinded out the framework, I expect the releases to slow down just a bit. Below are things I plan on adding.

## High priority : 
- Vectors for take-off and landing ()
- Runway detection for takeoff and landing instructions. DCS default ATC does this right now so I wasnt so worried about this.
- Ensure multiplayer support (i think im already done but dont have time to test)
- Voice lines for all radio calls and variety (I have a very talended @WhiskeyTangoFoxtrot working on a full suite of recordings for the alpha release. Those will follow soon! Thank them lots)
- A wider range of radio messages

## Not so high priority (things not started yet):
- Working radio frequency (this is very mission editor heavy and i have not figured out how to do this yet)
- Dynamic menu (ed makes it very static to add a menu to top right. I would have to code every single instance of a menu)
- More radio options, for awacs and such. Need to figure out how to force triggers for awacs.

## Things planned but are far away
- I want it to run completly dynamically. ED doesnt keep track of taxi lanes, so having it tell you where to taxi, is either going to have to be hard coded, or im going to have to find a way to track them.
- Translations for radio lines + messages
- A faster version (i am doing a ton of coordinate + speed math). It can for sure detect states faster. LUA isnt fun to try and make efficient.


# Contributing + credits

Suggestions for Bug fixes, new features, or improvements to realism are welcome. I also will happily accept development help with this. Please message me on discord or github or reddit. I work a ton and don't have the time of day to write, test, and maintain this at the rate I have been. Same with voice lines, whatever else.

VOICE ACTORS (yes, i know voice lines arent in yet. Watch the youtube video): @WhiskeyTangoFoxtrot @Erinyes @BakedPotato

## License

This project is released under the MIT license. You have my permission to do whatever you see fit with it, as long as credit is given.
