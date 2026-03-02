# BetterConsoleHistoryMenu

AS3 source codes for Better Console, modified for [Persistent Console History](https://www.nexusmods.com/fallout4/mods/101885).

The interface will work without either Better Console or Persistent Console History.

## Changelog

- add support for console history
- consolehistory / betterconsole are not required to run this console menu
- the console is now resolution independant like the rest of the game menus: no more tiny text on 4k or huge text on 720p
- improved readability: add a slight text shadow so white text is more visible on lighter backgrounds
- improved readability: the background is now slightly darker
- pressing tab no longer selects the "prompt"
- current text is not cleared when console is closed: it is now selected so one can just type and discard, or keep editing
- slightly restyled betterconsole panels: betterconsole panels do not stretch anymore
- linuxified the prompt. Prompt is now customizable in the ConsoleHistory ini
- font sizes, colors, console size and more are now customizable in the ConsoleHistory ini
- include a stupid ini parser so that the settings are available immediately and there is no need to wait for f4se to display correct Style options
- the inis are not required to run this menu
- new fonts_console with JetBrains mono (Iosevka). no more Arial
