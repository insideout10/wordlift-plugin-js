(function() {
  var $, container, injector;

  angular.module('wordlift.ui.carousel', []).directive('wlCarousel', [
    '$window', '$log', function($window, $log) {
      return {
        restrict: 'A',
        scope: true,
        transclude: true,
        template: "<div class=\"wl-carousel\" ng-show=\"panes.length > 0\">\n  <div class=\"wl-panes\" style=\"width:{{panesWidth}}px; left:{{position}}px;\" ng-transclude ng-swipe-right=\"next()\"></div>\n  <div class=\"wl-carousel-arrow wl-prev\" ng-click=\"prev()\" ng-show=\"currentPaneIndex > 0\">\n    <i class=\"wl-angle-left\" />\n  </div>\n  <div class=\"wl-carousel-arrow wl-next\" ng-click=\"next()\" ng-hide=\"(currentPaneIndex + visibleElements()) == panes.length\">\n    <i class=\"wl-angle-right\" />\n  </div>\n</div>  ",
        controller: function($scope, $element, $attrs) {
          var ctrl, w;
          w = angular.element($window);
          $scope.visibleElements = function() {
            if ($element.width() > 460) {
              return 3;
            }
            if ($element.width() > 1024) {
              return 5;
            }
            return 1;
          };
          $scope.itemWidth = $element.width() / $scope.visibleElements();
          $scope.panesWidth = void 0;
          $scope.panes = [];
          $scope.position = 0;
          $scope.currentPaneIndex = 0;
          $scope.next = function() {
            $scope.position = $scope.position - $scope.itemWidth;
            return $scope.currentPaneIndex = $scope.currentPaneIndex + 1;
          };
          $scope.prev = function() {
            $scope.position = $scope.position + $scope.itemWidth;
            return $scope.currentPaneIndex = $scope.currentPaneIndex - 1;
          };
          $scope.setPanesWrapperWidth = function() {
            $scope.panesWidth = $scope.panes.length * $scope.itemWidth;
            $scope.position = 0;
            return $scope.currentPaneIndex = 0;
          };
          w.bind('resize', function() {
            var pane, _i, _len, _ref;
            $scope.itemWidth = $element.width() / $scope.visibleElements();
            $scope.setPanesWrapperWidth();
            _ref = $scope.panes;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              pane = _ref[_i];
              pane.scope.setWidth($scope.itemWidth);
            }
            return $scope.$apply();
          });
          ctrl = this;
          ctrl.registerPane = function(scope, element) {
            var pane;
            scope.setWidth($scope.itemWidth);
            pane = {
              'scope': scope,
              'element': element
            };
            $scope.panes.push(pane);
            return $scope.setPanesWrapperWidth();
          };
          return ctrl.unregisterPane = function(scope) {
            var index, pane, unregisterPaneIndex, _i, _len, _ref;
            unregisterPaneIndex = void 0;
            _ref = $scope.panes;
            for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
              pane = _ref[index];
              if (pane.scope.$id === scope.$id) {
                unregisterPaneIndex = index;
              }
            }
            $scope.panes.splice(unregisterPaneIndex, 1);
            return $scope.setPanesWrapperWidth();
          };
        }
      };
    }
  ]).directive('wlCarouselPane', [
    '$log', function($log) {
      return {
        require: '^wlCarousel',
        restrict: 'EA',
        transclude: true,
        template: "<div ng-transclude></div>",
        link: function($scope, $element, $attrs, $ctrl) {
          $log.debug("Going to add carousel pane with id " + $scope.$id + " to carousel");
          $element.addClass("wl-carousel-item");
          $scope.setWidth = function(size) {
            return $element.css('width', "" + size + "px");
          };
          $scope.$on('$destroy', function() {
            $log.debug("Destroy " + $scope.$id);
            return $ctrl.unregisterPane($scope);
          });
          return $ctrl.registerPane($scope, $element);
        }
      };
    }
  ]);

  angular.module('wordlift.utils.directives', []).directive('wlSrc', [
    '$window', '$log', function($window, $log) {
      return {
        restrict: 'A',
        priority: 99,
        link: function($scope, $element, $attrs, $ctrl) {
          return $element.bind('error', function() {
            if ($attrs.src !== $attrs.wlSrc) {
              $log.warn("Error on " + $attrs.src + "! Going to fallback on " + $attrs.wlSrc);
              return $attrs.$set('src', $attrs.wlSrc);
            }
          });
        }
      };
    }
  ]);

  $ = jQuery;

  angular.module('wordlift.facetedsearch.widget', ['wordlift.ui.carousel', 'wordlift.utils.directives']).provider("configuration", function() {
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
      $scope.configuration = configuration;
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
        return $scope.posts = posts;
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

  $(container = $("	<div ng-controller=\"FacetedSearchWidgetController\">\n    <h5>Contenuti associati a <strong>{{entity.label}}</strong></h5>\n    <div class=\"wl-facets\" wl-carousel>\n      <div class=\"wl-facets-container\" ng-repeat=\"type in supportedTypes\" wl-carousel-pane>\n        <h6 ng-class=\"'wl-fs-' + type\"><i class=\"type\" />{{type}}</h6>\n        <ul>\n          <li class=\"entity\" ng-repeat=\"entity in facets | filterEntitiesByType:type\" ng-click=\"addCondition(entity)\">     \n              <span class=\"wl-label\" ng-class=\" { 'selected' : isInConditions(entity) }\">{{entity.label}}</span>\n              <span class=\"counter\">({{entity.counter}})</span>\n          </li>\n        </ul>\n      </div>\n    </div>\n    <div class=\"wl-posts\">\n      <div class=\"wl-conditions\">\n        <span>Filtri:</span>\n        <strong class=\"wl-condition\" ng-repeat=\"(condition, entity) in conditions\">{{entity.label}}. </strong>\n      </div>\n      <div wl-carousel>\n        <div class=\"wl-post wl-card\" ng-repeat=\"post in posts\" wl-carousel-pane>\n          <img ng-src=\"{{post.thumbnail}}\" wl-src=\"{{configuration.defaultThumbnailPath}}\" />\n          <div class=\"wl-card-title\"> \n            <a ng-href=\"/?p={{post.ID}}\">{{post.post_title}}</a>\n          </div>\n        </div>\n      </div>\n\n    </div>\n   \n  </div>").appendTo('#wordlift-faceted-entity-search-widget'), injector = angular.bootstrap($('#wordlift-faceted-entity-search-widget'), ['wordlift.facetedsearch.widget']));

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
