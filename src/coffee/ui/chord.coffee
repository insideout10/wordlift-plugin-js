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