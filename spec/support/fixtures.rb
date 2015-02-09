module FixtureLoading
  def log_fixture(name)
    LogAgent::Event.new({
      :message => File.read(File.expand_path("../../data/#{name}.log", __FILE__))
    })
  end
  def log_fixture_array(name)
    File.read(File.expand_path("../../data/#{name}.log", __FILE__)).split("\n").map do |l|
      LogAgent::Event.new({
        :message => l
      })
    end
  end
end

module FixtureLoadingClassMethods
  def load_entries!(path)
    Dir.glob(File.expand_path("../../data/#{path}/*", __FILE__)) do |file|
      file = File.basename(file, ".*")
      let(file.intern) { log_fixture(File.join(path, file)).tap { |e| filter << e } }
      let(:"#{file}_array") { log_fixture_array(File.join(path, file)) }
    end
  end
end