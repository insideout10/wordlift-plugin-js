(function() {
  var $, container, injector,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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
  }).filter('filterEntitiesByType', [
    '$log', function($log) {
      return function(items, type) {
        var entity, filtered, id;
        filtered = [];
        $log.debug("andiamo");
        for (id in items) {
          entity = items[id];
          if (entity.mainType === type) {
            filtered.push(entity);
          }
        }
        return filtered;
      };
    }
  ]).controller('FacetedSearchWidgetController', [
    'DataRetrieverService', 'configuration', '$scope', '$log', function(DataRetrieverService, configuration, $scope, $log) {
      $scope.posts = [];
      $scope.facets = [];
      $scope.conditions = [];
      $scope.supportedTypes = ['thing', 'person', 'organization', 'place', 'event'];
      $scope.isInConditions = function(entity) {
        var _ref;
        return (_ref = entity.id, __indexOf.call($scope.conditions, _ref) >= 0);
      };
      $scope.addCondition = function(entity) {
        var _ref;
        $log.debug("Add entity " + entity.id + " to conditions array");
        if (_ref = entity.id, __indexOf.call($scope.conditions, _ref) >= 0) {
          $scope.conditions.splice($scope.conditions.indexOf(entity.id), 1);
        } else {
          $scope.conditions.push(entity.id);
        }
        return DataRetrieverService.load('posts', $scope.conditions);
      };
      $scope.$on("postsLoaded", function(event, posts) {
        $log.debug("Referencing posts for entity " + configuration.entity_id + " ...");
        $log.debug(posts);
        return $scope.posts = posts;
      });
      return $scope.$on("facetsLoaded", function(event, facets) {
        $log.debug("Referencing facets for entity " + configuration.entity_id + " ...");
        $log.debug(facets);
        return $scope.facets = facets;
      });
    }
  ]).service('DataRetrieverService', [
    'configuration', '$log', '$http', '$rootScope', function(configuration, $log, $http, $rootScope) {
      var service;
      service = {};
      service.load = function(type, conditions) {
        var uri;
        if (conditions == null) {
          conditions = [];
        }
        uri = "" + configuration.ajax_url + "?action=" + configuration.action + "&entity_id=" + configuration.entity_id + "&type=" + type;
        $log.debug("Going to search " + type + " with conditions");
        $log.debug(conditions);
        return $http({
          method: 'post',
          url: uri,
          data: conditions
        }).success(function(data) {
          return $rootScope.$broadcast("" + type + "Loaded", data);
        }).error(function(data, status) {
          return $log.warn("Error loading " + type + ", statut " + status);
        });
      };
      return service;
    }
  ]).config(function(configurationProvider) {
    return configurationProvider.setConfiguration(window.wl_faceted_search_params);
  });

  $(container = $("<div ng-controller=\"FacetedSearchWidgetController\">\n      <div class=\"facets\">\n        <fieldset ng-repeat=\"type in supportedTypes\">\n          <legend>{{type}}</legend>\n          <ul>\n            <li ng-class=\"'wl-fs-' + entity.mainType\" class=\"entity\" ng-repeat=\"entity in facets | filterEntitiesByType:type\" ng-click=\"addCondition(entity)\">\n              <i class=\"checkbox\" ng-class=\" { 'selected' : isInConditions(entity) }\" /><i class=\"type\" /><span class=\"label\">{{entity.label}}</span>\n            \n            </li>\n          </ul>\n        </fieldset>\n      </div>\n      <div class=\"posts\">\n        <div class=\"post\" ng-repeat=\"post in posts\">{{post.post_title}}</div>   \n      \n      <div class=\"conditions\">\n        <h5>Filtri</h5>\n        <span ng-repeat=\"condition in conditions\"><small>{{condition}}</small></span>\n      </div>\n      </div>\n      <br class=\"clear\" />\n    </div>").appendTo('#wordlift-faceted-entity-search-widget'), injector = angular.bootstrap($('#wordlift-faceted-entity-search-widget'), ['wordlift.facetedsearch.widget']));

  injector.invoke([
    'DataRetrieverService', '$rootScope', '$log', function(DataRetrieverService, $rootScope, $log) {
      return $rootScope.$apply(function() {
        DataRetrieverService.load('posts');
        return DataRetrieverService.load('facets');
      });
    }
  ]);

}).call(this);

//# sourceMappingURL=wordlift-faceted-entity-search-widget.js.map
