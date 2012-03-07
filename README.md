zmq-windows
===========

I needed a version of [zmq][z] 2.* bindings that would work under windows and found some projects ([JustinTulloss/zeromq.node][jtzn] and the windows branch of [mojodna/zeromq.node][mzn]) that were almost there. In combination with [node-gyp][ng] and [bindings][bn] i seem to have gotten it working. It is far from perfect and mostly untested, though the tests work and i get about ~15000 messages/s on my machine, single threaded, push/pull via tcp.

  [z]: http://www.zeromq.org/

  [jtzn]: https://github.com/JustinTulloss/zeromq.node
  [mzn]: https://github.com/mojodna/zeromq.node

  [ng]: https://github.com/TooTallNate/node-gyp
  [bn]: https://github.com/TooTallNate/node-bindings

Usage
-----
The api is identical to the [zeromq.node][jtzn] driver.

Compilation
-----------
If you want to compile the project, check it out and install node-gyp 

  npm install -g node-gyp 
  node-gyp configure 

The build folder should contain the vcproj then which could be built with node-gyp build sadly the generated vcproj seems to have an error and uses $(Configuration) instead of $(ConfigurationName) which, at least on my machines is not defined. Thus i change the vcproj file after running configure and replace *$(Configuration)* with *$(ConfigurationName)*. I created a [ticket][gypt] for this.

  [gypt]: https://github.com/TooTallNate/node-gyp/issues/35

After patching you can run:

  node-gyp build

which will build a release file and place it under build\Release.
This is the file used by default by the tests and example.

If you want to require the package you have to copy the zeromq.node file from build\Release to compiled\0.6\win32\ia32 as described by [bindings][bn].

  
Changes
=======

Apart from fixing the vcproj i made a few changes to:

bindings.cc
------------

  * I rewrote the Socket::UV_CheckFDState to use a timer and thus change the rest accordingly
    It uses a millisecond timer to check the socket state for new infos, dispatches it as before but before
    returning to the timer it repeats the check if more data has already queued up and dispatches that. If the 
    poll does not return any data i simply return into the event loop. So the initial latency should be 1ms, with
    more messages being faster if they batch up.

  * I changed the binding name from 'binding' to 'zeromq'. In the bindings.cc.

zeromq.gyp
----------

A small windows only gyp file.