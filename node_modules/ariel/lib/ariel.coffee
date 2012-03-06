fs = require 'fs'
path = require 'path'
file = require 'file'
child = require 'child_process'
util = require 'util'
require 'colors'
CoffeeScript = require 'coffee-script'
tty = require 'tty'
coveraje = require("coveraje").coveraje

module.exports.options = options =
  excludeDirs: ['.git.*', 'bin.*','node_modules.*', 'temp.*', 'tools.*']
  excludeCompileDirs: ['.git.*', 'bin.*','node_modules.*', 'temp.*', 'tools.*'] #,'test.*'] 
  compile: true
  dirPath: process.cwd()
  testRunner: 'mocha'
  coverageRunner: 'coveraje',
  useCoverageServer: true

rootDirPath = ""
filesToCleanup = []
watchedFiles = []
compilationRequests = []
testRequests = []
isRunningTests = no
coverageServer = null
isCoverageServerStarted = no

backslashRegExp = new RegExp("\\\\",'g')

module.exports.test = () -> true
module.exports.testAnother = () ->
  module.exports.watchDir 'FALSE FOLDER'
  
module.exports.watchDir = (dirPath) ->

  if not path.existsSync dirPath
    console.log "Cannot watch '#{dirPath}'. Directory does not exist."
    return false

  rootDirPath = options.dirPath = dirPath   

  console.log "watching dir: #{rootDirPath}"
  
  waitForCompilationRequests()
  waitForTestRequests()
  
  watchRootFolder()
  processRootFolder()

  cleanAllCompiledFilesOnProcessExit()

  queueTest()

  return true
  
waitForCompilationRequests = ->
  setInterval handleCompileRequests, 10

handleCompileRequests = ->
  
  return if isRunningTests

  if compilationRequests.length > 0
    console.log "Compiling...#{compilationRequests.length}".green
  
  requests = compilationRequests
  compilationRequests = []

  for f in requests
    compileFile f

waitForTestRequests = ->
  setInterval handleTestRequests, 250

handleTestRequests = ->

  return if isRunningTests

  if testRequests.length > 0  
       
    if isCoverageServerStarted and coveraje.webserver
        console.log "Stopping coverage server".yellow
        coveraje.webserver.stop()
        isCoverageServerStarted = no

    testRequests = []
    
    try
      isRunningTests = yes
      runTests -> isRunningTests = false
          
    catch error
      console.log "ERROR running test: #{error}".red
    
watchRootFolder = ->
  watchDir rootDirPath, options.excludeDirs

processRootFolder = ->
  processAllFilesInFolder rootDirPath

cleanAllCompiledFilesOnProcessExit = ->
  process.on 'exit', ->
    console.log "Cleaning #{filesToCleanup.length} compiled files."
    
    for filePath in filesToCleanup
      fs.unlinkSync filePath if path.existsSync filePath

processAllFilesInFolder = (dirPath) ->
  handleAllFiles dirPath, options.excludeDirs
  compileAllFiles dirPath, options.excludeCompileDirs
  
enumerateAllFiles = (rootDirPath, excludeDirs, callbackPerFile) ->

  if not excludeDirs
    throw "ERROR MISSING EXCLUDES"

  file.walkSync rootDirPath, (dirPath, dirs, files) ->

    dirName = path.relative rootDirPath, dirPath
    return if isMatchedByAny dirName, excludeDirs

    fullPaths = (path.join(dirPath,p) for p in files)
    fullPaths.forEach (filePath) -> callbackPerFile dirPath, filePath

isMatchedByAny = (str, matchers) ->

  for m in matchers   
    return true if str.match m
  return false

handleDetectedFile = (filePath) ->
  #console.log "detected #{filePath}"
  cleanupFile filePath if isCompiledJavascriptFileForMatchingCoffeeScript(filePath)
  watchFile filePath 

cleanupFile = (filePath) ->
  if filesToCleanup.indexOf(filePath) < 0
    #console.log "will cleanup #{filePath} later"
    filesToCleanup.push filePath 
  
handleAllFiles = (dirPath, excludeDirs) ->
  
  enumerateAllFiles dirPath, excludeDirs, (dirPath, filePath) ->   
    handleDetectedFile filePath     
  
compileAllFiles = (dirPath, excludeDirs) ->
  
  enumerateAllFiles dirPath, excludeDirs, (dirPath, filePath) ->   
    queueFileCompile filePath if isCoffeeScriptFile filePath
  
compileFile = (filePath) ->
    
  if not isCoffeeScriptFile filePath
    console.log "NOT COFFEE:#{filePath}".red

  compileToJavascript(filePath) if isCoffeeScriptFile filePath

queueTest = ->
  if testRequests.length == 0
    testRequests.push 'test'

queueFileCompile = (filePath) ->
  
  return if not options.compile

  if compilationRequests.indexOf(filePath) < 0
    compilationRequests.push filePath

watchDir = (dirPath, excludeDirs) ->
  fs.watch dirPath, (event,filename) ->
    
    return if isRunningTests
    return if isMatchedByAny filename, excludeDirs
    #console.log "CHANGE #{event} -> #{filename}".yellow

    processAllFilesInFolder rootDirPath, excludeDirs    
    queueTest()
  
watchFile = (filePath) ->
  
  return if not path.existsSync filePath
  return if watchedFiles.indexOf(filePath) >= 0
    
  watchedFiles.push filePath

  #console.log "WATCH #{filePath}"
  fs.watch filePath, (event,filename) ->
    #console.log "CHANGE:#{event}:#{filePath}"

    return if isRunningTests    

    if path.existsSync filePath

      if not isCompiledJavascriptFileForMatchingCoffeeScript(filePath) and not isIgnoredCompileFile(filePath)
        queueFileCompile filePath if isCoffeeScriptFile filePath
    
    queueTest()
  
