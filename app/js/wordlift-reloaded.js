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

  angular.module('wordlift.editpost.widget.controllers.EditPostWidgetController', ['wordlift.editpost.widget.services.AnalysisService', 'wordlift.editpost.widget.providers.ConfigurationProvider']).filter('entityTypeIn', [
    '$log', function($log) {
      return function(items, types) {
        var entity, filtered, id, _ref;
        filtered = [];
        for (id in items) {
          entity = items[id];
          if (_ref = entity.mainType, __indexOf.call(types, _ref) >= 0) {
            filtered.push(entity);
          }
        }
        return filtered;
      };
    }
  ]).controller('EditPostWidgetController', [
    'AnalysisService', 'configuration', '$log', '$scope', '$rootScope', '$injector', function(AnalysisService, configuration, $log, $scope, $rootScope, $injector) {
      var box, widget, _i, _j, _len, _len1, _ref, _ref1;
      $scope.configuration = [];
      $scope.analysis = {};
      $scope.newEntity = AnalysisService.createEntity();
      $scope.selectedEntities = {};
      $scope.widgets = {};
      $scope.annotation = void 0;
      $scope.boxes = [];
      $log.debug(configuration);
      _ref = configuration.boxes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        box = _ref[_i];
        $scope.selectedEntities[box.id] = {};
        $scope.widgets[box.id] = {};
        _ref1 = box.registeredWidgets;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          widget = _ref1[_j];
          $scope.widgets[box.id][widget] = [];
        }
      }
      $scope.configuration = configuration;
      $scope.addNewEntityToAnalysis = function() {
        var annotation;
        $scope.analysis.entities[$scope.newEntity.id] = $scope.newEntity;
        annotation = $scope.analysis.annotations[$scope.annotation];
        annotation.entityMatches.push({
          entityId: $scope.newEntity.id,
          confidence: 1
        });
        $scope.analysis.entities[$scope.newEntity.id].annotations[annotation.id] = annotation;
        return $scope.newEntity = AnalysisService.createEntity();
      };
      $scope.$on("updateOccurencesForEntity", function(event, entityId, occurrences) {
        var entities, _ref2, _ref3, _results;
        $log.debug("Occurrences " + occurrences.length + " for " + entityId);
        $scope.analysis.entities[entityId].occurrences = occurrences;
        if ($scope.annotation != null) {
          _ref2 = $scope.selectedEntities;
          for (box in _ref2) {
            entities = _ref2[box];
            $scope.boxes[box].relink($scope.analysis.entities[entityId], $scope.annotation);
          }
        }
        if (occurrences.length === 0) {
          _ref3 = $scope.selectedEntities;
          _results = [];
          for (box in _ref3) {
            entities = _ref3[box];
            delete $scope.selectedEntities[box][entityId];
            _results.push($scope.boxes[box].deselect($scope.analysis.entities[entityId]));
          }
          return _results;
        }
      });
      $scope.$on("textAnnotationClicked", function(event, annotationId) {
        $log.debug("click on " + annotationId);
        return $scope.annotation = annotationId;
      });
      $scope.$on("textAnnotationAdded", function(event, annotation) {
        $log.debug("added a new annotation with Id " + annotation.id);
        $scope.analysis.annotations[annotation.id] = annotation;
        $scope.annotation = annotation.id;
        return $scope.newEntity.label = annotation.text;
      });
      $scope.$on("analysisPerformed", function(event, analysis) {
        return $scope.analysis = analysis;
      });
      $scope.$on("updateWidget", function(event, widget, scope) {
        var items, retriever;
        $log.debug("Going to updated widget " + widget + " for box " + scope);
        retriever = $injector.get("" + widget + "DataRetrieverService");
        items = retriever.loadData($scope.selectedEntities[scope]);
        return $scope.widgets[scope][widget] = items;
      });
      return $scope.onSelectedEntityTile = function(entity, scope) {
        var id, _ref2;
        $log.debug("Entity tile selected for entity " + entity.id + " within '" + scope.id + "' scope");
        _ref2 = $scope.boxes;
        for (id in _ref2) {
          box = _ref2[id];
          box.closeWidgets();
        }
        if ($scope.selectedEntities[scope.id][entity.id] == null) {
          $scope.selectedEntities[scope.id][entity.id] = entity;
          return $scope.$emit("entitySelected", entity, $scope.annotation);
        } else {
          return $scope.$emit("entityDeselected", entity, $scope.annotation);
        }
      };
    }
  ]);

  angular.module('wordlift.editpost.widget.directives.wlClassificationBox', []).directive('wlClassificationBox', [
    '$log', function($log) {
      return {
        restrict: 'E',
        scope: true,
        transclude: true,
        template: "<div class=\"classification-box\">\n	<div class=\"box-header\">\n          <h5 class=\"label\">{{box.label}}\n            <span class=\"wl-suggestion-tools\" ng-show=\"hasSelectedEntities()\">\n              <i ng-class=\"'wl-' + widget\" title=\"{{widget}}\" ng-click=\"toggleWidget(widget)\" ng-repeat=\"widget in box.registeredWidgets\" class=\"wl-widget-icon\"></i>\n            </span>\n            <span ng-show=\"isWidgetOpened\" class=\"wl-widget-label\">{{currentWidget}}\n              <i ng-click=\"toggleWidget(currentWidget)\" class=\"wl-deselect-widget\"></i>\n            </span>  \n          </h5>\n          <div ng-show=\"isWidgetOpened\" class=\"box-widgets\">\n            <div ng-show=\"currentWidget == widget\" ng-repeat=\"widget in box.registeredWidgets\">\n              <img ng-click=\"embedImageInEditor(item.uri)\"ng-src=\"{{ item.uri }}\" ng-repeat=\"item in widgets[ box.id ][ widget ]\" />\n            </div>\n          </div>\n          <div class=\"selected-entities\">\n            <span ng-class=\"'wl-' + entity.mainType\" ng-repeat=\"(id, entity) in selectedEntities[box.id]\" class=\"wl-selected-item\">\n              {{ entity.label}}\n              <i class=\"wl-deselect-item\" ng-click=\"onSelectedEntityTile(entity, box)\"></i>\n            </span>\n          </div>\n        </div>\n  			<div class=\"box-tiles\">\n          <div ng-transclude></div>\n  		  </div>\n      </div>	",
        link: function($scope, $element, $attrs, $ctrl) {
          $scope.currentWidget = void 0;
          $scope.isWidgetOpened = false;
          $scope.closeWidgets = function() {
            $scope.currentWidget = void 0;
            return $scope.isWidgetOpened = false;
          };
          $scope.hasSelectedEntities = function() {
            return Object.keys($scope.selectedEntities[$scope.box.id]).length > 0;
          };
          $scope.embedImageInEditor = function(image) {
            return $scope.$emit("embedImageInEditor", image);
          };
          return $scope.toggleWidget = function(widget) {
            if ($scope.currentWidget === widget) {
              $scope.currentWidget = void 0;
              return $scope.isWidgetOpened = false;
            } else {
              $scope.currentWidget = widget;
              $scope.isWidgetOpened = true;
              return $scope.$emit("updateWidget", widget, $scope.box.id);
            }
          };
        },
        controller: function($scope, $element, $attrs) {
          var ctrl;
          $scope.tiles = [];
          $scope.$parent.boxes[$scope.box.id] = $scope;
          $scope.deselect = function(entity) {
            var tile, _i, _len, _ref, _results;
            _ref = $scope.tiles;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              tile = _ref[_i];
              if (tile.entity.id === entity.id) {
                _results.push(tile.isSelected = false);
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          };
          $scope.relink = function(entity, annotationId) {
            var tile, _i, _len, _ref, _results;
            _ref = $scope.tiles;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              tile = _ref[_i];
              if (tile.entity.id === entity.id) {
                _results.push(tile.isLinked = (__indexOf.call(tile.entity.occurrences, annotationId) >= 0));
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          };
          $scope.$watch("annotation", function(annotationId) {
            var tile, _i, _len, _ref, _results;
            $log.debug("Watching annotation ... New value " + annotationId);
            $scope.currentWidget = void 0;
            $scope.isWidgetOpened = false;
            _ref = $scope.tiles;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              tile = _ref[_i];
              if (annotationId != null) {
                tile.isVisible = tile.entity.isRelatedToAnnotation(annotationId);
                tile.annotationModeOn = true;
                _results.push(tile.isLinked = (__indexOf.call(tile.entity.occurrences, annotationId) >= 0));
              } else {
                tile.isVisible = true;
                tile.isLinked = false;
                _results.push(tile.annotationModeOn = false);
              }
            }
            return _results;
          });
          ctrl = {
            onSelectedTile: function(tile) {
              tile.isSelected = !tile.isSelected;
              return $scope.onSelectedEntityTile(tile.entity, $scope.box);
            },
            addTile: function(tile) {
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
  ]);

  angular.module('wordlift.editpost.widget.directives.wlEntityForm', []).directive('wlEntityForm', [
    '$log', function($log) {
      return {
        restrict: 'E',
        scope: {
          entity: '=',
          onSubmit: '&'
        },
        template: "<form class=\"wl-entity-form\" ng-submit=\"onSubmit()\">\n<div>\n    <label>Entity label</label>\n    <input type=\"text\" ng-model=\"entity.label\" />\n</div>\n<div>\n    <label>Entity type</label>\n    <select ng-model=\"entity.mainType\" ng-options=\"type.id as type.name for type in supportedTypes\" ></select>\n</div>\n<div>\n    <label>Entity Description</label>\n    <textarea ng-model=\"entity.description\" rows=\"6\"></textarea>\n</div>\n<div>\n    <label>Entity id</label>\n    <input type=\"text\" ng-model=\"entity.id\" />\n</div>\n<div>\n    <label>Entity Same as</label>\n    <input type=\"text\" ng-model=\"entity.sameAs\" />\n</div>\n<input type=\"submit\" value=\"save\" />\n</form>",
        link: function($scope, $element, $attrs, $ctrl) {
          return $scope.supportedTypes = [
            {
              id: 'person',
              name: 'http://schema.org/Person'
            }, {
              id: 'place',
              name: 'http://schema.org/Place'
            }, {
              id: 'organization',
              name: 'http://schema.org/Organization'
            }, {
              id: 'event',
              name: 'http://schema.org/Event'
            }, {
              id: 'creative-work',
              name: 'http://schema.org/CreativeWork'
            }
          ];
        }
      };
    }
  ]);

  angular.module('wordlift.editpost.widget.directives.wlEntityTile', []).directive('wlEntityTile', [
    '$log', function($log) {
      return {
        require: '^wlClassificationBox',
        restrict: 'E',
        scope: {
          entity: '='
        },
        template: "<div ng-class=\"'wl-' + entity.mainType\" ng-show=\"isVisible\" class=\"entity\">\n  <i ng-show=\"annotationModeOn\" ng-class=\"{ 'wl-linked' : isLinked, 'wl-unlinked' : !isLinked }\"></i>\n        <i ng-hide=\"annotationModeOn\" ng-class=\"{ 'wl-selected' : isSelected, 'wl-unselected' : !isSelected }\"></i>\n        <i class=\"type\"></i>\n        <span class=\"label\" ng-click=\"select()\">{{entity.label}}</span>\n        <small ng-show=\"entity.occurrences.length > 0\">({{entity.occurrences.length}})</small>\n        <i ng-class=\"{ 'wl-more': isOpened == false, 'wl-less': isOpened == true }\" ng-click=\"toggle()\"></i>\n  <span ng-class=\"{ 'active' : editingModeOn }\" ng-click=\"toggleEditingMode()\" ng-show=\"isOpened\" class=\"wl-edit-button\">Edit</span>\n        <div class=\"details\" ng-show=\"isOpened\">\n          <p ng-hide=\"editingModeOn\"><img class=\"thumbnail\" ng-src=\"{{ entity.images[0] }}\" />{{entity.description}}</p>\n          <wl-entity-form entity=\"entity\" ng-show=\"editingModeOn\" on-submit=\"toggleEditingMode()\"></wl-entity-form>\n        </div>\n\n</div>\n",
        link: function($scope, $element, $attrs, $ctrl) {
          $ctrl.addTile($scope);
          $scope.isOpened = false;
          $scope.isVisible = true;
          $scope.isSelected = false;
          $scope.isLinked = false;
          $scope.annotationModeOn = false;
          $scope.editingModeOn = false;
          $scope.toggleEditingMode = function() {
            return $scope.editingModeOn = !$scope.editingModeOn;
          };
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

  angular.module('wordlift.editpost.widget.services.AnalysisService', []).service('AnalysisService', [
    '$log', '$http', '$rootScope', function($log, $http, $rootScope) {
      var extend, merge, service, uniqueId, _currentAnalysis;
      uniqueId = function(length) {
        var id;
        if (length == null) {
          length = 8;
        }
        id = '';
        while (id.length < length) {
          id += Math.random().toString(36).substr(2);
        }
        return id.substr(0, length);
      };
      merge = function(options, overrides) {
        return extend(extend({}, options), overrides);
      };
      extend = function(object, properties) {
        var key, val;
        for (key in properties) {
          val = properties[key];
          object[key] = val;
        }
        return object;
      };
      service = _currentAnalysis = {};
      service.createEntity = function(params) {
        var defaults;
        if (params == null) {
          params = {};
        }
        defaults = {
          id: 'local-entity-' + uniqueId(32),
          label: '',
          description: '',
          mainType: '',
          types: [],
          images: [],
          occurrences: [],
          annotations: {},
          isRelatedToAnnotation: function(annotationId) {
            if (this.annotations[annotationId] != null) {
              return true;
            } else {
              return false;
            }
          }
        };
        return merge(defaults, params);
      };
      service.createAnnotation = function(params) {
        var defaults;
        if (params == null) {
          params = {};
        }
        defaults = {
          id: 'urn:local-text-annotation-' + uniqueId(32),
          text: '',
          start: 0,
          end: 0,
          entityMatches: []
        };
        return merge(defaults, params);
      };
      service.parse = function(data) {
        var annotation, ea, entity, id, _i, _len, _ref, _ref1, _ref2, _ref3;
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
        _ref3 = data.annotations;
        for (id in _ref3) {
          annotation = _ref3[id];
          annotation.id = id;
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
  ]);

  angular.module('wordlift.editpost.widget.services.EditorService', ['wordlift.editpost.widget.services.AnalysisService']).service('EditorService', [
    'AnalysisService', '$log', '$http', '$rootScope', function(AnalysisService, $log, $http, $rootScope) {
      var currentOccurencesForEntity, dedisambiguate, disambiguate, editor, service;
      editor = function() {
        return tinyMCE.get('content');
      };
      disambiguate = function(annotation, entity) {
        var discardedItemId, ed;
        ed = editor();
        ed.dom.addClass(annotation.id, "disambiguated");
        ed.dom.addClass(annotation.id, "wl-" + entity.mainType);
        discardedItemId = ed.dom.getAttrib(annotation.id, "itemid");
        ed.dom.setAttrib(annotation.id, "itemid", entity.id);
        return discardedItemId;
      };
      dedisambiguate = function(annotation, entity) {
        var discardedItemId, ed;
        ed = editor();
        ed.dom.removeClass(annotation.id, "disambiguated");
        ed.dom.removeClass(annotation.id, "wl-" + entity.mainType);
        discardedItemId = ed.dom.getAttrib(annotation.id, "itemid");
        ed.dom.setAttrib(annotation.id, "itemid", "");
        return discardedItemId;
      };
      currentOccurencesForEntity = function(entityId) {
        var annotation, annotations, ed, itemId, occurrences, _i, _len;
        ed = editor();
        occurrences = [];
        if (entityId === "") {
          return occurrences;
        }
        annotations = ed.dom.select("span.textannotation");
        for (_i = 0, _len = annotations.length; _i < _len; _i++) {
          annotation = annotations[_i];
          itemId = ed.dom.getAttrib(annotation.id, "itemid");
          if (itemId === entityId) {
            occurrences.push(annotation.id);
          }
        }
        return occurrences;
      };
      $rootScope.$on("analysisPerformed", function(event, analysis) {
        if ((analysis != null) && (analysis.annotations != null)) {
          return service.embedAnalysis(analysis);
        }
      });
      $rootScope.$on("embedImageInEditor", function(event, image) {
        return tinyMCE.execCommand('mceInsertContent', false, "<img src=\"" + image + "\" width=\"100%\" />");
      });
      $rootScope.$on("entitySelected", function(event, entity, annotationId) {
        var annotation, discarded, entityId, id, occurrences, _i, _len, _ref;
        discarded = [];
        if (annotationId != null) {
          discarded.push(disambiguate(entity.annotations[annotationId], entity));
        } else {
          _ref = entity.annotations;
          for (id in _ref) {
            annotation = _ref[id];
            $log.debug("Going to disambiguate annotation " + id);
            discarded.push(disambiguate(annotation, entity));
          }
        }
        for (_i = 0, _len = discarded.length; _i < _len; _i++) {
          entityId = discarded[_i];
          if (entityId) {
            occurrences = currentOccurencesForEntity(entityId);
            $rootScope.$broadcast("updateOccurencesForEntity", entityId, occurrences);
          }
        }
        occurrences = currentOccurencesForEntity(entity.id);
        return $rootScope.$broadcast("updateOccurencesForEntity", entity.id, occurrences);
      });
      $rootScope.$on("entityDeselected", function(event, entity, annotationId) {
        var annotation, discarded, entityId, id, occurrences, _i, _len, _ref;
        discarded = [];
        if (annotationId != null) {
          dedisambiguate(entity.annotations[annotationId], entity);
        } else {
          _ref = entity.annotations;
          for (id in _ref) {
            annotation = _ref[id];
            dedisambiguate(annotation, entity);
          }
        }
        for (_i = 0, _len = discarded.length; _i < _len; _i++) {
          entityId = discarded[_i];
          if (entityId) {
            occurrences = currentOccurencesForEntity(entityId);
            $rootScope.$broadcast("updateOccurencesForEntity", entityId, occurrences);
          }
        }
        occurrences = currentOccurencesForEntity(entity);
        return $rootScope.$broadcast("updateOccurencesForEntity", entity.id, occurrences);
      });
      service = {
        createTextAnnotationFromCurrentSelection: function() {
          var content, ed, htmlPosition, text, textAnnotation, textAnnotationSpan, textPosition, traslator;
          ed = editor();
          if (ed.selection.isCollapsed()) {
            $log.warn("Invalid selection! The text annotation cannot be created");
            return;
          }
          text = "" + (ed.selection.getSel());
          textAnnotation = AnalysisService.createAnnotation({
            text: text
          });
          textAnnotationSpan = "<span id=\"" + textAnnotation.id + "\" class=\"textannotation selected\">" + (ed.selection.getContent()) + "</span>";
          ed.selection.setContent(textAnnotationSpan);
          content = ed.getContent({
            format: "html"
          });
          traslator = Traslator.create(content);
          htmlPosition = content.indexOf(textAnnotationSpan);
          textPosition = traslator.html2text(htmlPosition);
          textAnnotation.start = textPosition;
          textAnnotation.end = textAnnotation.start + text.length;
          $log.debug("New text annotation created!");
          $log.debug(textAnnotation);
          return $rootScope.$broadcast('textAnnotationAdded', textAnnotation);
        },
        embedAnalysis: (function(_this) {
          return function(analysis) {
            var annotation, annotationId, ed, element, entity, html, isDirty, traslator, _ref;
            ed = editor();
            html = ed.getContent({
              format: 'raw'
            });
            while (html.match(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')) {
              html = html.replace(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2');
            }
            traslator = Traslator.create(html);
            _ref = analysis.annotations;
            for (annotationId in _ref) {
              annotation = _ref[annotationId];
              entity = analysis.entities[ annotation.entityMatches[0].entityId];
              element = "<span id=\"" + annotationId + "\" class=\"textannotation\">";
              traslator.insertHtml(element, {
                text: annotation.start
              });
              traslator.insertHtml('</span>', {
                text: annotation.end
              });
            }
            isDirty = ed.isDirty();
            ed.setContent(traslator.getHtml(), {
              format: 'raw'
            });
            return ed.isNotDirty = !isDirty;
          };
        })(this)
      };
      return service;
    }
  ]);

  angular.module('wordlift.editpost.widget.services.ImageSuggestorDataRetrieverService', []).service('ImageSuggestorDataRetrieverService', [
    '$log', '$http', '$rootScope', function($log, $http, $rootScope) {
      var service;
      service = {};
      service.loadData = function(entities) {
        var entity, id, image, items, _i, _len, _ref;
        items = [];
        for (id in entities) {
          entity = entities[id];
          _ref = entity.images;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            image = _ref[_i];
            items.push({
              'uri': image
            });
          }
        }
        return items;
      };
      return service;
    }
  ]);

  angular.module('wordlift.editpost.widget.providers.ConfigurationProvider', []).provider("configuration", function() {
    var boxes, provider;
    boxes = void 0;
    provider = {
      setBoxes: function(items) {
        return boxes = items;
      },
      $get: function() {
        return {
          boxes: boxes
        };
      }
    };
    return provider;
  });

  $ = jQuery;

  angular.module('wordlift.editpost.widget', ['wordlift.editpost.widget.providers.ConfigurationProvider', 'wordlift.editpost.widget.controllers.EditPostWidgetController', 'wordlift.editpost.widget.directives.wlClassificationBox', 'wordlift.editpost.widget.directives.wlEntityForm', 'wordlift.editpost.widget.directives.wlEntityTile', 'wordlift.editpost.widget.services.AnalysisService', 'wordlift.editpost.widget.services.EditorService', 'wordlift.editpost.widget.services.ImageSuggestorDataRetrieverService']).config(function(configurationProvider) {
    console.log("daje sempre");
    console.log(window.wordlift.classificationBoxes);
    return configurationProvider.setBoxes(window.wordlift.classificationBoxes);
  });

  $(container = $("<div id=\"wordlift-edit-post-wrapper\" ng-controller=\"EditPostWidgetController\">\n	<div ng-show=\"annotation\">\n        <h4 class=\"wl-annotation-label\">\n          <i class=\"wl-annotation-label-icon\"></i>\n          {{ analysis.annotations[ annotation ].text }} \n          <small>[ {{ analysis.annotations[ annotation ].start }}, {{ analysis.annotations[ annotation ].end }} ]</small>\n          <i class=\"wl-annotation-label-remove-icon\" ng-click=\"annotation = undefined\"></i>\n        </h4>\n        <wl-entity-form entity=\"newEntity\" on-submit=\"addNewEntityToAnalysis()\"ng-show=\"analysis.annotations[annotation].entityMatches.length == 0\"></wl-entity-form>\n      </div>\n      <wl-classification-box ng-repeat=\"box in configuration.boxes\">\n        <wl-entity-tile entity=\"entity\" ng-repeat=\"entity in analysis.entities | entityTypeIn:box.registeredTypes\"></wl-entity>\n      </wl-classification-box>\n    </div>").appendTo('#dx'), injector = angular.bootstrap($('#wordlift-edit-post-wrapper'), ['wordlift.editpost.widget']), tinymce.PluginManager.add('wordlift', function(editor, url) {
    editor.onLoadContent.add(function(ed, o) {
      return injector.invoke([
        'AnalysisService', '$rootScope', function(AnalysisService, $rootScope) {
          return $rootScope.$apply(function() {
            return AnalysisService.perform();
          });
        }
      ]);
    });
    editor.addButton('wordlift', {
      classes: 'widget btn wordlift_add_entity',
      text: ' ',
      tooltip: 'Insert entity',
      onclick: function() {
        return injector.invoke([
          'AnalysisService', 'EditorService', '$rootScope', function(AnalysisService, EditorService, $rootScope) {
            return $rootScope.$apply(function() {
              return EditorService.createTextAnnotationFromCurrentSelection();
            });
          }
        ]);
      }
    });
    return editor.onClick.add(function(editor, e) {
      return injector.invoke([
        '$rootScope', function($rootScope) {
          return $rootScope.$apply(function() {
            var annotation, _i, _len, _ref, _results;
            _ref = editor.dom.select("span.textannotation");
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              annotation = _ref[_i];
              if (annotation.id === e.target.id) {
                if (editor.dom.hasClass(annotation.id, "selected")) {
                  editor.dom.removeClass(annotation.id, "selected");
                  _results.push($rootScope.$broadcast('textAnnotationClicked', void 0));
                } else {
                  editor.dom.addClass(annotation.id, "selected");
                  _results.push($rootScope.$broadcast('textAnnotationClicked', e.target.id));
                }
              } else {
                _results.push(editor.dom.removeClass(annotation.id, "selected"));
              }
            }
            return _results;
          });
        }
      ]);
    });
  }));

}).call(this);

//# sourceMappingURL=wordlift-reloaded.js.map
