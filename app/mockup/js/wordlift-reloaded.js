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
        var annotation, entity, id, match, _i, _len, _ref, _ref1, _ref2;
        _ref = data.entities;
        for (id in _ref) {
          entity = _ref[id];
          entity.occurrences = 0;
        }
        _ref1 = data.annotations;
        for (id in _ref1) {
          annotation = _ref1[id];
          _ref2 = annotation.entityMatches;
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            match = _ref2[_i];
            data.entities[match.entityId]['occurrences'] += 1;
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
      $scope.$on("configurationLoaded", function(event, configuration) {
        var box, _i, _len, _ref;
        _ref = configuration.classificationBoxes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          box = _ref[_i];
          $scope.entitySelection[box.id] = [];
        }
        return $scope.configuration = configuration;
      });
      $scope.$on("analysisPerformed", function(event, analysis) {
        $log.debug(analysis);
        return $scope.analysis = analysis;
      });
      return $scope.onSelectedEntityTile = function(entityId, scope) {
        $log.debug("Entity tile selected for entity " + entityId + " within '" + scope + "' scope");
        if (__indexOf.call($scope.entitySelection[scope], entityId) < 0) {
          return $scope.entitySelection[scope].push(entityId);
        }
      };
    }
  ]);

  $(container = $('<div id="wordlift-edit-post-wrapper" ng-controller="coreController">\n	<ul ng-repeat="box in configuration.classificationBoxes" class="classification-box">\n		<li>{{box.label}}</li>\n		<ul ng-repeat="(entityId, entity) in analysis.entities">\n			<li ng-click="onSelectedEntityTile( entityId, box.id )" ng-class="\'wl-\' + entity.mainType">{{entity.label}} <small>({{entity.occurrences}})</small></li>\n		</ul>\n	</ul>\n	<hr />\n	<div ng-repeat="(box, ids) in entitySelection">\n		<span>{{ box }}</span> - <span>{{ ids }}</span> \n	</div>\n</div>').appendTo('#dx'));

  injector = angular.bootstrap($('#wordlift-edit-post-wrapper'), ['wordlift.core']);

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
