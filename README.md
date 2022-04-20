# AS2Delaunay
An AS2 backport of Alan Shaw's AS3 Delaunay library.

# More About Alan Shaw's AS3 Delaunay library
I want to start this off by thanking Alan Shaw, Amit Patel, and Justin Walsh for their work on the original AS3 Delaunay library, built for several geometric functions in AS3, focusing largely on Delaunay triangulation and Voronoi diagrams. The original library is [available here](https://github.com/nodename/as3delaunay), with [more detailed info here](https://nodename.github.io/as3delaunay/).

# FAQ
### AS2? In 2022? But why?
In 2022, Newgrounds hosted their second annual Flash Forward Jam, a game jam inviting users to build a game in Flash, playable through the [Ruffle Flash emulator](https://ruffle.rs/). At this point in time, Ruffle is only compatible with AS2. My game for the jam revolves around using Voronoi tesselation as a map for entities to traverse. While I wasn't able to finish the game in time, I intend to still finish it, and wanted to make all my code available a little bit at a time. 
### What are the key differences between the AS3 and AS2 versions?
My biggest focus on this project was purely backporting the code from AS3 to AS2, leaving the way it was originally written largely intact. This meant stripping out AS3-exclusive keywords and functionalities (i.e. class behaviors). Aside from those changes, the two versions are functionally equal.
### How would I go about using this in my own projects?
First off, I'd take a few minutes to seriously consider whether AS2 is worth sticking with. Nobody's stopping you (especially if your heart is set on Flash, and you want to ensure your work is compatible with the Ruffle player), but unless you're part of that very small number of folks making games for these Ruffle-focused game jams, I'd check out newer tools, like Unity or Unreal. That said, if you truly have a passion for emulators of platforms old enough to serve in the military, check out the example .fla!
