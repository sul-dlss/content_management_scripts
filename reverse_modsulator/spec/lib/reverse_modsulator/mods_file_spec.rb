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
    it "extracted paired code/text attributes" do
      expect(mods).to include("ro1:authority" => "marcrelator")
    end
    it "extracted paired code/text values" do
      expect(mods).to include("ro1:roleText2" => "author", "ro1:roleCode2" => "aut")
    end
  end
end
