'use strict'

module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    coffee:
      compile:
        options:
          join: true
          sourceMap: true
        files:
          'app/js/wordlift.js': [
            'src/coffee/app.config.coffee',
            'src/coffee/app.directives.coffee',
            'src/coffee/app.services.AnalysisService.coffee',
            'src/coffee/app.services.EditorService.coffee',
            'src/coffee/app.services.EntityService.coffee',
            'src/coffee/app.services.coffee',
            'src/coffee/app.controllers.coffee',
            'src/coffee/app.coffee'
          ]

    uglify:
      wordlift:
        options:
          sourceMap: 'app/js/wordlift.min.js.map'
          sourceMapIn: 'app/js/wordlift.js.map'
          sourceMappingURL: 'wordlift.min.js.map'
          compress:
            drop_console: true
          dead_code: true
          mangle: true
          beautify: false
        files:
          'app/js/wordlift.min.js': ['app/js/wordlift.js']
          'app/js/wordlift.<%= pkg.version %>.min.js': ['app/js/wordlift.js']

    less:
      development:
        files:
          'src/css/wordlift-admin.css': ['src/less/wordlift-admin.less']
          'src/css/wordlift-editor.css': ['src/less/wordlift-editor.less']
      'wordlift-admin.min':
        options:
          cleancss: true
          sourceMap: true
          sourceMapFilename: 'src/css/wordlift-admin.min.css.map'
        files:
          'src/css/wordlift-admin.min.css': ['src/less/wordlift-admin.less']
      'wordlift-editor.min':
        options:
          cleancss: true
          sourceMap: true
          sourceMapFilename: 'src/css/wordlift-editor.min.css.map'
        files:
          'src/css/wordlift-editor.min.css': ['src/less/wordlift-editor.less']

    copy:
      main:
        expand: true
        cwd: 'src/bower_components/components-font-awesome/fonts/'
        src: '*'
        dest: 'src/fonts/'
        flatten: true
        filter: 'isFile'
      # Copy files to dist folder.
      dist:
        expand: true
        cwd: 'app/js/'
        src: [
          'wordlift.js',
          'wordlift.min.js',
          'wordlift.<%= pkg.version %>.min.js'
        ]
        dest: 'dist/'
        flatten: true

    docco:
      doc:
        src: [
          'src/coffee/**/*.coffee',
          'test/unit/**/*.coffee',
        ]
        options:
          output: 'docs/'

    watch:
      scripts:
        files: ['src/coffee/**/*.coffee']
        tasks: ['coffee', 'uglify', 'docco']
        options:
          spawn: false
      styles:
        files: ['src/less/*.less']
        tasks: ['less']
        options:
          spawn: false

  # Load plugins
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-docco')

  # Default task(s).
  grunt.registerTask('default', ['coffee', 'uglify', 'less', 'copy', 'docco'])
