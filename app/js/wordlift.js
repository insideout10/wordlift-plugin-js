(function() {
  var $, container, injector;

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

  angular.module('wordlift.tinymce.plugin.directives', ['wordlift.tinymce.plugin.controllers']).directive('wlMetaBoxSelectedEntity', function() {
    return {
      restrict: 'AE',
      scope: {
        index: '=',
        entity: '='
      },
      template: "<span>{{entity.label}} (<small>{{entity.type}}</span>)\n\n<br /><small>{{entity.thumbnail}}</small>\n<input type=\"hidden\" name=\"entities[{{index}}]['id']\" value=\"{{entity.id}}\" />\n\n<input type=\"hidden\" name=\"entities[{{index}}]['label']\" value=\"{{entity.label}}\" />\n\n<input type=\"hidden\" name=\"entities[{{index}}]['description']\" value=\"{{entity.description}}\" />\n\n<input type=\"hidden\" name=\"entities[{{index}}]['type']\" value=\"{{entity.type}}\" />\n\n<input type=\"hidden\" name=\"entities[{{index}}]['thumbnail']\" value=\"{{entity.thumbnail}}\" />\n"
    };
  }).directive('wlEntities', function() {
    return {
      restrict: 'E',
      scope: {
        textAnnotation: '='
      },
      template: "<div>\n  <ul>\n    <li ng-repeat=\"(id, entityAnnotation) in textAnnotation.entityAnnotations | orderObjectBy:'confidence':true\">\n      <div class=\"entity {{entityAnnotation.entity.type}}\" ng-class=\"{selected: true==entityAnnotation.selected}\" ng-click=\"onEntityClicked(id, entityAnnotation)\" ng-show=\"entityAnnotation.entity.label\">\n        <div class=\"thumbnail\" ng-show=\"entityAnnotation.entity.thumbnail\" title=\"{{entityAnnotation.entity.id}}\" ng-attr-style=\"background-image: url({{entityAnnotation.entity.thumbnail}})\"></div>\n        <div class=\"thumbnail empty\" ng-hide=\"entityAnnotation.entity.thumbnail\" title=\"{{entityAnnotation.entity.id}}\"></div>\n        <div class=\"confidence\" ng-bind=\"entityAnnotation.confidence\"></div>\n        <div class=\"label\" ng-bind=\"entityAnnotation.entity.label\"></div>\n        <div class=\"type\"></div>\n        <div class=\"source\" ng-class=\"entityAnnotation.entity.source\" ng-bind=\"entityAnnotation.entity.source\"></div>\n      </div>\n    </li>\n  </ul>\n</div>"
    };
  });

  angular.module('AnalysisService', []).service('AnalysisService', [
    '$http', '$q', '$rootScope', '$log', function($http, $q, $rootScope, $log) {
      return {
        isRunning: false,
        analyze: function(content) {
          var that;
          if (this.isRunning) {
            return;
          }
          this.isRunning = true;
          that = this;
          return $http.post(ajaxurl + '?action=wordlift_analyze', {
            data: content
          }).success(function(data, status, headers, config) {
            $rootScope.$broadcast('analysisReceived', that.parse(data));
            return that.isRunning = false;
          }).error(function(data, status, headers, config) {
            console.log('error received');
            return that.isRunning = false;
          });
        },
        parse: function(data) {
          var containsOrEquals, context, createEntity, createEntityAnnotation, createLanguage, createTextAnnotation, dctype, entities, entity, entityAnnotations, expand, get, getKnownType, getLanguage, graph, id, item, key, language, languages, prefixes, textAnnotations, types, value, _i, _len;
          languages = [];
          textAnnotations = {};
          entityAnnotations = {};
          entities = {};
          getKnownType = function(types) {
            var type, typesArray, _i, _j, _k, _l, _len, _len1, _len10, _len11, _len2, _len3, _len4, _len5, _len6, _len7, _len8, _len9, _m, _n, _o, _p, _q, _r, _s, _t;
            if (types == null) {
              return null;
            }
            typesArray = angular.isArray(types) ? types : [types];
            for (_i = 0, _len = typesArray.length; _i < _len; _i++) {
              type = typesArray[_i];
              if ('http://schema.org/Person' === expand(type)) {
                return 'person';
              }
            }
            for (_j = 0, _len1 = typesArray.length; _j < _len1; _j++) {
              type = typesArray[_j];
              if ('http://rdf.freebase.com/ns/people.person' === expand(type)) {
                return 'person';
              }
            }
            for (_k = 0, _len2 = typesArray.length; _k < _len2; _k++) {
              type = typesArray[_k];
              if ('http://schema.org/Organization' === expand(type)) {
                return 'organization';
              }
            }
            for (_l = 0, _len3 = typesArray.length; _l < _len3; _l++) {
              type = typesArray[_l];
              if ('http://rdf.freebase.com/ns/government.government' === expand(type)) {
                return 'organization';
              }
            }
            for (_m = 0, _len4 = typesArray.length; _m < _len4; _m++) {
              type = typesArray[_m];
              if ('http://schema.org/Newspaper' === expand(type)) {
                return 'organization';
              }
            }
            for (_n = 0, _len5 = typesArray.length; _n < _len5; _n++) {
              type = typesArray[_n];
              if ('http://schema.org/Place' === expand(type)) {
                return 'place';
              }
            }
            for (_o = 0, _len6 = typesArray.length; _o < _len6; _o++) {
              type = typesArray[_o];
              if ('http://rdf.freebase.com/ns/location.location' === expand(type)) {
                return 'place';
              }
            }
            for (_p = 0, _len7 = typesArray.length; _p < _len7; _p++) {
              type = typesArray[_p];
              if ('http://schema.org/Event' === expand(type)) {
                return 'event';
              }
            }
            for (_q = 0, _len8 = typesArray.length; _q < _len8; _q++) {
              type = typesArray[_q];
              if ('http://dbpedia.org/ontology/Event' === expand(type)) {
                return 'event';
              }
            }
            for (_r = 0, _len9 = typesArray.length; _r < _len9; _r++) {
              type = typesArray[_r];
              if ('http://rdf.freebase.com/ns/music.artist' === expand(type)) {
                return 'music';
              }
            }
            for (_s = 0, _len10 = typesArray.length; _s < _len10; _s++) {
              type = typesArray[_s];
              if ('http://schema.org/MusicAlbum' === expand(type)) {
                return 'music';
              }
            }
            for (_t = 0, _len11 = typesArray.length; _t < _len11; _t++) {
              type = typesArray[_t];
              if ('http://www.opengis.net/gml/_Feature' === expand(type)) {
                return 'place';
              }
            }
            return 'thing';
          };
          createEntity = function(item, language) {
            var entity, freebaseThumbnails, id, thumbnail, thumbnails, types;
            id = get('@id', item);
            types = get('@type', item);
            thumbnails = get('foaf:depiction', item);
            freebaseThumbnails = get('http://rdf.freebase.com/ns/common.topic.image', item);
            freebaseThumbnails = angular.isArray(freebaseThumbnails) ? freebaseThumbnails : [freebaseThumbnails];
            freebaseThumbnails = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = freebaseThumbnails.length; _i < _len; _i++) {
                thumbnail = freebaseThumbnails[_i];
                _results.push("admin-ajax.php?action=wordlift_freebase_image&url=" + (escape(thumbnail)));
              }
              return _results;
            })();
            thumbnails = thumbnails.concat(freebaseThumbnails);
            entity = {
              id: id,
              thumbnail: null,
              thumbnails: thumbnails,
              type: getKnownType(types),
              types: types,
              description: getLanguage('rdfs:comment', item, language),
              descriptions: get('rdfs:comment', item),
              label: getLanguage('rdfs:label', item, language),
              labels: get('rdfs:label', item),
              source: id.match('^http://rdf.freebase.com/.*$') ? 'freebase' : id.match('^http://dbpedia.org/.*$') ? 'dbpedia' : 'wordlift',
              _item: item
            };
            if ((thumbnails != null) && angular.isArray(thumbnails)) {
              $q.all((function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = thumbnails.length; _i < _len; _i++) {
                  thumbnail = thumbnails[_i];
                  _results.push($http.head(thumbnail));
                }
                return _results;
              })()).then(function(results) {
                var result;
                entity.thumbnails = (function() {
                  var _i, _len, _results;
                  _results = [];
                  for (_i = 0, _len = results.length; _i < _len; _i++) {
                    result = results[_i];
                    if (200 === result.status) {
                      _results.push(result.config.url);
                    }
                  }
                  return _results;
                })();
                if (0 < entity.thumbnails.length) {
                  return entity.thumbnail = entity.thumbnails[0];
                }
              });
            }
            return entity;
          };
          createEntityAnnotation = function(item) {
            var entity, textAnnotation;
            textAnnotation = textAnnotations[get('dc:relation', item)];
            entity = {
              id: get('@id', item),
              label: get('enhancer:entity-label', item),
              confidence: get('enhancer:confidence', item),
              entity: entities[get('enhancer:entity-reference', item)],
              relation: textAnnotations[get('dc:relation', item)],
              _item: item
            };
            if (textAnnotation != null) {
              textAnnotation.entityAnnotations[entity.id] = entity;
            }
            return entity;
          };
          createTextAnnotation = function(item) {
            return {
              id: get('@id', item),
              selectedText: get('enhancer:selected-text', item)['@value'],
              selectionPrefix: get('enhancer:selection-prefix', item)['@value'],
              selectionSuffix: get('enhancer:selection-suffix', item)['@value'],
              confidence: get('enhancer:confidence', item),
              entityAnnotations: {},
              _item: item
            };
          };
          createLanguage = function(item) {
            return {
              code: get('dc:language', item),
              confidence: get('enhancer:confidence', item),
              _item: item
            };
          };
          get = function(what, container) {
            var key, value, whatExp;
            whatExp = expand(what);
            for (key in container) {
              value = container[key];
              if (whatExp === expand(key)) {
                return value;
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
                return item['@value'];
              }
            }
            return null;
          };
          containsOrEquals = function(what, where) {
            var item, whatExp, whereArray, _i, _len;
            if (where == null) {
              return false;
            }
            whereArray = angular.isArray(where) ? where : [where];
            whatExp = expand(what);
            for (_i = 0, _len = whereArray.length; _i < _len; _i++) {
              item = whereArray[_i];
              if (whatExp === expand(item)) {
                return true;
              }
            }
            return false;
          };
          expand = function(content) {
            var matches, path, prefix, prepend;
            if (null === (matches = content.match(/([\w|\d]+):(.*)/))) {
              return content;
            }
            prefix = matches[1];
            path = matches[2];
            prepend = prefixes[prefix] != null ? prefixes[prefix] : "" + prefix + ":";
            return prepend + path;
          };
          context = data['@context'] != null ? data['@context'] : {};
          graph = data['@graph'] != null ? data['@graph'] : {};
          prefixes = [];
          for (key in context) {
            value = context[key];
            if (-1 === key.indexOf(':') && angular.isString(value)) {
              prefixes[key] = value;
            }
          }
          for (_i = 0, _len = graph.length; _i < _len; _i++) {
            item = graph[_i];
            id = item['@id'];
            types = item['@type'];
            dctype = get('dc:type', item);
            if (containsOrEquals('enhancer:TextAnnotation', types) && containsOrEquals('dc:LinguisticSystem', dctype)) {
              languages.push(createLanguage(item));
            } else if (containsOrEquals('enhancer:TextAnnotation', types)) {
              textAnnotations[id] = item;
            } else if (containsOrEquals('enhancer:EntityAnnotation', types)) {
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
            entity = createEntity(item, language);
            entities[id] = entity;
          }
          for (id in textAnnotations) {
            item = textAnnotations[id];
            textAnnotations[id] = createTextAnnotation(item);
          }
          for (id in entityAnnotations) {
            item = entityAnnotations[id];
            entityAnnotations[id] = createEntityAnnotation(item);
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
    }
  ]);

  angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService']).service('EditorService', [
    'AnalysisService', '$rootScope', '$log', 'Configuration', function(AnalysisService, $rootScope, $log, Configuration) {
      var service;
      service = {
        embedAnalysis: function(analysis) {
          var cleanUp, currentHtmlContent, id, isDirty, r, replace, selPrefix, selSuffix, selText, spanre, textAnnotation, _ref;
          cleanUp = function(text) {
            return text.replace('\\', '\\\\').replace('\(', '\\(').replace('\)', '\\)').replace('\n', '\\n?').replace('-', '\\-').replace('\x20', '\\s').replace('\xa0', '&nbsp;');
          };
          currentHtmlContent = tinyMCE.get('content').getContent({
            format: 'raw'
          });
          spanre = /<span class="textannotation"[^>]*>([^<]*)<\/span>/gi;
          while (spanre.test(currentHtmlContent)) {
            currentHtmlContent = currentHtmlContent.replace(spanre, '$1');
          }
          _ref = analysis.textAnnotations;
          for (id in _ref) {
            textAnnotation = _ref[id];
            selPrefix = cleanUp(textAnnotation.selectionPrefix.substr(-1));
            if ('' === selPrefix) {
              selPrefix = '^|\\W';
            }
            selSuffix = cleanUp(textAnnotation.selectionSuffix.substr(0, 1));
            if ('' === selSuffix) {
              selSuffix = '$|\\W';
            }
            selText = textAnnotation.selectedText;
            r = new RegExp("(" + selPrefix + "(?:<[^>]+>){0,})(" + selText + ")((?:<[^>]+>){0,}" + selSuffix + ")(?![^<]*\"[^<]*>)");
            replace = "$1<span class=\"textannotation\" id=\"" + id + "\" typeof=\"http://fise.iks-project.eu/ontology/TextAnnotation\">$2</span>$3";
            currentHtmlContent = currentHtmlContent.replace(r, replace);
          }
          isDirty = tinyMCE.get('content').isDirty();
          tinyMCE.get('content').setContent(currentHtmlContent);
          if (!isDirty) {
            tinyMCE.get('content').isNotDirty = 1;
          }
          return tinyMCE.get('content').onClick.add(function(editor, e) {
            return $rootScope.$apply($log.debug("Going to notify click on annotation with id " + e.target.id), $rootScope.$broadcast('textAnnotationClicked', e.target.id, e));
          });
        },
        ping: function(message) {
          return $log.debug(message);
        },
        analyze: function(content) {
          if (AnalysisService.isRunning) {
            return;
          }
          $('.mce_wordlift').addClass('running');
          tinyMCE.get('content').getBody().setAttribute('contenteditable', false);
          return AnalysisService.analyze(content);
        },
        getEditor: function() {
          return tinyMCE.get('content');
        },
        getBody: function() {
          return this.getEditor().getBody();
        },
        getDOM: function() {
          return this.getEditor().dom;
        },
        getWinPos: function(elem) {
          var ed, el, left, top;
          ed = this.getEditor();
          el = elem.target;
          top = $('#content_ifr').offset().top - $('body').scrollTop() + el.offsetTop - $(ed.getBody()).scrollTop();
          left = $('#content_ifr').offset().left - $('body').scrollLeft() + el.offsetLeft - $(ed.getBody()).scrollLeft();
          return {
            top: top,
            left: left
          };
        }
      };
      $rootScope.$on('DisambiguationWidget.entitySelected', function(event, obj) {
        var cssClasses, dom, elem, id;
        cssClasses = "textannotation highlight " + obj.entity.type + " disambiguated";
        dom = tinyMCE.get("content").dom;
        id = obj.relation.id;
        elem = dom.get(id);
        dom.setAttrib(id, 'class', cssClasses);
        dom.setAttrib(id, 'itemscope', 'itemscope');
        dom.setAttrib(id, 'itemtype', obj.entity.type);
        return dom.setAttrib(id, 'itemid', obj.entity.id);
      });
      $rootScope.$on('analysisReceived', function(event, analysis) {
        $log.info('analysisReceived [ analysis :: ' + analysis + ' ]');
        service.embedAnalysis(analysis);
        $('.mce_wordlift').removeClass('running');
        return tinyMCE.get('content').getBody().setAttribute('contenteditable', true);
      });
      return service;
    }
  ]);

  angular.module('wordlift.tinymce.plugin.services.EntityService', ['wordlift.tinymce.plugin.config']).service('EntityService', [
    '$log', function($log) {
      var container;
      container = $('#wordlift_selected_entitities_box');
      return {
        select: function(entityAnnotation) {
          var description, entity, entityDiv, id, image, images, label, type, _i, _len;
          $log.info('select');
          $log.info(entityAnnotation);
          entity = entityAnnotation.entity;
          id = entity.id;
          label = entity.label;
          description = entity.description != null ? entity.description : '';
          images = entity.thumbnails;
          type = entity.type;
          entityDiv = $("<div itemid='" + id + "'></div>").append("<input type='text' name='wl_entities[" + id + "][uri]' value='" + id + "'>").append("<input type='text' name='wl_entities[" + id + "][label]' value='" + label + "'>").append("<input type='text' name='wl_entities[" + id + "][description]' value='" + description + "'>").append("<input type='text' name='wl_entities[" + id + "][type]' value='" + type + "'>");
          if (angular.isArray(images)) {
            for (_i = 0, _len = images.length; _i < _len; _i++) {
              image = images[_i];
              entityDiv.append("<input type='text' name='wl_entities[" + id + "][image]' value='" + image + "'>");
            }
          } else {
            entityDiv.append("<input type='text' name='wl_entities[" + id + "][image]' value='" + images + "'>");
          }
          return container.append(entityDiv);
        },
        deselect: function(entityAnnotation) {
          var entity, id;
          $log.info('deselect');
          $log.info(entityAnnotation);
          entity = entityAnnotation.entity;
          id = entity.id;
          return $("div[itemid='" + id + "']").remove();
        }
      };
    }
  ]);

  angular.module('wordlift.tinymce.plugin.services', ['wordlift.tinymce.plugin.config', 'wordlift.tinymce.plugin.services.EditorService', 'AnalysisService', 'wordlift.tinymce.plugin.services.EntityService']);

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
  }).controller('EntitiesController', [
    'EditorService', 'EntityService', '$log', '$scope', 'Configuration', function(EditorService, EntityService, $log, $scope, Configuration) {
      var el, scroll, setArrowTop;
      $scope.analysis = null;
      $scope.textAnnotation = null;
      $scope.textAnnotationSpan = null;
      $scope.annotations = [];
      $scope.selectedEntity = void 0;
      $scope.selectedEntitiesMapping = {};
      $scope.getSelectedEntities = function() {
        var entities, key, value, _ref;
        entities = [];
        _ref = $scope.selectedEntitiesMapping;
        for (key in _ref) {
          value = _ref[key];
          entities.push(value);
        }
        return entities;
      };
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
      $scope.onEntityClicked = function(entityIndex, entityAnnotation) {
        $scope.selectedEntity = entityIndex;
        $scope.selectedEntitiesMapping[entityAnnotation.relation.id] = entityAnnotation.entity;
        entityAnnotation.selected = !entityAnnotation.selected;
        if (entityAnnotation.selected) {
          EntityService.select(entityAnnotation);
        } else {
          EntityService.deselect(entityAnnotation);
        }
        return $scope.$emit('DisambiguationWidget.entitySelected', entityAnnotation);
      };
      $scope.$on('analysisReceived', function(event, analysis) {
        return $scope.analysis = analysis;
      });
      return $scope.$on('textAnnotationClicked', function(event, id, sourceElement) {
        var pos, _ref, _ref1;
        $scope.selectedEntity = void 0;
        $scope.textAnnotationSpan = angular.element(sourceElement.target);
        $scope.textAnnotation = $scope.analysis.textAnnotations[id];
        if (0 === ((_ref = $scope.textAnnotation) != null ? (_ref1 = _ref.entityAnnotations) != null ? _ref1.length : void 0 : void 0)) {
          return $('#wordlift-disambiguation-popover').hide();
        } else {
          pos = EditorService.getWinPos(sourceElement);
          setArrowTop(pos.top - 50);
          return $('#wordlift-disambiguation-popover').show();
        }
      });
    }
  ]);

  $ = jQuery;

  angular.module('wordlift.tinymce.plugin', ['wordlift.tinymce.plugin.controllers', 'wordlift.tinymce.plugin.directives']);

  $(container = $('<div id="wordlift-disambiguation-popover" class="metabox-holder">\n  <div class="postbox">\n    <div class="handlediv" title="Click to toggle"><br></div>\n    <h3 class="hndle"><span>Semantic Web</span></h3>\n    <div class="inside">\n      <form role="form">\n        <div class="form-group">\n          <div class="ui-widget">\n            <input type="text" class="form-control" id="search" placeholder="search or create">\n          </div>\n        </div>\n\n        <wl-entities annotation="textAnnotation"></wl-entities>\n\n      </form>\n    </div>\n  </div>\n</div>').appendTo('body').css({
    display: 'none',
    height: $('body').height() - $('#wpadminbar').height() + 32,
    top: $('#wpadminbar').height() - 1,
    right: 0
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
    return container.hide();
  }), $('body').attr('ng-controller', 'EntitiesController'), injector = angular.bootstrap(document, ['wordlift.tinymce.plugin']), tinymce.PluginManager.add('wordlift', function(editor, url) {
    return editor.addButton('wordlift', {
      text: 'WordLift',
      icon: false,
      onclick: function() {
        return injector.invoke([
          'EditorService', function(EditorService) {
            return EditorService.analyze(tinyMCE.activeEditor.getContent({
              format: 'text'
            }));
          }
        ]);
      }
    });
  }));

}).call(this);

//# sourceMappingURL=wordlift.js.map
