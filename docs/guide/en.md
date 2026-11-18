# DRX to LUT — User guide
v{{VERSION}} · DaVinci Resolve Studio 21.2 · macOS 13+ (Apple silicon)

## 1. What it does
DRX to LUT turns a grade you made in DaVinci Resolve into a 65³ .cube LUT. You export the grade from Resolve as a DRX file, drop it into the app, review which nodes can go into a LUT, confirm the input and output, and press "Create LUT 65". Everything runs on your Mac; nothing is uploaded.

## 2. Before you start
- DaVinci Resolve Studio must be running, with external scripting enabled: Preferences > System > General > External scripting using > Local. The app was verified with Resolve Studio 21.2; other versions and the free edition were not verified.
- The OFX effects used in the DRX (for example GDC STYLE Client, installed separately) must be installed on this Mac. If one is missing the app says so and creates nothing, because the LUT would be incomplete.
- Save your own Resolve project first. The app works in a separate project called "DRX to LUT - work project". If Resolve is in another project, the app asks before switching, and afterwards offers to return to yours. Your project is never saved by the app.

## 3. Install
Open DRXtoLUT-{{VERSION}}.pkg, follow the installer (it asks for your Mac password) and open DRX to LUT from Applications. The first time, macOS may ask you to confirm opening an app downloaded from the internet; the app is signed with a Developer ID certificate and notarized by Apple.

## 4. Export a DRX from Resolve
On the Color page, grade a clip. Grab a still (right-click the viewer > Grab Still). In the gallery, right-click the still, choose Export, pick the DRX format and a name.

## 5. Create the LUT
Drop the DRX into the window, or press "Choose DRX...".
![idle]
The app opens the grade in Resolve and lists the nodes. Tick the nodes that should go into the LUT. Nodes that cannot be in a LUT are excluded and locked.
![review]
Read the Input and output box, then tick the confirmation. Choose a name and the destination folder and press "Create LUT 65". A progress bar shows the steps; Cancel stops safely and leaves no incomplete file. If a file with the same name exists, the app asks before replacing it.
![done]
In the folder you get: the .cube, a copy of the DRX, a notes file (.README.txt) and a machine-readable file (.lutinfo.json).

## 6. Apply the LUT correctly in Resolve
1. In Resolve open Project Settings > Color Management > Lookup Tables and press "Open LUT Folder". Copy the .cube there, then press "Update Lists".
2. On a node of your clip, right-click > 3D LUT and choose the file. Set 3D LUT interpolation to Tetrahedral.
3. The clip must be in the input colour space you confirmed in the app. Do not add the input or output transforms a second time: the LUT already contains the nodes you ticked.

## 7. What a LUT cannot hold
A LUT changes colour pixel by pixel. Blur, grain, halation, noise reduction, masks, tracking and anything that depends on neighbouring pixels or other frames cannot be inside a LUT. The app uses four labels:
- Goes into the LUT: per-pixel colour operations the app recognises.
- Cannot be in a LUT: spatial or temporal effects. Excluded automatically and listed in the notes.
- Unknown effect: an OFX effect the app cannot classify. Excluded by default; you decide.
- Unidentified Resolve operation: Resolve's native tools cannot be fully identified. Blur, noise reduction, masks or qualifiers inside such a node are not detected and would give a wrong LUT.
Detection relies on effect names visible in Resolve; it is not a complete image analysis. A 65³ LUT is an approximation: small differences can appear in extreme colours or next to abrupt transitions. The app does not claim that a LUT looks identical to the DRX; compare them on your own footage.

## 8. If something goes wrong
![failed]
- "DaVinci Resolve is not running": start Resolve Studio and try again.
- "Resolve does not accept the connection": enable external scripting (section 2).
- "Effects missing on this Mac": install the OFX effects used in the DRX, then open the DRX again.
- "The DRX file looks corrupt": export it again from Resolve.
- "The render result is degenerate": usually offline media or a node that destroys the image; no LUT is written.

## 9. Updates, privacy, uninstall
The app checks for updates at launch and verifies the package signature, checksum and version before installing. Your DRX files, LUTs and personal data never leave your Mac; the only network connection is the update check. A local log is kept in ~/Library/Logs/DRXtoLUT.log; Settings can export a redacted diagnostics package that you send yourself if you wish. Settings > "Uninstall the app completely" removes the app and its data.
DRX to LUT is an independent MIT-licensed project, provided "as is", and is not affiliated with Blackmagic Design. It bundles a Python 3.12 runtime; see OPEN_SOURCE_NOTICES.md. Source and issues: https://github.com/gordasgdc/drx-to-lut
