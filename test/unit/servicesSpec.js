'use strict';

/* jasmine specs for services go here */

describe('service', function() {
  beforeEach(module("wordlift.tinymce.plugin", {
      setup: function() {
          var f = jasmine.getFixtures();
          f.fixturesPath = 'base';
          f.load('src/test/js/TestFixture.html');
      },
      teardown: function() {
          var f = jasmine.getFixtures();
          f.cleanUp();
          f.clearCache();
      }
  }));
//
  describe('AnalysisService', function() {
    it('should not be running', inject(function(AnalysisService) {
      expect(AnalysisService.isRunning).toEqual(false);
    }));
  });
});
