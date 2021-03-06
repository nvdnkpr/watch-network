fs  = require 'fs'
del = require 'del'

{spawn} = require 'child_process'

describe 'WatchNetwork Feature', ->
  watch = null
  listenProcess = null
  beforeEach (done) ->
    if fs.existsSync './tmp'
      del.sync './tmp', force: true
    fs.mkdirSync './tmp'

    listenProcess = spawn "listen", ["-d", "./tmp"]
    setTimeout ->
      done()
    , 500


  afterEach (done) ->
    listenProcess.on 'close', ->
      setTimeout ->
        del.sync './tmp', force: true
        done()
      , 500
    listenProcess.kill 'SIGTERM'


  it 'should execute tasks based on file patterns', (done) ->
    niftyTaskCalled = false

    gulp = require 'gulp'
    gulp.task 'nifty', (next) ->
      niftyTaskCalled = true
      next()

    WatchNetwork = require './'
    watch = WatchNetwork
      gulp: gulp
      rootFile: './tmp/.root'
      configs: [
        {
          patterns: '**/*.ext'
          tasks: 'nifty'
        }
      ]

    niftyMatched = false
    watch.on 'changed', (files) ->
      niftyIndex = files.indexOf 'file.ext'
      if niftyIndex > -1 and not niftyMatched
        niftyMatched = true
        expect(files[niftyIndex]).to.equal 'file.ext'
        expect(niftyTaskCalled).to.be.true
        watch.stop()
        done()

    watch.initialize ->
      fs.writeFileSync './tmp/file.ext'


  it 'should execute the tasks in series', (done) ->
    firstTaskCalled = false
    secondTaskCalled = false

    gulp = require 'gulp'
    gulp.task 'first', (next) ->
      firstTaskCalled = true
      setTimeout ->
        expect(secondTaskCalled).to.be.false
        next()
      , 250

    gulp.task 'second', ->
      secondTaskCalled = true
      expect(firstTaskCalled).to.be.true
      watch.stop()
      done()


    WatchNetwork = require './'
    watch = WatchNetwork
      gulp: gulp
      rootFile: './tmp/.root'
      configs: [
        {
          patterns: 'foo'
          tasks: ['first', 'second']
        }
      ]

    watch.initialize ->
      fs.writeFileSync './tmp/foo'
