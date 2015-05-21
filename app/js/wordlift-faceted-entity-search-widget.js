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
  ]).directive('wlTruncate', [
    '$log', function($log) {
      return {
        restrict: 'A',
        scope: {
          text: '=',
          charsThreshold: '='
        },
        link: function($scope, $element, $attrs) {
          var CHARS_THRESHOLD;
          CHARS_THRESHOLD = parseInt($scope.charsThreshold);
          $scope.label = $scope.text;
          if ($scope.text.length > CHARS_THRESHOLD) {
            $scope.label = $scope.text.substr(0, CHARS_THRESHOLD) + ' ...';
          }
          return $element.append($scope.label);
        }
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
        $log.debug(facets);
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
  ]).directive('wlCarousel', [
    '$log', function($log) {
      return {
        restrict: 'A',
        scope: true,
        transclude: true,
        template: "<div ng-transclude></div>\n<br class=\"clear\" />\n<ul>\n<li ng-repeat=\"item in items\">{{item.$id}}</li>\n</ul>\n<h4>{{currentItemId}}</h4>",
        controller: function($scope, $element, $attrs) {
          var ctrl;
          $scope.items = [];
          $scope.startAt = 0;
          $scope.maxItems = 3;
          $scope.calculateDimensions = function() {
            var index, item, _ref, _results;
            _ref = $scope.items;
            _results = [];
            for (index in _ref) {
              item = _ref[index];
              $log.debug(index);
              _results.push($log.debug(item));
            }
            return _results;
          };
          ctrl = this;
          return ctrl.registerItem = function(scope, element) {
            var item;
            item = {
              'scope': scope,
              'element': element
            };
            $scope.items.push(item);
            return $scope.calculateDimensions();
          };
        }
      };
    }
  ]).directive('wlCarouselItem', [
    '$log', function($log) {
      return {
        require: '^wlCarousel',
        restrict: 'A',
        transclude: true,
        template: "<div ng-transclude></div>",
        link: function($scope, $element, $attrs, $ctrl) {
          $log.debug("Going to add item with id " + $scope.$id + " to carousel");
          return $ctrl.registerItem($scope, $element);
        }
      };
    }
  ]).config(function(configurationProvider) {
    return configurationProvider.setConfiguration(window.wl_faceted_search_params);
  });

  $(container = $("<div ng-controller=\"FacetedSearchWidgetController\">\n      <h5>Contenuti associati a <strong>{{entity.label}}</strong></h5>\n      <div class=\"wl-facets\">\n        <div class=\"wl-facets-container\" ng-repeat=\"type in supportedTypes\">\n          <h6 ng-class=\"'wl-fs-' + type\"><i class=\"type\" />{{type}}</h6>\n          <ul>\n            <li class=\"entity\" ng-repeat=\"entity in facets | filterEntitiesByType:type\" ng-click=\"addCondition(entity)\">     \n                <span class=\"wl-label\" ng-class=\" { 'selected' : isInConditions(entity) }\" wl-truncate text=\"entity.label\" chars-threshold=\"100\"></span>\n                <span class=\"counter\">({{entity.counter}})</span>\n            </li>\n          </ul>\n        </div>\n      </div>\n      <div class=\"wl-posts\">\n        <div class=\"wl-conditions\">\n          <span>Filtri:</span>\n          <strong class=\"wl-condition\" ng-repeat=\"(condition, entity) in conditions\">{{entity.label}}. </strong>\n        </div>\n        <div class=\"wl-post\" ng-repeat=\"post in posts\">\n          <a ng-href=\"/?p={{post.ID}}\">{{post.post_title}}</a>\n        </div>   \n      </div>\n     \n    </div>").appendTo('#wordlift-faceted-entity-search-widget'), injector = angular.bootstrap($('#wordlift-faceted-entity-search-widget'), ['wordlift.facetedsearch.widget']));

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
