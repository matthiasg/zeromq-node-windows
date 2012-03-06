testFs = require './lib/test-fs'

ariel = require '../lib/ariel'

describe 'mytest3', ->

  it 'should just work', ->
    2.should.equal(2)

  it 'should not work', ->
    3.should.equal(3)

  it 'should test ariel', ->
    ariel.test().should.be.true

  it 'should compile javascript', ->
    #testDir = testFs.createTestDir()
    #testFs.createDummyCoffeeFile testDir    

  it 'should cover more', ->
    ariel.testAnother().should.be.false