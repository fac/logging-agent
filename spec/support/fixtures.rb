module FixtureLoading
  def log_fixture(name)
    LogAgent::Event.new({
      :message => File.read(File.expand_path("../../data/#{name}.log", __FILE__))
    })
  end
end

module FixtureLoadingClassMethods
  def load_entries!(path)
    Dir.glob(File.expand_path("../../data/#{path}/*", __FILE__)) do |file|
      file = File.basename(file, ".*")
      let(file.intern) { log_fixture(File.join("#{path}", file)).tap { |e| filter << e } }
    end
  end
end