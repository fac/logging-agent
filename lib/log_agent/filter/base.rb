module LogAgent::Filter
  class Base < LogAgent::Input::Base
    alias_method :<<, :emit
  end
end
