# MacHelix

A proof-of-concept GUI wrapper around the terminal based editor [Helix](https://helix-editor.com/)

![MacHelix main window](./media/MacHelixMainWindow.png)

## Background

I became interested in Helix while searching for alternatives to JetBrains' AppCode after it was 
announced that it would be no longer be developed. There's a lot to like, but personally I 
prefer my editor to support standard operating system affordances such as access to the system
clipboard, drag-and-drop (including a draggable proxy icon), etc. I have been using vim for 
years on the Mac - mainly through the excellent MacVim. I wanted the same thing for Helix. 
Discussions on developing a gui wrapper for Helix are ongoing, but so far, afaik, development
has not yet started.

So I had the idea that maybe I could do a sort of poor-man's wrapper by embedding a terminal
in a Mac app to run Helix in, and communicating between the wrapper app and Helix via some sort
of IPC. MacHelix is the result.

## Current Features

- Drag and drop
- Titlebar shows filename and draggable proxy icon for the file in the active view
- Copy/Paste with ⌘C and ⌘V
- Select All with ⌘A
- Window background changes with helix theme changes

## Status

The project is prototype quality. It exists mainly to satisfy my curiosity that such an app is
possible/practical. It will take quite a bit of work to bring this to production quality. It 
includes an embedded custom build of `hx` with rudimentary IPC implemented via named pipes.

The terminal layer comes from my fork of [SwiftTerm](https://github.com/humblehacker/SwiftTerm),
with some really rough fixes for sgr mouse support (with code borrowed from 
[iTerm](https://github.com/gnachman/iTerm2)).
