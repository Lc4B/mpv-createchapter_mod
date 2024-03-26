# createchapter_mod
Chapter maker with ability to export XML chapter file and insert them into MKV file.

## Info
This script was created based entirely on [mpv-createchapter](https://github.com/shinchiro/mpv-createchapter) thanks to the XML export that I preferred. At first I just wanted to make some small private changes, then reading [chapter-make-read.lua](https://github.com/dyphire/mpv-scripts?tab=readme-ov-file#chapter-make-readlua) and [chapters_for_mpv](https://github.com/mar04/chapters_for_mpv) I decided to implement some useful features and changed it to be more customizable for users.

## Features and Changes
* chapter numbering corrected and changed to 2-digit numbering
* prevented the creation of an empty chapter file
* standardized the xml output according to matroskachapters.dtd and uniformed the spacing
* added chapter remove function
* added chapter rename function (mp.input)
* added function to insert chapter file into mkv file (mkvpropedit)
* added config file to customize:
	* chapters name
	* chapters language
	* xml file suffix
	* keybinds
	* (...)

## Usage
Place the [`createchapter_mod.lua`](https://github.com/Lc4B/mpv-createchapter_mod/raw/master/createchapter_mod.lua) file into mpv `scripts` folder and the [`createchapter_mod.conf`](https://github.com/Lc4B/mpv-createchapter_mod/raw/master/createchapter_mod.conf) file into mpv `script-opts` folder.

## Keybind
`Shift-c` - Mark chapters  
`Shift-x` - Remove chapters  
`Shift-e` - Rename chapter  
`Shift-b` - Export xml file  
`Shift-n` - Insert xml into mkv  

## Details
Depending on the chapter name you use, mpv may not show the 2-digit numbering, but it would still be written correctly in the export file.  
The matroska_format option uses the format down to nanoseconds (as per mkv standard) but does not calculate it, only fills it.  
The insert_matroska function uses mkvpropedit (MKVToolNix tool) to insert chapters only into mkv files (without remuxing), without this it cannot work.  
The script is limited to the current session/file, if it is reloaded it will not be able to access the written file or it will not load the previous chapters not inserted.  
