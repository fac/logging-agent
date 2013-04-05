module FixtureLoading
  def log_fixture(name)
    LogAgent::Event.new({
      :message => File.read(File.expand_path("../../data/#{name}.log", __FILE__))
    })
  end
end