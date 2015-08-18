describe "Traslator tests", ->
  it "detect text pos from html one properly - case 1", ->
  	t = Traslator.create '''
 		<p>Sto collaborando con <span id="urn:enhancement-f324418b-8502-2f23-54a8-0e3b90910acf" class="textannotation highlight wl-organization" itemid="http://data.redlink.io/685/dataset-for-fun/entity/Associazione_Sportiva_Roma">Roma</span> adesso.</p>
  	''' 	
  	expect(t.html2text(24)).toBe(21)

  it "detect text pos from html one properly - case 2", ->
   t = Traslator.create '''
 		<p>Sto collaborando con <strong>*<span id="urn:enhancement-86adde59-0246-c85c-1985-fefc0f1d2efd" class="textannotation highlight wl-organization" itemscope="itemscope" itemid="http://dbpedia.org/resource/A.S._Roma">Roma</span></strong> adesso.</p>
   '''
   expect(t.html2text(33)).toBe(22)

  it "detect text pos from html one properly - case 3", ->
   t = Traslator.create '''
 		<p>Sto collaborando con <strong><span id="urn:enhancement-86adde59-0246-c85c-1985-fefc0f1d2efd" class="textannotation highlight wl-organization" itemscope="itemscope" itemid="http://dbpedia.org/resource/A.S._Roma">Roma</span></strong> adesso.</p>
   '''
   expect(t.html2text(32)).toBe(21)

#  it "test tinymce default value", ->
#   t = Traslator.create '<p><br data-mce-bogus="1"></p>'
#   expect(t.getText()).toBe('')

  it "detect text pos from html one properly - case 4", ->
   t = Traslator.create '''
<div class="dnd-atom-wrapper type-image context-side_image atom-align-right" contenteditable="false"> <div class="dnd-drop-wrapper"></div> <div class="dnd-legend-wrapper"> <div class="caption"><span id="urn:enhancement-9de5d4e0-a428-4ece-a9b3-8792ad667ffb" class="textannotation">Planning</span> <span id="urn:enhancement-26f94354-a8ba-f73a-d3a8-fac1e5950fae" class="textannotation">for</span> <span id="urn:enhancement-16b8bd6e-4bee-f1e4-d19c-021e1fe55936" class="textannotation disambiguated wl-organization" itemid="http://data.redlink.io/91/be2/entity/NASA">NASA</span>'s.</div> <div class="link"></div> </div> </div>
'''
   expect(t.html2text(562)).toBe(16)

  it "detect text pos from html one properly - case 5", ->
   content = '''
<div class="dnd-atom-wrapper type-image context-side_image atom-align-right" contenteditable="false">
<div class="dnd-drop-wrapper"></div>
<div class="dnd-legend-wrapper">
<div class="caption"><span id="urn:enhancement-9de5d4e0-a428-4ece-a9b3-8792ad667ffb" class="textannotation">Planning</span> <span id="urn:enhancement-26f94354-a8ba-f73a-d3a8-fac1e5950fae" class="textannotation">for</span> <span id="urn:enhancement-16b8bd6e-4bee-f1e4-d19c-021e1fe55936" class="textannotation disambiguated wl-organization" itemid="http://data.redlink.io/91/be2/entity/NASA">NASA</span>'s.</div>
<div class="link"></div>
</div>
</div>
'''
   t = Traslator.create content
   expect(t.html2text(562)).toBe(16)




