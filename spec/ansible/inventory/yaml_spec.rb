RSpec.describe Ansible::Inventory::YAML do
  it "has a version number" do
    expect(Ansible::Inventory::YAML::VERSION).not_to be nil
  end

  inventory = {
    "all" => {
      "hosts" => {
        "foo" => { "ansible_host" => "192.168.1.100" },
        "bar" => { "ansible_host" => "192.168.1.101" },
        "buz" => { "ansible_host" => "192.168.1.102" }
      }
    },
    "group1" => {
      "hosts" => {
        "foo" => ""
      }
    },
    "group2" => {
      "children" => {
        "group1" => ""
      }
    },
    "group3" => {
      "children" => {
        "group2" => ""
      }
    },
    "group4" => {
      "hosts" => {
        "bar" => ""
      }
    },
    "group5" => {
      "children" => {
        "group1" => "",
        "group4" => ""
      }
    },
    "group6" => {
      "children" => {
        "group3" => "",
        "group4" => ""
      }
    }
  }

  describe ".new" do
    it "does not throw exception" do
      double = instance_double("inventory")
      allow(double).to receive(:load_file).and_return(inventory)
      allow(double).to receive(:new)
      expect { double.new("/path/to/file.yml") }.not_to raise_exception
    end
  end

  let(:i) { Ansible::Inventory::YAML.new("/path/to/file.yml") }
  before(:each) { allow(i).to receive(:load_file).and_return(inventory) }
  describe ".config" do
    it "returns Hash" do
      expect(i.config.class).to eq Hash
    end
  end

  describe ".all_groups" do
    it "returns all groups" do
      expect(i.all_groups.sort).to eq %w(
        group1 group2 group3 group4 group5 group6
      ).sort
    end
  end

  describe ".all_hosts_in" do
    it "returns group1" do
      expect(i.all_hosts_in("group1")).to eq ["foo"]
    end

    it "returns group2" do
      expect(i.all_hosts_in("group2")).to eq ["foo"]
    end

    it "returns group3" do
      expect(i.all_hosts_in("group3")).to eq ["foo"]
    end

    it "returns group4" do
      expect(i.all_hosts_in("group4")).to eq ["bar"]
    end

    it "returns group5" do
      expect(i.all_hosts_in("group5").sort).to eq %w(foo bar).sort
    end

    it "returns group6" do
      expect(i.all_hosts_in("group6").sort).to eq %w(foo bar).sort
    end
  end

  describe ".host" do
    it "returns host hash of foo" do
      expect(i.host("foo")).to include({ "ansible_host" => "192.168.1.100" })
    end

    it "returns host hash of bar" do
      expect(i.host("bar")).to include({ "ansible_host" => "192.168.1.101" })
    end

    it "returns host hash of buz" do
      expect(i.host("buz")).to include({ "ansible_host" => "192.168.1.102" })
    end
  end
end
