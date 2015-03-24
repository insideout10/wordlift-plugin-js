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
  }).filter('filterEntitiesByType', [
    '$log', 'configuration', function($log, configuration) {
      return function(items, type) {
        var entity, filtered, id;
        filtered = [];
        for (id in items) {
          entity = items[id];
          if (entity.mainType === type && entity.id !== configuration.entity_uri) {
            filtered.push(entity);
          }
        }
        return filtered;
      };
    }
  ]).controller('FacetedSearchWidgetController', [
    'DataRetrieverService', 'configuration', '$scope', '$log', function(DataRetrieverService, configuration, $scope, $log) {
      $scope.entity = void 0;
      $scope.posts = [];
      $scope.facets = [];
      $scope.conditions = {};
      $scope.supportedTypes = ['thing', 'person', 'organization', 'place', 'event'];
      $scope.isInConditions = function(entity) {
        if ($scope.conditions[entity.id]) {
          return true;
        }
        return false;
      };
      $scope.addCondition = function(entity) {
        $log.debug("Add entity " + entity.id + " to conditions array");
        if ($scope.conditions[entity.id]) {
          delete $scope.conditions[entity.id];
        } else {
          $scope.conditions[entity.id] = entity;
        }
        return DataRetrieverService.load('posts', Object.keys($scope.conditions));
      };
      $scope.$on("postsLoaded", function(event, posts) {
        $log.debug("Referencing posts for entity " + configuration.entity_id + " ...");
        $scope.posts = posts;
        return $log.debug($scope.posts);
      });
      return $scope.$on("facetsLoaded", function(event, facets) {
        var entity, _i, _len;
        $log.debug("Referencing facets for entity " + configuration.entity_id + " ...");
        for (_i = 0, _len = facets.length; _i < _len; _i++) {
          entity = facets[_i];
          if (entity.id === configuration.entity_uri) {
            $scope.entity = entity;
          }
        }
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

  $(container = $("<div ng-controller=\"FacetedSearchWidgetController\">\n      <div class=\"facets\">\n        <fieldset ng-repeat=\"type in supportedTypes\">\n          <legend>{{type}}</legend>\n          <ul>\n            <li ng-class=\"'wl-fs-' + entity.mainType\" class=\"entity\" ng-repeat=\"entity in facets | filterEntitiesByType:type\" ng-click=\"addCondition(entity)\">\n              <i class=\"checkbox\" ng-class=\" { 'selected' : isInConditions(entity) }\" /><i class=\"type\" /><span class=\"label\">{{entity.label}}</span>\n            </li>\n          </ul>\n        </fieldset>\n      </div>\n      <div class=\"posts\">\n        <div class=\"conditions\">\n          Contenuti associati a <strong>{{entity.label}}</strong><br />\n          <span>Filtri:</span>\n          <strong class=\"condition\" ng-repeat=\"(condition, entity) in conditions\">{{entity.label}}. </strong>\n        </div>\n        <div class=\"post\" ng-repeat=\"post in posts\">\n          <a ng-href=\"/?p={{post.ID}}\">{{post.post_title}}</a>\n        </div>   \n      </div>\n      <br class=\"clear\" />\n    </div>").appendTo('#wordlift-faceted-entity-search-widget'), injector = angular.bootstrap($('#wordlift-faceted-entity-search-widget'), ['wordlift.facetedsearch.widget']));

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
