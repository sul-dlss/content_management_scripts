
RSpec.describe ReverseModsulator do
  default = ReverseModsulator.new(FIXTURES_DIR, File.join(FIXTURES_DIR, "test.txt"))
#  optional = ReverseModsulator.new(FIXTURES_DIR, File.join(FIXTURES_DIR, "test.txt"), {:namespace => "mods"})
  describe "parse_parameters_correctly" do
    it "uses the default namespace" do
      expect(default.namespace).to eq("xmlns")
    end
    # it "uses the provided namespace" do
    #   expect(optional.namespace).to eq("mods")
    # end
  end
  describe "modify_template" do
    it "replaces subject child element names" do
      expect(default.template_xml.to_s.scan('topic').size).to be > 1
    end
  end
end
