describe "Chord Ui Component Unit Test", ->
  domElement = undefined
  
  # Tests set-up.
  beforeEach inject(->
    jasmine.getJSONFixtures().fixturesPath = "base/app/assets/"
    domElement = $('<div class="wl-chord"></div>')
    $(document.body).append $(domElement)
  )

  afterEach inject(->
    $( ".wl-chord" ).remove()
  )

  it "does not create chord if receives empty data", ->

    fakeResponse = getJSONFixture("chord_0.json")
    # Set a mock object to replace jquery Ajax POST with fake / mock results
    spyOn(jQuery, "ajax").and.callFake((request)->
      request.success fakeResponse
    )
    # Initialize the plugin
    domElement.chord()

    # Jquery post() has been called during the initialization
    expect(jQuery.ajax).toHaveBeenCalled()

    # Check that there are no entities in the chord
    expect(domElement.find('.entity').length).toEqual(0)

  it "creates successfully a chord with three entities and three relations", ->
    fakeResponse = getJSONFixture("chord_1.json")
    # Set a mock object to replace jquery Ajax POST with fake / mock results
    spyOn(jQuery, "ajax").and.callFake((request)->
      request.success fakeResponse
    )
    # Initialize the plugin
    domElement.chord()

    # Jquery post() has been called during the initialization
    expect(jQuery.ajax).toHaveBeenCalled()
    # Check if the map is visible
    expect(domElement.is(":visible")).toBeTruthy()
    # Check the presence fo three relations and three entities
    expect(domElement.find('.entity').length).toEqual(3)
    expect(domElement.find('.relation').length).toEqual(3)
 
