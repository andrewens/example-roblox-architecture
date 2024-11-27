# Example Roblox Game Architecture
This project is an example of how I might create a test-driven ROBLOX game.

How the project is organized:
* `src/replicated-storage/Tests` is a directory of tests; this code automatically tests that the game functions correctly using the TestEZ library
* All game code is implemented in `src/replicated-storage/SoccerDuels` as an API (this is the code that is tested)
* All game configuration settings are in `src/replicated-storage/Config/DefaultConfig.lua`
* A list of all expected asset templates (e.g. UI elements, maps, etc) are in `src/SoccerDuels/AssetDependencies/ExpectedAssets.lua`. The system automatically tells you if any asset is missing or of the wrong Instance type
* Client code is actually tested on the server, which gives about a 10X improvement in runtime for the test suite as opposed to running client tests in local scripts. This is achieved via polymorphic libraries that expose the same interface but are implemented differently on the server + client

Why this is a good way of doing this:
* Test-driven development is the best way to ensure code quality: it forces the developer to design a convenient interface, while also specifying exactly what problem they are solving; it also tells you if your system works automatically, which means you can refactor without fear of accidentally breaking something. Furthermore, every test is a concrete example of how to use the game code, which serves as the most practical kind of documentation.
* If you are looking for a config value, they will always be in one place
* The AssetDependencies module makes it easy to understand exactly what templates are depended on (again, in one place), and allows for asset creators to arbitrarily change the path that templates are stored without editing implementation code. Plus, the system instantly tells you if an asset is missing, which saves time from digging through code and parsing an error message.
* Multiplayer networking creates the most complex problems in ROBLOX development. Automatically testing Client-Server replication is incredibly helpful when it comes to implementing these features, because it will catch nuanced bugs (e.g. data being replicated in the wrong order) without the developer having to manually test it themself.
