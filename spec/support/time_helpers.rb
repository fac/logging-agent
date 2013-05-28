module TimeHelpers

  # Public: Fake out the local machine timezone by temporarily
  # setting the ENV['TZ'] value for the duration of a block.
  #
  #    timezone - the value for ENV['TZ']
  #
  def fake_local_timezone(timezone)
    ENV['TZ'], old_tz = timezone, ENV['TZ']
    yield
  ensure
    ENV['TZ'] = old_tz
  end

end
