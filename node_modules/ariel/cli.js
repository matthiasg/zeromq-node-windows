var argv = require('optimist')
            .default('dir', process.cwd())
            .default('coverageConsole', false)
            .alias('cc', 'coverageConsole')
            .argv;

require('coffee-script');
require('colors');

var ariel = require('./lib/ariel');

module.exports.run = function() {
  
  console.log("PRESS CTRL-C to stop.".yellow);
  
  ariel.options.useCoverageServer = !argv.coverageConsole  
  ariel.watchDir( argv.dir );

  waitForCtrlC();
}

waitForCtrlC = function() {
  
  process.stdin.resume();
  require('tty').setRawMode(true);

  process.stdin.on('keypress', function(letter,key){
    
    if(key && key.ctrl & key.name === 'c'){
      process.exit();
    }

  });

}

