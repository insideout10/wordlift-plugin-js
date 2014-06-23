describe "Timeline Ui Component Unit Test", ->
  domElement = undefined
  
  # Tests set-up.
  beforeEach inject(->
    jasmine.getJSONFixtures().fixturesPath = "base/app/assets/"
    domElement = $('<div id="timeline"></div>')
    $(document.body).append $(domElement)
  )

  afterEach inject(->
    $( "#timeline" ).remove()
  )