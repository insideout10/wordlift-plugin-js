'use strict';

/* jasmine specs for services go here */

describe('service', function() {
  beforeEach(module('wordlift.tinymce.plugin.services'));

  describe('AnalysisService', function() {
    it('should not be running', inject(function(AnalysisService) {
      expect(AnalysisService.isRunning).toEqual(false);
    }));
  });
});
