ariel = require '../../lib/ariel'

console.log 'console.log "RUNNING3"'

describe 'mytest2', ->

  it 'should just work', ->
    2.should.equal(2)

  it 'should not work', ->
    3.should.equal(3)

  it 'should test ariel', ->
    ariel.test().should.be.true