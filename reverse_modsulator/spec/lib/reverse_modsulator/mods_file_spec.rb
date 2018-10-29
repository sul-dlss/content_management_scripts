RSpec.describe(MODSFile) do
  describe "process_mods_file" do
    mods_file = MODSFile.new(File.join(FIXTURES_DIR, "bg730rr6720.xml"), Nokogiri::XML(File.open(TEMPLATE_FILE)), "xmlns")
    mods = mods_file.process_mods_file
    it "returns a hash" do
      expect(mods.is_a?(Hash)).to be
    end
    it "extracts self attributes" do
      expect(mods).to include("na1:type" => "personal", "na1:usage" => "primary", "na1:authority" => "naf", "na1:valueURI" => "http://id.loc.gov/authorities/names/n79113135")
    end
    it "extracts self value" do
      expect(mods['ge1:genre']).to eq("photographs")
    end
    it "extracts child attributes" do
      expect(mods).to include("rc:contentSourceAuthority" => "marcorg")
    end
    it "extracts child values" do
      expect(mods).to include("na1:namePart" => "Nowinski, Ira", "na2:namePart" => "Smith, Jane")
    end
    it "extracts paired code/text attributes" do
      expect(mods).to include("ro1:authority" => "marcrelator")
    end
    it "extracts paired code/text values" do
      expect(mods).to include("ro1:roleText" => "photographer", "ro1:roleText2" => "author", "ro1:roleCode2" => "aut")
    end
    it "extracts name subject attributes" do
      expect(mods).to include("sn1:p1:nameType" => "personal", "sn1:p1:nm:authority" => "naf")
    end
    it "extracts name subject values" do
      expect(mods).to include("sn1:p1:name" => "Cranston, Mary B.", "sn2:p1:name" => "Ochoa, Ellen")
    end
    it "extracts other subject attributes" do
      expect(mods).to include("su1:authority" => "lcsh")
    end
    it "extracts other subject values" do
      expect(mods).to include("su1:p1:value" => "Video arcades")
    end
    it "extracts other subject types" do
      expect(mods).to include("su1:p1:type" => "topic", "su1:p2:type" => "geographic", "su1:p3:type" => "geographic", "su1:p4:type" => "genre")
    end
    it "extracts a repository" do
      expect(mods).to include("lo:repository" => "Stanford University. Libraries. Department of Special Collections and University Archives")
    end
    it "extracts a physical location" do
      expect(mods).to include("lo:physicalLocation" => "MSS PHOTO 0309 Flat Box 1")
    end
    it "extracts a shelf locator" do
      expect(mods).to include("lo:callNumber" => "MS 0309")
    end
    it "extracts a purl" do
      expect(mods).to include("lo:purl" => "https://purl.stanford.edu")
    end
    it "extracts a non-purl url" do
      expect(mods).to include("lo:url" => "http://www.example.com")
    end
    it "extracts a language term" do
      expect(mods).to include("la1:text" => "English")
    end
    it "extracts a language code" do
      expect(mods).to include("la2:code" => "rus")
    end
  end
end
