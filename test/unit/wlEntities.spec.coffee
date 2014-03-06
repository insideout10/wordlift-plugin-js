'use strict';

# Test directives.
describe 'directives', ->

  beforeEach module('wordlift.tinymce.plugin.directives')

  # Test the wlEntities directive.
  describe 'wlEntities', ->

    scope = undefined
    element = undefined

    # Get the root scope and create a wl-entities element.
    beforeEach inject( ($rootScope) ->
      scope = $rootScope
      element = angular.element '<wl-entities></wl-entities>'
    )

    # Test for the entity to empty.
    it 'should be empty', inject( ($compile) ->

      $compile(element)(scope)
      scope.$digest()

      dump element

      expect(element.text()).toEqual ''
    )
