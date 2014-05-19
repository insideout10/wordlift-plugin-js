$ = jQuery

getChordData = (params) ->
  $.post params.ajax_url, {
      action:  params.action
      post_id: params.post_id
      depth:   params.depth
  	}, (response) ->
    data  = JSON.parse response
    buildChord data, params

buildChord = (data, params) ->
  return if data.entities.length < 2

#  niceData = 'entities' in dataMock && 'relations' in dataMock
  #  niceData = niceData && (dataMock.entities.length) >= 2 && (dataMock.relations >= 1)
  #  if ( niceData )
  #    d3.select( '#' + wl_chord_params.widget_id )
  #     .style('height', '50px')
  #     .html(' --- WordLift shortcode: No entities found. --- ')
  #  return;
  #}

  translate = (x, y, size) -> 'translate(' + x * size + ',' + y * size + ')'

  rotate = (x) -> "rotate(#{x})"

  rad2deg = (a) ->  ( a / (2*Math.PI)) * 360

  sign = (n) -> if n >= 0.0 then 1 else -1

  beautifyLabel = (txt) ->
    return txt.substring(0, 12) + '...' if txt.length > 12
    txt

  colorLuminance = (hex, lum) ->
    # Validate hex string.
    hex = String(hex).replace(/[^0-9a-f]/gi, '')

    if (hex.length < 6)
      hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2]

    lum = lum or 0

    # Convert to decimal and change luminosity.
    rgb = "#"
    c = undefined
    i = undefined

    for i in [0..3]
      c = parseInt(hex.substr(i*2,2), 16)
      c = Math.round(Math.min(Math.max(0, c + (c * lum)), 255)).toString(16)
      rgb += ("00"+c).substr(c.length)

    rgb

  getEntityIndex = (uri) ->
    return i for i in [0..data.entities.length] when data.entities[i].uri is uri
    -1

# Build adiacency matrix.
  matrix = []
  matrix.push (0 for e in data.entities) for entity in data.entities

  for relation in data.relations
    x = getEntityIndex relation.s
    y = getEntityIndex relation.o
    matrix[x][y] = 1
    matrix[y][x] = 1
  
  viz = d3.select('#' + params.widget_id ).append('svg')
  viz.attr('width', '100%').attr('height', '100%')

  # Getting dimensions in pixels.
  width = parseInt(viz.style('width'))
  height = parseInt(viz.style('height'))
  size =  if height < width then height else width
  innerRadius = size*0.2
  outerRadius = size*0.25
  arc = d3.svg.arc().innerRadius(innerRadius).outerRadius(outerRadius)

  chord = d3.layout.chord()
    .padding(0.3)
    .matrix(matrix)

  # Draw relations.
  viz.selectAll('chords')
    .data(chord.chords)
    .enter()
    .append('path')
    .attr('class', 'relation')
    .attr('d', d3.svg.chord().radius(innerRadius))
    .attr('transform', translate(0.5, 0.5, size) )
    .style('opacity', 0.2)
    .on('mouseover', ->  d3.select(this).style('opacity', 0.8) )
    .on('mouseout', ->  d3.select(this).style('opacity', 0.2) )

  # Draw entities.
  viz.selectAll('arcs')
    .data(chord.groups)
    .enter()
    .append('path')
    .attr('class', (d) ->
      return "entity #{data.entities[d.index].css_class}"
    )
    .attr('d', arc)
    .attr('transform', translate(0.5, 0.5, size))
    .style('fill', (d) ->
      baseColor = params.main_color;
      type = data.entities[d.index].type
      return baseColor if(type == 'post')
      return colorLuminance( baseColor, -0.5) if type is 'entity'
      colorLuminance( baseColor, 0.5 )
    )

  # Draw entity labels.
  viz.selectAll('arcs_labels')
    .data(chord.groups)
    .enter()
    .append('text')
    .attr('class', 'label')
    .html( (d) ->
      lab = data.entities[d.index].label
      beautifyLabel(lab)
    )
    .attr('font-size', ->
      fontSize = parseInt( size/35 )
      fontSize = 8 if(fontSize < 8)
      fontSize + 'px'
    )
    .attr('transform', (d) ->
      alpha = d.startAngle - Math.PI/2 + Math.abs((d.endAngle - d.startAngle)/2)
      labelWidth = 3
      labelAngle
      if(alpha > Math.PI/2)
        labelAngle = alpha - Math.PI
        labelWidth += d3.select(this)[0][0].clientWidth
      else
       labelAngle = alpha

      labelAngle = rad2deg( labelAngle )

      r = (outerRadius + labelWidth)/size
      x = 0.5 + ( r * Math.cos(alpha) )
      y = 0.5 + ( r * Math.sin(alpha) )

      translate(x, y, size) + rotate( labelAngle )
    )

  # Creating an hidden tooltip.
  tooltip = d3.select('body').append('div')
    .attr('class', 'tooltip')
    .style('background-color', 'white')
    .style('opacity', 0.0)
    .style('position', 'absolute')
    .style('z-index', 100)

  #  Dynamic behavior for entities.
  viz.selectAll('.entity, .label')
    .on('mouseover', (c) ->
      d3.select(this).attr('cursor','pointer')
      viz.selectAll('.relation')
        .filter( (d, i) -> d.source.index is c.index or d.target.index is c.index )
        .style( 'opacity', 0.8)

      # Show tooltip.
      tooltip.text( data.entities[c.index].label ).style('opacity', 1.0 )
    )
    .on('mouseout', (c) ->
      viz.selectAll('.relation')
        .filter( (d, i) -> d.source.index is c.index or d.target.index is c.index )
        .style( 'opacity', 0.2 )

        # Hide tooltip.
        tooltip.style('opacity', 0.0)
    )
    .on('mousemove', ->
      # Change tooltip position.
      tooltip.style("left", (d3.event.pageX) + "px")
        .style("top", (d3.event.pageY - 30) + "px")
    )
    .on('click', (d) ->
      url = data.entities[d.index].url
      window.location = url
    )

