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