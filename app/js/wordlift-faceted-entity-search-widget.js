(function() {
  var $, container, injector;

  $ = jQuery;

  angular.module('wordlift.facetedsearch.widget', []).provider("configuration", function() {
    var provider, _configuration;
    _configuration = void 0;
    provider = {
      setConfiguration: function(configuration) {
        return _configuration = configuration;
      },
      $get: function() {
        return _configuration;
      }
    };
    return provider;
  }).controller('FacetedSearchWidgetController', ['configuration', '$scope', '$log', function(configuration, $scope, $log) {}]).service('DataRetrieverService', [
    'configuration', '$log', '$http', '$rootScope', function(configuration, $log, $http, $rootScope) {
      var service;
      service = {};
      service.load = function(type, conditions) {
        var uri;
        if (conditions == null) {
          conditions = {};
        }
        uri = "" + configuration.ajax_url + "?action=" + configuration.action + "&entity_id=" + configuration.entity_id + "&type=" + type;
        $log.debug("Going to ask posts at uri " + uri);
        return $http({
          method: 'get',
          url: uri
        }).success(function(data) {
          return $rootScope.$broadcast("postsLoaded", data);
        }).error(function(data, status) {
          return $log.warn("Error loading " + type + "s, statut " + status);
        });
      };
      service;
      return service;
    }
  ]).config(function(configurationProvider) {
    return configurationProvider.setConfiguration(window.wl_faceted_search_params);
  });

  $(container = $("<div ng-controller=\"FacetedSearchWidgetController\">\n      <div><h3>Facets</h3></div>\n      <div><h3>Related posts</h3></div>\n    </div>").appendTo('#wordlift-faceted-entity-search-widget'), injector = angular.bootstrap($('#wordlift-faceted-entity-search-widget'), ['wordlift.facetedsearch.widget']));

  injector.invoke([
    'DataRetrieverService', '$rootScope', '$log', function(DataRetrieverService, $rootScope, $log) {
      return $rootScope.$apply(function() {
        return DataRetrieverService.load('posts');
      });
    }
  ]);

}).call(this);

//# sourceMappingURL=wordlift-faceted-entity-search-widget.js.map