$('.wl-chord-widget').each( () ->
  # Get local params.
  wl_local_chord_params = $(this).data()
  wl_local_chord_params.widget_id = $(this).attr('id');
  
  # Merge local and global params.
  $.extend wl_local_chord_params, wl_chord_params
  
  # Launch chord.
  getChordData wl_local_chord_params
);
$ = jQuery

timelineData = timeline:
  headline: "Sh*t People Say"
  type: "default"
  text: "People say stuff"
  startDate: "2012,1,26"
  date: [
    {
      startDate: "2011,12,12"
      endDate: "2012,1,27"
      headline: "Vine"
      text: "<p>Vine Test</p>"
      asset:
        media: "https://vine.co/v/b55LOA1dgJU"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,26"
      endDate: "2012,1,27"
      headline: "Sh*t Politicians Say"
      text: "<p>In true political fashion, his character rattles off common jargon heard from people running for office.</p>"
      asset:
        media: "http://youtu.be/u4XpeU9erbg"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,10"
      headline: "Sh*t Nobody Says"
      text: "<p>Have you ever heard someone say “can I burn a copy of your Nickelback CD?” or “my Bazooka gum still has flavor!” Nobody says that.</p>"
      asset:
        media: "http://youtu.be/f-x8t0JOnVw"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,26"
      headline: "Sh*t Chicagoans Say"
      text: ""
      asset:
        media: "http://youtu.be/Ofy5gNkKGOo"
        credit: ""
        caption: ""
    }
    {
      startDate: "2011,12,12"
      headline: "Sh*t Girls Say"
      text: ""
      asset:
        media: "http://youtu.be/u-yLGIH7W9Y"
        credit: ""
        caption: "Writers & Creators: Kyle Humphrey & Graydon Sheppard"
    }
    {
      startDate: "2012,1,4"
      headline: "Sh*t Broke People Say"
      text: ""
      asset:
        media: "http://youtu.be/zyyalkHjSjo"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,4"
      headline: "Sh*t Silicon Valley Says"
      text: ""
      asset:
        media: "http://youtu.be/BR8zFANeBGQ"
        credit: ""
        caption: "written, filmed, and edited by Kate Imbach & Tom Conrad"
    }
    {
      startDate: "2011,12,25"
      headline: "Sh*t Vegans Say"
      text: ""
      asset:
        media: "http://youtu.be/OmWFnd-p0Lw"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,23"
      headline: "Sh*t Graphic Designers Say"
      text: ""
      asset:
        media: "http://youtu.be/KsT3QTmsN5Q"
        credit: ""
        caption: ""
    }
    {
      startDate: "2011,12,30"
      headline: "Sh*t Wookiees Say"
      text: ""
      asset:
        media: "http://youtu.be/vJpBCzzcSgA"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,17"
      headline: "Sh*t People Say About Sh*t People Say Videos"
      text: ""
      asset:
        media: "http://youtu.be/c9ehQ7vO7c0"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,20"
      headline: "Sh*t Social Media Pros Say"
      text: ""
      asset:
        media: "http://youtu.be/eRQe-BT9g_U"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,11"
      headline: "Sh*t Old People Say About Computers"
      text: ""
      asset:
        media: "http://youtu.be/HRmc5uuoUzA"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,11"
      headline: "Sh*t College Freshmen Say"
      text: ""
      asset:
        media: "http://youtu.be/rwozXzo0MZk"
        credit: ""
        caption: ""
    }
    {
      startDate: "2011,12,16"
      headline: "Sh*t Girls Say - Episode 2"
      text: ""
      asset:
        media: "http://youtu.be/kbovd-e-hRg"
        credit: ""
        caption: "Writers & Creators: Kyle Humphrey & Graydon Sheppard"
    }
    {
      startDate: "2011,12,24"
      headline: "Sh*t Girls Say - Episode 3 Featuring Juliette Lewis"
      text: ""
      asset:
        media: "http://youtu.be/bDHUhT71JN8"
        credit: ""
        caption: "Writers & Creators: Kyle Humphrey & Graydon Sheppard"
    }
    {
      startDate: "2012,1,27"
      headline: "Sh*t Web Designers Say"
      text: ""
      asset:
        media: "http://youtu.be/MEOb_meSHhQ"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,12"
      headline: "Sh*t Hipsters Say"
      text: "No meme is complete without a bit of hipster-bashing."
      asset:
        media: "http://youtu.be/FUhrSVyu0Kw"
        credit: ""
        caption: "Written, Directed, Conceptualized and Performed by Carrie Valentine and Jessica Katz"
    }
    {
      startDate: "2012,1,6"
      headline: "Sh*t Cats Say"
      text: "No meme is complete without cats. This had to happen, obviously."
      asset:
        media: "http://youtu.be/MUX58Vi-YLg"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,21"
      headline: "Sh*t Cyclists Say"
      text: ""
      asset:
        media: "http://youtu.be/GMCkuqL9IcM"
        credit: ""
        caption: "Video script, production, and editing by Allen Krughoff of Hardcastle Photography"
    }
    {
      startDate: "2011,12,30"
      headline: "Sh*t Yogis Say"
      text: ""
      asset:
        media: "http://youtu.be/IMC1_RH_b3k"
        credit: ""
        caption: ""
    }
    {
      startDate: "2012,1,18"
      headline: "Sh*t New Yorkers Say"
      text: ""
      asset:
        media: "http://youtu.be/yRvJylbSg7o"
        credit: ""
        caption: "Directed and Edited by Matt Mayer, Produced by Seth Keim, Written by Eliot Glazer. Featuring Eliot and Ilana Glazer, who are siblings, not married."
    }
  ]

$(document).ready =>
  createStoryJS =>
      type:       'timeline'
      width:      '800'
      height:     '600'
      source:     'path_to_json/or_link_to_googlespreadsheet'
      embed_id:   'wl-timeline-11121221231231'  # ID of the DIV you want to load the timeline into
  
  
  $('.wl-timeline-widget').each( () ->
    # Get local params.
    wl_local_timeline_params = $(this).data()
    wl_local_timeline_params.widget_id = $(this).attr('id');
    
    # Merge local and global params.
    $.extend wl_local_timeline_params, wl_chord_params
    console.log wl_local_timeline_params
    
    # Launch chord.
    #getChordData wl_local_chord_params
  );