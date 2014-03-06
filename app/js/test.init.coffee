# disable karma auto start and start it manually, once the tinymce is initialized
# similar to what requirejs adapter does
__karma__.loaded = ->


document.body.innerHTML = '<textarea id="content"></textarea><div id="content_ifr"></div>'

editor  = undefined
# Set the AJAX URL to the mock up response.
ajaxurl = '/base/app/assets/english.json'

tinymce.init
    # General options
    mode : 'exact'
    elements : 'content'
    theme : "simple"
    plugins : "autolink,lists,spellchecker,pagebreak,style,layer,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template,wordlift"

    # Theme options
    theme_advanced_buttons1 : "save,newdocument,|,bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect,fontsizeselect"
    theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,help,code,|,insertdate,inserttime,preview,|,forecolor,backcolor"
    theme_advanced_buttons3 : "tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,emotions,iespell,media,advhr,|,print,|,ltr,rtl,|,fullscreen"
    theme_advanced_buttons4 : "insertlayer,moveforward,movebackward,absolute,|,styleprops,spellchecker,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template,blockquote,pagebreak,|,insertfile,insertimage"
    theme_advanced_toolbar_location : "top"
    theme_advanced_toolbar_align : "left"
    theme_advanced_statusbar_location : "bottom"
    theme_advanced_resizing : true

    # Skin options
    skin : "o2k7"
    skin_variant : "silver"

    # Example content CSS (should be your site CSS)
    # content_css : "css/example.css"

    # Drop lists for link/image/media/template dialogs
    template_external_list_url : "js/template_list.js"
    external_link_list_url : "js/link_list.js"
    external_image_list_url : "js/image_list.js"
    media_external_list_url : "js/media_list.js"

    init_instance_callback: (ed) ->
      editor = ed;

      # trigger Karma manually
      __karma__.start();

#$(
#  # Set the AJAX URL as WordPress would do.
#  ajaxurl = ''
#
##  console.log $('#context')
#
#  # Append a textarea element for TinyMCE.
##  $('#context').append '<textarea id="content" name="content" style="width:100%"></textarea>'
#
#  tinyMCE.init
#    # General options
#    mode : 'exact'
#    elements : 'content'
#    theme : "simple"
#    plugins : "autolink,lists,spellchecker,pagebreak,style,layer,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template"
#
#    # Theme options
#    theme_advanced_buttons1 : "save,newdocument,|,bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect,fontsizeselect"
#    theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,help,code,|,insertdate,inserttime,preview,|,forecolor,backcolor"
#    theme_advanced_buttons3 : "tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,emotions,iespell,media,advhr,|,print,|,ltr,rtl,|,fullscreen"
#    theme_advanced_buttons4 : "insertlayer,moveforward,movebackward,absolute,|,styleprops,spellchecker,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template,blockquote,pagebreak,|,insertfile,insertimage"
#    theme_advanced_toolbar_location : "top"
#    theme_advanced_toolbar_align : "left"
#    theme_advanced_statusbar_location : "bottom"
#    theme_advanced_resizing : true
#
#    # Skin options
#    skin : "o2k7"
#    skin_variant : "silver"
#
#    # Example content CSS (should be your site CSS)
#    # content_css : "css/example.css"
#
#    # Drop lists for link/image/media/template dialogs
#    template_external_list_url : "js/template_list.js"
#    external_link_list_url : "js/link_list.js"
#    external_image_list_url : "js/image_list.js"
#    media_external_list_url : "js/media_list.js"
#
##    init_instance_callback : (ed) ->
##      console.log 'initialized'
##
##    setup : (ed) ->
##      ed.onInit.add (ed) ->
##        console.debug 'Editor is done: ' + ed.id
#
#)