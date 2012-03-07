
var zmq = require('..')
  , should = require('should');

var pull = zmq.socket('pull')
  , push = zmq.socket('push');

var start;
var end;
var messageCount=1000;
var messagesReceived=0;

pull.on('message', function(msg){

  //console.log('on message');
  msg.should.be.an.instanceof(Buffer);
  msg.toString().should.equal('hello');

  messagesReceived++;

  if(messagesReceived == messageCount) {
    end = new Date();

    var ms = end.getTime()-start.getTime();
    var messagesPerSecond = messageCount / (ms/1000);

    console.log("done:" + ms + " msg/s=" + messagesPerSecond);
    pull.close();
    push.close();
  }
});

//var address = 'inproc://stuff'
var address = 'tcp://127.0.0.1:8978'

push.bind(address, function(){
  pull.connect(address);

  start = new Date();
  setTimeout(function(){
    console.log('sending work');

    for(var i=0;i<messageCount;i++)
      push.send('hello');
  }, 1);

  
});