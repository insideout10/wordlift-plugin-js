angular.module('wordlift.tinymce.plugin.services.Helpers', [])
.service('Helpers', [ ->
    service = {}

    # Merges two objects by copying overrides param onto the options.
    service.merge = (options, overrides) ->
      @extend (@extend {}, options), overrides

    service.extend = (object, properties) ->
      for key, val of properties
        object[key] = val
      object

    # Creates a unique ID of the specified length (default 8).
    service.uniqueId = (length = 8) ->
      id = ''
      id += Math.random().toString(36).substr(2) while id.length < length
      id.substr 0, length

    ###*
     * Expand a string using the provided context.
     * @param {string} A content string to be expanded.
     * @param {object} A context providing prefix -> URL key-value pairs
     * @return {string} An expanded string.
     ###
    service._expand = (content, context) ->
      # console.log "expand [ content :: #{content} ][ context :: #{context} ]"
      return if not content?
      # if there's no prefix, return the original string.
      if null is matches = "#{content}".match(/([\w|\d]+):(.*)/)
        prefix = content
        path = ''
      else
        # get the prefix and the path.
        prefix = matches[1]
        path = matches[2]

      # if the prefix is unknown, leave it.
      if context[prefix]?
        prepend = if angular.isString context[prefix] then context[prefix] else context[prefix]['@id']
      else
        prepend = prefix + ':'

      # return the full path.
      prepend + path

    ###*
     * Expand the specified content using the prefixes in the provided context.
     * @param {string|array} The content string or an array of strings.
     * @param {object} A context made of prefix -> URLs value pairs.
     * @return {string|array} An expanded string or an array of expanded strings.
     ###
    service.expand = (content, context) ->
      if angular.isArray content
        return (service.expand(c, context) for c in content)

      service._expand content, context

    # Return the services.
    service

  ])