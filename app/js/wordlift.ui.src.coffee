$ = jQuery

getChordData = (params) ->
  $.post params.ajax_url, { action: params.action, post_id: params.postId, depth: params.depth }, (data) ->
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
      baseColor = params.mainColor;
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
#    .html( (d) ->
#      lab = data.entities[d.index].label
#      beautifyLabel(lab)
#    )
    .attr('font-size', ->
      fontSize = parseInt( size/35 )
      fontSize = 8 if(fontSize < 8)
      fontSize + 'px'
    )
    .each( (d) ->
      n = data.entities[d.index].label.split(/\s/)

      # get the current element
      text = d3.select(this)
        .attr("dy", n.length / 3 - (n.length-1) * 0.9 + 'em')
        .html(n[0])

      # now loop
      for i in [1..n.length]
        text.append("tspan")
        .attr('x', 0)
        .attr('dy', '1em')
        .html(n[i])

      text.attr('transform', (d) ->
        alpha = d.startAngle - Math.PI/2 + Math.abs((d.endAngle - d.startAngle)/2)
        labelWidth = 3
        labelAngle = undefined
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

jQuery ($) ->
  $('.wl-chord').each ->
    # Get local params.
    params = $(this).data()
    params.widget_id = $(this).attr('id');
    
    # Merge local and global params.
    $.extend params, wl_chord_params
    
    # Launch chord.
    getChordData params

jQuery ($) ->
  $('.wl-timeline').each ->

    # Get local params.
    params = $(this).data()
    elemId = $(this).attr('id')

    # Merge local and global params.
    $.extend params, wl_timeline_params

    # Get data via AJAX
    $.post params.ajax_url, { action: params.action, post_id: params.postId }, (data) ->
      if data.timeline?
        createStoryJS
          type: 'timeline'
          width: '100%'
          height: '600'
          source: data
          embed_id: elemId  # ID of the DIV you want to load the timeline into
          start_at_slide: data.startAtSlide

      else
        $( "##{elemId}" ).html('No data for the timeline.')
          .height '30px'
          .css 'background-color', 'red'

$ = jQuery

getGeomapData = (params) ->
  $.post params.ajax_url,
    { action: params.action, post_id: params.postId },
    (data) ->
      buildGeomap data, params

buildGeomap = (data, params) ->
  
  console.log data, params

  # Check if data contains POIs
  if 'features' in data
    error = true;
  if data.features.length < 1
    error = true;
  if error
    $( "##{params.widget_id}" ).html('No data for the geomap.')
      .height '30px'
      .css 'background-color', 'red'
      return
  
  # Create a map
  map = L.map params.widget_id
  
  # Set the bounds of the map or the center, according on how many features we have on the map.
  if data.features.length == 1
    map.setView data.features[0].geometry.coordinates, 13
  else
    map.fitBounds data.boundaries

  # Add an OpenStreetMap tile layer
  L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png',
    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
  ).addTo map

  L.geoJson( data.features, {
      pointToLayer: (feature, latlng) ->
        # TODO: give marker style here
        return L.marker latlng, {}
      onEachFeature: (feature, layer) ->
        # Does this feature have a property named popupContent?
        if feature.properties and feature.properties.popupContent
          layer.bindPopup feature.properties.popupContent
  }).addTo map

jQuery ($) ->
  $('.wl-geomap').each ->
    # Get local params.
    params = $(this).data()
    params.widget_id = $(this).attr('id');
    
    # Merge local and global params.
    $.extend params, wl_geomap_params
    
    # Launch chord.
    getGeomapData params
    
  