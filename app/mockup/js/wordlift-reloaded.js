(function() {
  var $, Traslator, container, injector,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Traslator = (function() {
    Traslator.prototype._htmlPositions = [];

    Traslator.prototype._textPositions = [];

    Traslator.prototype._html = '';

    Traslator.prototype._text = '';

    Traslator.create = function(html) {
      var traslator;
      traslator = new Traslator(html);
      traslator.parse();
      return traslator;
    };

    function Traslator(html) {
      this._html = html;
    }

    Traslator.prototype.parse = function() {
      var htmlElem, htmlLength, htmlPost, htmlPre, match, pattern, textLength, textPost, textPre;
      this._htmlPositions = [];
      this._textPositions = [];
      this._text = '';
      this._html = this._html.replace(/&nbsp;/gim, ' ');
      pattern = /([^<]*)(<[^>]*>)([^<]*)/gim;
      textLength = 0;
      htmlLength = 0;
      while (match = pattern.exec(this._html)) {
        htmlPre = match[1];
        htmlElem = match[2];
        htmlPost = match[3];
        textPre = htmlPre + ('</p>' === htmlElem.toLowerCase() ? '\n\n' : '');
        textPost = htmlPost;
        textLength += textPre.length;
        htmlLength += htmlPre.length + htmlElem.length;
        this._htmlPositions.push(htmlLength);
        this._textPositions.push(textLength);
        textLength += textPost.length;
        htmlLength += htmlPost.length;
        this._text += textPre + textPost;
      }
      if ('' === this._text && '' !== this._html) {
        this._text = new String(this._html);
      }
      if (0 === this._textPositions.length || 0 !== this._textPositions[0]) {
        this._htmlPositions.unshift(0);
        return this._textPositions.unshift(0);
      }
    };

    Traslator.prototype.text2html = function(pos) {
      var htmlPos, i, textPos, _i, _ref;
      htmlPos = 0;
      textPos = 0;
      for (i = _i = 0, _ref = this._textPositions.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (pos < this._textPositions[i]) {
          break;
        }
        htmlPos = this._htmlPositions[i];
        textPos = this._textPositions[i];
      }
      return htmlPos + pos - textPos;
    };

    Traslator.prototype.html2text = function(pos) {
      var htmlPos, i, textPos, _i, _ref;
      if (pos < this._htmlPositions[0]) {
        return 0;
      }
      htmlPos = 0;
      textPos = 0;
      for (i = _i = 0, _ref = this._htmlPositions.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (pos < this._htmlPositions[i]) {
          break;
        }
        htmlPos = this._htmlPositions[i];
        textPos = this._textPositions[i];
      }
      return textPos + pos - htmlPos;
    };

    Traslator.prototype.insertHtml = function(fragment, pos) {
      var htmlPos;
      htmlPos = this.text2html(pos.text);
      this._html = this._html.substring(0, htmlPos) + fragment + this._html.substring(htmlPos);
      return this.parse();
    };

    Traslator.prototype.getHtml = function() {
      return this._html;
    };

    Traslator.prototype.getText = function() {
      return this._text;
    };

    return Traslator;

  })();

  window.Traslator = Traslator;

  $ = jQuery;

  angular.module('wordlift.core', []).service('AnalysisService', [
    '$log', '$http', '$rootScope', function($log, $http, $rootScope) {
      var service, _currentAnalysis;
      service = _currentAnalysis = {};
      service.parse = function(data) {
        var annotation, ea, entity, id, _i, _len, _ref, _ref1, _ref2;
        _ref = data.entities;
        for (id in _ref) {
          entity = _ref[id];
          entity.occurrences = 0;
          entity.id = id;
          entity.annotations = {};
          entity.isRelatedToAnnotation = function(annotationId) {
            if (this.annotations[annotationId] != null) {
              return true;
            } else {
              return false;
            }
          };
        }
        _ref1 = data.annotations;
        for (id in _ref1) {
          annotation = _ref1[id];
          _ref2 = annotation.entityMatches;
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            ea = _ref2[_i];
            data.entities[ea.entityId].annotations[id] = annotation;
          }
        }
        return data;
      };
      service.perform = function() {
        return $http({
          method: 'get',
          url: 'assets/sample-response.json'
        }).success(function(data) {
          return $rootScope.$broadcast("analysisPerformed", service.parse(data));
        });
      };
      return service;
    }
  ]).service('ConfigurationService', [
    '$log', '$http', '$rootScope', function($log, $http, $rootScope) {
      var service, _configuration;
      service = _configuration = {};
      service.loadConfiguration = function() {
        return $http({
          method: 'get',
          url: 'assets/sample-widget-configuration.json'
        }).success(function(data) {
          return $rootScope.$broadcast("configurationLoaded", data);
        });
      };
      return service;
    }
  ]).controller('coreController', [
    '$log', '$scope', '$rootScope', function($log, $scope, $rootScope) {
      $scope.configuration = [];
      $scope.analysis = {};
      $scope.entitySelection = {};
      $scope.occurences = {};
      $scope.annotation = void 0;
      $scope.boxes = [];
      $scope.$on("configurationLoaded", function(event, configuration) {
        var box, _i, _len, _ref;
        _ref = configuration.classificationBoxes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          box = _ref[_i];
          $scope.entitySelection[box.id] = {};
        }
        return $scope.configuration = configuration;
      });
      $scope.$on("analysisPerformed", function(event, analysis) {
        $log.debug(analysis);
        return $scope.analysis = analysis;
      });
      return $scope.onSelectedEntityTile = function(entity, scope) {
        $log.debug("Entity tile selected for entity " + entity.id + " within '" + scope + "' scope");
        if ($scope.entitySelection[scope][entity.id] == null) {
          $scope.entitySelection[scope][entity.id] = entity;
          return $log.debug($scope.entitySelection);
        } else {
          return delete $scope.entitySelection[scope][entity.id];
        }
      };
    }
  ]).directive('wlClassificationBox', [
    '$log', function($log) {
      return {
        restrict: 'E',
        scope: true,
        template: "    	<div class=\"classification-box\">\n    		<div class=\"box-header\">\n          <h5 class=\"label\">{{box.label}}</h5>\n          <span ng-class=\"'wl-' + entity.mainType\" ng-repeat=\"(id, entity) in entitySelection[box.id]\" class=\"wl-selected-item\">\n            {{ entity.label}}\n            <i class=\"wl-deselect-item\" ng-click=\"onSelectedEntityTile(entity, box.id)\"></i>\n          </span>\n        </div>\n	<wl-entity-tile notify=\"onSelectedEntityTile(entity.id, box.id)\" entity=\"entity\" ng-repeat=\"entity in entities\"></wl-entity>\n</div>	",
        link: function($scope, $element, $attrs, $ctrl) {
          var entity, id, _ref, _ref1, _results;
          $scope.entities = {};
          _ref = $scope.analysis.entities;
          _results = [];
          for (id in _ref) {
            entity = _ref[id];
            if (_ref1 = entity.mainType, __indexOf.call($scope.box.registeredTypes, _ref1) >= 0) {
              _results.push($scope.entities[id] = entity);
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        },
        controller: function($scope, $element, $attrs) {
          var ctrl;
          $scope.tiles = [];
          $scope.$watch("annotation", function(annotationId) {
            var tile, _i, _len, _ref, _results;
            $log.debug("annotation " + annotationId);
            if (annotationId == null) {
              return;
            }
            _ref = $scope.tiles;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              tile = _ref[_i];
              _results.push(tile.isVisible = tile.entity.isRelatedToAnnotation(annotationId));
            }
            return _results;
          });
          ctrl = {
            onSelectedTile: function(tile) {
              return $scope.onSelectedEntityTile(tile.entity, $scope.box.id);
            },
            addTile: function(tile) {
              $log.debug("Adding tile with id " + tile.$id);
              return $scope.tiles.push(tile);
            },
            closeTiles: function() {
              var tile, _i, _len, _ref, _results;
              _ref = $scope.tiles;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                tile = _ref[_i];
                _results.push(tile.close());
              }
              return _results;
            }
          };
          return ctrl;
        }
      };
    }
  ]).directive('wlEntityTile', [
    '$log', function($log) {
      return {
        require: '^wlClassificationBox',
        restrict: 'E',
        scope: {
          entity: '='
        },
        template: "<div ng-class=\"wrapperCssClasses\" ng-show=\"isVisible\">\n  <i class=\"type\"></i>\n        <span class=\"label\" ng-click=\"select()\">{{entity.label}}</span>\n        <small ng-show=\"entity.occurrences > 0\">({{entity.occurrences}})</small>\n        <i ng-class=\"{ 'wl-more': isOpened == false, 'wl-less': isOpened == true }\" ng-click=\"toggle()\"></i>\n  <div class=\"details\" ng-show=\"isOpened\">\n          <p><img class=\"thumbnail\" ng-src=\"{{ entity.images[0] }}\" />{{entity.description}}</p>\n        </div>\n</div>\n",
        link: function($scope, $element, $attrs, $ctrl) {
          $ctrl.addTile($scope);
          $scope.isOpened = false;
          $scope.isVisible = true;
          $scope.wrapperCssClasses = ["entity", "wl-" + $scope.entity.mainType];
          $scope.open = function() {
            return $scope.isOpened = true;
          };
          $scope.close = function() {
            return $scope.isOpened = false;
          };
          $scope.toggle = function() {
            if (!$scope.isOpened) {
              $ctrl.closeTiles();
            }
            return $scope.isOpened = !$scope.isOpened;
          };
          return $scope.select = function() {
            return $ctrl.onSelectedTile($scope);
          };
        }
      };
    }
  ]);

  $(container = $("<div id=\"wordlift-edit-post-wrapper\" ng-controller=\"coreController\">\n	<wl-classification-box ng-repeat=\"box in configuration.classificationBoxes\"></wl-classification-box>\n    <hr />\n    <h3>{{box}}</h3>\n    <div ng-repeat=\"(b, e) in entitySelection['what']\">      \n      <span>{{ e.label}}</span>\n    </div>\n    <button ng-click=\"annotation = 'urn:enhancement-1f83847a-95c2-c81b-cba9-f958aed45b34'\"></button>\n    </div>\n").appendTo('#dx'));

  injector = angular.bootstrap($('body'), ['wordlift.core']);

  injector.invoke([
    'ConfigurationService', 'AnalysisService', '$rootScope', function(ConfigurationService, AnalysisService, $rootScope) {
      return $rootScope.$apply(function() {
        AnalysisService.perform();
        return ConfigurationService.loadConfiguration();
      });
    }
  ]);

}).call(this);

//# sourceMappingURL=wordlift-reloaded.js.map
