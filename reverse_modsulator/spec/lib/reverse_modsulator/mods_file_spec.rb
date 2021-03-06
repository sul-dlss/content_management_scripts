RSpec.describe(MODSFile) do
  describe "process_mods_file" do
    subject { MODSFile.new(File.join(FIXTURES_DIR, "bg730rr6720.xml"), Nokogiri::XML(ReverseModsulator.new(FIXTURES_DIR,'rm_test').modify_template), "xmlns").process_mods_file }
    it "returns a hash" do
      expect(subject.is_a?(Hash)).to be
    end
    it "extracts self attributes" do
      expect(subject).to include("na1:type" => "personal", "na1:usage" => "primary", "na1:authority" => "naf", "na1:valueURI" => "http://id.loc.gov/authorities/names/n79113135")
    end
    it "extracts self value" do
      expect(subject['ge1:genre']).to eq("photographs")
    end
    it "extracts child attributes" do
      expect(subject).to include("rc:contentSourceAuthority" => "marcorg")
    end
    it "extracts child values" do
      expect(subject).to include("na1:namePart" => "Nowinski, Ira", "na2:namePart" => "Smith, Jane")
    end
    it "extracts paired code/text attributes" do
      expect(subject).to include("ro1:authority" => "marcrelator")
    end
    it "extracts paired code/text values" do
      expect(subject).to include("ro1:roleText" => "photographer", "ro1:roleText2" => "author", "ro1:roleCode2" => "aut")
    end
    it "extracts name subject attributes" do
      expect(subject).to include("sn1:p1:nameType" => "personal", "sn1:p1:nm:authority" => "naf")
    end
    it "extracts name subject values" do
      expect(subject).to include("sn1:p1:name" => "Cranston, Mary B.", "sn2:p1:name" => "Ochoa, Ellen")
    end
    it "extracts only name subjects as name subject values" do
      expect(subject.keys.map {|k| k if k.start_with?('sn')}.compact.size).to eq(10)
    end
    it "extracts other subject attributes" do
      expect(subject).to include("su1:authority" => "lcsh")
    end
    it "extracts other subject values" do
      expect(subject).to include("su1:p1:value" => "Video arcades")
    end
    it "extracts only other subjects as other subject values" do
      expect(subject.keys.map {|k| k if k.start_with?('su')}.compact.size).to eq(9)
    end
    it "extracts other subject types" do
      expect(subject).to include("su1:p1:type" => "topic", "su1:p2:type" => "geographic", "su1:p3:type" => "geographic", "su1:p4:type" => "genre")
    end
    it "extracts a repository" do
      expect(subject).to include("lo:repository" => "Stanford University. Libraries. Department of Special Collections and University Archives")
    end
    it "extracts a physical location" do
      expect(subject).to include("lo:physicalLocation" => "MSS PHOTO 0309 Flat Box 1")
    end
    it "extracts a shelf locator" do
      expect(subject).to include("lo:callNumber" => "MS 0309")
    end
    it "extracts a purl" do
      expect(subject).to include("lo:purl" => "https://purl.stanford.edu")
    end
    it "extracts a non-purl url" do
      expect(subject).to include("lo:url" => "http://www.example.com")
    end
    it "extracts a language term and attributes" do
      expect(subject).to include("la1:text" => "English")
      expect(subject).to include("la1:authority" => "iso639-2b")
    end
    it "extracts a language code and attributes" do
      expect(subject).to include("la2:code" => "rus")
      expect(subject).to include("la2:authority" => "iso639-2b")
    end
    it "extracts a language term from recordInfo" do
      expect(subject).to include("rc:languageOfCatalogingTerm" => "English")
    end
    it "extracts a language code and attributes from recordInfo" do
      expect(subject).to include("rc:languageOfCataloging" => "eng")
      expect(subject).to include("rc:langAuthority" => "iso639-2b")
    end
    it "extracts a script term from recordInfo" do
      expect(subject).to include("rc:scriptOfCatalogingTerm" => "Latin")
    end
    it "extracts a script code and attributes from recordInfo" do
      expect(subject).to include("rc:scriptOfCatalogingCode" => "Latn")
      expect(subject).to include("rc:scriptAuthority" => "iso15924")
    end
    it "extracts originInfo attributes" do
      expect(subject).to include("or:eventType" => "production")
    end
    it "extracts a place and attributes" do
      expect(subject).to include("pl:placeText" => "Berkeley (Calif.)")
      expect(subject).to include("pl:valueURI" => "http://id.loc.gov/authorities/names/n79046046")
    end
    it "extracts dates and attributes" do
      expect(subject).to include("dt:dateCreated" => "1981")
      expect(subject).to include("dt:dateCreatedKeyDate" => "yes")
      expect(subject).to include("dt:dateCreated2" => "1982")
    end
    it "extracts cartographic subjects" do
      expect(subject).to include("sc1:scale" => "Scale")
    end
    it "extracts relatedItem attributes" do
      expect(subject).to include("ri1:displayLabel" => "Case")
    end
    it "extracts relatedItem child values" do
      expect(subject).to include("ri1:title" => "The Prosecutor v. Rusdin Maubere")
    end
    it "extracts relatedItem child attributes" do
      expect(subject).to include("ri1:id1:type" => "case number")
    end
    it "does not extract collections as related items" do
      expect(subject).not_to include("ri2:title" => "Trial Records of the Special Panels for Serious Crimes (SPSC) in East Timor")
    end
    it "does not include brackets or newlines in header keys" do
      expect(subject.keys.map {|k| k if k.match(/[\[\]\n]/)}.compact.size).to eq(0)
    end
#    puts mods.inspect
  end
end
