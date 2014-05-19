(function() {
  var $, buildChord, getChordData, timelineData;

  $ = jQuery;

  getChordData = function(params) {
    return $.post(params.ajax_url, {
      action: params.action,
      post_id: params.post_id,
      depth: params.depth
    }, function(response) {
      var data;
      data = JSON.parse(response);
      return buildChord(data, params);
    });
  };

  buildChord = function(data, params) {
    var arc, beautifyLabel, chord, colorLuminance, e, entity, getEntityIndex, height, innerRadius, matrix, outerRadius, rad2deg, relation, rotate, sign, size, tooltip, translate, viz, width, x, y, _i, _j, _len, _len1, _ref, _ref1;
    if (data.entities.length < 2) {
      return;
    }
    translate = function(x, y, size) {
      return 'translate(' + x * size + ',' + y * size + ')';
    };
    rotate = function(x) {
      return "rotate(" + x + ")";
    };
    rad2deg = function(a) {
      return (a / (2 * Math.PI)) * 360;
    };
    sign = function(n) {
      if (n >= 0.0) {
        return 1;
      } else {
        return -1;
      }
    };
    beautifyLabel = function(txt) {
      if (txt.length > 12) {
        return txt.substring(0, 12) + '...';
      }
      return txt;
    };
    colorLuminance = function(hex, lum) {
      var c, i, rgb, _i;
      hex = String(hex).replace(/[^0-9a-f]/gi, '');
      if (hex.length < 6) {
        hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
      }
      lum = lum || 0;
      rgb = "#";
      c = void 0;
      i = void 0;
      for (i = _i = 0; _i <= 3; i = ++_i) {
        c = parseInt(hex.substr(i * 2, 2), 16);
        c = Math.round(Math.min(Math.max(0, c + (c * lum)), 255)).toString(16);
        rgb += ("00" + c).substr(c.length);
      }
      return rgb;
    };
    getEntityIndex = function(uri) {
      var i, _i, _ref;
      for (i = _i = 0, _ref = data.entities.length; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (data.entities[i].uri === uri) {
          return i;
        }
      }
      return -1;
    };
    matrix = [];
    _ref = data.entities;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      entity = _ref[_i];
      matrix.push((function() {
        var _j, _len1, _ref1, _results;
        _ref1 = data.entities;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          e = _ref1[_j];
          _results.push(0);
        }
        return _results;
      })());
    }
    _ref1 = data.relations;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      relation = _ref1[_j];
      x = getEntityIndex(relation.s);
      y = getEntityIndex(relation.o);
      matrix[x][y] = 1;
      matrix[y][x] = 1;
    }
    viz = d3.select('#' + params.widget_id).append('svg');
    viz.attr('width', '100%').attr('height', '100%');
    width = parseInt(viz.style('width'));
    height = parseInt(viz.style('height'));
    size = height < width ? height : width;
    innerRadius = size * 0.2;
    outerRadius = size * 0.25;
    arc = d3.svg.arc().innerRadius(innerRadius).outerRadius(outerRadius);
    chord = d3.layout.chord().padding(0.3).matrix(matrix);
    viz.selectAll('chords').data(chord.chords).enter().append('path').attr('class', 'relation').attr('d', d3.svg.chord().radius(innerRadius)).attr('transform', translate(0.5, 0.5, size)).style('opacity', 0.2).on('mouseover', function() {
      return d3.select(this).style('opacity', 0.8);
    }).on('mouseout', function() {
      return d3.select(this).style('opacity', 0.2);
    });
    viz.selectAll('arcs').data(chord.groups).enter().append('path').attr('class', function(d) {
      return "entity " + data.entities[d.index].css_class;
    }).attr('d', arc).attr('transform', translate(0.5, 0.5, size)).style('fill', function(d) {
      var baseColor, type;
      baseColor = params.main_color;
      type = data.entities[d.index].type;
      if (type === 'post') {
        return baseColor;
      }
      if (type === 'entity') {
        return colorLuminance(baseColor, -0.5);
      }
      return colorLuminance(baseColor, 0.5);
    });
    viz.selectAll('arcs_labels').data(chord.groups).enter().append('text').attr('class', 'label').html(function(d) {
      var lab;
      lab = data.entities[d.index].label;
      return beautifyLabel(lab);
    }).attr('font-size', function() {
      var fontSize;
      fontSize = parseInt(size / 35);
      if (fontSize < 8) {
        fontSize = 8;
      }
      return fontSize + 'px';
    }).attr('transform', function(d) {
      var alpha, labelAngle, labelWidth, r;
      alpha = d.startAngle - Math.PI / 2 + Math.abs((d.endAngle - d.startAngle) / 2);
      labelWidth = 3;
      labelAngle;
      if (alpha > Math.PI / 2) {
        labelAngle = alpha - Math.PI;
        labelWidth += d3.select(this)[0][0].clientWidth;
      } else {
        labelAngle = alpha;
      }
      labelAngle = rad2deg(labelAngle);
      r = (outerRadius + labelWidth) / size;
      x = 0.5 + (r * Math.cos(alpha));
      y = 0.5 + (r * Math.sin(alpha));
      return translate(x, y, size) + rotate(labelAngle);
    });
    tooltip = d3.select('body').append('div').attr('class', 'tooltip').style('background-color', 'white').style('opacity', 0.0).style('position', 'absolute').style('z-index', 100);
    return viz.selectAll('.entity, .label').on('mouseover', function(c) {
      d3.select(this).attr('cursor', 'pointer');
      viz.selectAll('.relation').filter(function(d, i) {
        return d.source.index === c.index || d.target.index === c.index;
      }).style('opacity', 0.8);
      return tooltip.text(data.entities[c.index].label).style('opacity', 1.0);
    }).on('mouseout', function(c) {
      viz.selectAll('.relation').filter(function(d, i) {
        return d.source.index === c.index || d.target.index === c.index;
      }).style('opacity', 0.2);
      return tooltip.style('opacity', 0.0);
    }).on('mousemove', function() {
      return tooltip.style("left", d3.event.pageX + "px").style("top", (d3.event.pageY - 30) + "px");
    }).on('click', function(d) {
      var url;
      url = data.entities[d.index].url;
      return window.location = url;
    });
  };

  $('.wl-chord-widget').each(function() {
    var wl_local_chord_params;
    wl_local_chord_params = $(this).data();
    wl_local_chord_params.widget_id = $(this).attr('id');
    $.extend(wl_local_chord_params, wl_chord_params);
    return getChordData(wl_local_chord_params);
  });

  $ = jQuery;

  timelineData = {
    timeline: {
      headline: "Sh*t People Say",
      type: "default",
      text: "People say stuff",
      startDate: "2012,1,26",
      date: [
        {
          startDate: "2011,12,12",
          endDate: "2012,1,27",
          headline: "Vine",
          text: "<p>Vine Test</p>",
          asset: {
            media: "https://vine.co/v/b55LOA1dgJU",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,26",
          endDate: "2012,1,27",
          headline: "Sh*t Politicians Say",
          text: "<p>In true political fashion, his character rattles off common jargon heard from people running for office.</p>",
          asset: {
            media: "http://youtu.be/u4XpeU9erbg",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,10",
          headline: "Sh*t Nobody Says",
          text: "<p>Have you ever heard someone say “can I burn a copy of your Nickelback CD?” or “my Bazooka gum still has flavor!” Nobody says that.</p>",
          asset: {
            media: "http://youtu.be/f-x8t0JOnVw",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,26",
          headline: "Sh*t Chicagoans Say",
          text: "",
          asset: {
            media: "http://youtu.be/Ofy5gNkKGOo",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2011,12,12",
          headline: "Sh*t Girls Say",
          text: "",
          asset: {
            media: "http://youtu.be/u-yLGIH7W9Y",
            credit: "",
            caption: "Writers & Creators: Kyle Humphrey & Graydon Sheppard"
          }
        }, {
          startDate: "2012,1,4",
          headline: "Sh*t Broke People Say",
          text: "",
          asset: {
            media: "http://youtu.be/zyyalkHjSjo",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,4",
          headline: "Sh*t Silicon Valley Says",
          text: "",
          asset: {
            media: "http://youtu.be/BR8zFANeBGQ",
            credit: "",
            caption: "written, filmed, and edited by Kate Imbach & Tom Conrad"
          }
        }, {
          startDate: "2011,12,25",
          headline: "Sh*t Vegans Say",
          text: "",
          asset: {
            media: "http://youtu.be/OmWFnd-p0Lw",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,23",
          headline: "Sh*t Graphic Designers Say",
          text: "",
          asset: {
            media: "http://youtu.be/KsT3QTmsN5Q",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2011,12,30",
          headline: "Sh*t Wookiees Say",
          text: "",
          asset: {
            media: "http://youtu.be/vJpBCzzcSgA",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,17",
          headline: "Sh*t People Say About Sh*t People Say Videos",
          text: "",
          asset: {
            media: "http://youtu.be/c9ehQ7vO7c0",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,20",
          headline: "Sh*t Social Media Pros Say",
          text: "",
          asset: {
            media: "http://youtu.be/eRQe-BT9g_U",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,11",
          headline: "Sh*t Old People Say About Computers",
          text: "",
          asset: {
            media: "http://youtu.be/HRmc5uuoUzA",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,11",
          headline: "Sh*t College Freshmen Say",
          text: "",
          asset: {
            media: "http://youtu.be/rwozXzo0MZk",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2011,12,16",
          headline: "Sh*t Girls Say - Episode 2",
          text: "",
          asset: {
            media: "http://youtu.be/kbovd-e-hRg",
            credit: "",
            caption: "Writers & Creators: Kyle Humphrey & Graydon Sheppard"
          }
        }, {
          startDate: "2011,12,24",
          headline: "Sh*t Girls Say - Episode 3 Featuring Juliette Lewis",
          text: "",
          asset: {
            media: "http://youtu.be/bDHUhT71JN8",
            credit: "",
            caption: "Writers & Creators: Kyle Humphrey & Graydon Sheppard"
          }
        }, {
          startDate: "2012,1,27",
          headline: "Sh*t Web Designers Say",
          text: "",
          asset: {
            media: "http://youtu.be/MEOb_meSHhQ",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,12",
          headline: "Sh*t Hipsters Say",
          text: "No meme is complete without a bit of hipster-bashing.",
          asset: {
            media: "http://youtu.be/FUhrSVyu0Kw",
            credit: "",
            caption: "Written, Directed, Conceptualized and Performed by Carrie Valentine and Jessica Katz"
          }
        }, {
          startDate: "2012,1,6",
          headline: "Sh*t Cats Say",
          text: "No meme is complete without cats. This had to happen, obviously.",
          asset: {
            media: "http://youtu.be/MUX58Vi-YLg",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,21",
          headline: "Sh*t Cyclists Say",
          text: "",
          asset: {
            media: "http://youtu.be/GMCkuqL9IcM",
            credit: "",
            caption: "Video script, production, and editing by Allen Krughoff of Hardcastle Photography"
          }
        }, {
          startDate: "2011,12,30",
          headline: "Sh*t Yogis Say",
          text: "",
          asset: {
            media: "http://youtu.be/IMC1_RH_b3k",
            credit: "",
            caption: ""
          }
        }, {
          startDate: "2012,1,18",
          headline: "Sh*t New Yorkers Say",
          text: "",
          asset: {
            media: "http://youtu.be/yRvJylbSg7o",
            credit: "",
            caption: "Directed and Edited by Matt Mayer, Produced by Seth Keim, Written by Eliot Glazer. Featuring Eliot and Ilana Glazer, who are siblings, not married."
          }
        }
      ]
    }
  };

  $(document).ready((function(_this) {
    return function() {
      createStoryJS(function() {
        return {
          type: 'timeline',
          width: '800',
          height: '600',
          source: 'path_to_json/or_link_to_googlespreadsheet',
          embed_id: 'wl-timeline-11121221231231'
        };
      });
      return $('.wl-timeline-widget').each(function() {
        var wl_local_timeline_params;
        wl_local_timeline_params = $(this).data();
        wl_local_timeline_params.widget_id = $(this).attr('id');
        $.extend(wl_local_timeline_params, wl_chord_params);
        return console.log(wl_local_timeline_params);
      });
    };
  })(this));

}).call(this);

//# sourceMappingURL=wordlift.ui.js.map
