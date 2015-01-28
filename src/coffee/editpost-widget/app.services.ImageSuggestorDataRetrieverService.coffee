angular.module('wordlift.editpost.widget.services.ImageSuggestorDataRetrieverService', [])
# Manage redlink analysis responses
.service('ImageSuggestorDataRetrieverService', [ '$log', '$http', '$rootScope', ($log, $http, $rootScope)-> 
  
  service = {}
  service.loadData = (entities)->
    items = []
    for id, entity of entities
      for image in entity.images
        items.push { 'uri': image }
    items

  service

])