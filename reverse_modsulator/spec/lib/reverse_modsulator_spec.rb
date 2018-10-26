
RSpec.describe ReverseModsulator do
  describe "parse_parameters_correctly" do
    default = ReverseModsulator.new(FIXTURES_DIR, File.join(FIXTURES_DIR, "test.txt"))
    it "uses the default namespace" do
      expect(default.namespace).to eq("xmlns")
    end
    optional = ReverseModsulator.new(FIXTURES_DIR, File.join(FIXTURES_DIR, "test.txt"), {:namespace => "mods"})
    it "uses the provided namespace" do
      expect(optional.namespace).to eq("mods")
    end
  end
  describe "process_mods_file" do
    mods_file = MODSFile.new(File.join(FIXTURES_DIR, "bg730rr6720.xml"))
    it "returns default data" do
      expect(mods_file.process_mods_file).to eq({"ti1:title" => "title placeholder"})
    end
  end
end
