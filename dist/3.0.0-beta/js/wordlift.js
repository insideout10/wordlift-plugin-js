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
        if (0 < htmlPost.length) {
          this._htmlPositions.push(htmlLength);
          this._textPositions.push(textLength);
        }
        textLength += textPost.length;
        htmlLength += htmlPost.length;
        this._text += textPre + textPost;
      }
      if (0 === this._textPositions.length || 0 !== this._textPositions[0]) {
        this._htmlPositions.unshift(0);
        return this._textPositions.unshift(0);
      }
    };

    Traslator.prototype.text2html = function(pos) {
      var htmlPos, i, textPos, _i, _ref;
      htmlPos = this._textPositions[0];
      textPos = this._textPositions[0];
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
      htmlPos = this._textPositions[0];
      textPos = this._textPositions[0];
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

  angular.module('wordlift.tinymce.plugin.config', []).constant('Configuration', {
    supportedTypes: ['schema:Place', 'schema:Event', 'schema:CreativeWork', 'schema:Product', 'schema:Person', 'schema:Organization'],
    entityLabels: {
      'entityLabel': 'enhancer:entity-label',
      'entityType': 'enhancer:entity-type',
      'entityReference': 'enhancer:entity-reference',
      'textAnnotation': 'enhancer:TextAnnotation',
      'entityAnnotation': 'enhancer:EntityAnnotation',
      'selectionPrefix': 'enhancer:selection-prefix',
      'selectionSuffix': 'enhancer:selection-suffix',
      'selectedText': 'enhancer:selected-text',
      'confidence': 'enhancer:confidence',
      'relation': 'dc:relation'
    }
  });

  angular.module('wordlift.tinymce.plugin.directives', ['wordlift.tinymce.plugin.controllers']).directive('wlEntities', function() {
    return {
      restrict: 'E',
      scope: {
        textAnnotation: '=',
        onSelect: '&'
      },
      link: function(scope, element, attrs) {
        return scope.select = function(item) {
          var entityAnnotation, id, _ref;
          _ref = scope.textAnnotation.entityAnnotations;
          for (id in _ref) {
            entityAnnotation = _ref[id];
            entityAnnotation.selected = item.id === entityAnnotation.id && !entityAnnotation.selected;
          }
          return scope.onSelect({
            textAnnotation: scope.textAnnotation,
            entityAnnotation: item.selected ? item : null
          });
        };
      },
      template: "<div>\n  <ul>\n    <li ng-repeat=\"entityAnnotation in textAnnotation.entityAnnotations | orderObjectBy:'confidence':true\">\n      <wl-entity on-select=\"select(entityAnnotation)\" entity-annotation=\"entityAnnotation\"></wl-entity>\n    </li>\n  </ul>\n</div>"
    };
  }).directive('wlEntity', function() {
    return {
      restrict: 'E',
      scope: {
        entityAnnotation: '=',
        onSelect: '&'
      },
      template: "<div class=\"entity {{entityAnnotation.entity.css}}\" ng-class=\"{selected: true==entityAnnotation.selected}\" ng-click=\"onSelect()\" ng-show=\"entityAnnotation.entity.label\">\n  <div class=\"thumbnail\" ng-show=\"entityAnnotation.entity.thumbnail\" title=\"{{entityAnnotation.entity.id}}\" ng-attr-style=\"background-image: url({{entityAnnotation.entity.thumbnail}})\"></div>\n  <div class=\"thumbnail empty\" ng-hide=\"entityAnnotation.entity.thumbnail\" title=\"{{entityAnnotation.entity.id}}\"></div>\n  <div class=\"confidence\" ng-bind=\"entityAnnotation.confidence\"></div>\n  <div class=\"label\" ng-bind=\"entityAnnotation.entity.label\"></div>\n  <div class=\"type\"></div>\n  <div class=\"source\" ng-class=\"entityAnnotation.entity.source\" ng-bind=\"entityAnnotation.entity.source\"></div>\n</div>"
    };
  }).directive('wlEntityInputBoxes', function() {
    return {
      restrict: 'E',
      scope: {
        textAnnotations: '='
      },
      template: "<div class=\"wl-entity-input-boxes\" ng-repeat=\"textAnnotation in textAnnotations\">\n  <div ng-repeat=\"entityAnnotation in textAnnotation.entityAnnotations | filterObjectBy:'selected':true\">\n\n    <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][uri]' value='{{entityAnnotation.entity.id}}'>\n    <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][label]' value='{{entityAnnotation.entity.label}}'>\n    <textarea name='wl_entities[{{entityAnnotation.entity.id}}][description]'>{{entityAnnotation.entity.description}}</textarea>\n\n    <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][main_type]' value='{{entityAnnotation.entity.type}}'>\n\n    <input ng-repeat=\"type in entityAnnotation.entity.types\" type='text'\n    	name='wl_entities[{{entityAnnotation.entity.id}}][type][]' value='{{type}}'>\n\n    <input ng-repeat=\"image in entityAnnotation.entity.thumbnails\" type='text'\n      name='wl_entities[{{entityAnnotation.entity.id}}][image][]' value='{{image}}'>\n    <input ng-repeat=\"sameAs in entityAnnotation.entity.sameAs\" type='text'\n      name='wl_entities[{{entityAnnotation.entity.id}}][sameas][]' value='{{sameAs}}'>\n\n    <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][latitude]' value='{{entityAnnotation.entity.latitude}}'>\n    <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][longitude]' value='{{entityAnnotation.entity.longitude}}'>\n\n  </div>\n</div>"
    };
  });

  angular.module('AnalysisService', []).service('AnalysisService', [
    '$filter', '$http', '$q', '$rootScope', function($filter, $http, $q, $rootScope) {
      var ANALYSIS_EVENT, CONTEXT, DBPEDIA, DBPEDIA_ORG, DCTERMS, FISE_ONT, FISE_ONT_CONFIDENCE, FISE_ONT_ENTITY_ANNOTATION, FISE_ONT_TEXT_ANNOTATION, FREEBASE, FREEBASE_COM, FREEBASE_NS, FREEBASE_NS_DESCRIPTION, GRAPH, KNOWN_TYPES, RDFS, RDFS_COMMENT, RDFS_LABEL, SCHEMA_ORG, SCHEMA_ORG_DESCRIPTION, VALUE, WGS84_POS, findOrCreateTextAnnotation, findTextAnnotation, service, _ref;
      CONTEXT = '@context';
      GRAPH = '@graph';
      VALUE = '@value';
      ANALYSIS_EVENT = 'analysisReceived';
      RDFS = 'http://www.w3.org/2000/01/rdf-schema#';
      RDFS_LABEL = "" + RDFS + "label";
      RDFS_COMMENT = "" + RDFS + "comment";
      FREEBASE = 'freebase';
      FREEBASE_COM = "http://rdf." + FREEBASE + ".com/";
      FREEBASE_NS = "" + FREEBASE_COM + "ns/";
      FREEBASE_NS_DESCRIPTION = "" + FREEBASE_NS + "common.topic.description";
      SCHEMA_ORG = 'http://schema.org/';
      SCHEMA_ORG_DESCRIPTION = "" + SCHEMA_ORG + "description";
      FISE_ONT = 'http://fise.iks-project.eu/ontology/';
      FISE_ONT_ENTITY_ANNOTATION = "" + FISE_ONT + "EntityAnnotation";
      FISE_ONT_TEXT_ANNOTATION = "" + FISE_ONT + "TextAnnotation";
      FISE_ONT_CONFIDENCE = "" + FISE_ONT + "confidence";
      DCTERMS = 'http://purl.org/dc/terms/';
      DBPEDIA = 'dbpedia';
      DBPEDIA_ORG = "http://" + DBPEDIA + ".org/";
      WGS84_POS = 'http://www.w3.org/2003/01/geo/wgs84_pos#';
      KNOWN_TYPES = ((_ref = window.wordlift) != null ? _ref.types : void 0) != null ? window.wordlift.types : [];
      findTextAnnotation = function(textAnnotations, start, end) {
        var textAnnotation, textAnnotationId;
        for (textAnnotationId in textAnnotations) {
          textAnnotation = textAnnotations[textAnnotationId];
          if (textAnnotation.start === start && textAnnotation.end === end) {
            return textAnnotation;
          }
        }
      };
      findOrCreateTextAnnotation = function(analysis, textAnnotation) {
        var ta;
        ta = findTextAnnotation(analysis.textAnnotations, textAnnotation.start, textAnnotation.end);
        if (null === ta) {
          ta = {
            id: 'wordlift-ta-' + textAnnotation.start + '-' + textAnnotation.end,
            selectedText: textAnnotation.label,
            selectionPrefix: '',
            selectionSuffix: '',
            start: textAnnotation.start,
            end: textAnnotation.end,
            confidence: null,
            entityAnnotations: {},
            _item: null
          };
          analysis.textAnnotations[ta.id] = ta;
        }
        return ta;
      };
      service = {
        promise: void 0,
        isRunning: false,
        abort: function() {
          if (this.isRunning && (this.promise != null)) {
            return this.promise.resolve();
          }
        },
        preselect: function(analysis, annotations) {
          var annotation, ea, entityAnnotation, textAnnotation, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = annotations.length; _i < _len; _i++) {
            annotation = annotations[_i];
            textAnnotation = findOrCreateTextAnnotation(analysis, annotation);
            entityAnnotation = this.findEntityAnnotation(textAnnotation.entityAnnotations, {
              uri: annotation.uri
            });
            if (entityAnnotation != null) {
              _results.push(entityAnnotation.selected = true);
            } else {
              if (!analysis.entities[annotation.uri]) {
                analysis.entities[annotation.uri] = window.wordlift.entities[annotation.uri];
              }
              ea = {
                id: 'wordlift-ea-from-' + textAnnotation.id,
                label: annotation.label,
                confidence: null,
                entity: analysis.entities[annotation.uri],
                relation: analysis.textAnnotations[textAnnotation.id],
                _item: null,
                selected: true
              };
              analysis.entityAnnotations[ea.id] = ea;
              _results.push(textAnnotation.entityAnnotations[ea.id] = analysis.entityAnnotations[ea.id]);
            }
          }
          return _results;
        },
        analyze: function(content, merge) {
          var that;
          if (merge == null) {
            merge = false;
          }
          if (this.isRunning) {
            return;
          }
          this.isRunning = true;
          this.promise = $q.defer();
          that = this;
          return $http({
            method: 'post',
            url: ajaxurl + '?action=wordlift_analyze',
            data: content,
            timeout: this.promise.promise
          }).success(function(data) {
            $rootScope.$broadcast(ANALYSIS_EVENT, that.parse(data, merge));
            return that.isRunning = false;
          }).error(function(data, status) {
            that.isRunning = false;
            $rootScope.$broadcast(ANALYSIS_EVENT, void 0);
            if (0 === status) {
              return;
            }
            return $rootScope.$broadcast('error', 'An error occurred while requesting an analysis.');
          });
        },
        findEntityAnnotation: function(entityAnnotations, filter) {
          var entityAnnotation, entityAnnotationId, _ref1;
          if (filter.uri != null) {
            for (entityAnnotationId in entityAnnotations) {
              entityAnnotation = entityAnnotations[entityAnnotationId];
              if (filter.uri === entityAnnotation.entity.id || (_ref1 = filter.uri, __indexOf.call(entityAnnotation.entity.sameAs, _ref1) >= 0)) {
                return entityAnnotation;
              }
            }
          }
          if (filter.selected != null) {
            for (entityAnnotationId in entityAnnotations) {
              entityAnnotation = entityAnnotations[entityAnnotationId];
              if (entityAnnotation.selected) {
                return entityAnnotation;
              }
            }
          }
        },
        parse: function(data, merge) {
          var anotherEntityAnnotation, anotherId, containsOrEquals, context, createEntity, createEntityAnnotation, createLanguage, createTextAnnotation, dctype, entities, entity, entityAnnotation, entityAnnotations, expand, get, getA, getKnownTypes, getLanguage, graph, id, item, language, languages, mergeEntities, mergeUnique, textAnnotation, textAnnotationId, textAnnotations, types, _i, _len, _ref1, _ref2;
          if (merge == null) {
            merge = false;
          }
          languages = [];
          textAnnotations = {};
          entityAnnotations = {};
          entities = {};
          getKnownTypes = function(types) {
            var defaultType, kt, matches, returnTypes, uri, uris, _i, _len;
            returnTypes = [];
            defaultType = void 0;
            for (_i = 0, _len = KNOWN_TYPES.length; _i < _len; _i++) {
              kt = KNOWN_TYPES[_i];
              if (__indexOf.call(kt.sameAs, '*') >= 0) {
                defaultType = [
                  {
                    type: kt
                  }
                ];
              }
              uris = kt.sameAs.concat(kt.uri);
              matches = (function() {
                var _j, _len1, _results;
                _results = [];
                for (_j = 0, _len1 = uris.length; _j < _len1; _j++) {
                  uri = uris[_j];
                  if (containsOrEquals(uri, types)) {
                    _results.push(uri);
                  }
                }
                return _results;
              })();
              if (0 < matches.length) {
                returnTypes.push({
                  matches: matches,
                  type: kt
                });
              }
            }
            if (0 === returnTypes.length) {
              return defaultType;
            }
            $filter('orderBy')(returnTypes, 'matches', true);
            return returnTypes;
          };
          createEntity = function(item, language) {
            var css, entity, id, knownTypes, sameAs, thumbnails, types;
            id = get('@id', item);
            types = get('@type', item);
            types = angular.isArray(types) ? types : [types];
            sameAs = get('http://www.w3.org/2002/07/owl#sameAs', item);
            sameAs = angular.isArray(sameAs) ? sameAs : [sameAs];
            thumbnails = get(['http://xmlns.com/foaf/0.1/depiction', "" + FREEBASE_NS + "common.topic.image", "" + SCHEMA_ORG + "image"], item, function(values) {
              var match, value, _i, _len, _results;
              values = angular.isArray(values) ? values : [values];
              _results = [];
              for (_i = 0, _len = values.length; _i < _len; _i++) {
                value = values[_i];
                match = /m\.(.*)$/i.exec(value);
                if (null === match) {
                  _results.push(value);
                } else {
                  _results.push("https://usercontent.googleapis.com/" + FREEBASE + "/v1/image/m/" + match[1] + "?maxwidth=4096&maxheight=4096");
                }
              }
              return _results;
            });
            knownTypes = getKnownTypes(types);
            css = knownTypes[0].type.css;
            entity = {
              id: id,
              thumbnail: 0 < thumbnails.length ? thumbnails[0] : null,
              thumbnails: thumbnails,
              css: css,
              type: knownTypes[0].type.uri,
              types: types,
              label: getLanguage(RDFS_LABEL, item, language),
              labels: get(RDFS_LABEL, item),
              sameAs: sameAs,
              source: id.match("^" + FREEBASE_COM + ".*$") ? FREEBASE : id.match("^" + DBPEDIA_ORG + ".*$") ? DBPEDIA : 'wordlift',
              _item: item
            };
            entity.description = getLanguage([RDFS_COMMENT, FREEBASE_NS_DESCRIPTION, SCHEMA_ORG_DESCRIPTION], item, language);
            entity.descriptions = get([RDFS_COMMENT, FREEBASE_NS_DESCRIPTION, SCHEMA_ORG_DESCRIPTION], item);
            if (entity.description == null) {
              entity.description = '';
            }
            entity.latitude = get("" + WGS84_POS + "lat", item);
            entity.longitude = get("" + WGS84_POS + "long", item);
            if (0 === entity.latitude.length || 0 === entity.longitude.length) {
              entity.latitude = '';
              entity.longitude = '';
            }
            return entity;
          };
          createEntityAnnotation = function(item) {
            var annotations, entity, entityAnnotation, id, reference, relation, relations, textAnnotation, _i, _len;
            reference = get("" + FISE_ONT + "entity-reference", item);
            entity = entities[reference];
            if (entity == null) {
              return null;
            }
            annotations = [];
            id = get('@id', item);
            relations = get("" + DCTERMS + "relation", item);
            relations = angular.isArray(relations) ? relations : [relations];
            for (_i = 0, _len = relations.length; _i < _len; _i++) {
              relation = relations[_i];
              textAnnotation = textAnnotations[relation];
              entityAnnotation = {
                id: id,
                label: get("" + FISE_ONT + "entity-label", item),
                confidence: get(FISE_ONT_CONFIDENCE, item),
                entity: entity,
                relation: textAnnotation,
                _item: item,
                selected: false
              };
              if (textAnnotation != null) {
                textAnnotation.entityAnnotations[entityAnnotation.id] = entityAnnotation;
              }
              annotations.push(entityAnnotation);
            }
            return annotations[0];
          };
          createTextAnnotation = function(item) {
            var textAnnotation;
            textAnnotation = {
              id: get('@id', item),
              selectedText: get("" + FISE_ONT + "selected-text", item)[VALUE],
              selectionPrefix: get("" + FISE_ONT + "selection-prefix", item)[VALUE],
              selectionSuffix: get("" + FISE_ONT + "selection-suffix", item)[VALUE],
              start: get("" + FISE_ONT + "start", item),
              end: get("" + FISE_ONT + "end", item),
              confidence: get(FISE_ONT_CONFIDENCE, item),
              entityAnnotations: {},
              _item: item
            };
            return textAnnotation;
          };
          createLanguage = function(item) {
            return {
              code: get("" + DCTERMS + "language", item),
              confidence: get(FISE_ONT_CONFIDENCE, item),
              _item: item
            };
          };
          get = function(what, container, filter) {
            var add, key, values, _i, _len;
            if (!angular.isArray(what)) {
              return getA(what, container, filter);
            }
            values = [];
            for (_i = 0, _len = what.length; _i < _len; _i++) {
              key = what[_i];
              add = getA(key, container, filter);
              add = angular.isArray(add) ? add : [add];
              mergeUnique(values, add);
            }
            return values;
          };
          getA = function(what, container, filter) {
            var key, value, whatExp;
            if (filter == null) {
              filter = function(a) {
                return a;
              };
            }
            whatExp = expand(what);
            for (key in container) {
              value = container[key];
              if (whatExp === expand(key)) {
                return filter(value);
              }
            }
            return [];
          };
          getLanguage = function(what, container, language) {
            var item, items, _i, _len;
            if (null === (items = get(what, container))) {
              return;
            }
            items = angular.isArray(items) ? items : [items];
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              item = items[_i];
              if (language === item['@language']) {
                return item[VALUE];
              }
            }
            return null;
          };
          containsOrEquals = function(what, where) {
            var item, whatExp, whereArray, _i, _j, _len, _len1;
            if (where == null) {
              return false;
            }
            whereArray = angular.isArray(where) ? where : [where];
            whatExp = expand(what);
            if ('@' === what.charAt(0)) {
              for (_i = 0, _len = whereArray.length; _i < _len; _i++) {
                item = whereArray[_i];
                if (whatExp === expand(item)) {
                  return true;
                }
              }
            } else {
              for (_j = 0, _len1 = whereArray.length; _j < _len1; _j++) {
                item = whereArray[_j];
                if (whatExp === expand(item)) {
                  return true;
                }
              }
            }
            return false;
          };
          mergeUnique = function(array1, array2) {
            var item, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = array2.length; _i < _len; _i++) {
              item = array2[_i];
              if (__indexOf.call(array1, item) < 0) {
                _results.push(array1.push(item));
              }
            }
            return _results;
          };
          mergeEntities = function(entity, entities) {
            var existing, sameAs, _i, _len, _ref1;
            _ref1 = entity.sameAs;
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              sameAs = _ref1[_i];
              if ((entities[sameAs] != null) && entities[sameAs] !== entity) {
                existing = entities[sameAs];
                mergeUnique(entity.sameAs, existing.sameAs);
                mergeUnique(entity.thumbnails, existing.thumbnails);
                entity.source += ", " + existing.source;
                if (DBPEDIA === existing.source) {
                  entity.description = existing.description;
                }
                if (DBPEDIA === existing.source && (existing.longitude != null)) {
                  entity.longitude = existing.longitude;
                }
                if (DBPEDIA === existing.source && (existing.latitude != null)) {
                  entity.latitude = existing.latitude;
                }
                entities[sameAs] = entity;
                mergeEntities(entity, entities);
              }
            }
            return entity;
          };
          expand = function(content) {
            var matches, path, prefix, prepend;
            if (null === (matches = content.match(/([\w|\d]+):(.*)/))) {
              prefix = content;
              path = '';
            } else {
              prefix = matches[1];
              path = matches[2];
            }
            if (context[prefix] != null) {
              prepend = angular.isString(context[prefix]) ? context[prefix] : context[prefix]['@id'];
            } else {
              prepend = prefix + ':';
            }
            return prepend + path;
          };
          if (!((data[CONTEXT] != null) && (data[GRAPH] != null))) {
            $rootScope.$broadcast('error', 'The analysis response is invalid. Please try again later.');
            return false;
          }
          context = data[CONTEXT];
          graph = data[GRAPH];
          for (_i = 0, _len = graph.length; _i < _len; _i++) {
            item = graph[_i];
            id = item['@id'];
            types = item['@type'];
            dctype = get("" + DCTERMS + "type", item);
            if (containsOrEquals(FISE_ONT_TEXT_ANNOTATION, types) && containsOrEquals("" + DCTERMS + "LinguisticSystem", dctype)) {
              languages.push(createLanguage(item));
            } else if (containsOrEquals(FISE_ONT_TEXT_ANNOTATION, types)) {
              textAnnotations[id] = item;
            } else if (containsOrEquals(FISE_ONT_ENTITY_ANNOTATION, types)) {
              entityAnnotations[id] = item;
            } else {
              entities[id] = item;
            }
          }
          languages.sort(function(a, b) {
            if (a.confidence < b.confidence) {
              return -1;
            }
            if (a.confidence > b.confidence) {
              return 1;
            }
            return 0;
          });
          language = languages[0].code;
          for (id in entities) {
            item = entities[id];
            entities[id] = createEntity(item, language);
          }
          if (merge) {
            for (id in entities) {
              entity = entities[id];
              mergeEntities(entity, entities);
            }
          }
          for (id in textAnnotations) {
            item = textAnnotations[id];
            textAnnotations[id] = createTextAnnotation(item);
          }
          for (id in entityAnnotations) {
            item = entityAnnotations[id];
            entityAnnotations[id] = createEntityAnnotation(item);
          }
          if (merge) {
            for (textAnnotationId in textAnnotations) {
              textAnnotation = textAnnotations[textAnnotationId];
              _ref1 = textAnnotation.entityAnnotations;
              for (id in _ref1) {
                entityAnnotation = _ref1[id];
                _ref2 = textAnnotation.entityAnnotations;
                for (anotherId in _ref2) {
                  anotherEntityAnnotation = _ref2[anotherId];
                  if (id !== anotherId && entityAnnotation.entity === anotherEntityAnnotation.entity) {
                    delete textAnnotation.entityAnnotations[anotherId];
                  }
                }
              }
            }
          }
          return {
            language: language,
            entities: entities,
            entityAnnotations: entityAnnotations,
            textAnnotations: textAnnotations,
            languages: languages
          };
        }
      };
      return service;
    }
  ]);

  angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService']).service('EditorService', [
    'AnalysisService', '$rootScope', function(AnalysisService, $rootScope) {
      var CONTENT_EDITABLE, CONTENT_IFRAME, EDITOR_ID, MCE_WORDLIFT, RUNNING_CLASS, TEXT_ANNOTATION, editor, findEntities, service;
      EDITOR_ID = 'content';
      TEXT_ANNOTATION = 'textannotation';
      CONTENT_IFRAME = '#content_ifr';
      RUNNING_CLASS = 'running';
      MCE_WORDLIFT = '.mce_wordlift';
      CONTENT_EDITABLE = 'contenteditable';
      editor = function() {
        return tinyMCE.get(EDITOR_ID);
      };
      findEntities = function(html) {
        var match, pattern, traslator, _results;
        traslator = Traslator.create(html);
        pattern = /<(\w+)[^>]*\sitemid="([^"]+)"[^>]*>([^<]+)<\/\1>/gim;
        _results = [];
        while (match = pattern.exec(html)) {
          _results.push({
            start: traslator.html2text(match.index),
            end: traslator.html2text(match.index + match[0].length),
            uri: match[2],
            label: match[3]
          });
        }
        return _results;
      };
      service = {
        embedAnalysis: function(analysis) {
          var ed, element, entities, entity, entityAnnotation, html, isDirty, textAnnotation, textAnnotationId, traslator, _ref;
          ed = editor();
          html = ed.getContent({
            format: 'raw'
          });
          entities = findEntities(html);
          AnalysisService.preselect(analysis, entities);
          html = html.replace(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2');
          traslator = Traslator.create(html);
          _ref = analysis.textAnnotations;
          for (textAnnotationId in _ref) {
            textAnnotation = _ref[textAnnotationId];
            if (!(0 < Object.keys(textAnnotation.entityAnnotations).length)) {
              continue;
            }
            element = "<span id=\"" + textAnnotationId + "\" class=\"" + TEXT_ANNOTATION;
            entityAnnotation = AnalysisService.findEntityAnnotation(textAnnotation.entityAnnotations, {
              selected: true
            });
            if (entityAnnotation != null) {
              entity = entityAnnotation.entity;
              element += " highlight " + entity.css + "\" itemid=\"" + entity.id;
            }
            element += '">';
            traslator.insertHtml(element, {
              text: textAnnotation.start
            });
            traslator.insertHtml('</span>', {
              text: textAnnotation.end
            });
          }
          isDirty = ed.isDirty();
          ed.setContent(traslator.getHtml());
          return ed.isNotDirty = !isDirty;
        },
        analyze: function(content) {
          if (AnalysisService.isRunning) {
            return AnalysisService.abort();
          }
          $(MCE_WORDLIFT).addClass(RUNNING_CLASS);
          editor().getBody().setAttribute(CONTENT_EDITABLE, false);
          return AnalysisService.analyze(content, true);
        },
        getWinPos: function(elem) {
          var ed, el;
          ed = editor();
          el = elem.target;
          return {
            top: $(CONTENT_IFRAME).offset().top - $('body').scrollTop() + el.offsetTop - $(ed.getBody()).scrollTop(),
            left: $(CONTENT_IFRAME).offset().left - $('body').scrollLeft() + el.offsetLeft - $(ed.getBody()).scrollLeft()
          };
        }
      };
      $rootScope.$on('selectEntity', function(event, args) {
        var cls, dom, entity, id, itemid, itemscope, itemtype;
        dom = editor().dom;
        id = args.ta.id;
        cls = TEXT_ANNOTATION;
        if (args.ea != null) {
          entity = args.ea.entity;
          cls += " highlight " + entity.css;
          itemscope = 'itemscope';
          itemtype = entity.types.join(' ');
          itemid = entity.id;
        } else {
          itemscope = null;
          itemtype = null;
          itemid = null;
        }
        dom.setAttrib(id, 'class', cls);
        dom.setAttrib(id, 'itemscope', itemscope);
        dom.setAttrib(id, 'itemtype', itemtype);
        return dom.setAttrib(id, 'itemid', itemid);
      });
      $rootScope.$on('analysisReceived', function(event, analysis) {
        if ((analysis != null) && (analysis.textAnnotations != null)) {
          service.embedAnalysis(analysis);
        }
        $(MCE_WORDLIFT).removeClass(RUNNING_CLASS);
        return editor().getBody().setAttribute(CONTENT_EDITABLE, true);
      });
      return service;
    }
  ]);

  angular.module('wordlift.tinymce.plugin.services', ['wordlift.tinymce.plugin.config', 'wordlift.tinymce.plugin.services.EditorService', 'AnalysisService']);

  angular.module('wordlift.tinymce.plugin.controllers', ['wordlift.tinymce.plugin.config', 'wordlift.tinymce.plugin.services']).filter('orderObjectBy', function() {
    return function(items, field, reverse) {
      var filtered;
      filtered = [];
      angular.forEach(items, function(item) {
        return filtered.push(item);
      });
      filtered.sort(function(a, b) {
        return a[field] > b[field];
      });
      if (reverse) {
        filtered.reverse();
      }
      return filtered;
    };
  }).filter('filterObjectBy', function() {
    return function(items, field, value) {
      var filtered;
      filtered = [];
      angular.forEach(items, function(item) {
        if (item[field] === value) {
          return filtered.push(item);
        }
      });
      return filtered;
    };
  }).controller('EntitiesController', [
    'EditorService', '$log', '$scope', 'Configuration', function(EditorService, $log, $scope, Configuration) {
      var el, scroll, setArrowTop;
      $scope.analysis = null;
      $scope.textAnnotation = null;
      $scope.textAnnotationSpan = null;
      $scope.sortByConfidence = function(entity) {
        return entity[Configuration.entityLabels.confidence];
      };
      $scope.getLabelFor = function(label) {
        return Configuration.entityLabels[label];
      };
      setArrowTop = function(top) {
        return $('head').append('<style>#wordlift-disambiguation-popover .postbox:before,#wordlift-disambiguation-popover .postbox:after{top:' + top + 'px;}</style>');
      };
      el = void 0;
      scroll = function() {
        var pos;
        if (el == null) {
          return;
        }
        pos = EditorService.getWinPos(el);
        return setArrowTop(pos.top - 50);
      };
      $(window).scroll(scroll);
      $('#content_ifr').contents().scroll(scroll);
      $scope.onEntitySelected = function(textAnnotation, entityAnnotation) {
        $scope.$emit('selectEntity', {
          ta: textAnnotation,
          ea: entityAnnotation
        });
        return window.wordlift.entities[entityAnnotation.entity.id] = entityAnnotation.entity;
      };
      $scope.$on('analysisReceived', function(event, analysis) {
        return $scope.analysis = analysis;
      });
      return $scope.$on('textAnnotationClicked', function(event, id, sourceElement) {
        var pos, _ref;
        $scope.textAnnotationSpan = angular.element(sourceElement.target);
        $scope.textAnnotation = $scope.analysis.textAnnotations[id];
        if ((((_ref = $scope.textAnnotation) != null ? _ref.entityAnnotations : void 0) == null) || 0 === Object.keys($scope.textAnnotation.entityAnnotations).length) {
          return $('#wordlift-disambiguation-popover').hide();
        } else {
          pos = EditorService.getWinPos(sourceElement);
          setArrowTop(pos.top - 50);
          return $('#wordlift-disambiguation-popover').show();
        }
      });
    }
  ]).controller('ErrorController', [
    '$element', '$scope', '$log', function($element, $scope, $log) {
      var element;
      element = $($element).dialog({
        title: 'WordLift',
        dialogClass: 'wp-dialog',
        modal: true,
        autoOpen: false,
        closeOnEscape: true,
        buttons: {
          Ok: function() {
            return $(this).dialog('close');
          }
        }
      });
      return $scope.$on('error', function(event, message) {
        $scope.message = message;
        return element.dialog('open');
      });
    }
  ]);

  $ = jQuery;

  angular.module('wordlift.tinymce.plugin', ['wordlift.tinymce.plugin.controllers', 'wordlift.tinymce.plugin.directives']);

  $(container = $('<div id="wl-app" class="wl-app">\n  <div id="wl-error-controller" class="wl-error-controller" ng-controller="ErrorController">\n    <p ng-bind="message"></p>\n  </div>\n  <div id="wordlift-disambiguation-popover" class="metabox-holder" ng-controller="EntitiesController">\n    <div class="postbox">\n      <div class="handlediv" title="Click to toggle"><br></div>\n      <h3 class="hndle"><span>Semantic Web</span></h3>\n      <div class="inside">\n        <form role="form">\n          <div class="form-group">\n            <div class="ui-widget">\n              <input type="text" class="form-control" id="search" placeholder="search or create">\n            </div>\n          </div>\n\n          <wl-entities on-select="onEntitySelected(textAnnotation, entityAnnotation)" text-annotation="textAnnotation"></wl-entities>\n\n        </form>\n\n        <wl-entity-input-boxes text-annotations="analysis.textAnnotations"></wl-entity-input-boxes>\n      </div>\n    </div>\n  </div>\n</div>').appendTo('form[name=post]'), $('#wordlift-disambiguation-popover').css({
    display: 'none',
    height: $('body').height() - $('#wpadminbar').height() + 12,
    top: $('#wpadminbar').height() - 1,
    right: 20
  }).draggable(), $('#search').autocomplete({
    source: ajaxurl + '?action=wordlift_search',
    minLength: 2,
    select: function(event, ui) {
      console.log(event);
      return console.log(ui);
    }
  }).data("ui-autocomplete")._renderItem = function(ul, item) {
    console.log(ul);
    return $("<li>").append("<li>\n  <div class=\"entity " + item.types + "\">\n    <!-- div class=\"thumbnail\" style=\"background-image: url('')\"></div -->\n    <div class=\"thumbnail empty\"></div>\n    <div class=\"confidence\"></div>\n    <div class=\"label\">" + item.label + "</div>\n    <div class=\"type\"></div>\n    <div class=\"source\"></div>\n  </div>\n</li>").appendTo(ul);
  }, $('#wordlift-disambiguation-popover .handlediv').click(function(e) {
    return $('#wordlift-disambiguation-popover').hide();
  }), injector = angular.bootstrap($('#wl-app'), ['wordlift.tinymce.plugin']), tinymce.PluginManager.add('wordlift', function(editor, url) {
    editor.addButton('wordlift', {
      text: 'WordLift',
      icon: false,
      onclick: function() {
        return injector.invoke([
          'EditorService', '$rootScope', function(EditorService, $rootScope) {
            return $rootScope.$apply(function() {
              var html, text;
              html = tinyMCE.activeEditor.getContent({
                format: 'raw'
              });
              text = Traslator.create(html).getText();
              return EditorService.analyze(text);
            });
          }
        ]);
      }
    });
    return editor.onClick.add(function(editor, e) {
      return injector.invoke([
        '$rootScope', function($rootScope) {
          return $rootScope.$apply(function() {
            return $rootScope.$broadcast('textAnnotationClicked', e.target.id, e);
          });
        }
      ]);
    });
  }));

}).call(this);

//# sourceMappingURL=wordlift.js.map
