$ = jQuery

$.ready ->

  $('.wl-timeline').each ->
    
    # Get local params.
    params = $(this).data()
    params.widget_id = $(this).attr('id');
    
    # Merge local and global params.
    $.extend params, wl_timeline_params

    # Get data via AJAX
    $.post params.ajax_url, {
      action:  params.action
      post_id: params['post-id']
    }, (response) ->
      timelineData  = JSON.parse response
      console.log timelineData
      
      if timelineData.timeline
        createStoryJS
          type:       'timeline'
          width:      '100%'
          height:     '600'
          source:     timelineData
          embed_id:   params.widget_id  # ID of the DIV you want to load the timeline into
      else
        id = '#' + params.widget_id;
        $(id).html 'No data for the timeline.'
             .height '30px'
             .css 'background-color','red'
