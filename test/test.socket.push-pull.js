
var zmq = require('../')
  , should = require('should');

var pull = zmq.socket('pull')
  , push = zmq.socket('push');

pull.on('message', function(msg){
  msg.should.be.an.instanceof(Buffer);
  msg.toString().should.equal('hello');

  pull.close();
  push.close();
});

//var address = 'inproc://stuff'
var address = 'tcp://127.0.0.1:8978'

push.bind(address, function(){
  pull.connect(address);
  
  setTimeout(function(){
    push.send('hello');
  }, 1);

});