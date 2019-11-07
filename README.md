# arma3-missions

Singleplayer and multiplayer compatible missions for Arma 3.

## Development

Open a PowerShell window and navigate to the `missions` folder in your Arma 3
profile folder. I'm using mine as an example in the directions below.

```
> Set-Location -Path ([environment]::getFolderPath("MyDocuments"))
> cd '.\Arma 3 - Other Profiles\CtrlC-Root\missions'
```

Clone the repository directly into the `missions` folder.

```
> git init
> git remote add origin https://github.com/CtrlC-Root/arma3-missions
> git pull origin master
```

Run the `Setup.ps1` script to setup symbolic links to shared mission scripts.

```
> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted
> .\Setup.ps1
```

Now you should be able to open and run the missions from the built-in editor.
If you want to play them in regular Singleplayer or Multiplayer modes you need
to load the mission in the editor and then export it. In the 3D editor you
can click "File" then "Export" from the main menu at the top. This compiles and
packages the mission into a `.pbo` file in the appropriate directory for the
mission type. Now you should be able to start a Singleplayer or Multiplayer
game with the mission.

## Releases

You can download pre-packaged versions of the missions from the GitHub releases
page. You can install these locally without having to export them through
the editor.

* To install the singleplayer missions copy the contents of the `Missions`
  folder to `%ProgramFiles(x86)%\Steam\steamapps\common\Arma 3\Missions`.
* To install the multiplayer missions copy the contents of the `MPMissions`
  folder to `%ProgramFiles(x86)%\Steam\steamapps\common\Arma 3\MPMissions`.

## Missions

All missions are named using the `CtrlC-[Type]-[Name].[Map]` pattern.

## References

* https://dev.arma3.com/
* Scripting
  * https://community.bistudio.com/wiki/Category:Scripting_Commands_Arma_3
  * https://community.bistudio.com/wiki/Category:Arma_3:_Functions
  * https://community.bistudio.com/wiki/Arma_3:_Event_Handlers
  * https://community.bistudio.com/wiki/Arma_3_Actions
* Engine
  * https://community.bistudio.com/wiki/Initialization_Order
  * https://resources.bisimulations.com/wiki/Locality_in_Multiplayer
  * https://community.bistudio.com/wiki/Arma_3_Remote_Execution
* Mission configuration
  * https://community.bistudio.com/wiki/Description.ext
  * https://community.bistudio.com/wiki/Loading_Screens
  * https://community.bistudio.com/wiki/Multiplayer_Game_Types
  * https://community.bistudio.com/wiki/Arma_3_Respawn
* Extensions
  * http://killzonekid.com/arma-scripting-tutorials-how-to-make-arma-extension-part-1/
  * http://killzonekid.com/arma-scripting-tutorials-how-to-make-arma-extension-part-2/
  * http://killzonekid.com/arma-scripting-tutorials-how-to-make-arma-extension-part-3/
  * http://killzonekid.com/arma-scripting-tutorials-how-to-make-arma-extension-part-4/
* Miscellaneous
  * https://forums.bistudio.com/forums/topic/103196-critical-section-mutex-atomicity-spawnexecvm/
  * https://forums.bistudio.com/forums/topic/188984-sqf-feature-requests/
