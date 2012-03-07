fs = require 'fs'
file = require 'file'
wrench = require 'wrench'
path = require 'path'

tempRoot = path.join process.cwd(), 'tempTest'
hasRegisteredForDeletingTempRoot = no

module.exports.createTestDir = ->
  
  createTempRoot()

  i = 0
  while true
    i++
    testDirPath = path.join tempRoot, "test-#{i}"
    continue if path.existsSync testDirPath    
    
    fs.mkdirSync testDirPath    
    return testDirPath

createTempRoot =  ->  
  fs.mkdirSync tempRoot if not path.existsSync tempRoot
  deleteTempRootOnExit() if not hasRegisteredForDeletingTempRoot

deleteTempRootOnExit = ->
  process.on 'exit', -> removeDir tempRoot
  hasRegisteredForDeletingTempRoot = yes
 
removeDir = (dirPath) ->
  
  console.log 'removing dir'
  failSilently = true
  wrench.rmdirSyncRecursive dirPath, failSilently

module.exports.createDummyCoffeeFile = (dirPath) ->

  file.mkdirsSync dirPath if not path.existsSync dirPath

  i = 0
  while true
    i++
    
    dummyPath = path.join dirPath, "dummy-#{i}.coffee"
    continue if path.existsSync dummyPath    
    
    fs.writeFileSync dummyPath, '### DUMMY FILE #' + "#{i}"
    return dummyPath