isIgnoredCompileFile = (filePath)->
  relativePath = path.relative rootDirPath, filePath
  isMatchedByAny relativePath, options.excludeCompileDirs

runTests = (cbFinished) ->

  if not path.existsSync 'test'
    console.log "cannot run tests. no 'test' folder.".yellow
    return

  console.log 'running tests...'.green  
  runMocha => 
    console.log 'running coverage...'.green
    runCoveraje options.useCoverageServer, cbFinished
    
runCoveraje = (withServer, cbFinished) ->

  runSingleTest = (file) ->
    return (context) ->
        console.log "running helper #{file}"
        return coveraje.runHelper("mocha", {
                require: "should",
                timeout: 200,
                ui: "bdd",
                globals: [],
                _mocha: context.mocha
        }).run(file)
      
  testFiles = gatherTestFiles( options.dirPath, 'test' )

  runner = {}
  for name,testFilePath of testFiles
    runner[name] = runSingleTest("./#{testFilePath}")

  opts = 
          useServer: withServer,
          globals: "node",
          resolveRequires: ["*"]
  
  rel = path.relative __dirname,process.cwd()
  
  rel = rel.replace(backslashRegExp,'/')
  indexPath = "#{rel}/index.js"
  code = "var root = require('#{indexPath}');"

  coveraje.cover code, runner, opts
  isCoverageServerStarted = withServer
  
  cbFinished() if cbFinished

gatherTestFiles = (rootDirPath, testDir) ->

  testFiles = {}

  startDirPath = path.join rootDirPath, testDir

  file.walkSync startDirPath, (dirPath, dirs, files) ->

    # no recursive tests for now since mocha does not gather them automatically for now
    return if dirPath != startDirPath    
    # console.log "adding #{dirPath}"
    fullPaths = (path.join(dirPath,p) for p in files)
    fullPaths.forEach (filePath) ->

      return if not isTestFile filePath

      testDir = path.dirname filePath
      
      testFilePath = path.join( path.relative(rootDirPath, testDir), path.basename(filePath))
      name = path.join( path.relative(startDirPath, testDir), path.basename(filePath))


      testFilePath = testFilePath.replace(backslashRegExp,'/')
      testFiles[name] = testFilePath
  
  return testFiles

runMocha = (cbFinished)->
   

  try  

    opt = 
      cwd: process.cwd()
      setsid:true
      #customFds: [1,2,3]    
      
    testFiles = gatherTestFiles( options.dirPath, 'test' )
    testFilesPaths = for name of testFiles
      testFiles[name]

    #process.stdin.pause()
    #tty.setRawMode(true);
    mochaPath = path.join( __dirname, '../node_modules/mocha/bin/_mocha' );
    args = [mochaPath].concat(testFilesPaths)

    proc = child.spawn process.argv[0], args, opt
    proc.stdout.pipe process.stdout
    proc.stderr.pipe process.stdout

    #proc.stdout.on 'data', (data)->process.stdout.write(data)
    #proc.stderr.on 'data', (data)->process.stderr.write(data)

    proc.on 'exit', ->
      console.log()
      console.log "Testing completed.".green
      #tty.setRawMode(false);
      cbFinished() if cbFinished
    
  catch error
    console.log "ERROR starting tests >".red
    console.log error
    cbFinished() if cbFinished

compileToJavascript = (filePath) ->

  javascriptFilePath = changeToJavascriptExtension filePath

  if path.existsSync javascriptFilePath
    return if isNewer javascriptFilePath, filePath
    console.log "re-compiling #{filePath} -> #{javascriptFilePath}"
  else
    console.log "compiling #{filePath} -> #{javascriptFilePath}"

  compileCoffeeScriptFileToJavascriptFile filePath, javascriptFilePath
  cleanupFile javascriptFilePath

compileCoffeeScriptFileToJavascriptFile = (coffeePath, jsPath) ->
  
  try
    code = fs.readFileSync(coffeePath).toString()
    compiledJs = CoffeeScript.compile code, getCoffeeScriptOptions(coffeePath)  
    fs.writeFileSync jsPath, compiledJs
  catch error
    console.log "Error compiling #{coffeePath}:".red + error
    fs.unlinkSync jsPath if path.existsSync jsPath
    

  return
  

isNewer = (a, b) ->
  aStats = fs.statSync a
  bStats = fs.statSync b
  
  return aStats.mtime.getTime() > bStats.mtime.getTime()

getCoffeeScriptOptions = (filePath) ->
  filename: filePath,
  bare: yes

isCoffeeScriptFile = (filePath) -> path.extname(filePath) == '.coffee'
isJavascriptFile = (filePath) -> path.extname(filePath) == '.js'
isTestFile = (filePath) -> 
  
  result = filePath.match(/test\.js$/gi)
  result != null

isCompiledJavascriptFileForMatchingCoffeeScript = (filePath) ->
  
  return isJavascriptFile(filePath) and 
         path.existsSync(changeToCoffeeScriptExtension(filePath))
  
changeToCoffeeScriptExtension = (filePath) ->  changeExtension(filePath, '.coffee')
changeToJavascriptExtension = (filePath) ->  changeExtension(filePath, '.js')

changeExtension = (filePath, newExtension) ->  
  
  dirname = path.dirname(filePath)
  oldExtension = path.extname(filePath)
  nameWithoutExtension = path.basename(filePath, oldExtension )

  return path.join( dirname, nameWithoutExtension  + newExtension )

