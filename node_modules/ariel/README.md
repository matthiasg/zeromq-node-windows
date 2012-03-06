Ariel
=====
As in 'The Tempest' [Ariel][w] is a the magicians eyes and ears, dutifully watching code and listening to coverage going up and down. 

Getting Started
---------------

    npm install ariel

create a *mocha.opts* file in your local 'test' directory.
Should look something like

    --require should 
    --reporter tap
    --ui bdd
    --growl

if you want to write and test coffee-script then do

    npm install coffee-script 

create an index.js importing all relevant modules from your lib folder. These will be inspected for coverage.
write your mocha tests in the 'test' directory. You can write them in coffee script or javascript. 

start ariel from "node_modules/.bin"

or if you have ./node_modules/.bin" in your path then just type:

	ariel

Running
-------

When ariel starts it compiles all coffee files into js files in order to allow
for coverage and easier debugging (line number matches and coffee compiler issues).
These automatically compiled files are deleted when ariel is exited (CTRL-C). It will recompile whenever a change is detected to a coffee file.

Whenever a test is detected or a change to any source file is detected a re-run of all tests is initiated and coverage is recalculated.

You can look at coverage in the webbrowser. The url is written to the console. only files included from index.js in the root are covered, so make sure you
require them from there.

Command Line Arguments
----------------------
--cc or --coverageConsole will output coverage to the console as a single metric instead of starting the server


Based On
--------
The awesome coveraje (had to bundle it though since i had to make a minor change which i will try to push into the original)
mocha
optimist
...


[w]: http://en.wikipedia.org/wiki/Ariel_(The_Tempest)

[![Build Status](https://secure.travis-ci.org/matthiasg/node-ariel.png?branch=master)](http://travis-ci.org/matthiasg/node-ariel)

Other tools that might come in handy
====================================

[Growl][g] ([Windows][gw]) with [Risor][gr] installed is very helpful. I like Risor because i find it more apparent and yet unobtrusive than getting a similiar bar from the top :). Dont forget to install [growlnotify][gn] on windows (i also put it into dev-tools though.)

[g]: http://www.growl.info
[gw]: http://www.growlforwindows.com
[gr]: http://www.growlforwindows.com/gfw/displays/risor
[gn]: http://www.growlforwindows.com/gfw/help/growlnotify.aspx


