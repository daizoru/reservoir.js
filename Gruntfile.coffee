module.exports = ->

  @initConfig

    pkg: @file.readJSON 'package.json'

    coffee: 
      build: 
        files: 
          'lib/main.js': 'src/main.coffee'
    watch:
      coffee:
        files: [ 'src/*.coffee' ]
        tasks: [ 'coffee' ]
        options: debounceDelay: 250


  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-contrib-concat'

  @registerTask 'default', [
    'coffee'
  ]
