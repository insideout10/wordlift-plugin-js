$ = jQuery

getGeomapData = (params) ->
  $.post params.ajax_url,
    { action: params.action, post_id: params.postId },
    (data) ->
      buildGeomap data, params

buildGeomap = (data, params) ->
  
  # Check if data contains entities, and that there are more than 2
  if 'entities' in data
    return if data.entities.length < 2
  else
    return
  
  console.log data, params

jQuery ($) ->
  $('.wl-geomap').each ->
    # Get local params.
    params = $(this).data()
    params.widget_id = $(this).attr('id');
    
    # Merge local and global params.
    $.extend params, wl_geomap_params
    
    # Launch chord.
    getGeomapData params
    
  