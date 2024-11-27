# Example Roblox Game Architecture
This project is an example of how I might create a test-driven ROBLOX game.

Some things to note:
* `src/replicated-storage/Tests` is a directory of tests; this code automatically tests that the game functions correctly
* All game code is implemented in `src/replicated-storage/SoccerDuels` as an API (this is the code that is tested)
* All game configuration settings are in `src/replicated-storage/Config/DefaultConfig.lua`
* A list of all expected asset templates (e.g. UI elements, maps, etc) are in `src/SoccerDuels/AssetDependencies/ExpectedAssets.lua`. The system automatically tells you if any asset is missing or of the wrong Instance type
* Client code is actually tested on the server, which gives about a 10X improvement in runtime for the test suite as opposed to running client tests in local scripts. This is achieved via polymorphic libraries that expose the same interface but are implemented differently on the server + client
