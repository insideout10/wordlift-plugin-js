$ = jQuery

# Add a geomap plugin object to jQuery
$.fn.extend
  # Change pluginName to your plugin's name.
  geomap: (options) ->
    # Default settings
    settings =
      url: ''
      debug: false
      zoom: 13 

    # Merge default settings with options.
    settings = $.extend settings, options
    # Create a reference to dom element
    container = $( this )

    # Initialization method
    init = ()->
      retrieveGeomapData()

    # Retrieve data from for map rendering
    retrieveGeomapData = ()->
      $.ajax(
        url: settings.url
        success: (response) ->
          buildGeomap response
      )
    # Build a geoMap obj via Leaflet.js
    buildGeomap = (data) ->
        
      # With no features set the container as hidden and log a warning
      if data.features?.length is 0
        container.hide()
        log "Features missing: geomap cannot be rendered"
        return

      # Create a map
      map = L.map container.attr('id')
  
      # With a single feature sets the map center accordingly to feature coordinates.
      # With more than one feature sets baundaries instead.
      if data.features.length is 1
        map.setView data.features[0].geometry.coordinates, settings.zoom
      else
        map.fitBounds data.boundaries

      # Add an OpenStreetMap tile layer
      L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png',
        attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
      ).addTo map

      L.geoJson( data.features, {
        pointToLayer: (feature, latlng) ->
          # TODO: give marker style here
          L.marker latlng, {}
        onEachFeature: (feature, layer) ->
          # On each feature set popupContent if available
          if feature.properties?.popupContent
            layer.bindPopup feature.properties.popupContent
      }).addTo map

    # Simple logger 
    log = (msg) ->
      console?.log msg if settings.debug

    init()

jQuery ($) ->
  $('.wl-geomap').each ->
    element = $(this)
    
    params = element.data()
    $.extend params, wl_geomap_params
    
    url = "#{params.ajax_url}?#{$.param({ 'action': params.action, 'postId': params.postId })}"
    
    element.geomap(
      url: url
      )
    
  