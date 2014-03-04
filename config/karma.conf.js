module.exports = function(config){
    config.set({
    basePath : '../',

    files : [
        'app/lib/angular/angular.js',
        'app/lib/angular/angular-*.js',
        'app/lib/jquery/jquery-1.10.2.min.js',
        'app/lib/jquery-ui-1.10.3/ui/jquery-ui.js',
        'app/js/wordlift-plugin.js',
        'test/lib/angular/angular-mocks.js',
        'app/js/**/*.js',
        'test/unit/**/*.js'
    ],

    exclude : [
        'app/lib/angular/angular-loader.js',
        'app/lib/angular/*.min.js',
        'app/lib/angular/angular-scenario.js'
    ],

    autoWatch : true,

    frameworks: ['jasmine'],

    browsers : [
        'Chrome',
        'Firefox',
        'Safari'
    ],

    plugins : [
        'karma-junit-reporter',
        'karma-chrome-launcher',
        'karma-firefox-launcher',
        'karma-safari-launcher',
        'karma-jasmine'
    ],

    junitReporter : {
      outputFile: 'test_out/unit.xml',
      suite: 'unit'
    }

})}
