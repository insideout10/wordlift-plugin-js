
describe "TinyMCE tests", ->
  it "editor exists and plugin is loaded", ->

    # Set a reference to the editor.
    ed = tinyMCE.get('content')

    # Check that the editor is loaded and that the WordLift plugin is loaded too.
    expect( ed ).not.toBe undefined
    expect( ed.plugins.wordlift ).not.toBe undefined



