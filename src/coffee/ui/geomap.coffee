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
    
  